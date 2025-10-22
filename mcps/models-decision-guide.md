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
- GPT-5-Codex (Low, Medium and High Thinking modes)
    
    - Positioning: specialized for agentic coding with strong multi-file editing, refactors, and CLI/tool orchestration; defaults to safe, sandboxed execution with good traceability.
    - Thinking effort guide
        - minimal: quickest for deterministic edits (formatting, extraction, small regex fixes, snapshot updates); weakest at synthesis or multi-hop reasoning.
        - low: good for single-file features, docstrings, small tests; balances speed with light planning; may miss cross-cutting constraints.
        - medium (default): reliable for cross-file changes, API glue, query edits; best baseline for most subagent roles.
        - high: use for complex migrations, concurrency design, recovery flows; higher latency/cost; occasionally “overthinks” or invents issues—keep it grounded with concrete artifacts and tests.
    - Architecture/design analysis (architect, design-analysis)
        - Strengths: decomposes modules, proposes interfaces, flags coupling; produces migration plans with checkpoints.
        - Weaknesses: can overspec; prefers ideal patterns over constraints; mitigate with budget/SLAs and repo reality (Sourcegraph context).
        - Effort: medium for review/suggestions; high for ground-up re-architecture with trade-off tables.
    - Large migrations/refactors (migrations/refactors, tech-debt)
        - Strengths: mass-rename, interface swaps, pattern lifting; consistent code updates with tests.
        - Weaknesses: drift on edge cases; brittle mocks; mitigate via incremental branches and verification passes.
        - Effort: medium for scoped refactors; high for repo-wide changes with safety nets.
    - API/integration (api-integration, backend-architect)
        - Strengths: contract-first design, client/server stubs, contract tests, idempotency/retry patterns.
        - Weaknesses: occasional overconfident stubs, hard-coded config; enforce policy files and secrets hygiene.
        - Effort: low/medium for glue code; high for gateways, versioning, and E2E rollouts.
    - Data/ML pipelines (ai-ml, data-engineer, sql-pro)
        - Strengths: ETL wiring, SQL tuning, dataset/schema validation, job orchestration templates.
        - Weaknesses: library/version brittleness; memory/backpressure misestimates; validate with profiling and EXPLAIN plans.
        - Effort: medium; high when optimizing joins/windows or streaming semantics.
    - Frontend/design systems (frontend-ux, design-systems)
        - Strengths: component refactors, tokens, accessibility nits, storybook/test updates.
        - Weaknesses: CSS specificity/layout edge-cases; visual fidelity requires review.
        - Effort: minimal/low for style tweaks; medium for component library changes.
    - Platform/DevOps/Infra (devops-infra, platform-engineering, terraform)
        - Strengths: IaC scaffolds (Terraform/K8s), CI steps, policy wiring, progressive delivery.
        - Weaknesses: over-permissive defaults, noisy alerts; pin images, apply OPA/Conftest.
        - Effort: medium; high for multi-region or DR topologies.
    - Observability/incident (observability-incident, docs-agent)
        - Strengths: golden-signal dashboards, SLO/error budgets, runbooks, incident timelines.
        - Weaknesses: speculative RCA without data; require logs/traces and citations.
        - Effort: low/medium for dashboards/runbooks; high to synthesize RCA across services.
    - Reliability/scalability (reliability, distributed-systems)
        - Strengths: backpressure, retries/jitter, circuit breaking, graceful degradation.
        - Weaknesses: tuning knobs (queues/pools) easy to mis-size; validate with load tests.
        - Effort: medium for patterns; high for capacity plans and failure-mode analysis.
    - Security/privacy (security-privacy)
        - Strengths: secret scanning, common vuln patterns, policy-as-code, secure defaults checklists.
        - Weaknesses: naïve fixes, false positives; pair with Semgrep rules and human review.
        - Effort: low/medium for linting/fixes; high for threat models.
    - Testing/verification (testing-and-verif, task-decomp)
        - Strengths: unit/property tests, mutation tests, CI flake triage, reproducible seeds.
        - Weaknesses: brittle mocks/fixtures; enforce hermetic helpers and contract tests.
        - Effort: minimal/low for snapshots and simple units; medium/high for integration matrices.
    - Performance optimization (optimization, perf-optimizer)
        - Strengths: finds N+1s, blocking I/O, bad complexity; suggests caching, batching, pool tuning.
        - Weaknesses: micro-optimization bias without profiles; require traces/benchmarks.
        - Effort: medium; high for algorithmic or architecture-level improvements.
    - Real-time systems (real-time-systems)
        - Strengths: latency budgets, jitter control, scheduling/backpressure proposals, serialization/transport tuning.
        - Weaknesses: OS/hardware nuances (NUMA/GC/interrupts) need bench validation; avoid speculative tuning.
        - Effort: high for design; medium for scoped code changes with budgets enforced in tests.
    - Databases/SQL (database-specialist, sql-pro)
        - Strengths: query/index refactors, migration plans, connection pool guidance, consistency talk-throughs.
        - Weaknesses: corner-case indexing and planner heuristics; always verify with EXPLAIN/ANALYZE.
        - Effort: medium; high for heavy migrations and partitioning.
    - Systems languages (cpp-pro, rust-pro, golang-pro)
        - Strengths: scaffolds, concurrency primitives, FFI patterns, safety idioms.
        - Weaknesses: UB/unsafe edges require rigorous compile/test/fuzz loops.
        - Effort: medium/high depending on safety and concurrency complexity.
    - Cost/latency trade-offs
        - minimal/low keep costs and latency down for everyday edits.
        - high increases tokens and latency—reserve for problems that truly need deep planning and justification.
    
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
  - **Strategic use**: First choice for: (1) tasks needing 100k+ token context (2) math-heavy work (3) multi-service/entire-repo analysis (4) budget-constrained projects
- Haiku 4.5
- Sonnet 4.5
- Opus 4.1
