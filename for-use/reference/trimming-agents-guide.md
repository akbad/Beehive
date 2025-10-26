# Trimming v2‑complete templates into production‑ready agent files

This is a self‑contained, foolproof playbook to convert the thorough templates in `agents/swe/v2-complete/` into:

- A short clink role prompt (body‑only, no YAML)
- An optional Claude Code subagent file (YAML frontmatter + body)

while preserving all critical information by linking to the correct must‑read references and deep dives.


## outputs you will produce

- clink role prompt (for Zen `clink`)
    
    - Body‑only “delta” role prompt
    - Target: 600–2,000 characters (≈100–320 words; ≈10–35 lines)

- Claude Code subagent (optional, when you want Claude to delegate proactively)
    
    - Markdown with YAML frontmatter
    - Target: 1,200–5,000 characters for Sonnet 4.5 (≈200–800 words), or 1,200–4,000 for Opus 4.1

Produce one or both per v2 template depending on how the role will be used. Default to producing both if unsure.


## canonical structure to preserve critical meaning

Keep instruction density high by compressing into these sections. Do not restate the CLI’s own developer/system message.

- Role and scope
    
    - 2–3 bullets describing what the agent does and boundaries.

- When to invoke (triggers)
    
    - 3–6 bullets using concrete, actionable triggers ("after tests fail", "immediately after code edits").

- Approach / workflow
    
    - 3–6 bullets with the steps the agent will take; prefer verbs and observed behavior.

- Must‑read files (progressive disclosure)
    
    - 3–5 links to Tier‑1/2/3 references (see mapping below). Never inline large docs.
    - Format in-repo references as Markdown links using relative paths, for example: the [compact MCP list](./compact-mcp-list.md) and the [code search guide](./mcps-by-category/code-search.md).

- Output format
    
    - 3–6 bullets describing the expected deliverable shape (sections, tables, JSON hints), not prose examples.

- Constraints and handoffs
    
    - 3–6 bullets that include MUST/SHOULD/AVOID rules and clear delegation/approval cues.


## length targets and measurement

Use character counts as the primary budget.

```bash
# counts
wc -m path/to/prompt.md   # characters
wc -w path/to/prompt.md   # words (secondary)
wc -l path/to/prompt.md   # lines (secondary)

# find overly long lines (top 10)
awk '{ print length, $0 }' path/to/prompt.md | sort -nr | sed -n '1,10p'
```

- clink role prompt: 600–2,000 chars (hard cap ≈2,200)
- Claude subagent: 1,200–5,000 (Sonnet) or 1,200–4,000 (Opus)

If over budget, compress by turning prose into bullets, eliminating examples, and moving details to must‑read links.


## what counts as “critical information” (keep) vs “background” (link)

KEEP (must be present, compact):

- Clear role/scope and triggers to ensure correct routing/delegation
- Minimal workflow steps (what the agent will actually do first)
- Guardrails (security, approvals, “do not …” rules)
- Output contract (sections, format expectations)
- Tooling intent at the category level (e.g., “web research with citations”, “symbol‑level code edits”), not per‑tool how‑tos

LINK (reference, don’t inline):

- Tool selection and parameters → Tier‑1 compact MCP list; Tier‑2 category guides; Tier‑3 deep dives
- Long operational policies, examples, and tutorials
- Provider/model details unless selection genuinely matters (see model selection below)

DROP (omit):

- Repetition of CLI developer/system messages
- Redundant examples (keep one short example only if absolutely necessary)
- Vendor marketing or generic best‑practice essays


## map v2 template content → trimmed sections and references

Use this mapping to relocate content out of the long template into concise sections and links.

