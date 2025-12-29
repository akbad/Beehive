"""WebSearchAPI MCP Server - Google-quality search via websearchapi.ai

This MCP server provides access to websearchapi.ai's Google-quality search results.
It serves as a fallback tier in the Bureau search chain:
  Tavily (1K/mo) -> Brave (2K/mo) -> WebSearchAPI (2K/mo) -> web-search-mcp (unlimited)

Environment variables:
  WEBSEARCHAPI_KEY: API key from https://websearchapi.ai/
  WEBSEARCHAPI_URL: API base URL (default: https://api.websearchapi.ai)
"""

import json
import os
from collections.abc import Callable
from typing import Any

import httpx
from mcp.server import NotificationOptions, Server
from mcp.server.stdio import stdio_server
from mcp.types import TextContent, Tool
from mcp.server.models import InitializationOptions

# Read URL from env var (set by set-up-tools.sh from charter.yml)
WEBSEARCHAPI_BASE = os.environ.get("WEBSEARCHAPI_URL", "https://api.websearchapi.ai")

server = Server("websearchapi")

# Module-level client for connection pooling (lazy initialized)
_client: httpx.AsyncClient | None = None

# Cached API key (lazy initialized)
_api_key: str | None = None
_api_key_checked: bool = False


def get_client() -> httpx.AsyncClient:
    """Get or create the shared HTTP client for connection pooling."""
    global _client
    if _client is None:
        _client = httpx.AsyncClient(timeout=30.0)
    return _client


def get_api_key() -> str | None:
    """Get the API key (cached after first read)."""
    global _api_key, _api_key_checked
    if not _api_key_checked:
        _api_key = os.environ.get("WEBSEARCHAPI_KEY")
        _api_key_checked = True
    return _api_key


async def close_client():
    """Close the HTTP client on shutdown."""
    global _client
    if _client is not None:
        await _client.aclose()
        _client = None


async def _fetch_api(
    endpoint: str,
    body: dict[str, Any],
    formatter: Callable[[dict[str, Any]], str],
) -> str:
    """Fetch from API endpoint and format the response.

    Consolidates HTTP request logic for all API calls:
    - Uses cached API key and connection-pooled client
    - Handles all error cases consistently
    - Applies the appropriate formatter to successful responses

    Args:
        endpoint: API endpoint path (e.g., "/ai-search", "/scrape")
        body: JSON body for the POST request
        formatter: Function to format the JSON response into readable text

    Returns:
        Formatted result string or error message
    """
    api_key = get_api_key()
    if not api_key:
        return (
            "Error: WEBSEARCHAPI_KEY environment variable not set. "
            "Get a key at https://websearchapi.ai/"
        )

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    client = get_client()

    try:
        response = await client.post(
            f"{WEBSEARCHAPI_BASE}{endpoint}",
            json=body,
            headers=headers,
        )
        response.raise_for_status()
        data = response.json()
        return formatter(data)
    except httpx.HTTPStatusError as e:
        if e.response.status_code == 401:
            return "Error: Invalid API key. Check your WEBSEARCHAPI_KEY."
        elif e.response.status_code == 429:
            return (
                "Error: Rate limit exceeded. "
                "WebSearchAPI free tier allows 2,000 queries/month. "
                "Consider using web-search-mcp (unlimited) as fallback."
            )
        else:
            return f"HTTP Error {e.response.status_code}: {e.response.text}"
    except httpx.RequestError as e:
        return f"Request Error: {e}"
    except json.JSONDecodeError:
        return "Error: Invalid JSON response from API"


@server.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools for web search and content extraction."""
    return [
        Tool(
            name="websearch",
            description=(
                "Search the web using Google-quality results via websearchapi.ai. "
                "Returns title, URL, and snippet for each result. "
                "Free tier: 2,000 queries/month."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search query",
                    },
                    "num_results": {
                        "type": "integer",
                        "default": 10,
                        "minimum": 1,
                        "maximum": 20,
                        "description": "Number of results to return (1-20)",
                    },
                    "country": {
                        "type": "string",
                        "default": "us",
                        "description": "Country code for localized results (e.g., 'us', 'uk', 'de')",
                    },
                },
                "required": ["query"],
            },
        ),
        Tool(
            name="extract_content",
            description=(
                "Extract clean text content from a URL using websearchapi.ai's extraction endpoint. "
                "Removes boilerplate, ads, and navigation to return the main content."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "URL to extract content from",
                    },
                },
                "required": ["url"],
            },
        ),
    ]


def format_search_results(data: dict[str, Any]) -> str:
    """Format search results into a readable string."""
    results = data.get("organic", [])
    answer = data.get("answer", "")

    formatted = []

    # Include AI-generated answer if available
    if answer:
        formatted.append(f"**Answer:** {answer}")

    if not results:
        return answer if answer else "No results found."

    for i, result in enumerate(results, 1):
        title = result.get("title", "No title")
        url = result.get("url", "")
        snippet = result.get("description", "No description")
        formatted.append(f"{i}. {title}\n   URL: {url}\n   {snippet}")

    return "\n\n".join(formatted)


def format_extraction_result(data: dict[str, Any]) -> str:
    """Format extraction result into a readable string."""
    # Response is nested under "data" key
    inner = data.get("data", data)
    content = inner.get("content", inner.get("text", ""))
    title = inner.get("title", "")

    if not content:
        return "No content extracted."

    result = ""
    if title:
        result = f"# {title}\n\n"
    result += content

    return result


@server.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    """Handle tool calls for web search and content extraction."""
    if name == "websearch":
        result = await _fetch_api(
            "/ai-search",
            {
                "query": arguments["query"],
                "maxResults": arguments.get("num_results", 10),
                "country": arguments.get("country", "us"),
                "includeContent": True,
            },
            format_search_results,
        )
    elif name == "extract_content":
        result = await _fetch_api(
            "/scrape",
            {
                "url": arguments["url"],
                "returnFormat": "markdown",
            },
            format_extraction_result,
        )
    else:
        result = f"Unknown tool: {name}"

    return [TextContent(type="text", text=result)]


def main():
    """Run the MCP server using stdio transport."""
    import asyncio

    async def run():
        try:
            async with stdio_server() as (read_stream, write_stream):
                await server.run(
                    read_stream,
                    write_stream,
                    InitializationOptions(
                        server_name="websearchapi",
                        server_version="0.1.0",
                        capabilities=server.get_capabilities(
                            notification_options=NotificationOptions(),
                            experimental_capabilities={},
                        ),
                    ),
                )
        finally:
            await close_client()

    asyncio.run(run())


if __name__ == "__main__":
    main()
