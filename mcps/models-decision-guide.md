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
        | | . | high increases tokens and latency—reserve for problems that truly need deep planning and justification. |  |
    
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
- Sonnet 4.5
- Opus 4.1
