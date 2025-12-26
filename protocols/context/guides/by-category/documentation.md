# API documentation tools: Context7 usage guide

## Overview

**Context7** is the primary tool for retrieving up-to-date, version-specific API documentation and code examples.

## Quick reference

| Aspect | Details |
|--------|---------|
| **Best for** | Official docs, library syntax, API examples |
| **Coverage** | Public repos only (free tier) |
| **Rate limits** | Plan-based: Free lower, Pro higher, Enterprise custom |
| **Strengths** | Version-specific, official sources, code examples |

## What Context7 does

**Fetches:**
- Up-to-date API documentation
- Version-specific syntax and examples
- Official library/framework docs
- Code snippets from official sources

**Works with:**
- Public repositories (GitHub, npm, PyPI, etc.)
- Major frameworks (React, Vue, Angular, Express, etc.)
- Libraries and SDKs
- API documentation sites

## When to use

**Primary use cases:**
- Learning a new library/framework
- Checking current API syntax
- Getting official usage examples
- Understanding library capabilities
- Verifying breaking changes between versions

**Examples:**
```
"Get React 18 hooks documentation"
→ Returns official React docs for version 18 hooks

"Show Express.js router API"
→ Fetches Express router documentation

"Next.js 14 app router examples"
→ Gets version-specific App Router docs

"Pandas DataFrame API"
→ Returns pandas DataFrame official docs
```

## Workflow

**1. Resolve library ID (required first step):**
```
resolve-library-id → Get Context7-compatible ID
```

**2. Fetch documentation:**
```
get-library-docs with:
- context7CompatibleLibraryID (from step 1)
- topic (optional, focuses results)
- tokens (default: 5000, max controls length)
```

**Example flow:**
```
Step 1: resolve-library-id("Next.js")
        → Returns: "/vercel/next.js"

Step 2: get-library-docs("/vercel/next.js", topic="routing")
        → Returns routing documentation
```

## Parameters

**resolve-library-id:**
- `libraryName` - Package/library name to search

**get-library-docs:**
- `context7CompatibleLibraryID` - ID from resolve step (required)
- `topic` - Focus area (e.g., "hooks", "routing") (optional)
- `tokens` - Max tokens to return (default: 5000) (optional)

## Best practices

**Always resolve first:** Must call `resolve-library-id` before `get-library-docs` (unless user provides ID in `/org/project` format)

**Be specific with topics:** Use focused topics to get relevant docs
- ✅ `topic="hooks"` → React hooks docs
- ✅ `topic="middleware"` → Express middleware docs
- ❌ `topic="everything"` → Too broad

**Adjust token limit wisely:**
- Default 5000 works for most cases
- Increase for comprehensive docs
- Decrease for quick lookups

**Version-specific queries:**
- Specify version when known: "React 18", "Next.js 14"
- Context7 returns version-appropriate docs

## When *not* to use

**Use other tools when:**
- Need code examples from real projects → Sourcegraph
- Want community solutions → Web research (Tavily/Brave)
- Looking for blog posts/tutorials → Web research
- Need private repo docs → Not supported (requires paid tier)
- Simple web search → Web research tools

## Common use cases

**API syntax lookup:**
→ Context7 (`resolve-library-id` + `get-library-docs`)

**Real-world usage examples:**
→ Sourcegraph (search public repos)

**Best practices and patterns:**
→ Web research (Tavily for articles)

**Version migration guides:**
→ Context7 (official docs) + Web research (community guides)

## Integration with other tools

**Typical workflow:**
1. Context7 → Get official API docs
2. Sourcegraph → Find real-world usage examples
3. Web research → Find tutorials/guides if needed

**Example:**
```
Task: "Learn how to use React Server Components"

1. Context7: Get official React 18 server components docs
2. Sourcegraph: Find real implementations in public repos
3. Tavily: Find blog posts explaining concepts
```

## Limitations

**Free tier restrictions:**
- Public repositories only
- Private/org repos require paid plan

**Not a substitute for:**
- Code search (use Sourcegraph)
- Web tutorials (use Tavily/Brave)
- Community Q&A (use web research)

## Quick decision tree

```
Need documentation?
    ↓
Official API docs?
    ├─ YES → Context7
    └─ NO  → Community examples?
        ├─ YES → Sourcegraph
        └─ NO  → Tutorials/guides?
            └─ YES → Web research (Tavily)
```

## Common mistakes to avoid

❌ Skipping `resolve-library-id` (required first step)
❌ Using for community content (use web research)
❌ Using for private repos (not supported on free tier)
❌ Not specifying topic (get irrelevant broad docs)
❌ Using for real-world repo examples (use Sourcegraph). Context7 is for official docs and examples

## Links to deep dives

- [Context7: *full guide*](../deep-dives/context7.md)

