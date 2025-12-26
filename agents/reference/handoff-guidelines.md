# *Handoff guidelines:* how and when to delegate to subagents

> **Purpose**: a concise guide for when to delegate work vs. when to ask the user for guidance.

## Table of contents

- [Table of contents](#table-of-contents)
- [Terminology](#terminology)
- [Core delegation strategies](#core-delegation-strategies)
  - [Delegation mechanisms available](#delegation-mechanisms-available)
  - [Delegation principles](#delegation-principles)
  - [When NOT to delegate](#when-not-to-delegate)
  - [Integration with *Superpowers* skills *(Claude and Codex only)*](#integration-with-superpowers-skills-claude-and-codex-only)
- [Delegation mechanisms (detailed)](#delegation-mechanisms-detailed)
  - [Quick comparison](#quick-comparison)
  - [Using `clink`](#using-clink)
  - [Using `Task` tool *(Claude Code only)*](#using-task-tool-claude-code-only)
  - [Using `AskUserQuestion`](#using-askuserquestion)
- [Parallel delegation strategies](#parallel-delegation-strategies)
  - [When to parallelize](#when-to-parallelize)
  - [How to parallelize](#how-to-parallelize)
  - [Common parallelization patterns](#common-parallelization-patterns)
  - [Default mindset](#default-mindset)
- [Merge \& verify results](#merge--verify-results)
- [Subagent context management](#subagent-context-management)
  - [Setting your spawned subagents up for success](#setting-your-spawned-subagents-up-for-success)
  - [Tool-specific guidance](#tool-specific-guidance)
  - [Common context handoff mistakes](#common-context-handoff-mistakes)
- [Choosing *models* when spawning subagents](#choosing-models-when-spawning-subagents)
  - [Decision tree (quick reference)](#decision-tree-quick-reference)
  - [Task category → model/role mapping](#task-category--modelrole-mapping)
  - [Thinking level optimization](#thinking-level-optimization)
- [Handoff patterns](#handoff-patterns)
- [When to ask the user (AskUserQuestion)](#when-to-ask-the-user-askuserquestion)
  - [When to ask](#when-to-ask)
  - [Best practices](#best-practices)
  - [What requires explicit approval, always](#what-requires-explicit-approval-always)

## Terminology

| Concept | Definition |
| :------ | :--------- |
| **Skill** | *Superpowers* workflow (e.g., `superpowers:test-driven-development`) + any extra Claude/Codex skills files you define |
| **Agent** |  Personas used by agents (e.g., `debugger`, `architect`), invoked either directly in your main chat or as subagents |
| **Subagent** | A child **agent**, isolated from the main chat, spawned to complete a particular task by *either* (1) Claude Code or OpenCode native subagents feature or (2) `clink` |
| **MCP** | MCP servers made available for you to use; see `compact-mcp-list.md` (on your list of must-read files) for a full guide |

## Core delegation strategies

### Delegation mechanisms available

1. `clink` (from PAL MCP, available everywhere): Cross-model orchestration to Claude, Codex (GPT‑5.1‑Codex), Gemini
2. `Task` tool (Claude) or native subagents (OpenCode): Spawn specialized subagents
3. `AskUserQuestion`: Stop and obtain explicit user guidance

### Delegation principles

- Delegate when another model or role materially improves accuracy, speed, cost, or context handling.
- Ask the user when requirements are ambiguous, multiple valid options exist, or explicit approval is required.
- Handle directly when the task is within your capability and scope is clear.

### When NOT to delegate

**Handle tasks directly (don't delegate) when:**

- **Task is simple and well-understood** — 1-2 file edits with clear requirements; faster to do than explain
- **Requires tight iteration loops** — Debugging with frequent hypothesis testing; trial-and-error exploration
- **Context loss would be expensive** — Deeply nested state that's hard to summarize; extensive prior conversation history
- **You already have necessary context loaded** — Files read, relationships understood; delegation = wasteful reloading
- **Explanation overhead > execution time** — If describing the task takes longer than doing it

**Cost of delegation:**
- Context summarization overhead (lossy compression of your current understanding)
- Potential information loss (nuances don't survive handoff)
- Coordination time (waiting for subagent, reviewing results)
- Risk of misunderstanding requirements (ambiguity in your prompt)

**Rule of thumb:** If you can complete the task in <2 minutes with context you already have → handle directly.

### Integration with *Superpowers* skills *(Claude and Codex only)*

#### Precedence rule when both systems apply

1. **Process enforcement (*Superpowers*)**: If a *Superpowers* skill mandates a specific workflow (e.g., TDD, systematic debugging), you MUST follow it — this is non-negotiable per the skill's requirements.
2. **Capability selection**: Within that mandated workflow, use handoff guidelines (this file) and model selection guide to choose:

    - Which model/CLI to use (`clink` with appropriate role)
    - Which MCP tools to leverage (per `compact-mcp-list.md`)
    - When to delegate vs. handle directly

#### Both systems are complementary

- *Superpowers* defines ***how** to work*
- `handoff-guidelines.md` defines ***who** does it*
- `mcp-compact-list.md` defines ***which tools** are used*

For example, suppose you are performing a debugging task. Examples of what could be enforced by each system:

| System | What it enforces/leads you to do |
| :-- | :-- |
| Superpowers | Use `systematic-debugging` skill (4-phase investigation process) |
| "Handoff guidelines" and "Compact MCP list" guides | Use Codex via `clink` with `debugger` role + Serena MCP for code search |

## Delegation mechanisms (detailed)

### Quick comparison

| Mechanism | CLI Support | Primary Use Cases | When to Use |
| :--- | :--- | :--- | :--- |
| **`clink`** | All CLIs | Cross-model delegation, specialized roles | Different model needed (see [decision tree](#decision-tree-quick-reference)), isolated context required |
| **`Task`** / native subagents | Claude, OpenCode | Specialized subagents, exploration, research | Codebase exploration, parallel searches, multi-step research |
| **`AskUserQuestion`** | All CLIs | User guidance, approval gates | Ambiguity, multiple valid approaches, explicit approval needed |

### Using `clink`

**When to use:**
- Cross-model collaboration is beneficial (see [decision tree](#decision-tree-quick-reference) for which model to choose)
- Spawning a specialized role with isolated context
- Task requires capabilities better suited to a different model

**CLI-specific rules:**
- **Claude Code**: Use `clink` for delegation to Codex or Gemini (use `Task` for Claude subagents)
- **Codex/Gemini**: Use `clink` for all delegation (no `Task` tool available)

**How to use:**
- Provide `cli_name` (`claude`, `codex`, `gemini`), clear `prompt`, and `role` (from clink role prompts directory)
- Always reuse `continuation_id` to preserve conversation context
- Include absolute file paths when relevant

**Special: Explore and Plan agents**

For `Explore` and `Plan` agents, specify thoroughness in your prompt:

| Thoroughness | Result |
| :--- | :--- |
| `"quick"` | Basic pattern matching, fast lookups |
| `"medium"` | Moderate exploration across multiple files |
| `"very thorough"` | Comprehensive analysis across entire codebase |

### Using `Task` tool *(Claude Code)* / native subagents *(OpenCode)*

**When to use:**
- Codebase exploration (Explore agent with configurable thoroughness)
- Multi-step research tasks and token-conserving searches
- Parallelizing independent search/analysis tasks

**When NOT to use:**
- Single known file reads or known symbol queries (use direct tools instead)
- Cross-model delegation (use `clink` instead)

### Using `AskUserQuestion`

See [When to ask the user](#when-to-ask-the-user-askuserquestion) section for complete guidance.

## Parallel delegation strategies

### When to parallelize

Spawn multiple subagents **concurrently** (not sequentially) when tasks are:
- **Independent**: No data dependencies between them
- **Parallelizable**: Can execute simultaneously without coordination
- **Time-consuming**: Research, analysis, exploration, code search
- **Mergeable**: Results can be combined afterward

### How to parallelize

**Critical:** Use **multiple tool calls in a single response** to launch parallel subagents.

**Example (correct - parallel execution):**
```
Let me analyze these 4 modules in parallel using clink:
[Launches 4 clink calls in one message]
```

**Anti-pattern (sequential execution):**
```
Let me analyze module A first...
[waits for response]
Now let me analyze module B...
[waits for response]
```

### Common parallelization patterns

1. **Multi-module analysis**
   - Spawn N subagents, one per module/package/service
   - Merge findings after all complete

2. **Dependency research**
   - Research 5 libraries in parallel (features, security, compatibility)
   - Compare results in single summary

3. **Cross-codebase search**
   - Search multiple repos/branches concurrently
   - Aggregate results

4. **Independent refactors**
   - Refactor 3 unrelated files in parallel
   - Review all changes together

5. **Multi-step investigation**
   - Investigate 4 potential root causes simultaneously
   - Converge on likely culprit

### Default mindset

**Before starting work:** Ask "Can I break this into 2+ independent subtasks?"
- If **YES** → Spawn multiple subagents in parallel
- If **NO** → Handle directly or spawn single subagent

**Err toward parallelization.** Coordination overhead is minimal compared to sequential execution time.

## Merge & verify results

Parallel execution only helps if you consolidate the answers rigorously. After every parallel batch, run this checklist:

1. **Collect & normalize:** pull every subagent summary into one workspace (table/list/doc) and record CLI/model/thinking levels plus citations so claims stay traceable.
2. **Compare & detect conflicts:** highlight overlaps, find contradictions or duplicated work, and confirm no component was overlooked.
3. **Validate critical claims:** spot-check referenced files, rerun key commands/tests, and double‑check web/API citations before accepting conclusions.
4. **Decide outcomes:** 

    - Mark each subtask `Accepted` / `Needs follow-up` / `Rejected`
    - If blockers remain, spawn a focused follow-up subagent or use `AskUserQuestion`

5. **Record & broadcast:** update Memory MCP (relationships) and Qdrant (insights/gotchas) with the reconciled truth (and not raw subagent dump) and summarize decisions back to the main thread/user.
6. **Plan next actions:** turn accepted recommendations into concrete edits/tests/commits and explicitly close the loop on rejected paths so future agents don’t retry them.

> **Reminder:** Never ship or store memories until merged results are verified. Raw, unvetted subagent output must not flow into persistent systems.

## Subagent context management

### Setting your spawned subagents up for success

**Always include in subagent prompts:**

1. **Relevant file paths** (absolute, not relative)
   - Provide exact paths to files the subagent will need
   - Example: `/Users/you/project/src/module/file.ts` NOT `./file.ts`

2. **Summarized context** (what you've learned that's relevant)
   - Key findings from your investigation so far
   - Important constraints or requirements discovered
   - Relevant architectural decisions or patterns

3. **Clear success criteria** (what "done" looks like)
   - Specific deliverable expected from the subagent
   - How you'll verify the work is complete
   - What format you need the results in

4. **Explicit constraints** (what NOT to do)
   - Actions requiring approval (don't commit, don't delete, etc.)
   - Areas to avoid modifying
   - Specific approaches to reject

### Tool-specific guidance

**For `clink`:**
- **Reuse `continuation_id`** to preserve conversation context across multiple turns
- Provide **absolute file paths**, never relative paths
- Specify **role explicitly** (e.g., `debugger`, `architect`) — don't assume defaults
- Include **images** parameter if visual context is needed (screenshots, diagrams)

**For `Task` tool (Claude Code):**
- Choose appropriate **thoroughness level** for Explore/Plan agents (`quick`, `medium`, `very thorough`)
- Use **parallel Task calls** for independent exploration/research tasks
- Provide **clear prompt** with specific research questions or exploration goals

**For native subagents (OpenCode):**
- Press **Tab** to cycle through registered agents and select the appropriate one
- Use natural language to delegate, or explicitly name the agent (e.g., "Have the debugger agent investigate...")
- OpenCode auto-delegates when agent descriptions match the task context

### Common context handoff mistakes

**DON'T:**
- ❌ Say "investigate this bug" without providing error messages, stack traces, or relevant files
- ❌ Assume subagent has your conversation history (it doesn't — provide needed context)
- ❌ Use vague success criteria like "make it better" or "fix the issues"
- ❌ Forget to mention approval requirements (subagent might commit/delete without knowing)
- ❌ Provide relative paths when codebase structure is ambiguous

**DO:**
- ✅ Include specific error messages: "Getting `NullPointerException` at line 42 in `UserService.java`"
- ✅ Summarize findings: "Found 3 similar bugs in `auth/` module, all related to session handling"
- ✅ Set concrete goals: "Refactor `processPayment()` to extract retry logic into separate function"
- ✅ State constraints clearly: "Don't modify database schema; only change application code"
- ✅ Give absolute paths: `/Users/you/beehive/agents/reference/handoff-guidelines.md`

## Choosing *models* when spawning subagents

### Decision tree (quick reference)

Use this flowchart for fast model selection based on **hard constraints** and **proven strengths**:

1. **Context >400K tokens?** → **Gemini 2.5 Pro** (1M context window; only option)
2. **Math-heavy work** (DB/ML/optimization) **+ context ≤400K?** → **GPT-5.1-Codex** with **High thinking** (superior math/code accuracy)
3. **Mechanical refactors, multi-file changes, testing?** → **GPT-5.1-Codex** (proven strength for repo-wide changes)
4. **Fast iterations, CI fixes, simple tasks?** → **Claude Haiku 4.5** (speed)
5. **Maximum rigour, highest-impact decisions?** → **Claude Opus 4.5** (use sparingly; strict weekly limits)
6. **Default for most other tasks?** → **GPT-5.1-Codex** or **Claude Sonnet 4.5** (both capable; choose based on task table below, personal preference, or availability)

### Task category → model/role mapping

| Task Category | First Pick | CLI | Role | Why |
| --- | --- | --- | --- | --- |
| Architecture & system design | Sonnet 4.5 | `claude` | `architect` | Trade‑off aware planning; extended thinking |
| Large migrations & refactors | GPT‑5.1‑Codex | `codex` | `migration-refactoring` | Best for repo‑wide mechanical changes |
| API integration | GPT‑5.1‑Codex | `codex` | `api-integration` | Contract‑first design; idempotency/retry patterns |
| Data engineering / ML | GPT‑5.1‑Codex | `codex` | `ai-ml-eng` | Superior code/math accuracy when ≤400K tokens |
| Database optimization | GPT‑5.1‑Codex | `codex` | `db-internals` | Cross‑file SQL + app code analysis |
| Performance optimization | GPT‑5.1‑Codex | `codex` | `optimization` | Finds N+1s, blocking I/O, complexity issues |
| Frontend / design systems | GPT‑5.1‑Codex | `codex` | `frontend` | Component refactors; accessibility |
| Platform / DevEx / Infra | Haiku 4.5 | `claude` | `platform-eng` | CI fix‑ups; batch hygiene; speed |
| Observability / incident | Sonnet 4.5 | `claude` | `observability` | Runbooks; SLO/error budgets; RCAs |
| Reliability / scalability | Sonnet 4.5 | `claude` | `scalability-reliability` | Capacity plans; coordination |
| Security / privacy | Sonnet 4.5 | `claude` | `security-compliance` | Threat modeling; audits |
| Testing / verification | GPT‑5.1‑Codex | `codex` | `testing` | Unit/property/mutation tests |
| Real‑time systems | GPT‑5.1‑Codex | `codex` | `realtime` | Latency budgets; scheduling |
| Systems: C++ | GPT‑5.1‑Codex | `codex` | `cpp-pro` | Concurrency, FFI, safety |
| Systems: Rust | GPT‑5.1‑Codex | `codex` | `rust-pro` | Ownership, unsafe blocks |
| Systems: Go | GPT‑5.1‑Codex | `codex` | `golang-pro` | Goroutines, channels |
| DevOps / IaC | GPT‑5.1‑Codex | `codex` | `devops-infra-as-code` | Terraform, Kubernetes |
| Implementation helper | GPT-5.1-Codex or Sonnet 4.5 | `codex` for GPT-5.1-Codex; `claude` for Sonnet 4.5 | `implementation-helper` | General coding assistance |
| Code explanation / understanding | Any with good context | Any | `explainer` | Choose model based on codebase size/complexity |
| Architecture audits | Sonnet 4.5 | `claude` | `architecture-audit` | Deep analysis of existing architecture; identify issues |
| Tech debt analysis | Sonnet 4.5 | `claude` | `tech-debt` | Identify and prioritize technical debt systematically |
| Cost optimization | Sonnet 4.5 | `claude` | `cost-optimization-finops` | Cloud costs; resource optimization; FinOps strategies |
| Distributed systems design | Sonnet 4.5 | `claude` | `distributed-systems` | Consensus; consistency; partition tolerance |
| Networking / edge infrastructure | GPT‑5.1‑Codex | `codex` | `networking-edge-infra` | CDN; load balancing; edge compute patterns |
| Mobile engineering | GPT‑5.1‑Codex | `codex` | `mobile-eng-architect` | iOS/Android architecture; mobile‑specific patterns |
| Whole‑repo analysis >400K tokens | Gemini 2.5 Pro | `gemini` | `explainer` | 1M‑token context |
| API client SDK design | GPT‑5.1‑Codex | `codex` | `api-client-designer` | Idiomatic SDKs; retries/pagination/auth; contract‑driven |
| Authentication engineering | Sonnet 4.5 | `claude` | `auth-specialist` | Secure flows (sessions/OAuth/JWT); OWASP; least privilege |
| Caching strategy & implementation | Gemini 2.5 Pro | `gemini` | `caching-specialist` | Layering, TTL/invalidations, cache keys, metrics |
| Chaos engineering & resilience drills | Sonnet 4.5 | `claude` | `chaos-engineer` | Plan experiments, limit blast radius, SLOs; coordinate runs |
| Code review | GPT‑5.1‑Codex | `codex` | `code-reviewer` | Quality, security, maintainability; actionable diffs |
| Data engineering pipelines | Gemini 2.5 Pro | `gemini` | `data-eng` | ETL/ELT, SQL tuning, batch/stream jobs |
| Debugging and triage | GPT‑5.1‑Codex | `codex` | `debugger` | Cross‑file fault isolation; logs/traces; reproduction |
| Event‑driven design/implementation | GPT‑5.1‑Codex | `codex` | `event-driven` | Topics/queues, idempotency, backpressure, ordering |
| Engineering historian | Sonnet 4.5 | `claude` | `historian` | Change timelines, root causes, commit/story synthesis |
| Incident command | Sonnet 4.5 | `claude` | `incident-commander` | Runbooks, comms, decision logs, mitigations |
| Interviewer (requirements) | Sonnet 4.5 | `claude` | `interviewer` | Clarify constraints/trade‑offs; elicit missing info |
| Schema evolution & migrations | GPT‑5.1‑Codex | `codex` | `schema-evolution` | Backward‑compatible changes, migrations, rollout/rollback |
| Repository/code search | Haiku 4.5 | `claude` | `searcher` | Fast exploration; summarize findings; pointers |
| Task decomposition | Sonnet 4.5 | `claude` | `task-decomposer` | Break goals into verifiable steps, deps, risks |

### Thinking level optimization

When delegating via `clink`, adjust thinking levels in your prompt for better performance:

**Codex (effort levels):**
- `"minimal effort"` — formatting, regex, simple text transforms
- `"low effort"` — single-file edits, straightforward changes
- *(default)* — cross-file analysis, moderate complexity
- `"high effort"` — migrations, concurrency, complex refactors, math-heavy work

**Claude (extended thinking):**

Add `"extended thinking"` to your prompt for:
- Long-horizon refactors, complex architectural decisions
- Root cause analysis (RCAs), incident investigations
- Multi-service planning, system design
- Complex research requiring deep reasoning

## Handoff patterns

Follow the sequential flow of phases in the table below (in the order presented):

| Order | Phase name | Objectives | Actions to perform |
| :--- | :--- | :--- | :--- |
| **1** | **Research** | Understand requirements, code, and constraints | Use `Task` Explore (Claude) for codebase exploration; use direct read/glob for known files/symbols; use `clink`→Gemini for long‑context needs (>~400K). If ambiguity remains, see [AskUserQuestion](#when-to-ask-the-user-askuserquestion) |
| **2** | **Planning** | Design the approach, break down tasks, identify risks | Outline steps; note trade‑offs; delegate complex architecture to Claude (`architect`) or refactoring planning to Codex (`migration-refactoring`) via `clink`. For large goals, use `task-decomposer` to produce verifiable substeps and dependencies. Resolve ambiguities via [AskUserQuestion](#when-to-ask-the-user-askuserquestion). See [What requires explicit approval, always](#what-requires-explicit-approval-always) before proceeding. |
| **3** | **Implementation** | Execute the plan and write changes | Track tasks; use Codex for wide refactors/testing; use Claude for coordination; use Gemini for long‑context codebase analysis. Leverage specialist roles as needed (e.g., `schema-evolution`, `auth-specialist`, `caching-specialist`, `event-driven`, `debugger`). Also see [what requires explicit approval, always](#what-requires-explicit-approval-always) before proceeding. |
| **4** | **Review/Verification (optional)** | Verify changes, run tests, prepare for commit | Request code review (use `code-reviewer` for structured guidance); run tests; follow the [Approval pattern](#approval-pattern) as needed. |

## When to ask the user (AskUserQuestion)

### When to ask

Ask the user when:
- Requirements are ambiguous, trade‑offs are uncited, or multiple valid approaches exist.
- High‑impact architectural decisions are involved (system design, stack selection, breaking changes).
- Critical information is missing (configs, environment details).
- Security/compliance sensitivity exists (credentials, access control, retention).
- Before destructive operations or any action listed under “Explicit Approval”.

### Best practices
- Provide 2–4 clear options with concise trade‑offs; allow multi‑select when appropriate.
- Include context about why you’re asking; keep headers short.

### What requires <ins>explicit</ins> approval, <ins>always</ins>

- **Version control operations**: creating commits (unless explicitly told), pushing, merging, rebasing, force pushes, amending commits.

  - Exception: User explicitly says "commit this" or "push these changes".

- **Destructive operations**: deleting files/dirs, truncating databases, dropping tables, purging caches, removing dependencies.

  - *Exception*: User explicitly says "delete X" or removal is part of an explicitly approved refactoring task.

- **Production/deployment**: prod deploys, prod config changes, service restarts, env var changes, prod migrations.

  - Never assume: always ask even if user says "deploy".

- **Security/access changes**: authN/Z changes, permission grants, exposing endpoints, disabling security features, handling secrets.
- **Breaking changes**: public API removals, signature changes without backward compatibility, schema changes without migrations, config format changes.

  - *Exception*: Proceed only with explicit user approval for the breaking change.

- **Cost‑impacting changes**: adding cloud resources, increasing instance size, storage tier changes, rate‑limit changes, adding paid third‑party services.

#### Approval pattern

1. Clearly state what will happen
2. List affected resources/files
3. Explain potential risks/impacts
4. Use AskUserQuestion with clear options
5. Wait for explicit approval
6. Proceed only after approval
