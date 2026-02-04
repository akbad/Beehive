#!/usr/bin/env bash
#
# Bureau logging library
#
# Provides consistent, colorized logging functions for all Bureau scripts.
#
# Usage:
#   source "$REPO_ROOT/bin/lib/logging.sh"
#
# Available functions:
#   log_info "message"       - Blue [INFO] prefix
#   log_success "message"    - Green ✓ prefix
#   log_warning "message"    - Yellow ⚠ prefix
#   log_error "message"      - Red ✗ prefix
#   log_debug "message"      - Gray [DEBUG] prefix (only if LOG_DEBUG=true)
#   log_action "verb" "obj"  - Blue verb, white object
#   log_header "title" "path" ["note1" "note2" ...]  - Section headers
#   log_empty_line           - Blank line
#   log_divider              - Horizontal rule
#   log_separator            - Empty + divider + empty
#   log_banner "title"       - Banner with dividers
#
# Environment variables:
#   LOG_COLORS=false         - Disable all colors (for CI/logs)
#   LOG_DEBUG=true           - Enable debug messages
#   LOG_QUIET=true           - Suppress info messages (warnings/errors only)

# Color codes (ANSI escape sequences)
if [[ "${LOG_COLORS:-true}" == "true" && -t 1 ]]; then
    # Terminal supports colors and user hasn't disabled them
    export LOG_GREEN='\033[0;32m'
    export LOG_BLUE='\033[0;34m'
    export LOG_YELLOW='\033[1;33m'
    export LOG_RED='\033[0;31m'
    export LOG_GRAY='\033[0;90m'
    export LOG_BOLD='\033[1m'
    export LOG_NC='\033[0m'  # No Color (reset)
else
    # No color support or disabled
    export LOG_GREEN=''
    export LOG_BLUE=''
    export LOG_YELLOW=''
    export LOG_RED=''
    export LOG_GRAY=''
    export LOG_BOLD=''
    export LOG_NC=''
fi

# For backward compatibility, also export unprefixed versions
export GREEN="$LOG_GREEN"
export BLUE="$LOG_BLUE"
export YELLOW="$LOG_YELLOW"
export RED="$LOG_RED"
export NC="$LOG_NC"

# Core logging functions
log_info() {
    if [[ "${LOG_QUIET:-false}" == "true" ]]; then
        return 0
    fi
    echo -e "${LOG_BLUE}[INFO]${LOG_NC} $*"
}

log_success() {
    echo -e "${LOG_GREEN}✓${LOG_NC} $*"
}

log_warning() {
    echo -e "${LOG_YELLOW}⚠${LOG_NC} $*" >&2
}

log_error() {
    echo -e "${LOG_RED}✗${LOG_NC} $*" >&2
}

log_debug() {
    if [[ "${LOG_DEBUG:-false}" == "true" ]]; then
        echo -e "${LOG_GRAY}[DEBUG]${LOG_NC} $*"
    fi
}

# Action logging (verb + object pattern)
log_action() {
    local action=$1
    local detail=${2:-}  # Optional second argument
    echo -e "${LOG_BLUE}${action}${LOG_NC} ${detail}"
}

# Section headers (with optional notes in yellow)
log_header() {
    local label=$1
    local path=$2
    shift 2

    echo -e "${LOG_BLUE}${label}${LOG_NC} (${path})"
    for line in "$@"; do
        echo -e "  ${LOG_YELLOW}${line}${LOG_NC}"
    done
}

# Formatting helpers
log_empty_line() {
    echo ""
}

log_divider() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

log_separator() {
    log_empty_line
    log_divider
    log_empty_line
}

# Print a styled banner (for script headers)
log_banner() {
    local title=$1
    local padding="        "
    local divider_char="━"
    local line_len=$(( ${#title} + 16 ))

    local divider
    divider=$(printf '%*s' "$line_len" "" | tr ' ' "$divider_char")

    echo "$divider"
    echo "${padding}${title}${padding}"
    echo "$divider"
}

# Progress indicator (for long-running operations)
log_progress() {
    local current=$1
    local total=$2
    local message=${3:-""}

    local percent=$((current * 100 / total))
    local bar_width=30
    local filled=$((bar_width * current / total))
    local empty=$((bar_width - filled))

    # Build progress bar
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    echo -ne "\r${LOG_BLUE}[${bar}]${LOG_NC} ${percent}% ${message}"

    # Newline when complete
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# Print an (aligned) key-value pair
log_kv() {
    local key=$1
    local value=$2
    local key_width=${3:-20}

    printf "${LOG_GRAY}%-${key_width}s${LOG_NC} %s\n" "$key:" "$value"
}

# Prompt user for yes/no confirmation (returns 0 for yes, 1 for no)
log_confirm() {
    local prompt=$1
    local default=${2:-n}  # 'y' or 'n'

    local yn_prompt
    if [[ "$default" == "y" ]]; then
        yn_prompt="[Y/n]"
    else
        yn_prompt="[y/N]"
    fi

    echo -ne "${LOG_YELLOW}❓${LOG_NC} ${prompt} ${yn_prompt} "
    read -r response

    # Use default if empty
    response=${response:-$default}

    case "$response" in
        [Yy]*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Print usage/help text from script comment block
# Extracts lines 2-N from the calling script until first blank line
log_usage() {
    local script_path=${1:-${BASH_SOURCE[1]}}
    sed -n '2,/^$/p' "$script_path" | sed 's/^# //g'
}

# Utility: Check if running in CI environment
is_ci() {
    [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${GITLAB_CI:-}" ]]
}

# Utility: Check if stdout is a terminal (for color detection)
is_terminal() {
    [[ -t 1 ]]
}

# Export functions so they're available to subshells
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f log_debug
export -f log_action
export -f log_header
export -f log_empty_line
export -f log_divider
export -f log_separator
export -f log_banner
export -f log_progress
export -f log_kv
export -f log_confirm
export -f log_usage
export -f is_ci
export -f is_terminal
