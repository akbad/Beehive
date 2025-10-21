# MCP workflow playbook

A practical field manual for orchestrating the must-have MCP servers and GitHub SpecKit during real software projects.

## How to read this guide

- Use the workflow section to choose the right stack for the job, then flip to the prompting section for ready-to-run phrasing.
- Each workflow highlights when overlapping tools diverge so you can deliberately pick (for example) `fetch` versus `firecrawl`.
- ICON legend is textual: look for **Focus tools**, **Why this mix**, **Sequence**, and **Prompt move** under every workflow bullet.
- Skim the prompting section once, then bookmark it; the snippets are designed to be copy-adjustable for any CLI that supports MCP or `/speckit.*`.

## Workflow playbook

- **Workflow 01: Cold-start repo assimilation**
    
    - Focus tools: `sourcegraph`, `filesystem`, `qdrant`.
    - Why this mix: `sourcegraph` spans repos, `filesystem` gives structured file reads, `qdrant` locks in context for later sessions.
    - Sequence: start with `sourcegraph.search` to map ownership, pull pivotal files via `filesystem.read_file`, archive findings in `qdrant.store`.
    - Prompt move: "Use Sourcegraph to list all entrypoints touching billing, read the main handler with filesystem, then store a labeled summary in Qdrant."

- **Workflow 02: Historical decision recall for architecture reviews**
    
    - Focus tools: `qdrant`, `sourcegraph`.
    - Why this mix: semantic memory retrieves prior ADRs while Sourcegraph confirms the current implementation landscape.
    - Sequence: call `qdrant.find` with metadata filters (component, date) before `sourcegraph.search` to see if code still aligns.
    - Prompt move: "Pull Qdrant memories tagged architecture and payments from last quarter, then use Sourcegraph to verify the constraints still hold."

- **Workflow 03: Multi-agent design debate**
    
    - Focus tools: `clink`, primary CLI.
    - Why this mix: `clink` spins up specialized roles (planner, reviewer) without losing the main thread; no other server replicates this cross-CLI orchestration.
    - Sequence: ask the host CLI to call `clink` sequentially (planner → reviewer → implementer) so each model contributes with isolation.
    - Prompt move: "Launch Planner via clink to draft the sharding strategy, have Codereviewer critique it, then let Default codex propose adjustments."

- **Workflow 04: Feature specification handshake**
    
    - Focus tools: `spec-kit`, `clink`, `qdrant`.
    - Why this mix: SpecKit structures the constitution/spec/plan, `clink` lets you borrow the best model for each phase, `qdrant` stores artifacts for reuse.
    - Sequence: `/speckit.constitution` (planner role via clink), `/speckit.specify`, `/speckit.plan`, then archive the generated doc in Qdrant.
    - Prompt move: "Run `/speckit.specify` for rate limiting, asking clink planner to help draft acceptance criteria, then stash the spec in Qdrant tagged rollout."

- **Workflow 05: Hardening a risky module before release**
    
    - Focus tools: `filesystem`, `semgrep`, `git`.
    - Why this mix: `filesystem` scopes read/write access, `semgrep` enforces deterministic security checks, `git` captures structured diffs and commits.
    - Sequence: inspect with `filesystem`, patch, run `semgrep.scan` targeting high-severity rules, then stage/commit via `git.stage` and `git.commit`.
    - Prompt move: "Apply filesystem edits for auth validators, run Semgrep OWASP Top 10 on the touched files, stage the clean diff with git."

- **Workflow 06: Brand-new API integration research**
    
    - Focus tools: `context7`, `fetch`, `tavily`.
    - Why this mix: `context7` serves version-correct API docs, `fetch` converts supplemental blog posts into Markdown, `tavily` surfaces fresh examples or changelogs.
    - Sequence: open with `context7.lookup` for canonical docs, use `tavily.search` for community insights, ingest long-form guidance with `fetch`.
    - Prompt move: "Get Context7 docs for Stripe Checkout v2024-08-16, Tavily search for recent upgrade notes, then Fetch the best tutorial and summarize parameters."

