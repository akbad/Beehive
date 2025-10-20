#!/usr/bin/env bash

# MCP server setup script
#
# Prerequisites:
#   Required:
#       - Node.js (for npx)
#       - uv/uvx (for Python packages - Python 3.12 recommended)
#       - Docker (for Qdrant container)
#       - Homebrew (for installing semgrep binary)
#       - Context7 API key in $CONTEXT7_API_KEY
#       - Tavily API key in $TAVILY_API_KEY
#
#   Optional but recommended:
#       - Set up Zen clink config:
#           - Roles and per-CLI config at `~/.zen/cli_clients/`
#           - Subagent prompts at `~/.zen/prompts`
#
# Usage:
#   ./setup-mcp-servers.sh [options]
#
# Options:
#   -d, --dir <path>    The directory to allow the Filesystem MCP to access.
#                       Defaults to ~/Code.
#   -h, --help          Show this help message.
#
# Purpose:
#  1. Sets up the following MCP servers in HTTP mode
#    (i.e. shared across all agents/repos):
#      - Zen MCP (local server, clink only - for cross-CLI orchestration)
#      - Qdrant MCP (local server, semantic memory with Docker backend)
#      - Sourcegraph MCP (local server wrapper for Sourcegraph.com public search)
#      - Semgrep MCP (local server, static analysis and security scanning)
#      - Context7 MCP (remote Upstash server, always-fresh API docs)
#      - Tavily MCP (remote Tavily server, web search/extract/map/crawl)
#      - Firecrawl MCP (remote Firecrawl server, web scraping and crawling)
#  2. Sets up the following MCP servers in stdio mode
#     (i.e. each agent runs its own server)
#      - Filesystem MCP (necessary since only supports stdio transport)
#      - Fetch MCP (necessary since only supports stdio transport)
#      - Git MCP (necessary since needs to run specifically within *one* Git repo)
#  3. Connects coding agent CLI clients:
#      - Gemini CLI
#      - Claude Code
#      - Codex CLI

set -e  # exit on error

# Get the directory where this script lives (for referencing adjacent files)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- ARGUMENT PARSING ---

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--dir)
        FS_ALLOWED_DIR="$2"
        shift # past argument
        shift # past value
        ;;

        -h|--help)
        # Extract the header comment block to show as help text:
        # 1. selects lines from line 2 up until first blank line
        # 2. removes leading `#` chars
        # 3. prints the resulting help message
        sed -n '2,/^$/p' "$0" | sed 's/^# //g'
        exit 0
        ;;

        *) # unknown option
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# --- CONFIG ---

# Parent repo (best if it contains all projects you want to use these agents with)
PARENT_REPO="$HOME/Code"

# Agent CLIs we support and their config file locations
AGENTS=("gemini" "claude" "codex")

GEMINI_CONFIG="$HOME/.gemini/settings.json"
CLAUDE_CONFIG="$HOME/.claude.json"
CODEX_CONFIG="$HOME/.codex/config.toml"

DEFAULT_TIMEOUT=30     # timeout when waiting for any server/daemon to start
RANCHER_TIMEOUT=120    # timeout specific for Rancher Desktop startup (can take a while)

# Remote server URLs
export CONTEXT7_URL="https://mcp.context7.com/mcp"
export TAVILY_URL="https://mcp.tavily.com/mcp/?tavilyApiKey=\${TAVILY_API_KEY}"
export FIRECRAWL_BASE_URL="https://mcp.firecrawl.dev"
export FIRECRAWL_STREAMABLE_HTTP_PATH="/v2/mcp"

# Zen MCP: disable all tools except clink
export ZEN_CLINK_DISABLED_TOOLS='analyze,apilookup,challenge,chat,codereview,consensus,debug,docgen,planner,precommit,refactor,secaudit,testgen,thinkdeep,tracer'

