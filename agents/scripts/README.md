# Agent setup scripts

This directory contains scripts that set up Bureau's agent role prompts for use within the supported coding agent CLIs, both as background subagents and direct, main agents.

## Why role prompt bodies are *embedded* in the launcher scripts generated for Codex & Gemini

> [!NOTE]
> This section concerns *only* the launcher generator scripts [for Codex](set-up-codex-role-launchers.sh) and [for Gemini](set-up-gemini-role-launchers.sh).

### Background

- The launcher generators *embed* the role prompt content into each generated launcher script.
- These, in turn, only write their role prompt to a temp file when they're run (the temp file gets automatically cleaned via `trap`, and backups are used to avoid clobbering). 

### Rationale 

- **Maintains a snapshot of behavior:** launchers are stable even if role prompts are changed later (the role prompts only update upon the next run of the corresponding launcher generator script and/or `open-bureau`)
- **Launchers keep working without the repo** even if it's moved or deleted, avoiding runtime dependency on repo availability.
- **Keeping security/perms consistent** by not requiring launchers to read repo files at runtime.

> [!TIP]
>
> After updating any role prompts, you **must** run [`open-bureau`](../../bin/open-bureau) to regenerate the launcher scripts to contain the updated prompts.
