"""Abstract base class for storage cleanup handlers."""
from abc import ABC, abstractmethod
from datetime import datetime, timedelta, timezone
from typing import Any

from ...config_loader import Config, parse_duration, get_retention


class CleanupHandler(ABC):
    """Abstract base class for storage backend-specific cleanup handlers."""

    name: str  # e.g. "qdrant", "claude-mem"

    def __init__(self, config: Config):
        self.config = config

    @abstractmethod
    def get_expired_items(self, cutoff: datetime) -> list[dict[str, Any]]:
        """Return items older than cutoff with id/path and metadata."""
        pass

    @abstractmethod
    def export_to_trash(self, items: list[dict[str, Any]], retention: str) -> str:
        """Export items to trash, return the trash file path."""
        pass

    @abstractmethod
    def delete_items(self, items: list[dict[str, Any]]) -> int:
        """Delete items from storage, return count of deleted items."""
        pass

    @abstractmethod
    def wipe(self, backup: bool = True) -> dict[str, Any]:
        """Completely erase all data from storage.

        Args:
            backup: If True, export all data to trash before wiping.

        Returns:
            Dict with 'storage', 'wiped' count, and optionally 'backup_path'.
        """
        pass

    def get_cutoff(self, retention: str) -> datetime:
        """Calculate cutoff datetime from retention period."""
        delta = parse_duration(retention)
        if delta == timedelta.max:
            # retention period is "forever": return a cutoff date far in the past so that
            #   no stored memories are older than it
            return datetime.min
        return datetime.now(timezone.utc) - delta

    def cleanup(self, retention: str | None = None, dry_run: bool = False) -> dict[str, Any]:
        """Runs cleanup for the given storage backend and returns stats."""
        if retention is None:
            # retrieve retention period for the given storage backend
            retention = get_retention(self.name)

        if retention.lower() == "always":
            # memories are set to always be kept for the given storage backend
            return {
                "storage": self.name,
                "skipped": True,
                "reason": "retention set to 'always'"
            }

        cutoff = self.get_cutoff(retention)
        items = self.get_expired_items(cutoff)

        if not items:
            return {
                "storage": self.name, 
                "deleted": 0, 
                "message": "no expired items"
            }

        if dry_run:
            return {
                "storage": self.name,
                "would_delete": len(items),
                "dry_run": True,
                "items": items[:10],  # show first 10 items that *would have been* deleted
            }

        # write *new* files for the deleted items to the trash 
        # (to be kept for the specified grace period)
        trash_path = self.export_to_trash(items, retention)

        count = self.delete_items(items)

        return {
            "storage": self.name,
            "deleted": count,
            "trash_path": trash_path,
        }
