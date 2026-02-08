#!/usr/bin/env bash
set -euo pipefail

# Setup script for Gemini CLI role launcher wrappers: creates executable scripts 
#   in ~/.local/bin/ for launching Gemini with specific agent roles
#
# Note: to see the rationale for *embedding* role prompts in the launcher scripts 
#   (e.g. rather than providing a Bureau-internal path to the role prompt file): 
#   see agents/scripts/README.md

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

log_success "Role launcher setup for Gemini"
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

# Gemini-specific processing function
process_gemini_launcher() {
    local role_name="$1"
    local target_dir="$2"
    local role_file="$CLINK_ROLES_DIR/${role_name}.md"

    # Skip if file doesn't exist
    if [[ ! -f "$role_file" ]]; then
        log_warning "Role file not found: $role_file (skipping)"
        return 1
    fi

    # Create launcher script with "gemini-" prefix
    local launcher_file="gemini-${role_name}"
    launcher_file="$target_dir/$launcher_file"

    # Create the launcher script that:
    # 1. Creates a temporary file with the role prompt
    # 2. Launches gemini with --prompt-interactive
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

    # Append the actual role content between the EOF_INNER delineators in the launcher
    cat "$role_file" >> "$launcher_file"

    # Close the heredoc and add the launch command
    cat >> "$launcher_file" << 'EOF_OUTER'
EOF_INNER

# Launch Gemini with the role as a system prompt via --prompt-interactive
gemini --prompt-interactive "$(cat "$ROLE_FILE")" "$@"
EOF_OUTER

    # Make it executable
    chmod +x "$launcher_file"

    log_info "Created $launcher_file"
    return 0
}

# Run setup using common workflow
setup_roles_for_cli "Gemini CLI" "gemini" "$HOME/.local/bin" process_gemini_launcher


# Print usage instructions
echo ""
log_success "Setup complete!"
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
    log_warning "Remember to add ~/.local/bin to your PATH!"
    echo ""
fi
