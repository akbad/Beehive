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
| docs‑as‑code | Manage docs with the same rigor as code | Docs in repo, reviewed via PRs | “Templates, CI link checks, owners” | Docs stay current and reviewable |
| single source publishing | Publish from one canonical doc/source | Generate API docs from OpenAPI | “Define source and targets” | No divergence across copies |
| information architecture (IA) | Structure and navigation of doc spaces | Task‑based sections; clear hierarchy | “Design IA; test findability” | Faster doc discovery |
| content debt | Accumulated outdated/duplicative/missing docs | Stale READMEs, duplicated pages | “Track and pay down quarterly” | Lower doc entropy |
| broken‑link budget | Limit on allowed broken links | 0 broken links in CI | “Automate link check in CI” | No broken links ship |
| docs ownership SLAs | Time to respond/update docs | 7‑day doc update SLA | “Owner tags and review cadence” | Stale docs trend down |
| ADR supersession policy | How ADRs are replaced/updated | ADR‑042 supersedes ADR‑031 | “Link superseded/superseding ADRs” | Clear decision history |
| knowledge base hygiene | Keep KB articles current and accurate | Archive stale pages quarterly | “Review cadence and owners” | KB remains trustworthy |
| last‑reviewed metadata standard | Required last‑reviewed tags | Add `last_reviewed: YYYY‑MM‑DD` | “CI check for freshness” | Docs kept fresh |

- Best practices
    
    - Prefer small, linkable pages with task‑focused titles; compose via links rather than giant pages.
    - Keep runbooks action‑first: prerequisites, steps, validation, rollback; include exact commands and owners.
    - Tag documents (owner, system, version, last‑reviewed) to enable maintenance.
    - Add doc coverage gates for changed public surfaces; measure coverage by surface area.
    - Require runnable examples for public APIs and test them in CI.
    - Automate freshness: fail CI when `last_reviewed` exceeds policy for critical docs; auto‑open tickets.
    - Apply runbook DRY: factor shared steps into includes/snippets to prevent divergence.
    - Run reader‑journey tests: have a new teammate complete a task using only docs; file gaps.

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
| bounded context | A clearly scoped domain area with its own model and language | Separate “Billing” and “Identity” models | “Define boundaries, owners, and integration contracts” | Fewer cross‑context leaks; clean interfaces |
| cohesion and coupling | Cohesion: how tightly related module’s responsibilities are; Coupling: how interdependent modules are | High cohesion within `payments/`; low coupling to `auth/` | “Refactor to increase cohesion; reduce unnecessary dependencies” | Smaller blast radius; simpler change sets |
| control plane vs data plane | Control: config/coordination; Data: user traffic handling | Service mesh control plane vs sidecars | “List which components are control vs data; isolate failures” | Control failure doesn’t drop data plane |
| sidecar pattern | Co‑process providing cross‑cutting concerns per instance | Envoy sidecar for mTLS and retries | “Define sidecar interfaces and resource limits” | App doesn’t embed network logic; consistent policies |
| service mesh | Network layer providing service‑to‑service features | mTLS, retries, circuit breaking via mesh | “Declare policies centrally; validate at edges” | Traffic policy applied consistently; fewer bespoke clients |
| partitioning strategy | How data/work is divided across shards/partitions | Hash by tenant id; range by time | “State key, cardinality, and balance plan” | Even load; minimal cross‑partition ops |
| shard rebalancing | Moving keys/partitions to keep load even | Reassign hot shards to new nodes | “Define triggers and migration steps” | No hotspots; minimal impact during move |
| partition key selection | Choosing the field(s) used to partition | Use `tenant_id` not `user_id` | “Estimate cardinality/skew; plan for growth” | Low skew; predictable scaling |
| cache stampede (aka dogpile) | Many clients rebuild cache simultaneously on expiry | Thundering recompute after TTL | “Use jittered TTLs and locking” | Flat CPU during expiry; single recompute |
| cache warming | Pre‑populate cache before traffic or expiry | Warm top N keys on deploy | “Schedule warms; choose key set” | Low cold‑start latency; fewer misses |
| hot path vs cold path | Hot: latency‑critical path; Cold: background/async | Sync write vs async enrichment | “Identify hot path code; keep it minimal” | P99 stable under load; perf profiles clean |
| fan‑in / fan‑out | Many inputs to one consumer / one input to many consumers | Aggregation service; broadcast to N workers | “Cap concurrency; bound queues” | No resource starvation; predictable latency |
| temporal coupling | Two components must be up at same time to work | Synchronous calls tie lifetimes | “Prefer async or retries/queues to decouple” | Fewer correlated failures; resilient retries |
| data locality | Keep compute near data to reduce latency/egress | Run jobs in same AZ/region as data | “Co‑locate services; avoid cross‑region hops” | Lower tail latency; reduced egress costs |
| transactional outbox | Record domain events in same transaction as writes | Write row + enqueue from outbox | “Implement outbox table + relay; idempotent” | No lost events; exactly‑once effect semantics |
| saga pattern | Orchestrated/choreographed sequence of local transactions with compensations | Reserve → charge → ship with compensations | “Define steps, compensations, and timeouts” | Failures compensate; no stuck partial state |
| try‑confirm‑cancel (TCC) | Two‑phase action with provisional hold then confirm/cancel | Pre‑auth card then capture/void | “Define expiry and idempotency per phase” | Holds expire; double‑charge prevented |
| dead‑letter queue (DLQ) | Queue for messages that repeatedly fail processing | Poison messages routed to DLQ | “Define retry count, DLQ retention, owners” | DLQ drained; root cause tracked |
| poison pill handling | Strategy for inputs that always fail | Quarantine + alert + manual fix path | “Detect patterns; add validation upstream” | Reduced reprocessing; clear runbook |
| hysteresis (breaker behavior) | Add different thresholds for open vs close to avoid flapping | Close only after sustained health | “Set open/close thresholds and windows” | Stable breaker state; fewer oscillations |
| CAP trade‑offs | Trade consistency, availability, and partition tolerance under network partitions | Choose AP with eventual consistency | “Document choice per subsystem and user impact” | Behavior under partition matches expectation |
| causal consistency | Reads reflect causally related writes | Show comment after posting it | “Guarantee session stickiness or version vectors” | No anomalies in causal chains |
| read‑your‑writes consistency | Client sees its own writes immediately | User sees profile update | “Implement per‑user cache bust/affinity” | Tests pass for self‑reads after write |
| monotonic reads | Reads do not move backward in time | Paginated reads don’t regress | “Use versioning or sequence IDs” | No time travel in reads during failover |
| paved road adoption | Measure/drive adoption of the golden path | % services on standard template | “Track adoption KPIs and blockers” | Adoption rises; incident rate drops |

