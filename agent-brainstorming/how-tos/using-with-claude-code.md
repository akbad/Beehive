# Using v3-superstars prompts with Claude Code subagents

This guide shows you, step by step, how to turn your `agents/v3-superstars/` prompt files into Claude **subagents** that are available everywhere via `~/.claude/agents`. It also explains the YAML frontmatter you must add, how to choose tools and models, and how to make Claude proactively delegate to the right subagent without you repeatedly asking.


## What subagents are and where they live

Subagents are specialized, pre-configured AI assistants that Claude can delegate to for specific tasks. Each subagent has:

- Its own system prompt (the body of your file)
- YAML frontmatter with minimal metadata
- A separate context window, allowing focused, long-running main sessions

Locations and precedence when names collide:

- Project-level: `.claude/agents/` (highest priority within that project)
- CLI flag: `claude --agents '{ ... }'` (lower than project, higher than user)
- User-level: `~/.claude/agents/` (available to all projects)


## Minimal, correct YAML frontmatter

Every subagent file is markdown with a YAML header, followed by your system prompt. The absolutely essential fields are `name` and `description`. Optional fields include `tools` and `model`.

Template:

```markdown
---
name: your-sub-agent-name
description: Natural-language description of when to use this subagent
tools: Read, Grep, Glob, Bash           # Optional; inherits all tools if omitted
model: inherit                          # Optional; alias or 'inherit'
---

Your subagent’s system prompt goes here. Provide precise, step-by-step guidance.
```

Field guidance:

- `name` (required): unique, lowercase, hyphenated (e.g., `architecture-agent`).

- `description` (required): action-oriented trigger text that Claude can match against your requests. Write “Use proactively after …” and “Use when …” phrasing.

- `tools` (optional): comma-separated list. Omit to inherit all tools (including MCP tools) from the main thread; include to restrict. Typical tools:

    - `Read, Grep, Glob, Bash` for code review and investigation

    - add `Edit, Write` for automated fixes or refactors

- `model` (optional): one of `sonnet`, `haiku`, `opus`, or `inherit`.

    - `inherit`: use the conversation’s model

    - `sonnet`: balanced default for agentic coding and multi-step planning

    - `haiku`: fast, cost-efficient; great for CI fix-ups and tight edit–run–fix loops

    - `opus`: best for final, complex decision docs (RFCs, threat models)


## Map v3-superstars prompts to subagents (drop-in examples)

Below are “ready-to-drop” frontmatter blocks with suggested tools/models. Paste the corresponding v3-superstars prompt body beneath each header.

Code reviewer (diff-focused):

```markdown
---
name: superstars-codereviewer
description: Proactively review only the most recent code changes (git diff). Use immediately after edits to catch security, correctness, performance, and maintainability issues with precise file:line references and concrete fixes.
tools: Read, Grep, Glob, Bash
model: inherit
---

```

Test runner/fixer:

```markdown
---
name: superstars-testfix
description: Use when tests fail. Automatically run tests, reproduce failures, identify root cause, implement minimal fix, and re-run. Keep fixes small and focused.
tools: Read, Edit, Write, Bash, Grep, Glob
model: inherit
---

```

Architecture/migration planner:

```markdown
---
name: superstars-architect
description: Use for architecture and migration plans across services. Create phased plans with trade-offs, risks, and validation gates; prefer minimal-disruption rollouts.
tools: Read, Grep, Glob, Bash
model: sonnet
---

```

Security/privacy reviewer:

```markdown
---
name: superstars-security
description: Proactively check recent changes for security risks, secrets, and policy-as-code gaps. Prioritize findings by severity with concrete remediation steps.
tools: Read, Grep, Glob, Bash
model: inherit
---

```

Performance optimizer:

```markdown
---
name: superstars-perf
description: Use to detect N+1s, blocking I/O, and algorithmic hot spots. Provide measurements or guidance to add traces/benchmarks and propose concrete fixes.
tools: Read, Grep, Glob, Bash
model: inherit
---

```


## Install globally or per-project

User-level (reusable everywhere):

```bash
mkdir -p ~/.claude/agents
# Save files such as:
# ~/.claude/agents/superstars-codereviewer.md
# ~/.claude/agents/superstars-testfix.md
# ~/.claude/agents/superstars-architect.md
```

Project-level (checked into VCS, overrides user-level if names collide):

```bash
mkdir -p .claude/agents
# Save/commit the same files under .claude/agents/
```


## Make Claude delegate proactively (no micromanaging)

Claude delegates automatically based on:

- Your request’s content
- Subagent `description` text (triggers)
- Available tools and current model
- Context of the session

To increase proactive selection:

