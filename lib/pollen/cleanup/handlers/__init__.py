"""Cleanup handlers specific to each memory backend."""
from .base import CleanupHandler
from .qdrant import QdrantHandler
from .claude_mem import ClaudeMemHandler
from .serena import SerenaHandler
from .memory_mcp import MemoryMcpHandler


# register memory backends' handler classes
HANDLERS = (
    ClaudeMemHandler,
    SerenaHandler,
    QdrantHandler,
    MemoryMcpHandler,
)


__all__ = [
    "CleanupHandler",
    "QdrantHandler",
    "ClaudeMemHandler",
    "SerenaHandler",
    "MemoryMcpHandler",
    "HANDLERS",
]
