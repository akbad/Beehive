# Agent prompt lengths for Claude Code subagents and Zen clink roles

This guide gives foolproof, source-backed recommendations for how long your subagent and role prompts should be (in characters, words, and lines), plus exact steps to measure and validate them across:

- Claude Code subagents for Sonnet 4.5 and Opus 4.1

- Zen’s clink role prompts used to spawn subagents in Claude Code (Haiku 4.5, Sonnet 4.5, Opus 4.1), Codex CLI (GPT‑5 and GPT‑5‑Codex), and Gemini CLI (Gemini 2.5 Pro)


## executive summary

- Claude Code subagents

    - Sonnet 4.5: 1,200–5,000 characters (≈200–800 words; ≈15–60 lines)

    - Opus 4.1: 1,200–4,000 characters (≈200–650 words; ≈15–50 lines)

    - Structure: frontmatter with a focused `description`, plus 2–4 short sections and a compact checklist.

- Zen clink role prompts (all CLIs)

    - General: 600–2,000 characters (≈100–320 words; ≈10–35 lines)

    - Keep them role‑specific "deltas" instead of restating each CLI's full developer/system message.

    - Zen handles very large prompts via a file‑handoff path around ~50,000 characters, but shorter role prompts perform better in practice.

- Must‑read files (referenced in role prompts, read via Read tool)

    - Tool list (compact): 1,000–1,500 characters

    - Style guide: 1,200–2,000 characters

    - Handoff guidelines: 1,800–2,800 characters

    - Combined maximum for typical agent: ~6,300 characters ≈ 1,600 tokens (well within MCP budget)

- Model‑specific emphasis

    - GPT‑5‑Codex: favor the minimum. 400–1,500 characters; "less is more."

    - GPT‑5: 1,500–4,000 characters when extra guardrails are truly needed; avoid duplicating the CLI developer message.

    - Gemini 2.5 Pro: 600–2,000 characters; concise system instructions outperform long manifestos even with a 1M context window.

    - Claude Haiku 4.5 (clink roles): 600–1,500 characters; tight, prescriptive role cues.


## how to measure length locally

Use these commands from the repo root to check characters, words and lines.

```bash
# Count Unicode characters and lines
wc -m agents/how-tos/agent-prompt-lengths.md
wc -l agents/how-tos/agent-prompt-lengths.md

# Count words (approximate tokens/lines guidance)
wc -w agents/how-tos/agent-prompt-lengths.md

# Show line lengths to spot very long lines
awk '{ print length, $0 }' path/to/prompt.md | sort -nr | sed -n '1,10p'
```

Notes:

- Character counts are the best simple proxy for “prompt size.” Word and line counts are provided only as secondary guardrails.

- If your terminal uses different locale settings, ensure `LC_ALL`/`LANG` are set to a UTF‑8 locale so `wc -m` counts characters correctly.


## Claude Code subagents

### file shape and where they live

Claude Code stores subagents as Markdown with YAML frontmatter.

```markdown
---
name: code-reviewer
description: Expert code review specialist. Proactively reviews code for quality, security, and maintainability. Use immediately after writing or modifying code.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a senior code reviewer ensuring high standards of code quality and security.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Begin review immediately

Checklist:
- Code is simple and readable
- Proper error handling
- No secrets
```

Locations:

- Project subagents: `.claude/agents/` (highest precedence)

- User subagents: `~/.claude/agents/`

The `/agents` command provides an interactive UI to create and edit subagents.

References: Anthropic subagents docs (file format, locations, management).


### ideal lengths and why

- Sonnet 4.5: 1,200–5,000 characters (≈200–800 words; ≈15–60 lines)

    - Sonnet 4.5’s context awareness and instruction following work best with specific, actionable guidance rather than long policy dumps. A few short sections (role, approach, “when invoked”, compact checklist) are ideal.

- Opus 4.1: 1,200–4,000 characters (≈200–650 words; ≈15–50 lines)

    - Opus is tuned for depth and rigorous review, but longer prompts still incur cold‑start latency and can dilute the instruction signal. Keep them focused.

Do this:

- Put proactive routing cues in `description` (for example, “use PROACTIVELY”, “MUST BE USED”).

- Keep the body to role, approach, and a short checklist. Link to longer house rules rather than pasting them inline.

Avoid this:

