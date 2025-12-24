#!/usr/bin/env python3
"""
Purpose:
- This script:
    1. wraps Zen's stdio transport in an HTTP gateway
    2. starts the Zen MCP in HTTP mode
- This allows many locally-running coding CLIs to connect to a single Zen instance.

Required environment variables:
- DISABLED_TOOLS ➔ Comma-separated list of Zen tools to disable
- ZEN_MCP_PORT   ➔ Port to run the server on (default: 3333)

Note dependencies are *automatically installed* at startup when the server is started
in set-up-tools.sh using uvx (which reads zen-mcp-server's package metadata)
"""

import os
from contextlib import asynccontextmanager
from starlette.applications import Starlette
from starlette.routing import Mount
from mcp.server.streamable_http_manager import StreamableHTTPSessionManager
from server import server
import uvicorn

# converts requests/responses between HTTP and underlying MCP server protocol
#
# stateless mode:
#   - each request gets a fresh transport with no session tracking
#   - matches Zen's nature (each tool call is independent)
#   - works with all HTTP clients without requiring session handshake
session_manager = StreamableHTTPSessionManager(server, stateless=True, json_response=True)

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
    # timeout_graceful_shutdown: max seconds to wait for HTTP keep-alive connections
    # to close before force-terminating (prevents server from hanging on shutdown)
    uvicorn.run(app, host='127.0.0.1', port=port, timeout_graceful_shutdown=5)