- Best practices
    
    - Turn architectural tenets into fitness functions that run in CI (e.g., “public APIs must be backward compatible” as contract tests).
    - Prefer isolation (bulkheads, timeouts, budgets) over perfect resiliency; define failure domains and graceful fallbacks up front.
    - For migrations, design for coexistence (expand/contract, dual‑write, data verification) rather than big‑bang switches.
    - Set a complexity budget per module (cyclomatic complexity, fan‑out, file size) and require waivers for exceeding it.
    - Maintain an assumption ledger per subsystem with attached tests/monitors; review on major changes.
    - Track design debt with explicit expiry and owners; review quarterly.
    - Maintain a footgun registry of risky operations guarded by lints/wrappers; require explicit acknowledgment in PRs.
    - Prefer “two‑way doors” by default (adapters, flags, config); call out one‑way decisions for deeper review.

## Performance and resilience

- What these cover
    
    - Patterns and budgets that keep latency predictable, capacity healthy, and systems stable under stress

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| headroom (capacity margin) | Reserved capacity above steady demand | Keep 30% headroom | “Define per resource and env” | No saturation at peaks |
| latency budget | Target timing per step/path | 50 ms for auth, 100 ms DB | “Budget per hop; sum to SLO” | Profiles meet budgets |
| retry budget | Cap on retries to protect systems | Max 2 retries with backoff | “Define per client/resource” | No retry storms |
| jitter policy | Randomize retry/backoff to avoid sync | Add +/- 20% jitter | “Document jitter rules in libs” | Reduced herd behavior |
| timeout budget | Upper bound on wait times | 300 ms per dependency | “Set per hop; total < user SLO” | Fewer hung requests |
| priority inversion | Low‑priority work blocking high | Unbounded queues mix work | “Separate queues/pools per priority” | Critical work unaffected |
| thundering herd | Many workers wake at once overload | Cron fan‑out at top of minute | “Stagger schedules; jitter TTLs” | No synchronized spikes |
| cold start mitigation | Reduce first‑use latency | Warm instances, lazy‑load caches | “Prewarm critical paths” | Stable P99 after deploy |
| load shedding | Drop or degrade non‑essential work under load | Return 503 for expensive endpoints | “Define shed policy and thresholds” | Core path stays healthy |
| admission control | Refuse work when over capacity | Return 429 with retry‑after | “Set queue/backlog limits” | Protects system from overload |
| queue backpressure thresholds | Queue len thresholds to throttle | Pause producers at len > N | “Set thresholds per queue” | Stable throughput, bounded latency |
| prewarming strategies | Prepare capacity before spikes | Scale out before traffic spike | “Predictive rules; on‑call button” | Smooth traffic ramps |

