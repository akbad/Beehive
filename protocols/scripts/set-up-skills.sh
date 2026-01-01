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
# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
UNINSTALL=false

# Constants for functionality
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"  # we are in protocols/scripts/, so move up 2 parents
BUREAU_SKILLS_DIR="$REPO_ROOT/protocols/context/static/skills"
INSTALL_PREFIX="bureau-"  # prefix added to skill names when installing

# Skill directory locations for each CLI
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
OPENCODE_SKILLS_DIR="$HOME/.config/opencode/skill"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
GEMINI_SKILLS_DIR="$HOME/.gemini/skills"

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

log_action() {
    local action=$1
    local detail=$2
    echo -e "${BLUE}$action${NC} $detail"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    local label=$1
    local path=$2
    shift 2

    echo -e "${BLUE}${label}${NC} ($path)"
    for line in "$@"; do
        echo -e "  ${YELLOW}${line}${NC}"
    done
}

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
        command="ln -s"
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

    for skill_source_dir in "${SKILL_DIRS[@]}"; do
        local skill_name
        local skill_install_subdir  # install path relative to the CLI's skill config dir
        local skill_install_dir     # full install path

        skill_name=$(basename "$skill_source_dir")
        skill_install_subdir="${INSTALL_PREFIX}${skill_name}"
        skill_install_dir="$skill_conf_dir/$skill_install_subdir"

        # Auto-detect whether directory is symlinked or copied
        # Must check -L first (since symlinked dirs match both -L and -d)
        if [[ -L "$skill_install_dir" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log_action "Would remove:" "$skill_install_dir"
            else
                rm "$skill_install_dir"
                log_success "Removed: $skill_install_dir"
            fi
        elif [[ -d "$skill_install_dir" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log_action "Would remove:" "$skill_install_dir/"
            else
                rm -rf "$skill_install_dir"
                log_success "Removed: $skill_install_dir/"
            fi
        elif [[ -e "$skill_install_dir" ]]; then
            log_warning "Skipped $skill_install_subdir (unexpected file type)"
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

if [[ ${#SKILL_DIRS[@]} -eq 0 ]]; then
    log_error "No skill directories found in $BUREAU_SKILLS_DIR"
    exit 1
fi

echo -e "\n${BLUE}Bureau skill installation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Source: $BUREAU_SKILLS_DIR"
echo -e "Skills found: ${#SKILL_DIRS[@]}\n"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Dry run mode: no changes will be made${NC}\n"
fi

echo -e "${YELLOW}Removing existing Bureau skill installs...${NC}\n"

# Always remove skill directories to ensure install is consistent 
#   with source of truth (bureau/protocols/context/static/skills/)
remove_bureau_skill_dirs "$CLAUDE_SKILLS_DIR"
remove_bureau_skill_dirs "$OPENCODE_SKILLS_DIR"
remove_bureau_skill_dirs "$CODEX_SKILLS_DIR"
remove_bureau_skill_dirs "$GEMINI_SKILLS_DIR"

echo -e "\n${GREEN}Bureau skills uninstalled.${NC}\n"

if [[ "$UNINSTALL" == true ]]; then
    exit 0
fi

echo -e "${BLUE}Setting up fresh skill installs...${NC}\n"

print_header "Claude Code" "$CLAUDE_SKILLS_DIR"
set_up_bureau_skill_dirs "$CLAUDE_SKILLS_DIR"
echo ""

print_header "OpenCode" "$OPENCODE_SKILLS_DIR"
set_up_bureau_skill_dirs "$OPENCODE_SKILLS_DIR"
echo ""

print_header "Codex" "$CODEX_SKILLS_DIR" "Note Codex ignores symlinked directories; copying instead."
set_up_bureau_skill_dirs "$CODEX_SKILLS_DIR"
echo ""

print_header "Gemini CLI" "$GEMINI_SKILLS_DIR"
set_up_bureau_skill_dirs "$GEMINI_SKILLS_DIR"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Dry run complete. Run without --dry-run to apply changes.${NC}"
else
    echo -e "${GREEN}Bureau skills setup complete!${NC}"
fi