# Qdrant MCP: semantic memory configuration
export QDRANT_PORT=8780
export QDRANT_URL="http://127.0.0.1:$QDRANT_PORT"
export QDRANT_COLLECTION_NAME="coding-memory"
export QDRANT_EMBEDDING_PROVIDER="fastembed"
export QDRANT_DATA_DIR="$PARENT_REPO/qdrant-data"

# Sourcegraph MCP: code search configuration
export SOURCEGRAPH_ENDPOINT="https://sourcegraph.com"                     # Free public search (no token needed)
export SOURCEGRAPH_REPO_PATH="$PARENT_REPO/mcp-servers/sourcegraph-mcp"   # Where to clone the MCP server repo to

# Ports for local HTTP servers
export ZEN_MCP_PORT=8781
export QDRANT_MCP_PORT=8782
export SOURCEGRAPH_MCP_PORT=8783
export SEMGREP_MCP_PORT=8784

# Directories
FS_ALLOWED_DIR="${FS_ALLOWED_DIR:-$PARENT_REPO}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- HELPERS ---

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_separator() {
    echo ""
    echo "----------------"
    echo ""
}

# Check if a port is already in use
check_port() {
    local port=$1
    if lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Kill process on a port
kill_port() {
    local port=$1
    if check_port "$port"; then
        log_warning "Port $port is in use. Killing existing process..."
        lsof -ti:"$port" | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
}

# Build the Firecrawl streamable HTTP URL with the API key embedded in the path.
# Returns an empty string if no API key is provided so callers can detect the issue
# without the script exiting (since set -e is enabled globally).
build_firecrawl_streamable_http_url() {
    local api_key=$1
    local base="${FIRECRAWL_BASE_URL%/}"
    local path="$FIRECRAWL_STREAMABLE_HTTP_PATH"

    if [[ -z "$api_key" ]]; then
        echo ""
        return 0
    fi

    if [[ "${path:0:1}" != "/" ]]; then
        path="/$path"
    fi

    echo "$base/$api_key$path"
}

# Start Qdrant Docker container idempotently
start_qdrant_docker() {
    local container_name="qdrant"
    local port=$QDRANT_PORT
    local data_dir=$QDRANT_DATA_DIR

    # Check if container exists and is running
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_success "Qdrant container already running"
        return 0
    fi

    # Check if container exists but is stopped
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_info "Starting existing Qdrant container..."
        docker start "$container_name" >/dev/null
        sleep 2
        log_success "Qdrant container started"
        return 0
    fi

    # Create data directory if it doesn't exist
    mkdir -p "$data_dir"

    # Start new container
    log_info "Creating and starting Qdrant container..."
    docker run -d \
        --name "$container_name" \
        -p "$port:6333" \
        -v "$data_dir:/qdrant/storage" \
        qdrant/qdrant >/dev/null

    sleep 2
    log_success "Qdrant container started on port $port"
}

# Start HTTP server idempotently (returns PID via variable name passed as arg)
start_http_server() {
    local server_name=$1
    local port=$2
    local pid_var=$3  # Variable name to store PID
    shift 3
    local start_cmd=("$@")
    local log_file="/tmp/mcp-${server_name}-server.log"
    local pid
    local elapsed=0

    if check_port "$port"; then
        log_success "$server_name already running on port $port"
        pid=$(lsof -ti:"$port" | head -1)
        log_info "Using existing server (PID: $pid)"
        eval "$pid_var=$pid"
    else
        log_info "Starting $server_name on port $port..."
        log_info "  → launch command: ${start_cmd[*]}"
        nohup "${start_cmd[@]}" > "$log_file" 2>&1 &
        pid=$!

        # Poll for port to become available (check every second, up to DEFAULT_TIMEOUT seconds)
        while [ $elapsed -lt $DEFAULT_TIMEOUT ]; do
            sleep 1
            elapsed=$((elapsed + 1))

            if check_port "$port"; then
                log_success "$server_name started (PID: $pid) after ${elapsed}s"
                eval "$pid_var=$pid"
                return 0
            fi
        done

        # If we get here, server didn't start within DEFAULT_TIMEOUT seconds
        log_error "Failed to start $server_name within ${DEFAULT_TIMEOUT}s."
        echo ""
        log_error "Log file with output from failed server startup saved at this location:"
        log_error "$log_file"
        echo ""
        log_error "Log file contents:"
        log_separator
        cat "$log_file" 2>/dev/null || echo "(log file not found or empty)"
        log_separator
        exit 1
    fi
}

# Add or update Gemini MCP entry (supports HTTP and stdio transports)
add_to_gemini_json() {
    local transport=$1
    local server_name=$2
    shift 2

    mkdir -p "$HOME/.gemini"

    # Initialize file if it doesn't exist
    if [[ ! -f "$GEMINI_CONFIG" ]]; then
        echo '{"mcpServers":{}}' > "$GEMINI_CONFIG"
    fi

    # Check if server already exists
    if grep -q "\"$server_name\"" "$GEMINI_CONFIG" 2>/dev/null; then
        return 0
    fi

    python3 "$SCRIPT_DIR/add_to_gemini_json.py" "$transport" "$server_name" "$GEMINI_CONFIG" "$@"
}

# Add server to Codex config file
add_to_codex() {
    local server_name=$1
    local transport=$2
    shift 2

    mkdir -p "$HOME/.codex"
    [[ ! -f "$CODEX_CONFIG" ]] && touch "$CODEX_CONFIG"

    if grep -q "^\[mcp_servers.$server_name\]" "$CODEX_CONFIG" 2>/dev/null; then
        return 0  # Already exists
    fi

    if [[ "$transport" == "http" ]]; then
        local url=$1
        cat >> "$CODEX_CONFIG" << EOF

[mcp_servers.$server_name]
url = "$url"
transport = "http"
EOF
    else  # stdio server
        local cmd_args=("$@")
        cat >> "$CODEX_CONFIG" << EOF

[mcp_servers.$server_name]
command = "${cmd_args[0]}"
args = [$(printf '"%s", ' "${cmd_args[@]:1}" | sed 's/, $//')]
transport = "stdio"
EOF
    fi
}

# Idempotently configure an agent to use an HTTP MCP (at user scope) 
add_http_mcp_to_agent() {
    local agent=$1
    local server=$2
    local url=$3
    shift 3
    local headers=("$@")  # Remaining args are headers (format: KEY:value)

    case $agent in
        gemini)
            # Use direct JSON manipulation to add server with headers
            add_to_gemini_json "http" "$server" "$url" "${headers[@]}"
            ;;
        claude)
            # Check user scope config directory for existing server
            if grep -q "\"$server\"" "$CLAUDE_CONFIG"; then
                return 0  # Already exists
            fi

            # Build header flags if provided (format: KEY:value)
            local header_args=()
            for header in "${headers[@]}"; do
                if [[ "$header" == *":"* ]]; then
                    header_args+=(--header "$header")
                fi
            done

            echo "Adding $server as remote HTTP to Claude with the command:"
            local claude_cmd=(claude mcp add --transport http "$server" --scope user "$url" "${header_args[@]}")
            printf '  %q' "${claude_cmd[@]}"
            echo ""
            "${claude_cmd[@]}"
            ;;
        codex)
            # Codex HTTP mode doesn't support custom headers, only bearer_token
            # Skip if headers are required
            if [[ ${#headers[@]} -gt 0 ]]; then
                return 1  # Cannot configure - headers not supported
            fi
            add_to_codex "$server" "http" "$url"
            ;;
    esac
}

# Idempotently configure an agent to use a stdio MCP (at user scope)
add_stdio_mcp_to_agent() {
    local agent=$1
    local server=$2
    shift 2
    local cmd_args=("$@")

    case $agent in
        gemini)
            add_to_gemini_json "stdio" "$server" "${cmd_args[@]}"
            ;;
        claude)
            # Check user scope config directory for existing server
            if grep -q "\"$server\"" "$CLAUDE_CONFIG"; then
                return 0  # Already exists
            fi

            echo "Adding $server as local stdio to Claude with the command:"
            local claude_cmd=(claude mcp add --transport stdio "$server" --scope user -- "${cmd_args[@]}")
            printf '  %q' "${claude_cmd[@]}"
            echo ""
            "${claude_cmd[@]}"
            ;;
        codex)
            add_to_codex "$server" "stdio" "${cmd_args[@]}"
            ;;
    esac
}

