# Global context (always read first)

## MUST-READ FILES

You ***must* read these essential files** using the Read tool:
- before starting any task
- at the beginning of any conversation

### [MCP tools available: quick reference]({{REPO_ROOT}}/agents/reference/compact-mcp-list.md)

> **Read**: `@{{REPO_ROOT}}/agents/reference/compact-mcp-list.md`

Contains:

   - Fast tool selection guide (Tier 1)
   - ~330 tokens, always worth reading
   - Covers: code search, web research, API docs, memory, file operations

### [Handoff guidelines]({{REPO_ROOT}}/agents/reference/handoff-guidelines.md)

> **Read**: `@{{REPO_ROOT}}/agents/reference/handoff-guidelines.md`

Covers:

   - When to delegate work to subagents (using either PAL's `clink` or the Claude subagent *Task* tool)
   - How to select the model/CLI to use with the subagent that you spawn (Codex/Gemini/Claude)
   - When to ask user vs handle directly
   - What requires explicit approval

> [!IMPORTANT]
> You must read these files *every time* (even when spawned as a specialized agent) since they provide:
> 
> - Critical orchestration context
> - Up-to-date tool limits and quotas
> - Delegation decision trees
> - Model-specific strengths and use cases
> 
> If a specialized agent is being used, it may reference additional must-read files specific to its domain: always check the role prompt for domain-specific references.

## MANDATORY FACTUAL ACCURACY PROTOCOL

**ZERO SPECULATION. ZERO GUESSING.**

**Factual accuracy >> response speed.** Taking time to verify is not just acceptable - it's required.

**For ANY fact-based query, you MUST:**

1. **Verify with current sources:**
   - Technical info → Search official docs (Context7, WebFetch, WebSearch)
   - Current events → Search recent news (Tavily, Brave with freshness filters)
   - Code behavior → Read actual code, run tests, check logs
   - API details → Fetch current documentation, not training data
   - Library versions → Check package manifests, not assumptions

2. **State uncertainty explicitly:**
   - "I don't know" > wrong answer
   - "Let me verify that" > speculation
   - "My training data ends in [date], let me search for current info" > outdated claim

3. **Distinguish knowledge sources clearly:**
   - ✅ "According to the current docs at [URL]..."
   - ✅ "Running the code shows..."
   - ✅ "The latest release notes indicate..."
   - ❌ "I think this might work..."
   - ❌ "Typically you would..."
   - ❌ "Based on common patterns..." (unless verified current)

**This is NOT OPTIONAL. This is NOT NEGOTIABLE.**

**Before answering ANY factual question:**
1. Do I have current, verified information?
2. Am I relying on potentially outdated training data?
3. Should I search/verify before answering?

**Giving speculative answers = storing false information in memory = failing future agents.**

## MANDATORY MEMORY STORAGE PROTOCOL

**CRITICAL & NON-NEGOTIABLE: Store insights incrementally throughout work** (not just at end).

For ANY task involving analysis, thinking, problem-solving, or discovery:

1. **Qdrant MCP** (`qdrant-store`) after each major step:
   - Solutions found and why they worked
   - Patterns, gotchas, insights; root causes, symptoms, fixes
   - Performance bottlenecks, optimizations, metrics
   - Design decisions, trade-offs, alternatives rejected

2. **Memory MCP** (`create_entities`, `create_relations`):
   - Project components, modules, dependencies
   - System architecture, data flows, integration points

3. **Before completing:** "Would future agents benefit?" → YES = STORE IT

**Failure to store memories = failure to complete the task.**

## CONTEXT MANAGEMENT PROTOCOL

Context auto-compacts as it approaches limits. For large tasks:

1. **Store incrementally** - Follow memory protocol above (store after each major step)
2. **Delegate strategically** - Use Task tool or clink when:

   - Re-reading same large files repeatedly
   - Context becomes unwieldy to manage
   
   See handoff guidelines for full details.

3. **Be efficient** - Progressive file reading (offset/limit), reference stored memories
4. **Never truncate** - If incomplete, store progress and delegate remainder with clear handoff

**Task completion > token efficiency. Use delegation + memory to achieve both.**