- Best practices
    
    - Budget latency and timeouts per hop; prevent additive timeouts that exceed user SLOs.
    - Enforce retry budgets and jitter in shared client libraries; review production configs regularly.
    - Prefer proactive shedding and admission control over cascading failures; define non‑essential work explicitly.
    - Define performance budgets per feature during design and enforce in PRs and pre‑prod checks.
    - Maintain a load‑profile library (typical/peak/abuse) as reusable scenarios versioned with the service.
    - Set capacity headroom SLOs per resource with alerts and quarterly re‑estimation.
    - Use priority lanes (separate pools/queues) to protect critical work under load.
    - Include $/unit analysis alongside latency in performance trade‑offs.

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
| progressive delivery | Family of techniques to safely expose changes and learn | Use flags, canaries, and experiments | “Define stages, metrics, and stop conditions” | Evidence of learning; controlled risk |
| canary analysis (automated) | Automated stats comparison between canary and baseline | Compare error/latency distributions | “Pick metrics, test, and threshold method” | Auto‑promotion/rollback decisions logged |
| shadow traffic | Send real traffic to new path without user impact | Dual‑run new service; drop results | “Route mirrored traffic; compare outputs” | Output parity; zero user impact |
| bake time (post‑deploy) | Hold after deploy before further ramps | 30–120 minutes depending on risk | “Define bake windows per risk tier” | Issues found before mass impact |
| release train | Fixed cadence releases bundling changes | Weekly branch cut and ship | “Calendar, branch policy, rollback plan” | Predictable releases; less thrash |
| change freeze window | Period when no risky changes are allowed | EOY retail freeze | “Define dates/scope/exceptions” | Fewer incidents during peak |
| merge queue | Automated, serializable PR merges gated by checks | Queue merges with rebase + retest | “Enable required checks; serialize by queue” | Green main; fewer flaky breaks |
| trunk‑based development | Small, frequent merges to main with short‑lived branches | Feature flags replace long‑lived branches | “Policy: branch life < 2 days” | Fewer merge conflicts; higher flow |
| bisectability | Ease of pinpointing a bad change via binary search | Small commits, isolated diffs | “Keep changes small; single concern per PR” | Fast git bisect to culprit |
| artifact promotion | Move the same built artifact across envs | Promote image digest from staging → prod | “Ban rebuilds; sign artifacts” | Bit‑identical artifact; provenance intact |
| environment parity | Keep environments similar enough to predict prod behavior | Same versions/configs; prod‑like data | “Define parity levels and exceptions” | Fewer env‑only bugs |
| gated checks | Mandatory automated checks before merge/deploy | Tests, linters, security scans | “Define required checks; block on fail” | Reduced regressions; audit trail |
| release orchestration | Coordinated multi‑service rollout with dependencies | DB migrate → service A → service B | “Dependency graph and runbook” | Smooth multi‑service cutover |
| change risk scoring | Heuristic score predicting change risk | Large diff + low test coverage = high | “Define inputs/weights; act on score” | Fewer incidents from high‑risk changes |
| change failure rate (DORA) | % of deploys causing incidents or rollbacks | 10% CFR target | “Define severity threshold; track per team” | CFR trends down |
| deployment frequency (DORA) | How often you ship | Daily to production | “Measure per service/team” | Higher frequency with stable SLOs |
| lead time for changes (DORA) | Time from code commit to production | < 24 hours goal | “Instrument CI/CD timestamps” | Lead time trends down |
| MTTR (DORA) | Mean time to restore service after incident | < 30 minutes | “Track by severity class” | Faster recovery over time |

