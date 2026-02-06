---
description: Two-phase code assessment workflow (architectural comprehension then quality audit) that adapts output to context. Interactive guided tour when running as a main agent; structured markdown report when running as a subagent. Activate when user says "assess my changes", "review my changes", "walk me through this code", "audit these files", or "ASSESS MODE ON". Configurable standards sources and git diff targets.
---

# Assess mode: *protocol*

> <ins>***Goal:** understand, then audit*</ins>
>
> *Two-phase review of code changes: first build a mental model of what changed and why, then audit every file against configured quality standards. Adapt delivery to context: interactive tour if running as a main agent, and written report if running as an isolated subagent.*

> [!IMPORTANT]
>
> The directives below are **non-negotiable hard constraints** to be followed **exactly as they are specified**.

## Formatting

Read and follow `style.md` (bundled with this skill) for **all** output: interactive messages, written reports, and any files you create or edit. No exceptions.

## Activation

When the user says anything like:

- "assess my changes"
- "assess this branch"
- "review my changes"
- "review this branch"
- "walk me through this code"
- "audit these files against my standards"
- "ASSESS MODE ON"

*Follow this assess mode protocol.* If you are unsure, confirm unambiguously with the user.

## Determine inputs

### Target *(what to review)*

- If the user provides **explicit files or directories** in their prompt, review those
- Otherwise, use **git diff** against the ref configured in `assess_mode.default_diff` (default: `HEAD`)

    - Include both modified (staged + unstaged) and untracked files
    - Run `git diff --name-only <ref>` and `git ls-files --others --exclude-standard` to collect the full changeset

### Standards sources *(what to check against)*

- Resolve in this order:

    1. User provides paths in their activation prompt → use those
    2. `assess_mode.standards_sources` in config → use those
    3. Neither found → the quality audit still runs but only checks internal consistency (DRYness, algorithmic efficiency, codebase pattern consistency); explicitly inform the user that no external standards docs were found

- Read all resolved standards documents before beginning the audit phase

### Mode *(how to deliver results)*

- **Interactive** → default when running as a main/direct agent in conversation with the user
- **Report** → default when spawned as a subagent; also triggered when the user explicitly requests a report (e.g. "review my changes and write a report")

## Phase 1: comprehension

### Internal prep *(do not show to user)*

1. Collect the full changeset (all files to review)
2. Read every changed/new file
3. Build a dependency graph → which files import, call, or reference which
4. Identify **logical groups** → cluster files by module, directory, or purpose (e.g. "config loading", "MCP setup", "test suite")
5. For each file, extract: purpose, key functions/classes, invariants, design decisions
6. Identify cross-cutting concerns: shared utilities, common patterns, config flow

### Present style choice *(interactive mode only)*

> [!NOTE]
>
> In **report mode**, skip this prompt and use the **layered walkthrough** by default (it reads well as a document).

Present the user with this choice:

> How would you like me to walk you through these changes?
>
> 1. **Top-down summary** → one cohesive narrative of what the changeset does, then move to quality audit; best when you roughly know what changed and just need confirmation
> 2. **Layered walkthrough** → executive summary, then component map, then per-component deep dive, with pauses between layers; best when you want to build a mental model incrementally
> 3. **Dependency-ordered** → foundational modules first, consumers last, like reading a textbook; best when the code is unfamiliar and you want to understand it in the order it was designed to be understood
> 4. **Skip** → go straight to quality audit

### Execute comprehension

#### Top-down summary

- Present a single architectural narrative covering the entire changeset
- One pause for questions, then proceed to Phase 2

#### Layered walkthrough

- **Layer 1:** one-paragraph executive summary of the entire changeset
- **Layer 2:** component map → the 3-5 logical groups of files, what each group does, how they connect
- **Layer 3:** per-component deep dive → design decisions, data flow, invariants for each group
- **Pause after each layer**; the user can:

    - Ask questions about the current layer
    - Say "continue" or "next" to proceed to the next layer
    - Say "skip to audit" to jump to Phase 2
    - Say "go deeper on this" to expand a section

#### Dependency-ordered

- Topologically sort the changes (foundational modules first, consumers last)
- Walk through each file/module in dependency order, explaining what it does and why
- **Pause after each module**; same user controls as layered walkthrough

## Phase 2: quality audit

### Check categories

