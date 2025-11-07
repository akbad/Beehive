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

## Memory ⭐

> [!IMPORTANT]
> **MANDATORY MEMORY STORAGE PROTOCOL**
>
> **You MUST store memories after ANY task involving:**
> - Analysis/investigation (code patterns, bugs, performance issues)
> - Thinking/reasoning (design decisions, trade-offs, alternatives considered)
> - Derivation of results (calculations, conclusions, recommendations)
> - Problem-solving (solutions found, approaches that failed, workarounds)
> - Discovery (undocumented behavior, quirks, gotchas, lessons learned)
>
> **This is NOT OPTIONAL. This is NOT NEGOTIABLE.**
>
> **Before completing ANY task, ask yourself:**
> 1. Did I analyze something? → Store in Qdrant
> 2. Did I discover relationships? → Store in Memory MCP
> 3. Would future agents benefit from knowing this? → Store it
>
> **Failure to store memories = failure to complete the task.**

> For ***Claude Code only***: use `claude‑mem` (works mostly automatically) ([deep dive](mcp-deep-dives/claude-mem.md)).
>
> Claude should still *scrupulously keep the memory MCPs below updated* so that Gemini and Codex CLI agents can benefit from its knowledge/discoveries (and vice versa).

- For each of Gemini CLI, Codex CLI, and Claude Code:

    - For **semantic memory**: use Qdrant MCP — `qdrant-store` after every analysis/discovery ([deep dive](mcp-deep-dives/qdrant.md))
    - For **structured memory**: use Memory MCP — track entities/relations for project context ([deep dive](mcp-deep-dives/memory.md))

> **Storage decision tree:**
> - **Qdrant**: Code patterns, solutions, gotchas, insights, "how I solved X"
> - **Memory MCP**: Who/what/how relationships, project structure, dependencies
> - **Both**: Complex problems (store solution in Qdrant, track entities/relations in Memory MCP)
>
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

## Limits

| Tool        | Limit                    | Reset/Notes                                    |
|-------------|--------------------------|------------------------------------------------|
| Tavily      | 1,000 credits/month      | Resets on 1st of month                        |
| Brave       | 2,000 queries/month      | Free tier; basic web search                    |
| Sourcegraph | Interactive limits       | use count:all to make the search exhaustive, bump timeout if needed; switch to src-cli for very large result sets beyond the UI display limit. |
