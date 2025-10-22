# Software engineering jargon: precise definitions and practical translations

A field guide to the vague‑ish, process‑and‑operations‑leaning jargon commonly found in engineering playbooks, runbooks, postmortems, and planning docs. Definitions are written to be unambiguous for a sharp senior undergraduate while preserving industry nuance. Each term includes plain‑English meaning, concrete examples, and—where useful—how to make the statement measurable or actionable.

## How to use this guide

- Skim the category that matches your context (code change, incident, planning, docs, security).
- When a phrase feels vague, use the “make it concrete” cues to rewrite it into a specific question, search, or check.
- Prefer the source‑of‑truth pointers and verification steps over intuition.

## Codebase and change mechanics

- What these cover
    
    - Navigating code surfaces and their relationships during reading, refactoring, or review
    - Turning “hand‑wavy” phrases into concrete searches, diffs, and validations

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| entrypoints touching X | Top‑level code paths (handlers, jobs, CLIs) that directly call or transitively call code in domain X | Find all handlers that call billing code | “List all exported HTTP handlers that import `billing/*` or call `Charge()` directly or indirectly” | A cross‑ref list of symbols and files; call graph snippet or search query with results |
| pivotal files | Files that disproportionately define behavior or constraints for a feature or system | `router.go`, `schema.sql`, `FeatureFlag.ts`, `PolicyEvaluator.java` | “Identify the 3–5 files that, if changed, would change behavior of <feature> the most” | Edit history, fan‑in/fan‑out counts, hot‑spot metrics |
| impacted functions | Functions likely to require change or retest due to a code or config change | Functions using a deprecated API being removed | “List functions calling `OldAPI.*` and their tests” | Static search, type checker errors after API change, failing tests mapped to call sites |
| dependency ordering | The sequence in which modules/services/packages must initialize, build, deploy, or migrate | DB schema before app deploy; migrate producer before consumer | “Enumerate steps with preconditions: A before B because <reason>” | CI pipeline order, migration runbooks, health checks passing in order |
| bypass patterns | Code paths that skip intended validation, policy, auth, or safety checks | “DEBUG=true” short‑circuits auth; direct DB write avoids business rules | “Find all code paths that set `skipValidation` or call write APIs without validators” | Grep for flags, analyze guards, negative tests proving bypass no longer works |
| applying a patch | Making a specific, reviewable change to code or config (often via `git apply` or PR) | Cherry‑pick a commit, or apply a diff from a vendor | “Apply diff X to branch Y; show resulting files changed” | Clean `git status`, expected diff, passing build |
| validating a patch | Proving the patch does what it claims and only that | Compile, run tests, targeted checks (e.g., Semgrep rule, linter) | “Run unit tests touching changed files and a focused e2e; verify no broader regressions” | Green tests, no new warnings, expected behavior in staging |
| user‑facing annotations | Code comments, docstrings, or schema metadata that drive UI/tooling or developer comprehension | OpenAPI descriptions, GraphQL deprecations, protobuf `deprecated=true` | “Ensure each public field has description, examples, and deprecation guidance if applicable” | Generated docs include fields; lint rules enforce presence |
| code alignment | Code behavior matches the documented spec, ADRs, and policies | Rate limiting code matches spec thresholds | “Diff behavior against spec section X.Y; list divergences” | Contract tests or assertions derived from spec; ADR constraints enforced |

- Best practices
    
    - Prefer symbol‑aware queries (language server, Sourcegraph, ripgrep with patterns) over free‑text greps.
    - When declaring “impacted,” attach the dependency path (A → B → C) and the reason (ABI change, semantic contract, config coupling).
    - For dependency ordering, write preconditions (“B requires table T created by A”) and postconditions (“A exposes health endpoint H before B starts”).
    - Always pair “apply a patch” with “validate via smallest sufficient test surface,” then widen if confidence is low.
    - For annotations, treat public APIs as user interfaces; document breaking changes and deprecations where clients read them (OpenAPI/GraphQL/proto).

## Specification, planning, and delivery (product/agile)