- Tooling “how to choose/search/fetch” → Must‑read links
    
    - Tier‑1: the [compact MCP list](./compact-mcp-list.md)
    - Tier‑2 categories: [web research](./mcps-by-category/web-research.md), [code search](./mcps-by-category/code-search.md), [memory](./mcps-by-category/memory.md), [documentation](./mcps-by-category/documentation.md)
    - Tier‑3 deep dives: see [deep dives](./mcp-deep-dives/) such as [tavily](./mcp-deep-dives/tavily.md), [brave](./mcp-deep-dives/brave.md), [exa](./mcp-deep-dives/exa.md), [fetch](./mcp-deep-dives/fetch.md), [firecrawl](./mcp-deep-dives/firecrawl.md), [serena](./mcp-deep-dives/serena.md), [sourcegraph](./mcp-deep-dives/sourcegraph.md), [context7](./mcp-deep-dives/context7.md), [semgrep](./mcp-deep-dives/semgrep.md), [memory](./mcp-deep-dives/memory.md), [qdrant](./mcp-deep-dives/qdrant.md), [zen](./mcp-deep-dives/zen.md)

- Delegation and handoff logic → Must‑read handoff guidelines (if present in your project)
    
    - Example reference: the [handoff guidelines](../handoff-guidelines.md) (if available)
    - If missing, capture 3–4 bullets in Constraints for when to use clink/Task/AskUserQuestion

- Style rules → Docs/code style guides
    
    - the [docs style guide](./style-guides/docs-style-guide.md)
    - the [code style guide](./style-guides/code-style-guide.md) (if populated in your project)


## minimal tool and model guidance to include

Tools (principle of least privilege):

- clink role prompts: do not list tools; keep the body tool‑agnostic and let references cover choices.
- Claude subagents: either omit `tools:` (inherit) or specify a minimal set only when needed (e.g., `Read, Grep, Glob, Bash`; add `Edit, Write` for fixers).

Model selection (defaults and exceptions):

- Default: `inherit` (use session model)
- Prefer `sonnet` for multi‑step coding/orchestration
- Prefer `haiku` for fast edit–run–fix CI loops (test fixers)
- Reserve `opus` for final decision docs and deep analysis


## templates to copy‑paste

clink role prompt (600–2,000 chars):

```markdown
You are a ROLE specialist.

Role and scope:
- State the narrow responsibility
- Name key boundaries (what you will not do)

When to invoke:
- Trigger A (e.g., immediately after code edits)
- Trigger B (e.g., when tests fail)
- Trigger C (e.g., planning across services)

Approach:
- Step 1 (short, actionable)
- Step 2 (short, actionable)
- Step 3 (short, actionable)

Must‑read at startup:
- the [compact MCP list](./compact-mcp-list.md) (Tier 1 tool selection)
- the [web research guide](./mcps-by-category/web-research.md) or the [code search guide](./mcps-by-category/code-search.md) (Tier 2, pick relevant)
- the [Serena deep dive](./mcp-deep-dives/serena.md) or the [Tavily deep dive](./mcp-deep-dives/tavily.md) (Tier 3, pick relevant)

Output format:
- Specify sections/table or JSON fields expected

Constraints and handoffs:
- Do not restate long docs; link and read as needed
- Use clink for cross‑model delegation when needed
- AskUserQuestion if approvals/requirements are unclear
```

Claude Code subagent (YAML + body; 1,200–5,000/4,000 chars):

```markdown
---
name: your-subagent-name
description: Action‑oriented trigger text for proactive delegation ("Use proactively after X"; "Use when Y fails").
tools: Read, Grep, Glob, Bash          # omit to inherit all; add Edit, Write only if required
model: inherit                          # or sonnet/haiku/opus per "model selection"
---

Role and scope:
- Brief summary and clear boundary

When to invoke:
- Trigger A
- Trigger B
- Trigger C

Approach:
- Step 1
- Step 2
- Step 3

Must‑read at startup:
- the [compact MCP list](./compact-mcp-list.md) (Tier 1)
- the relevant [category guide](./mcps-by-category/) (Tier 2)
- the relevant [deep dive](./mcp-deep-dives/) (Tier 3, only if needed)
- the [docs style guide](./style-guides/docs-style-guide.md) (when writing docs)

Output format:
- Bulleted deliverable contract

Constraints and handoffs:
- Safety/approval rules; minimal edits first; delegate with clink when cross‑model fits better
- AskUserQuestion when requirements/approvals are ambiguous
```