- Best practices
    
    - Every rollout plan includes a fast, scripted rollback with data safety notes; practice it.
    - Attach quantitative guardrails (latency/error/cost) and automated stop conditions to each exposure step.
    - Track flag lifecycle explicitly: creation reason → ramp plan → removal date; remove flags promptly to prevent configuration debt.
    - Run a pre‑mortem for risky changes: top failure modes, detection signals, kill‑switches, and rollback steps with owners/metrics.
    - Use record→replay verification to validate behavior/performance in staging before exposure.
    - Add shadow assertions in production that emit metrics on invariant violations without user impact.
    - Gate ramps with automated post‑deploy verification over a defined soak window.
    - Drill kill‑switches/flag aborts periodically in staging and at tiny scope in prod.
    - Include a “what would we roll back?” paragraph in PRs touching critical paths.
    - Add pre‑merge scenario analysis for critical changes (user flows, failure modes, observability deltas).
    - Track DORA with control charts to spot process regressions early.
    - Publish release notes with user and ops impact, including monitoring changes.
    - Automate “no orphan flags” ticketing (missing owner/expiry or stale checks).
    - Define auto‑backport policy for critical fixes with scripted backports.

## Observability and reliability (advanced)

- What these cover
    
    - Signals, alerting strategies, and pitfalls that separate solid ops from guesswork

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| golden signals (RED/USE) | Standard metrics sets for services (Rate, Errors, Duration) and resources (Utilization, Saturation, Errors) | Track R/E/D for HTTP, U/S/E for queues | “Define per service; add to dashboards” | Dashboards exist; alerts tied to SLOs |
| burn‑rate alerting | Alert on speed of SLO error budget consumption | 2h window at 14.4×, 24h at 6× | “Pick short/long windows and multipliers” | Alerts trigger early but not noisy |
| tail latency | High percentile latency representing worst user experience | P99.9 spikes despite median flat | “Monitor P95/P99/P99.9; avoid averages” | Percentiles recorded; regressions caught |
| cardinality explosion (aka cardinality budget/control) | Too many unique label combinations in metrics/logs | User‑id label on request metrics | “Whitelist labels; sample or hash high‑card fields” | Metric ingestion stays within budget |
| trace sampling (tail‑based) (aka tail sampling policy) | Choose traces to keep based on interesting signals | Keep error/slow traces | “Define sampling rules; budget target” | Trace store cost bounded; useful traces kept |
| blackbox vs whitebox monitoring | Blackbox: externally observed; Whitebox: internal metrics | HTTP probe vs app metrics | “Define both per service; avoid either‑only” | Outages detected even if app metrics fail |
| synthetic monitoring | Scripted checks from user perspective | Login flow synthetic probe | “Define critical user journeys; run on schedule” | Detects failures before users do |
| error budget policy | Rules tying feature velocity to SLO burn | Freeze on burn > threshold | “Document policy and actions” | Velocity throttles when reliability degrades |
| toil budget | Time reserved to reduce repetitive manual work | 20% of on‑call time on automation | “Track toil hours; prioritize eliminations” | Toil trends down; fewer tickets |
| auto‑remediation | Safe automated actions to fix known issues | Restart crashed worker automatically | “Guardrails, canaries, abort conditions” | Remediations help without flapping |
| runbook automation | Script runbook steps to reduce MTTR | One‑click failover script | “Idempotent scripts with dry‑run” | Faster, safer incident response |
| correlation ID | Identifier propagated across logs/metrics/traces | `x‑request‑id` across services | “Inject/propagate in middleware” | End‑to‑end debugging possible |
| histogram buckets | Bucket boundaries for latency/size distributions | Exponential buckets for latency | “Choose buckets aligned to SLOs” | Actionable histograms; low quantile error |
| exemplars | Link metrics to example traces | Attach trace id to error metric | “Emit exemplars on anomalies” | Faster root cause via drill‑down |
| saturation vs utilization | Utilization = how busy; Saturation = queued work | CPU 80% vs run queue length | “Track both for resources” | Capacity limits caught early |
| high‑watermark / low‑watermark | Thresholds that define healthy ranges | Queue len 0–1 healthy; >10 alert | “Set both bounds; add hysteresis” | Fewer alert flaps; stable systems |
| noise budget for alerts | Explicit cap on alert volume/page load | < 2 pages/on‑call/week | “Track, review, and prune alerts” | Sustainable on‑call; high signal |
| observability golden path | Standardized way to instrument, log, alert | Library + templates per service | “Adopt path; lint for usage” | Consistent, high‑quality telemetry |
| log hygiene (structured logging) | Logs are structured, leveled, and PIIsafe | JSON logs with levels and fields | “Schema and redaction policy” | Searchable, compliant logs |

