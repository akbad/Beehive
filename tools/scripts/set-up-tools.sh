#!/usr/bin/env bash

# Tools setup script for Beehive (for MCP servers, backing Docker containers, etc.)
#
# Prerequisites:
#   Required:
#       - Node.js/npm (for npx)
#       - uv/uvx with Python 3.12 (for Python-based MCP servers)
#       - Docker Desktop or Rancher Desktop (for Qdrant container)
#       - Homebrew (for installing Semgrep binary)
#
#   API keys (for cloud-based MCP servers' free tiers):
#       - Tavily API key in $TAVILY_API_KEY
#       - Brave Search API key in $BRAVE_API_KEY
#
#   Optional but recommended: Set up Zen clink config
#       - Roles and per-CLI config at `~/.zen/cli_clients/`
#       - Subagent prompts at `~/.zen/prompts`
#
# Usage:
#   ./set-up-tools.sh [options]
#
# Options:
#   -f, --fsdir <path>    The directory to allow the Filesystem MCP to access.
#                         Defaults to ~/Code.
#   -c, --clonedir <path> The directory to clone MCP server repositories into.
#                         Defaults to ~/Code/mcp-servers/.
#   -y, --yes             Auto-approve all MCP tools for detected agents.
#                         Configures agents to skip permission prompts for MCP tools.
#   -h, --help            Show this help message.
#
# Agent discovery:
#   Automatically configures any agentic CLI with a config directory
#     - Claude Code: ~/.claude/
#     - Gemini CLI:  ~/.gemini/
#     - Codex:       ~/.codex/
#
# Purpose:
#   1. Sets up the following MCP servers in HTTP mode
#      (i.e. shared across all agents/repos):
#       - Zen MCP (local server, clink only - for cross-CLI orchestration)
#       - Qdrant MCP (local server, semantic memory with Docker backend)
#       - Sourcegraph MCP (local server wrapper for Sourcegraph.com public search)
#       - Semgrep MCP (local server, static analysis and security scanning)
#       - Serena MCP (local server, semantic code analysis and editing with LSP)
#       - Context7 MCP (remote Upstash server, always-fresh API docs)
#       - Tavily MCP (remote Tavily server, web search/extract/map/crawl)
#       - Brave MCP (remote Brave server, web/image/video/news search)
#   2. Sets up the following MCP servers in stdio mode
#      (i.e. each agent runs its own server)
#       - Filesystem MCP (necessary since only supports stdio transport)
#       - Fetch MCP (necessary since only supports stdio transport)
#       - Memory MCP (knowledge graph for persistent structured memory)
#       - Brave Search MCP (privacy-focused web search)
#   3. Connects coding agent CLI clients if their user-level config dir exists
#       (see discover_agents):
#       - Gemini CLI
#       - Claude Code
#       - Codex

set -e  # exit on error

# --- CONFIG ---

# Determine relevant paths (best if it contains all projects you want to use these agents with)
PROJECTS_DIR="$HOME/Code"
CLONE_DIR="$PROJECTS_DIR/mcp-servers"

# Where to place needed clones of MCP server repos
export SOURCEGRAPH_REPO_PATH="$CLONE_DIR/sourcegraph-mcp"
export SERENA_REPO_PATH="$CLONE_DIR/serena"

SERVER_START_TIMEOUT=200  # timeout when waiting for any server/daemon to start
RANCHER_TIMEOUT=120       # timeout specific for Rancher Desktop startup (can take a while)

# Remote server URLs
export SOURCEGRAPH_ENDPOINT="https://sourcegraph.com"
export CONTEXT7_URL="https://mcp.context7.com/mcp"
export TAVILY_URL="https://mcp.tavily.com/mcp/?tavilyApiKey=${TAVILY_API_KEY}"

# Zen MCP: disable all tools except clink (since they need an API key)
export ZEN_CLINK_DISABLED_TOOLS='analyze,apilookup,challenge,chat,codereview,consensus,debug,docgen,planner,precommit,refactor,secaudit,testgen,thinkdeep,tracer'

