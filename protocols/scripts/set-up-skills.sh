#!/usr/bin/env bash
#
# Purpose:
# - Installs Bureau's skills to all supported coding agents
# - Handles all Bureau-supported coding agents using the following user-scoped skills dirs:
#     - Claude Code:  ~/.claude/skills/
#     - OpenCode:     ~/.config/opencode/skill/
#     - Gemini CLI:   ~/.gemini/skills/
#     - Codex:        ~/.codex/skills/  (copies directories since Codex ignores symlinked dirs)
#
# Args:
#    --dry-run      Show what would be done without making changes
#    --uninstall    Remove all Bureau skill installs

set -e

# Constants for functionality
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"  # we are in protocols/scripts/, so move up 2 parents

# Source shared libraries
source "$REPO_ROOT/bin/lib/logging.sh"


# Skill directory locations for each CLI
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
OPENCODE_SKILLS_DIR="$HOME/.config/opencode/skill"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
GEMINI_SKILLS_DIR="$HOME/.gemini/skills"
BUREAU_SKILL_PREFIX="bureau-"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -u|--uninstall)
            UNINSTALL=true
            shift
            ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | sed 's/^# //g'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

ensure_dir() {
    local dir=$1

    if [[ "$DRY_RUN" == true ]]; then
        log_action "Would create:" "$dir"
    else
        mkdir -p "$dir"
    fi
}

set_up_bureau_skill_dirs() {
    local command
    local action
    local skill_conf_dir=$1
    ensure_dir "$skill_conf_dir"

    # If configuring Codex, must copy the skill dirs (Codex skips symlinked dirs); else symlink
    if [[ $skill_conf_dir == $CODEX_SKILLS_DIR ]]; then
        command="cp -r"
        action="copy to"
    else
        command="ln -sf"
        action="link from"
    fi
    
    for skill_source_dir in "${SKILL_DIRS[@]}"; do
        local skill_name
        local skill_install_subdir  # install path relative to the CLI's skill config dir
        local skill_install_dir     # full install path

        skill_name=$(basename "$skill_source_dir")
        skill_install_subdir="${INSTALL_PREFIX}${skill_name}"
        skill_install_dir="$skill_conf_dir/$skill_install_subdir"

        if [[ $DRY_RUN == true ]]; then
            log_action "Would $action:" "$skill_install_dir"
            continue
        fi

        # run the copy/symlink for this skill directory
        $command "$skill_source_dir" "$skill_install_dir"
        log_success "$skill_install_dir"
    done
}

remove_bureau_skill_dirs() {
    local skill_conf_dir=$1

    if [[ ! -d "$skill_conf_dir" ]]; then
        return
    fi

    for entry in "$skill_conf_dir"/${BUREAU_SKILL_PREFIX}*; do
        if [[ ! -e "$entry" ]]; then
            continue
        fi

        if [[ -L "$entry" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log_action "Would remove:" "$entry"
            else
                rm -f "$entry"
                log_success "Removed: $entry"
            fi
        elif [[ -d "$entry" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log_action "Would remove:" "$entry/"
            else
                rm -rf "$entry"
                log_success "Removed: $entry/"
            fi
        elif [[ -e "$entry" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log_action "Would remove:" "$entry"
            else
                rm -f "$entry"
                log_success "Removed: $entry"
            fi
        fi
    done
}

# Ensure Bureau skills directory exists
if [[ ! -d "$BUREAU_SKILLS_DIR" ]]; then
    log_error "Bureau skills directory not found: $BUREAU_SKILLS_DIR"
    exit 1
fi

# Get list of skill directories (source dirs don't have bureau- prefix)
SKILL_DIRS=($(find "$BUREAU_SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | sort))

if [[ ${#SKILL_NAMES[@]} -eq 0 ]]; then
    log_error "No skills found in $SKILLS_CONFIG_PATH"
    exit 1
fi

log_empty_line
log_banner "Bureau skill installation"
echo "Config: $SKILLS_CONFIG_PATH"
echo "Skills found: ${#SKILL_NAMES[@]}"
log_empty_line

if [[ "$DRY_RUN" == true ]]; then
    log_warning "Dry run mode: no changes will be made"
    log_empty_line
fi

log_warning "Removing existing Bureau skill installs..."
log_empty_line

# Always remove Bureau-prefixed skills to keep installs consistent 
#   and avoid stale entries
remove_bureau_skill_dirs "$CLAUDE_SKILLS_DIR"
remove_bureau_skill_dirs "$OPENCODE_SKILLS_DIR"
remove_bureau_skill_dirs "$CODEX_SKILLS_DIR"
remove_bureau_skill_dirs "$GEMINI_SKILLS_DIR"

log_empty_line
log_success "Bureau skills uninstalled."
log_empty_line

if [[ "$UNINSTALL" == true ]]; then
    exit 0
fi

log_info "Setting up fresh skill installs..."
log_empty_line

log_header "Claude Code" "$CLAUDE_SKILLS_DIR"
set_up_bureau_skill_dirs "$CLAUDE_SKILLS_DIR"
echo ""

log_header "OpenCode" "$OPENCODE_SKILLS_DIR"
set_up_bureau_skill_dirs "$OPENCODE_SKILLS_DIR"
echo ""

log_header "Codex" "$CODEX_SKILLS_DIR" "Note Codex ignores symlinked directories; copying instead."
set_up_bureau_skill_dirs "$CODEX_SKILLS_DIR"
echo ""

log_header "Gemini CLI" "$GEMINI_SKILLS_DIR"
set_up_bureau_skill_dirs "$GEMINI_SKILLS_DIR"
echo ""

log_divider
if [[ "$DRY_RUN" == true ]]; then
    log_warning "Dry run complete. Run without --dry-run to apply changes."
else
    log_success "Bureau skills setup complete!"
fi
