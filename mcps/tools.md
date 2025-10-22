# Tools set up by [`scripts/set-up-mcps.sh`](scripts/set-up-mcps.sh) & how to use them

- [**MCP servers**](#mcp-servers)
- [**Non-MCP tools**](#non-mcp-tools)

**Full how-tos for each tool** can be found in `tool-descriptions/`

---

## MCP servers

### MCP servers for browsing/researching/fetching stuff from the internet

A few of these servers have redundant/duplicate roles. This is on purpose so we have fallback choices in case we hit rate limits.

| Server | Functionality | How it's run/talked to by agents | Restrictions |
| :----- | :------------ | :------------ | :----------- |
| **Fetch MCP** | fetch HTTP/HTTPS URLs; turns HTML into Markdown for faster/more accurate processing by LLMs (optional raw HTML); chunk reading via start_index; custom UA/robots handling | Stdio with private client-managed instance | None |
| **Firecrawl MCP** | crawl/scrape/extract/map websites; "better" web search; batching & deep research | **Claude & Codex**: HTTP using Firecrawl's cloud-hosted server; **Gemini**: stdio with local proxy that talks to Firecrawl's cloud server | [Free plan](https://www.firecrawl.dev/pricing) used, limits are 10 `/scrape` calls/min, 1 `/crawl` call/min, each uses 1 credit. **Looks like you need to make a new account/API key after 500 total scrapes/crawls** |
| **Context7 MCP** | pull up-to-date, version-specific API/code docs & examples into prompts | **Claude & Gemini**: HTTP using Context7's cloud-hosted server; **Codex**: stdio with local proxy that talks to Context7's cloud server | Free tier used: **only allows accessing *public* repos** | 
| **Sourcegraph MCP** | Basically **“Google for code”**: lets your agent search across repos (and branches) using powerful filters (regex, language, and file-path), then open the matching files/line ranges to pull the exact code snippets you're looking for. Also includes **guided search prompts**, so the agent can turn a natural request (e.g., “find all places we construct HttpClient with a 5s timeout”) into precise queries and iterate until it finds what you need. | Free tier used: search covers **public repos only**; covering private/org repos requires paid plans | HTTP with locally-run server (that talks to [Sourcegraph Public Code Search](https://sourcegraph.com/search)) |
| **Tavily MCP** | Handles searching, extracting, mapping and crawling the web, with citations | HTTP with Tavily's cloud-hosted server | Free version used: gives 1000 API credits/month (resets on 1st of month); *[click to see amount of credits used for each request type](https://docs.tavily.com/documentation/api-credits#api-credits-costs)* | 
| [**Brave MCP**](https://github.com/brave/brave-search-mcp-server) | Privacy-focused fallback/alternative search engine with generous free tier | stdio with private client-managed instances | Free tier used: 2000 queries/month, limited to basic web search only |
| [**Exa MCP**](https://github.com/exa-labs/exa-mcp-server) | Neural search engine optimized specifically for LLMs and AI agents: has better semantic understanding than traditional keyword search and returns content formatted for AI consumption. Complements Tavily's general-purpose search with its AI-native approach, and comes out superior for research and knowledge discovery | HTTP with Exa's cloud-hosted server | Free plan used with one time credit of $10. **Looks like you need to make a new account/API key once you've used this up** |

> Important: 
> - **The *Fetch* MCP does not support fetching directly from the GitHub website** (e.g. to look up API-/code-related info about public repos) 
> - Instead, tell the agent to use one of these solutions, depending on what you need from GitHub: 
>     - **Best / most straightforward:**
>
>         - Use Fetch MCP to fetch from `https://raw.githubusercontent.com/<path>`, where `<path>` is usually something like `<user/org>/<repo>/<dir>/<file>`
>         - Use `gh` CLI locally
>
>     - **Other solutions:**
>
>         - Use Sourcegraph MCP
>         - Clone repos locally and use Git MCP to go through them
 
### MCP memory servers

| Server | Functionality | How it's run/talked to by agents | Restrictions |
| :----- | :------------ | :------------ | :----------- |
| **Qdrant MCP** | *semantic memory* layer: allows agent to save things it learns/produces (code snippets, notes, links) and later retrieve them by searching *semantically* (i.e. not just by keyword); uses FastEmbed models w/ HNSW index for search | HTTP with locally-running server, backed by *Qdrant DB instance running in a local Docker container* | None |
| **Memory MCP** | *structured memory* layer (knowledge graph): stores entities, relations, and observations to track *relationships* between concepts and maintain context across sessions; complements Qdrant's semantic search with explicit relationship tracking | Stdio with private client-managed instances | None (completely free, local JSONL storage) | 


### Other MCP servers

| Server | Functionality | How it's run/talked to by agents | Restrictions |
| :----- | :------------ | :------------ | :----------- |
| **Zen MCP *(`clink` only)*** | multi-model orchestration; CLI-to-CLI bridge (“clink”); spawn sub-agents; context threading across tools/CLIs | HTTP with locally-run server | None |
| **Filesystem MCP** | read/write/edit files; create/list/delete/move; metadata; secure roots/allowlist & path validation | stdio with private client-managed instances | None |
| **Git MCP** | handles basically all Git operations (git status/diff/log; add/commit/reset; branch/checkout/show; targeted compare) | stdio with private client-managed instances (**parent agent must be run at the root dir of the Git repo**) | None |
| **Semgrep MCP** | lets your agent **(1)** scan source code locally (no code leaves your machine) using AST-aware, pattern-based rules to *catch security issues, bugs, and risky anti-patterns across many languages* **(2)** run targeted scans (a file, dir, or diff) or full-repo checks **(3)** choose rulesets (built-in or custom YAML rules you write in code-like patterns) **(4)** get structured findings back, by file/line, rule ID, severity, message, code snippet **(5)** autofix suggestions when a rule defines a fix | HTTP with locally-running instance of *Semgrep's free "community edition" server* | Free "community edition" used: see *[full list of Semgrep community edition features](https://semgrep.dev/docs/semgrep-pro-vs-oss)* |
| **Serena MCP** | language-server-powered semantic code navigation, refactoring, and editing; provides IDE-grade symbol search (`find_symbol`, `find_referencing_symbols`), structural edits (`insert_after_symbol`, `rename_symbol`, `replace_symbol_body`), project onboarding/memories, and LSP integration across 20+ languages (Python, TypeScript, Go, Rust, Java, etc.); complements Filesystem/Git MCP by working at the semantic level instead of whole-file operations | HTTP with locally-running server (cloned from GitHub repo), downloads language servers as needed | None |

## Non-MCP tools

| Tool | Type | Functionality |
| :--- | :--- | :------------ |
| **[GitHub SpecKit](https://github.github.io/spec-kit/) *(amazing, your agents will never hallucinate or get distracted again)*** | Command-line tool | Enables **Spec-Driven Development** via `specify` CLI, which allows making detailed constitution/spec/plan/tasks for each project; agent-agnostic templates (Copilot/Claude/Gemini) |

> There's a bit of a learning curve for getting to use GitHub SpecKit, but it's definitely worth it
