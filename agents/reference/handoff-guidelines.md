# Handoff Guidelines for Agents (Trimmed)

> Purpose: A concise guide for when to delegate work vs. when to ask the user for guidance. This trimmed version consolidates duplicated guidance into single canonical sections and removes repeated reminders.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Core Delegation Strategies](#core-delegation-strategies)
  - [Delegation Mechanisms](#delegation-mechanisms)
  - [General Principles](#general-principles)
  - [Which Mechanism to Use](#which-mechanism-to-use)
- [Context Window Guidance](#context-window-guidance)
- [When to Use Clink](#when-to-use-clink)
- [When to Use Task Tool (Claude Code)](#when-to-use-task-tool-claude-code)
- [When to Ask the User (AskUserQuestion)](#when-to-ask-the-user-askuserquestion)
- [Model Selection Guide](#model-selection-guide)
- [Handoff Patterns](#handoff-patterns)
- [What Requires Explicit Approval](#what-requires-explicit-approval)
- [Decision Matrix](#decision-matrix)
- [Practical Examples](#practical-examples)
- [Key Takeaways](#key-takeaways)

---

## Core Delegation Strategies

### Delegation Mechanisms

1. `clink` (Zen MCP): Cross-model orchestration to Claude, Codex (GPT‑5‑Codex), Gemini
2. `Task` tool: Spawn specialized Claude Code subagents (Claude‑only)
3. `AskUserQuestion`: Stop and obtain explicit user guidance

### General Principles

- Delegate when another model or role materially improves accuracy, speed, cost, or context handling.
- Ask the user when requirements are ambiguous, multiple valid options exist, or explicit approval is required.
- Handle directly when the task is within your capability and scope is clear.

### Which Mechanism to Use

- If you are Claude Code (Sonnet/Haiku/Opus):
  - Use `Task` tool only for Claude subagents.
  - Use `clink` for delegation to Codex or Gemini.
- If you are Codex CLI or Gemini CLI: Use `clink` for all delegation (never `Task`).

---

## Context Window Guidance

- Gemini: ~1M token context; best when input truly exceeds ~400K tokens (e.g., whole repos/services, massive logs).
- GPT‑5‑Codex: ~400K token context; preferred for most coding tasks when input fits (higher accuracy on code/manipulation).
- Claude: typically smaller context; strong for orchestration and planning; choose when depth of chain‑of‑thought and tool coordination matter and context fits.

Rule of thumb:
- Prefer GPT‑5‑Codex for coding/refactoring/testing when the total context fits ≤400K.
- Use Gemini when you genuinely need >400K context or when budget dominates (free tier prototyping).
- Use Claude for complex agentic coordination, planning, and reasoning where context fits.

---

## When to Use Clink

Use `clink` to delegate to another model when:
- Context window constraints require Gemini’s 1M context; otherwise prefer Codex for code accuracy.
- Cost/speed optimizations are needed (e.g., batch generation, fast prototyping).
- Specialized reasoning is required (e.g., heavy math/algorithm analysis, large‑scale mechanical refactors, formal threat modeling, maximum depth reasoning).
- Ultra‑fast interactive loops are needed (e.g., Haiku for speed).

How to use `clink` (canonical specifics):
- Provide `cli_name` (`claude`, `codex`, `gemini`), a clear `prompt`, and a `role` (roles live in the clink role prompts directory).
- Always reuse `continuation_id` to preserve conversation context.
- Include absolute file paths when relevant.

### Available Roles by CLI

**codex**: api-integration, cpp-pro, devops-infra-as-code, frontend, golang-pro, implementation-helper, migration-refactoring, mobile-eng-architect, networking-edge-infra, realtime, rust-pro, testing

**gemini**: ai-ml-eng, db-internals, explainer, implementation-helper, optimization

**claude**:
- Haiku: implementation-helper, platform-eng (+ any role for speed)
- Sonnet: architect, architecture-audit, cost-optimization-finops, distributed-systems, explainer, implementation-helper, observability, scalability-reliability, security-compliance, tech-debt
- Opus: architect, architecture-audit, security-compliance, tech-debt (+ any role for max rigor)

---

## When to Use Task Tool (Claude Code)

`Task` is Claude Code‑only. Use it to spawn Claude subagents for:
- Codebase exploration (e.g., Explore agent with configurable thoroughness).
- Multi‑step research tasks and token‑conserving searches.
- Parallelizing independent search/analysis tasks.

Thoroughness levels:
- "quick": Basic pattern matching, fast lookups
- "medium": Moderate exploration across multiple files
- "very thorough": Comprehensive analysis across entire codebase

When not to use `Task`:
- Single known file reads or known symbol queries (use direct tools instead).
- Cross‑model delegation (use `clink`).

---

## When to Ask the User (AskUserQuestion)

Use AskUserQuestion when:
- Requirements are ambiguous, trade‑offs are uncited, or multiple valid approaches exist.
- High‑impact architectural decisions are involved (system design, stack selection, breaking changes).
- Critical information is missing (configs, environment details).
- Security/compliance sensitivity exists (credentials, access control, retention).
- Before destructive operations or any action listed under “Explicit Approval”.

Best practices:
- Provide 2–4 clear options with concise trade‑offs; allow multi‑select when appropriate.
- Include context about why you’re asking; keep headers short.

---

## Model Selection Guide

Quick reference (first picks by task category; defer to [Context Window Guidance](#context-window-guidance) for size‑driven decisions):

| Task Category | First Pick | CLI | Role | Why |
| --- | --- | --- | --- | --- |
| Architecture & system design | Sonnet 4.5 | `claude` | `architect` | Trade‑off aware planning; extended thinking |
| Large migrations & refactors | GPT‑5‑Codex | `codex` | `migration-refactoring` | Best for repo‑wide mechanical changes |
| API integration | GPT‑5‑Codex | `codex` | `api-integration` | Contract‑first design; idempotency/retry patterns |
| Data engineering / ML | GPT‑5‑Codex | `codex` | `ai-ml-eng` | Superior code/math accuracy when ≤400K tokens |
| Database optimization | GPT‑5‑Codex | `codex` | `db-internals` | Cross‑file SQL + app code analysis |
| Performance optimization | GPT‑5‑Codex | `codex` | `optimization` | Finds N+1s, blocking I/O, complexity issues |
| Frontend / design systems | GPT‑5‑Codex | `codex` | `frontend` | Component refactors; accessibility |
| Platform / DevEx / Infra | Haiku 4.5 | `claude` | `platform-eng` | CI fix‑ups; batch hygiene; speed |
| Observability / incident | Sonnet 4.5 | `claude` | `observability` | Runbooks; SLO/error budgets; RCAs |
| Reliability / scalability | Sonnet 4.5 | `claude` | `scalability-reliability` | Capacity plans; coordination |
| Security / privacy | Sonnet 4.5 | `claude` | `security-compliance` | Threat modeling; audits |
| Testing / verification | GPT‑5‑Codex | `codex` | `testing` | Unit/property/mutation tests |
| Real‑time systems | GPT‑5‑Codex | `codex` | `realtime` | Latency budgets; scheduling |
| Systems: C++ | GPT‑5‑Codex | `codex` | `cpp-pro` | Concurrency, FFI, safety |
| Systems: Rust | GPT‑5‑Codex | `codex` | `rust-pro` | Ownership, unsafe blocks |
| Systems: Go | GPT‑5‑Codex | `codex` | `golang-pro` | Goroutines, channels |
| DevOps / IaC | GPT‑5‑Codex | `codex` | `devops-infra-as-code` | Terraform, Kubernetes |
| Implementation helper | Any | Any | `implementation-helper` | General coding assistance |
| Code explanation / understanding | Any with good context | Any | `explainer` | Choose model based on codebase size/complexity |
| Architecture audits | Sonnet 4.5 | `claude` | `architecture-audit` | Deep analysis of existing architecture; identify issues |
| Tech debt analysis | Sonnet 4.5 | `claude` | `tech-debt` | Identify and prioritize technical debt systematically |
| Cost optimization | Sonnet 4.5 | `claude` | `cost-optimization-finops` | Cloud costs; resource optimization; FinOps strategies |
| Distributed systems design | Sonnet 4.5 | `claude` | `distributed-systems` | Consensus; consistency; partition tolerance |
| Networking / edge infrastructure | GPT‑5‑Codex | `codex` | `networking-edge-infra` | CDN; load balancing; edge compute patterns |
| Mobile engineering | GPT‑5‑Codex | `codex` | `mobile-eng-architect` | iOS/Android architecture; mobile‑specific patterns |
| Whole‑repo analysis >400K tokens | Gemini 2.5 Pro | `gemini` | `explainer` | 1M‑token context |

Model‑specific notes:
- Codex (GPT‑5‑Codex): multi‑file refactoring, mechanical changes, contract/testing, and cross‑file code accuracy.
- Claude (Sonnet/Haiku/Opus): orchestration, planning, coordination; Haiku for speed, Opus for maximum rigor.
- Gemini: choose for truly large contexts (>~400K tokens) or budget‑driven prototyping.
 - Note: Opus 4.1 has strict weekly limits — use sparingly for highest‑impact work.

### Thinking Level Optimization

**Codex** (mention in prompt):
- "minimal effort": formatting, regex
- "low effort": single-file
- default: cross-file
- "high effort": migrations, concurrency

**Claude** (mention "extended thinking" for):
- Long-horizon refactors, RCAs, multi-service planning, complex research

---

## Handoff Patterns

Sequential flow with references to canonical sections rather than repeating rules:

1) Research
- Objectives: understand requirements, code, and constraints.
- Actions: use `Task` Explore (Claude) for codebase exploration; use direct read/glob for known files/symbols; use `clink`→Gemini for long‑context needs (>~400K). If ambiguity remains, see [AskUserQuestion](#when-to-ask-the-user-askuserquestion).

2) Planning
- Objectives: design the approach, break down tasks, identify risks.
- Actions: outline steps; note trade‑offs; delegate complex architecture to Claude (`architect`) or refactoring planning to Codex (`migration-refactoring`) via `clink`. Resolve ambiguities via [AskUserQuestion](#when-to-ask-the-user-askuserquestion). Obtain approval before implementation when needed (see [Explicit Approval](#what-requires-explicit-approval)).

3) Implementation
- Objectives: execute the plan and write changes.
- Actions: track tasks; use Codex for wide refactors/testing; use Claude for coordination; use Gemini for long‑context codebase analysis. For approval gates (commits/deploys/destructive ops), see [Explicit Approval](#what-requires-explicit-approval).

4) Review/Verification (optional)
- Objectives: verify changes, run tests, prepare for commit.
- Actions: request code review (any model with a reviewer role); run tests; follow the [Approval Pattern](#what-requires-explicit-approval) before committing/pushing.

---

## What Requires Explicit Approval

Always ask before:
- Version control operations: creating commits (unless explicitly told), pushing, merging, rebasing, force pushes, amending commits.
  - Exception: User explicitly says "commit this" or "push these changes".
- Destructive operations: deleting files/dirs, truncating databases, dropping tables, purging caches, removing dependencies.
  - Exception: User explicitly says "delete X" or removal is part of an explicitly approved refactoring task.
- Production/deployment: prod deploys, prod config changes, service restarts, env var changes, prod migrations.
  - Never assume: always ask even if user says "deploy".
- Security/access changes: authN/Z changes, permission grants, exposing endpoints, disabling security features, handling secrets.
- Breaking changes: public API removals, signature changes without backward compatibility, schema changes without migrations, config format changes.
  - Exception: Proceed only with explicit user approval for the breaking change.
- Cost‑impacting changes: adding cloud resources, increasing instance size, storage tier changes, rate‑limit changes, adding paid third‑party services.

Approval pattern:
```
1) Clearly state what will happen
2) List affected resources/files
3) Explain potential risks/impacts
4) Use AskUserQuestion with clear options
5) Wait for explicit approval
6) Proceed only after approval
```

---

## Decision Matrix

Condensed if‑then rules referring to canonical sections:

Context size
```
IF total context > ~400K tokens
THEN use Gemini via clink (see Context Window Guidance)

IF total context ≤ ~400K tokens AND coding/refactoring accuracy matters
THEN prefer Codex (see Model Selection Guide)

IF task is orchestration/planning with tool coordination and context fits
THEN prefer Claude (Sonnet/Haiku/Opus as appropriate)
```

Discovery vs. direct reads
```
IF open‑ended codebase exploration
THEN use Claude Task Explore (see Task Tool)

IF specific files/symbols are known
THEN use direct Read/Glob instead of spawning agents
```

Ambiguity and approvals
```
IF requirements or trade‑offs are ambiguous
THEN use AskUserQuestion (see AskUserQuestion)

IF operation is destructive, prod‑impacting, or otherwise sensitive
THEN follow Explicit Approval and Approval Pattern
```

### Critical Edge Cases

**Context thresholds**:
- <200K: handle directly | 200K-400K: codex | >400K: gemini

**DB/ML/optimization**:
- Gemini ONLY when datasets/logs exceed 400K tokens
- Otherwise: codex + High thinking (94.6% vs 88% AIME)

**Math-heavy**:
- Codex + High thinking preferred (94.6%)
- Gemini (88%) only for budget or >400K context

---

## Practical Examples

Example 1: “Refactor the authentication system to use JWT”
- Flow: Research (Explore) → AskUserQuestion for requirements → Plan → Approvals for breaking changes → Implement with Codex (`migration-refactoring`) → Approval before commit.

Example 2: “Find all places where we handle errors”
- Flow: Use Claude Task Explore (medium thoroughness) → Summarize findings.

Example 3: “Optimize slow database queries in the analytics service”
- Flow: Check context size → If >~400K, use Gemini with `db-internals`; else Codex with `db-internals` → Confirm approach via AskUserQuestion → Implement.

Example 4: “Write a threat model for our payment API”
- Flow: Gather context → Delegate to Claude Opus + `security-compliance` via `clink` → Review.

Example 5: “Fix 50 linting errors across the codebase”
- Flow: Use Claude Haiku + `implementation-helper` via `clink` for speed/cost → Approval before commit.

---

## Key Takeaways

- Prefer Codex for coding/refactoring/testing when context fits ≤~400K; use Gemini for genuinely large contexts or budget‑driven prototyping; use Claude for orchestration/planning and agentic coordination.
- `Task` tool is Claude‑only; use it for exploration/research/parallel search—not cross‑model delegation (use `clink`).
- Use `clink` with `cli_name`, `prompt`, `role`, and reusable `continuation_id`; include absolute file paths when helpful.
- Follow [Explicit Approval](#what-requires-explicit-approval) for commits, destructive changes, production operations, security changes, breaking changes, and cost‑impacting actions.
- Resolve ambiguity with [AskUserQuestion](#when-to-ask-the-user-askuserquestion) using concise options and clear trade‑offs.
