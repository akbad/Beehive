# Memory MCP: Deep Dive

## Overview

Knowledge graph with entities, relations, and observations. Tracks explicit relationships between concepts. Unlimited local JSONL storage.

## Available Tools

### 1. `create_entities` - Create Graph Nodes

**What it does:** Creates entities (nodes) in knowledge graph

**Parameters:**
- `entities` (required) - Array of entities to create
  - Each: `{name, entityType, observations[]}`

**Returns:** Confirmation of creation

**Best for:** Adding people, projects, concepts, organizations

**Rate limits:** None

### 2. `create_relations` - Define Relationships

**What it does:** Creates directed relationships between entities

**Parameters:**
- `relations` (required) - Array of relations
  - Each: `{from, to, relationType}` (active voice)

**Returns:** Confirmation of creation

**Best for:** Linking entities with explicit relationships

**Rate limits:** None

### 3. `add_observations` - Add Facts to Entities

**What it does:** Adds observations (facts) to existing entities

**Parameters:**
- `observations` (required) - Array of observations
  - Each: `{entityName, contents[]}`

**Returns:** Confirmation of additions

**Best for:** Adding new facts to existing entities

**Rate limits:** None

### 4. `delete_entities` - Remove Entities

**What it does:** Deletes entities and their relations

**Parameters:**
- `entityNames` (required) - Array of entity names to delete

**Returns:** Confirmation of deletion

**Best for:** Cleanup, removing outdated entities

**Rate limits:** None

### 5. `delete_observations` - Remove Specific Facts

**What it does:** Deletes specific observations from entities

**Parameters:**
- `deletions` (required) - Array of deletions
  - Each: `{entityName, observations[]}`

**Returns:** Confirmation of deletion

**Best for:** Removing outdated or incorrect facts

**Rate limits:** None

### 6. `delete_relations` - Remove Relationships

**What it does:** Deletes specific relationships

**Parameters:**
- `relations` (required) - Array of relations to delete
  - Each: `{from, to, relationType}`

**Returns:** Confirmation of deletion

**Best for:** Removing incorrect or outdated relationships

**Rate limits:** None

### 7. `read_graph` - View Entire Graph

**What it does:** Returns complete knowledge graph

**Parameters:** None

**Returns:** All entities, relations, observations

**Best for:** Full graph visualization, debugging

**Rate limits:** None

### 8. `search_nodes` - Search Entities

**What it does:** Searches entities by name, type, or observation content

**Parameters:**
- `query` (required) - Search query

**Returns:** Matching entities with details

**Best for:** Finding specific entities or concepts

**Rate limits:** None

### 9. `open_nodes` - Get Specific Entities

**What it does:** Retrieves specific entities by name

**Parameters:**
- `names` (required) - Array of entity names

**Returns:** Requested entities with all details

**Best for:** Getting known entities

**Rate limits:** None

## Tradeoffs

### Advantages
✅ **Explicit relationships** (track who/what/how)
✅ **Graph queries** (find relationships)
✅ **Structured storage** (entities/relations/observations)
✅ **Unlimited** (local JSONL file)
✅ **Persistent** (cross-session)
✅ **Official Anthropic** implementation

### Disadvantages
❌ **No semantic search** (use Qdrant for that)
❌ **Manual management** (not automatic like claude-mem)
❌ **Requires discipline** (must create/update manually)
❌ **No similarity** matching (exact names/queries)

## Common Pitfalls: When NOT to Use

### ❌ Need Semantic/Similarity Search
**Problem:** Memory uses exact matching, not semantic
**Alternative:** Qdrant

**Example:**
```
Bad:  memory.search_nodes("authentication patterns")
      → Requires exact observation text match

Good: qdrant-find("authentication patterns")
      → Semantic search finds JWT, OAuth, etc.
```

### ❌ Simple Note-Taking
**Problem:** Graph structure overkill for unstructured notes
**Alternative:** Qdrant or filesystem

**Example:**
```
Bad:  create_entities for quick notes
Good: qdrant-store or Write to file
```

### ❌ Temporary Context
**Problem:** Permanent storage for ephemeral data
**Alternative:** Conversation context

**Example:**
```
Bad:  create_entities for current session calculations
Good: Keep in conversation context
```

### ❌ Relationships Don't Matter
**Problem:** Graph overhead when relationships aren't needed
**Alternative:** Qdrant

**Example:**
```
Bad:  memory for independent code snippets
Good: qdrant-store for searchable snippets
```