# Configure all agents for HTTP MCP server
setup_http_mcp() {
    local server=$1
    local url=$2
    shift 2
    local headers=("$@")  # Remaining args are headers (format: KEY=value)

    log_info "Setting up $server (HTTP - shared)..."

    for agent in "${AGENTS[@]}"; do
        # No Codex CLI command for HTTP servers; must use config file
        if [[ "$agent" == "codex" ]] || command -v "$agent" &> /dev/null; then
            log_info "Configuring $agent..."
            (add_http_mcp_to_agent "$agent" "$server" "$url" "${headers[@]}" && log_success "$agent configured") || log_warning "Already exists"
        else
            log_warning "$agent not found, skipping..."
        fi
    done
}

# Configure all agents for stdio MCP server
setup_stdio_mcp() {
    local server=$1
    shift
    local cmd_args=("$@")

    log_info "Setting up $server (stdio - per-agent)..."

    for agent in "${AGENTS[@]}"; do
        if [[ "$agent" == "codex" ]] || command -v "$agent" &> /dev/null; then
            log_info "Configuring $agent..."
            (add_stdio_mcp_to_agent "$agent" "$server" "${cmd_args[@]}" && log_success "$agent configured") || log_warning "Already exists"
        else
            log_warning "$agent not found, skipping..."
        fi
    done
}

