# When to use each MCP tool: decision guide

> [!NOTE]
> - **Audience:** both humans (documentation) and coding agents (instructions)
> - **Purpose:** optimal tool selection for
>   
>   - maximizing value
>   - avoiding rate limits
>   - minimizing waste *(of tokens, tool usage limits, etc.)*

**<ins>Contents:</ins>**

- [Quick Reference: Tool Usage Hierarchy](#quick-reference-tool-usage-hierarchy)
- [Detailed Tool Profiles](#detailed-tool-profiles)
- [Decision Trees by Task Type](#decision-trees-by-task-type)
- [Rate Limit Management](#rate-limit-management)
- [Special Cases & Gotchas](#special-cases--gotchas)

---

## Quick reference: tool usage hierarchy

### Web browsing/researching/fetching tools (use following prescribed priorities)

**Tier 1: Primary Tools (Use First)**

1.  **Sourcegraph MCP** - Code search across public repos
2.  **Tavily MCP** - Web research with citations (1000 credits/month)
3.  **Context7 MCP** - API documentation and examples

**Tier 2: Specialized Tools (Conditional Use)**

4.  **Brave MCP** - Privacy-focused search (2000 queries/month)

**Tier 3: Fallback Tools (Last Resort)**

5.  **Fetch MCP** - Simple URL fetching (no rate limits)

### Memory & coding tools (use as needed)

**Memory & Knowledge:**

-   **Qdrant MCP** - Semantic memory layer (vector search, find by meaning, no rate limits)
-   **Memory MCP** - Knowledge graph (entities/relations, structured memory, no rate limits)

**Code Analysis & Manipulation:**

-   **Serena MCP** - Semantic code navigation/refactoring (symbol-level operations)
-   **Semgrep MCP** - Security/bug scanning (pattern-based analysis)
-   **Filesystem MCP** - File operations (read/write/edit)
-   **Git MCP** - Git operations (status/diff/commit/etc.)

**Browser Automation:**

-   **Playwright MCP** - Web automation (navigate, click, type, extract via accessibility tree)

## Detailed tool profiles

### Web research & search tools

#### Sourcegraph MCP ⭐ **[PRIMARY FOR CODE]**

**What it does:**

-   "Google for code" - searches across public GitHub repos
-   Powerful filters: regex, language, file path, branch
-   Guided search prompts (natural language → precise queries)
-   Returns exact code snippets with line numbers

**When to use:**

-   Finding code examples/patterns across repos
-   Researching how libraries/APIs are used in practice
-   Discovering implementations of specific algorithms
-   Learning from real-world code

**Rate limits:** None apparent (free tier for public repos)

**Why use first:** Purpose-built for code search with no strict limits

#### Tavily MCP ⭐ **[PRIMARY FOR WEB]**

**What it does:**

-   Web search, extract, map, and crawl
-   **Includes citations** (critical for credibility)
-   Handles news, general info, current events

**When to use:**

-   General web research
-   Finding current information
-   Getting cited sources for claims
-   Extracting content from known URLs
-   Mapping site structure

**Rate limits:** 1000 API credits/month (resets on 1st)

-   Basic search: ~1-5 credits
-   Extract: varies by complexity
-   See [full credit costs](https://docs.tavily.com/documentation/api-credits#api-credits-costs)

**Why use second:** Best balance of features and generous limits

#### Context7 MCP ⭐ **[PRIMARY FOR DOCS]**

**What it does:**

-   Fetches up-to-date, version-specific API documentation
-   Includes code examples from official docs
-   Works with public repos only

**When to use:**

-   Learning a new library/framework
-   Checking current API syntax
-   Getting official usage examples
-   Understanding library capabilities

**Rate limits:** Free tier, public repos only

**Why use third:** Specialized for documentation, no apparent hard limits

#### Brave MCP **[SECONDARY SEARCH]**

**What it does:**

-   Privacy-focused search engine
-   Web, local, news, image, video search
-   No tracking or profiling

**When to use:**

-   Tavily credits exhausted
-   Need privacy-focused results
-   Basic web search without advanced features

**Rate limits:** 2000 queries/month (basic web search only on free tier)

**Why use here:** Good fallback when Tavily exhausted, but limited to basic search

#### Fetch MCP **[SIMPLE FALLBACK]**

**What it does:**

-   Basic HTTP/HTTPS URL fetching
-   Converts HTML to Markdown
-   Optional raw HTML
-   Chunk reading via start_index

**When to use:**

-   Simple one-off URL fetch
-   Don't need search/crawl/extraction
-   All other tools exhausted or overkill

**Rate limits:** None

**Limitations:**

-   **Does NOT support fetching directly from github.com** (fetch from `raw.githubusercontent.com` instead, or use `gh` CLI)

**Why use last:** No advanced features, but reliable and unlimited

### Memory & knowledge tools

#### Qdrant MCP ⭐ **[PRIMARY FOR SEMANTIC MEMORY]**

**What it does:**

-   Vector-based semantic memory layer using Qdrant database
-   Stores information with embeddings for semantic (meaning-based) retrieval
-   Uses FastEmbed models (default: sentence-transformers/all-MiniLM-L6-v2)
-   Can run locally or connect to cloud/remote Qdrant instances
-   Supports optional structured metadata alongside text

**Tools available:**

1.  `qdrant-store` - Store information with optional metadata
2.  `qdrant-find` - Retrieve semantically similar information by query

**When to use (MANDATORY for these scenarios):**

-   **After solving ANY problem** - Store the solution, approach, and why it worked
-   **After investigating code** - Store patterns discovered, gotchas found, insights gained
-   **After making decisions** - Store trade-offs considered, alternatives rejected, rationale
-   **After debugging** - Store root cause, symptoms, fix approach, prevention tips
-   **After analyzing performance** - Store bottlenecks found, optimizations applied, metrics
-   **After discovering undocumented behavior** - Store quirks, edge cases, workarounds
-   Storing code snippets, examples, or reusable patterns for later retrieval
-   Building a personal knowledge base across sessions
-   Need to find information by *meaning* rather than exact keywords
-   Storing learned insights from previous conversations

**When NOT to use:**

-   Need to track explicit relationships between items → Use Memory MCP instead
-   Need structured graph queries → Use Memory MCP instead
-   Simple keyword search is sufficient → Use grep/filesystem tools
-   Truly trivial one-time lookups with zero learning value → Skip (rare)

**Rate limits:** None (local Docker container or self-hosted)

**Best practices:**

-   Store atomic pieces of information (one concept per store)
-   Use metadata field for structure (e.g., `{"type": "code", "language": "python"}`)
-   Descriptive text helps retrieval (include context, not just code)
-   Good for: code patterns, solutions to problems, useful links, learned facts
-   Works great with Cursor/Windsurf for code snippet libraries

**Example use cases:**

-   "Store this React hook pattern for reuse later" → retrieves by describing what you need
-   Building a personal StackOverflow of solved problems
-   Remembering API patterns across different projects
-   Semantic code snippet search in your IDE

**Why use:** Best tool for "find things similar to X" - works like a persistent, intelligent search over your saved knowledge

#### Memory MCP ⭐ **[PRIMARY FOR KNOWLEDGE GRAPHS]**

**What it does:**

-   Persistent knowledge graph with entities, relations, and observations
-   Tracks explicit relationships between concepts/people/things
-   Stores structured information in local JSONL file
-   Maintains context and facts across sessions
-   Official MCP implementation by Anthropic

**Tools available:**

1.  `create_entities` - Create nodes in the graph (people, orgs, events, concepts)
2.  `create_relations` - Define directed relationships between entities (in active voice)
3.  `add_observations` - Add facts/notes to existing entities
4.  `delete_entities` - Remove entities and their relations
5.  `delete_observations` - Remove specific facts from entities
6.  `delete_relations` - Remove specific relationships
7.  `read_graph` - Read the entire knowledge graph
8.  `search_nodes` - Search entities by name/type/observation content
9.  `open_nodes` - Retrieve specific entities by name

**When to use (MANDATORY for these scenarios):**

-   **After working on a project** - Create/update entities for components, modules, dependencies
-   **After discovering relationships** - Map how components interact, depend on each other
-   **After identifying key people/tools** - Track who owns what, what tools are used where
-   **After analyzing architecture** - Store system structure, data flows, integration points
-   **When project context emerges** - Capture facts about the codebase, team, processes
-   **After making architectural decisions** - Store what components exist and how they relate
-   Need to track *who* relates to *what* and *how*
-   Building a structured knowledge base with explicit relationships
-   Maintaining facts about users/preferences/history
-   Need to query relationships (e.g., "which components depend on module X?")

**When NOT to use:**

-   Need semantic/similarity search → Use Qdrant MCP instead
-   Relationships aren't important, just storage → Use Qdrant MCP instead
-   Simple note-taking without structure → Use filesystem or Qdrant
-   Temporary context (single session) → Just keep in conversation context

**Rate limits:** None (local JSONL file storage)

**Best practices:**

-   Entities: Use clear, unique names (e.g., "John_Smith", "ProjectX")
-   Relations: Always use active voice (e.g., "works_at", "depends_on")
-   Observations: Keep atomic (one fact per observation)
-   Entity types: Use consistent categorization (e.g., "person", "company", "project")
-   Relations are directed: order matters (from → to)

**Example structure:**

```
Entity: John_Smith (type: person)
    Observations: ["Speaks Spanish", "Prefers async communication"]
    Relations: John_Smith --works_at--> Anthropic
               John_Smith --contributes_to--> ProjectX

Entity: Anthropic (type: company)
    Observations: ["AI safety research", "Based in San Francisco"]
```

**Example use cases:**

-   Personal memory: Remember user preferences, context, history
-   Project documentation: Track components, dependencies, who owns what
-   Relationship mapping: Social/professional network graphs
-   Learning journal: Connect concepts, topics, resources with explicit links
-   Code understanding: Map relationships between modules, functions, data flows

**Why use:** Best tool for "X relates to Y" - maintains structured knowledge with queryable relationships

### Qdrant vs memory: quick decision guide

**Use Qdrant when:**

-   "Find things similar to this concept"
-   Semantic search is the main access pattern
-   Relationships between items aren't critical
-   Building a retrieval/search system

**Use Memory when:**

-   "Show me what relates to X"
-   Explicit relationships matter
-   Need structured graph queries
-   Building a knowledge/context management system

**Use both when:**

-   Complex knowledge base needs both similarity search AND relationship tracking
-   E.g., Qdrant for code snippets, Memory for tracking which projects use which patterns

### Code analysis & manipulation tools

#### Serena MCP ⭐ **[PRIMARY FOR CODE EDITING]**

**What it does:**

-   Language-server-powered semantic code navigation
-   IDE-grade symbol search (find_symbol, find_referencing_symbols)
-   Structural edits (rename, insert, replace at symbol level)
-   20+ languages supported

**When to use:**

-   Need semantic understanding of code (not just text)
-   Refactoring operations
-   Finding all references to a symbol
-   IDE-level code intelligence

**Rate limits:** None (local server)

**Why use:** Works at semantic level vs. whole-file operations

#### Semgrep MCP

**What it does:**

-   AST-aware security/bug/anti-pattern scanning
-   Pattern-based rules (built-in or custom)
-   Autofix suggestions
-   Local scanning (code never leaves machine)

**When to use:**

-   Security audits
-   Finding bugs/anti-patterns
-   Code quality checks
-   Custom rule enforcement

**Rate limits:** None (free community edition, local server)

#### Playwright MCP

**What it does:**

-   Browser automation using Playwright's accessibility tree
-   Fast, deterministic tool application (no vision models)
-   Navigate, click, type, extract content from web pages
-   Supports Chrome, Firefox, WebKit with device emulation
-   Can run headless or headed mode

**When to use:**

-   Automated web testing and interaction
-   Scraping dynamic content requiring JavaScript execution
-   Form filling and submission automation
-   End-to-end testing workflows
-   Extracting data from interactive web applications

**Rate limits:** None (local execution)

#### Filesystem MCP

**What it does:** Bulk file reads (filtered to `read_multiple_files` only)

**When to use:**
- Batch reading 10+ files (30-60% token savings vs multiple Read calls)

**Rate limits:** None (local)

## Decision trees by task type

### Finding code examples

```
START
    ↓
Need code from public repos?
    ├─ YES → Use Sourcegraph MCP (no rate limits)
    └─ NO  → Need GitHub-specific?
        ├─ YES → Use gh CLI or raw.githubusercontent.com via Fetch
        └─ NO  → Context7 for docs/examples from official sources
```

### Web research & information gathering

```
START
    ↓
What type of information?
    ├─ API docs/library info → Context7 MCP
    ├─ Current events/general web → Tavily MCP
    ├─ Basic search (Tavily exhausted) → Brave MCP
    └─ Simple URL content → Fetch MCP
```

### Website crawling/scraping

```
START
    ↓
Single URL or simple extraction?
    ├─ YES → Fetch MCP (unlimited) or Tavily extract
    └─ NO  → Multiple pages/complex?
        ↓
        Try Tavily search/extract/map/crawl
        ↓ Still need more?
        ↓
        Use Fetch iteratively on known URLs
```

### Code manipulation

```
START
    ↓
Need semantic understanding?
    ├─ YES → Serena MCP (symbol-level operations)
    └─ NO  → Simple file edits?
        ├─ YES → Filesystem MCP
        └─ NO  → Security/bug scan → Semgrep MCP
```

### Browser automation & web interaction

```
START
    ↓
Need to interact with web pages?
    ├─ Static content (no JS) → Fetch MCP or Tavily extract
    └─ Dynamic content or user interaction needed?
        ├─ YES → Playwright MCP
        │        (click, type, navigate, extract)
        └─ NO  → Just need HTML? → Fetch MCP
```

### Memory & knowledge storage

```
START
    ↓
Need to store/retrieve information across sessions?
    ├─ NO  → Keep in conversation context
    └─ YES → What's the primary access pattern?
        ↓
        Do relationships between items matter?
        ├─ NO  → Need similarity/semantic search?
        │        ├─ YES → Qdrant MCP
        │        │        (find by meaning: "auth patterns" → OAuth/JWT/etc.)
        │        └─ NO  → Simple storage → Filesystem or notes
        │
        └─ YES → Need explicit relationships?
            ├─ YES → Memory MCP
            │        (track X relates to Y: person → works_at → company)
            └─ NO  → Qdrant MCP sufficient

Special case: Complex knowledge base?
    → Use BOTH:
        • Qdrant: Store searchable content
        • Memory: Track relationships between content

Example: Code snippet library
    → Qdrant: Store snippets, find by description
    + Memory: Track which projects/patterns use which snippets
```

## Rate limit management

### Critical limits to track

| Tool | Limit Type | Amount | Reset | Severity |
|------|-----------|---------|-------|----------|
| Tavily | Monthly | 1000 credits | 1st of month | 🟡 MEDIUM |
| Brave | Monthly | 2000 queries | Monthly | 🟡 MEDIUM |
| Sourcegraph | None | ∞ | N/A | 🟢 SAFE |
| Fetch | None | ∞ | N/A | 🟢 SAFE |
| Playwright | None | ∞ | N/A | 🟢 SAFE |

### Strategies

1.  **Always exhaust unlimited tools first** (Sourcegraph, Fetch)
2.  **Use monthly-reset tools wisely** (Tavily/Brave) - both reset monthly
3.  **Front-load Tavily early in month** - will reset on 1st

### Cost-benefit analysis before using limited tools

**Before using Tavily (1k/month):**

-   Can Fetch do this for known URLs? (Unlimited)
-   Can Brave do this basic search? (2k/month)
-   Is this worth using monthly quota?
-   Early in month vs. late in month?

## Special cases & gotchas

### GitHub content

❌ **DON'T:** Use Fetch MCP on github.com URLs (not supported)

✅ **DO:** Use one of these:

1.  **Best:** `raw.githubusercontent.com/<user>/<repo>/<branch>/<file>` via Fetch
2.  **Also good:** `gh` CLI locally
3.  **For search:** Sourcegraph MCP
4.  **For analysis:** Clone locally + Git MCP + Serena MCP

### Documentation lookup

**Use this priority:**

1.  Context7 (official docs, version-specific)
2.  Tavily search (general web docs, tutorials)
3.  Sourcegraph (real-world usage examples)

### Multi-page content extraction

**Recommended sequence:**

1.  Tavily search to find relevant pages
2.  Tavily extract on specific URLs
3.  Tavily map/crawl for site structure
4.  If still insufficient, Fetch iteratively on known URLs

### Dynamic web content

**Use this priority:**

1.  Playwright (for JS-heavy sites, form interactions, dynamic content)
2.  Tavily extract (for simpler extractions)
3.  Fetch MCP (for static HTML only)

### Memory & knowledge storage

**Memory MCP Best Practices:**

❌ **DON'T:**

-   Use passive voice for relations ("is_managed_by" → use "manages")
-   Create duplicate entities (check with `search_nodes` first)
-   Store multiple facts in one observation
-   Use complex entity names with spaces/special chars

✅ **DO:**

-   Use active voice relations: "John --works_at--> Company" (not "Company --employs--> John")
-   Use underscores in names: "John_Smith", not "John Smith"
-   Keep observations atomic: ["Speaks Spanish", "Graduated 2019"] (not ["Speaks Spanish and graduated in 2019"])
-   Use consistent entity types across the graph

**Qdrant vs Memory Decision:**

| Scenario | Use Qdrant | Use Memory | Use Both |
|----------|-----------|------------|----------|
| Store code snippets for "find similar" | ✅ | ❌ | Optional |
| Track who created what code | ❌ | ✅ | Recommended |
| Personal knowledge base | ✅ | ❌ | Optional |
| Project relationship map | ❌ | ✅ | N/A |
| Searchable docs + author tracking | ✅ | ✅ | ✅ |

**Data Persistence:**

-   **Qdrant**: Data in Docker volume (survives restarts) OR cloud (persistent)
-   **Memory**: JSONL file (location: `MEMORY_MCP_STORAGE_PATH` or default `~/.memory-mcp/memory.jsonl`)
-   Both require explicit deletion - data persists across sessions

### When multiple tools can work

**Default to this order:**

1.  Unlimited tools (Sourcegraph, Fetch)
2.  Monthly-reset tools (Tavily, Brave) - prefer Tavily for citations

## Summary: golden rules

### Search & research

1.  **Sourcegraph first for code**, Tavily first for web
2.  **Fetch is unlimited** - use liberally for simple fetches
3.  **Context7 for official docs**, Sourcegraph for real examples
4.  **Tavily for citations**, Brave as fallback when Tavily exhausted
5.  **Front-load Tavily early each month** before credits run out

### Memory & knowledge

8.  **Qdrant for "find similar"**, Memory for "X relates to Y"
9.  **Both memory tools have no rate limits** - use freely for persistent storage
10. **Qdrant needs Docker OR cloud**, Memory works out of the box
11. **Memory relations in active voice** - "works_at" not "is_employed_by"
12. **Data persists across sessions** - remember to clean up when done

## Quick decision flowchart

```
Need to accomplish task
    ↓
Is it code-related?
    ├─ YES → Finding examples? → Sourcegraph
    │        ↓
    │        Need docs? → Context7
    │        ↓
    │        Editing/refactoring? → Serena
    │        ↓
    │        Security scan? → Semgrep
    │
    └─ NO  → Is it web/research?
        ├─ YES → General info? → Tavily
        │        ↓
        │        Simple URL? → Fetch
        │        ↓
        │        Need semantic search? → Try Tavily first, then Exa
        │        ↓
        │        Complex crawl? → Try Tavily, then consider Firecrawl
        │
        └─ NO  → Memory storage? → Qdrant (semantic) or Memory (graph)
            ↓
            Files? → Filesystem
            ↓
            Git? → Git MCP
```

