#!/usr/bin/env bash
#
# Setup script for global/user-scoped config/context files
# Handles generating config files from templates and creating symlinks for portability

set -euo pipefail

CONTEXT_DIRNAME="context"
TEMPLATES_DIRNAME="templates"
GENERATED_DIRNAME="generated"

# Retrieve absolute paths
CONFIGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  # protocols dir
REPO_ROOT="$(cd "$CONFIGS_DIR/.." && pwd)"
CONTEXT_TEMPLATES="$(cd "$CONFIGS_DIR/$CONTEXT_DIRNAME/$TEMPLATES_DIRNAME/" && pwd)"

# Create generated directory if it doesn't exist
mkdir -p "$CONFIGS_DIR/$CONTEXT_DIRNAME/$GENERATED_DIRNAME"
CONTEXT_GENERATED="$(cd "$CONFIGS_DIR/$CONTEXT_DIRNAME/$GENERATED_DIRNAME/" && pwd)"

# Source shared libraries
source "$REPO_ROOT/bin/lib/agent-selection.sh"
source "$REPO_ROOT/bin/lib/logging.sh"

# Detect installed CLIs based on directory existence
# (exits if none found, logs detected CLIs)
discover_agents

log_banner "User-level agent context files setup"
echo "Repo root: $REPO_ROOT"
echo "Selected agents: ${AGENTS[*]}"
log_empty_line

# Function to safely create symlink
# Args: 
#   $1 = source (where symlink points to)
#   $2 = target (symlink location)
# Note: Should only be called for enabled CLIs (caller must check using agent_enabled())
create_safe_symlink() {
    local source="$1"
    local target="$2"

    # Check if target exists
    if [[ -L "$target" ]]; then
        # It's a symlink - check if it points to the right place
        local current_link
        current_link="$(readlink "$target")"
        if [[ "$current_link" == "$source" ]]; then
            log_warning "Symlink already exists: $target -> $source"
            return 0
        else
            # Points to wrong location - remove it
            log_warning "Removing incorrect symlink: $target -> $current_link"
            rm "$target"
        fi
    elif [[ -f "$target" ]]; then
        # It's a regular file - backup before removing
        local backup
        backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warning "Backing up existing file: $target -> $backup"
        mv "$target" "$backup"
    elif [[ -e "$target" ]]; then
        # Exists but not a file or symlink (directory?)
        log_error "Cannot create symlink: $target exists and is not a file or symlink"
    fi

    # Create the symlink
    ln -s "$source" "$target"
    log_success "Created symlink: $target -> $source"
}

# Check if we're in the right place
if [[ ! -f "$CONTEXT_TEMPLATES/AGENTS.template.md" ]] || [[ ! -f "$CONTEXT_TEMPLATES/CLAUDE.template.md" ]]; then
    log_error "Cannot find config template files. Please run this script from within the repository."
fi
# ============================================================================
# Generate config files from templates (in repo)
# ============================================================================
log_action "Generating config files from templates"

# Generate AGENTS.md in repo (for Gemini CLI & Codex)
sed "s|{{REPO_ROOT}}|$REPO_ROOT|g" "$CONTEXT_TEMPLATES/AGENTS.template.md" > "$CONTEXT_GENERATED/AGENTS.md"
log_success "Generated $CONTEXT_GENERATED/AGENTS.md from template"

# Generate CLAUDE.md in repo (for Claude Code)
sed "s|{{REPO_ROOT}}|$REPO_ROOT|g" "$CONTEXT_TEMPLATES/CLAUDE.template.md" > "$CONTEXT_GENERATED/CLAUDE.md"
log_success "Generated $CONTEXT_GENERATED/CLAUDE.md from template"

echo ""

# ============================================================================
# Create symlinks from CLI config locations to repo files
# ============================================================================
log_action "Creating symlinks to generated config files"

# Symlink for Gemini CLI
if agent_enabled "Gemini CLI"; then
    create_safe_symlink "$CONTEXT_GENERATED/AGENTS.md" "$HOME/.gemini/GEMINI.md"
else
    log_action "Skipping Gemini symlink (user-scoped CLI directory not found)"
fi

# Symlink for Codex
if agent_enabled "Codex"; then
    create_safe_symlink "$CONTEXT_GENERATED/AGENTS.md" "$HOME/.codex/AGENTS.md"
else
    log_action "Skipping Codex symlink (user-scoped CLI directory not found)"
fi

# Symlink for Claude Code
if agent_enabled "Claude Code"; then
    create_safe_symlink "$CONTEXT_GENERATED/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
