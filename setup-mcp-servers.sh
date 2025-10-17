#!/usr/bin/env bash

# MCP server setup script
#
# Prerequisites:
#   Required:
#       - Node.js (for npx)
#       - uv/uvx (for Python packages)
#       - Docker (for Qdrant container)
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
#      - Filesystem MCP (local server)
#      - Zen MCP (local server, clink only - for cross-CLI orchestration)
#      - Fetch MCP (local server, HTML to Markdown conversion)
#      - Qdrant MCP (local server, semantic memory with Docker backend)
#      - Sourcegraph MCP (local server wrapper for Sourcegraph.com public search)
#      - Semgrep MCP (local server, static analysis and security scanning)
#      - Context7 MCP (remote Upstash server, always-fresh API docs)
#      - Tavily MCP (remote Tavily server, web search/extract/map/crawl)
#      - Firecrawl MCP (remote Firecrawl server, resilient scraping with Fire-engine)
#  2. Sets up the following MCP servers in stdio mode
#     (i.e. each agent runs its own server)
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

# Agent CLIs we support
AGENTS=("gemini" "claude" "codex")

# Remote server URLs
export CONTEXT7_URL="https://mcp.context7.com/mcp"
export TAVILY_URL="https://mcp.tavily.com/mcp/?tavilyApiKey=\${TAVILY_API_KEY}"
export FIRECRAWL_URL="https://mcp.firecrawl.dev/\${FIRECRAWL_API_KEY}/v2/mcp"

# Zen MCP: disable all tools except clink
export ZEN_CLINK_DISABLED_TOOLS='analyze,apilookup,challenge,chat,codereview,consensus,debug,docgen,planner,precommit,refactor,secaudit,testgen,thinkdeep,tracer'

# Qdrant MCP: semantic memory configuration
export QDRANT_PORT=8779
export QDRANT_URL="http://127.0.0.1:$QDRANT_PORT"
export QDRANT_COLLECTION_NAME="coding-memory"
export QDRANT_EMBEDDING_PROVIDER="fastembed"
export QDRANT_DATA_DIR="$PARENT_REPO/qdrant-data"

# Sourcegraph MCP: code search configuration
export SOURCEGRAPH_ENDPOINT="https://sourcegraph.com"                     # Free public search (no token needed)
export SOURCEGRAPH_REPO_PATH="$PARENT_REPO/mcp-servers/sourcegraph-mcp"   # Where to clone the MCP server repo to

# Ports for local HTTP servers
export FS_MCP_PORT=8780
export ZEN_MCP_PORT=8781
export FETCH_MCP_PORT=8782
export QDRANT_MCP_PORT=8783
export SOURCEGRAPH_MCP_PORT=8784
export SEMGREP_MCP_PORT=8785

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

    if check_port "$port"; then
        log_success "$server_name already running on port $port"
        pid=$(lsof -ti:"$port")
        log_info "Using existing server (PID: $pid)"
        eval "$pid_var=$pid"
    else
        log_info "Starting $server_name on port $port..."
        nohup "${start_cmd[@]}" > "$log_file" 2>&1 &
        pid=$!
        sleep 2

        if check_port "$port"; then
            log_success "$server_name started (PID: $pid)"
            eval "$pid_var=$pid"
        else
            log_error "Failed to start $server_name. Check $log_file"
            exit 1
        fi
    fi
}