# Check for required dependency and exit if not found
check_dependency() {
    local cmd=$1
    local install_msg=$2
    local success_msg=${3:-""}

    if ! command -v "$cmd" &> /dev/null; then
        log_error "$cmd not found. $install_msg"
        exit 1
    fi

    if [[ -n "$success_msg" ]]; then
        log_info "$success_msg"
    fi
}

# Check for required environment variable and warn if not set
check_env_var() {
    local var_name=$1
    local description=$2

    if [[ -z "${!var_name}" ]]; then
        log_warning "$var_name not set. $description"
        return 1
    fi
    return 0
}

# Check if Rancher Desktop is running and start it if needed
ensure_rancher_running() {
    # Check if Docker daemon is already running
    if docker info &> /dev/null; then
        log_success "Docker daemon is already running"
        return 0
    fi

    # Check if rdctl is available
    if ! command -v rdctl &> /dev/null; then
        log_warning "rdctl not found. Cannot auto-start Rancher Desktop."
        log_info "Please ensure Rancher Desktop is running manually."
        return 1
    fi

    # Rancher/Docker is not running, attempt to start it
    log_info "Docker daemon is not running. Starting Rancher Desktop..."

    if rdctl start; then
        log_info "Waiting for Docker daemon to become ready..."
        local elapsed=0

        while [ $elapsed -lt $RANCHER_TIMEOUT ]; do
            sleep 3
            elapsed=$((elapsed + 3))

            # Check if Docker daemon is responsive
            if docker info &> /dev/null; then
                log_success "Docker daemon is ready after ${elapsed}s"
                return 0
            fi
        done

        log_error "Docker daemon did not become ready within ${RANCHER_TIMEOUT}s"
        log_info "You may need to wait a bit longer and run the script again."
        return 1
    else
        log_error "Failed to start Rancher Desktop"
        return 1
    fi
}

