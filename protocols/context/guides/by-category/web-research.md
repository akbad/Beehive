# Web research tools: comparison & usage guides

## Quick selection table

| Tool | Best For | Limit | When to Use | Avoid When |
|------|----------|-------|-------------|-----------|
| **Tavily** | General web + citations | 1k/mo | Current info, multi-source research | Credits low |
| **Brave** | Privacy search | 2k/mo | Tavily exhausted, basic search | Need advanced features |
| **WebSearchAPI** | Google-quality results | 2k/mo | Tavily+Brave exhausted, need quality | All quotas available |
| **web-search-mcp** | Unlimited browser search | ∞ | All API quotas exhausted | Speed matters |
| **crawl4ai** | Quality extraction | ∞ | JS rendering, clean extraction | Simple static pages |
| **Fetch** | Simple URL fetch | ∞ | Known URL, simple content | Need search/crawl |

## Tool usage guides

### Tavily (primary choice)

**Strengths:**
- Citations included (critical for credibility)
- Search + extract + map + crawl in one tool
- Generous 1k credits/month (resets 1st)
- Handles news, current events, general info

**Common Parameters:**
- `search` - Query with citations (1–2 credits; basic=1, advanced=2)
- `extract` - Get content from URLs (varies)
- `map` - Discover site structure
- `crawl` - Multi-page content

**Examples:**
```
"Latest React 19 features" → search with citations
"Extract content from example.com/article" → extract
"Map all docs at docs.example.com" → map
```

**When NOT to use:** Credits < 100 remaining → switch to Brave

### Brave (secondary choice)

**Strengths:**
- Privacy-focused, no tracking
- 2k queries/month
- Multiple search types (web/news/image/video; Local API on Pro)
- Good general-purpose fallback

**Limitations:**
- Free plan includes Web/Images/Videos/News/Discussions/FAQ; Local API requires Pro
- No advanced crawling/extraction

**Examples:**
```
"Python asyncio tutorial" → web search
"Restaurants near me" → local search (if Pro)
"AI news today" → news search
```

**When to use:** After Tavily credits exhausted, need basic search

### WebSearchAPI (tertiary choice)

**Strengths:**
- Google-quality search results
- 2k queries/month (extends API capacity)
- Clean JSON response format
- Content extraction included

**Tools:**
- `websearch` - Search query (returns title, URL, snippet)
- `extract_content` - Extract clean text from URL (removes boilerplate)

**Examples:**
```
"GraphQL best practices 2024" → websearch
"Extract content from blog.example.com/post" → extract_content
```

**When to use:** After Tavily + Brave exhausted, need quality results before slow fallback

**When NOT to use:** Tavily or Brave credits available (prefer those first)

### web-search-mcp (unlimited fallback)

**Strengths:**
- Unlimited queries (no rate limits)
- Real browser execution via Playwright
- Handles dynamic/JS-rendered content
- Works when all API quotas exhausted

**Limitations:**
- Slower than API-based tools (launches browser)
- Higher resource usage
- No citation metadata

**Examples:**
```
"Latest Rust async patterns" → search
"Find React 19 migration guides" → search
```

**When to use:** All API quotas exhausted (Tavily + Brave + WebSearchAPI)

**When NOT to use:** Speed is critical; any API quota available

### crawl4ai (quality extraction)

**Strengths:**
- JS rendering for dynamic content
- Intelligent boilerplate removal
- Handles complex page structures
- Docker-based (zero local deps)
- Unlimited usage

**Limitations:**
- Requires Docker
- No search capability (extraction only)
- Slower than simple Fetch

**Examples:**
```
"Extract article from spa-site.com/article" → crawl (JS rendered)
"Get clean content from cluttered-blog.com" → crawl (boilerplate removed)
```

**When to use:** Dynamic/JS pages, need clean extraction, Fetch not working

**When NOT to use:** Static pages where Fetch works fine

### Fetch (simple fallback)

**Strengths:**
- Unlimited usage
- HTML → Markdown conversion
- Chunk reading via start_index
- No rate limits

**Limitations:**
- For raw file contents from GitHub, use raw.githubusercontent.com or gh CLI; GitHub HTML pages are fetchable
- No search/crawl features
- One URL at a time

**Examples:**
```
fetch("https://raw.githubusercontent.com/user/repo/main/README.md")
fetch("https://example.com/article.html") → returns markdown
```

**When to use:** Simple one-off URL fetch, all other tools overkill

## Decision tree

```
Need web content?
    ↓
Known URL(s)?
├─ YES → Single static URL? → Fetch
│        JS/dynamic content? → crawl4ai
│        Multiple URLs? → Tavily extract
└─ NO → Need search
    ↓
    Tavily credits OK?
    ├─ YES → Use Tavily (citations!)
    └─ NO → Brave credits OK?
        ├─ YES → Use Brave (2k/mo)
        └─ NO → WebSearchAPI credits OK?
            ├─ YES → Use WebSearchAPI (Google-quality)
            └─ NO → Use web-search-mcp (unlimited, slower)
```

## Best practices

**Search priority order:**
1. Tavily (citations, best features)
2. Brave (2k/mo backup)
3. WebSearchAPI (Google-quality, +2k/mo)
4. web-search-mcp (unlimited, slowest)

**Extraction priority order:**
1. Fetch (static pages, fastest)
2. crawl4ai (JS pages, boilerplate removal)
3. Tavily extract (multiple URLs, credits permitting)

**Track limits:** Check monthly resets (Tavily: 1st, Brave/WebSearchAPI: varies)

## Common mistakes to avoid

❌ Ignoring Tavily's citation feature (always prefer cited sources)
❌ Not checking credit balance before complex Tavily operations
❌ Using Fetch against GitHub when you need raw file contents (use raw.githubusercontent.com or gh CLI). For HTML repo pages, Fetch is fine.

## Links to deep dives

- [Tavily deep dive](../deep-dives/tavily.md)
- [Brave deep dive](../deep-dives/brave.md)
- [WebSearchAPI deep dive](../deep-dives/websearchapi.md)
- [web-search-mcp deep dive](../deep-dives/web-search-mcp.md)
- [crawl4ai deep dive](../deep-dives/crawl4ai.md)
- [Fetch deep dive](../deep-dives/fetch.md)