- Best practices
    
    - Alert on symptoms (SLO) not just causes; keep pages scarce and actionable with runbook links.
    - Control metric cardinality by policy; separate high‑cardinality data to logs/traces with sampling.
    - Include correlation IDs across logs and traces; require a request context in libraries.
    - Define observability contracts per service (required metrics/log schemas/traces) with SLO‑aligned buckets and cardinality guardrails.
    - Create an error taxonomy and codebook that maps error codes to runbook steps and user messages.
    - Require exemplars on high‑value metrics to link to representative traces.
    - Hold a monthly alert review with a noise budget; prune or fix the noisiest alerts.
    - Standardize first‑screen dashboards (SLO, burn, RED, dependencies) to reduce incident cognitive load.

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
| mutation testing | Deliberately introduce small code changes to ensure tests fail appropriately | Mutate operators/branches | “Run mutation score; set target” | Higher mutation score indicates robust tests |
| property‑based testing | Generate inputs to verify properties/invariants | Commutativity, idempotence properties | “Define properties; limit search space” | Fewer missed edge cases |
| fuzz testing | Randomized input to find crashes/security issues | Fuzz parsers/decoders | “Set corpus, seed, and time budget” | Crashes reproduced and fixed |
| snapshot/golden tests | Compare output to a stored canonical result | Formatter output matches golden file | “Review/approve golden updates” | Diffs surface unintended changes |
| approval tests | Human‑approved outputs checked into repo | UI render approved images | “Define approval process” | Intentional changes only merged |
| test oracles | Mechanism to decide pass/fail when expected result is unknown | Invariants, metamorphic relations | “Define oracle rules” | Reliable test judgments |
| test doubles (stub/mock/fake/spy) | Stand‑ins for dependencies to isolate tests | Mock HTTP client | “Choose the right double per need” | Stable, fast tests |
| seams for testing | Places to insert doubles/config for tests | Inject interfaces/factories | “Design seams at boundaries” | Easier isolation; less flakiness |
| fixture management | Strategy for test data setup/teardown | Factories, builders, ephemeral DBs | “Standardize fixtures; avoid shared state” | Faster, reliable tests |
| contract‑first testing (aka contract test) | Generate/provider tests from agreed contract | OpenAPI/Pact‑driven | “Own the contract; version and validate” | Provider breaks caught early |
| non‑flaky test policy | Team rules to keep flakes out of main | Quarantine + SLO + ownership | “Policy doc and weekly triage” | Flake rate trends down |
| quarantine lanes (aka flaky test quarantine) | Dedicated CI lane for flaky tests | Separate job, non‑blocking | “Auto‑move flakes; track SLO” | Main CI stays green |
| coverage quality (risk‑weighted) | Weight coverage by risk not just lines | Critical modules need more | “Map risk → coverage target” | Useful coverage; fewer blind spots |
| test data management | Managing datasets safely and reproducibly | Synthetic data; anonymized prod samples | “Catalog datasets; access controls” | Repro tests; compliant data use |

