# Playwright MCP: Deep Dive

## Overview

- Fast, lightweight browser automation using Playwright's accessibility tree. 
- No vision models needed; operates on structured data for deterministic, reliable web interactions.

## Available Tools

### Core Navigation & Interaction Tools

1. **`playwright_navigate`** - Navigate to URL
2. **`playwright_click`** - Click elements by selector/text
3. **`playwright_type`** - Type text into input fields
4. **`playwright_evaluate`** - Execute JavaScript in page context
5. **`playwright_screenshot`** - Capture screenshots (optional, for debugging)

### Content Extraction Tools

6. **`playwright_extract`** - Extract structured data from page
7. **`playwright_get_accessibility_tree`** - Get full accessibility snapshot

### Session Management

8. **`playwright_new_page`** - Create new browser page/tab
9. **`playwright_close_page`** - Close current page
10. **`playwright_save_storage_state`** - Save cookies/auth for reuse

## Key Features

### Fast & Lightweight
- Uses accessibility tree, not pixel-based input
- No vision models required
- Deterministic tool application

### Multi-Browser Support
- Chrome/Chromium
- Firefox
- WebKit (Safari)
- Microsoft Edge

### Configuration Options

Via CLI args in config (add to `"args"` array):

**Browser Selection:**
- `--browser chrome|firefox|webkit|msedge`

**Execution Mode:**
- `--headless` - Run without UI (default: headed)

**Device Emulation:**
- `--device "iPhone 15"` - Emulate specific devices

**Session Persistence:**
- `--user-data-dir <path>` - Persistent browser profile
- `--storage-state <path>` - Load saved auth state
- `--save-session` - Save session to output directory
- `--isolated` - In-memory profile (no disk writes)

**Security:**
- `--ignore-https-errors` - Skip certificate validation
- `--no-sandbox` - Disable sandbox (use cautiously)

**Network:**
- `--proxy-server <url>` - Use proxy
- `--blocked-origins <list>` - Block specific origins
- `--allowed-origins <list>` - Whitelist origins only

**Debugging:**
- `--save-trace` - Record Playwright trace
- `--save-video <size>` - Record video (e.g., "800x600")
- `--output-dir <path>` - Output directory

**Timeouts:**
- `--timeout-action <ms>` - Action timeout (default: 5000ms)
- `--timeout-navigation <ms>` - Nav timeout (default: 60000ms)

## Tradeoffs

### Advantages
✅ No vision models needed (structured data only)
✅ Deterministic, reliable automation
✅ Fast execution via accessibility tree
✅ Multi-browser support
✅ Session persistence and auth reuse
✅ Local execution (privacy-friendly)
✅ Free and unlimited

### Disadvantages
❌ Requires Node.js runtime (npx)
❌ Only supports stdio transport (per-agent instances)
❌ Can't interact with canvas/WebGL (accessibility-based)
❌ May struggle with highly dynamic shadow DOM
❌ Requires learning Playwright selectors

## Common Pitfalls: When NOT to Use

### ❌ Simple Static HTML Fetch
**Problem:** Playwright is overkill for static content
**Alternative:** Fetch MCP or Tavily extract

**Example:**
```
Bad:  playwright_navigate + playwright_extract
Good: fetch("https://example.com/static-page")
```

### ❌ Content Already Accessible via API
**Problem:** Direct API calls are faster and more reliable
**Alternative:** Use Fetch MCP with API endpoint

**Example:**
```
Bad:  Automate website to scrape data
Good: Call REST API directly
```

### ❌ Large-Scale Scraping
**Problem:** Running browser instances is resource-intensive
**Alternative:** Use Tavily crawl or Fetch for bulk operations

**Example:**
```
Bad:  playwright loop over 100 URLs
Good: tavily_crawl or parallel fetch calls
```

### ❌ Complex JavaScript Reverse Engineering
**Problem:** Accessibility tree may miss dynamically generated content
**Alternative:** Use browser DevTools or screenshot-based approaches

## When Playwright IS the Right Choice

✅ **Form interactions** (login, submit, multi-step flows)
✅ **JavaScript-heavy sites** (SPAs, React/Vue apps)
✅ **Testing web applications** (E2E tests)
✅ **Dynamic content extraction** (infinite scroll, lazy loading)
✅ **Browser automation workflows** (repetitive tasks)
✅ **Authenticated sessions** (persist login state)

**Decision rule:** "Does this require clicking, typing, or waiting for JS? → Use Playwright"

## Best Practices

**Start headed, switch to headless:**
- Debug with `--headless` omitted (see what's happening)
- Production: add `--headless` for faster execution

**Reuse browser sessions:**
```bash
# Save auth once
--save-session --output-dir ./sessions/

# Reuse later
--storage-state ./sessions/storage.json
```

**Handle timeouts appropriately:**
- Fast actions: `--timeout-action 3000`
- Slow sites: `--timeout-navigation 120000`

**Use device emulation for mobile testing:**
```bash
--device "iPhone 15"
```

**Enable traces for debugging:**
```bash
--save-trace --output-dir ./traces/
```

**Selector best practices:**
- Prefer text selectors: `"button:has-text('Submit')"`
- Use test IDs: `[data-testid="login-button"]`
- Avoid brittle CSS classes
- Use `--test-id-attribute` for custom test ID attributes

## Alternatives Summary

| Task | Instead of Playwright | Use This |
|------|----------------------|----------|
| Static HTML | playwright_navigate | Fetch MCP |
| API access | Browser automation | Direct API call |
| Bulk scraping | Multiple Playwright instances | Tavily crawl |
| Simple extraction | Accessibility tree | Tavily extract |
| Visual testing | Accessibility only | Screenshot-based tools |

## Quick Reference

**Transport:** stdio only (per-agent instance)
**Rate limits:** None (local execution)
**Cost:** Free (open source)

**Links:**
- [Official Playwright MCP README](https://github.com/microsoft/playwright-mcp)
- [Playwright Documentation](https://playwright.dev)
- [Full decision guide](../../../tools/tools-decision-guide.md)