- **Workflow 07: JavaScript-heavy documentation scrape**
    
    - Focus tools: `firecrawl`, `fetch`.
    - Why this mix: `firecrawl` can interact (click, scroll) and solve CAPTCHAs, while `fetch` is faster for simple HTML once the heavy lifting is done.
    - Sequence: run `firecrawl.scrape` with action script to reveal hidden content, optionally re-run `fetch` on the visible HTML for token-efficient markdown.
    - Prompt move: "Use Firecrawl to open the Next.js routing docs and click 'Show more', then Fetch the exposed HTML so the agent works from clean Markdown."

- **Workflow 08: Quick doc snippet ingestion during pairing**
    
    - Focus tools: `fetch`.
    - Why this mix: zero-setup `fetch` call beats `firecrawl` when pages are static and you just need tidy Markdown.
    - Sequence: single `fetch.retrieve` with `system_prompt` asking for highlight extraction.
    - Prompt move: "Fetch `https://docs.python.org/3/library/asyncio.html` and return only the best practices section as Markdown bullets."

- **Workflow 09: Competitive landscape scan**
    
    - Focus tools: `tavily`, `firecrawl`.
    - Why this mix: `tavily.search` ranks authoritative sources with citations, `firecrawl.batch_scrape` extracts structured data once targets are known.
    - Sequence: search with filters (domain, recency), push top results into `firecrawl.batch_scrape`, synthesise using agent reasoning.
    - Prompt move: "Run Tavily advanced search on 'GraphQL federation best practices' (last 6 months), then Firecrawl extract pricing tiers from each competitor site."

- **Workflow 10: Breaking-change audit before dependency upgrade**
    
    - Focus tools: `sourcegraph`, `context7`, `git`.
    - Why this mix: `sourcegraph` finds code usage, `context7` surfaces new API diff, `git` helps branch and document remediation.
    - Sequence: gather API change notes via `context7`, search for impacted functions with `sourcegraph`, check diffs and branch using `git`.
    - Prompt move: "Ask Context7 for AWS SDK S3 breaking changes 3.6.x→3.7.x, Sourcegraph for all `listObjectV2` calls, then create a feature branch via git."

- **Workflow 11: Legacy modernization blueprint**
    
    - Focus tools: `sourcegraph`, `qdrant`, `spec-kit`.
    - Why this mix: `sourcegraph` inventories legacy patterns, `qdrant` surfaces prior migration lore, `spec-kit` captures the modernization plan.
    - Sequence: search deprecated APIs, retrieve old ADRs from Qdrant, run `/speckit.plan` to outline migration waves.
    - Prompt move: "Search Sourcegraph for `joda-time`, bring back Qdrant notes tagged time_migration, then draft `/speckit.plan` for java.time adoption."

- **Workflow 12: Security incident triage**
    
    - Focus tools: `semgrep`, `tavily`, `qdrant`.
    - Why this mix: `semgrep` locates vulnerable patterns, `tavily` finds advisories or CVEs, `qdrant` stores the incident postmortem for future recall.
    - Sequence: run targeted Semgrep rule, research mitigations with Tavily, log remediation steps into Qdrant.
    - Prompt move: "Scan for JWT signature bypass patterns with Semgrep, Tavily search for latest CVEs, then store the incident summary in Qdrant tagged security_high."

- **Workflow 13: Branch hygiene and commit choreography**
    
    - Focus tools: `git`, `filesystem`.
    - Why this mix: `git` handles branches and staging, `filesystem` ensures edits respect allow-listed paths.
    - Sequence: edit via `filesystem.write_file`, inspect with `git.status`, craft commit messages through `git.commit`.
    - Prompt move: "Use filesystem to update README, confirm clean status with git, create `docs/readme-refresh` branch, and stage+commit."