## compression playbook (from v2 template → trimmed)

1) Skim and tag content

- Highlight MUST/SHOULD/AVOID sentences → move to Constraints
- Find triggers (“when…”, “after…”) → move to When to invoke
- Extract the first 3–6 concrete steps → move to Approach
- Identify outputs/deliverables → compress into Output format bullets
- Any tool tutorials → replace with links to Tier‑1/2/3 references

2) Reduce length without losing meaning

- Convert paragraphs to bullets; remove filler and hedging
- Keep one short example only if it drastically clarifies intent
- Replace repeated cautions with a single “Constraints” bullet
- Prefer category phrasing ("use web research with citations") over vendor names; details live in references

3) Add must‑read links (progressive disclosure)

- Always include Tier‑1 compact MCP list
- Add the one most relevant Tier‑2 category
- Include at most one Tier‑3 deep dive initially; agent can open more on demand

4) Finalize model/tools minimally

- Subagent: set `model: inherit` unless there’s a strong reason otherwise
- Tools: only list when restricting is valuable; otherwise omit `tools:` to inherit

5) Validate against budgets

```bash
wc -m path/to/role.md     # 600–2,000 chars (clink)
wc -m path/to/subagent.md # 1,200–5,000 (Sonnet) or 1,200–4,000 (Opus)
```


## acceptance checklist (must pass)

- Length within target budgets (measured via `wc -m`)
- Has Role/scope, Triggers, Approach, Must‑reads, Output, Constraints
- Contains no long inlined tool docs or policy walls
- Points to Tier‑1 compact MCP list and the single most relevant Tier‑2 category guide
- Includes at most one Tier‑3 deep dive link (more can be opened as needed)
- Subagent only: YAML frontmatter present, `name` unique, `description` action‑oriented, minimal `tools`/`model` set
- Style basics followed (clear bullets, sentence‑case headers, sensible spacing)


## worked micro‑example (before → after)

Before (v2 excerpt, paraphrased):

> As a performance optimizer, first explore flamegraphs, then look for N+1 queries and blocking I/O. Consider cache strategies, concurrency, and database indexes. Provide a detailed plan with measurements and trade‑offs. Use Tavily/Brave for research. Consider Semgrep for hotspots. Avoid premature micro‑optimizations; keep changes minimal.

After (clink role prompt slice):

```markdown
Role and scope:
- Performance optimization with minimal, measurable changes

When to invoke:
- After benchmarks/regressions indicate hotspots
- When users report latency spikes

Approach:
- Profile (flamegraphs, tracing) → confirm top 1–2 bottlenecks
- Target N+1/blocked I/O first; prefer low‑risk fixes
- Re‑measure and record deltas; repeat

Must‑read at startup:
- the [compact MCP list](./compact-mcp-list.md)
- the [code search guide](./mcps-by-category/code-search.md)
- the [Semgrep deep dive](./mcp-deep-dives/semgrep.md)

Output format:
- Summary (baseline, targets) • Findings (ranked) • Fix plan • Metrics deltas

Constraints and handoffs:
- Avoid premature micro‑optimization; prefer reversible changes
- AskUserQuestion if benchmarks/SLAs are unclear
```


## file placement and naming

- clink role prompts → keep with your clink config or project prompts; body‑only
- Claude subagents → `.claude/agents/` (project‑level) or `~/.claude/agents/` (user‑level)
- Use lowercase, hyphenated names (e.g., `perf-optimizer`, `superstars-codereviewer`)


## troubleshooting quick fixes

- Over budget → collapse prose into bullets; replace inlined how‑tos with Tier‑2/3 links
- Not delegating proactively → strengthen `description` triggers; narrow scope
- Tool confusion → ensure Tier‑1/2 links present; avoid listing vendor specifics in body
- Frequent edits needed → prefer `model: haiku` for test‑fixer subagents


## recap

- Preserve meaning by compressing into role, triggers, workflow, output, constraints
- Keep the prompt short; move depth into must‑read references
- Validate with `wc -m`; aim for 600–2,000 (clink) and 1,200–5,000/4,000 (subagent)
