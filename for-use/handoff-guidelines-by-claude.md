# Handoff Guidelines for Agents

> **Purpose**: Guide for agents on when to delegate work vs. when to ask the user for guidance. This document covers cross-model orchestration, subagent spawning, user approval requirements, and delegation decision matrices.

## Table of Contents

1. [Core Delegation Strategies](#core-delegation-strategies)
2. [When to Use Clink (Cross-Model Orchestration)](#when-to-use-clink-cross-model-orchestration)
3. [When to Use Task Tool (Claude Code Subagents)](#when-to-use-task-tool-claude-code-subagents)
4. [When to Ask the User (AskUserQuestion)](#when-to-ask-the-user-askuserquestion)
5. [Model Selection Guide for Clink Roles](#model-selection-guide-for-clink-roles)
6. [Handoff Patterns](#handoff-patterns)
7. [What Requires Explicit Approval](#what-requires-explicit-approval)
8. [Decision Matrix](#decision-matrix)

---

## Core Delegation Strategies

### Three Delegation Mechanisms

1. **`clink` (Zen MCP)**: Cross-model orchestration - delegate to different AI models (GPT-5, Gemini, Claude models)
2. **`Task` tool**: Spawn specialized Claude Code subagents within the same environment
3. **`AskUserQuestion`**: Stop and get explicit user guidance

### General Principles

- **Delegate when**: The task requires specialized capabilities beyond your current scope, or a different model has clear advantages
- **Ask user when**: Requirements are ambiguous, multiple valid approaches exist, or explicit approval is needed
- **Handle directly when**: Task is within your capabilities and requirements are clear

---

## When to Use Clink (Cross-Model Orchestration)

### Use `clink` to delegate to other AI models when:

#### 1. **Context Window Constraints**
- **Current task requires > 200K tokens of context** (e.g., analyzing entire large services/repos)
- **Delegate to**: `gemini` (1M context window)
- **Example**: "Analyze the entire legacy authentication service to understand all dependencies before refactoring"

#### 2. **Cost/Speed Optimization**
- **High-volume batch operations** where cost efficiency matters
- **Delegate to**: `gemini` (free tier, practically unlimited) for research/prototyping
- **Example**: "Generate 50 test cases for different API endpoints"

#### 3. **Specialized Reasoning Requirements**

**Math/Science Heavy Tasks**:
- Complex mathematical analysis, algorithm optimization with formal proofs
- **Delegate to**: `codex` with GPT-5-Codex + High thinking (94.6% AIME 2025)
- **Budget alternative**: `gemini` with `optimization` role (88% AIME, free tier)
- **Example**: "Analyze the time complexity of this sorting algorithm and prove optimality"

**Large-Scale Refactoring**:
- Repo-wide mechanical changes, mass-renames, pattern lifts across 10+ files
- **Delegate to**: `codex` with GPT-5-Codex (91% multi-file refactoring success)
- **Example**: "Rename all instances of `OldAuthService` to `AuthenticationService` across the entire codebase with tests"

**Maximum Depth Reasoning**:
- High-stakes architecture RFCs, formal threat models, contentious design decisions
- **Delegate to**: `claude` with Opus 4.1 role
- **Example**: "Write a comprehensive threat model for our new payment processing system"

#### 4. **Speed Requirements**
- **Interactive editing loops** needing sub-second responses
- **Delegate to**: `claude` with Haiku 4.5 role
- **Example**: "Apply these 20 linting fixes across the codebase quickly"

#### 5. **Model-Specific Strengths**

Refer to [Model Selection Guide](#model-selection-guide-for-clink-roles) for detailed mappings.

### How to Use Clink

```
Always provide:
- `cli_name`: "claude", "codex", or "gemini"
- `prompt`: Clear task description with context
- `role`: Appropriate role preset (see model selection guide and available roles below)
  Note: Roles are defined in /clink-role-prompts/ directory (e.g., "architect", "migration-refactoring", "api-integration")
- `continuation_id`: ALWAYS reuse from previous calls to maintain conversation context
- `files`: Absolute paths to relevant files (optional but helpful)
```

---

## When to Use Task Tool (Claude Code Subagents)

### Use `Task` tool to spawn Claude Code subagents when:

#### 1. **Codebase Exploration**
- **Scenario**: Need to understand codebase structure, find patterns, or locate implementations
- **Subagent**: `Explore` agent
- **Thoroughness levels**:
  - `"quick"`: Basic pattern matching, fast lookups
  - `"medium"`: Moderate exploration across multiple files
  - `"very thorough"`: Comprehensive analysis across entire codebase
- **Example**: "Find all authentication-related files in the codebase" → Use Explore agent with "medium" thoroughness

#### 2. **Multi-Step Research Tasks**
- **Scenario**: Open-ended questions requiring multiple rounds of searching and analysis
- **Subagent**: `general-purpose` agent
- **Example**: "Research how the payment processing flow works across services" → Use general-purpose agent

#### 3. **Parallel Processing**
- **Scenario**: Multiple independent tasks that can run concurrently
- **Action**: Launch multiple Task tools in a single message
- **Example**: Searching for multiple unrelated code patterns simultaneously

#### 4. **Token Conservation**
- **Scenario**: Task requires extensive file searching that would consume your context
- **Subagent**: Any appropriate specialized agent
- **Example**: Searching for a keyword across 100+ files → Use Explore agent instead of Grep directly

### When NOT to Use Task Tool

- **Single file reads**: Use `Read` tool directly
- **Specific known file paths**: Use `Read` or `Glob` directly
- **Specific class/function definitions**: Use `Glob` directly
- **Known 2-3 files**: Use `Read` tool directly instead of spawning an agent

---

## When to Ask the User (AskUserQuestion)

### Always Use AskUserQuestion When:

#### 1. **Ambiguous Requirements**
- Multiple valid implementation approaches exist
- User intent is unclear from the prompt
- **Example**: "Should we use REST or GraphQL for this new API?" (when not specified)

#### 2. **High-Impact Decisions**
- Architectural choices that affect the entire system
- Technology stack selections
- Breaking changes to public APIs
- **Example**: "This refactoring will break backward compatibility. Should we proceed or implement a deprecation path?"

#### 3. **Missing Critical Information**
- Required configuration values not provided
- Environment-specific details needed
- **Example**: "Which database should this service connect to - staging or production?"

#### 4. **Trade-Off Decisions**
- Performance vs. maintainability
- Cost vs. features
- Speed vs. quality
- **Example**: "We can optimize this query for speed but it will make the code more complex. Which do you prefer?"

#### 5. **Security/Compliance Sensitive**
- Credential management approaches
- Data retention policies
- Access control decisions
- **Example**: "How long should we retain user session logs?"

#### 6. **Before Destructive Operations** (see also: [Explicit Approval Requirements](#what-requires-explicit-approval))
- Deletions, force pushes, production deployments
- **Example**: "This will delete 15 unused files. Proceed?"

### AskUserQuestion Best Practices

- **Provide 2-4 clear options** with descriptions
- **Include trade-offs** for each option
- **Use descriptive headers** (max 12 chars)
- **Set `multiSelect: true`** when choices aren't mutually exclusive
- **Always include context** about why you're asking

---

## Model Selection Guide for Clink Roles

### Quick Reference: First Picks by Task Category

| Task Category | First Pick | CLI | Role | Why |
|---------------|-----------|-----|------|-----|
| Architecture & system design | Sonnet 4.5 | `claude` | `architect` | Trade-off aware; multi-tool planning; extended thinking for deep justification |
| Large migrations & refactors | GPT-5-Codex | `codex` | `migration-refactoring` | 91% multi-file refactoring success; repo-wide mechanical changes |
| API integration | GPT-5-Codex | `codex` | `api-integration` | Contract-first design; idempotency/retry patterns |
| Data engineering / ML | Gemini 2.5 Pro | `gemini` | `ai-ml-eng` | **Only if needs 1M context** for large datasets/logs; else use codex with High thinking |
| Database optimization | Gemini 2.5 Pro | `gemini` | `db-internals` | **Only if analyzing entire slow query logs** (1M context); else use codex |
| Performance optimization | GPT-5-Codex | `codex` | `optimization` | Finds N+1s, blocking I/O, complexity issues; use High thinking for algorithmic redesign |
| Frontend / design systems | GPT-5-Codex | `codex` | `frontend` | Component refactors; a11y; Storybook updates |
| Platform / DevEx / Infra | Haiku 4.5 | `claude` | `platform-eng` | CI fix-ups; batch hygiene; cost-efficient at scale |
| Observability / incident | Sonnet 4.5 | `claude` | `observability` | Runbooks; SLO/error budgets; extended thinking for RCAs |
| Reliability / scalability | Sonnet 4.5 | `claude` | `scalability-reliability` | Capacity plans; multi-tool coordination |
| Security / privacy | Sonnet 4.5 | `claude` | `security-compliance` | Proactive fixes; extended thinking for threat modeling |
| Testing / verification | GPT-5-Codex | `codex` | `testing` | Unit/property/mutation tests; CI flake triage |
| Real-time systems | GPT-5-Codex | `codex` | `realtime` | Latency budgets; jitter control; scheduling proposals |
| Systems languages: C++ | GPT-5-Codex | `codex` | `cpp-pro` | Concurrency primitives; FFI patterns; safety idioms |
| Systems languages: Rust | GPT-5-Codex | `codex` | `rust-pro` | Memory safety; ownership patterns; unsafe blocks |
| Systems languages: Go | GPT-5-Codex | `codex` | `golang-pro` | Goroutines; channels; idiomatic Go patterns |
| Code explanation / understanding | Any with good context | Any | `explainer` | Use appropriate model based on codebase size/complexity |
| Architecture audits | Sonnet 4.5 | `claude` | `architecture-audit` | Deep analysis of existing architecture; identify issues |
| High-stakes RFCs / threat models | Opus 4.1 | `claude` | `architect` | Maximum depth reasoning; formal write-ups |
| Tech debt analysis | Sonnet 4.5 | `claude` | `tech-debt` | Identify and prioritize technical debt systematically |
| Cost optimization | Sonnet 4.5 | `claude` | `cost-optimization-finops` | Cloud costs; resource optimization; FinOps strategies |
| Distributed systems design | Sonnet 4.5 | `claude` | `distributed-systems` | Consensus; consistency; partition tolerance |
| Networking / edge infrastructure | GPT-5-Codex | `codex` | `networking-edge-infra` | CDN; load balancing; edge compute patterns |
| Mobile engineering | GPT-5-Codex | `codex` | `mobile-eng-architect` | iOS/Android architecture; mobile-specific patterns |
| DevOps / IaC focus | GPT-5-Codex | `codex` | `devops-infra-as-code` | Terraform; Kubernetes; IaC best practices |
| Implementation helper | Any | Any | `implementation-helper` | General coding assistance; when no specific specialty needed |
| Long-context whole-repo analysis (>400K tokens) | Gemini 2.5 Pro | `gemini` | `explainer` | **1M context is undisputed advantage** for entire repos/services that exceed GPT-5's 400K limit |

### Model-Specific Guidance

#### Use `codex` (GPT-5-Codex) for:
- **Multi-file refactoring** (91% success rate)
- **Mechanical changes** at scale (mass-renames, interface swaps)
- **API contract design** with client/server stubs
- **Testing** (unit, property, mutation tests)
- **Code reviews** requiring precision
- **Frontend component libraries**
- **Cross-file dependency management**

**Available roles**:
- `api-integration` - API design, client/server stubs, contract-first development
- `cpp-pro` - C++ expertise, concurrency, FFI patterns
- `devops-infra-as-code` - Terraform, Kubernetes, IaC best practices
- `frontend` - React, component libraries, accessibility, design systems
- `golang-pro` - Go idioms, goroutines, channels
- `implementation-helper` - General coding assistance
- `migration-refactoring` - Large-scale refactoring, pattern lifts
- `mobile-eng-architect` - iOS/Android architecture
- `networking-edge-infra` - CDN, load balancing, edge compute
- `realtime` - Real-time systems, latency budgets, scheduling
- `rust-pro` - Rust memory safety, ownership, unsafe blocks
- `testing` - Unit, integration, property-based testing

**Thinking effort in prompts** (when using codex):
- Mention "minimal effort" for formatting, small regex fixes
- Mention "low effort" for single-file features
- Default (medium) for cross-file changes
- Mention "high effort" for complex migrations, concurrency design

#### Use `gemini` (Gemini 2.5 Pro) for:
- **Primary use case: Long context analysis** (>400K tokens - entire repos/services - 1M tokens)
  - This is Gemini's **undisputed advantage** over GPT-5 (400K) and Claude (200K)
  - Analyzing entire slow query logs, large datasets, multi-service analysis
  - Whole codebase understanding when size exceeds 400K tokens
- **Budget-constrained projects** (free tier with practically unlimited usage)
  - Good choice when cost matters and 88% AIME vs 94.6% is acceptable trade-off

**Important**: For most tasks where context fits in 400K tokens, **prefer GPT-5-Codex with High thinking** for better accuracy (94.6% vs 88% AIME). Only choose Gemini when:
1. Context genuinely exceeds 400K tokens, OR
2. Budget is a primary constraint and free tier needed

**Available roles**:
- `ai-ml-eng` - ML pipelines (use only when analyzing massive datasets requiring 1M context)
- `db-internals` - Database optimization (use only when entire slow query logs exceed 400K)
- `explainer` - Code explanation for massive codebases (>400K tokens)
- `implementation-helper` - General coding assistance (budget-constrained scenarios)
- `optimization` - Performance analysis (use only for whole-service analysis >400K tokens)

**Note**: Watch for unrelated file modifications; be precise with instructions

#### Use `claude` with Haiku 4.5 for:
- **High-volume batch operations** (CI fix-ups, lint passes)
- **Interactive editing loops** (fast feedback cycles)
- **Cost-sensitive automation**
- **Quick code hygiene tasks**
- **Real-time UI/application loops**

**Available roles**:
- `implementation-helper` - Quick coding tasks, CI fix-ups
- `platform-eng` - Platform/DevEx work, batch hygiene
- Any role when speed/cost is priority (but with reduced depth vs Sonnet)

#### Use `claude` with Sonnet 4.5 for:
- **Agentic coding** (multi-step tool coordination)
- **Architecture design** (trade-off aware proposals)
- **Security incident response** (proactive fixes, runbooks)
- **Research synthesis** (multi-source analysis)
- **Computer use / browser automation**
- **Complex planning** requiring extended thinking

**Available roles**:
- `architect` - Architecture design, system design, trade-off analysis
- `architecture-audit` - Auditing existing architectures, finding issues
- `cost-optimization-finops` - Cloud cost analysis, FinOps strategies
- `distributed-systems` - Consensus, consistency, CAP theorem trade-offs
- `explainer` - Code explanation with strong reasoning
- `implementation-helper` - General agentic coding assistance
- `observability` - Monitoring, alerting, SLOs, incident response
- `scalability-reliability` - Scaling strategies, reliability patterns
- `security-compliance` - Security audits, threat modeling, compliance
- `tech-debt` - Technical debt analysis and prioritization

**When to mention "extended thinking"** in prompt:
- Long-horizon refactors
- Incident RCAs
- Multi-service planning
- Complex research

#### Use `claude` with Opus 4.1 for:
- **Architecture RFCs** (maximum depth reasoning)
- **Threat models** (systematic attack surface analysis)
- **Migration decision papers** (phased approach, rollback strategies)
- **Long-form documentation** (executive summaries, policy docs)
- **"Final say" reviews** before sign-off

**Available roles**:
- `architect` - Deep architecture RFCs, formal design documents
- `architecture-audit` - Comprehensive architecture reviews
- `security-compliance` - Formal threat models, security audits
- `tech-debt` - Strategic technical debt analysis
- Use any role when maximum depth/rigor is required (but note strict weekly limits)

**Note**: Strict weekly limits - use sparingly for highest-impact work

### Cost/Speed Optimization Strategy

1. **Prototype/explore** with Haiku 4.5 (fast) or Gemini only if budget-constrained (free tier)
2. **Implement** with GPT-5-Codex (default choice - superior accuracy, 91% refactoring success, 94.6% AIME)
3. **Complex agentic/coordination** with Sonnet 4.5 (multi-tool orchestration, extended thinking)
4. **Finalize/review** with Opus 4.1 only if high-stakes (maximum rigor, strict limits)

**Default model preference**: GPT-5-Codex (High thinking) > Sonnet 4.5 > Gemini (only for >400K context or budget constraints)

---

## Handoff Patterns

### Sequential Handoff Pattern: Research → Planning → Implementation

#### 1. Research Phase
**Objective**: Understand requirements, existing code, constraints

**When you're in this phase**:
- User asks exploratory questions ("How does X work?", "Where is Y implemented?")
- Need to gather context before making changes
- Analyzing existing architecture

**Actions**:
- Use `Task` tool with `Explore` agent for codebase exploration
- Use `Read` tool for specific file analysis
- Use `clink` to `gemini` if requires long-context whole-repo analysis

**Handoff signal**:
- Once you understand the landscape → Ask user if they want you to create a plan
- Or if user asks "now implement/fix this" → Move to planning phase

#### 2. Planning Phase
**Objective**: Design approach, break down tasks, identify risks

**When you're in this phase**:
- User asks "how should we implement X?"
- After research, ready to propose approach
- Need to design architecture/refactoring strategy

**Actions**:
- Create plan outline with steps
- Identify trade-offs and risks
- Use `clink` to `claude` with `planner` role for complex architecture design
- Use `clink` to `codex` with `planner` role for refactoring strategy
- Use `AskUserQuestion` to resolve ambiguities or get preference on trade-offs

**Handoff signal**:
- Present plan to user
- Use `ExitPlanMode` if in plan mode
- Get approval before moving to implementation
- Or ask "Should I proceed with implementation?"

#### 3. Implementation Phase
**Objective**: Execute the plan, write/modify code

**When you're in this phase**:
- User gives approval to implement
- User says "go ahead", "implement it", "make these changes"
- Plan is approved and clear

**Actions**:
- Use `TodoWrite` to track implementation tasks
- For large refactors: Use `clink` to `codex` (best multi-file refactoring)
- For agentic coordination: Stay in Claude (Sonnet 4.5) with tool orchestration
- For speed-critical batches: Use `clink` to `claude` with Haiku 4.5
- Execute changes systematically
- Mark todos as in_progress/completed as you go

**Handoff signal**:
- After implementation → Offer to create tests
- Or ask "Should I commit these changes?"
- Or move to review phase

#### 4. Review/Verification Phase (Optional)
**Objective**: Verify changes, run tests, create commits

**When you're in this phase**:
- Implementation complete
- Need to verify correctness
- User asks for testing/review

**Actions**:
- Use `clink` to any model with `codereviewer` role for formal review
- Run tests with `Bash` tool
- Use `AskUserQuestion` before commits (see approval requirements)

---

## What Requires Explicit Approval

### Always Ask Before:

#### 1. **Version Control Operations**
- Creating commits (unless user explicitly said "commit this")
- Pushing to remote repositories
- Merging branches
- Rebasing (especially interactive rebase)
- Force pushes (`git push --force`)
- Amending commits (unless adding pre-commit hook changes)
- **Exception**: User explicitly says "commit this" or "push these changes"

#### 2. **Destructive Operations**
- Deleting files (show list and ask first)
- Deleting directories
- Truncating databases
- Dropping tables/collections
- Purging caches
- Removing dependencies
- **Exception**: User explicitly says "delete X" or removal is part of explicit refactoring task

#### 3. **Production/Deployment Operations**
- Deploying to production
- Modifying production configurations
- Restarting production services
- Changing environment variables in prod
- Database migrations in production
- **Exception**: Never assume - always ask even if user says "deploy"

#### 4. **Security/Access Changes**
- Modifying authentication logic
- Changing authorization rules
- Granting permissions
- Exposing endpoints publicly
- Disabling security features
- Committing credentials (warn and block)

#### 5. **Breaking Changes**
- Removing public APIs
- Changing API signatures without backward compatibility
- Modifying database schemas without migration path
- Changing configuration formats
- **Exception**: User explicitly approves breaking changes

#### 6. **Cost-Impacting Changes**
- Adding cloud resources
- Increasing instance sizes
- Changing storage tiers
- Modifying rate limits
- Adding paid third-party services

### Approval Pattern

```
When operation requires approval:
1. Clearly state what will happen
2. List affected resources/files
3. Explain potential risks/impacts
4. Use AskUserQuestion with clear options
5. Wait for explicit approval
6. Proceed only after approval
```

---

## Decision Matrix

### "If X, then Y" Decision Rules

#### Context Analysis
```
IF context needed > 400K tokens (exceeds GPT-5's limit)
THEN delegate to gemini via clink with appropriate role (e.g., explainer for whole-repo analysis)
     Reason: Gemini's 1M context is undisputed advantage

IF context between 200K-400K tokens
THEN delegate to codex with GPT-5-Codex (400K context limit)

IF context < 200K AND within Claude capabilities
THEN handle directly or use Task tool

IF need whole-repo analysis AND repo size < 400K tokens
THEN prefer codex over gemini (better accuracy)
```

#### Task Complexity
```
IF open-ended codebase exploration
THEN use Task tool with Explore agent

IF simple file read with known path
THEN use Read tool directly

IF need to understand "how does X work"
THEN use Task tool with Explore agent (medium thoroughness)

IF need to find "where is X implemented"
THEN use Glob tool if specific pattern, else Task tool with Explore agent
```

#### Refactoring Scale
```
IF mechanical refactor across 10+ files
THEN delegate to codex via clink with migration-refactoring role

IF refactor within 2-5 files
THEN handle directly with Edit tool

IF mass rename across entire repo
THEN delegate to codex with migration-refactoring role + "high effort" in prompt

IF API refactoring/integration changes
THEN delegate to codex with api-integration role
```

#### Speed Requirements
```
IF need sub-second responses for batch edits
THEN delegate to claude with Haiku 4.5 + implementation-helper role via clink

IF interactive editing loop
THEN handle directly (already Sonnet 4.5)

IF long-running agentic workflow
THEN handle directly (Sonnet 4.5 best for this)

IF platform/CI work needing speed
THEN delegate to claude with Haiku 4.5 + platform-eng role via clink
```

#### Reasoning Depth
```
IF math-heavy algorithm analysis
THEN delegate to codex with GPT-5-Codex + High thinking (94.6% AIME)
     Budget alternative: gemini with optimization role (88% AIME, free)

IF complex algorithm optimization with formal proofs
THEN delegate to codex with GPT-5-Codex + High thinking

IF architecture RFC needing maximum depth
THEN delegate to claude with Opus 4.1 + architect role via clink

IF threat model for sign-off
THEN delegate to claude with Opus 4.1 + security-compliance role via clink

IF standard architecture design
THEN handle directly (Sonnet 4.5) or delegate to claude with architect role

IF architecture audit/review
THEN delegate to claude with Sonnet 4.5 + architecture-audit role

IF distributed systems design
THEN delegate to claude with distributed-systems role
```

#### User Interaction
```
IF requirements ambiguous
THEN use AskUserQuestion

IF multiple valid approaches exist
THEN use AskUserQuestion to clarify preference

IF destructive operation required
THEN use AskUserQuestion for approval

IF security/access change needed
THEN use AskUserQuestion for approval

IF user says "commit this" explicitly
THEN proceed with commit (no approval needed)
```

#### Cost Optimization
```
IF budget-constrained project
THEN prefer gemini with appropriate role (free tier)

IF high-volume batch operations
THEN delegate to claude with Haiku 4.5 + implementation-helper role (cost-efficient)

IF quota concerns with paid models
THEN delegate to gemini via clink with appropriate role

IF cloud cost analysis needed
THEN delegate to claude with cost-optimization-finops role
```

#### Testing
```
IF need comprehensive test generation
THEN delegate to codex with testing role via clink

IF simple test fixes/updates
THEN handle directly

IF property-based testing strategy needed
THEN delegate to codex with testing role + High thinking (better math reasoning: 94.6% vs 88%)

IF unit/integration test scaffolding
THEN delegate to codex with testing role

IF mutation testing/test coverage analysis
THEN delegate to codex with testing role
```

#### Security
```
IF security audit needed
THEN delegate to claude with Sonnet 4.5 + security-compliance role

IF threat model for formal review
THEN delegate to claude with Opus 4.1 + security-compliance role

IF quick security hygiene (secret scanning)
THEN delegate to codex with security-compliance role or claude with Haiku 4.5 + implementation-helper

IF compliance analysis needed
THEN delegate to claude with security-compliance role
```

#### Frontend/UI
```
IF component library refactor
THEN delegate to codex with frontend role via clink

IF quick styling tweaks
THEN delegate to claude with Haiku 4.5 + implementation-helper role

IF design system coordination
THEN handle directly (Sonnet 4.5) with extended thinking or delegate to codex with frontend role

IF mobile UI/architecture work
THEN delegate to codex with mobile-eng-architect role
```

#### Database/Data
```
IF analyzing entire slow query logs AND logs exceed 400K tokens
THEN delegate to gemini with db-internals role via clink (1M context advantage)

IF analyzing slow query logs AND logs fit within 400K tokens
THEN delegate to codex with db-internals role (better analysis accuracy)

IF schema design with math rigor
THEN delegate to codex with GPT-5-Codex + High thinking (superior math: 94.6% vs 88%)

IF SQL refactoring and code changes
THEN delegate to codex with db-internals role via clink

IF data engineering/ML pipelines with massive datasets (>400K tokens)
THEN delegate to gemini with ai-ml-eng role (1M context needed)
     ELSE delegate to codex with High thinking (better accuracy)

IF performance optimization analysis for entire service (>400K tokens)
THEN delegate to gemini with optimization role (1M context advantage)
     ELSE delegate to codex + High thinking (better optimization analysis)
```

#### DevOps/Platform/Infrastructure
```
IF Terraform/Kubernetes/IaC work
THEN delegate to codex with devops-infra-as-code role

IF platform engineering/CI-CD
THEN delegate to claude with Haiku 4.5 + platform-eng role (for speed)
     OR claude with Sonnet 4.5 + platform-eng role (for complex coordination)

IF networking/CDN/edge infrastructure
THEN delegate to codex with networking-edge-infra role
```

#### Observability/Reliability
```
IF observability/monitoring setup
THEN delegate to claude with observability role

IF incident response/RCA
THEN delegate to claude with Sonnet 4.5 + observability role (extended thinking for RCAs)

IF scalability/reliability design
THEN delegate to claude with scalability-reliability role

IF real-time systems work
THEN delegate to codex with realtime role
```

#### Systems Languages
```
IF C++ work (concurrency, FFI, safety)
THEN delegate to codex with cpp-pro role

IF Rust work (memory safety, ownership)
THEN delegate to codex with rust-pro role

IF Go work (goroutines, channels, idioms)
THEN delegate to codex with golang-pro role
```

#### Technical Debt/Code Quality
```
IF tech debt analysis/prioritization
THEN delegate to claude with tech-debt role

IF code explanation/understanding
THEN delegate to gemini with explainer role (for long context)
     OR claude with explainer role (for deep reasoning)

IF general implementation help
THEN delegate with implementation-helper role to appropriate CLI
```

---

## Practical Examples

### Example 1: User asks "Refactor the authentication system to use JWT"

**Analysis**:
- Large refactor (likely 10+ files)
- Involves security changes
- Requires planning

**Decision Path**:
1. Use `Task` tool with `Explore` agent to understand current auth implementation
2. Use `AskUserQuestion` to clarify requirements (token expiration, refresh tokens, storage?)
3. Create plan and present to user
4. Get approval for breaking changes
5. Delegate implementation to `codex` via `clink` with `migration-refactoring` role (best for multi-file refactoring)
6. After completion, ask before committing

### Example 2: User asks "Find all places where we handle errors"

**Analysis**:
- Codebase exploration
- Open-ended search
- Token-intensive if done directly

**Decision Path**:
1. Use `Task` tool with `Explore` agent, "medium" thoroughness
2. Let Explore agent handle the multi-round searching
3. Summarize findings back to user

### Example 3: User asks "Optimize the slow database queries in the analytics service"

**Analysis**:
- Likely needs long context (entire service, query logs)
- Math-heavy analysis
- Database-specific

**Decision Path**:
1. **Check context size first**:
   - If slow query logs + service code > 400K tokens → delegate to `gemini` with `db-internals` role (1M context advantage)
   - If < 400K tokens → delegate to `codex` with `db-internals` role + High thinking (better accuracy: 94.6% vs 88%)
2. Include all slow query logs and relevant service files
3. Get optimization recommendations
4. Use `AskUserQuestion` to confirm approach before implementing
5. Implement changes (delegate to codex with `db-internals` role for SQL refactoring)

### Example 4: User asks "Write a threat model for our payment API"

**Analysis**:
- Security-sensitive
- Requires maximum depth reasoning
- High-stakes document

**Decision Path**:
1. Gather context about payment API (use `Read` tool or `Task` tool with Explore)
2. Delegate to `claude` with Opus 4.1 + `security-compliance` role via `clink`
3. Review and present to user
4. This is for sign-off, so Opus 4.1's depth is justified

### Example 5: User asks "Fix these 50 linting errors across the codebase"

**Analysis**:
- High-volume batch operation
- Mechanical changes
- Speed and cost matter

**Decision Path**:
1. Delegate to `claude` with Haiku 4.5 + `implementation-helper` role via `clink`
2. Provide file list and linting error details
3. Let Haiku handle quickly and cheaply
4. Ask before committing

---

## Key Takeaways

1. **Default to delegation when**:
   - Task exceeds your context window
   - Another model has clear advantages (cost, speed, specialization)
   - Multi-file refactoring at scale (codex)
   - Long-context analysis >400K tokens (gemini's undisputed advantage)

   **Important**: Prefer GPT-5-Codex with High thinking for most tasks. Only use Gemini when:
   - Context genuinely exceeds 400K tokens (its 1M context is undisputed advantage), OR
   - Budget is primary constraint and free tier needed

2. **Always ask user when**:
   - Requirements unclear
   - Multiple valid approaches
   - Destructive operations
   - Security/compliance decisions
   - Before commits/deployments

3. **Use Task tool when**:
   - Codebase exploration
   - Multi-round research
   - Token conservation needed

4. **Remember**:
   - Always reuse `continuation_id` in clink for context preservation
   - Provide absolute file paths when using clink
   - Use appropriate specialized roles (see available roles for each CLI: `architect`, `migration-refactoring`, `api-integration`, `security-compliance`, etc.)
   - Mark todos throughout implementation
   - Be explicit about thinking effort (minimal/low/medium/high) when relevant

5. **Cost/Speed Strategy**:
   - Prototype → Haiku 4.5 (fast) or Gemini only if budget-constrained
   - Implement → GPT-5-Codex with appropriate thinking level (default choice for coding)
   - Complex/Agentic → Sonnet 4.5 (multi-tool coordination)
   - Finalize → Opus 4.1 (high-stakes only)

   **Model selection priority**: GPT-5-Codex (High thinking) > Sonnet 4.5 > Gemini (only for >400K context or budget constraints)