- **Workflow 14: On-call hotfix under time pressure**
    
    - Focus tools: `sourcegraph`, `filesystem`, `git`, `semgrep`.
    - Why this mix: Sourcegraph quickly locates faulty code, filesystem applies patch, git bundles hotfix, Semgrep validates the patch.
    - Sequence: Sourcegraph identify regression, filesystem patch, run Semgrep on touched files, commit and push via git.
    - Prompt move: "Find the `null` guard missing in `api/newOrder` using Sourcegraph, patch with filesystem, run Semgrep quick scan, stage and commit."

- **Workflow 15: Infrastructure-as-code drift detection**
    
    - Focus tools: `semgrep`, `tavily`, `sourcegraph`.
    - Why this mix: Semgrep IaC rules catch misconfigurations, Tavily surfaces provider deprecations, Sourcegraph confirms usage across env repos.
    - Sequence: run Semgrep with IaC profile, research provider announcements via Tavily, search Sourcegraph for references to flagged resources.
    - Prompt move: "Run Semgrep Terraform rules on infra/, Tavily search for AWS ALB TLS policy updates, Sourcegraph for `ELBSecurityPolicy-TLS-1-0` uses."

- **Workflow 16: Institutional memory building**
    
    - Focus tools: `qdrant`, `filesystem`.
    - Why this mix: Qdrant stores semantic notes, filesystem extracts meeting docs or READMEs to seed memory.
    - Sequence: read reference docs via filesystem, summarize and `qdrant.store` with metadata (team, lifecycle).
    - Prompt move: "Read `/docs/ops/oncall.md`, distill key runbooks, store in Qdrant with owner=ops and expires=2025-12-31."

- **Workflow 17: Sprint backlog shaping with precise tasks**
    
    - Focus tools: `spec-kit`, `clink`.
    - Why this mix: SpecKit’s `/speckit.tasks` creates reviewable backlog items, `clink` lets you pick the best planning model.
    - Sequence: finalize `/speckit.plan`, then `/speckit.tasks` via clink planner, optionally push outputs into PM tool manually.
    - Prompt move: "After `/speckit.plan`, run `/speckit.tasks` with clink planner focusing on dependency ordering and test expectations."

- **Workflow 18: Release notes synthesis**
    
    - Focus tools: `git`, `sourcegraph`, `qdrant`.
    - Why this mix: `git.log` reveals recent commits, Sourcegraph finds user-facing strings, Qdrant archives the notes for the marketing team.
    - Sequence: gather `git.log` since last tag, search Sourcegraph for feature toggles, store final notes in Qdrant.
    - Prompt move: "List commits since v1.8.0, find any `user-facing` annotations via Sourcegraph, store the formatted release notes in Qdrant release channel."

- **Workflow 19: Cross-CLI code review board**
    
    - Focus tools: `clink`, `semgrep`, `git`.
    - Why this mix: `clink` brings multiple reviewers (Gemini/Claude) into a single thread, Semgrep provides automated findings, Git supplies diff context.
    - Sequence: ask `clink` codereviewer to critique staged changes, then run Semgrep to cross-check, finalize with Git diff summary.
    - Prompt move: "Have clink codereviewer read the staged diff via git, summarize risks, then run Semgrep for confirmation."

- **Workflow 20: Data migration readiness**
    
    - Focus tools: `spec-kit`, `sourcegraph`, `filesystem`.
    - Why this mix: SpecKit structures migration plan, Sourcegraph maps column usage, filesystem verifies schema files.
    - Sequence: `/speckit.specify` requirements, search Sourcegraph for field usages, update migration scripts via filesystem.
    - Prompt move: "Draft `/speckit.plan` for moving `customer_status`, Sourcegraph search for reads, apply schema changes with filesystem."