# Ports for local HTTP servers
export QDRANT_DB_PORT=8780
export ZEN_MCP_PORT=8781
export QDRANT_MCP_PORT=8782
export SOURCEGRAPH_MCP_PORT=8783
export SEMGREP_MCP_PORT=8784
export SERENA_MCP_PORT=8785

# Qdrant MCP: semantic memory configuration
export QDRANT_URL="http://127.0.0.1:$QDRANT_DB_PORT"
export QDRANT_COLLECTION_NAME="coding-memory"
export QDRANT_EMBEDDING_PROVIDER="fastembed"
export QDRANT_DATA_DIR="$PROJECTS_DIR/qdrant-data"

# Directories
FS_ALLOWED_DIR="${FS_ALLOWED_DIR:-$PROJECTS_DIR}"

# --- INTERNAL SCRIPT CONSTANTS ---

# For referencing adjacent files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source agent selection library
source "$REPO_ROOT/bin/lib/agent-selection.sh"

# Supported agents' printable string names 
CLAUDE="Claude Code"
CODEX="Codex"
GEMINI="Gemini CLI"

# User-level config locations for supported coding CLIs
GEMINI_CONFIG="$HOME/.gemini/settings.json"
CODEX_CONFIG="$HOME/.codex/config.toml"
CLAUDE_CONFIG="$HOME/.claude/settings.json"
CLAUDE_CLI_STATE="$HOME/.claude.json"

# Contains the list of agents to be configured by this script to use Beehive and its tools;
# Populated by discover_agents(); agentic CLIs above are added if their corresponding 
#   user-level config dir exists
AGENTS=()

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- ARGUMENT PARSING ---

AUTO_APPROVE_MCP=false

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -f|--fsdir)
        FS_ALLOWED_DIR="$2"
        shift # past argument
        shift # past value
        ;;

        -c|--clonedir)
        CLONE_DIR="$2"
        shift # past argument
        shift # past value
        ;;

        -y|--yes)
        AUTO_APPROVE_MCP=true
        shift # past argument
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

# Detect installed CLIs based on config directory existence (exits if none found, logs detected CLIs)
discover_agents

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

log_empty_line() {
    echo ""
}

log_divider_line() {
    echo "--------------------"
}

log_separator() {
    log_empty_line
    log_divider_line
    log_empty_line
}

# Check if a port is already in use 
# (If it is, it's assumed to be by what this script intends to launch on it)
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
    mkdir -p "$QDRANT_DATA_DIR"

    # Start new container
    log_info "Creating and starting Qdrant container..."

    # mappings:
    # - uses port $QDRANT_DB_PORT on host machine, 6333 within container
    # - maps the directory $QDRANT_DATA_DIR on host machine to `/qdrant/directory` 
    #   in the container's filesystem
    docker run -d \
        --name "$container_name" \
        -p "$QDRANT_DB_PORT:6333" \
        -v "$QDRANT_DATA_DIR:/qdrant/storage" \
        qdrant/qdrant >/dev/null

    sleep 2
    log_success "Qdrant container started on port $QDRANT_DB_PORT"
}