- Best practices
    
    - Prefer contract tests at boundaries to keep e2e suites lean; add smoke e2e for the true happy path only.
    - Track and pay down flakiness like production incidents: owner, SLO for flake rate, weekly review.
    - Make every test runnable locally with one command and minimal setup; document data fixtures.
    - Add performance regression gates in CI with small‑noise thresholds and auto‑bisect on regressions.
    - Write guardrail tests for architectural invariants (for example, auth always runs before the handler).
    - Maintain golden datasets (PII‑safe, realistic distributions) for tests/benchmarks/load; version with changelogs.
    - Use test impact analysis to run only affected tests plus a thin e2e slice; publish the impacted list.
    - Page owning teams when flake SLOs are breached; treat as incidents with action items.

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
| schema registry | Central store for versioned schemas | Confluent/Avro schema registry | “Enforce compatibility policies” | Producers/consumers validated in CI |
| CDC (change data capture) | Stream changes from source DB to downstream | Debezium stream to analytics | “Define lag SLO and replay policy” | No data loss; bounded lag |
| read repair | Fix inconsistent replicas during reads | Update stale replica on read | “Enable conditional write on mismatch” | Consistency improves over time |
| dual‑write window (aka expand/contract dual‑write) | Period writing to old and new destinations | Dual‑write to old/new topics | “Bound duration; verify parity” | Exit window after parity proven |
| quiescing | Pause writes/traffic to make a change safely | Freeze writes for keyspace split | “Define quiesce window and abort” | No data races during change |
| online schema change | Apply schema changes without downtime | `gh-ost`, `pt-online-schema-change` | “Choose tool; monitor lag” | Zero‑downtime migrations |
| ghost tables | Shadow tables used during online change | Write to ghost then swap | “Plan swap and cleanup” | Correct final schema; minimal lock time |
| compaction/vacuum windows | Maintenance windows for storage engines | Nightly compaction schedule | “Set cadence and thresholds” | Stable storage performance |
| watermarking (batch progress) | Marker indicating processed up to time/offset | High‑watermark timestamp | “Store per job; alert on staleness” | No silent data lag |
| data residency | Keeping data in allowed regions | EU‑only storage for EU users | “Tag residency and enforce routing” | Audits pass; no cross‑region leaks |
| retention policy | How long to keep data by class | Delete logs after 30 days | “Define by class; automate deletes” | Deletions logged; cost controlled |
| legal hold | Prevent deletion due to legal request | Suspend deletion of user X data | “Record scope/duration; audit trail” | Holds honored; deletions paused |
| PII classification | Tag and protect personal data classes | `email` as PII; `country` as low risk | “Classify fields; apply controls” | Access controlled; masked in logs |
| lineage tracking | Track where data originates and flows | Column‑level lineage in warehouse | “Automate lineage collection” | Impact analysis accurate |
| reconciliation job | Periodic job that compares two sources of truth | Compare ledger vs payments processor | “Define comparisons and tolerances” | Discrepancies surfaced and resolved |
| consistency checker | Tooling/tests to detect inconsistent state | Foreign keys, checksums, invariants | “Schedule checks; alert on drift” | Early detection of corruption |

- Best practices
    
    - Treat migrations as code with rehearsals in staging and verifiable post‑conditions (row counts, checksums, dual‑read comparisons).
    - Ensure idempotency and restartability for long‑running backfills; record progress and guard concurrency.
    - Write explicit compat policies (how long fields live; how unknown fields are handled) and test across versions.
    - Author backfill playbooks with safety budgets (QPS/CPU/IO/deadlines) and auto‑pause on threshold breach.
    - Record lineage impacts at PR time (upstream/downstream assets) and require checks to pass.
    - Rehearse data deletion/retention flows quarterly with proof artifacts.
    - Run always‑on consistency monitors (counts, checksums, FK‑like invariants) that file tickets on drift.
    - Define statistical parity exit criteria for dual‑write windows and remove old paths promptly.

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
| service catalog | Inventory of services with owners and metadata | Backed by code ownership files | “Publish catalog; require ownership” | Clear ownership; faster routing |
| ownership model (single‑owner) | Exactly one accountable owner per thing | One team owns service X | “Define accountable team; publish map” | Fewer gaps/overlaps |
| operational maturity levels | Staged criteria for readiness and ops quality | L1→L4 maturity rubric | “Assess quarterly; track deltas” | Upward maturity trend |
| deprecation policy | Rules for retiring features/APIs safely | 90‑day deprecation window | “Announce, dual‑support, remove” | Smooth sunsets; fewer surprises |
| sunset plan | Concrete steps/timeline to remove | Notify → disable new → migrate → delete | “Owners, dates, and comms plan” | Clean decommissions |
| risk register | List of known risks with severity/owners | Single place to track mitigations | “Review cadence and owners” | Fewer unknown‑unknowns |
| RFC ladder | Scaled review process by impact | Minor RFC vs major design review | “Define thresholds and templates” | Right‑sized process |
| decision log | Chronological record of key decisions | Short entries with links | “Update alongside PRs/ADRs” | Context recoverable later |
| paved‑road metrics | Measures of adoption and outcomes | % repos using template | “Define KPIs; report quarterly” | Proof paved road works |
| escalation policy | How incidents and blockers escalate | Pager chain and timelines | “Publish; test via drills” | Faster resolution; fewer stalls |
| incident roles (IC/commander, scribe) | Defined roles during incidents | IC directs; scribe records | “Train and rotate roles” | Clear comms; lower MTTR |
| comms plan (stakeholder mapping) | Who to inform for what changes/incidents | Matrix by audience/severity | “Templates and channels defined” | No surprises; correct cadence |
| readiness checklist (launch/ORR variants) | Pre‑launch checklist variants by risk | DB + SRE + security checks | “Tailor per class of change” | Fewer launch incidents |
| quarterly technical plan (QTP) | Quarterly engineering strategy and commitments | Q goals, NFRs, risks | “Publish and review cross‑org” | Alignment and delivery |
| drift review (tech, doc, config) | Regular review for divergence from source of truth | Code vs docs vs configs | “Schedule; file tickets” | Reduced drift over time |

