#!/usr/bin/env bash
#
# Setup script for global config files
# Generates config files from templates and creates symlinks for portability

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Source agent selection library
source "$REPO_ROOT/bin/lib/agent-selection.sh"

# Detect installed CLIs based on directory existence 
# (exits if none found, logs detected CLIs)
discover_agents

echo -e "${GREEN}User-level agent context files setup${NC}"
echo -e "Repo root: $REPO_ROOT"
echo -e "Selected agents: ${AGENTS[*]}"
echo ""

# Function to print step headers
print_step() {
    echo -e "${YELLOW}==>${NC} $1"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print error and exit
print_error() {
    echo -e "${RED}✗${NC} $1" >&2
    exit 1
}

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
            print_warning "Symlink already exists: $target -> $source"
            return 0
        else
            # Points to wrong location - remove it
            print_warning "Removing incorrect symlink: $target -> $current_link"
            rm "$target"
        fi
    elif [[ -f "$target" ]]; then
        # It's a regular file - backup before removing
        local backup
        backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Backing up existing file: $target -> $backup"
        mv "$target" "$backup"
    elif [[ -e "$target" ]]; then
        # Exists but not a file or symlink (directory?)
        print_error "Cannot create symlink: $target exists and is not a file or symlink"
    fi

    # Create the symlink
    ln -s "$source" "$target"
    print_success "Created symlink: $target -> $source"
}

# Check if we're in the right place
if [[ ! -f "$CONTEXT_TEMPLATES/AGENTS.template.md" ]] || [[ ! -f "$CONTEXT_TEMPLATES/CLAUDE.template.md" ]]; then
    print_error "Cannot find config template files. Please run this script from within the repository."
fi
# ============================================================================
# Generate config files from templates (in repo)
# ============================================================================
print_step "Generating config files from templates"

# Generate AGENTS.md in repo (for Gemini CLI & Codex)
sed "s|{{REPO_ROOT}}|$REPO_ROOT|g" "$CONTEXT_TEMPLATES/AGENTS.template.md" > "$CONTEXT_GENERATED/AGENTS.md"
print_success "Generated $CONTEXT_GENERATED/AGENTS.md from template"

# Generate CLAUDE.md in repo (for Claude Code)
sed "s|{{REPO_ROOT}}|$REPO_ROOT|g" "$CONTEXT_TEMPLATES/CLAUDE.template.md" > "$CONTEXT_GENERATED/CLAUDE.md"
print_success "Generated $CONTEXT_GENERATED/CLAUDE.md from template"

echo ""

# ============================================================================
# Create symlinks from CLI config locations to repo files
# ============================================================================
print_step "Creating symlinks to generated config files"

# Symlink for Gemini CLI
if agent_enabled "Gemini CLI"; then
    create_safe_symlink "$CONTEXT_GENERATED/AGENTS.md" "$HOME/.gemini/GEMINI.md"
else
    print_step "Skipping Gemini symlink (user-scoped CLI directory not found)"
fi

# Symlink for Codex
if agent_enabled "Codex"; then
    create_safe_symlink "$CONTEXT_GENERATED/AGENTS.md" "$HOME/.codex/AGENTS.md"
else
    print_step "Skipping Codex symlink (user-scoped CLI directory not found)"
fi

# Symlink for Claude Code
if agent_enabled "Claude Code"; then
    create_safe_symlink "$CONTEXT_GENERATED/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
else
    print_step "Skipping Claude symlink (user-scoped CLI directory not found)"
fi

echo -e "${GREEN}✓ Config files setup complete!${NC}"
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
print_step "Generating PAL per-CLI config files (used when coding CLIs are called via clink)"

PAL_GENERATED_DIR="$REPO_ROOT/protocols/pal/generated"
PAL_CLI_CLIENTS_DIR="$HOME/.pal/cli_clients"

# Generate PAL CLI configs from settings.yaml (auto-discovers roles from agents/role-prompts/)
if uv run python "$REPO_ROOT/protocols/scripts/generate-pal-configs.py"; then
    print_success "PAL per-CLI config files generated in $PAL_GENERATED_DIR"
else
    print_warning "Failed to generate PAL per-CLI config files - using existing files"
fi

echo ""
print_step "Symlinking PAL per-CLI config files to $PAL_CLI_CLIENTS_DIR"

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
    print_success "PAL per-CLI config files symlinked ($symlink_count files)"
else
    print_warning "No PAL per-CLI config files found to symlink"
fi

echo ""
echo "PAL per-CLI config files are symlinked from $PAL_GENERATED_DIR/"
echo "To update these:"
echo "  1. Edit directives.yml (or local.yml for personal overrides) for model/role settings"
echo "  2. Re-run this script (or bin/open-bureau, which calls this script)"
echo "  3. Restart your coding CLIs (or use their internal MCP-related commands if possible) to reconnect to PAL"
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
echo "by user-run agents that they trust. However, be aware:"
echo ""
echo "  • Review changes after delegation completes (git diff)"
echo "  • Don't delegate tasks you wouldn't run yourself"
echo "  • Instruct agents to run clink-spawned subagents in fresh git worktrees for"
echo "    maximum isolation"
echo "────────────────────────────────────────────────────────────────────────────────"