# Wait for a server process to open its port or exit (success/failure)
wait_for_server_startup() {
    local server_name=$1
    local pid=$2
    local port=$3
    local timeout=$4
    local log_file=$5
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        sleep 1
        elapsed=$((elapsed + 1))

        # Process exited - capture exit code and fail fast
        if ! kill -0 "$pid" 2>/dev/null; then
            local exit_code
            wait "$pid"
            exit_code=$?
            if [[ $exit_code -eq 0 ]]; then
                log_error "$server_name exited cleanly before opening port $port"
            else
                log_error "$server_name exited with code $exit_code before opening port $port"
            fi
            log_empty_line
            log_error "Log file saved at: $log_file"
            return 1
        fi

        # Port became available → server ready
        if check_port "$port"; then
            log_success "$server_name started (PID: $pid) after ${elapsed}s"
            return 0
        fi
    done

    log_error "$server_name did not open port $port within ${timeout}s (process still running)"
    log_empty_line
    log_error "Log file saved at: $log_file"
    return 1
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
        pid=$(lsof -ti:"$port" -sTCP:LISTEN | head -1)
        log_info "Using existing server (PID: $pid)"
        
        # Expands to `eval "SERVER_PID=1234"`, then executes that (global) assignment
        eval "$pid_var=$pid"
    else
        log_info "Starting $server_name on port $port with ${SERVER_START_TIMEOUT}sec timeout..."
        log_info "  → launch command: ${start_cmd[*]}"

        # Start tail first (waits for file creation)
        tail -f "$log_file" 2>/dev/null &
        local tail_pid=$!

        # Start server with output to log file (nohup ensures survival after terminal closes)
        nohup "${start_cmd[@]}" > "$log_file" 2>&1 &
        pid=$!

        local startup_ok=true
        if wait_for_server_startup "$server_name" "$pid" "$port" "$SERVER_START_TIMEOUT" "$log_file"; then
            eval "$pid_var=$pid"
        else
            startup_ok=false
        fi

        # Stop showing output
        kill "$tail_pid" 2>/dev/null

        # Wait for the process to be fully killed, while ignoring exit code (returns 143 after being killed)
        wait "$tail_pid" 2>/dev/null || true 

        if [[ "$startup_ok" == true ]]; then
            return 0
        else
            exit 1
        fi
    fi
}

# Add or update Gemini MCP entry (supports HTTP and stdio transports)
add_mcp_to_gemini() {
    local transport=$1
    local server_name=$2

    # shift past the args so that the remaining ones can be passed to the script at the end of the function
    shift 2

    mkdir -p "$HOME/.gemini"

    # Initialize file if it doesn't exist
    if [[ ! -f "$GEMINI_CONFIG" ]]; then
        echo '{"mcpServers":{}}' > "$GEMINI_CONFIG"
    fi

    # Check if server already exists
    # IMPORTANT: must check for `\"$server_name\": {`  since the string \"$server_name\" 
    #            may already exist in the `autoApprovedTools` array
    if grep -q "\"$server_name\": {" "$GEMINI_CONFIG" 2>/dev/null; then
        return 1
    fi

    python3 "$SCRIPT_DIR/add-mcp-to-gemini.py" "$transport" "$server_name" "$GEMINI_CONFIG" "$@"
}