- What these cover
    
    - Translating product intent into testable, verifiable engineering artifacts
    - Avoiding ambiguity during scoping and acceptance

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| acceptance criteria | The minimum, testable conditions required to accept a story/feature | “Reject attempts after 5 failures; reset counter after 1 hour” | “List GIVEN/WHEN/THEN cases; map to tests and metrics” | Automated tests per criterion; UAT checklist; linked metrics/alerts |
| definition of done | Team‑agreed list beyond “it works” (docs, tests, monitoring, rollout) | Docs updated, alert added, feature flag wired | “Checklist for this repo/service; attach evidence links” | PR includes docs/tests; dashboards/alerts exist; flag configured |
| canonical docs | The authoritative, current documentation a team commits to follow | ADRs, API specs, runbooks in a single repo/space | “Point to the single source of truth and its update policy” | Links resolve; versioning exists; drift checks pass |
| scope guardrails | Explicit inclusions/exclusions to prevent scope creep | “Only change ingestion pipeline; no UI edits” | “Enumerate in/out of scope by component” | PR diff limited to allowed areas; reviewers enforce |
| rollout plan | Steps to safely enable a change and recover if needed | Flag → canary → regional ramp → global | “Specify steps, owners, abort thresholds, rollback” | Change record exists; production follows plan; rollback tested |

- Best practices
    
    - Write acceptance criteria in behavior‑driven form (GIVEN/WHEN/THEN) and link each to an automated check.
    - Keep canonical docs findable, versioned, and reviewed; designate an owner and an SLA for updates.
    - Add observability acceptance: “Emits metric X and structured log Y when Z happens.”
    - Rollout and rollback are mirror images—author both together.

## Documentation and knowledge operations (DocOps)

- What these cover
    
    - Managing documentation as product: sources of truth, ingestion, distillation, and runbooks

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| ingest long‑form guidance | Pull lengthy articles/specs into a local, searchable format | Convert vendor docs/blogs to Markdown with citations | “Store as Markdown with source links and metadata tags” | Files exist with metadata; search returns them; citations preserved |
| distill key runbooks | Summarize the critical, step‑by‑step procedures needed during operations | “Database failover” quick steps page | “Produce a one‑page checklist with commands and abort criteria” | Dry‑run succeeds; on‑call can execute without escalation |
| source of truth | The single place that is authoritative for a domain | OpenAPI spec for API shape; Terraform for infra | “Identify the file/repo; treat all others as generated/derived” | Changes flow from the source; drift detection alerts |
| doc drift | Docs no longer match reality | README shows deprecated flags | “Schedule drift checks; add pre‑release doc review” | CI link checks; reviewers verify examples; alerts on 404s |

- Best practices
    
    - Prefer small, linkable pages with task‑focused titles; compose via links rather than giant pages.
    - Keep runbooks action‑first: prerequisites, steps, validation, rollback; include exact commands and owners.
    - Tag documents (owner, system, version, last‑reviewed) to enable maintenance.

## Reliability and incidents (SRE)

- What these cover
    
    - Language for outages, post‑incident learning, and reliability contracts

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| incident postmortem | A blameless analysis of what happened, why, impact, and fixes | RCA after a 30‑minute 500‑spike | “Document timeline, contributing factors, corrective actions with owners/dates” | Action items tracked to closure; follow‑up review done |
| SLO/SLA/SLA breach | Target reliability/internal or contractual promises/violation | 99.9% monthly availability | “Define SLI query and period; alert at error budget burn rates” | Dashboard shows SLI; burn alerts configured; reports sent |
| blast radius | Scope of impact a change or failure can cause | A feature flag limiting exposure to 1% | “List containment mechanisms and their thresholds” | Chaos tests show containment; metrics confirm isolation |
| rollback plan | Steps to safely revert | Revert deploy, disable flag, restore schema backup | “Enumerate triggers, commands, data considerations, owners” | Periodic rollback drills pass |

- Best practices
    
    - Write postmortems within 72 hours; separate facts, contributing factors, and countermeasures.
    - Tie every corrective action to a measurable change (test, alert, rate limit, isolation).
    - Practice rollbacks and disaster recovery; untested rollbacks are wishes.

## Security, policy, and compliance

