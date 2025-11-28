#!/usr/bin/env bash
set -euo pipefail

# Setup script for installing the Superpowers skills library for Codex
# Makes the installation idempotent and safe to rerun.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Find repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$AGENTS_DIR/.." && pwd)"

# Source agent selection library
source "$REPO_ROOT/bin/lib/agent-selection.sh"

# Load agent selection from profile
discover_agents

# Skip entirely if Codex not selected
if ! agent_enabled "Codex"; then
    echo -e "${YELLOW}Codex not in CLI profile. Skipping Superpowers setup.${NC}"
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

print_step() {
    echo -e "${YELLOW}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
    exit 1
}

print_step "Ensuring Codex directories exist"
mkdir -p "${HOME}/.codex"
mkdir -p "${SKILLS_DIR}"
print_success "Codex directories ready"

if [ -d "${TARGET_DIR}/.git" ]; then
    print_step "Updating existing Superpowers checkout"
    git -C "${TARGET_DIR}" remote set-url origin "${REPO_URL}"
    if ! git -C "${TARGET_DIR}" fetch --tags --prune; then
        print_warning "Unable to fetch updates for Superpowers. Continuing with existing checkout."
    else
        if ! git -C "${TARGET_DIR}" merge --ff-only origin/main >/dev/null 2>&1; then
            print_warning "Could not fast-forward Superpowers repository (local changes?). Leaving as-is."
        else
            print_success "Superpowers repository updated"
        fi
    fi
else
    print_step "Cloning Superpowers repository"
    git clone "${REPO_URL}" "${TARGET_DIR}"
    print_success "Superpowers repository cloned"
fi

if [ ! -x "${BOOTSTRAP_CMD}" ]; then
    print_warning "Bootstrap command ${BOOTSTRAP_CMD} not found or not executable"
else
    print_step "Running Superpowers bootstrap (verification)"
    if "${BOOTSTRAP_CMD}" bootstrap >/dev/null 2>&1; then
        print_success "Superpowers bootstrap completed"
    else
        print_warning "Bootstrap command exited with a non-zero status. Review output above if any."
    fi
fi

print_success "Superpowers setup for Codex complete!"
