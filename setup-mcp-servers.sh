#!/bin/bash

# MCP server setup script
#
# Prerequisites:
#   - Node.js (for npx)
#   - uv/uvx (for Python packages)
#   - Context7 API key in $CONTEXT7_API_KEY
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
#      - Context7 MCP (remote Upstash server, always-fresh API docs)
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

# Ports for local HTTP servers
export FS_MCP_PORT=8080
export ZEN_MCP_PORT=8081
export FETCH_MCP_PORT=8082

# Remote server URLs
export CONTEXT7_URL="https://mcp.context7.com/mcp"

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
setup_agent_http() {
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
setup_agent_stdio() {
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
            (setup_agent_http "$agent" "$server" "$url" "${headers[@]}" && log_success "$agent configured") || log_warning "Already exists"
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

# Check for uvx (required for Git MCP and Zen MCP)
if ! command -v uvx &> /dev/null; then
    log_error "uvx not found. Please install uv first: https://docs.astral.sh/uv/getting-started/installation/"
    exit 1
fi
log_info "uvx found, will use for Git MCP (stdio mode) and Zen MCP"

log_success "Dependency check complete."

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

# ============================================================================
#   Configure agents to use MCP servers
# ============================================================================

# Servers to use in HTTP mode
# - Filesystem MCP (local)
# - Zen MCP (local, clink)
# - Fetch MCP (local)
# - Context7 MCP (remote Upstash - for Gemini & Claude only)
log_info "Configuring agents to use Filesystem MCP (HTTP)..."
setup_http_mcp "fs" "http://localhost:$FS_MCP_PORT/mcp/"

log_info "Configuring agents to use Zen MCP for clink (HTTP)..."
setup_http_mcp "zen" "http://localhost:$ZEN_MCP_PORT/mcp/"

log_info "Configuring agents to use Fetch MCP (HTTP)..."
setup_http_mcp "fetch" "http://localhost:$FETCH_MCP_PORT/mcp/"

log_info "Configuring Gemini & Claude to use Context7 MCP (HTTP - remote Upstash)..."
# Note: Uses colon format for headers
# Codex will use stdio mode (configured below) since HTTP doesn't support custom headers
# Gemini requires both CONTEXT7_API_KEY and Accept headers
setup_http_mcp "context7" "$CONTEXT7_URL" "CONTEXT7_API_KEY:\$CONTEXT7_API_KEY" "Accept:application/json, text/event-stream"

# Servers to use in stdio mode
# - Git MCP (per-agent)
# - Context7 MCP (for Codex only, since Codex HTTP doesn't support custom headers)
log_info "Configuring agents to use Git MCP (stdio)..."
setup_stdio_mcp "git" "uvx" "mcp-server-git" "--repository" "."

log_info "Configuring Codex to use Context7 MCP (stdio)..."
setup_agent_stdio "codex" "context7" "npx" "-y" "@upstash/context7-mcp" "--api-key" "\$CONTEXT7_API_KEY"

# ============================================================================
#   Completion output
# ============================================================================

echo ""
log_success "Setup complete."
echo ""
log_info "Local HTTP servers running:"
log_info "  • Filesystem MCP: http://localhost:$FS_MCP_PORT/mcp/ (PID: $FS_PID)"
log_info "    └─ Shared across all agents, allowed dir: $FS_ALLOWED_DIR"
log_info "  • Zen MCP (clink): http://localhost:$ZEN_MCP_PORT/mcp/ (PID: $ZEN_PID)"
log_info "    └─ Cross-CLI orchestration (only 'clink' tool enabled)"
log_info "  • Fetch MCP: http://localhost:$FETCH_MCP_PORT/mcp/ (PID: $FETCH_PID)"
log_info "    └─ HTML to Markdown conversion for web content"
echo ""
log_info "Remote HTTP servers configured:"
log_info "  • Context7 MCP: $CONTEXT7_URL"
log_info "    └─ Always-fresh API docs (remote Upstash server)"
log_info "    └─ Requires CONTEXT7_API_KEY in environment (already set in your .zshrc)"
log_info "    └─ Gemini: Headers configured automatically in ~/.gemini/settings.json"
log_info "    └─ Claude: Header configured automatically via CLI"
log_info "    └─ Codex: Using stdio mode instead (HTTP doesn't support custom headers)"
echo ""
log_info "Configured stdio servers:"
log_info "  → Each agent starts its own server when launched, stops when exited."
log_info "  • Git MCP (all agents)"
log_info "    └─ Uses current directory when agent is launched"
log_info "  • Context7 MCP (Codex only)"
log_info "    └─ Codex HTTP doesn't support custom headers, so using stdio mode"
echo ""
log_info "Logs:"
log_info "  • Filesystem: /tmp/mcp-Filesystem MCP-server.log"
log_info "  • Zen MCP: /tmp/mcp-Zen MCP-server.log"
log_info "  • Fetch MCP: /tmp/mcp-Fetch MCP-server.log"
echo ""
log_info "To verify setup:"
log_info "  1. cd into a git repo"
log_info "  2. Run 'gemini', 'claude', or 'codex'"
log_info "  3. Type '/mcp' to see available tools"
echo ""
log_info "To stop local HTTP servers:"
log_info "  kill $FS_PID $ZEN_PID $FETCH_PID"

