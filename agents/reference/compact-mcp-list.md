# MCPs: quick decision guide

- Fast, first-choice tool per task with limits.
- Contains links to:

    - Per‑category guides (only look at these if your exact, desired use case is not covered here)
    - Per‑MCP deep dives (only look when you need full guidance on the intricacies of using a particular MCP's toolset)

## Code search

- For going through **public, open‑source code**: use Sourcegraph ([deep dive](mcp-deep-dives/sourcegraph.md)) to find examples/patterns (interactive time/result limits)
- **Within local codebases**:

    - For **semantic navigation/symbol-level refactors**: use Serena MCP ([deep dive](mcp-deep-dives/serena.md))
    - For **simple text searches**: use ripgrep/grep to find plain text/regex matches fast (respects .gitignore)

> Link: [Full category guide - *code search*](mcps-by-category/code-search.md) 

## Web research

- For **general web info**: use Tavily (cited results; 1k/mo) ([deep dive](mcp-deep-dives/tavily.md))

    - Fallback if *Tavily is exhausted*: use Brave (2k/mo) ([deep dive](mcp-deep-dives/brave.md))

- For **simple URL fetches**: use Fetch (unlimited) ([deep dive](mcp-deep-dives/fetch.md))

> Link: [full category guide - *web research*](mcps-by-category/web-research.md)

## API docs

- For **official documentation**: use Context7 (versioned; public repos only) ([deep dive](mcp-deep-dives/context7.md))

> Link: [full category guide - *API docs*](mcps-by-category/documentation.md) 

## Memory

### MANDATORY MEMORY RETRIEVAL PROTOCOL

> [!IMPORTANT]
> **You MUST check memories at the START of EVERY task.**

**Before starting ANY task, you MUST:**

1. **Query all memory systems for relevant context:**
- Memory MCP (`read_graph`, `search_nodes`) - for architectural relationships, component structure
- Qdrant MCP (`qdrant-find`) - for past solutions, patterns, gotchas, learnings
- claude-mem (`get_recent_context`, `search_observations`, `find_by_type`) **(*ONLY* if you are Claude Code)** for recent session history, file changes

2. **Verify memory accuracy BEFORE trusting it:**
- Compare memory timestamps with file modification dates
- If memory references specific files/code → Read those files to verify
- If memory describes system behavior → Test/verify it's still true
- **Older memories are MORE LIKELY to be stale** - verify aggressively

3. **Update or delete incorrect memories immediately:**
- Found stale info? → Overwrite with current truth
- Found obsolete relationships? → Delete and recreate
- Found incorrect patterns? → Store the correction

**This is NOT OPTIONAL. This is NOT NEGOTIABLE.**

**Before starting ANY task, ask yourself:**
1. What memories might exist about this? → Search for them
2. Are these memories still accurate? → Verify against current state
3. Am I building on correct foundations? → Fix stale memories first

**Starting work with stale memories = building on false assumptions = failure.**

### MANDATORY MEMORY STORAGE PROTOCOL

**You MUST store memories after ANY task involving:**
- Analysis/investigation (code patterns, repository structure, bugs, performance issues)
- Thinking/reasoning (design decisions, trade-offs, alternatives considered)
- Derivation of results (calculations, conclusions, recommendations)
- Problem-solving (solutions found, approaches that failed, workarounds)
- Discovery (undocumented behavior, quirks, gotchas, lessons learned)

**This is NOT OPTIONAL. This is NOT NEGOTIABLE.**

**Before finishing ANY task, ask yourself:**
1. Did I analyze something? → Store in Qdrant
2. Did I discover relationships? → Store in Memory MCP
3. Would future agents benefit from knowing this? → Store it

**Failure to store memories = failure to complete the task.**

> [!NOTE]
> **Storage decision tree:**
>  - **Qdrant**: Code patterns, solutions, gotchas, insights, "how I solved X"
>  - **Memory MCP**: Who/what/how relationships, project structure, dependencies
>  - **Both**: Complex problems (store solution in Qdrant, track entities/relations in Memory MCP)

> Link: [full category guide - *memory MCPs*](mcps-by-category/memory.md)

## Code analysis and editing

- For **editing and refactors (especially symbol-level)**: use Serena (symbol‑level across 20+ languages) ([deep dive](mcp-deep-dives/serena.md))
- For **security and quality**: use Semgrep (local scans; autofix) ([deep dive](mcp-deep-dives/semgrep.md))

## Files and Git

> **⚠️ CRITICAL for ALL CLIs:** Default to **native tools** (Read/Write/Edit) for file operations.

- **Read files (1-9)**: use native Read tool — NOT `serena.read_file` (adds overhead)
- **Read files (10+)**: use Filesystem MCP `read_multiple_files` (30-60% token savings)
- **Write/Edit files**: use native Write/Edit — use Serena ONLY for symbol-level operations
- **Directory trees**: use `ls -R` or `find` via Bash (Filesystem MCP now filtered to read_multiple_files only)

> **When to use Serena for files:**
> - Understanding code **symbols** (classes/methods): `find_symbol` with `include_body=true`
> - Replacing **entire symbol**: `replace_symbol_body` (NOT for 1-line edits)
> - Adding **new symbol**: `insert_after_symbol` / `insert_before_symbol`
> - **Renaming symbol** codebase-wide: `rename_symbol`
>
> See [Serena deep dive](mcp-deep-dives/serena.md) for symbol vs text-based editing decision tree.

- For **Git operations**: use `git` via Bash tool — git status/diff/log/add/commit/branch/checkout

## Browser automation

- For **web automation and testing**: use Playwright (click, type, navigate, extract content) ([deep dive](mcp-deep-dives/playwright.md))

> Link: [full category guide - *browser automation*](mcps-by-category/browser-automation.md)

## Limits

All non-listed MCPs are local and/or have no usage limits.

| Tool        | Limit                    | Reset/Notes                                    |
|-------------|--------------------------|------------------------------------------------|
| Tavily      | 1,000 credits/month      | Resets on 1st of month                        |
| Brave       | 2,000 queries/month      | Free tier; basic web search                    |
| Sourcegraph | Interactive limits       | use count:all to make the search exhaustive, bump timeout if needed; switch to src-cli for very large result sets beyond the UI display limit. |
