---
description: Two-phase code assessment workflow (architectural comprehension then quality audit) that adapts output to context. Interactive guided tour when running as a main agent; structured markdown report when running as a subagent. Supports four comprehension styles including hunk-by-hunk inline review (comprehension + audit per diff hunk). Activate when user says "assess my changes", "review my changes", "walk me through this code", "audit these files", "assess my changes hunk by hunk", "detailed review", or "ASSESS MODE ON". Configurable standards sources and git diff targets.
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
- "assess my changes hunk by hunk"
- "detailed review"
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
> In **report mode**, skip this prompt and use the **layered walkthrough** by default (it reads well as a document). The **hunk-by-hunk** style is interactive-mode only and is never used in report mode.

Present the user with this choice:

> How would you like me to walk you through these changes?
>
> 1. **Top-down summary** → one cohesive narrative of what the changeset does, then move to quality audit; best when you roughly know what changed and just need confirmation
> 2. **Layered walkthrough** → executive summary, then component map, then per-component deep dive, with pauses between layers; best when you want to build a mental model incrementally
> 3. **Dependency-ordered** → foundational modules first, consumers last, like reading a textbook; best when the code is unfamiliar and you want to understand it in the order it was designed to be understood
> 4. **Hunk-by-hunk** → walk through each diff hunk individually, explaining what changed and why, then audit it inline; best when you want the finest granularity and want to catch issues in context as they appear
> 5. **Skip** → go straight to quality audit

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

#### Hunk-by-hunk

> [!NOTE]
>
> This style **merges Phase 1 and Phase 2**: comprehension and audit happen inline per hunk. There is no separate Phase 2 pass — skip directly to [Wrap-up](#wrap-up) after all hunks are processed.

- **Parse the diff** into individual hunks via `git diff -U3 <ref>`

    - Group adjacent or overlapping hunks within the same file into a single logical unit
    - Order hunks using the same file ordering chosen during internal prep (logical groups or dependency order)

- **For each hunk (or hunk group)**, emit this block:

    ```
    Hunk N/M — <file>:<start_line>-<end_line> (<function or scope>)
    ```

    1. **Show the diff** → render the hunk as a fenced diff code block (` ```diff `)
    2. **Explain** → what changed and why (1-3 bullets; reference the dependency graph and logical groups from internal prep)
    3. **Observe** *(optional — only when the hunk warrants it)* → surface a brief observation (1-3 sentences) when this hunk reveals something non-obvious: an interesting design trade-off, an architectural decision worth noting, or a genuinely suboptimal pattern that could be improved

        - **Read before you speak:** if your observation depends on code outside this hunk (callers, sibling modules, prior art in the codebase), read that context first; do not speculate about what surrounding code does.
        - **Earn the call-out:** only flag a design as suboptimal if (a) you have ingested enough context to be confident, (b) the improvement is concrete and actionable, and (c) it is not premature abstraction or YAGNI material. A real problem with a real fix — not a hypothetical improvement
        - **Skip silently** on trivial hunks (renames, import reordering, comment edits). Forced insight on uninteresting code wastes the user's attention

    4. **Inline audit** → run all 6 check categories against *this hunk only*; emit findings using the same global sequential numbering (`#1` through `#N`) and severity levels as Phase 2

        - If no findings: emit `No findings for this hunk.`
        - If findings exist: list each as:

            ```
            #<N> [<severity>] <title>
            <one-line explanation and suggested fix>
            ```

    5. **Pause** → emit:

        ```
        User: ">" to advance | "." to skip rest of file | "deeper" to expand | "fix #N" to fix now | or ask a question
        ⏸️
        ```

    6. **Wait for user signal** before proceeding:

        | User input | Agent action |
        | --- | --- |
        | `>` or "next" | Advance to next hunk |
        | `.` or "skip" | Skip remaining hunks in current file, advance to next file |
        | `deeper` | Expand analysis: show data flow, callers/callees, invariants affected by this hunk |
        | `fix #N` | Apply the suggested fix for finding `#N` immediately, then re-show the hunk with the fix applied and re-pause |
        | A question | Answer in context of the current hunk, then re-pause on the same hunk |

- **After all hunks are processed**, proceed directly to [Wrap-up](#wrap-up) (skip Phase 2)

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

> [!NOTE]
>
> If the **hunk-by-hunk** comprehension style was used, audit findings were already delivered inline per hunk. **Skip this entire Phase 2 delivery** and proceed directly to [Wrap-up](#wrap-up).

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

> [!NOTE]
>
> In **hunk-by-hunk** mode, all findings were delivered inline. The wrap-up still aggregates them into a single summary. Include any findings the user addressed via `fix #N` as resolved.

- Summarize: "**N** must-fix, **M** should-fix, **K** consider (**R** already fixed inline)" — omit the "already fixed inline" count if zero
- Ask if the user wants any remaining findings addressed now
- If the user expressed **recurring style or design preferences** during the review (e.g. "I prefer early returns," "don't flag missing docstrings on private methods"), list them back and ask: *"You mentioned these preferences during the review — would you like to add them to your quality standards?"*

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
