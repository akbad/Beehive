# Tools not in the script yet to add later

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


## SQLite Explorer MCP (FastMCP)

**Package**: `sqlite-explorer-fastmcp-mcp-server` (community-maintained)

**Repository**: https://github.com/hannesrudolph/sqlite-explorer-fastmcp-mcp-server

**Purpose**: Safe, read-only SQLite database exploration and analysis

**Why add it**:
- Actively maintained community alternative (official server was archived)
- Read-only access provides enhanced security (no accidental data modification)
- Built with modern FastMCP framework for reliability
- Query validation and sanitization built-in
- Analyze local databases without cloud services
- Complements Qdrant (which handles vectors, not relational data)
- Zero dependencies - just filesystem-based database
- Perfect for data analysis, prototyping, and structured queries

**How it's run**: Stdio with private client-managed instance (Python-based)

**Free tier**: Completely free (local SQLite files)

**Install**:
```bash
# Clone repository
git clone https://github.com/hannesrudolph/sqlite-explorer-fastmcp-mcp-server.git

# Run with uv
SQLITE_DB_PATH=/path/to/database.db uvx --from fastmcp run /path/to/sqlite_explorer.py
```

**Use cases**:
- Local data analysis and reporting
- Structured storage for agent-generated data
- Rapid prototyping with relational data
- Single-user app backends
- Database schema inspection and exploration

**Safety features**:
- Read-only access (no writes/deletes)
- Automatic query validation
- Parameter binding for SQL injection prevention
- Row limit enforcement