- What these cover
    
    - Guardrails that govern acceptable changes and operational behavior

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| policy updates | Changes to rules the system or team must follow | New password policy; PII retention change | “Update policy docs and the enforcement point; map policy → code” | Lints/validators enforce; tests cover policy cases; audit passes |
| compensating controls | Alternative safeguards when ideal control is infeasible | Extra monitoring if full RBAC not ready | “List risk, temporary control, expiry/owner” | Ticket with review date; control effectiveness measured |
| least privilege | Grant only required access | Service account can read one bucket | “Define minimal permissions per identity and resource” | IAM diffs; access reviews; denied‑by‑default logs |
| bypass patterns | Ways policy/auth can be sidestepped (repeated here for emphasis) | Hardcoded admin token, debug knobs | “Audit code for bypass flags/paths; remove or gate by owner‑only runtime guard” | Static checks; negative tests; production blocks |

- Best practices
    
    - Treat policies like code: version them, review them, test their enforcement.
    - Time‑box compensating controls with an explicit sunset and owner.
    - Default‑deny in production; require explicit allow with review trails.

## Research, discovery, and verification

- What these cover
    
    - Getting from vague request → precise questions → evidence‑backed answers

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| canonical source comparison | Compare reality (code/metrics) to the spec/ADR | “Does billing retry match ADR‑012?” | “List every divergence with file:line and spec section” | Tests or assertions added; ADR updated if divergence is intentional |
| evidence trail | Links proving claims | PRs, runbook, dashboards, alerts | “Attach URLs and commit SHAs for each claim” | Links resolve; reviewers can reproduce |
| reproducibility | Others can repeat your steps and results | “How to run this benchmark” | “List exact versions, commands, seeds, data” | Fresh run yields same result within tolerance |

## Concrete translation templates

- From vague phrase to actionable request
    
    - “Entry points touching billing”
        
        - Request: “List all exported HTTP handlers, CLIs, and background jobs that import `billing/*` or call `Charge()` directly or via one hop.”
        - Evidence: command or Sourcegraph query and results.
    
    - “Pivotal files”
        
        - Request: “Identify the top 5 files by fan‑in/fan‑out or edit heat that most determine <feature> behavior; explain why each is pivotal.”
        - Evidence: dependency graph snapshot, `git log --numstat`, or code metrics.
    
    - “Impacted functions”
        
        - Request: “List all call sites of `OldAPI.DoThing` and their tests; propose renames or adapters needed.”
        - Evidence: search results, type errors after a stub change, failing tests list.
    
    - “Dependency ordering”
        
        - Request: “Define step order with preconditions/postconditions and health checks: A creates table T, B migrates data, C reads new column.”
        - Evidence: migration logs, health endpoints, smoke tests.
    
    - “Bypass patterns”
        
        - Request: “Find code that sets `skip*`, `bypass*`, or `DEBUG`; confirm whether production paths can reach them; remove or guard.”
        - Evidence: static search, config diffs, negative tests.
    
    - “Applying and validating patches”
        
        - Request: “Apply diff X; run tests touching changed files and one e2e; attach green run links.”
        - Evidence: CI job URLs, artifact links.
    
    - “Acceptance criteria”
        
        - Request: “Write GIVEN/WHEN/THEN cases; map each to a unit or e2e test; add an observability check.”
        - Evidence: test files/lines, dashboard/alert link.
    
    - “Canonical docs”
        
        - Request: “Link the single page/ADR that is authoritative and confirm last‑reviewed date and owner.”
        - Evidence: doc link with metadata, review history.
    
    - “Distill key runbooks”
        
        - Request: “Produce a one‑page checklist with exact commands, owners, expected outputs, and abort criteria.”
        - Evidence: successful dry‑run transcript.

## Expanded glossary (A–Z)

- acceptance criteria
    
    - Testable conditions for accepting a story or change. Prefer GIVEN/WHEN/THEN.
    - Anti‑patterns: “works on my machine,” UI‑only confirmation, no failure cases.

- apply a patch / validate a patch
    
    - Apply: introduce a specific diff; Validate: prove correctness with focused checks.
    - Pair small, targeted tests with broader smoke/e2e as needed.

- bypass pattern
    
    - Any mechanism that avoids intended checks (auth, validation, policy). Remove or strictly gate.

- canonical docs / source of truth
    
    - The reference doc/spec the team commits to follow. Keep versioned, owned, and reviewed.

- code alignment
    
    - Behavioral parity between code and ADR/spec/policy. Close the gap by changing code or updating the doc with rationale.

