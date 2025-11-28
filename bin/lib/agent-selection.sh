#!/usr/bin/env bash

# Agent selection library
# > Simple directory-based detection for installed CLIs
# > Used across all setup scripts to determine agents to configure

# Agent name constants
CLAUDE="Claude Code"
CODEX="Codex"
GEMINI="Gemini CLI"
OPENCODE="OpenCode"

# Colors for logging (define individually if not already set)
[[ -z "${GREEN:-}" ]] && GREEN='\033[0;32m'
[[ -z "${BLUE:-}" ]] && BLUE='\033[0;34m'
[[ -z "${YELLOW:-}" ]] && YELLOW='\033[1;33m'
[[ -z "${RED:-}" ]] && RED='\033[0;31m'
[[ -z "${NC:-}" ]] && NC='\033[0m'

# Logging functions (use existing if defined, otherwise define minimal versions)
if ! declare -f log_info >/dev/null 2>&1; then
    log_info() {
        echo -e "${BLUE}[INFO]${NC} $1"
    }
fi

if ! declare -f log_success >/dev/null 2>&1; then
    log_success() {
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    }
fi

if ! declare -f log_warning >/dev/null 2>&1; then
    log_warning() {
        echo -e "${YELLOW}[WARNING]${NC} $1"
    }
fi

if ! declare -f log_error >/dev/null 2>&1; then
    log_error() {
        echo -e "${RED}[ERROR]${NC} $1"
    }
fi

# Check if an agent is enabled (installed) based on config directory existence
# Usage: agent_enabled "Claude Code"
# Returns: 0 if enabled, 1 if not
agent_enabled() {
    local agent_name="$1"

    case "$agent_name" in
        "Claude Code")
            [[ -d "$HOME/.claude" ]]
            ;;
        "Gemini CLI")
            [[ -d "$HOME/.gemini" ]]
            ;;
        "Codex")
            [[ -d "$HOME/.codex" ]]
            ;;
        "OpenCode")
            [[ -d "$HOME/.config/opencode" || -d "$HOME/.opencode" ]]
            ;;
        *)
            log_error "Unknown agent: $agent_name"
            return 1
            ;;
    esac
}

# Load list of enabled agents into AGENTS array
# Usage: discover_agents
# Sets: AGENTS array with names of all enabled agents
# Exits with error if no agents are detected
# Logs detected agents to stdout
discover_agents() {
    AGENTS=()

    agent_enabled "$CLAUDE" && AGENTS+=("$CLAUDE")
    agent_enabled "$GEMINI" && AGENTS+=("$GEMINI")
    agent_enabled "$CODEX" && AGENTS+=("$CODEX")
    agent_enabled "$OPENCODE" && AGENTS+=("$OPENCODE")

    if [[ ${#AGENTS[@]} -eq 0 ]]; then
        log_error "No CLI config directories found!"
        echo ""
        echo "Create a config directory for each CLI you want to configure:"
        echo "  - Claude Code: mkdir -p ~/.claude"
        echo "  - Gemini CLI:  mkdir -p ~/.gemini"
        echo "  - Codex:       mkdir -p ~/.codex"
        echo "  - OpenCode:    mkdir -p ~/.config/opencode"
        echo ""
        echo "Then re-run this script."
        exit 1
    fi

    # Log detected agents
    local formatted_agents
    formatted_agents=$( (IFS=', '; echo "${AGENTS[*]}") )
    log_info "Detected installed CLIs: ${formatted_agents}"

    return 0
}
