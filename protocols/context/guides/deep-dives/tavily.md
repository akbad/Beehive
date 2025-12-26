# Tavily MCP: Deep Dive

## Overview

Primary web research tool with search, extract, map, and crawl capabilities. Includes citations (critical for credibility). 1,000 credits/month, resets on 1st.

## Available Tools

### 1. `tavily_search` - Web Search with Citations

**What it does:** Search web and return results with source citations

**Parameters:**
- `query` (required) - Search query
- `max_results` (default 5) - Number of results
- `search_depth` - "basic" | "advanced"
- `topic` - "general" | "news" | "finance"
- `include_domains` / `exclude_domains` - Filter by domain
- `include_raw_content` (bool | "markdown" | "text") - Include cleaned HTML
- `include_images` / `include_image_descriptions` (bool)
- `time_range` - "day" | "week" | "month" | "year"
- `start_date` / `end_date` - "YYYY-MM-DD" format
- `country` - Boost results from specific country

**Returns:** Search results with citations, snippets, URLs

**Best for:** General web research with credible sources

**Credits:** Basic = 1 credit; Advanced = 2 credits

### 2. `tavily_extract` - Content Extraction from URLs

**What it does:** Extract clean content from specific URLs

**Parameters:**
- `urls` (required) - Array of URLs to extract
- `extract_depth` - "basic" | "advanced"
- `format` - "markdown" | "text"
- `include_images` (bool)

**Returns:** Extracted content in specified format

**Best for:** Getting full content from known URLs

**Credits:** Varies by complexity and depth

### 3. `tavily_crawl` - Multi-Page Website Crawling

**What it does:** Crawl multiple pages from a website

**Parameters:**
- `url` (required) - Starting URL
- `limit` (default 50) - Total pages to process
- `max_depth` (default 1) - How far from base URL
- `max_breadth` (default 20) - Links per page level
- `select_domains` / `exclude_domains` - Domain filters (regex)
- `select_paths` / `exclude_paths` - Path filters (regex)
- `instructions` - Natural language guidance for crawler
- `extract_depth` - "basic" | "advanced"
- `format` - "markdown" | "text"

**Returns:** Content from multiple pages (truncated to 500 chars/page)
**Returns:** Extracted content (raw content) from multiple pages

**Best for:** Gathering info from related pages (5-20 pages)

**Credits:** Mapping cost + Extraction cost (sum)

**Note:** Crawl combines mapping and extraction. For tighter control, use `tavily_map` to discover URLs first, then `tavily_extract` on selected pages.

### 4. `tavily_map` - Website Structure Discovery

**What it does:** Discover URLs without extracting content

**Parameters:**
- `url` (required) - Root URL
- `limit` - Max URLs to discover
- `max_depth` / `max_breadth` - Discovery limits
- `select_domains` / `exclude_domains` - Domain filters
- `instructions` - Crawler guidance

**Returns:** Array of discovered URLs

**Best for:** Understanding site structure before extraction

**Credits:** Lower than crawl (no content extraction)

## Tradeoffs

### Advantages
✅ **Includes citations** (critical for credibility)
✅ Generous 1k credits/month (resets 1st)
✅ Multiple capabilities (search/extract/crawl/map)
✅ Handles news, general info, current events
✅ Advanced depth options for complex tasks

### Disadvantages
❌ Monthly limit (1k credits)
❌ Credits vary by operation complexity
❌ Not a code/repository search engine (use Sourcegraph)

## Common Pitfalls: When NOT to Use

### ❌ Simple Known URL Fetch
**Problem:** Wastes credits on unlimited-alternative task
**Alternative:** Fetch MCP (unlimited)

**Example:**
```
Bad:  tavily_extract(["https://example.com/article"])
Good: fetch("https://example.com/article")
```

### ❌ Highly Specific Semantic Queries
**Problem:** While Tavily has good general understanding, extremely specific semantic queries may need refinement
**Alternative:** Refine query with more keywords or use broader search

**Example:**
```
Less ideal: tavily_search("concepts similar to CQRS")
Better:     tavily_search("CQRS event sourcing saga pattern microservices")
```

### ❌ Deep Multi-Page Crawl (50+ pages)
**Problem:** Crawl truncates content to 500 chars/page
**Alternative:** Map first, then extract specific pages for better control

**Example:**
```
Bad:  tavily_crawl(url, limit=100)  # Less control, higher cost
Good: tavily_map(url) → tavily_extract([specific_urls])
```

### ❌ Code Search
**Problem:** Tavily searches web, not code repositories
**Alternative:** Sourcegraph

**Example:**
```
Bad:  tavily_search("React hooks examples")
Good: sourcegraph.search("repo:.*react.* use.*Hook")
```

### ❌ Official API Documentation
**Problem:** Tavily returns web results, not structured docs
**Alternative:** Context7

**Example:**
```
Bad:  tavily_search("Next.js App Router API")
Good: context7.get_library_docs("/vercel/next.js", topic="routing")
```

### ❌ Credits Near Exhaustion (<100 remaining)
**Problem:** Risk running out mid-month
**Alternative:** Switch to Brave (2k/month)

**Example:**
```
Bad:  tavily_search (when at 90/1000 credits)
Good: brave_web_search
```

## When Tavily IS the Right Choice

✅ **General web research** needing citations
✅ **Multi-source synthesis** (search + extract)
✅ **Current events** and news
✅ **Site mapping** before selective extraction
✅ **Moderate crawling** (5-20 pages with full extraction workflow)

**Decision rule:** "Do I need citations and have credits available?"

## Alternatives Summary

| Task | Instead of Tavily | Use This |
|------|------------------|----------|
| Single URL | extract | Fetch MCP |
| Deep crawl (50+) | crawl | Map + extract for better control |
| Code search | search | Sourcegraph |
| API docs | search | Context7 |
| Credits low | any tool | Brave |

## Best Practices

**Optimize credit usage:**
- Use `max_results` wisely (default 5 is often enough)
- Start with "basic" depth, escalate to "advanced" if needed
- Use Fetch for known URLs (save credits)
- Monitor credit balance throughout month

**Smart crawling workflow:**
1. `tavily_map` → Discover URLs (lower cost)
2. Filter relevant URLs
3. `tavily_extract` → Get full content from specific pages
4. Use `tavily_crawl` to combine mapping+extraction when you want an end-to-end crawl; prefer Map → Extract for selective, full-content control

**When to use each tool:**
- **Search:** Discovery, research, current info
- **Extract:** Known URLs, full content needed
- **Map:** Site structure, URL discovery
- **Crawl:** Quick overview (accept truncation)

**Citation handling:**
- Always use Tavily when citations matter
- Include source URLs in outputs
- Verify claims against multiple sources

## Quick Reference

**Total budget:** 1,000 credits/month
**Rate limits:** Development 100 RPM; Production 1,000 RPM (Production keys require paid plan or PAYGO)
**Reset:** 1st of every month
**Cost:** Free tier

**Credit costs:**
- Basic search: 1 credit
- Advanced search: 2 credits
- Extract: Basic 1 credit per 5 successful URLs; Advanced 2 credits per 5 successful URLs
- Map: 1 credit per 10 pages; with `instructions`: 2 credits per 10 pages
- Crawl: Mapping cost + Extraction cost (sum)

**Links:**
- [Credit costs detail](https://docs.tavily.com/documentation/api-credits#api-credits-costs)
- [Category guide: Web research](../category/web-research.md)
- [Full decision guide](../../../tools/tools-decision-guide.md)
