# Tools not in the script yet that will definitely be included

## Memory MCP (Anthropic Official)

**Package**: `@modelcontextprotocol/server-memory`

**Purpose**: Knowledge graph for persistent structured memory across sessions

**Why add it**:
- Complements Qdrant's semantic memory with **structured relationships**
- Creates entities, relations, and observations in a knowledge graph
- Solves AI amnesia problem - maintains context across sessions
- Official Anthropic implementation
- Stores data locally in SQLite (zero cost, zero cloud dependencies)

**How it's run**: Stdio with private client-managed instance

**Free tier**: Completely free (local SQLite storage)

**Install**: `npx @modelcontextprotocol/server-memory`

**Key difference from Qdrant**:
- Qdrant = semantic vector search (finds *similar* things)
- Memory = knowledge graph (tracks *relationships* between things)



## Playwright/Puppeteer MCP

**Package**: `@modelcontextprotocol/server-puppeteer` or `@cloudflare/playwright-mcp`

**Purpose**: Browser automation, interactive web testing, dynamic scraping

**Why add it**:
- Firecrawl/Tavily can't handle **interactive web tasks** (clicking buttons, filling forms, navigating)
- Enables E2E testing automation
- Can handle JavaScript-heavy dynamic sites
- Take screenshots, simulate user interactions
- Fill and submit forms programmatically

**How it's run**: Stdio with private client-managed instance (uses local browser)

**Free tier**: Completely free (local browser automation, no API)

**Install**: `npx -y @modelcontextprotocol/server-puppeteer`

**Use cases**:
- Automated testing workflows
- Scraping sites that require interaction
- Form submission automation
- Visual regression testing



## Docker MCP

**Package**: `docker-mcp`

**Purpose**: Container and Docker Compose orchestration for agent workflows

**Why add it**:
- Eliminates manual terminal juggling for `docker compose up`, `docker logs`, and other container chores by exposing them as MCP tools
- Gives agents first-class control over local stacks for smoke tests, preview environments, and background services
- 100% open source with zero recurring cost; rides on the Docker Engine/Desktop you already run
- Works great alongside Git MCP to spin up deps before running checks or migrations

**How it's run**: Stdio with private client-managed instance that talks to the local Docker daemon

**Free tier**: Completely free (agent leverages your local Docker install)

**Install**: `uvx docker-mcp`

**Use cases**:
- Spin up/down Docker Compose services inside automation flows
- Tail container logs or fetch health metrics during debugging
- Provision short-lived integration environments without leaving the agent



## Serena MCP

**Package**: `serena`

**Purpose**: Language-server-powered semantic code navigation, refactoring, and editing tools for coding agents

**Why add it**:

- Gives agents IDE-grade symbol search (`find_symbol`, `find_referencing_symbols`) and structural edits (`insert_after_symbol`, `rename_symbol`)
- Complements Filesystem/Git MCP by working at the semantic level instead of whole-file reads
- Free and open-source with broad language support via LSP adapters
- Integrates smoothly with Claude Code, Codex, Gemini CLI, Cursor, Cline, and other MCP-aware clients

**How it's run**: Typically via `uvx --from git+https://github.com/oraios/serena serena start-mcp-server` (stdio transport by default; Streamable HTTP optional)

**Free tier**: Completely free (runs locally; downloads language servers as needed)

**Install**: `uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project "$(pwd)"`

**Use cases**:

- Accelerate large codebase navigation and refactors with language-aware tooling
- Offload onboarding/indexing and project memories to augment multi-session workflows
- Provide consistent semantic editing capabilities across different LLM clients



## OpenAPI MCP server

**Package**: `@janwilmake/openapi-mcp-server`

**Purpose**: API spec reconnaissance and endpoint discovery for third-party integrations

**Why add it**:
- Translates natural language (“charge a card in Stripe”) into matching OpenAPI operations and summaries
- Indexes specs so agents can surface required parameters, schemas, and verb-specific guidance instantly
- Pulls canonical documentation from the free OpenAPISearch corpus, keeping results vendor-neutral
- Light footprint: no external keys or paid plans needed, perfect for quick integration research

**How it's run**: HTTP via Smithery-managed local server or direct Node.js process

**Free tier**: Completely free; uses public OpenAPI documents with local caching

**Install**: `npx -y @smithery/cli install @janwilmake/openapi-mcp-server`

**Use cases**:
- Answer “how do I…?” integration questions with exact paths and payloads
- Draft request/response examples grounded in real schemas
- Audit partner APIs for missing endpoints or incompatible versions



## SQLite MCP (Official)

**Package**: `@modelcontextprotocol/server-sqlite`

**Purpose**: Local relational database operations and data analysis

**Why add it**:
- Analyze local databases without cloud services
- Perfect for prototyping, local data storage, structured queries
- Complements Qdrant (which handles vectors, not relational data)
- Zero dependencies - just filesystem-based database
- Official Anthropic implementation

**How it's run**: Stdio with private client-managed instance

**Free tier**: Completely free (local SQLite files)

**Install**: `npx @modelcontextprotocol/server-sqlite --db-path /path/to/database.db`

**Use cases**:
- Local data analysis and reporting
- Structured storage for agent-generated data
- Rapid prototyping with relational data
- Single-user app backends



## Brave Search MCP

**Package**: Community implementations available (search for `brave-search-mcp`)

**Purpose**: Privacy-focused alternative search engine with generous free tier

**Why add it**:
- Diversifies search sources (not reliant on single provider)
- More generous free tier than Tavily (2,000 queries/month vs 1,000)
- Privacy-respecting (no Google tracking)
- Good fallback when other search APIs hit rate limits

**How it's run**: Stdio or HTTP depending on implementation

**Free tier**: Brave Search API provides 2,000 queries/month free

**Restrictions**: Requires Brave Search API key (free to obtain)

**Use cases**:
- Search redundancy and failover
- Privacy-conscious searching
- Higher query volume needs



## EXA Search MCP

**Package**: Community implementations available (search for `exa-mcp` or `exa-search`)

**Purpose**: Neural search engine optimized specifically for LLMs and AI agents

**Why add it**:
- Designed from the ground up for AI/LLM workflows
- Better semantic understanding than traditional keyword search
- Returns content formatted for AI consumption
- Complements Tavily's general-purpose search with AI-native approach
- Superior for research and knowledge discovery

**How it's run**: Stdio or HTTP depending on implementation

**Free tier**: 1,000 searches/month free

**Restrictions**: Requires EXA API key (free tier available)

**Key difference from Tavily**:
- Tavily = general web search with citations
- EXA = neural search optimized for AI agents, finds contextually relevant content
