# Web research tools: comparison & usage guides

## Quick selection table

| Tool | Best For | Limit | When to Use | Avoid When |
|------|----------|-------|-------------|-----------|
| **Tavily** | General web + citations | 1k/mo | Current info, multi-source research | Credits low |
| **Brave** | Privacy search | 2k/mo | Tavily exhausted, basic search | Need advanced features |
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
├─ YES → Single URL? → Fetch
│        Multiple or complex? → Tavily extract
└─ NO → Need search
    ↓
    Tavily credits OK?
    ├─ YES → Use Tavily (citations!)
    └─ NO → Use Brave (2k/mo)
```

## Best practices

**Always start with:** Tavily (best balance of features + limits)

**Use Brave when:** Tavily credits low, need basic search

**Use Fetch when:** Known URL, simple content, other tools overkill

**Track limits:** Check monthly resets (Tavily: 1st, Brave: varies)

## Common mistakes to avoid

❌ Ignoring Tavily's citation feature (always prefer cited sources)
❌ Not checking credit balance before complex Tavily operations
❌ Using Fetch against GitHub when you need raw file contents (use raw.githubusercontent.com or gh CLI). For HTML repo pages, Fetch is fine.

## Links to deep dives

- [Tavily deep dive](../deep-dives/tavily.md)
- [Brave deep dive](../deep-dives/brave.md)
- [Fetch deep dive](../deep-dives/fetch.md)
