#!/usr/bin/env bash
set -euo pipefail

# Setup script for Claude Code slash commands that inject agent role prompts
# This allows launching agents in the current conversation via /architect, /frontend, etc.

# Find the repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$AGENTS_DIR/.." && pwd)"
CLAUDE_SUBAGENTS_DIR="$AGENTS_DIR/claude-subagents"

# Source shared libraries
source "$REPO_ROOT/bin/lib/agent-selection.sh"
source "$REPO_ROOT/bin/lib/logging.sh"
source "$REPO_ROOT/bin/lib/roles-setup.sh"

# Detect installed CLIs (exits if none found, logs detected CLIs)
discover_agents

log_banner "Agent slash command setup for Claude Code"
echo "Source: $CLAUDE_SUBAGENTS_DIR"
echo "Target: $HOME/.claude/commands"
log_empty_line

# Check if source directory exists
if [[ ! -d "$CLAUDE_SUBAGENTS_DIR" ]]; then
    log_error "Cannot find claude-subagents directory at: $CLAUDE_SUBAGENTS_DIR"
    exit 1
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
log_success "Setup complete!"
echo ""
echo "Usage:"
echo -e "  1. Launch Claude Code: ${BLUE}claude${NC}"
echo "  2. Use any agent role via slash command:"
echo ""
echo -e "     ${BLUE}/architect${NC}              - Principal software architect"
echo -e "     ${BLUE}/frontend${NC}               - Frontend architecture & UX"
echo -e "     ${BLUE}/observability${NC}          - Monitoring & incident response"
echo -e "     ${BLUE}/security-compliance${NC}    - Security & privacy architect"
echo -e "     ${BLUE}/testing${NC}                - Test quality & reliability"
echo "     ... and more"
echo ""
echo -e "  3. List all available commands: ${BLUE}/help${NC}"
echo ""
echo "Note: These inject the agent prompt into your current conversation."
echo "      For isolated subagent tasks, continue using the Task tool."
echo ""
