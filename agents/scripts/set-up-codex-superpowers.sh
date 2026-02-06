#!/usr/bin/env bash
#
# Idempotent setup & update script for installing the Superpowers skills library for Codex.

set -euo pipefail

# Find repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source logging + agent selection libraries
source "$REPO_ROOT/bin/lib/logging.sh"
source "$REPO_ROOT/bin/lib/agent-selection.sh"

# Load agent selection from profile
discover_agents

# Skip entirely if Codex not selected
if ! agent_enabled "Codex"; then
    log_warning "Codex not in CLI profile. Skipping Superpowers setup."
    echo "To enable Codex, run:"
    echo "  tools/scripts/set-up-tools.sh -a x    # Codex only"
    echo "  tools/scripts/set-up-tools.sh -a cx   # Codex + Claude"
    echo "  tools/scripts/set-up-tools.sh -a cgx  # All agents"
    exit 0
fi

REPO_URL="https://github.com/obra/superpowers.git"
SUPERPOWERS_DIR="${HOME}/.codex/superpowers"
CODEX_SKILLS_DIR="${HOME}/.agents/skills"
SUPERPOWERS_SKILLS_SOURCE="${SUPERPOWERS_DIR}/skills"
SUPERPOWERS_SKILLS_LINK="${CODEX_SKILLS_DIR}/superpowers"

log_action "==>" "Ensuring Codex directories exist"
mkdir -p "${HOME}/.codex"
mkdir -p "${CODEX_SKILLS_DIR}"
log_success "Codex directories ready"

if [ -d "${SUPERPOWERS_DIR}/.git" ]; then
    log_action "==>" "Updating existing Superpowers checkout"
    git -C "${SUPERPOWERS_DIR}" remote set-url origin "${REPO_URL}"
    if ! git -C "${SUPERPOWERS_DIR}" fetch --tags --prune; then
        log_warning "Unable to fetch updates for Superpowers. Continuing with existing checkout."
    else
        if ! git -C "${SUPERPOWERS_DIR}" merge --ff-only origin/main >/dev/null 2>&1; then
            log_warning "Could not fast-forward Superpowers repository (local changes?). Leaving as-is."
        else
            log_success "Superpowers repository updated"
        fi
    fi
else
    log_action "==>" "Cloning Superpowers repository"
    git clone "${REPO_URL}" "${SUPERPOWERS_DIR}"
    log_success "Superpowers repository cloned"
fi

if [ ! -d "${SUPERPOWERS_SKILLS_SOURCE}" ]; then
    log_error "Superpowers skills directory not found at ${SUPERPOWERS_SKILLS_SOURCE}"
    exit 1
fi

if [ -L "${SUPERPOWERS_SKILLS_LINK}" ]; then
    rm -f "${SUPERPOWERS_SKILLS_LINK}"
fi

if [ -e "${SUPERPOWERS_SKILLS_LINK}" ]; then
    log_error "Path exists and is not a symlink: ${SUPERPOWERS_SKILLS_LINK}"
    log_error "Move or remove it, then rerun this setup script."
    exit 1
else
    ln -s "${SUPERPOWERS_SKILLS_SOURCE}" "${SUPERPOWERS_SKILLS_LINK}"
    log_success "Linked ${SUPERPOWERS_SKILLS_LINK} -> ${SUPERPOWERS_SKILLS_SOURCE}"
fi

log_success "Superpowers setup for Codex complete!"