# Install or update a Python package from git using uv tool
install_or_update_pip_pkg_from_git() {
    local git_url=$1
    local package_name=$2

    # Check if package is already installed
    if uv tool list | grep -q "^$package_name "; then
        log_info "$package_name is already installed. Updating to latest version..."
        if uv tool install "$package_name" --force --from "git+$git_url"; then
            log_success "$package_name updated successfully"
        else
            log_error "Failed to update $package_name"
            return 1
        fi
    else
        log_info "$package_name not found. Installing from $git_url..."
        if uv tool install "$package_name" --from "git+$git_url"; then
            log_success "$package_name installed successfully"
        else
            log_error "Failed to install $package_name from $git_url"
            return 1
        fi
    fi
}

# --- CHECK DEPENDENCIES ---

log_info "Checking dependencies..."

check_dependency "npx" "Please install Node.js first."
check_dependency "uvx" "Please install uv first: https://docs.astral.sh/uv/getting-started/installation/" \
    "uvx found, will use for Git MCP (stdio mode) and Zen MCP"
check_dependency "docker" "Please install Docker first: https://docs.docker.com/get-docker/" \
    "docker found, will use for Qdrant container"
check_dependency "brew" "Please install Homebrew first: https://brew.sh/" \
    "brew found, will use for Semgrep installation"

# idempotently install Semgrep binary (used to launch MCP)
brew install semgrep

log_success "Dependency check complete."

log_info "Checking for optional tools..."
install_or_update_pip_pkg_from_git "https://github.com/github/spec-kit.git" "specify-cli"

log_info "Checking API keys..."

QDRANT_AVAILABLE=true
CONTEXT7_AVAILABLE=false
TAVILY_AVAILABLE=false
FIRECRAWL_AVAILABLE=false
SOURCEGRAPH_AVAILABLE=false

if check_env_var "CONTEXT7_API_KEY" "Context7 MCP will not work. Get a key at https://console.upstash.com/"; then
    CONTEXT7_AVAILABLE=true
fi

if check_env_var "TAVILY_API_KEY" "Tavily MCP will not work. Get a key at https://www.tavily.com/"; then
    TAVILY_AVAILABLE=true
fi

if check_env_var "FIRECRAWL_API_KEY" "Firecrawl MCP will not work. Get a key at https://firecrawl.dev/app/api-keys"; then
    FIRECRAWL_AVAILABLE=true
fi

log_success "API key check complete."

# Check if Sourcegraph MCP repo is available (must be cloned from GitHub)
log_info "Checking Sourcegraph MCP availability..."
if [[ -d "$SOURCEGRAPH_REPO_PATH" ]]; then
    log_success "Sourcegraph MCP repository found at $SOURCEGRAPH_REPO_PATH"
    SOURCEGRAPH_AVAILABLE=true
else
    log_warning "Sourcegraph MCP repository not found at $SOURCEGRAPH_REPO_PATH"
    log_info "Cloning Sourcegraph MCP repository..."

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$SOURCEGRAPH_REPO_PATH")"

    if git clone -b fix/server-startup https://github.com/akbad/sourcegraph-mcp.git "$SOURCEGRAPH_REPO_PATH"; then
        log_success "Repository cloned successfully"
        SOURCEGRAPH_AVAILABLE=true
    else
        log_error "Failed to clone Sourcegraph MCP repository"
        SOURCEGRAPH_AVAILABLE=false
    fi
fi

if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    log_info "Attempting to sync Sourcegraph deps (via uv sync)..."
    if (cd "$SOURCEGRAPH_REPO_PATH" && uv sync); then
        log_success "Deps synced successfully."
    else
        log_error "Failed to install/sync Sourcegraph dependencies."
        SOURCEGRAPH_AVAILABLE=false
    fi
fi

# ============================================================================
#   Start central HTTP servers
# ============================================================================

log_info "Idempotently starting up HTTP MCP servers..."

# Zen MCP (clink only - zero-API hub for cross-CLI orchestration)
start_http_server "Zen MCP" "$ZEN_MCP_PORT" "ZEN_PID" \
    env DISABLED_TOOLS="$ZEN_CLINK_DISABLED_TOOLS" ZEN_MCP_PORT="$ZEN_MCP_PORT" \
    uvx --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git \
    python3 "$SCRIPT_DIR/start-zen-http.py"

