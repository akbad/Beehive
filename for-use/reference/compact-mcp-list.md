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

- For **semantic discovery**: use Exa (semantic; $10 one‑time credit) ([deep dive](mcp-deep-dives/exa.md))
- For **simple URL fetches**: use Fetch (unlimited) ([deep dive](mcp-deep-dives/fetch.md))
- For **deep crawling (last resort)**: use Firecrawl (500 lifetime; prefer Tavily/Fetch first) ([deep dive](mcp-deep-dives/firecrawl.md))

> Link: [full category guide - *web research*](mcps-by-category/web-research.md)

## API docs

- For **official documentation**: use Context7 (versioned; public repos only) ([deep dive](mcp-deep-dives/context7.md))

> Link: [full category guide - *API docs*](mcps-by-category/documentation.md) 

## Memory ⭐

> **CRITICAL DIRECTIVE:** Use/update the following MCPs as much as possible:
> 
> - Search these as often as possible for clues left by previous agents when working on problems.
> - Update these regularly and scrupulously so that you and other agents can optimally and efficiently benefit from yours and each others' past experiences.

> For ***Claude Code only***: use `claude‑mem` (works mostly automatically) ([deep dive](mcp-deep-dives/claude-mem.md)). 
> 
> Claude should still *regularly and scrupulously keep the memory MCPs below updated* so that the Gemini and Codex CLIs' agents can benefit from its knowledge/discoveries (and vice versa).
 
- For each of Gemini CLI, Codex CLI, and Claude Code:

    - For **semantic memory**: use Qdrant MCP (vector search; no limits) ([deep dive](mcp-deep-dives/qdrant.md))
    - For **structured memory**: use Memory MCP (knowledge graph; no limits) ([deep dive](mcp-deep-dives/memory.md))

> Link: [full category guide - *memory MCPs*](mcps-by-category/memory.md)

## Code analysis and editing

- For **editing and refactors (especially symbol-level)**: use Serena (symbol‑level across 20+ languages) ([deep dive](mcp-deep-dives/serena.md))
- For **security and quality**: use Semgrep (local scans; autofix) ([deep dive](mcp-deep-dives/semgrep.md))

## Files and Git

- For files: use Filesystem MCP *only* for

    - **Batch reading 10+ files** (`read_multiple_files` - 30-60% token savings vs multiple Read calls)
    - **Analyzing project structures / directory trees** (`directory_tree` returns JSON)

- For **Git operations**: use Git MCP — status/diff/branch/commit (run at repo root)

- See: [mcp-deep-dives/filesystem.md](mcp-deep-dives/filesystem.md) · [mcp-deep-dives/git.md](mcp-deep-dives/git.md)

## Limits

| Tool        | Limit                    | Reset/Notes                                    |
|-------------|--------------------------|------------------------------------------------|
| Firecrawl   | 500 lifetime             | 10 scrape/min, 1 crawl/min; permanent credits |
| Exa         | $10 one‑time credit      | New account/API key after exhaustion          |
| Tavily      | 1,000 credits/month      | Resets on 1st of month                        |
| Brave       | 2,000 queries/month      | Free tier; basic web search                    |
| Sourcegraph | Interactive limits       | use count:all to make the search exhaustive, bump timeout if needed; switch to src-cli for very large result sets beyond the UI display limit. |
