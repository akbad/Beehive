#!/usr/bin/env bash
#
# Idempotent setup & update script for installing the Superpowers skills library for Codex.

set -euo pipefail

# Find repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$AGENTS_DIR/.." && pwd)"

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
TARGET_DIR="${HOME}/.codex/superpowers"
SKILLS_DIR="${HOME}/.codex/skills"
BOOTSTRAP_CMD="${TARGET_DIR}/.codex/superpowers-codex"

log_action "==>" "Ensuring Codex directories exist"
mkdir -p "${HOME}/.codex"
mkdir -p "${SKILLS_DIR}"
log_success "Codex directories ready"

if [ -d "${TARGET_DIR}/.git" ]; then
    log_action "==>" "Updating existing Superpowers checkout"
    git -C "${TARGET_DIR}" remote set-url origin "${REPO_URL}"
    if ! git -C "${TARGET_DIR}" fetch --tags --prune; then
        log_warning "Unable to fetch updates for Superpowers. Continuing with existing checkout."
    else
        if ! git -C "${TARGET_DIR}" merge --ff-only origin/main >/dev/null 2>&1; then
            log_warning "Could not fast-forward Superpowers repository (local changes?). Leaving as-is."
        else
            log_success "Superpowers repository updated"
        fi
    fi
else
    log_action "==>" "Cloning Superpowers repository"
    git clone "${REPO_URL}" "${TARGET_DIR}"
    log_success "Superpowers repository cloned"
fi

if [ ! -x "${BOOTSTRAP_CMD}" ]; then
    log_warning "Bootstrap command ${BOOTSTRAP_CMD} not found or not executable"
else
    log_action "==>" "Running Superpowers bootstrap (verification)"
    if "${BOOTSTRAP_CMD}" bootstrap >/dev/null 2>&1; then
        log_success "Superpowers bootstrap completed"
    else
        log_warning "Bootstrap command exited with a non-zero status. Review output above if any."
    fi
fi

log_success "Superpowers setup for Codex complete!"