# Add HTTP server with headers to Gemini settings.json
add_to_gemini_json() {
    local server_name=$1
    local url=$2
    shift 2
    local headers=("$@")  # Format: KEY:value
    local config_file="$HOME/.gemini/settings.json"

    mkdir -p "$HOME/.gemini"

    # Initialize file if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        echo '{"mcpServers":{}}' > "$config_file"
    fi

    # Check if server already exists
    if grep -q "\"$server_name\"" "$config_file" 2>/dev/null; then
        return 0  # Already exists
    fi

    # Build headers JSON
    local headers_json=""
    if [[ ${#headers[@]} -gt 0 ]]; then
        headers_json="\"headers\":{"
        local first=true
        for header in "${headers[@]}"; do
            if [[ "$header" == *":"* ]]; then
                local key="${header%%:*}"
                local value="${header#*:}"
                if [[ "$first" == true ]]; then
                    first=false
                else
                    headers_json+=","
                fi
                # If value starts with $, it's an env var reference
                if [[ "$value" == \$* ]]; then
                    headers_json+="\"$key\":\"$value\""
                else
                    headers_json+="\"$key\":\"$value\""
                fi
            fi
        done
        headers_json+="},"
    fi

    # Use Python to safely update JSON
    python3 - <<EOF
import json
import os

config_file = os.path.expanduser("$config_file")
with open(config_file, 'r') as f:
    config = json.load(f)

if 'mcpServers' not in config:
    config['mcpServers'] = {}

config['mcpServers']['$server_name'] = {
    'httpUrl': '$url'
}

# Add headers if provided
headers = {}
$(for header in "${headers[@]}"; do
    if [[ "$header" == *":"* ]]; then
        key="${header%%:*}"
        value="${header#*:}"
        echo "headers['$key'] = '$value'"
    fi
done)

if headers:
    config['mcpServers']['$server_name']['headers'] = headers

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)
EOF
}

# Add server to Codex config file
add_to_codex() {
    local server_name=$1
    local transport=$2
    shift 2
    local config_file="$HOME/.codex/config.toml"

    mkdir -p "$HOME/.codex"
    [[ ! -f "$config_file" ]] && touch "$config_file"

    if grep -q "^\[mcp_servers.$server_name\]" "$config_file" 2>/dev/null; then
        return 0  # Already exists
    fi

    if [[ "$transport" == "http" ]]; then
        local url=$1
        cat >> "$config_file" << EOF

[mcp_servers.$server_name]
url = "$url"
transport = "http"
EOF
    else  # stdio server
        local cmd_args=("$@")
        cat >> "$config_file" << EOF

[mcp_servers.$server_name]
command = "${cmd_args[0]}"
args = [$(printf '"%s", ' "${cmd_args[@]:1}" | sed 's/, $//')]
transport = "stdio"
EOF
    fi
}

# Idempotently configure single agent for HTTP MCP
add_http_mcp_to_agents() {
    local agent=$1
    local server=$2
    local url=$3
    shift 3
    local headers=("$@")  # Remaining args are headers (format: KEY:value)

    case $agent in
        gemini)
            # Use direct JSON manipulation to add server with headers
            add_to_gemini_json "$server" "$url" "${headers[@]}"
            ;;
        claude)
            # Check user scope config directory for existing server
            if [[ -d "$HOME/.claude" ]] && find "$HOME/.claude" -name "*.json" -exec grep -q "\"$server\"" {} \; 2>/dev/null; then
                return 0  # Already exists
            fi

            # Build header flags if provided (format: KEY:value)
            local header_flags=()
            for header in "${headers[@]}"; do
                if [[ "$header" == *":"* ]]; then
                    header_flags+=(--header "$header")
                fi
            done

            claude mcp add --transport http "$server" "$url" "${header_flags[@]}" 2>/dev/null
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

# Idempotently configure single agent for stdio MCP
add_stdio_mcp_to_agents() {
    local agent=$1
    local server=$2
    shift 2
    local cmd_args=("$@")

    case $agent in
        gemini)
            local gemini_config="$HOME/.gemini/settings.json"
            if [[ -f "$gemini_config" ]] && grep -q "\"$server\"" "$gemini_config" 2>/dev/null; then
                return 0  # Already exists
            fi
            gemini mcp add "$server" "${cmd_args[@]}" 2>/dev/null
            ;;
        claude)
            # Check user scope config directory for existing server
            if [[ -d "$HOME/.claude" ]] && find "$HOME/.claude" -name "*.json" -exec grep -q "\"$server\"" {} \; 2>/dev/null; then
                return 0  # Already exists
            fi
            claude mcp add "$server" -s user -- "${cmd_args[@]}" 2>/dev/null
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
            (add_http_mcp_to_agents "$agent" "$server" "$url" "${headers[@]}" && log_success "$agent configured") || log_warning "Already exists"
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
            (add_stdio_mcp_to_agents "$agent" "$server" "${cmd_args[@]}" && log_success "$agent configured") || log_warning "Already exists"
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

log_success "Dependency check complete."

log_info "Checking for optional tools..."
install_or_update_pip_pkg_from_git "https://github.com/github/spec-kit.git" "specify-cli"

log_info "Checking API keys..."

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

    if git clone https://github.com/divar-ir/sourcegraph-mcp "$SOURCEGRAPH_REPO_PATH"; then
        log_success "Repository cloned successfully"
        SOURCEGRAPH_AVAILABLE=true
    else
        log_error "Failed to clone Sourcegraph MCP repository"
        SOURCEGRAPH_AVAILABLE=false
    fi
