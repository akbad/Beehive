#!/usr/bin/env python3
"""
Start Zen MCP server in HTTP mode using streamable HTTP adapter.

This script wraps Zen's stdio transport in an HTTP gateway so multiple
agent CLIs can share the same server instance.

Dependencies (automatically installed by uvx via zen-mcp-server's package metadata):
  - zen-mcp-server (from git+https://github.com/BeehiveInnovations/zen-mcp-server.git)
  - starlette (dependency of zen-mcp-server)
  - uvicorn (dependency of zen-mcp-server)
  - mcp (MCP SDK, dependency of zen-mcp-server)

Environment variables:
  DISABLED_TOOLS - Comma-separated list of Zen tools to disable
  ZEN_MCP_PORT   - Port to run the server on (default: 3333)
"""

import os
from contextlib import asynccontextmanager
from starlette.applications import Starlette
from starlette.routing import Mount
from mcp.server.streamable_http_manager import StreamableHTTPSessionManager
from server import server as zen_server
import uvicorn

session_manager = StreamableHTTPSessionManager(zen_server)


async def mcp_app(scope, receive, send):
    await session_manager.handle_request(scope, receive, send)


@asynccontextmanager
async def lifespan(app):
    async with session_manager.run():
        yield


app = Starlette(routes=[Mount('/mcp', app=mcp_app)], lifespan=lifespan)

if __name__ == "__main__":
    port = int(os.environ.get('ZEN_MCP_PORT', '3333'))
    uvicorn.run(app, host='127.0.0.1', port=port)