# Add server to Codex config file
add_mcp_to_codex() {
    local server_name=$1
    local transport=$2
    shift 2

    mkdir -p "$HOME/.codex"
    [[ ! -f "$CODEX_CONFIG" ]] && touch "$CODEX_CONFIG"

    if grep -q "^\[mcp_servers.$server_name\]" "$CODEX_CONFIG" 2>/dev/null; then
        return 1  # Already exists
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
        "$GEMINI")
            # Use direct JSON manipulation to add server with headers
            add_mcp_to_gemini "http" "$server" "$url" "${headers[@]}"
            ;;
        "$CLAUDE")
            # Check user scope config directory for existing server
            if grep -q "\"$server\"" "$CLAUDE_CLI_STATE"; then
                return 1  # Already exists
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
            log_empty_line
            "${claude_cmd[@]}"
            ;;
        "$CODEX")
            # Codex HTTP mode doesn't support custom headers, only bearer_token
            # Skip if headers are required (usually checked by caller but repeat here for safety)
            if [[ ${#headers[@]} -gt 0 ]]; then
                return 2  # Cannot configure - headers not supported
            fi
            add_mcp_to_codex "$server" "http" "$url"
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
        "$GEMINI")
            add_mcp_to_gemini "stdio" "$server" "${cmd_args[@]}"
            ;;
        "$CLAUDE")
            # Check user scope config directory for existing server
            if grep -q "\"$server\"" "$CLAUDE_CLI_STATE"; then
                return 1 # Already exists
            fi

            echo "Adding $server as local stdio to Claude with the command:"
            local claude_cmd=(claude mcp add --transport stdio "$server" --scope user -- "${cmd_args[@]}")
            printf '  %q' "${claude_cmd[@]}"
            log_empty_line
            "${claude_cmd[@]}"
            ;;
        "$CODEX")
            add_mcp_to_codex "$server" "stdio" "${cmd_args[@]}" 
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
        log_info "Configuring $agent..."

        if [[ $agent == "$CODEX" && ${#headers[@]} -gt 0 ]]; then
            log_warning "Skipping setting up ${CODEX} with ${server} via HTTP since it does not support custom headers beyond bearer_token"
            return
        fi
        
        (add_http_mcp_to_agent "$agent" "$server" "$url" "${headers[@]}" && log_success "$agent configured") || log_warning "Already exists"
    done
}

# Configure all agents for stdio MCP server
setup_stdio_mcp() {
    local server=$1
    shift
    local cmd_args=("$@")

    log_info "Setting up $server (stdio - per-agent)..."

    for agent in "${AGENTS[@]}"; do
        log_info "Configuring $agent..."
        (add_stdio_mcp_to_agent "$agent" "$server" "${cmd_args[@]}" && log_success "$agent configured") || log_warning "Already exists"
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

    # Upgrade package if already installed; otherwise, install 
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

# Ensure a git repository is cloned to a target path
ensure_git_repo_cloned() {
    local repo_name=$1
    local repo_url=$2
    local target_path=$3
    local branch=${4:-""}  # Optional branch parameter

    log_info "Checking $repo_name availability..."

    if [[ -d "$target_path" ]]; then
        log_success "$repo_name repository found at $target_path"
        return 0
    fi

    log_warning "$repo_name repository not found at $target_path"
    log_info "Cloning $repo_name repository..."

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$target_path")"

    # Build git clone command with optional branch
    local clone_cmd=(git clone)
    if [[ -n "$branch" ]]; then
        clone_cmd+=(-b "$branch")
    fi
    clone_cmd+=("$repo_url" "$target_path")

    if "${clone_cmd[@]}"; then
        log_success "Repository cloned successfully"
        return 0
    else
        log_error "Failed to clone $repo_name repository"
        return 1
    fi
}

# Configure auto-approval for all agents
configure_auto_approve() {
    log_info "Configuring auto-approval for agents..."
    log_empty_line

    # Build list of MCP server names being configured
    local mcp_servers=()
    mcp_servers+=("zen" "qdrant" "semgrep" "fs" "fetch" "git" "memory" "playwright")

    # Add the other servers if they're available
    [[ "$SOURCEGRAPH_AVAILABLE" == true ]] && mcp_servers+=("sourcegraph")
    [[ "$SERENA_AVAILABLE" == true ]] && mcp_servers+=("serena")
    [[ "$CONTEXT7_AVAILABLE" == true ]] && mcp_servers+=("context7")
    [[ "$TAVILY_AVAILABLE" == true ]] && mcp_servers+=("tavily")
    [[ "$BRAVE_AVAILABLE" == true ]] && mcp_servers+=("brave")

    # Configure each agent
    for agent in "${AGENTS[@]}"; do
        log_info "→ Configuring $agent..."
        case "$agent" in
            "$CLAUDE")
                python3 "$SCRIPT_DIR/add-claude-auto-approvals.py" "$CLAUDE_CONFIG" "${mcp_servers[@]}"
                ;;
            "$CODEX")
                python3 "$SCRIPT_DIR/add-codex-auto-approvals.py" "$CODEX_CONFIG"
                ;;
            "$GEMINI")
                python3 "$SCRIPT_DIR/add-gemini-auto-approvals.py" "$GEMINI_CONFIG" "${mcp_servers[@]}"
                ;;
            *)
                log_warning "  Unknown agent: $agent (skipping)"
                ;;
        esac
    done

    log_empty_line
    log_success "Agent auto-approvals successfully configured."
    log_info "MCP tools will now be auto-approved without permission prompts"
}

# --- CHECK DEPENDENCIES ---

log_info "Checking dependencies..."

check_dependency "npx" "Please install Node.js first."
check_dependency "uvx" "Please install uv first: https://docs.astral.sh/uv/getting-started/installation/" \
    "uvx found, will use for Fetch MCP (stdio mode)"