fi

if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    if (cd "$SOURCEGRAPH_REPO_PATH" && uv sync); then
        log_success "Dependencies synced successfully"
    else
        log_error "Failed to install/sync Sourcegraph dependencies."
        SOURCEGRAPH_AVAILABLE=false
    fi
fi

# ============================================================================
#   Start central HTTP servers
# ============================================================================

log_info "Idempotently starting up HTTP MCP servers..."

# Filesystem MCP
log_info "Allowed directory for Filesystem MCP: $FS_ALLOWED_DIR"
start_http_server "Filesystem MCP" "$FS_MCP_PORT" "FS_PID" \
    npx -y @modelcontextprotocol/server-filesystem --port "$FS_MCP_PORT" "$FS_ALLOWED_DIR"

# Zen MCP (clink only - zero-API hub for cross-CLI orchestration)
start_http_server "Zen MCP" "$ZEN_MCP_PORT" "ZEN_PID" \
    env DISABLED_TOOLS="$ZEN_CLINK_DISABLED_TOOLS" ZEN_MCP_PORT="$ZEN_MCP_PORT" \
    uvx --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git \
    python3 "$SCRIPT_DIR/start-zen-http.py"

# Fetch MCP (HTML to Markdown conversion)
start_http_server "Fetch MCP" "$FETCH_MCP_PORT" "FETCH_PID" \
    npx -y @modelcontextprotocol/server-fetch --port "$FETCH_MCP_PORT"

# Qdrant (Docker container for semantic memory backend)
log_info "Starting Qdrant Docker container..."
start_qdrant_docker

# Qdrant MCP (wrapper server for semantic memory)
start_http_server "Qdrant MCP" "$QDRANT_MCP_PORT" "QDRANT_PID" \
    env QDRANT_URL="$QDRANT_URL" \
    COLLECTION_NAME="$QDRANT_COLLECTION_NAME" \
    EMBEDDING_PROVIDER="$QDRANT_EMBEDDING_PROVIDER" \
    uvx mcp-server-qdrant --transport http --port "$QDRANT_MCP_PORT"

# Sourcegraph MCP (wrapper for Sourcegraph.com public search)
if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    start_http_server "Sourcegraph MCP" "$SOURCEGRAPH_MCP_PORT" "SOURCEGRAPH_PID" \
        env SRC_ENDPOINT="$SOURCEGRAPH_ENDPOINT" \
        MCP_STREAMABLE_HTTP_PORT="$SOURCEGRAPH_MCP_PORT" \
        uv --directory "$SOURCEGRAPH_REPO_PATH" run python -m src.main
fi

# Semgrep MCP (static analysis and security scanning)
start_http_server "Semgrep MCP" "$SEMGREP_MCP_PORT" "SEMGREP_PID" \
    uvx semgrep-mcp -t streamable-http --port "$SEMGREP_MCP_PORT"

# ============================================================================
#   Configure agents to use MCP servers
# ============================================================================

# Servers to use in HTTP mode
# - Filesystem MCP (local)
# - Zen MCP (local, clink)
# - Fetch MCP (local)
# - Qdrant MCP (local)
# - Sourcegraph MCP (local wrapper for Sourcegraph.com)
# - Semgrep MCP (local,)
# - Context7 MCP (remote Upstash - for Gemini & Claude only)
# - Tavily MCP (remote Tavily - all agents)
# - Firecrawl MCP (remote Firecrawl - all agents)
log_info "Configuring agents to use Filesystem MCP (HTTP)..."
setup_http_mcp "fs" "http://localhost:$FS_MCP_PORT/mcp/"

log_info "Configuring agents to use Zen MCP for clink (HTTP)..."
setup_http_mcp "zen" "http://localhost:$ZEN_MCP_PORT/mcp/"

log_info "Configuring agents to use Fetch MCP (HTTP)..."
setup_http_mcp "fetch" "http://localhost:$FETCH_MCP_PORT/mcp/"

log_info "Configuring agents to use Qdrant MCP (HTTP)..."
setup_http_mcp "qdrant" "http://localhost:$QDRANT_MCP_PORT/mcp/"

