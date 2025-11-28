#!/usr/bin/env bash
set -euo pipefail

# Setup script for Gemini CLI role launcher wrappers
# Creates executable scripts in ~/.local/bin/ for launching Gemini with specific agent roles

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
CLINK_ROLES_DIR="$AGENTS_DIR/role-prompts"

# Source agent selection library
source "$REPO_ROOT/bin/lib/agent-selection.sh"

# Detect installed CLIs (exits if none found, logs detected CLIs)
discover_agents

# Skip entirely if Gemini not enabled
if ! agent_enabled "Gemini CLI"; then
    echo -e "${YELLOW}Gemini CLI not enabled. Skipping role launchers setup.${NC}"
    echo "To enable Gemini CLI:"
    echo "  mkdir -p ~/.gemini"
    echo "  Then re-run this script or agents/scripts/set-up-agents.sh"
    exit 0
fi

# Target directory for launcher scripts
LAUNCHERS_DIR="$HOME/.local/bin"

echo -e "${GREEN}Role launcher setup for Gemini${NC}"
echo -e "Source: $CLINK_ROLES_DIR"
echo -e "Target: $LAUNCHERS_DIR"
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
if [[ ! -d "$CLINK_ROLES_DIR" ]]; then
    print_error "Cannot find role-prompts directory at: $CLINK_ROLES_DIR"
fi

# Create launchers directory if it doesn't exist
mkdir -p "$LAUNCHERS_DIR"
print_success "Ensured $LAUNCHERS_DIR exists"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    print_info "Note: $HOME/.local/bin is not in your PATH"
    print_info "Add this to your ~/.zshrc or ~/.bashrc:"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# Counter for generated launchers
count=0

# Process each role file
print_step "Generating role launchers from clink role prompts"
echo ""

for role_file in "$CLINK_ROLES_DIR"/*.md; do
    # Get the base name without extension (e.g., "architect" from "architect.md")
    role_name=$(basename "$role_file" .md)

    # Create a launcher script name with "gemini-" prefix
    launcher_name="gemini-${role_name}"
    launcher_file="$LAUNCHERS_DIR/$launcher_name"

    # Read the role prompt content
    role_content=$(cat "$role_file")

    # Create the launcher script that:
    # 1. Creates a temporary GEMINI.md with the role prompt
    # 2. Launches gemini with that config
    # 3. Cleans up on exit
    cat > "$launcher_file" << 'EOF_OUTER'
#!/usr/bin/env bash
set -euo pipefail

# Temporary role config
ROLE_FILE=$(mktemp)
trap "rm -f $ROLE_FILE" EXIT

# Write role prompt to temp file
cat > "$ROLE_FILE" << 'EOF_INNER'
EOF_OUTER

    # Append the actual role content
    cat "$role_file" >> "$launcher_file"

    # Close the heredoc and add the launch command
    cat >> "$launcher_file" << 'EOF_OUTER'
EOF_INNER

# Launch Gemini with the role as a system prompt via --prompt-interactive
# The role content is injected as the first message
gemini --prompt-interactive "$(cat "$ROLE_FILE")" "$@"
EOF_OUTER

    # Make it executable
    chmod +x "$launcher_file"

    print_info "Created $launcher_name"
    count=$((count + 1))
done

echo ""
print_success "Generated $count role launchers"

# Print usage instructions
echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Usage examples:"
echo ""
echo -e "  ${BLUE}gemini-architect${NC}              # Launch Gemini as architect"
echo -e "  ${BLUE}gemini-frontend${NC}               # Launch Gemini as frontend expert"
echo -e "  ${BLUE}gemini-observability${NC}          # Launch Gemini as observability expert"
echo -e "  ${BLUE}gemini-security-compliance${NC}    # Launch Gemini as security expert"
echo ""
echo "All launchers accept additional arguments:"
echo -e "  ${BLUE}gemini-architect --model gemini-2.0-flash-exp${NC}"
echo ""
echo "List all available launchers:"
echo -e "  ${BLUE}ls ~/.local/bin/gemini-*${NC}"
echo ""

# Verify PATH setup
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${YELLOW}⚠${NC}  Remember to add ~/.local/bin to your PATH!"
    echo ""
fi