log_info "Ensuring Rancher Desktop is running..."
ensure_rancher_running

# Qdrant (Docker container for semantic memory backend)
log_info "Starting Qdrant Docker container..."
start_qdrant_docker

# Qdrant MCP (wrapper server for semantic memory)
start_http_server "Qdrant MCP" "$QDRANT_MCP_PORT" "QDRANT_PID" \
    env QDRANT_URL="$QDRANT_URL" \
    COLLECTION_NAME="$QDRANT_COLLECTION_NAME" \
    EMBEDDING_PROVIDER="$QDRANT_EMBEDDING_PROVIDER" \
    FASTMCP_PORT="$QDRANT_MCP_PORT" \
    uvx --from "mcp-server-qdrant>=0.8.0" mcp-server-qdrant --transport streamable-http

# Sourcegraph MCP (wrapper for Sourcegraph.com public search)
if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    start_http_server "Sourcegraph MCP" "$SOURCEGRAPH_MCP_PORT" "SOURCEGRAPH_PID" \
        env SRC_ENDPOINT="$SOURCEGRAPH_ENDPOINT" \
        MCP_STREAMABLE_HTTP_PORT="$SOURCEGRAPH_MCP_PORT" \
        uv --directory "$SOURCEGRAPH_REPO_PATH" run sourcegraph-mcp
fi

# Semgrep MCP (static analysis and security scanning)
start_http_server "Semgrep MCP" "$SEMGREP_MCP_PORT" "SEMGREP_PID" \
    semgrep mcp -t streamable-http --port "$SEMGREP_MCP_PORT"

# ============================================================================
#   Configure agents to use MCP servers
# ============================================================================

# Servers to use in HTTP mode
# - Zen MCP (local, clink)
# - Qdrant MCP (local)
# - Sourcegraph MCP (local wrapper for Sourcegraph.com)
# - Semgrep MCP (local)
# - Context7 MCP (remote Upstash - for Gemini & Claude only)
# - Tavily MCP (remote Tavily - all agents)
# - Firecrawl MCP (remote Firecrawl - Claude & Codex)
log_separator
log_info "Configuring agents to use Zen MCP for clink (HTTP)..."
setup_http_mcp "zen" "http://localhost:$ZEN_MCP_PORT/mcp/"

log_separator
log_info "Configuring agents to use Qdrant MCP (HTTP)..."
setup_http_mcp "qdrant" "http://localhost:$QDRANT_MCP_PORT/mcp/"

if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    log_separator
    log_info "Configuring all agents to use Sourcegraph MCP (HTTP - local wrapper for Sourcegraph.com)..."
    setup_http_mcp "sourcegraph" "http://localhost:$SOURCEGRAPH_MCP_PORT/sourcegraph/mcp/"
fi

log_separator
log_info "Configuring agents to use Semgrep MCP (HTTP)..."
setup_http_mcp "semgrep" "http://localhost:$SEMGREP_MCP_PORT/mcp/"

if [[ "$CONTEXT7_AVAILABLE" == true ]]; then
    log_separator
    log_info "Configuring Gemini & Claude to use Context7 MCP (HTTP - remote Upstash)..."
    # Note: Uses colon format for headers
    # Codex will use stdio mode (configured below) since HTTP doesn't support custom headers
    # Gemini requires both CONTEXT7_API_KEY and Accept headers
    setup_http_mcp "context7" "$CONTEXT7_URL" "CONTEXT7_API_KEY:\$CONTEXT7_API_KEY" "Accept:application/json, text/event-stream"
fi

if [[ "$TAVILY_AVAILABLE" == true ]]; then
    log_separator
    log_info "Configuring all agents to use Tavily MCP (HTTP - remote)..."
    # Tavily uses API key in URL query parameter, so no custom headers needed
    setup_http_mcp "tavily" "$TAVILY_URL"
