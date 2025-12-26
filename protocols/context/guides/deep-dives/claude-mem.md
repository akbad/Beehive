# claude-mem: Deep Dive

## Critical Note

**Claude Code Only** - Requires Claude Code's hook system. Not available for Codex/Gemini CLIs.

## Overview

Automatic persistent memory compression via Claude Code plugin hooks. Zero manual intervention. 7 search tools available.

## How It Works (Automatic)

### 5 Lifecycle Hooks (No Manual Calls)

**1. SessionStart:**
- Injects summaries from last 10 sessions
- Progressive disclosure (token costs visible)
- Layered timeline with color-coded priority

**2. UserPromptSubmit:**
- Creates session record automatically
- Saves raw user prompts for search
- No agent action required

**3. PostToolUse:**
- Fires after EVERY tool execution (Read, Write, Edit, Bash, etc.)
- Captures observations automatically
- No agent intervention needed

**4. Stop:**
- Generates session summaries
- Includes: request, completed, learned, next_steps
- Runs automatically when session pauses

**5. SessionEnd:**
- Marks sessions complete
- Graceful cleanup
- Preserves work across `/clear`

### Worker Service (PM2-Managed)

- Express server on port 37777
- Processes observations via Claude Agent SDK
- Extracts structured learnings (decisions, bugfixes, features, refactors, discoveries, changes)
- Auto-starts when first session begins

### SQLite Database

- Location: `~/.claude-mem/claude-mem.db`
- FTS5 full-text search with SQL injection protection
- Tracks files read/modified, concepts, types, relationships

## Available Search Tools (7 Manual Tools)

### 1. `search_observations` - Full-Text Observation Search

**What it does:** Search across observation titles, narratives, facts, concepts

**Parameters:**
- `query` (required) - FTS5 search query
- `format` (default "index") - "index" | "full"
- `type` - Filter: "decision", "bugfix", "feature", "refactor", "discovery", "change"
- `concepts` - Filter by concept tags
- `files` - Filter by file paths (partial match)
- `project` - Filter by project name
- `dateRange` - Filter by date range
- `limit` (default 20, max 100)
- `offset` (default 0)
- `orderBy` (default "relevance") - "relevance" | "date_desc" | "date_asc"

**Returns:** Observations with metadata

**Best for:** Finding past work, decisions, discoveries

**CRITICAL:** Always start with `format: "index"` (50-100 tokens/result) before `format: "full"` (500-1000 tokens/result)

### 2. `search_sessions` - Full-Text Session Search

**What it does:** Search across session summaries (requests, completions, learnings, notes)

**Parameters:**
- `query` (required)
- `format` (default "index")
- `project`, `dateRange`, `limit`, `offset`, `orderBy`

**Returns:** Session summaries

**Best for:** Finding past sessions, understanding project history

### 3. `search_user_prompts` - Raw User Request Search

**What it does:** Search what user actually said/requested

**Parameters:**
- `query` (required)
- `format` (default "index")
- `project`, `dateRange`, `limit`, `offset`, `orderBy`

**Returns:** User prompts (truncated in index, full in full format)

**Best for:** Tracing user intent → implementation

### 4. `find_by_concept` - Filter by Concept Tags

**What it does:** Find observations tagged with specific concept

**Parameters:**
- `concept` (required) - Concept tag (e.g., "architecture", "security")
- `format` (default "index")
- `project`, `dateRange`, `limit`, `offset`, `orderBy`

**Returns:** Observations with that concept

**Best for:** Topic-based discovery

**CRITICAL:** Start with `limit: 3-5` even in index mode (avoid MCP token limits)

### 5. `find_by_file` - Find Work on Specific Files

**What it does:** Find all observations/sessions referencing a file

**Parameters:**
- `filePath` (required) - File path (supports partial matching)
- `format` (default "index")
- `project`, `dateRange`, `limit`, `offset`, `orderBy`

**Returns:** Observations and sessions related to file

**Best for:** File history, understanding changes

### 6. `find_by_type` - Filter by Observation Type

**What it does:** Find observations of specific type

**Parameters:**
- `type` (required) - "decision" | "bugfix" | "feature" | "refactor" | "discovery" | "change"
- `format` (default "index")
- `project`, `dateRange`, `limit`, `offset`, `orderBy`

**Returns:** Typed observations

**Best for:** Finding all decisions, bugfixes, etc.

### 7. `get_recent_context` - Recent Session Context

**What it does:** Get recent session context for debugging/recovery

**Parameters:**
- `project` (optional, defaults to current directory basename)
- `limit` (default 3, max 10) - Number of recent sessions

**Returns:** Recent sessions and observations

**Best for:** Recovery, understanding recent work

## Tradeoffs

### Advantages
✅ **Fully automatic** (zero intervention)
✅ **Captures everything** (all tool executions)
✅ **Progressive disclosure** (index → full)
✅ **FTS5 full-text search** (powerful queries)
✅ **Typed observations** (decisions, bugfixes, etc.)
✅ **Claude Agent SDK** (AI extraction)

### Disadvantages
❌ **Claude Code only** (requires hooks)
❌ **No manual control** (automatic everything)
❌ **Different from Qdrant/Memory** (FTS5 vs vector/graph)
❌ **Token limits** on search results (use index first)