check_dependency "docker" "Please install Docker first: https://docs.docker.com/get-docker/" \
    "docker found, will use for Qdrant container"

if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    check_dependency "brew" "Please install Homebrew first: https://brew.sh/" \
        "brew found, will use for Semgrep installation"

    # idempotently install Semgrep binary (used to launch MCP)
    brew install semgrep
elif [[ "$(uname)" == "Linux" ]]; then
    # Linux
    log_info "Installing Semgrep via uv..."
    uv tool install semgrep
else 
    log_error "You are on an unsupported OS!"
    exit 1
fi

log_success "Dependency check complete."

log_info "Checking/installing optional tools..."
log_empty_line
log_info "→ Installing/checking for update for GitHub Spec Kit CLI..."
install_or_update_pip_pkg_from_git "https://github.com/github/spec-kit.git" "specify-cli"

log_info "Checking API keys..."

CONTEXT7_AVAILABLE=false
TAVILY_AVAILABLE=false
BRAVE_AVAILABLE=false
SOURCEGRAPH_AVAILABLE=false

if check_env_var "CONTEXT7_API_KEY" "Context7 MCP will not work. Get a key at https://console.upstash.com/"; then
    CONTEXT7_AVAILABLE=true
fi

if check_env_var "TAVILY_API_KEY" "Tavily MCP will not work. Get a key at https://www.tavily.com/"; then
    TAVILY_AVAILABLE=true
fi

if check_env_var "BRAVE_API_KEY" "Brave Search MCP will not work. Get a key at https://brave.com/search/api/"; then
    BRAVE_AVAILABLE=true
fi

log_success "API key check complete."

# Check if Sourcegraph MCP repo is available (must be cloned from GitHub)
if ensure_git_repo_cloned "Sourcegraph MCP" "https://github.com/akbad/sourcegraph-mcp.git" "$SOURCEGRAPH_REPO_PATH" "fix/server-startup"; then
    SOURCEGRAPH_AVAILABLE=true
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

# Check if Serena repo is available (must be cloned from GitHub)
SERENA_AVAILABLE=false
if ensure_git_repo_cloned "Serena" "https://github.com/oraios/serena" "$SERENA_REPO_PATH"; then
    SERENA_AVAILABLE=true
fi

# Configure MCP auto-approvals if requested
if [[ "$AUTO_APPROVE_MCP" == true ]]; then
    log_separator
    configure_auto_approve
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
    FASTMCP_SERVER_PORT="$QDRANT_MCP_PORT" \
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

# Serena MCP (semantic code analysis and editing)
if [[ "$SERENA_AVAILABLE" == true ]]; then
    start_http_server "Serena MCP" "$SERENA_MCP_PORT" "SERENA_PID" \
        uv run --directory "$SERENA_REPO_PATH" --python 3.11 serena start-mcp-server --transport streamable-http --port "$SERENA_MCP_PORT"
fi

# ============================================================================
#   Configure agents to use MCP servers
# ============================================================================

# Servers to use in HTTP mode
# - Zen MCP (local, clink)
# - Qdrant MCP (local)
# - Sourcegraph MCP (local wrapper for Sourcegraph.com)
# - Semgrep MCP (local)
# - Serena MCP (local, semantic code analysis and editing)
# - Context7 MCP (remote Upstash - for Gemini & Claude only)
# - Tavily MCP (remote Tavily - all agents)
log_separator
log_info "Configuring agents to use Zen MCP for clink (HTTP)..."
setup_http_mcp "zen" "http://localhost:$ZEN_MCP_PORT/mcp/"

log_separator
log_info "Configuring agents to use Qdrant MCP (HTTP)..."
setup_http_mcp "qdrant" "http://localhost:$QDRANT_MCP_PORT/mcp/"

if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    log_separator
    log_info "Configuring agents to use Sourcegraph MCP (HTTP - local wrapper for Sourcegraph.com)..."
    setup_http_mcp "sourcegraph" "http://localhost:$SOURCEGRAPH_MCP_PORT/sourcegraph/mcp/"
