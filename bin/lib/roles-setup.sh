#!/usr/bin/env bash

# Role setup library for *direct* role entrypoints for use by launcher and slash-command setup scripts
#
# Usage:
#   1. Import the library:
#      source "$REPO_ROOT/bin/lib/roles-setup.sh"
#
#   2. Define CLI-specific processing:
#      process_role() {
#          local role_name="$1"
#          local target_dir="$2"
#          # ... CLI-specific logic ...
#          return 0  # if successful
#      }
#
#   3. Run setup:
#      setup_roles_for_cli "CLI name" "cli_key" "$TARGET_DIR" process_role

# Get enabled roles for a specific CLI from the catalog
# Returns space-separated list of role names
# Usage: get_enabled_roles_for_cli "claude"
get_enabled_roles_for_cli() {
    local cli_key="$1"

    uv run python -m operations.roles_catalog "$cli_key"
}

# Main setup function for role configurations
# Usage: setup_roles_for_cli "CLI Name" "cli_key" "/target/dir" process_role
#
# Arguments:
#   $1 - Display name of CLI (e.g., "Claude Code", "Codex")
#   $2 - Config key for CLI (e.g., "claude", "codex")
#   $3 - Target directory for generated files to be written to
#   $4 - Callback function name for processing each role
#
# Callback signature:
#   process_role role_name target_dir
#   Returns: 0 on success, 1 on skip/failure
#
# Returns:
#   0 - Success
#   Other exit codes mirror those of agent_enabled()
setup_roles_for_cli() {
    local cli_name="$1"
    local cli_key="$2"
    local target_dir="$3"
    local process_role="$4"

    # Check if CLI is enabled (uses agent_enabled from agent-selection.sh)
    if ! agent_enabled "$cli_name"; then
        log_warning "$cli_name not enabled. Skipping setup."
        echo "To enable $cli_name:"
        echo "  Add '$cli_key' to agents list in directives.yml"
        echo "  Then re-run this script"
        return 0
    fi

    # Ensure target directory exists
    mkdir -p "$target_dir"
    log_success "Ensured $target_dir exists"

    # Get filtered role list from catalog
    log_action "Resolving enabled roles from configuration"
    local enabled_roles
    if ! enabled_roles=$(get_enabled_roles_for_cli "$cli_key"); then
        log_error "Failed to query roles catalog"
        return 1
    fi

    if [[ -z "$enabled_roles" ]]; then
        log_warning "No roles enabled in configuration. Skipping setup."
        echo "To enable roles, update the roles.enabled list in directives.yml"
        return 0
    fi

    log_success "Enabled roles ($(echo $enabled_roles | wc -w)): $enabled_roles"
    echo ""

    log_action "Processing roles for $cli_name"
    echo ""

    # Process each enabled role individually (to support per-CLI enabled role lists once implemented)
    local count=0
    for role_name in $enabled_roles; do
        if "$process_role" "$role_name" "$target_dir"; then
            count=$((count + 1))
        fi
    done

    echo ""
    log_success "Processed $count roles for $cli_name"

    return 0
}

# Export functions for use in subshells
export -f get_enabled_roles_for_cli
export -f setup_roles_for_cli