- Boilerplate that restates the CLI’s own system behavior.

- Large “policy” sections that rarely affect behavior on a given task.

Notes on context windows and cost:

- Sonnet 4/4.5 support large windows (200k standard; 1M beta for eligible orgs). Bigger windows help tasks, not initial instruction quality. Longer prompts still increase latency and cost.


## Zen clink roles

### what clink roles are

Zen’s `clink` tool spawns another CLI (Gemini, Codex, Claude Code) as an isolated subagent using a role prompt referenced by `prompt_path`. These roles are short, role‑specific system prompts that complement the spawned CLI’s own developer/system message.

References: Zen repository docs for `clink` and bundled role prompt examples.


### recommended lengths

- General (all CLIs): 600–2,000 characters (≈100–320 words; ≈10–35 lines)

    - Zen’s shipped role prompts (`systemprompts/clink/*.txt`) cluster around 700–900 bytes. They are intentionally short and performant.

- Claude Code via clink

    - Haiku 4.5: 600–1,500 characters

    - Sonnet 4.5: 800–2,000 characters

    - Opus 4.1: 800–1,800 characters

- Codex CLI via clink

    - GPT‑5‑Codex: 400–1,500 characters; favor the minimum.

    - GPT‑5: 1,500–4,000 characters if truly needed; otherwise prefer minimal role deltas.

- Gemini CLI via clink

    - Gemini 2.5 Pro: 600–2,000 characters; concise system instructions work best despite a 1M context window.


### where to place role prompts and how to reference them

Common user‑level layout (recommended for reuse across projects):

```text
~/.zen/
    cli_clients/
        gemini.json
        codex.json
        claude.json
        systemprompts/
            clink/
                my-roles/
                    planner.md
                    codereviewer.md
```

Example `~/.zen/cli_clients/gemini.json` using relative `prompt_path`:

```json
{
    "name": "gemini",
    "command": "gemini",
    "additional_args": ["--yolo", "-o", "json"],
    "env": {},
    "roles": {
        "default": { "prompt_path": "systemprompts/clink/default.txt" },
        "planner": { "prompt_path": "systemprompts/clink/my-roles/planner.md" },
        "codereviewer": { "prompt_path": "systemprompts/clink/my-roles/codereviewer.md" }
    }
}
```

Resolution rules:

- Relative `prompt_path` resolves relative to the JSON’s directory, then falls back to the Zen project root.

- Absolute `prompt_path` is accepted as is.


### large prompts and MCP limits

- MCP requests have a combined request+response budget around ~25k tokens. Zen automatically works around very large prompts by asking the client to save the prompt to a temporary file and resubmit with a file reference when the prompt exceeds ~50,000 characters.

- This fallback is reliable, but not "ideal" for interactivity. Prefer shorter role prompts and let the subagent read files on demand.


## must‑read files (referenced in role prompts)

Key distinction:

- **Role prompt**: Read once by the spawning harness, counts toward role prompt character budget
- **Must‑read files**: Read by the spawned agent via Read tool, counts toward MCP token budget (~25k total) and context window

### context files: optimal lengths

**Tool list (compact)**: 1,000–1,500 characters (≈160–250 words; ≈15–25 lines)

- Read by nearly every agent at startup (very high frequency)
- Should be a scannable cheat sheet, not comprehensive documentation
- Format: Category → When to use → First choice → Alternatives → Link to full docs
- Typical structure: 10–12 MCP categories × 3–4 lines each ≈ 1,200 characters
- Agents needing details follow links to full reference cards (5,000+ characters)
- Token cost: ~250–400 tokens per read (acceptable startup overhead)

**Style guide**: 1,200–2,000 characters (≈200–330 words; ≈20–35 lines)

- Only code‑writing roles need this (code‑reviewer, test‑fixer; not research‑synthesizer)
- Needs actionable detail (not generic advice like "use consistent naming")
- Should cover: naming conventions, formatting rules, testing patterns, anti‑patterns
- Can be language‑specific or multi‑language depending on project scope
- Slightly longer budget justified since it's role‑specific, not universal
- Token cost: ~300–500 tokens (reasonable for code‑editing agents)

**Handoff guidelines**: 1,800–2,800 characters (≈300–470 words; ≈30–50 lines)