if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    log_info "Configuring all agents to use Sourcegraph MCP (HTTP - local wrapper for Sourcegraph.com)..."
    setup_http_mcp "sourcegraph" "http://localhost:$SOURCEGRAPH_MCP_PORT/sourcegraph/mcp/"
fi

log_info "Configuring agents to use Semgrep MCP (HTTP)..."
setup_http_mcp "semgrep" "http://localhost:$SEMGREP_MCP_PORT/mcp/"

if [[ "$CONTEXT7_AVAILABLE" == true ]]; then
    log_info "Configuring Gemini & Claude to use Context7 MCP (HTTP - remote Upstash)..."
    # Note: Uses colon format for headers
    # Codex will use stdio mode (configured below) since HTTP doesn't support custom headers
    # Gemini requires both CONTEXT7_API_KEY and Accept headers
    setup_http_mcp "context7" "$CONTEXT7_URL" "CONTEXT7_API_KEY:\$CONTEXT7_API_KEY" "Accept:application/json, text/event-stream"
fi

if [[ "$TAVILY_AVAILABLE" == true ]]; then
    log_info "Configuring all agents to use Tavily MCP (HTTP - remote)..."
    # Tavily uses API key in URL query parameter, so no custom headers needed
    setup_http_mcp "tavily" "$TAVILY_URL"
fi

if [[ "$FIRECRAWL_AVAILABLE" == true ]]; then
    log_info "Configuring all agents to use Firecrawl MCP (HTTP - remote)..."
    # Firecrawl uses API key in URL path, so no custom headers needed
    setup_http_mcp "firecrawl" "$FIRECRAWL_URL"
fi

# Servers to use in stdio mode
# - Git MCP (per-agent)
# - Context7 MCP (for Codex only, since Codex HTTP doesn't support custom headers)
log_info "Configuring agents to use Git MCP (stdio)..."
setup_stdio_mcp "git" "uvx" "mcp-server-git" "--repository" "."

if [[ "$CONTEXT7_AVAILABLE" == true ]]; then
    log_info "Configuring Codex to use Context7 MCP (stdio)..."
    add_stdio_mcp_to_agents "codex" "context7" "npx" "-y" "@upstash/context7-mcp" "--api-key" "\$CONTEXT7_API_KEY"
fi

# ============================================================================
#   Completion output
# ============================================================================

echo ""
log_success "Setup complete."
echo ""
log_info "Local HTTP servers running:"
log_info "  • Filesystem MCP: http://localhost:$FS_MCP_PORT/mcp/ (PID: $FS_PID)"
log_info "    └─ Allowed directory: $FS_ALLOWED_DIR"
log_info "  • Zen MCP (clink only): http://localhost:$ZEN_MCP_PORT/mcp/ (PID: $ZEN_PID)"
log_info "  • Fetch MCP: http://localhost:$FETCH_MCP_PORT/mcp/ (PID: $FETCH_PID)"
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
        log_info "  • Firecrawl MCP: https://mcp.firecrawl.dev/*/v2/mcp"
        log_info "    └─ All agents: Configured via HTTP with API key in URL"
    fi

    echo ""
fi

log_info "Configured stdio servers:"
log_info "  → Each agent starts its own server when launched, stops when exited."
log_info "  • Git MCP (all agents)"
log_info "    └─ Uses current directory when agent is launched"

if [[ "$CONTEXT7_AVAILABLE" == true ]]; then
    log_info "  • Context7 MCP (Codex only)"
    log_info "    └─ Codex HTTP doesn't support custom headers, so using stdio mode"
fi
echo ""
log_info "Logs:"
log_info "  • Filesystem: /tmp/mcp-Filesystem MCP-server.log"
log_info "  • Zen MCP: /tmp/mcp-Zen MCP-server.log"
log_info "  • Fetch MCP: /tmp/mcp-Fetch MCP-server.log"
log_info "  • Qdrant MCP: /tmp/mcp-Qdrant MCP-server.log"
log_info "  • Qdrant Docker: docker logs qdrant"

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
pidlist="$FS_PID $ZEN_PID $FETCH_PID $QDRANT_PID $SEMGREP_PID"
[[ "$SOURCEGRAPH_AVAILABLE" == "true" ]] && pidlist+=("$SOURCEGRAPH_PID")
log_info "  kill ${pidlist[*]}"
echo ""
log_info "To stop Qdrant Docker container:"
log_info "  docker stop qdrant"