- Best practices
    
    - Separate exploration from commitment: spike, compare options, then record an ADR with trade‑offs and consequences.
    - Make ownership explicit (service owners, on‑call rotations, escalation paths); publish a service catalog.
    - Use RACI for complex launches to avoid approval confusion and timeline drift.
    - Add a reversibility memo to significant decisions describing how to undo them.
    - Call out option closure explicitly and what evidence would reopen alternatives.
    - Mark decisions with an expiry/review date; automate reminders.
    - Map stakeholders for each change (users, ops, support, security) and define comms.
    - Require cross‑team readiness sign‑off for changes crossing boundaries.

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
| defense in depth | Multiple, independent layers of protection | Network + authz + input validation | “Enumerate layers; verify independence” | Single failure doesn’t compromise system |
| attack surface | All ways an attacker could interact | Open ports/APIs, inputs | “Inventory and reduce exposure” | Fewer exposed endpoints |
| security posture | Overall security health | Posture scores; audit findings | “Set targets; remediate gaps” | Improved posture scores |
| hardening baseline | Minimum secure configuration standard | CIS benchmarks applied | “Baseline per OS/runtime; verify” | Drift alerts; hardened images |
| config drift detection | Detect changes from approved configs | GitOps drift alerts | “Define desired state and checks” | Drift detected early; reconciled |
| egress controls | Control outbound network traffic | Egress firewall rules | “Default‑deny; allow by policy” | Blocked exfiltration paths |
| break‑glass access | Emergency, time‑bound elevated access | Pager‑protected one‑time tokens | “Approval, logging, expiry” | Properly audited, time‑boxed access |
| key rotation cadence | Planned rotation frequency | Quarterly key rotation | “Automate rotation; alert on staleness” | Old keys retired on schedule |
| secrets sprawl | Uncontrolled secrets proliferation | Many long‑lived tokens | “Centralize, rotate, delete unused” | Secret count down; fewer exposures |
| vulnerability management (CVE/CVSS) | Process for finding, scoring, fixing vulns | Patch cycle by severity | “SLAs by CVSS; dashboards” | Faster time‑to‑patch |
| patch management policy | Policy for applying security updates | Monthly OS patching | “Window, owner, rollback” | Patched fleet; exceptions tracked |
| runtime protection (RASP) | In‑app runtime attack detection/defense | RASP agent blocks RCE payload | “Scope and false‑positive policy” | Blocks true attacks; low noise |
| dependency pinning | Lock dependency versions | Pin in lockfiles | “Renovate/Dependabot policy” | Repro builds; fewer supply‑chain issues |
| provenance attestation | Signed statements about build origin | SLSA attestations | “Sign and verify in CI/CD” | Tamper‑evident releases |
| artifact signing | Cryptographically sign artifacts/images | Cosign‑signed images | “Verify at deploy time” | Only trusted artifacts run |
| exception/waiver process | Controlled process to allow temporary policy exceptions | Approved waiver with expiry | “Owner, expiry, compensating controls” | Exceptions tracked and sunset |
| separation of duties | Split critical capabilities across people/roles | No single actor can deploy+approve | “Define SoD matrix” | Reduced insider risk |
| audit trail completeness | Full, immutable logs of sensitive actions | Append‑only logs with retention | “Scope, retention, integrity” | Audits pass; forensics possible |
| DLP (data loss prevention) | Prevent unauthorized data exfiltration | DLP rules for PII egress | “Define detectors and actions” | Exfil attempts blocked |
| data minimization | Collect/store only what is necessary | Drop unused fields | “Define necessity; delete excess” | Smaller blast radius; less risk |

