# Models decision guide

> Guide, for both humans and agents, as to when to use a particular model with a particular subagent spawned via Zen's `clink` tool.

## Models available and their constraints

| Company | CLI tool | Current membership tier | Models available | Constraints/usage limits |
| :------ | :------- | :---------------------- | :--------------- | :----------------------- |
| OpenAI | Codex CLI | ChatGPT Pro | GPT-5 and GPT-5-Codex (Low, Medium and High Thinking modes for each) | Practically unlimited |
| Anthropic | Claude Code | Claude Max 5x | Haiku 4.5, Sonnet 4.5, Opus 4.1 | Very, very generous limits for Haiku 4.5; generous limits for Sonnet 4.5; strict, low limits on Opus 4.1 that are only reset weekly | 
| Google | Gemini CLI | Free tier (very generous) | Gemini 2.5 Pro | Practically unlimited |

## Model strengths/weaknesses

- GPT-5 (Low, Medium and High Thinking modes)
  - **Top-tier for**: Reasoning benchmarks (94.6% AIME 2025, 88.4% GPQA), code refactoring (91% multi-file success), agentic coding (74.9% SWE-bench), architectural analysis, code reviews
  - **Excellent for**:

    | Use case | Why |
    |----------|-----|
    | Code Refactoring | 91% success on multi-file refactoring (GPT-5-Codex variant); superior at large-scale code changes with dependency reasoning |
    | Architecture Reviews | Produces tighter architectural reads, clearer plans, reliable fixes on complex changes; strong visual input analysis |
    | API/Backend Design | Contract-first design, client/server stubs, idempotency/retry patterns; OpenAPI/GraphQL schema excellence |
    | Performance Optimization | Finds N+1s, blocking I/O, complexity issues; suggests caching/batching with strong reasoning (88% Aider Polyglot) |
    | Testing/Verification | Unit/property/mutation tests with high success rate; CI flake triage; hermetic test design |
    | Migration Planning | Deep reasoning for migration strategies; checkpoint-based planning; handles complex dependency chains |

  - **Good for**:

    | Use case | Why |
    |----------|-----|
    | DevOps/Infrastructure | IaC scaffolds (Terraform/K8s), CI steps, policy wiring; may use over-permissive defaults - review required |
    | Data Engineering/ML | ETL wiring, SQL tuning, job orchestration; but may misestimate memory/backpressure - validate with profiling |
    | Security Auditing | Secret scanning, common vuln patterns, policy-as-code; pairs well with Semgrep; but naïve fixes possible |
    | Distributed Systems | Backpressure, retries, circuit breaking; strong reasoning on consensus algorithms; queue/pool sizing needs validation |
    | Database Optimization | Query/index refactors, migration plans, connection pooling; verify with EXPLAIN/ANALYZE |
    | Frontend Development | Component refactors, accessibility, Storybook updates; but CSS edge-cases need review |

  - **Moderate for**:

    | Use case | Why |
    |----------|-----|
    | Documentation | Technically accurate but less engaging than Claude; good for API docs, weaker for narrative/onboarding content |
    | Real-time Systems | Latency budgets and proposals solid, but OS/hardware nuances (NUMA/GC) need bench validation |
    | Language-Specific Idioms | Competent across C++/Rust/Go but may miss language-specific best practices vs specialized models |

  - **Less ideal for**:

    | Use case | Why |
    |----------|-----|
    | Creative/Narrative Writing | Claude Sonnet 4.5 superior for engaging docs, storytelling, developer onboarding, natural prose |
    | Large Codebase Analysis | 400k context vs Gemini's 1M tokens - cannot analyze entire services/repos in single context |
    | Math-Heavy Research | Strong (94.6% AIME) but Gemini 2.5 Pro faster and free with comparable math capabilities |

  - **Key advantages**:
    - **GPT-5-Codex variant**: Purpose-built for agentic software engineering with exceptional multi-file refactoring (91% success)
    - **Adaptive thinking**: Dynamic reasoning allocation - fast when possible, deep when needed (Low/Medium/High modes)
    - **Refactoring excellence**: Best-in-class at large-scale code changes with dependency awareness
    - **Architectural clarity**: Produces clearer plans and tighter architectural analysis than competitors
    - **Lower hallucination rate**: Better at reducing invented issues/code compared to earlier models
    - **Multimodal strength**: Strong visual input analysis for UI/diagram review

  - **Key limitations**:
    - **Context window**: 400k tokens vs Gemini's 1M - limits whole-repo/multi-service analysis
    - **High mode risks**: May "overthink" or invent issues on High thinking mode - keep grounded with tests/artifacts
    - **Cost**: Paid tiers required vs Gemini's free unlimited tier
    - **Creative writing**: Claude Sonnet 4.5 produces more engaging, natural documentation
    - **Speed trade-off**: High thinking mode significantly slower (52min vs Sonnet's 39min on complex tasks)

  - **Thinking mode guidance**:
    - **Low**: Single-file features, docstrings, small tests, formatting - balances speed with light planning
    - **Medium (default)**: Cross-file changes, API glue, query edits - best baseline for most subagent roles
    - **High**: Complex migrations, concurrency design, recovery flows, architectural redesign - reserve for truly complex problems requiring deep planning

  - **Strategic use**: First choice for: (1) large-scale refactoring/migrations (2) architecture reviews needing clarity (3) code quality requiring low hallucination (4) teams already on ChatGPT Pro (unlimited access)

- GPT-5-Codex (Low, Medium and High Thinking modes)
    
    - Positioning: specialized for agentic coding with strong multi-file editing, refactors, and CLI/tool orchestration; defaults to safe, sandboxed execution with good traceability.
    - Thinking effort guide
        - minimal: quickest for deterministic edits (formatting, extraction, small regex fixes, snapshot updates); weakest at synthesis or multi-hop reasoning.
        - low: good for single-file features, docstrings, small tests; balances speed with light planning; may miss cross-cutting constraints.
        - medium (default): reliable for cross-file changes, API glue, query edits; best baseline for most subagent roles.
        - high: use for complex migrations, concurrency design, recovery flows; higher latency/cost; occasionally “overthinks” or invents issues—keep it grounded with concrete artifacts and tests.
    - Cost/latency trade-offs
        - minimal/low keep costs and latency down for everyday edits
        - high increases tokens and latency—reserve for problems that truly need deep planning and justification
    - Task category breakdown

        | Task category | Strengths | Weaknesses | Effort |
        | :------------ | :--------- | :--------- | :----- |
        | Architecture/design analysis (architect, design-analysis) | decomposes modules, proposes interfaces, flags coupling; produces migration plans with checkpoints. | can overspec; prefers ideal patterns over constraints; mitigate with budget/SLAs and repo reality (Sourcegraph context). | medium for review/suggestions; high for ground-up re-architecture with trade-off tables. |
        | Large migrations/refactors (migrations/refactors, tech-debt) | mass-rename, interface swaps, pattern lifting; consistent code updates with tests. | drift on edge cases; brittle mocks; mitigate via incremental branches and verification passes. | medium for scoped refactors; high for repo-wide changes with safety nets. |
        | API/integration (api-integration, backend-architect) | contract-first design, client/server stubs, contract tests, idempotency/retry patterns. | occasional overconfident stubs, hard-coded config; enforce policy files and secrets hygiene. | low/medium for glue code; high for gateways, versioning, and E2E rollouts. |
        | Data/ML pipelines (ai-ml, data-engineer, sql-pro) | ETL wiring, SQL tuning, dataset/schema validation, job orchestration templates. | library/version brittleness; memory/backpressure misestimates; validate with profiling and EXPLAIN plans. | medium; high when optimizing joins/windows or streaming semantics. |
        | Frontend/design systems (frontend-ux, design-systems) | component refactors, tokens, accessibility nits, storybook/test updates. | CSS specificity/layout edge-cases; visual fidelity requires review. | minimal/low for style tweaks; medium for component library changes. |
        | Platform/DevOps/Infra (devops-infra, platform-engineering, terraform) | IaC scaffolds (Terraform/K8s), CI steps, policy wiring, progressive delivery. | over-permissive defaults, noisy alerts; pin images, apply OPA/Conftest. | medium; high for multi-region or DR topologies. |
        | Observability/incident (observability-incident, docs-agent) | golden-signal dashboards, SLO/error budgets, runbooks, incident timelines. | speculative RCA without data; require logs/traces and citations. | low/medium for dashboards/runbooks; high to synthesize RCA across services. |
        | Reliability/scalability (reliability, distributed-systems) | backpressure, retries/jitter, circuit breaking, graceful degradation. | tuning knobs (queues/pools) easy to mis-size; validate with load tests. | medium for patterns; high for capacity plans and failure-mode analysis. |
        | Security/privacy (security-privacy) | secret scanning, common vuln patterns, policy-as-code, secure defaults checklists. | naïve fixes, false positives; pair with Semgrep rules and human review. | low/medium for linting/fixes; high for threat models. |
        | Testing/verification (testing-and-verif, task-decomp) | unit/property tests, mutation tests, CI flake triage, reproducible seeds. | brittle mocks/fixtures; enforce hermetic helpers and contract tests. | minimal/low for snapshots and simple units; medium/high for integration matrices. |
        | Performance optimization (optimization, perf-optimizer) | finds N+1s, blocking I/O, bad complexity; suggests caching, batching, pool tuning. | micro-optimization bias without profiles; require traces/benchmarks. | medium; high for algorithmic or architecture-level improvements. |
        | Real-time systems (real-time-systems) | latency budgets, jitter control, scheduling/backpressure proposals, serialization/transport tuning. | OS/hardware nuances (NUMA/GC/interrupts) need bench validation; avoid speculative tuning. | high for design; medium for scoped code changes with budgets enforced in tests. |
        | Databases/SQL (database-specialist, sql-pro) | query/index refactors, migration plans, connection pool guidance, consistency talk-throughs. | corner-case indexing and planner heuristics; always verify with EXPLAIN/ANALYZE. | medium; high for heavy migrations and partitioning. |
        | Systems languages (cpp-pro, rust-pro, golang-pro) | scaffolds, concurrency primitives, FFI patterns, safety idioms. | UB/unsafe edges require rigorous compile/test/fuzz loops. | medium/high depending on safety and concurrency complexity. |
    
- Gemini 2.5 Pro
  - **Top-tier for**: Math/science reasoning (88% AIME 2025, 86.4% GPQA), large codebase analysis (1M context), agentic coding (67.2% SWE-bench), code editing (82.2% Aider), web development generation
  - **Excellent for**:

    | Use case | Why |
    |----------|-----|
    | Architecture/System Design | Best-in-class long context for entire service analysis; simultaneous consideration of performance, security, maintainability |
    | Data Engineering/ML | Superior math reasoning for pipeline optimization, feature engineering, model evaluation; 1M context for analyzing large datasets/logs |
    | Database Optimization | Strong at query plan analysis, schema design with mathematical rigor; long context handles entire slow query logs |
    | Performance Optimization | Mathematical approach to complexity analysis; can analyze entire service for bottlenecks |
    | Migration/Refactoring | 1M context enables analyzing entire legacy systems at once; strong multi-file reasoning |
    | Research/Documentation | Factuality (54% SimpleQA); multimodal for analyzing diagrams/charts; generates hierarchical docs aligned with industry standards |

  - **Good for**:

    | Use case | Why |
    |----------|-----|
    | DevOps/Infrastructure | IaC generation, config optimization; but verify security hardening (7 OWASP/MITRE findings in tests) |
    | Testing | Test generation, coverage analysis; mathematical reasoning for property-based testing strategies |
    | API Integration | Code generation for API clients/servers; OpenAPI/GraphQL schema design |
    | Distributed Systems | Strong reasoning for consensus algorithms, consistency models; long context for cross-service analysis |

  - **Moderate for**:

    | Use case | Why |
    |----------|-----|
    | Frontend/UX | Competent React/TypeScript generation but not specialized; multimodal helps with design analysis |
    | Security Auditing | Strong at threat modeling but prone to false positives; OWASP tests revealed vulnerabilities - use GPT-5 or Claude for critical security |
    | Tech Debt Analysis | Good at identifying patterns but can modify unrelated code segments - requires careful prompting |

  - **Less ideal for**:

    | Use case | Why |
    |----------|-----|
    | Creative/Narrative Docs | Claude Sonnet superior for engaging developer documentation, storytelling, onboarding guides |
    | Language Specialists (C++/Rust/Go) | Competent but GPT-5-Codex or Claude Sonnet show better language-specific idioms |
    | Prompt Engineering | Not meta-optimized for prompt crafting compared to GPT-5 or Claude |

  - **Key limitations**:
    - Can modify unrelated files/code during complex changes (precise instructions required)
    - Security testing shows 7 OWASP Top 10 / MITRE ATLAS vulnerabilities
    - Some code integration issues reported in multi-file edits
  - **Cost advantage**: Free tier with practically unlimited usage - use liberally for research, prototyping, large-scale analysis
  - **Strategic use**: first choice for
    1. tasks needing 100k+ token context
    2. math-heavy work 
    3. multi-service/entire-repo analysis 
    4. budget-constrained projects
- Haiku 4.5
    
    - **Top-tier for**: Fast, cost‑efficient agentic workflows; interactive editing and short‑horizon tasks at scale; high‑volume applications needing reliable coding + tool use with low latency
        
        - Highlights: near‑frontier intelligence with blazing speed; optimal cost/performance; first Haiku with Extended Thinking; context awareness; full tool support (bash, editor, browser/computer use); parallel tool execution
    
    - Extended thinking modes
        - Off (default): maximum responsiveness for interactive loops (edit‑run‑fix); great for small/medium feature work, quick reviews, and incremental code edits
        - On (extended thinking): deeper multi‑step reasoning when tasks exceed one‑prompt scope; improved plan quality and tool orchestration at the cost of higher latency/token use; set budgets to control depth
    
    - **Excellent for**:
        
        | Use case | Why |
        |----------|-----|
        | Real‑time applications/UI loops | Very fast responses keep developer feedback cycles tight; strong instruction following for precise edits |
        | High‑volume automation | Favorable pricing enables scalable batch edits, code hygiene, and doc generation at scale |
        | Sub‑agent architectures | Lightweight, responsive subagents for decomposition, with tool use and context awareness |
        | Computer use at scale | Reliable browser/desktop automation for repeatable flows with strong tool success rates |
        | Code editing & lint‑fix passes | Accurate, low‑latency edits with parallel tool calls; ideal for CI “fix‑up” steps |
    
    - **Good for**:
        
        | Use case | Why |
        |----------|-----|
        | CRUD APIs and integration glue | Generates endpoints/clients and tests quickly; extended thinking helps with versioning plans |
        | Data/ETL scaffolding | Orchestrates pipelines and validations; fast iteration on schemas/configs |
        | Documentation & onboarding | Produces concise, professional docs and code tours with low cost/latency |
        | Observability basics | Generates dashboards/runbooks quickly; pair with traces/logs for accuracy |
        | Security hygiene | Secret scanning/policy templates; use rules + review to reduce false positives |
    
    - **Moderate for**:
        
        | Use case | Why |
        |----------|-----|
        | Long‑horizon multi‑service refactors | Can plan and execute incrementally; Sonnet 4.5 often better for deeper trade‑off analysis |
        | Heavy research/synthesis | Extended thinking improves depth, but Sonnet 4.5 stronger on complex, multi‑source synthesis |
        | Advanced performance investigations | Finds common anti‑patterns; deep algorithmic/OS‑level tuning benefits from Sonnet or GPT‑5 |
    
    - **Less ideal for**:
        
        | Use case | Why |
        |----------|-----|
        | Deep architectural redesigns | Sonnet 4.5 provides more thorough trade‑off exploration and longer outputs |
        | Strict real‑time/low‑level tuning | Hardware/kernel nuances require on‑target profiling; prefer specialized models/workflows |
        | Highly stylized long‑form narrative | Capable, but other models may better match tone/long‑form narrative fidelity |
    
    - **Key limitations**:
        - Shallower default depth than Sonnet on long‑horizon tasks; enable extended thinking or escalate when needed
        - Extended thinking increases latency and tokens; apply budget controls and use selectively
        - As with any model, verify multi‑file edits and infra changes via tests, CI, and policy checks
    - **Strategic use**: Default choice for speed/cost‑sensitive agentic coding, CI “fix‑up” steps, batch code hygiene, and scalable computer‑use workflows; enable extended thinking for multi‑step tasks, and escalate to Sonnet 4.5 for deep design, complex RCA, and large refactors
- Sonnet 4.5
    
    - **Top-tier for**: Agentic coding and multi-step computer use; long-running agents that coordinate multiple tools; complex planning/design with explicit trade-offs; research/synthesis across many sources
        
        - Highlights: 200K context window; up to 64K output tokens; state-of-the-art coding and computer-use benchmarks (e.g., strong SWE‑bench Verified and OSWorld results); advanced tool coordination and context management
    
    - Extended thinking modes
        - Off (default): near‑instant responses; concise, direct style; ideal for interactive editing, reviews, quick fixes, short-form planning
        - On (extended thinking): step‑by‑step visible reasoning; better accuracy on long‑horizon, multi‑step coding, and complex research/analysis; higher latency and token usage; streamed thinking can arrive in “chunky” bursts; budget control recommended
    
    - **Excellent for**:
        
        | Use case | Why |
        |----------|-----|
        | Agentic coding & refactors | Strong planning + edit accuracy; coordinates parallel tool calls; maintains coherence across large, long-running tasks |
        | Computer use & browser automation | Leads on computer-use tasks; reliable multi-step flows (procurement, onboarding, competitive analysis) with high tool success |
        | Architecture & system design | Concise, trade-off aware proposals; keeps state across sessions; extended thinking improves depth and justification |
        | Security & incident response | Strong at proactive fixes, runbooks, and vulnerability remediation when paired with tools; benefits from extended thinking for RCA |
        | Research & synthesis | Pulls from multiple sources, summarizes with clear rationale; visible thinking improves traceability and review |
        | Financial analysis & reporting | Handles complex analysis pipelines and long-form outputs; extended thinking improves correctness and auditability |
    
    - **Good for**:
        
        | Use case | Why |
        |----------|-----|
        | Platform/DevEx & CI/CD | Generates policy/IaC/CI steps with strong instruction following; extended thinking helps plan safe rollouts |
        | Data engineering/ML | Orchestrates ETL, validations, and experiments; long context helps with config/log/code cross-referencing |
        | Database optimization | Solid at schema/query tuning with explanation; pair with EXPLAIN/ANALYZE and traces for verification |
        | Performance optimization | Identifies common anti-patterns (N+1, blocking I/O); extended thinking helps with multi-hop bottleneck analysis |
        | Distributed systems | Explains consistency/partitioning trade‑offs; coordinates changes across services with tool use |
    
    - **Moderate for**:
        
        | Use case | Why |
        |----------|-----|
        | Low-level C++/Rust performance edge cases | Strong guidance, but hardware/OS nuances require profiling; verify with benches/fuzzing |
        | Pixel-perfect UI/animation | Needs designer review for fidelity; excels when paired with design system constraints |
        | Strict real-time/HFT constraints | Proposes sound patterns, but kernel/NUMA/GC tuning must be validated on target hardware |
    
    - **Less ideal for**:
        
        | Use case | Why |
        |----------|-----|
        | Zero-latency responses with no visible reasoning | Extended thinking increases latency; default mode is better for speed but may trade depth |
        | Compliance contexts disallowing any reasoning traces | Thinking summaries are visible when extended thinking is enabled; disable when prohibited |
        | Pure creative/narrative long-form | Competent; however other models may be preferred for highly stylized narrative work |
    
    - **Key limitations**:
        - Extended thinking increases latency and token use; use budgets and enable only when depth is needed
        - Streaming of extended thinking can be “chunky” with intermittent delays between events
        - Concise communication style may skip verbose summaries after tool calls unless prompted
        - Hardware/OS‑level performance claims still require profiling and tests on target systems
    - **Strategic use**: Default to Sonnet 4.5 for agentic coding and computer use; keep extended thinking off for interactive edits and on for long-horizon work, incident RCAs, end‑to‑end refactors, and multi‑service planning
- Opus 4.1
    
    - **Top-tier for**: Maximum depth reasoning, high‑stakes reviews, formal write‑ups, and contentious design/security decisions where precision and justification matter more than speed/cost
        
        - Highlights: frontier‑level analytical quality and argumentation; excels at long‑form synthesis and rigorous trade‑off analysis; best used sparingly due to stricter weekly limits and higher latency/cost
    
    - **Excellent for**:
        
        | Use case | Why |
        |----------|-----|
        | Architecture RFCs & design reviews | Produces deeply reasoned proposals with explicit trade‑offs and risks; strong at clarifying decision records |
        | Threat models & risk assessments | Systematic enumeration of attack surfaces/mitigations with clear assumptions and constraints |
        | Complex algorithm analysis | Step‑by‑step derivations, proofs/explanations, and correctness arguments for tricky logic |
        | Migration/modernization decision papers | Carefully weighs phased approaches, rollback strategies, and stakeholder impact |
        | Long‑form documentation | High‑quality narratives, executive summaries, and policy/standards documents |
    
    - **Good for**:
        
        | Use case | Why |
        |----------|-----|
        | Hard bug triage & RCAs | Careful reasoning reduces misdiagnosis; strong at structuring evidence and hypotheses |
        | Data governance & DB evolution plans | Nuanced discussion of consistency, retention, partitioning, and compliance trade‑offs |
        | Cross‑org comms | Clear, persuasive writing tailored to leadership/stakeholders; reduces back‑and‑forth |
        | Research synthesis | Integrates many sources into coherent conclusions with well‑argued rationale |
        | Policy‑as‑code design | Captures intent and constraints before encoding as rules and tests |
    
    - **Moderate for**:
        
        | Use case | Why |
        |----------|-----|
        | Interactive coding loops | Higher latency can slow edit‑run‑fix cycles; prefer Haiku/Sonnet for tight feedback |
        | Multi‑tool agentic coding | Capable but strict weekly limits hinder long runs; Sonnet better for extended workflows |
        | Frontend polish & animation | Strong writing, but UI fidelity benefits from Sonnet + design system constraints |
        | Real‑time/perf tuning | Good reasoning, but OS/hardware nuances require on‑target profiling and faster iteration |
    
    - **Less ideal for**:
        
        | Use case | Why |
        |----------|-----|
        | High‑volume automation | Stricter weekly quotas and cost make large batch jobs impractical |
        | Zero‑latency UX | Latency profile unsuitable for rapid interactions; use Haiku |
        | Massive mechanical refactors | Prefer GPT‑5‑Codex or Sonnet for speed, tool orchestration, and consistency |
        | Browser/computer use at scale | Tool success is strong but quotas limit large‑scale runs; Sonnet/Haiku preferred |
    
    - **Key limitations**:
        - Strict, low weekly limits in many environments; reserve for highest‑impact tasks
        - Higher latency and cost per token; not suited for frequent interactive loops
        - Can over‑elaborate; prompt for concise outputs and explicit constraints
        - As with all models, validate code/infra changes via tests, policy checks, and reviews
    - **Strategic use**: Use Opus 4.1 as the “final say” model—finalize RFCs, threat models, decision records, and executive narratives. Prototype/explore with Haiku/Sonnet (or GPT‑5‑Codex for mass edits), then escalate to Opus for polished, defensible write‑ups and sign‑offs

## Condensed decision guides

### By model

- GPT-5

    - Documented here with Low/Medium/High thinking modes; this guide contains no further model-specific strengths/weaknesses beyond listing the modes.

- GPT-5-Codex

    - Positioning: specialized for agentic coding with strong multi-file editing, refactors, and CLI/tool orchestration; defaults to safe, sandboxed execution with traceability.
    
    - Thinking effort guide
        
        | Effort | Best for | Trade-offs |
        | :----- | :------- | :--------- |
        | minimal | deterministic edits (formatting, extraction, small regex fixes, snapshot updates) | weakest at synthesis or multi-hop reasoning |
        | low | single-file features, docstrings, small tests | faster but may miss cross-cutting constraints |
        | medium (default) | cross-file changes, API glue, query edits | best baseline for most roles |
        | high | complex migrations, concurrency design, recovery flows | higher latency/cost; can “overthink” without concrete artifacts/tests |
    
    - Best-fit categories (see full table above for details): architecture/design, large migrations/refactors, API/integration, data/ML pipelines, frontend/design systems, platform/devops/infra, observability/incident, reliability/scalability, security/privacy, testing/verification, performance optimization, real-time systems, databases/SQL, systems languages.

- Gemini 2.5 Pro

    - Top-tier for: math/science reasoning, long-context codebase analysis (1M), agentic coding, code editing, web development.
    
    - Excellent for
        
        | Use case | Why |
        |----------|-----|
        | Architecture/System Design | Best-in-class long context for entire service analysis; simultaneous consideration of performance, security, maintainability |
        | Data Engineering/ML | Superior math reasoning for pipeline optimization, feature engineering, model evaluation; 1M context for analyzing large datasets/logs |
        | Database Optimization | Strong at query plan analysis, schema design with mathematical rigor; long context handles entire slow query logs |
        | Performance Optimization | Mathematical approach to complexity analysis; can analyze entire service for bottlenecks |
        | Migration/Refactoring | 1M context enables analyzing entire legacy systems at once; strong multi-file reasoning |
        | Research/Documentation | Factuality and multimodal strengths; generates hierarchical docs aligned with standards |
    
    - Good for
        
        | Use case | Why |
        |----------|-----|
        | DevOps/Infrastructure | IaC generation, config optimization; verify security hardening |
        | Testing | Test generation, coverage analysis; strong for property-based strategies |
        | API Integration | Code generation for clients/servers; OpenAPI/GraphQL schema design |
        | Distributed Systems | Consensus/consistency reasoning; cross-service analysis with long context |
    
    - Moderate for
        
        | Use case | Why |
        |----------|-----|
        | Frontend/UX | Competent React/TS; multimodal helps design analysis but not specialized |
        | Security Auditing | Prone to false positives; use GPT-5/Claude for critical security |
        | Tech Debt Analysis | Can modify unrelated segments; needs careful prompting |
    
    - Less ideal for
        
        | Use case | Why |
        |----------|-----|
        | Creative/Narrative Docs | Claude Sonnet superior for engaging docs and storytelling |
        | Language Specialists (C++/Rust/Go) | Competent but GPT-5-Codex or Claude Sonnet show better idioms |
        | Prompt Engineering | Not meta-optimized vs GPT-5 or Claude |
    
    - Key limitations: may modify unrelated files in complex changes; security test weaknesses reported; occasional multi-file integration issues.
    - Cost advantage: extremely generous free tier; use liberally for research, prototyping, large-scale analysis.
    - Strategic use: first choice for 100k+ token context, math-heavy work, multi-service analysis, budget-constrained projects.

- Haiku 4.5

    - Top-tier for: fast, cost‑efficient agentic workflows; interactive editing and short‑horizon tasks at scale; high‑volume applications with low latency needs.
    
    - Extended thinking
        - Off: maximum responsiveness for edit‑run‑fix and incremental changes.
        - On: deeper multi‑step reasoning for tasks exceeding one prompt; higher latency/tokens—use budgets.
    
    - Excellent for
        
        | Use case | Why |
        |----------|-----|
        | Real‑time applications/UI loops | Very fast responses keep dev feedback tight; precise edits |
        | High‑volume automation | Favorable pricing for batch edits, hygiene, docs at scale |
        | Sub‑agent architectures | Lightweight, responsive subagents with tool use and context awareness |
        | Computer use at scale | Reliable automation for repeatable flows with strong tool success |
        | Code editing & lint‑fix passes | Low‑latency edits; great for CI “fix‑up” steps |
    
    - Good for
        
        | Use case | Why |
        |----------|-----|
        | CRUD APIs and integration glue | Quick endpoints/clients/tests; extended thinking helps versioning plans |
        | Data/ETL scaffolding | Orchestrates pipelines/validations; fast schema/config iteration |
        | Documentation & onboarding | Concise, professional docs at low cost/latency |
        | Observability basics | Quick dashboards/runbooks; verify with traces/logs |
        | Security hygiene | Secret scanning/policy templates; use rules + review |
    
    - Moderate for
        
        | Use case | Why |
        |----------|-----|
        | Long‑horizon multi‑service refactors | Can plan incrementally; Sonnet often better for deep trade‑offs |
        | Heavy research/synthesis | Extended thinking helps, but Sonnet stronger for complex synthesis |
        | Advanced performance investigations | Finds anti‑patterns; deep OS/algorithm tuning prefers Sonnet/GPT‑5 |
    
    - Less ideal for
        
        | Use case | Why |
        |----------|-----|
        | Deep architectural redesigns | Sonnet provides more thorough trade‑off exploration and longer outputs |
        | Strict real‑time/low‑level tuning | Hardware/kernel nuances need on‑target profiling |
        | Highly stylized long‑form narrative | Other models may better match tone/fidelity |
    
    - Key limitations: shallower default depth than Sonnet on long‑horizon tasks; extended thinking adds latency/tokens; always verify multi‑file/infra changes via tests and policy.
    - Strategic use: default for speed/cost‑sensitive agentic coding, CI fix‑ups, batch hygiene, and scalable computer use; enable extended thinking for multi‑step tasks; escalate to Sonnet for deep design/RCA/large refactors.

- Sonnet 4.5

    - Top-tier for: agentic coding and multi-step computer use; long-running agents coordinating multiple tools; complex planning/design; research/synthesis across many sources.
    
    - Extended thinking
        - Off: near‑instant responses; concise, direct; ideal for interactive edits, reviews, quick fixes, short‑form planning.
        - On: visible step‑by‑step reasoning; better accuracy on long‑horizon coding and complex research/analysis; higher latency/tokens; streaming can be “chunky.”
    
    - Excellent for
        
        | Use case | Why |
        |----------|-----|
        | Agentic coding & refactors | Strong planning + edit accuracy; parallel tool calls; coherence across long tasks |
        | Computer use & browser automation | Leads on computer-use tasks; reliable multi-step flows with high tool success |
        | Architecture & system design | Trade-off aware proposals; state across sessions; extended thinking improves depth |
        | Security & incident response | Proactive fixes/runbooks when paired with tools; extended thinking helps RCA |
        | Research & synthesis | Multi-source synthesis with clear rationale; thinking summaries aid review |
        | Financial analysis & reporting | Complex analysis pipelines and long-form outputs; extended thinking boosts correctness |
    
    - Good for
        
        | Use case | Why |
        |----------|-----|
        | Platform/DevEx & CI/CD | Policy/IaC/CI steps with strong instruction following; safer rollout plans |
        | Data engineering/ML | ETL, validations, experiments; long context helps cross-referencing |
        | Database optimization | Schema/query tuning with explanations; verify with EXPLAIN/ANALYZE and traces |
        | Performance optimization | Finds anti-patterns; extended thinking aids multi-hop bottleneck analysis |
        | Distributed systems | Consistency/partitioning trade‑offs; coordinates changes across services |
    
    - Moderate for
        
        | Use case | Why |
        |----------|-----|
        | Low-level C++/Rust perf edge cases | Hardware/OS nuances require profiling; verify with benches/fuzzing |
        | Pixel-perfect UI/animation | Needs designer review; shines with design system constraints |
        | Strict real-time/HFT constraints | Patterns are sound, but kernel/NUMA/GC tuning must be validated |
    
    - Less ideal for
        
        | Use case | Why |
        |----------|-----|
        | Zero-latency with no reasoning | Extended thinking adds latency; default mode is faster but may trade depth |
        | Compliance blocking any reasoning traces | Disable extended thinking when thinking summaries are prohibited |
        | Pure creative/narrative long-form | Competent; other models may be preferred for highly stylized work |
    
    - Key limitations: extended thinking increases latency/tokens; streaming can be “chunky”; concise style may skip verbose summaries unless prompted; OS/hardware performance claims require profiling.
    - Strategic use: default choice for agentic coding and computer use; keep extended off for interactive edits and on for long-horizon work, RCAs, end‑to‑end refactors, multi‑service planning.

- Opus 4.1

    - Top-tier for: maximum depth reasoning, high‑stakes reviews, formal write‑ups, and contentious design/security decisions where precision and justification matter more than speed/cost.
    
    - Excellent for
        
        | Use case | Why |
        |----------|-----|
        | Architecture RFCs & design reviews | Deeply reasoned proposals with explicit trade‑offs and risks; clear decision records |
        | Threat models & risk assessments | Systematic enumeration of attack surfaces/mitigations with assumptions/constraints |
        | Complex algorithm analysis | Step‑by‑step derivations and correctness arguments for tricky logic |
        | Migration/modernization decision papers | Weighs phased approaches, rollback strategies, and stakeholder impact |
        | Long‑form documentation | High‑quality narratives, executive summaries, and policy/standards docs |
    
    - Good for
        
        | Use case | Why |
        |----------|-----|
        | Hard bug triage & RCAs | Careful reasoning reduces misdiagnosis; structures evidence and hypotheses |
        | Data governance & DB evolution plans | Nuanced discussion of consistency, retention, partitioning, compliance |
        | Cross‑org comms | Clear, persuasive writing for leadership/stakeholders |
        | Research synthesis | Integrates many sources into coherent, argued conclusions |
        | Policy‑as‑code design | Captures intent/constraints before encoding as rules/tests |
    
    - Moderate for
        
        | Use case | Why |
        |----------|-----|
        | Interactive coding loops | Latency slows edit‑run‑fix; prefer Haiku/Sonnet for tight feedback |
        | Multi‑tool agentic coding | Capable but strict weekly limits hinder long runs; Sonnet better |
        | Frontend polish & animation | Better with Sonnet + design system constraints |
        | Real‑time/perf tuning | Good reasoning; OS/hardware nuances need on‑target profiling |
    
    - Less ideal for
        
        | Use case | Why |
        |----------|-----|
        | High‑volume automation | Quotas/cost make large batch jobs impractical |
        | Zero‑latency UX | Latency profile unsuitable; use Haiku |
        | Massive mechanical refactors | Prefer GPT‑5‑Codex or Sonnet for speed/tooling |
        | Browser/computer use at scale | Tool success is strong but quotas limit large‑scale runs |
    
    - Key limitations: strict weekly limits; higher latency/cost; can over‑elaborate—prompt for concise outputs; always validate code/infra changes via tests/policy/review.
    - Strategic use: the “final say” model—finalize RFCs, threat models, decision records, executive narratives; explore with Haiku/Sonnet or GPT‑5‑Codex, then escalate to Opus for polished, defensible sign‑offs.

### By task category

- Architecture & system design

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | Sonnet 4.5 | Trade‑off aware proposals; multi‑tool planning; extended thinking for deep justification | Strong agentic coordination; keeps state across sessions; enable extended thinking for long‑horizon design |
    | Gemini 2.5 Pro | Entire‑service analysis with very long context | 1M context fits large repos; excellent math/analysis for holistic constraints |
    | GPT‑5‑Codex | Code‑adjacent design that includes refactors and interface updates | Reliable cross‑file edits; pairs design with concrete code changes |
    | Opus 4.1 | Formal RFCs and decision records | Highest depth; use for final, defensible write‑ups |
    | Haiku 4.5 | Fast, incremental design tweaks | Great for interactive iterations; escalate for deep trade‑offs |
    | GPT‑5 | Use higher thinking effort for complex design evaluations | Choose high effort for deeper reasoning; medium for typical reviews |

- Large migrations & refactors

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | GPT‑5‑Codex | Repo‑wide, mechanical changes and pattern lifts | Mass‑rename/interface swaps with tests; medium/high effort as needed |
    | Sonnet 4.5 | End‑to‑end refactors with tool orchestration | Extended thinking improves planning/rollback design |
    | Gemini 2.5 Pro | Understanding legacy systems wholesale before changes | 1M context surfaces global coupling and risks |
    | Haiku 4.5 | High‑volume, incremental “fix‑up” passes | Cheap, fast edits in CI; enable extended thinking sparingly |
    | Opus 4.1 | Decision memos for approach/rollback | Use for decision papers; not for mechanical execution |
    | GPT‑5 | Use high effort for tricky dependency untangling | Pair with tests and CI gates |

- API integration (clients/servers, gateways, versioning)

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | GPT‑5‑Codex | Contract‑first design + glue code + contract tests | Strong idempotency/retry patterns; good for gateways/versioning |
    | Gemini 2.5 Pro | Schema design and multi‑service API mapping | Long context to reason across services |
    | Haiku 4.5 | CRUD endpoints, client scaffolds, quick iterations | Fast turnarounds; extended thinking for version plans |
    | Sonnet 4.5 | Gateway/policy design with tool orchestration | Good for safe E2E rollouts |
    | Opus 4.1 | Policy/standards documentation | Finalize guidance and comms |
    | GPT‑5 | Higher effort for complex compatibility matrices | Keep prompts concrete |

- Data engineering / ML pipelines

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | Gemini 2.5 Pro | Pipeline math, feature engineering, long‑context log/SQL analysis | Excellent analytical reasoning; 1M context for end‑to‑end view |
    | Sonnet 4.5 | ETL orchestration with tools; validations/experiments | Extended thinking for multi‑step jobs |
    | Haiku 4.5 | Scaffolding and rapid iteration on configs/schemas | Cost‑effective for volume changes |
    | GPT‑5‑Codex | SQL tuning and code‑level ETL edits | Use medium/high effort for complex windows/joins |
    | Opus 4.1 | Data governance decision papers | Formalize retention/partitioning/compliance trade‑offs |
    | GPT‑5 | High effort for tricky statistical/constraint reasoning | Pair with real data checks |

- Database optimization

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | Gemini 2.5 Pro | Whole‑system query/trace analysis with long context | Strong schema/plan reasoning at scale |
    | Sonnet 4.5 | Schema/query tuning with explanations | Verify via EXPLAIN/ANALYZE and traces |
    | GPT‑5‑Codex | Query/index refactors and connection pool guidance | Good for code‑level fixes and consistency talk‑throughs |
    | Haiku 4.5 | Quick index/constraint edits, doc updates | Fast CI fix‑ups |
    | Opus 4.1 | Governance/documentation of DB evolution plans | Deep trade‑off narratives |
    | GPT‑5 | Higher effort for edge‑case planner heuristics | Validate on target workload |

- Performance optimization

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | Gemini 2.5 Pro | Whole‑service bottleneck analysis | Strong mathematical reasoning over long context |
    | GPT‑5‑Codex | Finding N+1s, blocking I/O, complexity issues | Suggests caching/batching/pool tuning; needs profiles |
    | Sonnet 4.5 | Multi‑hop bottleneck analysis with tools | Extended thinking helps plan/validate changes |
    | Haiku 4.5 | Quick anti‑pattern fixes and lint passes | Great for CI “performance hygiene” |
    | Opus 4.1 | Complex algorithm correctness rationale | Use for proofs/explanations, not runtime tuning |
    | GPT‑5 | High effort for algorithmic redesigns | Back with benchmarks and tests |

- Frontend / design systems

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | GPT‑5‑Codex | Component refactors, tokens, a11y, storybook/tests | Strong for multi‑file library updates |
    | Haiku 4.5 | Style/UX nits, lint‑fix, rapid tweaks | Fast feedback; great for CI |
    | Sonnet 4.5 | Library‑level changes with coordination | Design‑system aware when well‑prompted |
    | Gemini 2.5 Pro | Design analysis via multimodal context | Competent React/TS; not specialized |
    | Opus 4.1 | Executive docs and design rationales | Long‑form narratives |
    | GPT‑5 | Use higher effort for complex state logic | Keep examples concrete |

- Platform / DevEx / Infra (IaC, CI/CD, policies)

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | Haiku 4.5 | CI “fix‑up” steps, batch hygiene, quick IaC edits | Cost‑efficient at scale |
    | Sonnet 4.5 | Coordinated rollouts, policy wiring, multi‑tool tasks | Extended thinking for safe plans |
    | Gemini 2.5 Pro | System‑wide config reasoning | Long context across repos/services |
    | GPT‑5‑Codex | Concrete CI steps and IaC code refactors | Good cross‑file consistency |
    | Opus 4.1 | Standards/policy documents | Finalize guidance |
    | GPT‑5 | High effort for complex pipeline logic | Pair with tests |

- Observability / incident response

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | Sonnet 4.5 | Runbooks, SLO/error budgets, incident timelines | Extended thinking improves RCAs |
    | GPT‑5‑Codex | Dashboards/runbooks linked to concrete code/config | Good at codifying playbooks |
    | Haiku 4.5 | Quick dashboards/runbooks | Verify against logs/traces |
    | Gemini 2.5 Pro | Cross‑service incident analysis with long context | Useful for broad log/trace correlation |
    | Opus 4.1 | Post‑incident deep‑dive documents | Executive/board‑ready RCAs |
    | GPT‑5 | High effort for critical incident retrospectives | Demand evidence and citations |

- Reliability / scalability

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | GPT‑5‑Codex | Backpressure, retries/jitter, circuit breaking patterns | Validate with load tests |
    | Sonnet 4.5 | Capacity plans with multi‑tool coordination | Extended thinking for failure‑mode analysis |
    | Gemini 2.5 Pro | Distributed systems/consensus reasoning | Long context for cross‑service analysis |
    | Haiku 4.5 | Quick policy/config hygiene | Good for incremental improvements |
    | Opus 4.1 | Formal capacity/risk memos | Deep trade‑off articulation |
    | GPT‑5 | High effort for resilience trade‑offs | Capture assumptions explicitly |

- Security / privacy

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | Sonnet 4.5 | Proactive fixes/runbooks with tool use | Extended thinking for complex RCAs and mitigations |
    | GPT‑5‑Codex | Secret scanning, vuln patterns, policy‑as‑code | Pair with Semgrep and human review |
    | Gemini 2.5 Pro | Threat modeling (caution: FP risk) | Use for ideation; confirm with stricter models/tools |
    | Haiku 4.5 | Security hygiene at scale | Templates/policies with review |
    | Opus 4.1 | Threat models/risk assessments for sign‑off | Highest rigor; quota/latency constraints |
    | GPT‑5 | Noted in file as strong for critical security auditing vs Gemini | Use higher effort as needed |

- Testing / verification

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | GPT‑5‑Codex | Unit/property/mutation tests; CI flake triage | Minimal/low effort for snapshots; medium/high for integration |
    | Gemini 2.5 Pro | Test generation and coverage analysis | Strong property‑based strategies |
    | Sonnet 4.5 | Coordinated integration testing with tools | Extended thinking for complex matrices |
    | Haiku 4.5 | Snapshot/test fix‑ups in CI | Fast, cost‑effective |
    | Opus 4.1 | Test strategy rationales and QA plans | Use for formal documentation |
    | GPT‑5 | High effort for tricky invariant reasoning | Pair with hermetic harnesses |

- Real‑time systems

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | GPT‑5‑Codex | Latency budgets, jitter control, scheduling/backpressure proposals | Validate on target hardware; enforce budgets in tests |
    | Sonnet 4.5 | Deterministic failover and multi‑step plan validation | Extended thinking for staged rollouts |
    | Gemini 2.5 Pro | Cross‑service streaming/consistency analysis | Long context useful for topology reasoning |
    | Haiku 4.5 | Rapid edits to buffers/queues/configs | Escalate for deep OS/hardware tuning |
    | Opus 4.1 | Risk/decision records for RT systems | Formalize constraints and trade‑offs |
    | GPT‑5 | High effort for scheduling/algorithm trade‑offs | Always bench/profile |

- Systems languages (C++/Rust/Go)

    | Model | When to prefer | Notes |
    | :---- | :------------- | :---- |
    | GPT‑5‑Codex | Scaffolds, concurrency primitives, FFI patterns, safety idioms | Use compile/test/fuzz loops rigorously |
    | Sonnet 4.5 | Coordination across modules/services | Design‑system and tool orchestration strengths |
    | Haiku 4.5 | Quick iterations on smaller changes | Great for CI pipelines |
    | Gemini 2.5 Pro | Reasoning across large codebases | Not specialized for language idioms |
    | Opus 4.1 | Formal docs and reviews | Deep narratives and trade‑offs |
    | GPT‑5 | High effort for subtle concurrency/unsafe edges | Verify thoroughly |

- Cost / latency trade‑offs

    - GPT‑5‑Codex: minimal/low keep costs/latency down for everyday edits; high for deep planning only when needed.
    - Haiku 4.5: default choice for speed/cost‑sensitive loops and batch hygiene.
    - Sonnet 4.5: enable extended thinking only when depth is required; otherwise keep interactive loops fast.
    - Gemini 2.5 Pro: leverage for long‑context analysis when it replaces multiple shorter runs.
    - Opus 4.1: reserve for highest‑impact documents/decisions due to quotas and latency.
    - GPT‑5: scale thinking effort (low/medium/high) to match task complexity and latency budgets.