fi

log_separator
log_info "Configuring agents to use Semgrep MCP (HTTP)..."
setup_http_mcp "semgrep" "http://localhost:$SEMGREP_MCP_PORT/mcp/"

if [[ "$SERENA_AVAILABLE" == true ]]; then
    log_separator
    log_info "Configuring agents to use Serena MCP (HTTP - local semantic code analysis)..."
    setup_http_mcp "serena" "http://localhost:$SERENA_MCP_PORT/mcp/"
fi

if [[ "$CONTEXT7_AVAILABLE" == true ]] && (agent_enabled "$GEMINI" || agent_enabled "$CLAUDE"); then
    log_separator
    log_info "Configuring Gemini and/or Claude to use Context7 MCP (HTTP - remote Upstash)..."
    # Note: Uses colon format for headers
    # Codex will use stdio mode (configured below) since HTTP doesn't support custom headers
    # Gemini requires both CONTEXT7_API_KEY and Accept headers
    setup_http_mcp "context7" "$CONTEXT7_URL" "CONTEXT7_API_KEY:${CONTEXT7_API_KEY}" "Accept:application/json, text/event-stream"
fi

if [[ "$TAVILY_AVAILABLE" == true ]]; then
    log_separator
    log_info "Configuring all agents to use Tavily MCP (HTTP - remote)..."
    # Tavily uses API key in URL query parameter, so no custom headers needed
    setup_http_mcp "tavily" "$TAVILY_URL"
fi


# Servers to use in stdio mode
# - Filesystem MCP (per-agent, filtered to read_multiple_files only via mcp-filter)
# - Fetch MCP (per-agent, only supports stdio transport)
# - Context7 MCP (for Codex only, since Codex HTTP doesn't support custom headers)
log_separator
log_info "Configuring agents to use Filesystem MCP (stdio, filtered to read_multiple_files only)..."
log_info "Allowed directory for Filesystem MCP: $FS_ALLOWED_DIR"
setup_stdio_mcp "fs" "npx" "-y" "mcp-filter" "-s" "npx -y @modelcontextprotocol/server-filesystem $FS_ALLOWED_DIR" "-a" "read_multiple_files"

log_separator
log_info "Configuring agents to use Fetch MCP (stdio)..."
setup_stdio_mcp "fetch" "uvx" "mcp-server-fetch"

log_separator
log_info "Configuring agents to use Memory MCP (stdio)..."
setup_stdio_mcp "memory" "npx" "-y" "@modelcontextprotocol/server-memory"

log_separator
log_info "Configuring agents to use Playwright MCP (stdio)..."
setup_stdio_mcp "playwright" "npx" "-y" "@playwright/mcp@latest"

if [[ "$BRAVE_AVAILABLE" == true ]]; then
    log_separator
    log_info "Configuring agents to use Brave Search MCP (stdio)..."
    setup_stdio_mcp "brave" "env" "BRAVE_API_KEY=$BRAVE_API_KEY" "npx" "-y" "@brave/brave-search-mcp-server" "--transport" "stdio"
fi

if [[ "$CONTEXT7_AVAILABLE" == true ]] && agent_enabled "$CODEX"; then
    log_separator
    log_info "Configuring Codex to use Context7 MCP (stdio)..."
    (add_stdio_mcp_to_agent "$CODEX" "context7" "npx" "-y" "@upstash/context7-mcp" "--api-key" "\$CONTEXT7_API_KEY") || log_warning "Already exists"
fi

# ============================================================================
#   Completion output
# ============================================================================

log_empty_line
log_success "Setup complete."
log_empty_line
log_info "Local HTTP servers running:"
log_info "  • Zen MCP (clink only): http://localhost:$ZEN_MCP_PORT/mcp/ (PID: $ZEN_PID)"
log_info "  • Qdrant MCP: http://localhost:$QDRANT_MCP_PORT/mcp/ (PID: $QDRANT_PID)"
log_info "    └─ Backend: Qdrant Docker container on port $QDRANT_DB_PORT"
log_info "    └─ Data directory: $QDRANT_DATA_DIR"

