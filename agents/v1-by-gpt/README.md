# Subagent templates by GPT-5

These subagents are written to behave like veteran, battle-tested principal engineers: meticulous about details, but also holistic about design, risk, rollout, and long-term maintainability.

### MCP usage notes

- When a huge read or second opinion is useful, can optionally call MCP tools you already wired (**Filesystem/Git/Fetch/Semgrep**)
- The subagents assume a zero-API setup: if the Zen MCP is present, they can use **`clink`** to invoke Gemini CLI/Codex CLI/Claude Code sub-sessions (which bill your subscriptions, not API).
- If Spec-Kit is present, kick off `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` and refine outputs.
- If Zen MCP is present and you need a giant read or a second brain, use:

    - `clink gemini` (1M) to map the repo
    - `clink codex` to scaffold stubs/tests. 
    - Return with the final ADR (*Architecture Decision Record*) and task list.