- **Workflow 21: Performance tuning exploration**
    
    - Focus tools: `tavily`, `fetch`, `context7`.
    - Why this mix: Tavily finds fresh benchmarks, Fetch ingests long-form guides, Context7 confirms official tuning knobs.
    - Sequence: start with Tavily advanced search filtered by recency, Fetch chosen deep dives, Context7 verify config flags for your SDK version.
    - Prompt move: "Tavily search 'Redis pipeline throughput tuning 2025', Fetch the best tutorial, Context7 for Redis client v5 options to adjust."

- **Workflow 22: Compliance evidence weaving**
    
    - Focus tools: `spec-kit`, `qdrant`, `semgrep`.
    - Why this mix: SpecKit tasks embed required controls, Qdrant stores audit evidence, Semgrep proves policy enforcement.
    - Sequence: run `/speckit.checklist` with compliance focus, execute tasks, store artifacts in Qdrant, run Semgrep to capture scan output.
    - Prompt move: "Generate `/speckit.checklist` for SOC2 change management, store completed items in Qdrant, attach Semgrep reports as evidence."

- **Workflow 23: Experiment design (A/B or feature flag)**
    
    - Focus tools: `spec-kit`, `sourcegraph`, `tavily`.
    - Why this mix: SpecKit documents hypothesis/tasks, Sourcegraph finds experiment hook points, Tavily surfaces industry heuristics.
    - Sequence: gather best practices via Tavily, run `/speckit.specify` and `/speckit.plan`, confirm code injection points with Sourcegraph.
    - Prompt move: "Search Tavily for 'feature flag rollout guardrails', run `/speckit.specify` for experiment, Sourcegraph for all `FeatureFlag.isEnabled` references."

- **Workflow 24: Pre-commit guardrail run**
    
    - Focus tools: `git`, `semgrep`, `filesystem`.
    - Why this mix: Git identifies changed files, Semgrep scans staged content, filesystem applies auto-fixes if needed.
    - Sequence: `git.diff_staged` to gather targets, run `semgrep.scan` on the diff, patch via filesystem, re-run scan, then commit.
    - Prompt move: "List staged files, run Semgrep high priority rules, patch violations with filesystem, confirm clean status."

- **Workflow 25: Diff-driven context injection for agents**
    
    - Focus tools: `git`, `context7`, `qdrant`.
    - Why this mix: Git reveals diff scope, Context7 fetches official docs relevant to touched APIs, Qdrant stores context for multi-session completion.
    - Sequence: inspect `git.diff_unstaged`, request matching doc sections via Context7, store curated context in Qdrant for future prompts.
    - Prompt move: "Show diff for modified AWS S3 code, request Context7 docs for affected methods, store the summary in Qdrant under sprint_28."

- **Workflow 26: External API change monitoring**
    
    - Focus tools: `context7`, `tavily`, `firecrawl`.
    - Why this mix: Context7 monitors official API changelogs, Tavily catches community chatter, Firecrawl archives entire changelog pages when versioned.
    - Sequence: schedule periodic Context7 summary, use Tavily advanced search with recency window, batch Firecrawl scrape the changelog for diffing.
    - Prompt move: "Context7 check Stripe API changelog for breaking updates, Tavily search 'Stripe API deprecation' last 30 days, Firecrawl crawl the changelog section."

- **Workflow 27: Architecture redesign summit**
    
    - Focus tools: `clink`, `spec-kit`, `sourcegraph`, `qdrant`.
    - Why this mix: clink coordinates multi-model debate, SpecKit logs decisions, Sourcegraph grounds discussion in code reality, Qdrant persists outcomes.
    - Sequence: run clink planner+reviewer to brainstorm, `/speckit.constitution` and `/speckit.plan`, Sourcegraph to validate feasibility, store final architecture notes in Qdrant.
    - Prompt move: "Have clink planner outline three redesign options, /speckit.plan the chosen path, Sourcegraph verify dependencies, archive final plan in Qdrant."

