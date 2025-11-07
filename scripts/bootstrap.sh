#!/usr/bin/env bash

# Bootstrap: Initial setup for Beehive across Claude Code, Codex CLI, and Gemini CLI
# > Run once: ./bootstrap.sh
# > Idempotent (safe to re-run; won't duplicate resources)
#
# Prerequisites: Node.js, Python 3.8+, git

# Change to repo root
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

agents/scripts/set-up-agents.sh && \
configs/scripts/set-up-configs.sh && \
tools/scripts/set-up-tools.sh -y && \
agents/scripts/set-up-claude-slash-commands.sh && \
agents/scripts/set-up-codex-role-launchers.sh && \
agents/scripts/set-up-gemini-role-launchers.sh