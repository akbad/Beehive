"""Operations: Bureau's internal package providing reusable utilities."""

from .config_templating import expand_placeholders
from .mcp_catalog import resolve_mcp_catalog
from .skills_catalog import resolve_skills_catalog

# define and expose package's API (for use within Bureau)
__all__ = [
    "expand_placeholders",
    "resolve_mcp_catalog",
    "resolve_skills_catalog",
]