### ❌ Using Passive Voice Relations
**Problem:** Confusing relationship direction
**Alternative:** Active voice

**Example:**
```
Bad:  create_relations({from: "Company", to: "John", relationType: "employs"})
      → Backwards

Good: create_relations({from: "John", to: "Company", relationType: "works_at"})
      → Active voice, clear direction
```

## When Memory MCP IS the Right Choice

✅ **Track relationships** (who → works_at → where)
✅ **Project context** (components, dependencies, owners)
✅ **Personal CRM** (people, companies, connections)
✅ **Dependency graphs** (X → depends_on → Y)
✅ **Structured knowledge** with clear connections

**Decision rule:** "Do relationships between items matter?"

## Usage Patterns

**Create entity with observations:**
```
create_entities([
  {
    name: "John_Smith",
    entityType: "person",
    observations: ["Speaks Spanish", "Prefers async communication"]
  }
])
```

**Create relationships:**
```
create_relations([
  {from: "John_Smith", to: "Anthropic", relationType: "works_at"},
  {from: "John_Smith", to: "ProjectX", relationType: "contributes_to"}
])
```

**Add new facts:**
```
add_observations([
  {
    entityName: "John_Smith",
    contents: ["Expert in TypeScript", "Located in San Francisco"]
  }
])
```

**Query relationships:**
```
search_nodes("works_at Anthropic")
→ Find all people who work at Anthropic

search_nodes("ProjectX")
→ Find all entities related to ProjectX

open_nodes(["John_Smith"])
→ Get John_Smith with all observations and relations
```

**Example graph structure:**
```
Entity: John_Smith (type: person)
    Observations: ["Speaks Spanish", "Async communication"]
    Relations:
        John_Smith --works_at--> Anthropic
        John_Smith --contributes_to--> ProjectX

Entity: ProjectX (type: project)
    Observations: ["React-based", "TypeScript", "Open source"]
    Relations:
        ProjectX --depends_on--> React
        ProjectX --deployed_on--> Vercel

Entity: Anthropic (type: company)
    Observations: ["AI safety research", "San Francisco"]
```

## Best Practices

**Entity naming:**
- Use underscores: `John_Smith`, `ProjectX`
- Unique names: `ProjectX_v2` vs `ProjectX_v1`
- Consistent: Don't mix `John Smith` and `John_Smith`

**Relation types (active voice):**
- ✅ `works_at`, `manages`, `depends_on`, `created_by`
- ❌ `employed_by`, `managed_by`, `is_used_by`

**Observations (atomic):**
- ✅ ["Speaks Spanish", "Graduated 2019"]
- ❌ ["Speaks Spanish and graduated in 2019"]

**Entity types (consistent):**
- Use standard types: `person`, `company`, `project`, `concept`
- Be consistent across graph

**Check before creating:**
```
search_nodes("John_Smith")
→ Check if exists before creating duplicate
```

**Relations are directed:**
```
from: "John" to: "Company" type: "works_at"
≠ from: "Company" to: "John" type: "works_at"
```

## Combining with Qdrant

**Use both for rich knowledge:**
```
Qdrant: Store searchable content (find by meaning)
Memory: Track relationships (X relates to Y)

Example:
  Qdrant: Store "JWT authentication implementation guide"
  Memory: ProjectA --uses--> JWT_pattern --created_by--> John
```

**Workflow:**
```
1. memory: Create entities (people, projects, concepts)
2. memory: Create relations (map dependencies, ownership)
3. qdrant: Store detailed content (code, docs, notes)
4. search: memory for relationships, qdrant for content
```

## Alternatives Summary

| Task | Instead of Memory | Use This |
|------|------------------|----------|
| Semantic search | search_nodes | Qdrant |
| Simple notes | create_entities | Qdrant / Filesystem |
| Temporary data | create_entities | Conversation context |
| No relationships | memory tools | Qdrant |

## Quick Reference

**Rate limits:** None (local JSONL)
**Storage:** JSONL file (local filesystem)
**Persistence:** Across sessions (explicit deletion needed)
**Best for:** Relationships, structured knowledge, graph queries
**Avoid for:** Semantic search, temporary data, simple notes

**Relation direction:** Always active voice (from → to)
**Entity names:** Use underscores, unique identifiers
**Observations:** Atomic facts (one per observation)

**Storage location:** `MEMORY_MCP_STORAGE_PATH` env var or default `~/.memory-mcp/memory.jsonl`

**Links:**
- [Category guide: Memory](../category/memory.md)
- [Full decision guide](../../../tools/tools-decision-guide.md)
