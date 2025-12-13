# Qdrant MCP: Deep Dive

## Overview

 Semantic memory layer using vector embeddings for meaning-based retrieval. Persistent local storage via Docker volume (limited by host disk).

## Available Tools

### 1. `qdrant-store` - Save Information

**What it does:** Stores information with embeddings for semantic search

**Parameters:**
- `information` (required) - Text to store
- `metadata` (optional) - JSON object with additional context

**Returns:** Confirmation of storage

**Best for:** Building personal knowledge base, storing code snippets, saving learnings

**Rate limits:** None (local Docker or cloud instance)

### 2. `qdrant-find` - Retrieve by Meaning

**What it does:** Finds semantically similar information by query

**Parameters:**
- `query` (required) - What to search for (by meaning)

**Returns:** Relevant stored information ranked by semantic similarity

**Best for:** Finding information by concept, discovering related content

**Rate limits:** None

## How It Works

**Vector embeddings:**
- Uses FastEmbed models (default: all-MiniLM-L6-v2)
- Converts text to mathematical vectors
- HNSW index for fast similarity search
- Finds by meaning, not keywords

**Storage:**
- Local: Docker container with persistent volume
- Cloud: Qdrant cloud instances
- Data persists across sessions

## Tradeoffs

### Advantages
✅ **Semantic search** (find by meaning, not keywords)
✅ **Persistent local storage** (Docker volume; limited by host disk)
✅ **Persistent** (survives restarts, cross-session)
✅ **Metadata support** (add structure to searches)
✅ **Fast retrieval** (HNSW index)
✅ **No rate limits** (local or self-hosted)

### Disadvantages
❌ **No relationship tracking** (use Memory MCP for that)
❌ **Requires manual saving** (not automatic like claude-mem)
❌ **No graph queries** (use Memory MCP)
❌ **Setup required** (Docker or cloud instance)

## Common Pitfalls: When NOT to Use

### ❌ Need Explicit Relationships
**Problem:** Qdrant finds similarity, not relationships
**Alternative:** Memory MCP

**Example:**
```
Bad:  qdrant-store("John works at Anthropic")
      qdrant-find("who works at Anthropic")
      → Might miss due to wording differences

Good: memory.create_entities + create_relations
      memory.search_nodes("works_at")
      → Explicit relationship query
```

### ❌ One-Time Information
**Problem:** Storing wastes space for temporary data
**Alternative:** Keep in conversation context

**Example:**
```
Bad:  qdrant-store("Today's meeting notes for one-time review")
Good: Just keep in current conversation
```

### ❌ Structured Graph Queries
**Problem:** Qdrant doesn't support "X relates to Y" queries
**Alternative:** Memory MCP

**Example:**
```
Bad:  qdrant for tracking project dependencies
Good: memory.create_relations for dependency graph
```

### ❌ Keyword-Only Search
**Problem:** Simple keyword search doesn't need vector embeddings
**Alternative:** Grep or filesystem search

**Example:**
```
Bad:  qdrant-store then qdrant-find for exact string match
Good: grep or filesystem search for keywords
```

### ❌ Temporary Session Data
**Problem:** Permanent storage for non-persistent data
**Alternative:** Conversation context

**Example:**
```
Bad:  qdrant-store("Intermediate calculation results")
Good: Keep in conversation, ephemeral
```

## When Qdrant IS the Right Choice

✅ **Find by meaning** ("auth patterns" → finds JWT, OAuth, sessions)
✅ **Cross-session knowledge base**
✅ **Code snippet library** (semantic search)
✅ **Remember solutions** to problems
✅ **Discover related concepts**

**Decision rule:** "Do I need to find this by meaning later?"

## Usage Patterns

**Store code snippets:**
```
qdrant-store(
  "React useEffect cleanup prevents memory leaks by returning function",
  metadata: {"type": "code", "language": "react", "topic": "hooks"}
)
```

**Store learnings:**
```
qdrant-store(
  "JWT tokens for stateless auth, refresh tokens for security",
  metadata: {"type": "architecture", "topic": "authentication"}
)
```

