# WebSearchAPI MCP: Deep Dive

## Overview

Google-quality search results via websearchapi.ai with 2,000 queries/month free tier. Serves as a tertiary fallback in the search chain after Tavily and Brave are exhausted.

**Fallback chain position:** `Tavily → Brave → WebSearchAPI → web-search-mcp`

## Available Tools

### 1. `websearch` - Google-Quality Web Search

**What it does:** Search the web with Google-quality results

**Parameters:**
- `query` (required) - Search query
- `num_results` (1-20, default 10) - Number of results
- `country` (default "us") - Country code for localized results

**Returns:** JSON list with title, URL, snippet for each result

**Best for:** High-quality search results when Tavily/Brave exhausted

**Rate limits:** 2,000 queries/month (free tier)

### 2. `extract_content` - Clean Content Extraction

**What it does:** Extract clean text from a URL, removing boilerplate, ads, navigation

**Parameters:**
- `url` (required) - URL to extract content from

**Returns:** Clean text content with optional title

**Best for:** Getting article content without clutter

**Rate limits:** Counted toward 2,000 queries/month

## Tradeoffs

### Advantages
- Google-quality search results
- Clean extraction (removes boilerplate)
- Fast API response times
- Extends API search capacity by +2K/mo
- Simple, focused API (just search + extract)

### Disadvantages
- No citations (unlike Tavily)
- No crawling capability
- No news/video/image-specific search
- Third in priority chain (use Tavily/Brave first)
- Requires API key setup

## Common Pitfalls: When NOT to Use

### ❌ Tavily or Brave Credits Available
**Problem:** Using WebSearchAPI when higher-priority tools available
**Alternative:** Check Tavily first, then Brave

**Example:**
```
Bad:  websearch("React 19 features") # Skip if Tavily available
Good: tavily_search("React 19 features") # Use Tavily for citations
```

### ❌ Need Citations
**Problem:** WebSearchAPI doesn't include source citations
**Alternative:** Tavily (includes citations by default)

**Example:**
```
Bad:  websearch("climate science facts")
Good: tavily_search("climate science facts")  # Returns with citations
```

### ❌ Need Multi-Page Crawling
**Problem:** WebSearchAPI extracts single pages, doesn't crawl
**Alternative:** Tavily crawl

**Example:**
```
Bad:  Multiple extract_content calls to crawl a site
Good: tavily_crawl("https://docs.example.com")
```

### ❌ JS-Rendered Content
**Problem:** extract_content may not handle dynamic JS content
**Alternative:** crawl4ai for JS rendering

**Example:**
```
Bad:  extract_content("https://spa-app.com/article")
Good: crawl4ai for JS-heavy pages
```

## When WebSearchAPI IS the Right Choice

- **Tavily + Brave exhausted** (extends monthly capacity)
- **Quality matters** but speed less critical
- **Simple search + extract** workflow
- **Before falling back to web-search-mcp** (API faster than browser)

**Decision rule:** "Tavily and Brave exhausted? Use WebSearchAPI before web-search-mcp."

## Alternatives Summary

| Task | Instead of WebSearchAPI | Use This |
|------|------------------------|----------|
| Search with citations | websearch | Tavily |
| Multi-page crawl | extract_content | Tavily crawl |
| JS-rendered extraction | extract_content | crawl4ai |
| Unlimited search | websearch | web-search-mcp |
| News-specific search | websearch | Brave news |

## Best Practices

**Use in the right order:**
1. Primary: Tavily (citations, crawl, extract)
2. Secondary: Brave (2k/mo backup)
3. Tertiary: WebSearchAPI (Google-quality, +2k/mo)
4. Fallback: web-search-mcp (unlimited, slower)

**Optimize queries:**
- Use specific keywords
- Leverage country parameter for localized results
- Combine search + extract for full workflow

**Monitor limits:**
- 2k/month reset varies by account
- Track usage across Tavily + Brave + WebSearchAPI
- Switch to web-search-mcp when all exhausted

## Quick Reference

**Total budget:** 2,000 queries/month
**Rate limits:** Monthly reset
**Reset:** Monthly (varies by account)
**Cost:** Free tier

**Environment:** Requires `WEBSEARCHAPI_KEY` env var

**Links:**
- [Category guide: Web research](../by-category/web-research.md)
- [Tools guide](../tools-guide.md)
