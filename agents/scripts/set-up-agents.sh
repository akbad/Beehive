#!/usr/bin/env bash
#
# Setup script for agent files and configurations
# Run from the agents/ directory (or anywhere in the repo)

set -euo pipefail

# Find the repo root (where this script's ancestor directory is)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_AGENTS_DIRNAME="claude-subagents"
CLINK_AGENTS_DIRNAME="role-prompts"
REPO_ROOT="$(cd "$AGENTS_DIR/.." && pwd)"

# Source shared libraries
source "$REPO_ROOT/bin/lib/agent-selection.sh"
source "$REPO_ROOT/bin/lib/logging.sh"

# Detect installed CLIs based on directory existence (exits if none found, logs detected CLIs)
discover_agents

# Subdirectory name for symlinked agents
AGENTS_SUBDIR="bureau-agents"

log_banner "Setting up Bureau agents"
echo "Repo root: $REPO_ROOT"
echo "Selected agents: ${AGENTS[*]}"
log_empty_line

# Check if we're in the right place
if [[ ! -d "$AGENTS_DIR/$CLAUDE_AGENTS_DIRNAME" ]] || [[ ! -d "$AGENTS_DIR/$CLINK_AGENTS_DIRNAME" ]]; then
    print_error "Cannot find agent directories! ($CLAUDE_AGENTS_DIRNAME/ and $CLINK_AGENTS_DIRNAME within $AGENTS_DIR)"
fi

# ============================================================================
# Step 1: Set up clink subagents (for PAL MCP with Gemini/Codex/Claude CLIs)
# ============================================================================
# Only set up PAL if any agent is selected (PAL is cross-CLI, used by all)
if [[ ${#AGENTS[@]} -gt 0 ]]; then
    log_action "Setting up clink subagents for PAL MCP"

    # Create directory structure
    mkdir -p ~/.pal/cli_clients/systemprompts
    log_success "Ensured/created ~/.pal/cli_clients/systemprompts"

    # Symlink role prompts folder
    if [[ -L ~/.pal/cli_clients/systemprompts/$AGENTS_SUBDIR ]]; then
        rm ~/.pal/cli_clients/systemprompts/$AGENTS_SUBDIR
        log_success "Removed existing Bureau symlink at ~/.pal/cli_clients/systemprompts/$AGENTS_SUBDIR (to ensure consistency after any reconfiguration)"
    fi
    ln -s "$AGENTS_DIR/$CLINK_AGENTS_DIRNAME" ~/.pal/cli_clients/systemprompts/$AGENTS_SUBDIR
    log_success "Symlinked role prompts (for use with clink) to ~/.pal/cli_clients/systemprompts/$AGENTS_SUBDIR"

    echo ""
fi

# ============================================================================
# Step 2: Set up Claude Code subagents
# ============================================================================
if agent_enabled "Claude Code"; then
    log_action "Setting up Claude Code subagents"

    # Symlink Claude subagents folder
    if [[ -L ~/.claude/agents/$AGENTS_SUBDIR ]]; then
        rm ~/.claude/agents/$AGENTS_SUBDIR
        log_success "Removed existing Bureau symlink at ~/.claude/agents/$AGENTS_SUBDIR (to ensure consistency after any reconfiguration)"
    fi
    mkdir -p ~/.claude/agents
    log_success "Ensured/created ~/.claude/agents directory"

    # Symlink all Claude subagent files
    ln -s "$AGENTS_DIR/$CLAUDE_AGENTS_DIRNAME" ~/.claude/agents/$AGENTS_SUBDIR
    log_success "Symlinked Claude subagent templates/role prompts to ~/.claude/agents/$AGENTS_SUBDIR"

    echo ""
else
    log_action "Skipping Claude Code subagents (CLI directory not found)"
    echo ""
fi

# ============================================================================
# Step 3: Set up agent launchers (slash commands and wrapper scripts)
# ============================================================================

# Claude Code slash commands
if agent_enabled "Claude Code"; then
    print_step "Setting up Claude Code slash commands"
    "$AGENTS_DIR/scripts/set-up-claude-slash-commands.sh"
    echo ""
fi

# Codex role launchers
if agent_enabled "Codex"; then
    log_action "Setting up Codex role launchers"
    "$AGENTS_DIR/scripts/set-up-codex-role-launchers.sh"
    echo ""
fi

# Gemini CLI role launchers
if agent_enabled "Gemini CLI"; then
    log_action "Setting up Gemini CLI role launchers"
    "$AGENTS_DIR/scripts/set-up-gemini-role-launchers.sh"
    echo ""
fi

# OpenCode agents (symlink for auto-discovery)
if agent_enabled "OpenCode"; then
    print_step "Setting up Bureau agents for OpenCode"

    # Symlink role prompts - OpenCode auto-discovers agents from this directory
    OPEN_AGENT_DIR="$HOME/.config/opencode/agent/$AGENTS_SUBDIR"
    mkdir -p "$HOME/.config/opencode/agent"

    if [[ -L "$OPEN_AGENT_DIR" ]]; then
        rm "$OPEN_AGENT_DIR"
        print_success "Removed old symlink at $OPEN_AGENT_DIR"
    fi
    ln -s "$AGENTS_DIR/$CLINK_AGENTS_DIRNAME" "$OPEN_AGENT_DIR"
    print_success "Symlinked Bureau role prompts to $OPEN_AGENT_DIR (OpenCode auto-discovers these)"
    echo ""
fi

log_success "Agent setup complete!"
echo ""
echo "Next steps:"
echo "  1. Run the configs setup script: protocols/scripts/set-up-protocols.sh"
echo "  2. Restart PAL MCP server to reload clink configs"
echo "  3. Verify Claude Code agents with: claude (then run /agents)"
echo "  4. Install claude-mem plugin:"
echo "     > /plugin marketplace add thedotmack/claude-mem"
echo "     > /plugin install claude-mem"