- dependency ordering
    
    - Explicit sequence of steps/components with prerequisites and health checks.

- distill runbooks
    
    - Boil complex procedures down to succinct, step‑by‑step checklists with owners and abort criteria.

- entrypoint
    
    - The function/executable path that begins a top‑level flow (HTTP handler, CLI command, cron job, message consumer).

- impacted function
    
    - A function likely to change or need retesting due to another change it depends on.

- incident postmortem
    
    - Blameless write‑up of what happened, why, and how to prevent recurrence; includes action items with owners/dates.

- policy update
    
    - A change to rules the system/team must enforce; update both prose and enforcement code.

- pivotal file
    
    - File with outsized effect on behavior; often routers, schemas, policy engines, feature flags.

- user‑facing annotation
    
    - Descriptive metadata in code that tools or users see (OpenAPI/GraphQL/protobuf field descriptions, deprecation markers).

## Quick checklists

- Before you call something “impacted”
    
    - What is the exact dependency path to the change?
    - What test proves it? What metric would move?
    - What is the smallest safe fix or proof?

- Before you say “policy updated”
    
    - Where is the source‑of‑truth doc?
    - Where is the enforcement point in code?
    - What tests/alerts prove the policy is enforced?

- Before you ship
    
    - Acceptance criteria mapped to tests
    - Observability added (metrics, logs, traces)
    - Rollout and rollback written and reviewed

## Architecture and systems design

- What these cover
    
    - Cross‑cutting architectural quality attributes and patterns used to reason about scalability, reliability, and evolvability

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| non‑functional requirements (NFRs) | Quality constraints the system must meet beyond features | “P99 < 300 ms; 99.9% availability; GDPR compliant” | “List NFRs with measurable thresholds and owners” | Dashboards/alerts target those thresholds; audits pass |
| fitness function | Automated check that continuously validates an architectural property | Contract test ensuring backward compatibility | “Encode the rule as a test or linter; run in CI” | Test fails on violation; trend visible over time |
| idempotency | Repeating an operation yields the same result | Retry payment capture without double‑charge | “Define idempotency keys and conflict behavior” | Tests simulating retry show a single side effect |
| eventual consistency | System converges to a correct state after some delay | Read‑after‑write lag in replicated stores | “Document staleness bounds and client expectations” | Consistency tests; SLO for staleness; caches honor TTL |
| graceful degradation | Maintain core functions under stress by shedding non‑essential work | Serve cached content if DB down | “Define tiers of functionality and shed policies” | Chaos tests prove core path stays available |
| bulkheading | Isolate components to prevent cascading failures | Separate thread pools per dependency | “List isolation boundaries and capacity limits” | Fault in one pool does not starve others |
| circuit breaker | Temporarily stop calling a failing dependency | Open breaker on 50% errors over N calls | “Set open/half‑open/close thresholds and timeouts” | Observed breaker state changes; error budget preserved |
| backpressure | Signal senders to slow down when consumers lag | HTTP 429; queue length based throttling | “Define queue thresholds and throttle responses” | Saturation tests show throughput stabilizes |
| strangler‑fig migration | Incrementally replace a legacy system by routing slices to the new one | Route 1% of traffic to v2 per endpoint | “Define routing rules, parity checks, and cutover” | Side‑by‑side diffing; error parity; ramp to 100% |
| golden path / paved road | Supported default approach/tooling giving fast and safe delivery | Standard service template with CI/CD baked in | “Document the path and guardrails; measure adoption” | New services use template; fewer incidents on the path |

- Best practices
    
    - Turn architectural tenets into fitness functions that run in CI (e.g., “public APIs must be backward compatible” as contract tests).
    - Prefer isolation (bulkheads, timeouts, budgets) over perfect resiliency; define failure domains and graceful fallbacks up front.
    - For migrations, design for coexistence (expand/contract, dual‑write, data verification) rather than big‑bang switches.

## Delivery and rollout patterns

