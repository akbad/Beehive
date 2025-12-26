# Brave MCP: Deep Dive

## Overview

Privacy-focused search engine with 5 search types and generous free tier (2,000 queries/month).

## Available Tools

### 1. `brave_web_search` - General Web Search

**What it does:** Standard web search with rich metadata

**Parameters:**
- `query` (required, max 400 chars) - Search query
- `count` (1-20, default 10) - Number of results
- `offset` (0-9) - Pagination offset
- `country` - 2-char code (US, GB, etc.)
- `search_lang` - Language preference (en, es, fr, etc.)
- `safesearch` - "off" | "moderate" | "strict"
- `result_filter` - Array (e.g. `["web", "images", "news", "videos", "discussions", "faq"]`; other values like `"infobox"`, `"query"`, `"summarizer"`, or `"locations"` may appear depending on plan/endpoint)
- `freshness` - "pd" | "pw" | "pm" | "py" | "YYYY-MM-DDtoYYYY-MM-DD"
- `spellcheck` (bool, default true)

**Returns:** JSON list with title, description, URL; may include FAQ, discussions, news, videos

**Best for:** General web searches, alternative to Tavily

**Rate limits:** 2,000 queries/month (free tier)

### 2. `brave_local_search` - Location-Based Search

**What it does:** Search for businesses, places, services

**Parameters:** Same as web search + location awareness

**Returns:** Business names, addresses, ratings, hours, phone numbers

**Best for:** "Near me" queries, local businesses, restaurants

**Rate limits:** Requires Pro plan (not available on free tier)

**Fallback:** Automatically falls back to web search if no local results

### 3. `brave_video_search` - Video Discovery

**What it does:** Search for videos with metadata

**Parameters:**
- `query` (required)
- `count` (1-50, default 20)
- `freshness` - Time filters
- `safesearch`

**Returns:** Videos with title, URL, description, duration, thumbnail

**Best for:** Finding video content, tutorials, talks

**Rate limits:** 2,000 queries/month

### 4. `brave_image_search` - Image Discovery

**What it does:** Search for images

**Parameters:**
- `query` (required)
- `count` (1-200, default 50)
- `safesearch` - "off" | "strict"

**Returns:** Images with URLs, titles, properties

**Best for:** Finding pictures, design inspiration, visual references

**Rate limits:** 2,000 queries/month

### 5. `brave_news_search` - News Articles

**What it does:** Search recent news

**Parameters:**
- `query` (required)
- `count` (1-50, default 20)
- `freshness` - "pd" | "pw" | "pm" | "py" | "YYYY-MM-DDtoYYYY-MM-DD" (no documented default)
- `extra_snippets` (bool) - Up to 5 additional excerpts

**Returns:** News articles with titles, URLs, descriptions, snippets

**Best for:** Current events, breaking news, recent updates

**Rate limits:** 2,000 queries/month

### 6. `brave_summarizer` - AI Summary (Pro Only)

**What it does:** Generate AI summaries of search results

**Parameters:**
- `key` (required) - Summary key from web search
- `inline_references` (bool) - Add source citations
- `entity_info` (bool) - Include entity details

**Returns:** Text summary with optional references

**Best for:** Quick overviews of complex topics

**Rate limits:** Requires Pro AI subscription

## Tradeoffs

### Advantages
✅ Privacy-focused (no tracking/profiling)
✅ Generous free tier (2k/month)
✅ Multiple search types in one MCP
✅ Good fallback when Tavily exhausted
✅ Clean, structured results

### Disadvantages
❌ Local Search and Summarizer require Pro plan
❌ No advanced crawling/extraction (use Tavily)
❌ Pro features require paid plan
❌ No citations included (unlike Tavily)

## Common Pitfalls: When NOT to Use

### ❌ Need Citations
**Problem:** Brave doesn't include source citations
**Alternative:** Tavily (includes citations by default)

**Example:**
```
Bad:  brave_web_search("climate change facts")
Good: tavily_search("climate change facts")  # Returns with citations
```

### ❌ Semantic/Conceptual Search
**Problem:** Brave uses keyword matching, not semantic understanding
**Alternative:** Tavily (better semantic understanding)

**Example:**
```
Bad:  brave_web_search("concepts similar to event sourcing")
Good: tavily_search("concepts similar to event sourcing")
```

### ❌ Content Extraction
**Problem:** Brave only returns search results, not full content
**Alternative:** Tavily extract or Fetch

**Example:**
```
Bad:  brave_web_search + manual extraction
Good: tavily_extract(["url1", "url2"])
```

### ❌ Multi-Page Crawling
**Problem:** Brave doesn't crawl websites
**Alternative:** Tavily crawl

**Example:**
```
Bad:  brave_web_search + trying to crawl results
Good: tavily_crawl("https://docs.example.com")
```

### ❌ Local Search (Free Tier)
**Problem:** Local search requires Pro plan
**Alternative:** Use web search with location terms

**Example:**
```
Bad:  brave_local_search("restaurants") # Fails on free tier
Good: brave_web_search("restaurants in [city]")
```

## When Brave IS the Right Choice

✅ **Tavily credits exhausted** (monthly reset)
✅ **Privacy-focused results** needed
✅ **Basic web search** sufficient
✅ **Video/image discovery** required
✅ **News search** for current events

**Decision rule:** "Is Tavily available? If not, use Brave."

## Alternatives Summary

| Task | Instead of Brave | Use This |
|------|-----------------|----------|
| Search with citations | web_search | Tavily |
| Semantic search | web_search | Exa |
| Content extraction | web_search | Tavily extract / Fetch |
| Multi-page crawl | web_search | Tavily crawl |
| Local businesses | local_search (free) | web_search with location |

## Best Practices

**Use Brave as backup:**
- Primary: Tavily (citations, extraction, crawl)
- Secondary: Brave (basic search when Tavily low)
- Tertiary: Exa (semantic search)

**Optimize queries:**
- Use specific keywords (not semantic)
- Add location terms for local results
- Use `freshness` for time-sensitive queries
- Filter with `result_filter` for specific content types

**Monitor limits:**
- 2k/month resets monthly
- Track usage to avoid exhaustion
- Switch to Fetch for known URLs

**Free tier constraints:**
- Web, Image, Video, and News endpoints are available
- Local Search and Summarizer require Pro; calls to these will fail on free tier
- You can use `result_filter` to scope web results; for full metadata use the dedicated endpoints

## Quick Reference

**Total budget:** 2,000 queries/month
**Rate limits:** Monthly reset
**Reset:** Monthly (varies by account)
**Cost:** Free tier, Pro for advanced features

**Links:**
- [Category guide: Web research](../category/web-research.md)
- [Full decision guide](../../../tools/tools-decision-guide.md)
