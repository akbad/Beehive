# Tools set up by [`scripts/set-up-tools.sh`](scripts/set-up-tools.sh)

> This file is meant for both humans and agents to read

- [**MCP servers**](#mcp-servers)
- [**Non-MCP tools**](#non-mcp-tools)

A **full decision guide as to when to use each tool** can be found at [`tools-decision-guide.md`](tools-decision-guide.md).

---

## MCP servers

### MCP servers for browsing/researching/fetching stuff from the internet

A few of these servers have redundant/duplicate roles. This is on purpose so we have fallback choices in case we hit rate limits.

| Server | Functionality | How it's run/talked to by agents | Restrictions |
| :----- | :------------ | :------------ | :----------- |
| **Fetch MCP** | fetch HTTP/HTTPS URLs; turns HTML into Markdown for faster/more accurate processing by LLMs (optional raw HTML); chunk reading via start_index; custom UA/robots handling | Stdio with private client-managed instance | None |
| **Context7 MCP** | pull up-to-date, version-specific API/code docs & examples into prompts | **Claude & Gemini**: HTTP using Context7's cloud-hosted server; **Codex**: stdio with local proxy that talks to Context7's cloud server | Free tier used: **only allows accessing *public* repos** |
| **Sourcegraph MCP** | Basically **"Google for code"**: lets your agent search across repos (and branches) using powerful filters (regex, language, and file-path), then open the matching files/line ranges to pull the exact code snippets you're looking for. Also includes **guided search prompts**, so the agent can turn a natural request (e.g., "find all places we construct HttpClient with a 5s timeout") into precise queries and iterate until it finds what you need. | Free tier used: search covers **public repos only**; covering private/org repos requires paid plans | HTTP with locally-run server (that talks to [Sourcegraph Public Code Search](https://sourcegraph.com/search)) |
| **Tavily MCP** | Handles searching, extracting, mapping and crawling the web, with citations | HTTP with Tavily's cloud-hosted server | Free version used: gives 1000 API credits/month (resets on 1st of month); *[click to see amount of credits used for each request type](https://docs.tavily.com/documentation/api-credits#api-credits-costs)* |
| [**Brave MCP**](https://github.com/brave/brave-search-mcp-server) | Privacy-focused fallback/alternative search engine with generous free tier | stdio with private client-managed instances | Free tier used: 2000 queries/month, limited to basic web search only |
| **WebSearchAPI MCP** | Google-quality search results via websearchapi.ai; extends API search capacity as tertiary fallback | stdio with private client-managed instances | Free tier used: 2000 queries/month |
| [**web-search-mcp**](https://github.com/mrkrsl/web-search-mcp) | Unlimited browser-based web search via Playwright; final fallback when all API quotas exhausted | stdio with private client-managed instances | None (unlimited, but slower than API tools) |
| **crawl4ai MCP** | Quality content extraction with JS rendering and intelligent boilerplate removal; handles dynamic/cluttered pages | stdio via Docker container | None (unlimited, requires Docker) |

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
>         - Clone repos locally and use git via Bash to navigate them

### MCP memory servers

> [!IMPORTANT]
> **MANDATORY USAGE REQUIREMENT**
>
> **ALL agents (Codex, Gemini, Claude Code) MUST store memories after ANY task involving:**
> - Analysis, investigation, thinking, reasoning, derivation
> - Problem-solving, debugging, optimization
> - Discovery of patterns, gotchas, undocumented behavior
> - Architectural decisions, trade-offs, design choices
>
> **This is NOT OPTIONAL. Memory storage = part of completing the task.**

| Server | Functionality | How it's run/talked to by agents | Restrictions |
| :----- | :------------ | :------------ | :----------- |
| **Qdrant MCP** | **[MANDATORY]** *semantic memory* layer: MUST save discoveries, solutions, insights, patterns after EVERY analytical task; retrieves by semantic meaning using FastEmbed HNSW vector search | HTTP with locally-running server, backed by *Qdrant DB instance running in a local Docker container* | None |
| **Memory MCP** | **[MANDATORY]** *structured memory* layer (knowledge graph): MUST track entities/relations when working on projects; stores who/what/how relationships, system architecture, dependencies | Stdio with private client-managed instances | None (completely free, local JSONL storage) | 

#### Claude-only: `claude-mem` context management plugin

**What it is**: A persistent memory compression system that automatically preserves context across Claude Code sessions. Unlike Qdrant/Memory MCPs which require manual saving, claude-mem operates fully automatically through Claude Code's plugin hook system. GitHub repo: [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)

**How it works automatically**:
- **5 Lifecycle Hooks** capture events without manual intervention:
  - `SessionStart`: Injects summaries from last 10 sessions into context with progressive disclosure (token costs visible)
  - `UserPromptSubmit`: Creates session record, saves raw user prompts for search
  - `PostToolUse`: Fires after EVERY tool execution (Read, Write, Edit, Bash, etc.), captures observations
  - `Stop`: Generates session summaries (request, completed, learned, next_steps)
  - `SessionEnd`: Marks sessions complete (graceful cleanup, preserves work across `/clear`)
- **Worker Service** (PM2-managed Express server on port 37777):
  - Processes observations via Claude Agent SDK
  - Extracts structured learnings: decisions, bugfixes, features, refactors, discoveries, changes
  - Auto-starts when first session begins
- **SQLite Database** (`~/.claude-mem/claude-mem.db`):
  - Stores sessions, observations, summaries, and user prompts
  - FTS5 full-text search with SQL injection protection (332 attack tests)
  - Tracks files read/modified, concepts, types, and relationships
- **Progressive Disclosure**: Context appears as layered timeline at session start
  - Layer 1 (Index): See what exists with token costs (🔴 critical, 🟤 decision, 🔵 informational)
  - Layer 2 (Details): Fetch full narratives on-demand via MCP search
  - Layer 3 (Perfect Recall): Access source code and original transcripts

**How agents can use it manually** (7 MCP search tools available in all Claude sessions):
- `search_observations` - Full-text search across observations (title, narrative, facts, concepts)
  - Filter by: type, concepts, files, project, date range
  - **Always start with `format: "index"` (50-100 tokens/result) before using `format: "full"` (500-1000 tokens/result)**
- `search_sessions` - Full-text search across session summaries
- `search_user_prompts` - Search raw user requests (trace intent → implementation)
- `find_by_concept` - Find observations tagged with specific concepts (e.g., "architecture", "security")
- `find_by_file` - Find all work related to specific files (e.g., "worker-service.ts")
- `find_by_type` - Find by observation type (decision, bugfix, feature, refactor, discovery, change)
- `get_recent_context` - Get recent session context for debugging/recovery
- **Citations**: All results use `claude-mem://` URIs for referencing historical context

**How Codex and Gemini CLIs can replicate this with Qdrant + Memory MCPs**:

Since Codex/Gemini lack Claude Code's hook system, they must manually implement similar patterns:

- **MANDATORY OBSERVATION LOGGING** (supplements automatic hooks):
  - **After investigating code**: MUST save discoveries to Qdrant (patterns, gotchas, insights) + Memory MCP (component relationships)
  - **After making decisions**: MUST create entities in Memory MCP with relations (e.g., "JWT" -[chosen_for]→ "authentication" -[because]→ "stateless design")
  - **After fixing bugs**: MUST store in Qdrant: root cause, symptoms, fix approach, prevention tips, with metadata (file, type, concepts)
  - **After solving problems**: MUST store solution + why it worked in Qdrant
  - **After optimizing**: MUST store bottleneck found, optimization applied, metrics in Qdrant
  - **After analyzing architecture**: MUST create entities/relations in Memory MCP for system structure
  - Use Qdrant for semantic retrieval ("find work related to authentication") and Memory MCP for relationship traversal
  - **Not storing = incomplete task**

- **Session summaries** (replaces Stop hook):
  - Before ending work, manually create summary and store in Qdrant
  - Include: request, completed, learned, next_steps (same structure as claude-mem)
  - Tag with project name and date for filtering

- **Context recovery** (replaces SessionStart hook):
  - Start sessions by searching Qdrant for relevant past work (semantic search by project/topic)
  - Fetch related entities from Memory MCP knowledge graph
  - Build context progressively as needed (similar to progressive disclosure)

- **File tracking** (replaces automatic file_read/file_modified tracking):
  - Manually create Memory MCP observations when reading/modifying files
  - Link files to concepts via relations (e.g., "auth.ts" -[implements]→ "JWT authentication")

- **Key differences**:
  - claude-mem is automatic (zero intervention), Qdrant+Memory requires agent discipline
  - claude-mem uses FTS5 full-text search, Qdrant uses vector/semantic search (different strengths)
  - claude-mem has typed observations (decision, bugfix, etc.), must manually tag in Qdrant/Memory
  - claude-mem uses Claude Agent SDK for AI extraction, Qdrant+Memory requires agent self-extraction
  - claude-mem tracks tool executions automatically, Qdrant+Memory requires explicit "save this" calls

- **Advantage of manual approach**: Works across all CLI agents (Codex, Gemini, Claude), not just Claude Code


### Other MCP servers

| Server | Functionality | How it's run/talked to by agents | Restrictions |
| :----- | :------------ | :------------ | :----------- |
| **PAL MCP *(`clink` only)*** | multi-model orchestration; CLI-to-CLI bridge ("clink"); spawn sub-agents; context threading across tools/CLIs | stdio with per-CLI instances | None |
| **Filesystem MCP** | bulk file reads (filtered to `read_multiple_files` only for 30-60% token savings on 10+ files; use native Read/Write/Edit for other operations) | stdio with private client-managed instances | None |
| **Semgrep MCP** | lets your agent **(1)** scan source code locally (no code leaves your machine) using AST-aware, pattern-based rules to *catch security issues, bugs, and risky anti-patterns across many languages* **(2)** run targeted scans (a file, dir, or diff) or full-repo checks **(3)** choose rulesets (built-in or custom YAML rules you write in code-like patterns) **(4)** get structured findings back, by file/line, rule ID, severity, message, code snippet **(5)** autofix suggestions when a rule defines a fix | HTTP with locally-running instance of *Semgrep's free "community edition" server* | Free "community edition" used: see *[full list of Semgrep community edition features](https://semgrep.dev/docs/semgrep-pro-vs-oss)* |
| **Serena MCP** | language-server-powered semantic code navigation, refactoring, and editing; provides IDE-grade symbol search (`find_symbol`, `find_referencing_symbols`), structural edits (`insert_after_symbol`, `rename_symbol`, `replace_symbol_body`), project onboarding/memories, and LSP integration across 20+ languages (Python, TypeScript, Go, Rust, Java, etc.); complements Filesystem MCP by working at the semantic level instead of whole-file operations | HTTP with locally-running server (cloned from GitHub repo), downloads language servers as needed | None |
| **Playwright MCP** | browser automation; interact with web pages via structured accessibility snapshots (no vision models needed); navigate, click, type, extract content; supports Chrome, Firefox, WebKit, with device emulation, storage state, custom scripts; runs headless or headed; all processing local via Playwright | stdio with private client-managed instances | None (free, local execution) |

## Non-MCP tools

| Tool | Type | Functionality |
| :--- | :--- | :------------ |
| **[GitHub SpecKit](https://github.github.io/spec-kit/) *(amazing, your agents will never hallucinate or get distracted again)*** | Command-line tool | Enables **Spec-Driven Development** via `specify` CLI, which allows making detailed constitution/spec/plan/tasks for each project; agent-agnostic templates (Copilot/Claude/Gemini) |

> There's a bit of a learning curve for getting to use GitHub SpecKit, but it's definitely worth it