- What these cover
    
    - Safe release strategies, exposure control, and learning before irreversible change

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| feature flag | Runtime switch to enable/disable code paths | Gradually enable new checkout | “Name, owner, kill‑switch, expiry date” | Flag registry; removal after rollout |
| dark launch | Deploy code in production without exposing to users | Compute results but do not show them | “Emit metrics for shadow path; no user impact” | Shadow metrics match control; no UX change |
| canary release | Release to a small subset to detect issues before global rollout | 1% traffic, then 5%, 25%, 100% | “Define ramp schedule and abort thresholds” | Automated rollback if error/latency exceed guardrails |
| blue/green | Run two prod environments and switch traffic | vN live, vN+1 staged; flip router | “Switch plan and data considerations” | Zero‑downtime cutover; quick rollback path |
| rolling deploy | Replace instances gradually | Update 10% at a time | “Batch size, health checks, surge capacity” | No capacity dips; health checks green |
| soak time | Time a change runs under real load before broader steps | 2 hours at 10% traffic | “Set minimum soak and what to monitor” | Stability metrics flat during soak |

- Best practices
    
    - Every rollout plan includes a fast, scripted rollback with data safety notes; practice it.
    - Attach quantitative guardrails (latency/error/cost) and automated stop conditions to each exposure step.
    - Track flag lifecycle explicitly: creation reason → ramp plan → removal date; remove flags promptly to prevent configuration debt.

## Observability and reliability (advanced)

- What these cover
    
    - Signals, alerting strategies, and pitfalls that separate solid ops from guesswork

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| golden signals (RED/USE) | Standard metrics sets for services (Rate, Errors, Duration) and resources (Utilization, Saturation, Errors) | Track R/E/D for HTTP, U/S/E for queues | “Define per service; add to dashboards” | Dashboards exist; alerts tied to SLOs |
| burn‑rate alerting | Alert on speed of SLO error budget consumption | 2h window at 14.4×, 24h at 6× | “Pick short/long windows and multipliers” | Alerts trigger early but not noisy |
| tail latency | High percentile latency representing worst user experience | P99.9 spikes despite median flat | “Monitor P95/P99/P99.9; avoid averages” | Percentiles recorded; regressions caught |
| cardinality explosion | Too many unique label combinations in metrics/logs | User‑id label on request metrics | “Whitelist labels; sample or hash high‑card fields” | Metric ingestion stays within budget |
| trace sampling (tail‑based) | Choose traces to keep based on interesting signals | Keep error/slow traces | “Define sampling rules; budget target” | Trace store cost bounded; useful traces kept |

- Best practices
    
    - Alert on symptoms (SLO) not just causes; keep pages scarce and actionable with runbook links.
    - Control metric cardinality by policy; separate high‑cardinality data to logs/traces with sampling.
    - Include correlation IDs across logs and traces; require a request context in libraries.

## Testing and quality engineering

- What these cover
    
    - Strategies to maximize signal with minimal flakiness and maintenance cost

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| test pyramid | Ratio guideline: many unit, fewer integration, few e2e | 70/25/5 split (example) | “Define tiers and guidelines per repo” | CI time under budget; failures localize quickly |
| contract test | Test that a provider meets a consumer’s API expectations | Pact between service A and B | “Version contracts; run in provider CI” | Breaking changes caught before deploy |
| flaky test quarantine | Isolate flaky tests to stop blocking delivery | Tag `@flaky`, run separately | “Owner, fix‑by date, and flake rate threshold” | Queue drains; flake rate trends down |
| risk‑based testing | Allocate testing depth to risk/impact | Deep tests around payments, light on admin UI | “Risk matrix and test depth mapping” | Coverage reflects risk; incidents down in high‑risk areas |
| determinism and hermeticity | Tests produce same results regardless of environment | Fixed seeds, no network | “Disallow external I/O; seed randomness” | Re‑runs match; fewer non‑repro failures |

- Best practices
    
    - Prefer contract tests at boundaries to keep e2e suites lean; add smoke e2e for the true happy path only.
    - Track and pay down flakiness like production incidents: owner, SLO for flake rate, weekly review.
    - Make every test runnable locally with one command and minimal setup; document data fixtures.

## Data engineering and migrations