## Common Pitfalls: When NOT to Use

### ❌ Not Using Index Format First
**Problem:** Full format consumes 10x tokens
**Alternative:** Always start with format: "index"

**Example:**
```
Bad:  search_observations("auth", format: "full")
      → 500-1000 tokens per result

Good: search_observations("auth", format: "index")
      → 50-100 tokens per result
      → Then fetch specific items with full format
```

### ❌ High Limit Without Index
**Problem:** Exceeds MCP token limits
**Alternative:** Start with limit: 3-5, even in index mode

**Example:**
```
Bad:  find_by_concept("architecture", limit: 20)
      → May exceed token limits

Good: find_by_concept("architecture", limit: 5, format: "index")
      → Check results, increase if needed
```

### ❌ Using on Codex/Gemini
**Problem:** claude-mem requires Claude Code hooks
**Alternative:** Manual Qdrant + Memory MCP workflow

**Example:**
```
Bad:  search_observations on Codex
      → Not available

Good: Manual qdrant-store + memory.create_entities workflow
```

### ❌ Expecting Manual Saves
**Problem:** claude-mem is automatic, no manual save
**Alternative:** Qdrant/Memory for manual control

**Example:**
```
Bad:  Trying to manually trigger observation capture
      → Automatic via hooks

Good: Use Qdrant for manual, selective saves
```

### ❌ Graph Queries
**Problem:** claude-mem doesn't support relationship graphs
**Alternative:** Memory MCP

**Example:**
```
Bad:  search_observations for "who created what"
Good: memory.search_nodes for relationship queries
```

## When claude-mem IS the Right Choice

✅ **Claude Code users** (required)
✅ **Automatic context** preservation
✅ **Cross-session memory** without manual saves
✅ **Finding past work/decisions**
✅ **Tracing user intent** → implementation

**Decision rule:** "Am I using Claude Code and need automatic context?"

## Usage Patterns

**Progressive disclosure workflow:**
```
1. search_observations("authentication", format: "index", limit: 5)
   → See titles, dates, concepts (50-100 tokens each)

2. Review index results, pick relevant IDs

3. search_observations("authentication", format: "full")
   → Get full details for specific items (500-1000 tokens each)
```

**Find recent work:**
```
get_recent_context(project: "my-app", limit: 3)
→ Last 3 sessions with summaries
```

**Trace user requests:**
```
search_user_prompts("implement JWT auth")
→ Find when user requested JWT implementation
→ Trace to observations/sessions
```

**Find by type:**
```
find_by_type("decision", limit: 5, format: "index")
→ Recent architectural decisions

find_by_type("bugfix", limit: 5, format: "index")
→ Recent bug fixes
```

**File history:**
```
find_by_file("auth.ts", format: "index")
→ All work on auth.ts file
```

**Concept-based:**
```
find_by_concept("security", limit: 5, format: "index")
→ Security-related observations
```

## Codex/Gemini Replication

**Since claude-mem requires hooks, manually replicate with Qdrant + Memory:**

**Manual observation logging:**
- After reading code → qdrant-store discoveries
- After decisions → memory.create_entities with relations
- After fixes → qdrant-store bugfix notes

**Session summaries:**
- Before ending → Create summary, qdrant-store
- Include: request, completed, learned, next_steps

**Context recovery:**
- Start sessions → qdrant-find for past work
- Fetch relations from Memory MCP

**Key differences:**
- claude-mem: automatic, zero intervention
- Qdrant+Memory: manual, requires discipline
- claude-mem: FTS5 search, Qdrant: vector search
- claude-mem: typed observations, manual tagging needed

## Alternatives Summary

| Task | Instead of claude-mem | Use This |
|------|--------------------|----------|
| Manual control | claude-mem | Qdrant / Memory |
| Codex/Gemini | claude-mem | Qdrant + Memory workflow |
| Graph queries | search | Memory MCP |
| Semantic search | search | Qdrant |

## Best Practices

**Always use index first:**
- Start with `format: "index"`
- Review results
- Fetch full details only for relevant items

**Limit wisely:**
- Even in index mode, start with `limit: 3-5`
- Increase if needed
- Watch for token limit warnings

**Use appropriate search:**
- `search_observations`: General work/decisions/discoveries
- `search_sessions`: Session-level context
- `search_user_prompts`: Trace user requests
- `find_by_concept`: Topic-based
- `find_by_file`: File-specific history
- `find_by_type`: Decision/bugfix/feature/etc.

**Citations:**
- Results use `claude-mem://` URIs
- Include in outputs for traceability

## Quick Reference

**Availability:** Claude Code only (requires hooks)
**Storage:** SQLite (`~/.claude-mem/claude-mem.db`)
**Search:** FTS5 full-text search
**Best for:** Automatic context preservation (Claude Code users)
**Avoid for:** Manual control, Codex/Gemini, graph queries

**Critical pattern:** Always `format: "index"` first, then `format: "full"`
**Token costs:** Index 50-100/result, Full 500-1000/result

**Links:**
- [GitHub repo: thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)
- [Category guide: Memory](../category/memory.md)
- [Full decision guide](../../../tools/tools-decision-guide.md)