- Write specific, action-oriented `description`s with real triggers:

    - “Use proactively after code changes; review only the diff.”

    - “Use when tests fail; run tests, fix, and re-run.”

    - “Use when asked for an architecture or migration plan spanning services.”

- Grant only the tools needed for the role (principle of least privilege). Missing essential tools (for example, `Read`, `Bash`, or `Edit`) can reduce the likelihood of selection or block the agent.

- Keep one clear responsibility per subagent. Single-purpose agents are matched more reliably.

- Start with `model: inherit` unless you have a strong reason to force a specific alias (for example, `haiku` for CI fix-ups, `opus` for final decision papers).


## Manage and verify

Interactive management:

```text
/agents
```

You can view all available subagents (built-in, plugin, user, and project), create/edit/delete them, and adjust tool permissions.

Quick verification workflow:

- After adding your files, run `/agents` and confirm your subagents appear.

- Try a vanilla request and let Claude choose:

    - “I just updated the payments service; review only the diff for security and performance regressions.”

- If the wrong agent is picked (or none):

    - Strengthen the `description` triggers.

    - Ensure the tools list covers what the role will actually do.

    - Avoid overlapping scopes across agents with similar names.


## Models and configuration tips

Aliases:

- `sonnet` → balanced for most agentic coding and orchestration

- `haiku` → fast and cost-efficient for interactive edit–run–fix, CI hygiene

- `opus` → best for final, high-rigor documents and deep reasoning

Session-level settings:

- Start the session with a model alias:

    ```bash
    claude --model sonnet
    ```

- Switch mid-session:

    ```text
    /model sonnet
    ```

Default subagent model:

- You can set the default model used by subagents (when `model` is omitted) via:

    ```bash
    export CLAUDE_CODE_SUBAGENT_MODEL=sonnet
    ```

Prompt caching controls (optional):

- Global disable:

    ```bash
    export DISABLE_PROMPT_CACHING=1
    ```

- Per-tier disables (for debugging):

    ```bash
    export DISABLE_PROMPT_CACHING_HAIKU=1
    export DISABLE_PROMPT_CACHING_SONNET=1
    export DISABLE_PROMPT_CACHING_OPUS=1
    ```


## Define session-only subagents via CLI (optional)

You can define subagents on the fly with the `--agents` flag (lower priority than project-level, higher than user-level):

```bash
claude --agents '{
    "code-reviewer": {
        "description": "Expert code reviewer. Use proactively after code changes.",
        "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
        "tools": ["Read", "Grep", "Glob", "Bash"],
        "model": "sonnet"
    }
}'
```


## Write bulletproof system prompts

In each subagent’s body (below the YAML frontmatter):

- Provide a short “When invoked” checklist:

    - “Run git diff and focus only on modified files.”

    - “If tests fail, reproduce and provide the minimal fix.”

- Define output structure clearly (for example, critical/warnings/suggestions with file:line references and concrete fixes).

- Add guardrails (for example, “Preserve test intent”, “No large code dumps—summarize with examples”).

- Add hand-off guidance sparingly (for example, “If a deep migration is required, produce a plan and stop; another agent may implement”).


## Troubleshooting

Agent does not appear in `/agents`:

- Ensure the YAML frontmatter is at the very top with `---` delimiters.

- Confirm required fields: `name`, `description`.

- Use `.md` extension and readable permissions.

- Restart the CLI if needed.

Delegation not triggering:

- Make `description` more specific and action-oriented (clear triggers).

- Avoid overlapping scopes across similarly named agents.

- Confirm tools list covers the role’s needed actions (for example, add `Edit`/`Write` if making changes).

- Prefer `model: inherit` initially to reduce model mismatch.

Name conflicts:

- Precedence: project `.claude/agents/` → CLI `--agents` → user `~/.claude/agents/`.

- Rename one agent to separate scopes if both are required.


## Quick checklist

- Create `~/.claude/agents/*.md` with proper YAML frontmatter.

- Use strong, action-oriented `description`s with clear triggers.

- Grant minimal tools required; inherit all by omitting `tools`.

- Prefer `model: inherit` unless you have strong reasons otherwise.

- Verify with `/agents`, then test with a vanilla request and expect proactive delegation.

- Iterate on descriptions/tools if Claude doesn’t auto-select the right subagent.


## Appendix: choosing the right model for the role

- `haiku`: speed/cost for CI hygiene, quick edits, and high-volume loops.

- `sonnet`: default choice for multi-step coding, planning, and tool orchestration.

- `opus`: reserve for “final say” documents (RFCs, threat models) and deep reasoning.

Tie this to your v3-superstars taxonomy (for example, `superstars-codereviewer` → `inherit`/`sonnet`, `superstars-testfix` → `inherit`/`haiku`, `superstars-architect` → `sonnet`, `superstars-security` → `sonnet`/`opus` when producing decision papers).

