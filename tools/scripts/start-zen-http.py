#!/usr/bin/env -S uv run --group zen-http
"""
Purpose:
- This script:
    1. wraps Zen's stdio transport in an HTTP gateway
    2. starts the Zen MCP in HTTP mode
- This allows many locally-running coding CLIs to connect to a single Zen instance.

Required environment variables:
- DISABLED_TOOLS ➔ Comma-separated list of Zen tools to disable
- ZEN_MCP_PORT   ➔ Port to run the server on (default: 3333)

Dependencies are defined in pyproject.toml under [dependency-groups.zen-http]
"""

import os
from contextlib import asynccontextmanager
from starlette.applications import Starlette
from starlette.routing import Mount
from mcp.server.streamable_http_manager import StreamableHTTPSessionManager
from server import server
import uvicorn

# converts requests/responses between HTTP and underlying MCP server protocol
session_manager = StreamableHTTPSessionManager(server)

# defines an MCP-compliant ASGI (Async Server Gateway Interface) adapter 
# to connect the Starlette app to the underlying transport-level session manager.
#
# in particular, the session manager will
#   - handle SSE connections for sending server notifs to clients
#   - handle clients' incoming HTTP POST reqs (bodies contain JSON-RPC app-level messages)
#
# params:
#   - scope:    dict containing conn details (headers, path, scheme)
#   - receive:  channel to read data from incoming HTTP req bodies
#   - send:     channel to write outgoing HTTP response bodies to
async def mcp_app(scope, receive, send):
    await session_manager.handle_request(scope, receive, send)


# entrypoint after uvicorn server starts the Starlette app
#   - inits server w/ run()
#   - then yields back to Starlette which starts handling HTTP reqs 
#   - `async with` block exits when server is killed, triggering cleanup by __aexit__ method 
#      of the _AsyncGeneratorContextManager instance returned by run()
#
# params:
#   - app: running Starlette app instance
@asynccontextmanager
async def lifespan(app):
    async with session_manager.run():
        yield

# configure the web server obj (to be run by uvicorn) to:
# - listen on /mcp 
# - delegate received requests to mcp_app ASGI adapter
# - use lifespan() for init/cleanup
app = Starlette(routes=[Mount('/mcp', app=mcp_app)], lifespan=lifespan)

if __name__ == "__main__":
    port = int(os.environ.get('ZEN_MCP_PORT', '3333'))
    uvicorn.run(app, host='127.0.0.1', port=port)