if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    log_info "  • Sourcegraph MCP: http://localhost:$SOURCEGRAPH_MCP_PORT/sourcegraph/mcp/ (PID: $SOURCEGRAPH_PID)"
    log_info "    └─ Endpoint: $SOURCEGRAPH_ENDPOINT (free public search)"
    log_info "    └─ Repository: $SOURCEGRAPH_REPO_PATH"
fi

log_info "  • Semgrep MCP: http://localhost:$SEMGREP_MCP_PORT/mcp/ (PID: $SEMGREP_PID)"
log_info "    └─ Static analysis and security scanning (5000+ rules)"

if [[ "$SERENA_AVAILABLE" == true ]]; then
    log_info "  • Serena MCP: http://localhost:$SERENA_MCP_PORT/mcp/ (PID: $SERENA_PID)"
    log_info "    └─ Semantic code analysis and editing with LSP integration"
    log_info "    └─ Repository: $SERENA_REPO_PATH"
fi

log_empty_line

# Only show remote servers section if at least one is configured
if [[ "$CONTEXT7_AVAILABLE" == true || "$TAVILY_AVAILABLE" == true ]]; then
    log_info "Remote HTTP servers configured:"

    if [[ "$CONTEXT7_AVAILABLE" == true ]]; then
        log_info "  • Context7 MCP: $CONTEXT7_URL"
        agent_enabled "$GEMINI" && log_info "    └─ Gemini: Headers configured automatically in ~/.gemini/settings.json"
        agent_enabled "$CLAUDE" && log_info "    └─ Claude: Header configured automatically via CLI"
        agent_enabled "$CODEX"  && log_info "    └─ Codex: Using stdio mode instead (HTTP doesn't support custom headers)"
    fi

    if [[ "$TAVILY_AVAILABLE" == true ]]; then
        log_info "  • Tavily MCP: https://mcp.tavily.com/mcp/"
        log_info "    └─ All agents: Configured via HTTP with API key in URL"
    fi

    log_empty_line
fi

log_info "Configured stdio servers:"
log_info "  → Each agent starts its own server when launched, stops when exited."
log_info "  • Filesystem MCP (all agents)"
log_info "    └─ Filtered to read_multiple_files only (30-60% token savings on bulk reads)"
log_info "    └─ Allowed directory: $FS_ALLOWED_DIR"
log_info "  • Fetch MCP (all agents)"
log_info "    └─ HTML to Markdown conversion"
log_info "  • Memory MCP (all agents)"
log_info "    └─ Knowledge graph for persistent structured memory (entities, relations, observations)"
log_info "  • Playwright MCP (all agents)"
log_info "    └─ Browser automation and UI interaction via Playwright"

if [[ "$BRAVE_AVAILABLE" == true ]]; then
    log_info "  • Brave Search MCP (all agents)"
    log_info "    └─ Privacy-focused web search (2,000 queries/month free)"
fi

if [[ "$CONTEXT7_AVAILABLE" == true ]] && agent_enabled "$CODEX"; then
    log_info "  • Context7 MCP (Codex only)"
    log_info "    └─ Codex HTTP doesn't support custom headers, so using stdio mode"
fi

log_empty_line
log_info "Logs:"
log_info "  • Zen MCP: /tmp/mcp-Zen MCP-server.log"
log_info "  • Qdrant MCP: /tmp/mcp-Qdrant MCP-server.log"
log_info "  • Qdrant Docker: docker logs qdrant"

if [[ "$SOURCEGRAPH_AVAILABLE" == true ]]; then
    log_info "  • Sourcegraph MCP: /tmp/mcp-Sourcegraph MCP-server.log"
fi

log_info "  • Semgrep MCP: /tmp/mcp-Semgrep MCP-server.log"

if [[ "$SERENA_AVAILABLE" == true ]]; then
    log_info "  • Serena MCP: /tmp/mcp-Serena MCP-server.log"
fi

