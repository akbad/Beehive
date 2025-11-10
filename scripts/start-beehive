#!/usr/bin/env bash
set -euo pipefail

# Bootstrap: Initial setup for Beehive across Claude Code, Codex, and Gemini CLI
# > Run once: ./bootstrap.sh
# > Idempotent (safe to re-run; won't duplicate resources)
#
# Prerequisites: Node.js, Python 3.8+, git
#
# Detection: Automatically configures any CLI with a config directory in ~/.
#   - Claude Code: ~/.claude/
#   - Gemini CLI:  ~/.gemini/
#   - Codex:       ~/.codex/

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'        # no colour

# Change to repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

# Source agent selection library
source "$REPO_ROOT/scripts/lib/agent-selection.sh"

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}  Beehive: user-scoped bootstrap setup${NC}"
echo -e "${BLUE}====================================================${NC}"
echo ""

# Detect installed CLIs (exits if none found, logs detected CLIs)
load_agent_selection
echo ""

# Run tools setup
echo -e "${BLUE}Setting up tools...${NC}"
echo ""
tools/scripts/set-up-tools.sh -y

# Run remaining setup scripts (all use directory-based detection)
echo ""
echo -e "${BLUE}Setting up agents and agent launchers...${NC}"
echo ""
agents/scripts/set-up-agents.sh

echo ""
echo -e "${BLUE}Setting up config files...${NC}"
echo ""
configs/scripts/set-up-configs.sh

echo ""
echo -e "${GREEN}==========================================================${NC}"
echo -e "${GREEN}  Bootstrapping complete: Beehive is ready to use.${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo ""
echo "To add/remove CLIs in the future:"
echo "  - Add: Create user-scoped config directory (e.g., mkdir -p ~/.gemini)"
echo "  - Remove: Delete user-scoped config directory (e.g., rm -rf ~/.codex)"
echo "  - Then re-run: ./scripts/bootstrap.sh"
echo ""