For each file in the changeset, check against these six categories:

1. **DRYness** → duplicated logic within the file *and* across the changeset; also flag over-abstraction (functions with too many parameters just to avoid trivial repetition)
2. **Algorithmic efficiency** → wrong data structure, unnecessary complexity class, suboptimal library choice, unnecessary iterations
3. **Consistency with codebase patterns** → does the new code follow conventions already established in the project (naming, structure, idioms, error handling)?
4. **Coding style** → checked against the configured standards docs (docstring format, comment style, naming conventions, file organization)
5. **Correctness concerns** → edge cases, potential race conditions, missing error handling, invariant violations (not a full security audit, but obvious issues)
6. **Design fit** → does this module belong where it is, are the abstractions at the right level, is anything over- or under-engineered?

### Severity levels

- **Must fix** → correctness bug, security issue, broken invariant
- **Should fix** → DRY violation, algorithmic inefficiency, clear style violation
- **Consider** → subjective design opinion, minor style nit, potential improvement

### Finding numbering

- Every finding is **numbered sequentially** across the entire review: `#1` through `#N`
- Numbering is **global** (not per-file, not per-severity)
- This enables quick referencing in follow-up prompts (e.g. "fix #3 and #7, ignore #5")

### Interactive mode delivery

- Walk through findings **grouped by file**, in the same order used during comprehension
- For each finding, explain: what the issue is, why it matters, and a suggested fix
- After each finding (or group of findings per file), pause for user response:

    - Agree: "fix it" / "noted" / "will fix"
    - Disagree: "that's intentional, here's why"
    - Ask for more context: "why is this a problem?"
    - Batch response: "fix #3 and #7, ignore #5"

### Report mode delivery

- Write a structured markdown document following the template below
- Findings appear in a summary table at the top, then in detail sections grouped by severity

## Wrap-up

### Interactive mode

- Summarize: "**N** must-fix, **M** should-fix, **K** consider"
- Ask if the user wants any findings addressed now

### Report mode

- Write the report to `docs/reviews/YYYY-MM-DD-<branch-or-topic>.md`
- Return a one-paragraph summary to the calling agent/user with finding counts

## Report template

> [!IMPORTANT]
>
> This template defines the **structure** of the report. Follow the `style.md` formatting guidelines for all content within it.

```markdown
# Code review: <branch or topic>

> **Generated:** <date> | **Target:** <git diff spec or file list>
> **Standards:** <list of standards source files used>

## Executive summary

- <2-3 bullets: what the changeset does, how many files, overall assessment>

## Architecture

### Component map

- **<Group 1 name>** — <purpose>

    - Files: `file1.py`, `file2.py`
    - Connects to: <Group 2> via <mechanism>

- **<Group 2 name>** — <purpose>

    - Files: `file3.sh`, `file4.sh`

### Per-component detail

#### <Group 1 name>

- **Purpose:** <what this group does>
- **Design decisions:**

    - <decision 1 and why>
    - <decision 2 and why>

- **Data flow:** <how data moves through this component>
- **Invariants:** <what must always be true>

## Findings

| # | File | Severity | Summary |
| --- | --- | --- | --- |
| 1 | `operations/mcp_catalog.py` | Should fix | Duplicated validation logic |
| 2 | `tools/scripts/set-up-tools.sh` | Must fix | Unquoted variable expansion on line 247 |

### Must fix

#### #2 — <title>

- **File:** `<path>:<line>`
- **Problem:** <explanation>
- **Why it matters:** <impact>
- **Suggested fix:** <what to do>

### Should fix

#### #1 — <title>

- **File:** `<path>:<line>`
- **Problem:** <explanation>
- **Suggested fix:** <what to do>

### Consider

#### #3 — <title>

- **File:** `<path>`
- <explanation>

## Summary

- **Must fix:** N findings
- **Should fix:** M findings
- **Consider:** K findings
```

## Compatibility with other Bureau workflows

- **Micro mode:** review findings can inform DAG construction; fixes become micro edits
- **Systematic debugging:** if a review finding reveals a bug, the user can invoke systematic debugging on that specific finding
- **Handoff guidelines:** in report mode, the skill is designed to run as a subagent; the calling agent can use findings to drive follow-up work
- **TDD skill:** "must fix" correctness findings can become test cases first (red), then fixes (green)
