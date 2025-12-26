#!/usr/bin/env bash

# Agent selection library
# > Determines enabled agents (based on YML configs)
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

# Get repo root (for calling Python modules)
_get_repo_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # running in bin/lib -> repo root is two levels up
    dirname "$(dirname "$script_dir")"
}

# Internal: call get-config Python module 
#   (caller must ensure env is setup, i.e. by running check-prereqs)
# Usage: _get_config <args...>
_get_config() {
    local repo_root
    repo_root="$(_get_repo_root)"
    (cd "$repo_root" && uv run get-config "$@")
}

declare -A AGENT_MAP=(
  ["Claude Code"]="claude"
  ["Gemini CLI"]="gemini"
  ["Codex"]="codex"
  ["OpenCode"]="opencode"
)

_agent_config_name() {
    local agent_name="$1"
    echo "${AGENT_MAP[$agent_name]:-}"
}

_agent_display_name() {
    local config_name="$1"
    local name
    for name in "${!AGENT_MAP[@]}"; do
        if [[ "${AGENT_MAP[$name]}" == "$config_name" ]]; then
            echo "$name"
            return
        fi
    done
    echo ""
}

# Check if an agent is enabled in directives.yml
# Usage: agent_enabled "Claude Code"
# Returns: 0 if enabled, 1 if not
agent_enabled() {
    local agent_name="$1"
    local config_name

    config_name="$(_agent_config_name "$agent_name")"
    if [[ -z "$config_name" ]]; then
        log_error "Unknown agent: $agent_name"
        return 1
    fi

    _get_config --check agent "$config_name"
}

# Load list of enabled agents into AGENTS array
# Usage: discover_agents
# Sets: AGENTS array with display names of all enabled agents
# Exits with error if no agents are configured
# Logs detected agents to stdout
discover_agents() {
    AGENTS=()

    local enabled_list
    if ! enabled_list="$(_get_config --list agents 2>&1)"; then
        log_error "Failed to read config: $enabled_list"
        exit 1
    fi

    if [[ -z "$enabled_list" ]]; then
        log_error "No agents enabled in directives.yml!"
        echo ""
        echo "Enable agents by editing directives.yml:"
        echo ""
        echo "  agents:"
        echo "    - claude"
        echo "    - gemini"
        echo "    - codex"
        echo "    - opencode"
        echo ""
        echo "Then re-run this script."
        exit 1
    fi

    # Convert config names to display names
    for config_name in $enabled_list; do
        local display_name
        display_name="$(_agent_display_name "$config_name")"
        if [[ -n "$display_name" ]]; then
            AGENTS+=("$display_name")
        fi
    done

    if [[ ${#AGENTS[@]} -eq 0 ]]; then
        log_error "No valid agents found in directives.yml configuration"
        exit 1
    fi

    # Log detected agents
    local formatted_agents
    formatted_agents=$( (IFS=', '; echo "${AGENTS[*]}") )
    log_info "Enabled agents (from directives.yml): ${formatted_agents}"

    return 0
}