fi

if [[ "$FIRECRAWL_AVAILABLE" == true ]]; then
    log_separator
    firecrawl_http_url="$(build_firecrawl_streamable_http_url "$FIRECRAWL_API_KEY")"
    if [[ -z "$firecrawl_http_url" ]]; then
        log_warning "Firecrawl API key missing; skipping Firecrawl HTTP configuration."
    else
        log_info "Configuring Claude to use Firecrawl MCP (HTTP - remote streamable)..."
        if add_http_mcp_to_agent "claude" "firecrawl" "$firecrawl_http_url"; then
            log_success "Claude configured"
        fi

        log_info "Configuring Codex to use Firecrawl MCP (HTTP - remote streamable)..."
        if add_http_mcp_to_agent "codex" "firecrawl" "$firecrawl_http_url"; then
            log_success "codex configured"
        fi

        log_info "Configuring Gemini to use Firecrawl MCP (stdio - local launcher)..."
        if add_stdio_mcp_to_agent "gemini" "firecrawl" "env" "FIRECRAWL_API_KEY=$FIRECRAWL_API_KEY" "npx" "-y" "firecrawl-mcp"; then
            log_success "gemini configured"
        fi
    fi
fi

# Servers to use in stdio mode
# - Filesystem MCP (per-agent, only supports stdio transport)
# - Fetch MCP (per-agent, only supports stdio transport)
# - Git MCP (per-agent)
# - Context7 MCP (for Codex only, since Codex HTTP doesn't support custom headers)
# - Firecrawl MCP (Gemini only, runs local stdio launcher)
log_separator
log_info "Configuring agents to use Filesystem MCP (stdio)..."
log_info "Allowed directory for Filesystem MCP: $FS_ALLOWED_DIR"
setup_stdio_mcp "fs" "npx" "-y" "@modelcontextprotocol/server-filesystem" "$FS_ALLOWED_DIR"

log_separator
log_info "Configuring agents to use Fetch MCP (stdio)..."
setup_stdio_mcp "fetch" "uvx" "mcp-server-fetch"

log_separator
log_info "Configuring agents to use Git MCP (stdio)..."
setup_stdio_mcp "git" "uvx" "mcp-server-git" "--repository" "."

if [[ "$CONTEXT7_AVAILABLE" == true ]]; then
    log_separator
    log_info "Configuring Codex to use Context7 MCP (stdio)..."
    add_stdio_mcp_to_agent "codex" "context7" "npx" "-y" "@upstash/context7-mcp" "--api-key" "\$CONTEXT7_API_KEY"
fi

# ============================================================================
#   Completion output
# ============================================================================

echo ""
log_success "Setup complete."
echo ""
log_info "Local HTTP servers running:"
log_info "  • Zen MCP (clink only): http://localhost:$ZEN_MCP_PORT/mcp/ (PID: $ZEN_PID)"
log_info "  • Qdrant MCP: http://localhost:$QDRANT_MCP_PORT/mcp/ (PID: $QDRANT_PID)"
log_info "    └─ Backend: Qdrant Docker container on port $QDRANT_PORT"
log_info "    └─ Data directory: $QDRANT_DATA_DIR"

if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    log_info "  • Sourcegraph MCP: http://localhost:$SOURCEGRAPH_MCP_PORT/sourcegraph/mcp/ (PID: $SOURCEGRAPH_PID)"
    log_info "    └─ Endpoint: $SOURCEGRAPH_ENDPOINT (free public search)"
    log_info "    └─ Repository: $SOURCEGRAPH_REPO_PATH"
fi

log_info "  • Semgrep MCP: http://localhost:$SEMGREP_MCP_PORT/mcp/ (PID: $SEMGREP_PID)"
log_info "    └─ Static analysis and security scanning (5000+ rules)"
echo ""