- Best practices
    
    - Shift security left: static analysis and dependency checks in PRs; block critical issues by default with an exception path.
    - Treat secrets as toxic: minimize surface, rotate often, and monitor usage; ban long‑lived keys.
    - Verify provenance: signed builds, pinned dependencies, and attested releases.
    - Add a security pre‑flight checklist for risky PRs; write targeted Semgrep rules when needed.
    - Enforce secrets lints pre‑commit and in CI with a waiver path that expires.
    - Review dependency diffs (including transitives) for new CVEs/licenses; require explicit acknowledgment.
    - Verify signatures and provenance at deploy time (not only at build).
    - Require after‑action reviews for any break‑glass access with compensating controls.

## Cost and efficiency (FinOps)

- What these cover
    
    - Guardrails and practices to keep cloud and compute costs predictable and optimized

- Core terms and translations

| Term | Plain meaning | Example in practice | Make it concrete | Verification |
| --- | --- | --- | --- | --- |
| unit economics | Cost per meaningful unit (request, tenant, model token) | $ per 1k requests | “Pick unit, attribute costs, set target” | Dashboards show trend; alerts on regression |
| cost guardrails | Automated limits to prevent runaway spend | Budget alerts, quota caps | “Define per‑env caps and abort actions” | Spend stays within budget; automatic stops |
| allocation / showback | Attribute shared costs to teams/services | Tagging resources; split shared Egress | “Tagging policy; monthly reports” | Teams see costs; incentives align |
| right‑sizing | Match resource size to actual usage | Resize over‑provisioned instances | “Set headroom targets and review cadence” | Lower cost without SLO impact |
| autoscaling policy | Rules for scaling up/down | CPU/queue‑based scaling | “Define metrics, cool‑downs, min/max” | Stable scaling; no thrash |
| spot/preemptible strategy | Use cheaper, interruptible capacity safely | Stateles workers on spot | “Diversify pools; rapid replacement” | Cost down; avail maintained |
| reserved/savings plans coverage | Pre‑commit to capacity for discounts | 70% coverage target | “Coverage KPI and purchase playbook” | Lower unit cost |
| cost anomaly detection | Detect unusual spend spikes quickly | Daily anomaly jobs | “Thresholds and auto‑halts” | Spikes caught early |
| cost SLOs | Targets for cost per unit | $/request budget | “SLO and burn alerts” | Budget burn under control |
| cost attribution accuracy | Correctly map spend to owners | Tagging completeness score | “Tagging policy; enforcement” | Accurate showback |
| idle shutdown policy | Turn off idle resources | Nightly dev cluster shutdown | “Idle criteria and schedule” | Idle spend reduced |
| precision/sampling budgets (metrics/logs) | Balance cost vs fidelity | Lower log sampling in dev | “Sampling policy per env” | Predictable telemetry cost |

- Best practices
    
    - Make cost a first‑class SLO (budget burn similar to reliability); alert on cost per unit regressions.
    - Enforce tagging and environment separation; delete or hibernate idle resources.
    - Include cost checks in PR review for high‑impact changes (batch sizes, sampling, cardinality, precision).
    - Add cost‑of‑delay framing to backlog items to inform prioritization.
    - Consider carbon/energy budgets where relevant for heavy jobs and include in trade‑offs.
    - Drill cost anomaly response (halt conditions, rollback) to speed containment.
    - Run an idle‑resource watchdog to detect and shut down unused capacity.
    - Set and review sampling/precision budgets by environment for telemetry cost control.