if agent_enabled "OpenCode"; then
    log_separator
    log_info "Syncing OpenCode MCP config"
    TEMPLATE_OC="$REPO_ROOT/configs/config/templates/opencode.json"
    GENERATED_OC="$REPO_ROOT/configs/config/generated/opencode.generated.json"
    TARGET_OC="$HOME/.config/opencode/opencode.json"

    if [[ -f "$TEMPLATE_OC" ]]; then
        mkdir -p "$(dirname "$GENERATED_OC")"
        if ! sed "s|{{REPO_ROOT}}|$REPO_ROOT|g" "$TEMPLATE_OC" > "$GENERATED_OC"; then
            log_warning "Failed to render OpenCode template; skipping OpenCode sync"
            GENERATED_OC=""
        fi
        mkdir -p "$(dirname "$TARGET_OC")"

        if [[ -n "$GENERATED_OC" && -f "$GENERATED_OC" ]]; then
            if PYTHONPATH="$REPO_ROOT/lib" python3 "$SCRIPT_DIR/configure-opencode.py" --target "$TARGET_OC" --generated "$GENERATED_OC"; then
                log_success "OpenCode config merged into $TARGET_OC (preserved user overrides)"
            else
                log_warning "OpenCode merge failed; leaving $TARGET_OC unchanged"
            fi
        else
            log_warning "OpenCode template render failed or generated file missing; skipping OpenCode sync"
        fi
    else
        log_warning "OpenCode config template not found at $TEMPLATE_OC; skipping OpenCode sync"
    fi
fi

if agent_enabled "$CODEX"; then
    log_separator
    log_info "Ensuring Superpowers skills are installed for Codex..."
    "$SCRIPT_DIR/../../agents/scripts/set-up-codex-superpowers.sh"
fi

log_empty_line
log_info "To verify setup:"
log_info "  1. cd into a git repo"
log_info "  2. Run 'gemini', 'claude', or 'codex', according to which CLI(s) you have available"
log_info "  3. Type '/mcp' to see available tools"

# Build running PID list in startup order, only including set PIDs
log_empty_line
log_info "To stop local HTTP servers:"
pidlist=""
[[ -n "$ZEN_PID" ]] && pidlist+=" $ZEN_PID"
[[ -n "$QDRANT_PID" ]] && pidlist+=" $QDRANT_PID"
[[ "$SOURCEGRAPH_AVAILABLE" == "true" && -n "$SOURCEGRAPH_PID" ]] && pidlist+=" $SOURCEGRAPH_PID"
[[ -n "$SEMGREP_PID" ]] && pidlist+=" $SEMGREP_PID"
[[ "$SERENA_AVAILABLE" == "true" && -n "$SERENA_PID" ]] && pidlist+=" $SERENA_PID"

# Trim leading space and create kill command
pidlist="${pidlist# }"
KILL_HTTPS_CMD="kill ${pidlist}"
log_info "  $KILL_HTTPS_CMD"

log_empty_line
QDRANT_STOP_CMD="docker stop qdrant"
log_info "To stop Qdrant Docker container:"
log_info "  $QDRANT_STOP_CMD"

log_empty_line
TAKE_DOWN_FILE="$REPO_ROOT/bin/stop-beehive"
echo "#!/usr/bin/env bash" > "$TAKE_DOWN_FILE"
echo -e "# Run this script to stop servers and containers launched by Beehive's tools script\n" >> "$TAKE_DOWN_FILE"
echo -e "$KILL_HTTPS_CMD\n$QDRANT_STOP_CMD" >> "$TAKE_DOWN_FILE"
log_info "✔︎ Stop commands also saved to $RED$TAKE_DOWN_FILE$NC for convenience"

if [[ "$AUTO_APPROVE_MCP" == true ]]; then
    log_empty_line
    log_success "All agents configured to auto-approve MCP tools (requested using -y/--yes option)"
    log_info "  → Updated: ~/.claude/settings.json"
    log_info "  → Updated: ~/.codex/config.toml"
    log_info "  → Updated: ~/.gemini/settings.json"
    log_info "  → MCP tools will no longer require permission prompts"
fi