# Only show remote servers section if at least one is configured
if [[ "$CONTEXT7_AVAILABLE" == true || "$TAVILY_AVAILABLE" == true || "$FIRECRAWL_AVAILABLE" == true ]]; then
    log_info "Remote HTTP servers configured:"

    if [[ "$CONTEXT7_AVAILABLE" == true ]]; then
        log_info "  • Context7 MCP: $CONTEXT7_URL"
        log_info "    └─ Gemini: Headers configured automatically in ~/.gemini/settings.json"
        log_info "    └─ Claude: Header configured automatically via CLI"
        log_info "    └─ Codex: Using stdio mode instead (HTTP doesn't support custom headers)"
    fi

    if [[ "$TAVILY_AVAILABLE" == true ]]; then
        log_info "  • Tavily MCP: https://mcp.tavily.com/mcp/"
        log_info "    └─ All agents: Configured via HTTP with API key in URL"
    fi

    if [[ "$FIRECRAWL_AVAILABLE" == true ]]; then
        log_info "  • Firecrawl MCP: https://mcp.firecrawl.dev/<firecrawl-api-key>/v2/mcp"
        log_info "    └─ Claude & Codex: Configured via HTTP streamable transport"
        log_info "    └─ Gemini: Uses local stdio launcher (env FIRECRAWL_API_KEY=... npx -y firecrawl-mcp)"
    fi

    echo ""
fi

log_info "Configured stdio servers:"
log_info "  → Each agent starts its own server when launched, stops when exited."
log_info "  • Filesystem MCP (all agents)"
log_info "    └─ Allowed directory: $FS_ALLOWED_DIR"
log_info "  • Fetch MCP (all agents)"
log_info "    └─ HTML to Markdown conversion"
log_info "  • Git MCP (all agents)"
log_info "    └─ Uses current directory when agent is launched"

if [[ "$CONTEXT7_AVAILABLE" == true ]]; then
    log_info "  • Context7 MCP (Codex only)"
    log_info "    └─ Codex HTTP doesn't support custom headers, so using stdio mode"
fi

if [[ "$FIRECRAWL_AVAILABLE" == true ]]; then
    log_info "  • Firecrawl MCP (Gemini only)"
    log_info "    └─ Launches via env FIRECRAWL_API_KEY=... npx -y firecrawl-mcp"
fi
echo ""
log_info "Logs:"
log_info "  • Zen MCP: /tmp/mcp-Zen MCP-server.log"

if [[ "$QDRANT_AVAILABLE" == true ]]; then
    log_info "  • Qdrant MCP: /tmp/mcp-Qdrant MCP-server.log"
    log_info "  • Qdrant Docker: docker logs qdrant"
fi

if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    log_info "  • Sourcegraph MCP: /tmp/mcp-Sourcegraph MCP-server.log"
fi

log_info "  • Semgrep MCP: /tmp/mcp-Semgrep MCP-server.log"
echo ""
log_info "To verify setup:"
log_info "  1. cd into a git repo"
log_info "  2. Run 'gemini', 'claude', or 'codex'"
log_info "  3. Type '/mcp' to see available tools"
echo ""
log_info "To stop local HTTP servers:"
pidlist="$ZEN_PID $SEMGREP_PID"
[[ "$QDRANT_AVAILABLE" == "true" ]] && pidlist+=" $QDRANT_PID"
[[ "$SOURCEGRAPH_AVAILABLE" == "true" ]] && pidlist+=" $SOURCEGRAPH_PID"
KILL_HTTPS_CMD="kill ${pidlist}"
log_info "  $KILL_HTTPS_CMD"
KILL_HTTPS_FILE="kill_local_http_mcps.sh"
echo "$KILL_HTTPS_CMD" > "$KILL_HTTPS_FILE"
log_info "  (also written to $KILL_HTTPS_FILE to allow conveniently stopping servers later)"


if [[ "$QDRANT_AVAILABLE" == true ]]; then
    echo ""
    log_info "To stop Qdrant Docker container:"
    log_info "  docker stop qdrant"
fi
