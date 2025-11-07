# Sourcegraph MCP: Deep Dive

## Overview

"Google for code" - Search across public open-source repositories (indexed on Sourcegraph Cloud) with powerful filters. Unlimited searches on free tier.

## Available Tools

### 1. `search_prompt_guide` - Query Construction Helper

**What it does:** Generates Sourcegraph-specific query guide

**Parameters:**
- `objective` (required) - What you're trying to find

**Returns:** Custom guide for constructing effective searches

**Best for:** Learning query syntax, complex search construction

**Rate limits:** None

**Important:** MUST call this ONCE at beginning before any search or fetch_content

### 2. `search` - Code Search Across Repos

**What it does:** Search code with powerful filters

**Parameters:**
- `query` (required) - Search query with filters

**Query Syntax:**
- Default: Searches file content
- `repo:pattern` - Filter by repo (regex)
- `file:pattern` - Filter by file path
- `lang:language` - Filter by language
- `type:symbol` - Search for symbols (functions/classes)
- Boolean: `AND`, `OR`, `-` (negation)
- Quotes: `"exact phrase"`
- Regex: Full regex support

**Returns:** Search results with file paths, line numbers, code snippets

**Best for:** Finding code examples, patterns, implementations

**Rate limits:** None (free tier for public repos)

### 3. `fetch_content` - Get File Content

**What it does:** Fetch file or directory content from repository

**Parameters:**
- `repo` (required) - Repository path (e.g., "github.com/org/project")
- `path` - File or directory path (empty for root)

**Returns:**
- If file: File content
- If directory/empty: Directory tree (depth 2)

**Best for:** Exploring repo structure, reading specific files

**Rate limits:** None

**Workflow:**
1. Search to find repos
2. Fetch root ("") to see structure
3. Fetch specific files

## Tradeoffs

### Advantages
✅ **Unlimited searches** (no rate limits on free tier)
✅ **Powerful regex filters** (repo, file, lang)
✅ **Guided search prompts** (natural → precise queries)
✅ **Returns exact code** with line numbers
✅ **Symbol search** (find functions/classes)
✅ **No credit tracking** needed

### Disadvantages
❌ **Public repos only** (free tier)
❌ **No web search** (code only)
❌ **No content extraction** from web
❌ **Private repos** require paid plan

## Common Pitfalls: When NOT to Use

### ❌ Web Content Search
**Problem:** Sourcegraph searches code, not web pages
**Alternative:** Tavily or Brave

**Example:**
```
Bad:  search("React hooks tutorial blog")
Good: tavily_search("React hooks tutorial blog")
```

### ❌ Official Documentation
**Problem:** Sourcegraph finds code examples, not structured docs
**Alternative:** Context7

**Example:**
```
Bad:  search("Next.js API documentation")
Good: context7.get_library_docs("/vercel/next.js")
```

### ❌ Private Repository Search
**Problem:** Free tier only searches public repos
**Alternative:** Clone locally + Serena MCP

**Example:**
```
Bad:  search("repo:private-org/private-repo")
Good: Clone locally → serena.find_symbol
```

### ❌ Non-Code Content
**Problem:** Sourcegraph indexes code, not docs/images/data
**Alternative:** Clone repo + Filesystem MCP

**Example:**
```
Bad:  search("README content")
Good: fetch("https://raw.githubusercontent.com/user/repo/main/README.md")
```

### ❌ Semantic/Conceptual Search
**Problem:** Sourcegraph uses regex/text matching, not semantic
**Alternative:** Use natural language in guide or Tavily for broader search

**Example:**
```
Bad:  search("patterns similar to observer")
Good: Use search_prompt_guide with objective, get specific query
```

## When Sourcegraph IS the Right Choice

✅ **Finding code examples** from public repos
✅ **Learning library usage** in the wild
✅ **Discovering implementations** of algorithms
✅ **Researching patterns** across projects
✅ **Symbol search** (functions, classes)
✅ **Unlimited usage** needed (no limits)

**Decision rule:** "Am I looking for code examples from public repos?"

## Usage Patterns

**Always start with guide:**
```
search_prompt_guide("find React hooks with cleanup functions")
→ Returns query syntax guidance
→ Use returned pattern in search
```

**Basic code search:**
```
search("useState lang:typescript")
→ Finds useState usage in TypeScript
```

**Repository filter:**
```
search("repo:github\\.com/facebook/react file:\\.tsx$ useState")
→ React repo, .tsx files, useState usage
```

**Symbol search:**
```
search("type:symbol func SendMessage lang:go")
→ Find SendMessage function definitions in Go
```

**Exclude patterns:**
```
search("authentication -file:test lang:python")
→ Find auth code, exclude test files
```

**Complex query:**
```
search("\"async def.*request\" lang:python file:api/")
→ Async functions with "request" in name, in api/ directory
```

**Workflow with fetch_content:**
```
1. search("repo:user/project type:repo")
   → Find repository

2. fetch_content(repo="github.com/user/project", path="")
   → Get root structure

3. fetch_content(repo="github.com/user/project", path="src/main.py")
   → Read specific file
```

## Search Operators Reference

| Operator | Example | Purpose |
|----------|---------|---------|
| `repo:` | `repo:github\\.com/org/project` | Filter by repository |
| `file:` | `file:\\.go$` or `file:src/` | Filter by file path |
| `lang:` | `lang:python` | Filter by language |
| `type:symbol` | `type:symbol` | Search symbols only |
| `-` | `-file:test` | Exclude pattern |
| `AND` / `OR` | `error AND handler` | Boolean logic |
| `""` | `"func SendMessage"` | Exact phrase |

## Alternatives Summary

| Task | Instead of Sourcegraph | Use This |
|------|----------------------|----------|
| Web search | search | Tavily / Brave |
| API documentation | search | Context7 |
| Private repos | search | Clone + Serena |
| Non-code files | search | Clone + Filesystem |
| Semantic search | search | Tavily / use guided prompts |

## Best Practices

**Leverage guided prompts:**
- Call `search_prompt_guide` first (required once)
- Describe what you want in natural language
- Get precise query syntax
- Iterate with guide if needed

**Build effective queries:**
- Start broad, narrow with filters
- Use regex for precise patterns
- Combine operators (repo + lang + file)
- Exclude test files with `-file:test`

**Explore before extracting:**
1. Search repos: `repo:name type:repo`
2. Fetch root to see structure
3. Search within repo
4. Fetch specific files

**Common patterns:**
```
Find function definitions:
  type:symbol "func functionName" lang:language

Find usage examples:
  "libraryName.method" lang:language -file:test

Find patterns in specific repo:
  repo:org/project pattern lang:language
```

## Quick Reference

**Rate limits:** None (unlimited on free tier)
**Coverage:** Public open-source repositories (Sourcegraph Cloud public index)
**Best for:** Code examples, learning usage, finding implementations
**Avoid for:** Web content, docs, private repos, semantic search

**Required first step:** Call `search_prompt_guide` once at start

**Links:**
- [Sourcegraph Public Code Search](https://sourcegraph.com/search)
- [Category guide: Code search](../category/code-search.md)
- [Full decision guide](../../../tools/tools-decision-guide.md)
