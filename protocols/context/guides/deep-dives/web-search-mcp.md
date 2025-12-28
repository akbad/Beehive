# web-search-mcp: Deep Dive

## Overview

Unlimited browser-based web search using Playwright. Serves as the final fallback when all API-based search tools (Tavily, Brave, WebSearchAPI) are exhausted.

**Fallback chain position:** `Tavily → Brave → WebSearchAPI → web-search-mcp`

**Key differentiator:** No rate limits - unlimited queries via real browser execution.

## Available Tools

### 1. `search` - Browser-Based Web Search

**What it does:** Execute web searches using a real browser via Playwright

**Parameters:**
- `query` (required) - Search query
- `engine` - Search engine to use (default: varies)
- `num_results` - Number of results to return

**Returns:** Search results with title, URL, snippet

**Best for:** Unlimited searching when all API quotas exhausted

**Rate limits:** None (unlimited)

**Performance:** Slower than API-based tools (launches browser)

## Tradeoffs

### Advantages
- **Unlimited queries** (no rate limits)
- Real browser execution (handles dynamic content)
- Works when all API quotas exhausted
- No API key required
- Handles CAPTCHAs and bot detection (via real browser)

### Disadvantages
- **Slower** than API-based tools (browser startup overhead)
- Higher resource usage (runs Chromium)
- No citation metadata
- Less structured results than API tools
- Requires Playwright + Chromium installed

## Common Pitfalls: When NOT to Use

### ❌ API Credits Available
**Problem:** Using slow browser search when fast APIs available
**Alternative:** Check Tavily → Brave → WebSearchAPI first

**Example:**
```
Bad:  web-search-mcp search("Python tutorial") # Slow, unnecessary
Good: tavily_search("Python tutorial")  # Fast, with citations
```

### ❌ Speed is Critical
**Problem:** Browser search has significant latency
**Alternative:** Use any available API-based tool

**Example:**
```
Bad:  web-search-mcp for time-sensitive lookups
Good: Brave/WebSearchAPI for faster response
```

### ❌ Need Citations
**Problem:** web-search-mcp doesn't provide citation metadata
**Alternative:** Tavily (includes citations)

**Example:**
```
Bad:  web-search-mcp for research requiring citations
Good: tavily_search for cited sources
```

### ❌ Content Extraction
**Problem:** web-search-mcp is search-only
**Alternative:** crawl4ai or Tavily extract

**Example:**
```
Bad:  web-search-mcp + manual page reading
Good: crawl4ai for content extraction
```

## When web-search-mcp IS the Right Choice

- **All API quotas exhausted** (Tavily + Brave + WebSearchAPI)
- **Need unlimited search capacity**
- **Bot detection issues** with APIs
- **Dynamic/JS search results** needed
- **No time pressure** (can wait for browser)

**Decision rule:** "All APIs exhausted? Use web-search-mcp as unlimited fallback."

## Alternatives Summary

| Task | Instead of web-search-mcp | Use This |
|------|--------------------------|----------|
| Fast search | search | Tavily/Brave/WebSearchAPI |
| Cited sources | search | Tavily |
| Content extraction | search | crawl4ai, Tavily extract |
| Structured results | search | Any API-based tool |

## Best Practices

**Use as last resort:**
1. Primary: Tavily (citations, best features)
2. Secondary: Brave (2k/mo)
3. Tertiary: WebSearchAPI (2k/mo)
4. Fallback: web-search-mcp (unlimited, slowest)

**Optimize for performance:**
- Batch searches when possible
- Use specific queries to reduce result scanning
- Consider caching results for repeated queries

**Resource awareness:**
- Browser consumes more memory than API calls
- Close browser sessions promptly
- Monitor system resources during heavy usage

## Installation Notes

**Dependencies:**
- Node.js
- npm
- Playwright + Chromium

**Auto-installed by Bureau:** Cloned from GitHub, built with npm, Playwright browsers installed automatically on first run.

## Quick Reference

**Total budget:** Unlimited
**Rate limits:** None
**Performance:** Slower than APIs (browser overhead)
**Cost:** Free (local execution)

**Requirements:**
- Node.js runtime
- ~500MB for Chromium browser

**Links:**
- [Category guide: Web research](../by-category/web-research.md)
- [Tools guide](../tools-guide.md)
- [GitHub repo](https://github.com/mrkrsl/web-search-mcp)
