#!/usr/bin/env bash
set -euo pipefail

# Setup script for Codex role launcher wrappers
# Creates executable scripts in ~/.local/bin/ for launching Codex with specific agent roles

# Find the repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$AGENTS_DIR/.." && pwd)"
CLINK_ROLES_DIR="$AGENTS_DIR/role-prompts"

# Source shared libraries
source "$REPO_ROOT/bin/lib/agent-selection.sh"
source "$REPO_ROOT/bin/lib/logging.sh"
source "$REPO_ROOT/bin/lib/roles-setup.sh"

# Detect installed CLIs (exits if none found, logs detected CLIs)
discover_agents

log_success "Role launcher setup for Codex"
echo -e "Source: $CLINK_ROLES_DIR"
echo -e "Target: $HOME/.local/bin"
echo ""

# Check if source directory exists
if [[ ! -d "$CLINK_ROLES_DIR" ]]; then
    log_error "Cannot find role-prompts directory at: $CLINK_ROLES_DIR"
    exit 1
fi

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    log_info "Note: $HOME/.local/bin is not in your PATH"
    log_info "Add this to your ~/.zshrc or ~/.bashrc:"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# Codex-specific processing function
process_codex_launcher() {
    local role_name="$1"
    local target_dir="$2"
    local role_file="$CLINK_ROLES_DIR/${role_name}.md"

    # Skip if file doesn't exist
    if [[ ! -f "$role_file" ]]; then
        log_warning "Role file not found: $role_file (skipping)"
        return 1
    fi

    # Create launcher script with "codex-" prefix
    local launcher_name="codex-${role_name}"
    local launcher_file="$target_dir/$launcher_name"

    # Create the launcher script that:
    # 1. Creates a temporary AGENTS.md with the role prompt
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

    log_info "Created $launcher_name"
    return 0
}

# Run setup using common workflow
setup_roles_for_cli "Codex" "codex" "$HOME/.local/bin" process_codex_launcher


# Print usage instructions
echo ""
log_success "Setup complete!"
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
    log_warning "Remember to add ~/.local/bin to your PATH!"
    echo ""
fi
