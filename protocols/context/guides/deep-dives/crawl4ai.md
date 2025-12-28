# crawl4ai MCP: Deep Dive

## Overview

Quality content extraction with JS rendering and intelligent boilerplate removal. Docker-based with zero local dependencies. Ideal for extracting clean content from dynamic, JavaScript-heavy, or cluttered web pages.

**Primary use case:** Extraction, not search. Use alongside search tools.

**Key differentiator:** Handles JS-rendered pages and removes boilerplate intelligently.

## Available Tools

### 1. `crawl` - Smart Content Extraction

**What it does:** Extract clean content from URLs with JS rendering and boilerplate removal

**Parameters:**
- `url` (required) - URL to extract content from
- `wait_for` - CSS selector to wait for (for dynamic content)
- `extract_media` - Include images/videos in extraction
- `timeout` - Max wait time for page load

**Returns:** Clean markdown/text content with main article text

**Best for:**
- JavaScript-rendered single-page apps (SPAs)
- Cluttered pages with ads/navigation
- Dynamic content that Fetch can't handle

**Rate limits:** Unlimited (local Docker execution)

### 2. `screenshot` - Visual Capture

**What it does:** Capture screenshot of rendered page

**Parameters:**
- `url` (required) - URL to screenshot
- `full_page` - Capture entire scrollable page

**Returns:** Screenshot image

**Best for:** Visual verification, debugging, capturing dynamic content

## Tradeoffs

### Advantages
- **JS rendering** (handles SPAs, dynamic content)
- **Intelligent boilerplate removal** (ads, navigation, footers)
- **Unlimited usage** (no rate limits)
- **Zero local deps** (Docker handles everything)
- Clean, readable output format

### Disadvantages
- **Slower** than Fetch (browser rendering)
- Requires Docker running
- **No search capability** (extraction only)
- Higher resource usage than simple Fetch
- Docker image size (~1GB)

## Common Pitfalls: When NOT to Use

### ❌ Static HTML Pages
**Problem:** Using crawl4ai for simple static pages
**Alternative:** Fetch is faster and simpler

**Example:**
```
Bad:  crawl4ai("https://example.com/static.html")  # Overkill
Good: fetch("https://example.com/static.html")    # Faster
```

### ❌ Need to Search
**Problem:** crawl4ai doesn't search, only extracts
**Alternative:** Use search tools (Tavily, Brave, etc.)

**Example:**
```
Bad:  Trying to find content with crawl4ai
Good: tavily_search("query") → then crawl4ai for extraction
```

### ❌ Multiple Pages/Crawling
**Problem:** crawl4ai extracts single pages, doesn't follow links
**Alternative:** Tavily crawl for multi-page

**Example:**
```
Bad:  Multiple crawl4ai calls to manually crawl
Good: tavily_crawl("https://docs.example.com")
```

### ❌ Raw File Content
**Problem:** Using crawl4ai to get raw files (code, data)
**Alternative:** Fetch with raw URLs

**Example:**
```
Bad:  crawl4ai("https://raw.githubusercontent.com/...")
Good: fetch("https://raw.githubusercontent.com/...")
```

### ❌ Docker Not Available
**Problem:** crawl4ai requires Docker
**Alternative:** WebSearchAPI extract_content or Tavily extract

**Example:**
```
Bad:  crawl4ai when Docker not running
Good: Check Docker first, fallback to alternatives
```

## When crawl4ai IS the Right Choice

- **JavaScript-rendered content** (SPAs, React/Vue/Angular apps)
- **Cluttered pages** (heavy ads, navigation, sidebars)
- **Fetch returns garbage** (minified HTML, no content)
- **Need clean article text** without boilerplate
- **Unlimited extraction** needed

**Decision rule:** "Is the page JS-heavy or cluttered? Is Fetch not working? Use crawl4ai."

## Alternatives Summary

| Task | Instead of crawl4ai | Use This |
|------|---------------------|----------|
| Static page extraction | crawl | Fetch |
| Multi-page crawl | crawl | Tavily crawl |
| Search | crawl | Tavily/Brave/WebSearchAPI |
| Raw file content | crawl | Fetch with raw URL |
| API extraction | crawl | WebSearchAPI extract_content |

## Best Practices

**Extraction decision tree:**
1. Static page? → Fetch (fastest)
2. JS-rendered? → crawl4ai
3. Multiple URLs? → Tavily extract
4. Need search first? → Search → then extract

**Optimize performance:**
- Use `wait_for` to specify when content is ready
- Set appropriate timeouts for slow pages
- Don't use for pages Fetch can handle

**Docker management:**
- Ensure Docker is running before use
- Image auto-pulled on first use (~1GB)
- Container runs and exits per request

## Installation Notes

**Requirements:**
- Docker installed and running
- ~1GB disk space for image

**Auto-installed by Bureau:** Docker image pulled automatically on first run.

**Docker image:** `uysalsadi/crawl4ai-mcp-server:latest`

## Quick Reference

**Total budget:** Unlimited
**Rate limits:** None
**Performance:** Slower than Fetch (browser rendering)
**Cost:** Free (local Docker)

**Requirements:**
- Docker daemon running
- ~1GB for Docker image

**Comparison with Fetch:**

| Feature | Fetch | crawl4ai |
|---------|-------|----------|
| JS rendering | No | Yes |
| Boilerplate removal | No | Yes |
| Speed | Fast | Slower |
| Dependencies | None | Docker |
| Rate limits | None | None |

**Links:**
- [Category guide: Web research](../by-category/web-research.md)
- [Tools guide](../tools-guide.md)
- [Docker Hub](https://hub.docker.com/r/uysalsadi/crawl4ai-mcp-server)
