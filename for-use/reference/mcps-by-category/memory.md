# Memory tools: comparison & usage guides

## Quick selection table

| Tool | Type | Best For | Access Pattern | Availability |
|------|------|----------|----------------|--------------|
| **Qdrant** | Semantic | Find by meaning | "Similar to X" | MCP-enabled clients (e.g., Claude Desktop, VS Code) |
| **Memory MCP** | Knowledge graph | Track relationships | "X relates to Y" | MCP-enabled clients (configured per client) |
| **claude-mem** | Auto context (example) | Persistent sessions | Automatic (implementation-specific) | Commonly used with Claude clients |

## Tool usage guides

### Qdrant (semantic memory)

**What it does:** Vector-based semantic memory using embeddings

**Strengths:**
- Find information by *meaning*, not keywords
- Uses FastEmbed for embeddings (default: BAAI/bge-small-en-v1.5; supports sentence-transformers/all-MiniLM-L6-v2)
- Local Docker or remote Qdrant instances
- Optional metadata alongside text
- Storage bounded by local disk/system resources

**Tools Available:**
- `qdrant-store` - Save information with metadata
- `qdrant-find` - Retrieve by semantic similarity

**Examples:**
```
Store: "JWT authentication with refresh tokens in Express.js"
Find: "auth patterns" → returns JWT, OAuth, session-based

Store: "React useEffect cleanup functions prevent memory leaks"
Find: "preventing React memory issues" → finds it

Store: "PostgreSQL JSONB indexing for fast queries"
Metadata: {"type": "database", "language": "sql"}
```

**When to use:**
- Build personal knowledge base
- Find by concept/similarity
- Store code snippets for reuse
- Remember solutions to problems
- Semantic search over your data

**When NOT to use:**
- Need explicit relationships → Use Memory MCP
- Graph queries needed → Use Memory MCP
- Simple keyword search → Use filesystem/grep
- One-time lookup → Don't store

**Best Practices:**
- Store atomic concepts (one idea per item)
- Use descriptive text (include context, not just code)
- Add metadata for structure (type, language, project)
- Good for: patterns, solutions, links, learnings

### Memory MCP (Knowledge Graphs)

**What it does:** Persistent knowledge graph with entities/relations/observations

**Strengths:**
- Track *who/what* relates to *how*
- Explicit directed relationships (active voice)
- Structured storage (local JSONL file; configurable path)
- Official Anthropic implementation
- Storage bounded by filesystem limits

**Tools Available:**
- `create_entities` - Create nodes (people, orgs, concepts)
- `create_relations` - Define relationships (from → to)
- `add_observations` - Add facts to entities
- `delete_entities/observations/relations` - Remove items
- `read_graph` - View entire graph
- `search_nodes` - Search by name/type/observation
- `open_nodes` - Get specific entities

**Example Structure:**
```
Entity: John_Smith (type: person)
    Observations: ["Speaks Spanish", "Async communication"]
    Relations:
        John_Smith --works_at--> Anthropic
        John_Smith --contributes_to--> ProjectX

Entity: ProjectX (type: project)
    Observations: ["React-based", "Uses TypeScript"]
    Relations:
        ProjectX --depends_on--> React
        ProjectX --deployed_on--> Vercel
```

**When to use:**
- Track relationships between concepts
- Build structured knowledge base
- Maintain project context (who, what, how)
- Personal CRM or project memory
- Query relationships ("who works at X?")
- Map dependencies/connections

**When NOT to use:**
- Need semantic/similarity search → Use Qdrant
- Relationships don't matter → Use Qdrant
- Simple notes → Use filesystem
- Temporary (single session) → Keep in context

**Best Practices:**
- Unique entity names (John_Smith, ProjectX)
- Active voice relations (works_at, depends_on)
- Atomic observations (one fact each)
- Consistent entity types (person, company, project)
- Order matters in relations (directed graph)

### claude-mem (Example Automatic Context)

Note: "claude-mem" is used here to describe a common, custom pattern for automatic context/memory built around Claude clients. It is not an official Anthropic product; features vary by implementation.

**What it does (example):** Implements automatic persistent memory using client/event hooks to capture observations and generate summaries.

**Potential strengths (implementation-dependent):**
- Fully automatic (minimal manual intervention)
- Captures observations after tool use or key actions
- Generates session summaries and offers progressive disclosure at session start

**Example lifecycle (varies by client):**
1. Session start → surface recent summaries for quick recall
2. Post tool use → capture observations automatically
3. Stop/end → generate summary (request/completed/learned)
4. Session end → persist across session resets

**Progressive disclosure pattern (recommended):**
- Layer 1: Compact index/summary
- Layer 2: Full details for selected items
- Layer 3: Source code and transcripts when needed

**Availability:** Implementation-specific; commonly built for Claude Desktop/Code

## Qdrant vs Memory: Quick Decision

**Use Qdrant when:**
- "Find things similar to this"
- Semantic search is main pattern
- Relationships don't matter
- Building retrieval system

**Use Memory when:**
- "Show me what relates to X"
- Explicit relationships critical
- Need graph queries
- Building context management

**Use both when:**
- Complex knowledge base needs similarity + relationships
- Example: Qdrant for code snippets, Memory for tracking which projects use them

## Replicating Automatic Context Flows

If your client lacks automatic hooks, manually implement:

**Manual observation logging:**
- After reading code → Save to Qdrant + Memory MCP
- After decisions → Create entities with relations
- After fixes → Store in Qdrant with metadata

**Session summaries:**
- Before ending → Create summary and store it (e.g., in Qdrant)
- Include: request, completed, learned, next_steps

**Context recovery:**
- Start sessions → Search Qdrant for past work
- Fetch related entities from Memory MCP

**Key differences:**
- Custom automatic flows: automated capture/surfacing
- Qdrant+Memory: manual capture unless automation is added
- Qdrant: vector search; Memory MCP: graph queries/relations
- Typed observations/tags often require manual conventions

## Best Practices

**Choose right tool:**
- Semantic search → Qdrant
- Relationships → Memory MCP
- Both → Use both (complementary)

**Storage strategy:**
- Qdrant: Searchable content, solutions, patterns
- Memory: Relationships, context, project structure

**Search efficiently:**
- Custom automatic memory: Start with an index/summary view
- Qdrant: Use descriptive queries
- Memory: Search then open specific nodes

**Common mistakes:**
- ❌ Using Qdrant for relationships (use Memory)
- ❌ Using Memory for similarity search (use Qdrant)
- ❌ Fetching full details without using an index/summary first

## Quick Reference Links

- [Full decision guide](../../mcps/tools-decision-guide.md#memory)
- [Compact tool list](../compact-mcp-list.md) *(tier 1)*