else
    log_action "Skipping Claude symlink (user-scoped CLI directory not found)"
fi

log_success "Config files setup complete!"
echo ""

# Show verification steps only for enabled agents
if agent_enabled "Claude Code"; then
    echo "Verification for Claude Code:"
    echo "  - Run '/status' (should show 'Memory: user (~/.claude/CLAUDE.md)')"
    echo ""
fi

if agent_enabled "Gemini CLI"; then
    echo "Verification for Gemini CLI:"
    echo "  - Run '/memory show' (should show GEMINI.md content)"
    echo ""
fi

if agent_enabled "Codex"; then
    echo "Verification for Codex:"
    echo "  - Ask 'What handoff guidelines were you given?' (should mention clink and delegation)"
    echo "    Note: /status shows 'AGENTS files: (none)' due to a display bug, but file IS loaded"
    echo ""
fi

echo "Configured CLIs now have access to:"
echo "  - Handoff guidelines (delegation rules)"
echo "  - Compact MCP list (tool selection guide)"
echo ""
echo "Context files are symlinked from $CONTEXT_GENERATED/"
echo "To update these:"
echo "  1. Edit the templates in $CONTEXT_TEMPLATES"
echo "  2. Re-run this script"
echo ""

# ============================================================================
# Generate and symlink PAL CLI configs
# ============================================================================
log_action "Generating PAL per-CLI config files (used when coding CLIs are called via clink)"

PAL_GENERATED_DIR="$REPO_ROOT/protocols/pal/generated"
PAL_CLI_CLIENTS_DIR="$HOME/.pal/cli_clients"

# Generate PAL CLI configs from settings.yaml (auto-discovers roles from agents/role-prompts/)
if uv run python "$REPO_ROOT/protocols/scripts/generate-pal-configs.py"; then
    log_success "PAL per-CLI config files generated in $PAL_GENERATED_DIR"
else
    log_warning "Failed to generate PAL per-CLI config files - using existing files"
fi

echo ""
log_action "Symlinking PAL per-CLI config files to $PAL_CLI_CLIENTS_DIR"

mkdir -p "$PAL_CLI_CLIENTS_DIR"

# Wipe all existing symlinks first (ensures renamed/removed configs don't linger)
find "$PAL_CLI_CLIENTS_DIR" -maxdepth 1 -type l -delete

symlink_count=0
for json_file in "$PAL_GENERATED_DIR/"*.json; do
    if [[ -f "$json_file" ]]; then
        filename=$(basename "$json_file")
        target="$PAL_CLI_CLIENTS_DIR/$filename"
        ln -sf "$json_file" "$target"
        symlink_count=$((symlink_count + 1))
    fi
done

if [[ $symlink_count -gt 0 ]]; then
    log_success "PAL per-CLI config files symlinked ($symlink_count files)"
else
    log_warning "No PAL per-CLI config files found to symlink"
fi

echo ""
echo "PAL per-CLI config files are symlinked from $PAL_GENERATED_DIR/"
echo "To update these:"
echo "  1. Edit directives.yml (or local.yml for personal overrides) for model/role settings"
echo "  2. Re-run this script (or bin/open-bureau, which calls this script)"
echo "  3. Restart your coding CLIs (or use their internal MCP-related commands if possible) to reconnect to PAL"
echo ""

# ============================================================================
# Set up Bureau editing mode skills
# ============================================================================
log_action "Setting up Bureau editing mode skills"

SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"
if [[ -x "$SCRIPTS_DIR/set-up-skills.sh" ]]; then
    "$SCRIPTS_DIR/set-up-skills.sh"
else
    log_warning "set-up-skills.sh not found or not executable; skipping skill setup"
fi

echo ""

echo "────────────────────────────────────────────────────────────────────────────────"
echo "⚠️ IMPORTANT SECURITY NOTE"
echo
echo "CLI subagents spawned via clink run with very permissive flags."
echo "  • Claude:  --permission-mode acceptEdits"
echo "  • Codex:   --dangerously-bypass-approvals-and-sandbox"
echo "  • Gemini:  --yolo"
echo ""
echo "This is intentional for automation, especially given subagents are only spawned"
echo "by *users* from within agents that they've launched. However, remain aware:"
echo ""
echo "  • Review changes after delegation completes (git diff)"
echo "  • Don't delegate tasks you wouldn't run yourself"
echo "  • Instruct agents to run clink-spawned subagents in fresh git worktrees for"
echo "    maximum isolation"
echo "────────────────────────────────────────────────────────────────────────────────"