**Store solutions:**
```
qdrant-store(
  "Fixed CORS by adding Access-Control-Allow-Origin header in Express",
  metadata: {"type": "solution", "problem": "CORS", "technology": "express"}
)
```

**Find by concept:**
```
qdrant-find("how to prevent memory leaks in React")
→ Returns useEffect cleanup snippet (semantic match)

qdrant-find("stateless authentication patterns")
→ Returns JWT/OAuth notes (concept match)

qdrant-find("fixing cross-origin issues")
→ Returns CORS solution (semantic similarity)
```

**With metadata (when filters enabled):**
Requires enabling filters (e.g., set `QDRANT_ALLOW_ARBITRARY_FILTER=true` or configure `filterable_fields`).
```
qdrant-find("authentication") + filter metadata.type="architecture"
```

## Combining with Memory MCP

**Use both for complex knowledge:**
```
Qdrant: Store searchable content
Memory: Track relationships

Example:
  Qdrant: Store "JWT authentication implementation details"
  Memory: Track project_A --uses--> JWT_pattern
```

**Workflow:**
```
1. qdrant-store: Save code snippets, solutions
2. memory.create_entities: Create projects, concepts
3. memory.create_relations: Link projects to patterns
4. qdrant-find: Discover by meaning
5. memory.search_nodes: Query relationships
```

## Best Practices

**What to store:**
- Code patterns and snippets
- Solutions to problems encountered
- Architectural decisions and rationale
- API usage examples
- Learned concepts and facts

**Storage strategy:**
- **Atomic pieces** (one concept per store)
- **Descriptive text** (include context, not just code)
- **Metadata** for structure (type, language, project, topic)
- **Rich descriptions** help semantic search

**Search optimization:**
- **Conceptual queries** (describe what you want)
- **Varied wording** (semantic search handles synonyms)
- **Specific enough** to narrow results

**Common mistakes:**
- ❌ Storing entire files (store key snippets)
- ❌ Minimal text (add context for better retrieval)
- ❌ No metadata (harder to filter)
- ❌ Expecting exact keyword match (it's semantic)

## Qdrant vs Memory Quick Decision

| Scenario | Use Qdrant | Use Memory | Use Both |
|----------|-----------|------------|----------|
| Store code snippets for "find similar" | ✅ | ❌ | Optional |
| Track who created what code | ❌ | ✅ | Recommended |
| Personal knowledge base | ✅ | ❌ | Optional |
| Project relationship map | ❌ | ✅ | N/A |
| Searchable docs + author tracking | ✅ | ✅ | ✅ |

## Alternatives Summary

| Task | Instead of Qdrant | Use This |
|------|------------------|----------|
| Explicit relationships | qdrant | Memory MCP |
| One-time information | qdrant-store | Conversation context |
| Graph queries | qdrant-find | Memory MCP |
| Keyword search | qdrant-find | Grep / Filesystem |
| Temporary data | qdrant-store | Conversation context |

## Local Setup Notes

For the provided setup script (beehive/tools/scripts/set-up-tools.sh):

- Qdrant DB: `http://127.0.0.1:8780` (Docker maps host 8780 → container 6333)
- Persistence: Docker bind mount to `~/.qdrant/storage/` (by default)
- MCP server (HTTP): `http://localhost:8782/mcp/` (transport: streamable-http)
- Default collection: `coding-memory`
- Embeddings: provider `fastembed`; model default `sentence-transformers/all-MiniLM-L6-v2`
- Filters: Metadata filtering is off by default (no `QDRANT_ALLOW_ARBITRARY_FILTER` and no `filterable_fields` configured). Enable one of these to filter by payload fields.

## Quick Reference

**Rate limits:** None (local/self-hosted)
**Storage:** Docker volume or cloud
**Persistence:** Across sessions (explicit deletion needed)
**Best for:** Semantic search, find by meaning
**Avoid for:** Relationships, temporary data, keyword-only search

**Embedding model:** sentence-transformers/all-MiniLM-L6-v2 (default)
**Search method:** HNSW vector similarity

**Links:**
- [Category guide: Memory](../category/memory.md)
- [Full decision guide](../../../tools/tools-decision-guide.md)
