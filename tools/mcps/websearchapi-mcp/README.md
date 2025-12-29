# websearchapi-mcp

MCP server for [websearchapi.ai](https://websearchapi.ai/) - Google-quality search results.

## Purpose

This MCP server provides access to Google-quality search results via the websearchapi.ai API. It serves as a fallback tier in Bureau's search chain:

```
Tavily (1K/mo) -> Brave (2K/mo) -> WebSearchAPI (2K/mo) -> web-search-mcp (unlimited)
```

## Tools

| Tool | Description |
|------|-------------|
| `websearch` | Search the web with Google-quality results |
| `extract_content` | Extract clean content from a URL |

## Setup

1. Get an API key from [websearchapi.ai](https://websearchapi.ai/)
2. Set the environment variable: `export WEBSEARCHAPI_KEY="your-key"`
3. Bureau will automatically configure this MCP for all agents

## Rate limits

- **Free tier**: 2,000 queries/month
- **Reset**: Monthly

## Local development

```bash
# Install dependencies
uv sync

# Run the server
uv run websearchapi-mcp
```
