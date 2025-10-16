#!/bin/bash

# MCP server setup script
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
#      - Filesystem MCP
#      - Zen MCP (clink only - for cross-CLI orchestration)
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

# Agent CLIs we support
AGENTS=("gemini" "claude" "codex")

# Ports
export FS_MCP_PORT=8080
export ZEN_MCP_PORT=8081

# Zen MCP: disable all tools except clink
export ZEN_CLINK_DISABLED_TOOLS='analyze,apilookup,challenge,chat,codereview,consensus,debug,docgen,planner,precommit,refactor,secaudit,testgen,thinkdeep,tracer'

# Directories
FS_ALLOWED_DIR="${FS_ALLOWED_DIR:-$HOME/Code}"

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

# Start HTTP server idempotently (returns PID via variable name passed as arg)
start_http_server() {
    local server_name=$1
    local port=$2
    local pid_var=$3  # Variable name to store PID
    shift 3
    local start_cmd=("$@")
    local log_file="/tmp/mcp-${server_name}-server.log"

    if check_port "$port"; then
        log_success "$server_name already running on port $port"
        local pid=$(lsof -ti:"$port")
        log_info "Using existing server (PID: $pid)"
        eval "$pid_var=$pid"
    else
        log_info "Starting $server_name on port $port..."
        nohup "${start_cmd[@]}" > "$log_file" 2>&1 &
        local pid=$!
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
        cat >> "$config_file" << EOF

[mcp_servers.$server_name]
url = "$1"
transport = "http"
EOF
    else
        local cmd_args=("$@")
        cat >> "$config_file" << EOF

[mcp_servers.$server_name]
command = "${cmd_args[0]}"
args = [$(printf '"%s", ' "${cmd_args[@]:1}" | sed 's/, $//')]
transport = "stdio"
EOF
    fi
}

# Configure single agent for HTTP MCP
setup_agent_http() {
    local agent=$1
    local server=$2
    local url=$3

    case $agent in
        gemini)
            gemini mcp add "$server" http --url "$url" 2>/dev/null
            ;;
        claude)
            claude mcp add --transport http "$server" "$url" 2>/dev/null
            ;;
        codex)
            add_to_codex "$server" "http" "$url"
            ;;
    esac
}

# Configure single agent for stdio MCP
setup_agent_stdio() {
    local agent=$1
    local server=$2
    shift 2
    local cmd_args=("$@")

    case $agent in
        gemini)
            gemini mcp add "$server" "${cmd_args[@]}" 2>/dev/null
            ;;
        claude)
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

    log_info "Setting up $server (HTTP - shared)..."

    for agent in "${AGENTS[@]}"; do
        # No Codex CLI command for HTTP servers; must use config file
        if [[ "$agent" == "codex" ]] || command -v "$agent" &> /dev/null; then
            log_info "Configuring $agent..."
            (setup_agent_http "$agent" "$server" "$url" && log_success "$agent configured") || log_warning "Already exists"
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
            (setup_agent_stdio "$agent" "$server" "${cmd_args[@]}" && log_success "$agent configured") || log_warning "Already exists"
        else
            log_warning "$agent not found, skipping..."
        fi
    done
}

# --- CHECK DEPENDENCIES ---

log_info "Checking dependencies..."

# Check for npx (needed for Filesystem server)
if ! command -v npx &> /dev/null; then
    log_error "npx not found. Please install Node.js first."
    exit 1
fi

# Check for uvx (recommended) or Python for Git MCP server
if ! command -v uvx &> /dev/null; then
    log_warning "uvx not found. Agents will need mcp-server-git installed via pip."
    if command -v python3 &> /dev/null || command -v python &> /dev/null; then
        log_info "Python found. Run: pip install mcp-server-git"
    else
        log_warning "Python not found. Install Python 3.10+ and run: pip install mcp-server-git"
    fi
else
    log_info "uvx found, will configure agents to use it for Git MCP (stdio mode)"
fi

log_success "Dependencies checked"

# ============================================================================
#   Start central HTTP servers
# ============================================================================

log_info "Idempotently starting up HTTP MCP servers..."

# Filesystem MCP
log_info "Allowed directory: $FS_ALLOWED_DIR"
start_http_server "Filesystem MCP" "$FS_MCP_PORT" "FS_PID" \
    npx -y @modelcontextprotocol/server-filesystem --port "$FS_MCP_PORT" "$FS_ALLOWED_DIR"

# Zen MCP (clink only - zero-API hub for cross-CLI orchestration)
start_http_server "Zen MCP" "$ZEN_MCP_PORT" "ZEN_PID" \
    env DISABLED_TOOLS="$ZEN_CLINK_DISABLED_TOOLS" ZEN_MCP_PORT="$ZEN_MCP_PORT" \
    uvx --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git \
    python "$SCRIPT_DIR/start-zen-http.py"

# ============================================================================
#   Configure agents to use MCP servers
# ============================================================================

# Servers to use in HTTP mode
# - Filesystem MCP
# - Zen MCP (clink)
log_info "Configuring agents to use Filesystem MCP (HTTP)..."
setup_http_mcp "fs" "http://localhost:$FS_MCP_PORT/mcp/"

log_info "Configuring agents to use Zen MCP for clink (HTTP)..."
setup_http_mcp "zen" "http://localhost:$ZEN_MCP_PORT/mcp/"

# Servers to use in stdio mode
# Git MCP (stdio mode - per-agent)
log_info "Configuring agents to use Git MCP (stdio)..."
setup_stdio_mcp "git" "uvx" "mcp-server-git" "--repository" "."

# ============================================================================
#   Completion output
# ============================================================================

echo ""
log_success "Setup complete."
echo ""
log_info "Central HTTP servers running:"
log_info "  • Filesystem MCP: http://localhost:$FS_MCP_PORT/mcp/ (PID: $FS_PID)"
log_info "    └─ Shared across all agents, allowed dir: $FS_ALLOWED_DIR"
log_info "  • Zen MCP (clink): http://localhost:$ZEN_MCP_PORT/mcp/ (PID: $ZEN_PID)"
log_info "    └─ Cross-CLI orchestration (only 'clink' tool enabled)"
echo ""
log_info "Configured stdio servers:"
log_info " -> Each agent will start its own server when launched, and stop it when it's exited."
log_info " • Git MCP server"
log_info "   └─ Uses current directory when agent is launched"
echo ""
log_info "Logs:"
log_info "  • Filesystem: /tmp/mcp-Filesystem MCP-server.log"
log_info "  • Zen MCP: /tmp/mcp-Zen MCP-server.log"
echo ""
log_info "To verify setup:"
log_info "  1. cd into a git repo"
log_info "  2. Run 'gemini', 'claude', or 'codex'"
log_info "  3. Type '/mcp' to see available tools"
echo ""
log_info "To stop HTTP servers:"
log_info "  kill $FS_PID $ZEN_PID"