- Most complex must‑read (decision trees, delegation matrices)
- All agents need this (universal)
- Critical for correct delegation behavior (token cost justified)
- Needs 4 sections: clink usage, Task tool usage, AskUserQuestion scenarios, approval requirements
- Each section needs examples plus decision matrix
- Maximum stretch to 3,000 characters for complex projects, but aim for <2,500
- Token cost: ~450–700 tokens (prevents costly delegation errors)

> Use `wc -m [path]` to validate that a file has the appropriate length.

### must‑read file length decision table

**Tool documentation (3-tier MCP lookup):**

| Tier | File Type | Ideal Length (chars) | Max Length (chars) | Read Frequency | Token Cost |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Compact tool list | 1,000–1,500 | 1,800 | Every agent | ~250–400 |
| 2 | Category reference | 3,500–5,000 | 6,000 | When comparing options | ~900–1,250 |
| 3 | Per-MCP deep dive | 4,000–6,000 | 8,000 | Complex tools only | ~1,000–1,500 |

**Other must-reads:**

| File Type | Ideal Length (chars) | Max Length (chars) | Target Words | Read Frequency | Token Cost |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Style guide | 1,200–2,000 | 2,500 | 200–330 | Code‑writing roles | ~300–500 |
| Handoff guidelines | 1,800–2,800 | 3,200 | 300–470 | Every agent | ~450–700 |


## model‑specific guidance and rationale

### GPT‑5‑Codex (Codex CLI)

- Keep it minimal (400–1,500 characters). The official guidance stresses “less is more.” Avoid preamble requests and keep tool descriptions concise.

- The GPT‑5‑Codex developer message used by Codex CLI is ~40% shorter than GPT‑5’s general developer message. Role prompts should mirror that brevity and only introduce role‑specific deltas.


### GPT‑5 (Codex CLI)

- Use 1,500–4,000 characters only when you truly need extra constraints beyond the CLI’s built‑in developer message. Do not restate the entire developer message in a role prompt.


### Gemini 2.5 Pro (Gemini CLI)

- 600–2,000 characters is the sweet spot. Concise, explicit instructions beat long manifestos even though Gemini offers a 1M context window.

- Add examples only when they add clear value; otherwise push concrete context into files that the subagent can read.


### Claude Sonnet 4.5 and Haiku 4.5 (Claude Code)

- Sonnet 4.5: favor clear, actionable instructions. Include short notes about context compaction/continuation only if your harness uses them; keep such “operational” guidance to 2–4 sentences.

- Haiku 4.5: keep role prompts tighter (600–1,500 characters) and prescriptive.


### Claude Opus 4.1 (Claude Code)

- Opus excels at depth. Keep the role directive compact (≈800–1,800 characters for clink roles; 1,200–4,000 for full subagents) and let Opus gather needed context via tools rather than front‑loading long policy blocks.


## foolproof checklists

### before you write

- Decide which harness you target first (Claude Code subagent vs clink role). This determines whether you include YAML frontmatter and how much the spawned CLI already brings in its own developer message.

- Identify “role deltas” only. What must this role add that the base CLI policy does not already provide?


### while you write

- Keep the prompt between the recommended character ranges for the specific model/CLI.

- Favor short sections:

    - Role and scope (2–4 sentences)

    - When invoked (3–6 bullet steps)

    - Checklist (5–10 short bullets)

    - Constraints and formatting (3–6 short bullets)

- Put proactive routing cues in `description` (for Claude subagents) rather than burying them in the body.


### after you write

- Measure size with `wc -m` and `wc -l` and compare to the ranges above.

- Smoke test by actually spawning the role/subagent:

    - Claude Code: run `/agents`, create or edit, and invoke it explicitly once to confirm behavior.

    - clink: issue a prompt like `clink with gemini role=planner to outline a three‑phase rollout` and verify the role sticks.

- If you exceed ~50k characters and see a “save prompt to file and retry” behavior, refactor the role prompt down and move long background context into files for the subagent to open on demand.


## examples: compact role prompts that fit the ranges

### clink planner role (≈900–1,200 characters)

