#!/usr/bin/env bash
set -euo pipefail

# Setup script for Claude Code slash commands that inject agent role prompts
# This allows launching agents in the current conversation via /architect, /frontend, etc.

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Find the repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$AGENTS_DIR/.." && pwd)"
CLAUDE_SUBAGENTS_DIR="$AGENTS_DIR/claude-subagents"

# Source agent selection library
source "$REPO_ROOT/bin/lib/agent-selection.sh"

# Detect installed CLIs (exits if none found, logs detected CLIs)
discover_agents

# Skip entirely if Claude not enabled
if ! agent_enabled "ClaudeCode"; then
    echo -e "${YELLOW}Claude Code not enabled. Skipping slash commands setup.${NC}"
    echo "To enable Claude Code:"
    echo "  mkdir -p ~/.claude"
    echo "  Then re-run this script or agents/scripts/set-up-agents.sh"
    exit 0
fi

# Target directory for slash commands
COMMANDS_DIR="$HOME/.claude/commands"

echo -e "${GREEN}Agent slash command setup for Claude Code${NC}"
echo -e "Source: $CLAUDE_SUBAGENTS_DIR"
echo -e "Target: $COMMANDS_DIR"
echo ""

# Function to print step headers
print_step() {
    echo -e "${YELLOW}==>${NC} $1"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Function to print error and exit
print_error() {
    echo -e "${RED}✗${NC} $1" >&2
    exit 1
}

# Check if source directory exists
if [[ ! -d "$CLAUDE_SUBAGENTS_DIR" ]]; then
    print_error "Cannot find claude-subagents directory at: $CLAUDE_SUBAGENTS_DIR"
fi

# Create commands directory if it doesn't exist
mkdir -p "$COMMANDS_DIR"
print_success "Ensured $COMMANDS_DIR exists"

# Counter for generated commands
count=0

# Process each agent file
print_step "Generating slash commands from agent files"
echo ""

for agent_file in "$CLAUDE_SUBAGENTS_DIR"/*.md; do
    # Get the base name without extension (e.g., "architect" from "architect.md")
    agent_name=$(basename "$agent_file" .md)

    # Target command file
    command_file="$COMMANDS_DIR/${agent_name}.md"

    # Extract the content after the frontmatter (everything after the second ---)
    # The frontmatter is between the first --- and second ---
    # We want everything after the second ---

    # Using awk to skip frontmatter and get the actual content
    agent_content=$(awk '
        BEGIN { in_frontmatter=0; past_frontmatter=0 }
        /^---$/ {
            if (!past_frontmatter) {
                in_frontmatter = !in_frontmatter;
                if (!in_frontmatter) past_frontmatter = 1;
                next;
            }
        }
        past_frontmatter { print }
    ' "$agent_file")

    # Create the slash command file with a preamble
    cat > "$command_file" << EOF
Adopt the role and instructions below for this conversation.

---

$agent_content
EOF

    print_info "Created /$agent_name -> $command_file"
    count=$((count + 1))
done

echo ""
print_success "Generated $count slash commands"

# Print usage instructions
echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Usage:"
echo -e "  1. Launch Claude Code: ${BLUE}claude${NC}"
echo "  2. Use any agent role via slash command:"
echo ""
echo -e "     ${BLUE}/architect${NC}     - Principal software architect"
echo -e "     ${BLUE}/frontend${NC}      - Frontend architecture & UX"
echo -e "     ${BLUE}/observability${NC} - Monitoring & incident response"
echo -e "     ${BLUE}/security-compliance${NC} - Security & privacy architect"
echo -e "     ${BLUE}/testing${NC}       - Test quality & reliability"
echo "     ... and $((count - 5)) more"
echo ""
echo -e "  3. List all available commands: ${BLUE}/help${NC}"
echo ""
echo "Note: These inject the agent prompt into your current conversation."
echo "      For isolated subagent tasks, continue using the Task tool."
echo ""
