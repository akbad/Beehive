#!/usr/bin/env bash
set -euo pipefail

# Setup script for Codex role launcher wrappers
# Creates executable scripts in ~/.local/bin/ for launching Codex with specific agent roles

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

# Skip entirely if Codex not enabled
if ! agent_enabled "Codex"; then
    echo -e "${YELLOW}Codex not enabled. Skipping role launchers setup.${NC}"
    echo "To enable Codex:"
    echo "  mkdir -p ~/.codex"
    echo "  Then re-run this script or agents/scripts/set-up-agents.sh"
    exit 0
fi

# Target directory for launcher scripts
LAUNCHERS_DIR="$HOME/.local/bin"

echo -e "${GREEN}Role launcher setup for Codex${NC}"
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

    # Create a launcher script name with "codex-" prefix
    launcher_name="codex-${role_name}"
    launcher_file="$LAUNCHERS_DIR/$launcher_name"

    # Read the role prompt content
    role_content=$(cat "$role_file")

    # Create the launcher script that:
    # 1. Creates a temporary AGENTS.md with the role prompt in the current directory
    # 2. Launches codex (which auto-loads ./AGENTS.md)
    # 3. Cleans up on exit
    cat > "$launcher_file" << 'EOF_OUTER'
#!/usr/bin/env bash
set -euo pipefail

# Temporary role config in current directory
ROLE_FILE="./AGENTS.md.tmp.$$"
trap "rm -f $ROLE_FILE" EXIT

# Write role prompt to temp file
cat > "$ROLE_FILE" << 'EOF_INNER'
EOF_OUTER

    # Append the actual role content
    cat "$role_file" >> "$launcher_file"

    # Close the heredoc and add the launch command
    cat >> "$launcher_file" << 'EOF_OUTER'
EOF_INNER

# Temporarily move existing AGENTS.md if it exists
if [[ -f ./AGENTS.md ]]; then
    mv ./AGENTS.md "./AGENTS.md.backup.$$"
    trap "rm -f $ROLE_FILE; mv ./AGENTS.md.backup.$$ ./AGENTS.md" EXIT
fi

# Symlink our role file as AGENTS.md
ln -s "$ROLE_FILE" ./AGENTS.md
trap "rm -f ./AGENTS.md $ROLE_FILE; [[ -f ./AGENTS.md.backup.$$ ]] && mv ./AGENTS.md.backup.$$ ./AGENTS.md" EXIT

# Launch Codex (it will auto-load ./AGENTS.md)
codex "$@"

# Cleanup is handled by trap
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
echo -e "  ${BLUE}codex-architect${NC}              # Launch Codex as architect"
echo -e "  ${BLUE}codex-frontend${NC}               # Launch Codex as frontend expert"
echo -e "  ${BLUE}codex-observability${NC}          # Launch Codex as observability expert"
echo -e "  ${BLUE}codex-security-compliance${NC}    # Launch Codex as security expert"
echo ""
echo "All launchers accept additional Codex arguments:"
echo -e "  ${BLUE}codex-architect --model o1${NC}"
echo -e "  ${BLUE}codex-architect \"Design a microservices system\"${NC}"
echo ""
echo "List all available launchers:"
echo -e "  ${BLUE}ls ~/.local/bin/codex-*${NC}"
echo ""
echo "Note: These launchers temporarily create ./AGENTS.md in your current directory"
echo "      and restore any existing ./AGENTS.md on exit."
echo ""

# Verify PATH setup
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${YELLOW}⚠${NC}  Remember to add ~/.local/bin to your PATH!"
    echo ""
fi