- **Workflow 28: Token-efficient documentation refresh**
    
    - Focus tools: `fetch`, `firecrawl`.
    - Why this mix: `fetch` excels at Markdown compression, `firecrawl` helps only when you must interact with the page first.
    - Sequence: try `fetch` first; if content is hidden behind interactions, run Firecrawl to expose, then re-run Fetch for optimal token footprint.
    - Prompt move: "Attempt Fetch with `strip_boilerplate=true`; if key sections missing, use Firecrawl actions to reveal content then repeat Fetch."

- **Workflow 29: Knowledge handoff to new teammate**
    
    - Focus tools: `qdrant`, `sourcegraph`, `filesystem`.
    - Why this mix: Qdrant stores curated onboarding packets, Sourcegraph links to code examples, filesystem collects docs and READMEs.
    - Sequence: gather docs via filesystem, annotate code references with Sourcegraph search URLs, store the structured overview in Qdrant.
    - Prompt move: "Summarize onboarding docs, attach Sourcegraph links for critical services, store the package in Qdrant tagged onboarding_backend."

- **Workflow 30: Full-stack feature delivery loop**
    
    - Focus tools: `spec-kit`, `fetch`, `context7`, `filesystem`, `semgrep`, `git`, `qdrant`.
    - Why this mix: SpecKit orchestrates phases, Fetch/Context7 provide research, Filesystem edits, Semgrep ensures safety, Git manages commits, Qdrant saves learnings.
    - Sequence: run `/speckit` phases, research with Fetch/Context7, implement via filesystem, scan with Semgrep, commit via Git, store retrospectives in Qdrant.
    - Prompt move: "Spin through `/speckit.constitution`→`/speckit.plan`, Fetch docs for UI patterns, Context7 for API calls, implement with filesystem, Semgrep scan, commit with git, archive lessons in Qdrant."

## Prompting guide

### Core principles

- Lead with the desired tool name or slash command so the agent routes correctly (for example, "Use Sourcegraph search..." or "/speckit.plan ...").
- Provide scope, guardrails, and success criteria in the same prompt; MCP tools respond best when you define directories, filters, or metadata tags.
- Chain-of-thought is optional but tool-of-choice is not: if multiple tools could answer, explicitly contrast them to avoid fallback to the wrong server.
- Reference outputs you expect ("return Markdown bullets", "store with metadata owner=infra") to nudge structured responses.
- When combining tools, spell out the order; agents respect explicit sequencing like "first run Tavily advanced search, then Firecrawl batch scrape".
- Reuse context via Qdrant by tagging memories and asking agents to retrieve by tag before tackling new tasks.

### Prompting tactics by tool

#### Clink prompt patterns

- Treat `clink` as an orchestrator: specify which role (default, planner, codereviewer) and which CLI you want (Codex, Claude, Gemini).
- Mention concurrency expectations ("sequential", "nested") so spawned agents behave predictably.
- Combine with downstream tool instructions by embedding them inside the delegated prompt.

```text
Run clink with role="planner" using Claude. Task: draft a migration outline for moving from RabbitMQ to Kafka. Require the planner to call Sourcegraph to list current `MessageQueue` usages before proposing steps.
```

#### Filesystem MCP prompt patterns

- Always declare the target path or glob and clarify whether you intend to read, write, or list.
- Request specific formats (diffs, full file, JSON) to control output size.
- Pair with guardrails, for example "do not create new files" if you only expect reads.

```text
Use filesystem.read_file on `services/payments/handler.go` and return only the docstring above `ProcessRefund`. Do not modify the file.
```

#### Git MCP prompt patterns

- Specify branch intent, staging scope, and commit message expectations.
- Chain commands ("show status, then stage src/api/**, then commit with message 'Fix retry jitter'") to minimize back-and-forth.
- Request machine-readable outputs (`--json` is automatic) and ask the agent to review diffs before committing.

```text
Invoke git.status to confirm only files under `src/auth` changed, stage those files, show me the staged diff, and prepare a commit message summarizing the bug fix. Stop before pushing.
```