- What these cover
    
    - Safe schema and data evolution, compat policies, and correctness checks

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| schema evolution | Managing change to data schemas over time | Add column with default | “State forward/backward compat policy” | Old and new versions interoperate |
| backward/forward compatibility | Old reads new data / new reads old data | Reader tolerates unknown fields | “Specify wire compat and deprecation period” | Contract tests across versions |
| expand/contract | Two‑phase zero‑downtime change (add new, migrate, remove old) | Write to both columns, then cut | “Plan phases, dual‑write window, verification” | No error during cutover; data checks pass |
| backfill | Populate data derived from existing records | Compute `normalized_email` for all users | “Define batches, throttling, idempotency” | Backfill resumes after failure; totals match |
| data contract | Formal expectations between producers and consumers | Avro schema with ownership and retention | “Versioned schema, owner, SLAs, PII class” | CI blocks incompatible changes |

- Best practices
    
    - Treat migrations as code with rehearsals in staging and verifiable post‑conditions (row counts, checksums, dual‑read comparisons).
    - Ensure idempotency and restartability for long‑running backfills; record progress and guard concurrency.
    - Write explicit compat policies (how long fields live; how unknown fields are handled) and test across versions.

## Program management and governance

- What these cover
    
    - Decision‑making, ownership, and flow of work at scale

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| RFC / design review | Lightweight proposal and feedback process | Doc with context, options, risks | “Template with decision log and reviewers” | Decisions captured; reviews timely |
| ADR (architectural decision record) | Short record of a significant decision and rationale | Choose Postgres over MySQL | “One file per decision; immutable; link consequences” | Referenced by code and docs; updated with superseded |
| RACI | Responsibility matrix (Responsible, Accountable, Consulted, Informed) | Launch plan roles | “Fill RACI table per cross‑team effort” | Less thrash; clear approvals |
| one‑way vs two‑way door | Irreversible vs reversible decision framing | Data model choice vs tunable config | “Call out reversibility and mitigation” | Review depth matches decision type |
| operational readiness review (ORR) | Gate before production ensuring supportability | On‑call, runbooks, dashboards in place | “Checklist and owners signed off” | Service accepted by SRE; fewer pager regressions |

- Best practices
    
    - Separate exploration from commitment: spike, compare options, then record an ADR with trade‑offs and consequences.
    - Make ownership explicit (service owners, on‑call rotations, escalation paths); publish a service catalog.
    - Use RACI for complex launches to avoid approval confusion and timeline drift.

## Security and supply chain

- What these cover
    
    - Preventative and detective controls across code, builds, and runtime

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| threat modeling | Structured analysis of how a system can be attacked | STRIDE per component | “Diagram, trust boundaries, mitigations, owners” | Findings tracked; mitigations in code |
| least privilege (reprise) | Access limited to necessary scope | Narrow IAM roles | “Access review cadence and tooling” | Periodic reviews; denied‑by‑default |
| secret management | Handling credentials safely | KMS + short‑lived tokens | “Ban plaintext secrets; rotate; detect leaks” | Scans clean; rotation logs |
| SBOM and SLSA | Software bill of materials and supply chain levels | Provenance for builds | “Generate SBOM; sign artifacts; define level target” | Verifiable attestations; policy checks in CI |
| policy as code | Enforceable rules encoded in code | OPA/Rego, Semgrep rule packs | “Define rules, owners, exception process” | CI blocks violations; exceptions audited |

- Best practices
    
    - Shift security left: static analysis and dependency checks in PRs; block critical issues by default with an exception path.
    - Treat secrets as toxic: minimize surface, rotate often, and monitor usage; ban long‑lived keys.
    - Verify provenance: signed builds, pinned dependencies, and attested releases.

## Cost and efficiency (FinOps)

- What these cover
    
    - Guardrails and practices to keep cloud and compute costs predictable and optimized

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| unit economics | Cost per meaningful unit (request, tenant, model token) | $ per 1k requests | “Pick unit, attribute costs, set target” | Dashboards show trend; alerts on regression |
| cost guardrails | Automated limits to prevent runaway spend | Budget alerts, quota caps | “Define per‑env caps and abort actions” | Spend stays within budget; automatic stops |
| allocation / showback | Attribute shared costs to teams/services | Tagging resources; split shared Egress | “Tagging policy; monthly reports” | Teams see costs; incentives align |

- Best practices
    
    - Make cost a first‑class SLO (budget burn similar to reliability); alert on cost per unit regressions.
    - Enforce tagging and environment separation; delete or hibernate idle resources.
    - Include cost checks in PR review for high‑impact changes (batch sizes, sampling, cardinality, precision).
