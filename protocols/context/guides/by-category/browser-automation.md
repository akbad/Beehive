# MCPs: Browser Automation

## Overview

Tools for automating browser interactions, testing web applications, and extracting content from dynamic JavaScript-heavy websites.

## Available MCPs

### Playwright MCP ⭐ PRIMARY

**What it does:** Browser automation via accessibility tree

**Key capabilities:**
- Navigate to URLs and interact with pages
- Click buttons, fill forms, submit data
- Extract structured content from dynamic pages
- Take screenshots for debugging
- Save/restore authentication state
- Multi-browser support (Chrome, Firefox, WebKit)

**When to use:**
- Testing web applications (E2E tests)
- Interacting with JavaScript-heavy SPAs
- Form automation (login, multi-step flows)
- Extracting data from dynamic content
- Automating repetitive browser tasks

**When NOT to use:**
- Static HTML content → Use Fetch MCP
- API access available → Use direct API calls
- Large-scale scraping → Use Tavily crawl

**Rate limits:** None (local execution)

**Configuration:** stdio transport only

**Links:**
- [Playwright deep dive](../deep-dives/playwright.md)
- [Full decision guide](../../../tools/tools-decision-guide.md)

## Decision Tree

```
Need to interact with a website?
    ↓
Is content static (no JavaScript)?
    ├─ YES → Use Fetch MCP (simpler, faster)
    └─ NO  → Need to click/type/navigate?
        ├─ YES → Use Playwright MCP
        └─ NO  → Just need final HTML?
            └─ Try Tavily extract first
            └─ Then Playwright if needed
```

## Related Categories

- [Web Research](web-research.md) - For simple content fetching
- [Code Search](code-search.md) - For finding code examples