#### Fetch prompt patterns

- Provide URL list, extraction focus, and formatting (Markdown, table, bullet summary).
- Mention boilerplate stripping or section targeting to keep responses lean.
- If chaining with Firecrawl, state that the second call should happen only if content is missing.

```text
Fetch https://redis.io/docs/interact/programmability/lua-scripting/ and return a Markdown section summarizing best practices, preserving code blocks and links.
```

#### Context7 prompt patterns

- Include library name, version, and the specific API or concept you need.
- Ask for both docs and real code snippets, plus note if you require diff versus previous versions.
- When cross-referencing with diffs, request citations or section anchors.

```text
Use Context7 to retrieve AWS SDK for Java v2 SQS `ReceiveMessage` documentation and provide the retry/backoff guidance with code samples. Cite the doc section in the response.
```

#### Qdrant prompt patterns

- Tag every memory with metadata you can filter later (component, owner, sprint, severity).
- Differentiate between `store` and `find`; include queries with semantic text and structured filters.
- Request summaries when storing so you can recall succinct context quickly.

```text
Store in Qdrant: summary="Blue/green deploy rollout plan", details="<paste plan>", metadata={"component":"deployments","owner":"platform","sprint":"2025-03"}.
```

#### Tavily prompt patterns

- Leverage search depth, domain filters, and time ranges to control relevance.
- Ask for citation-rich summaries and optionally follow-up extraction tasks on returned URLs.
- Combine with Firecrawl by instructing the agent to feed Tavily results into batch scrapes.

```text
Run Tavily search for "event sourcing saga pattern pitfalls" with depth=advanced, max_results=6, filter to domains {martinfowler.com, microservices.io}. Summarize insights with citations.
```

#### Firecrawl prompt patterns

- Define action sequences (click, wait, scroll) for interactive pages.
- Specify tool mode (`scrape`, `batch_scrape`, `crawl`, `extract`) and output schema.
- Note retry/backoff expectations when crawling large sites.

```text
Use Firecrawl.scrape on https://react.dev/learn. Before extraction, click the "Show more" button and scroll to the bottom. Return Markdown with each interactive example in its own subsection.
```

#### Sourcegraph prompt patterns

- Provide repo filters, file globs, and search patterns (regex or literal).
- Ask for summaries of results, not just raw matches, to drive actionable insights.
- Chain follow-ups like `sourcegraph.get_file` once matches are identified.

```text
Search Sourcegraph across repos matching `backend-*` for `context.Background()` in Go files. Summarize each repo that lacks cancellation handling and fetch the surrounding 20 lines for two representative cases.
```

#### Semgrep prompt patterns

- Specify rule packs (owasp-top-ten, ci, secrets) or custom rule content inline.
- Limit scan scope to avoid timeouts and clarify severity thresholds you care about.
- Request remediation suggestions or auto-fix attempts when appropriate.

```text
Run Semgrep scan on `services/auth/**/*.py` using the `p/ci` rule pack. Report only High or Critical findings and propose code-level fixes for each.
```

#### GitHub Spec-Kit prompt patterns

- Call the correct slash command (`/speckit.constitution`, `/speckit.plan`, etc.) with concise yet complete instructions.
- Embed acceptance criteria, success metrics, and stakeholders to enrich generated artifacts.
- When iterating, reference previous outputs by filename so SpecKit maintains continuity.

```text
/speckit.plan Build Redis-backed rate limiting middleware with sliding window per endpoint, include rollback plan, testing strategy, and monitoring hooks. Base the plan on constitution.md guardrails.
```

### Combining prompts across tools

- Use explicit sequencing descriptors ("Step 1", "Step 2") within a single prompt to ensure agents execute tools in order.
- For dense workflows, draft a mini playbook inside the prompt that maps tasks to tools.
- After multi-tool runs, prompt the agent to summarize outputs and store in Qdrant, creating durable artifacts for future automations.