```markdown
You are a planning agent coordinating safely across tools.

Goals:
- Produce an actionable, phased plan
- Call out risks and mitigations
- Keep steps concise and testable

When invoked:
1. Inspect the repository layout and recent changes
2. Identify dependencies and validation gates per phase
3. Propose 2–3 alternatives where trade‑offs matter
4. Return a JSON plan with steps, owners, and verification notes

Constraints:
- Avoid repeating file contents verbatim
- Prefer minimal, incremental changes first
- Keep the summary under 500 words
```

### Claude Code subagent body (Sonnet 4.5, ≈2,000–3,000 characters)

```markdown
You are a senior code reviewer for safety, security, and maintainability. Be direct and specific.

When invoked:
1. Read recent diffs, then open changed files first
2. Prioritize correctness, security, and performance
3. Propose minimal viable fixes before refactors

Checklist:
- Simplicity and readability
- Naming clarity and API contracts respected
- Error handling and edge cases
- No secrets or hardcoded credentials
- Tests updated or added where behavior changes

Constraints:
- Do not speculate about files you have not opened
- Keep findings ordered by severity; cite files/lines
- Offer one concrete fix per finding whenever possible
```


## references and sources

- Claude Code subagents (format, management, examples):

    - https://docs.claude.com/en/docs/claude-code/sub-agents

- Claude 4 prompt engineering best practices (Sonnet 4.5, Opus 4.1, Haiku 4.5):

    - https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices

- Claude context windows and long‑context pricing:

    - https://docs.claude.com/en/docs/build-with-claude/context-windows#1m-token-context-window

    - https://docs.claude.com/en/docs/about-claude/pricing#long-context-pricing

- Zen MCP clink tool and bundled role prompts:

    - Clink overview: https://github.com/BeehiveInnovations/zen-mcp-server/blob/main/docs/tools/clink.md

    - Example role prompts (short, ~700–900 bytes): https://github.com/BeehiveInnovations/zen-mcp-server/tree/main/systemprompts/clink

    - Working with large prompts (file‑handoff around ~50k chars): https://github.com/BeehiveInnovations/zen-mcp-server/blob/main/docs/advanced-usage.md#working-with-large-prompts

- Codex CLI developer messages and GPT‑5‑Codex guidance:

    - GPT‑5‑Codex prompting guide (“less is more”): https://cookbook.openai.com/examples/gpt-5-codex_prompting_guide

    - Codex CLI dev messages: https://github.com/openai/codex/blob/main/codex-rs/core/gpt_5_codex_prompt.md and https://github.com/openai/codex/blob/main/codex-rs/core/prompt.md

- Gemini prompt design strategies and system instructions:

    - https://ai.google.dev/gemini-api/docs/prompting-strategies

    - https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/system-instructions


## appendix: quick decision table

### role prompts

| Target | Model | Ideal length (characters) | Notes |
| :--- | :--- | :--- | :--- |
| Claude Code subagent | Sonnet 4.5 | 1,200–5,000 | Detailed but focused; use short sections and a checklist |
| Claude Code subagent | Opus 4.1 | 1,200–4,000 | Depth with brevity; avoid policy walls |
| clink role → Claude Code | Haiku 4.5 | 600–1,500 | Tight and prescriptive |
| clink role → Claude Code | Sonnet 4.5 | 800–2,000 | Short role delta; let tools fetch context |
| clink role → Claude Code | Opus 4.1 | 800–1,800 | Keep role compact; Opus gathers details |
| clink role → Codex CLI | GPT‑5‑Codex | 400–1,500 | Minimal; do not request preambles |
| clink role → Codex CLI | GPT‑5 | 1,500–4,000 | Only if extra guardrails are needed |
| clink role → Gemini CLI | Gemini 2.5 Pro | 600–2,000 | Concise system instructions perform best |

### must‑read files

| File Type | Ideal Length (chars) | Max Length (chars) | Read Frequency | Used By |
| :--- | :--- | :--- | :--- | :--- |
| Tool list (compact) | 1,000–1,500 | 1,800 | Every agent | All roles |
| Style guide | 1,200–2,000 | 2,500 | Code‑writing agents | code‑reviewer, test‑fixer, refactorer |
| Handoff guidelines | 1,800–2,800 | 3,200 | Every agent | All roles |
| Full tool reference (tier 2) | 4,000–6,000 | 8,000 | On‑demand | Agents needing detailed tool docs |
| Project context (tier 2) | 3,000–5,000 | 6,000 | On‑demand | Project‑specific agents |

