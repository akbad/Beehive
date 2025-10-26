# Web research tools: comparison & usage guides

## Quick selection table

| Tool | Best For | Limit | When to Use | Avoid When |
|------|----------|-------|-------------|-----------|
| **Tavily** | General web + citations | 1k/mo | Current info, multi-source research | Credits low |
| **Brave** | Privacy search | 2k/mo | Tavily exhausted, basic search | Need advanced features |
| **Exa** | Semantic/AI-native | $10 once | Deep research, semantic queries | Simple keyword search |
| **Fetch** | Simple URL fetch | ∞ | Known URL, simple content | Need search/crawl |
| **Firecrawl** | Complex crawl/extract | 500 total | Multi-page deep crawl ONLY | Anything else possible |

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
- Less AI-optimized than Exa

**Examples:**
```
"Python asyncio tutorial" → web search
"Restaurants near me" → local search (if Pro)
"AI news today" → news search
```

**When to use:** After Tavily credits exhausted, need basic search

### Exa (specialized semantic saerch)

**Strengths:**
- Neural search optimized for AI/LLMs
- Superior semantic understanding
- Best for research/knowledge discovery
- Returns AI-formatted content

**Critical Limit:** $10 one-time credit (new account after exhaustion)

**Examples:**
```
"Concepts similar to event sourcing" → finds CQRS, saga patterns
"Authentication architectures for microservices"
"Modern alternatives to REST APIs" → finds GraphQL, gRPC, tRPC
```

**When to use:** Semantic queries where keyword search fails, task justifies limited credits

**When NOT to use:** Simple factual lookup, keyword search sufficient

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

### Firecrawl (LAST RESORT)

**Critical Warning:** 500 lifetime limit before new account required

**Strengths:**
- Advanced multi-page crawling
- Batch operations
- Deep extraction/mapping
- Complex site navigation

**Rate Limits:**
- 10 /scrape per minute
- 1 /crawl per minute
- **500 total lifetime limit**

**When to use:** ONLY when other tools cannot handle:
- Deep multi-page crawls (10+ pages)
- Complex batch processing
- Advanced extraction Tavily can't do

**Examples:**
```
Crawl entire documentation site (100+ pages)
Batch scrape product catalogs
Extract structured data across site
```

**When NOT to use:** Anything Tavily/Brave/Fetch/Exa can handle

## Decision tree

```
Need web content?
    ↓
Known URL(s)?
├─ YES → Single URL? → Fetch
│        Multiple or complex? → Tavily extract
└─ NO → Need search
    ↓
    Semantic/conceptual search?
    ├─ YES → Try Tavily first
    │        └─ Insufficient? → Exa (if worth credits)
    └─ NO → General search
        ↓
        Tavily credits OK?
        ├─ YES → Use Tavily (citations!)
        └─ NO → Use Brave (2k/mo)

Deep crawl needed? (10+ pages)
    └─ Try Tavily crawl first
       └─ Still need more? → Firecrawl (track usage!)
```

## Best practices

**Always start with:** Tavily (best balance of features + limits)

**Escalate to Exa when:** Semantic search needed, Tavily results insufficient

**Use Brave when:** Tavily credits low, need basic search

**Use Fetch when:** Known URL, simple content, other tools overkill

**Use Firecrawl when:** Literally no other option works

**Track limits:** Check monthly resets (Tavily: 1st, Brave: varies)

## Common mistakes to avoid

❌ Using Firecrawl for single-page scraping (use Fetch)
❌ Using Exa for simple keyword search (use Tavily/Brave)
❌ Ignoring Tavily's citation feature (always prefer cited sources)
❌ Not checking credit balance before complex Tavily operations
❌ Using Fetch against GitHub when you need raw file contents (use raw.githubusercontent.com or gh CLI). For HTML repo pages, Fetch is fine.

## Links to deep dives

- [Tavily deep dive](../mcp-deep-dives/tavily.md)
- [Exa deep dive](../mcp-deep-dives/exa.md)
- [Firecrawl deep dive](../mcp-deep-dives/firecrawl.md)
- [Brave deep dive](../mcp-deep-dives/brave.md)
