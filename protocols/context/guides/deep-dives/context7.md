# Context7 MCP: Deep Dive

## Overview

Fetches up-to-date, version-specific API documentation and code examples from official sources. Public repos only on free tier.

## Available Tools

### 1. `resolve-library-id` - Get Context7 Library ID

**What it does:** Converts package/library name to Context7-compatible ID

**Parameters:**
- `libraryName` (required) - Name to search (e.g., "Next.js", "React", "pandas")

**Returns:** List of matching libraries with Context7 IDs

**Best for:** Finding the correct library ID before fetching docs

**Rate limits:** None apparent

**Required:** Must call before `get-library-docs` (unless user provides ID in `/org/project` format)

### 2. `get-library-docs` - Fetch Documentation

**What it does:** Retrieves official documentation for a library

**Parameters:**
- `context7CompatibleLibraryID` (required) - ID from resolve step or `/org/project` format
- `topic` (optional) - Focus area (e.g., "hooks", "routing", "authentication")
- `tokens` (optional, default 5000) - Max tokens to return

**Returns:** Official documentation with code examples

**Best for:** Learning APIs, checking syntax, getting official examples

**Rate limits:** None apparent (free tier)

## Tradeoffs

### Advantages
✅ **Version-specific docs** (accurate for specific versions)
✅ **Official sources** (authoritative)
✅ **Code examples included** (from official docs)
✅ **No apparent limits** (free tier)
✅ **Focused topics** (narrow results to relevant sections)

### Disadvantages
❌ **Public repos only** (free tier restriction)
❌ **Not for code search** (use Sourcegraph)
❌ **Not for tutorials** (use web search)
❌ **Requires two-step** process (resolve → fetch)

## Common Pitfalls: When NOT to Use

### ❌ Real-World Code Examples
**Problem:** Context7 returns official docs, not real usage
**Alternative:** Sourcegraph

**Example:**
```
Bad:  get-library-docs for real-world examples
Good: sourcegraph.search("repo:.*react.* useEffect")
```

### ❌ Community Tutorials/Guides
**Problem:** Context7 fetches official docs, not blog posts
**Alternative:** Tavily

**Example:**
```
Bad:  resolve-library-id("React tutorial")
Good: tavily_search("React hooks tutorial")
```

### ❌ Private/Organization Libraries
**Problem:** Free tier only supports public repos
**Alternative:** Clone docs + Read tool

**Example:**
```
Bad:  resolve-library-id("internal-company-lib")
Good: Clone docs repo → Read files
```

### ❌ Non-Documentation Content
**Problem:** Context7 fetches docs, not code/tests/examples
**Alternative:** Sourcegraph or clone repo

**Example:**
```
Bad:  get-library-docs for test examples
Good: sourcegraph.search("file:test repo:library")
```

### ❌ General Web Search
**Problem:** Context7 is for specific library docs
**Alternative:** Tavily or Brave

**Example:**
```
Bad:  resolve-library-id("best practices for React")
Good: tavily_search("React best practices 2024")
```

### ❌ Skip Resolve Step
**Problem:** get-library-docs requires exact Context7 ID
**Alternative:** Always call resolve-library-id first

**Example:**
```
Bad:  get-library-docs("React")  # Wrong ID format
Good: resolve-library-id("React") → get-library-docs("/facebook/react")
```

## When Context7 IS the Right Choice

✅ **Official API documentation** needed
✅ **Version-specific syntax** required
✅ **Learning new library/framework**
✅ **Checking current API**
✅ **Getting official examples**

**Decision rule:** "Do I need official, authoritative documentation?"

## Usage Patterns

**Two-step workflow (required):**
```
Step 1: resolve-library-id("Next.js")
        → Returns: {id: "/vercel/next.js", ...}

Step 2: get-library-docs("/vercel/next.js", topic="routing")
        → Returns: Official Next.js routing documentation
```

**Version-specific queries:**
```
resolve-library-id("React 18")
→ get-library-docs with React 18 docs

resolve-library-id("Next.js 14")
→ get-library-docs with Next.js 14 docs
```

**Focused topic retrieval:**
```
get-library-docs("/vercel/next.js", topic="app router")
get-library-docs("/facebook/react", topic="hooks")
get-library-docs("/expressjs/express", topic="middleware")
```

**Adjust token limit:**
```
get-library-docs(id, topic, tokens=10000)  # More context
get-library-docs(id, topic, tokens=2000)   # Quick lookup
```

**User-provided ID (skip resolve):**
```
If user says: "Get docs for /vercel/next.js"
→ Skip resolve-library-id
→ Direct: get-library-docs("/vercel/next.js")
```

## Integration Workflow

**Typical learning workflow:**
```
1. Context7: Get official API docs
2. Sourcegraph: Find real-world usage examples
3. Tavily: Find tutorials/guides if needed
```

**Example:**
```
Task: "Learn React Server Components"

Step 1: resolve-library-id("React")
        → /facebook/react

Step 2: get-library-docs("/facebook/react", topic="server components")
        → Official React docs on Server Components

Step 3: sourcegraph.search("repo:.*react.* server component")
        → Real implementations in public repos

Step 4: tavily_search("React server components tutorial")
        → Blog posts explaining concepts
```

## Selection Logic for resolve-library-id

**When results have multiple matches:**
- Prioritize exact name matches
- Consider description relevance
- Check documentation coverage (higher is better)
- Verify trust score (7-10 more authoritative)

**Return format:**
- Selected library ID clearly marked
- Brief explanation for choice
- Acknowledge other matches if relevant

## Alternatives Summary

| Task | Instead of Context7 | Use This |
|------|-------------------|----------|
| Real-world examples | get-library-docs | Sourcegraph |
| Tutorials/guides | get-library-docs | Tavily |
| Private libraries | get-library-docs | Clone + Read |
| Code search | get-library-docs | Sourcegraph |
| General web search | resolve-library-id | Tavily / Brave |

## Best Practices

**Always resolve first:**
- Call `resolve-library-id` before `get-library-docs`
- Exception: User provides `/org/project` format

**Use focused topics:**
- Narrow results to relevant sections
- Examples: "hooks", "routing", "authentication"
- More specific = more relevant results

**Adjust token limits:**
- Default 5000 works for most cases
- Increase for comprehensive docs (up to 50000)
- Decrease for quick lookups (down to 1000)

**Version-specific queries:**
- Include version in library name when known
- "React 18", "Next.js 14", "Vue 3"
- Context7 returns version-appropriate docs

**Combine with other tools:**
- Context7 → Official docs
- Sourcegraph → Real usage
- Tavily → Tutorials/best practices

## Quick Reference

**Rate limits:** None apparent (free tier)
**Coverage:** Public repos only
**Best for:** Official API docs, version-specific syntax
**Avoid for:** Real examples, tutorials, private libs

**Required workflow:** resolve-library-id → get-library-docs

**Links:**
- [Category guide: Documentation](../category/documentation.md)
- [Full decision guide](../../../tools/tools-decision-guide.md)
