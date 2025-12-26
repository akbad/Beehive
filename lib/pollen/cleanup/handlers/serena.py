"""Serena memories cleanup handler."""
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .base import CleanupHandler
from ..trash import get_trash_dir, move_to_trash, write_manifest
from ...config_loader import get_path, get_trash_grace_period


class SerenaHandler(CleanupHandler):
    """Cleanup handler for Serena project memories (.serena/memories/)."""

    name = "serena"

    def _get_projects_dir(self) -> Path:
        """Get the Serena projects directory."""
        return get_path("serena_projects")

    def _find_serena_dirs(self) -> list[Path]:
        """Find all .serena/memories directories under projects dir.

        Skips directories reached via symlinks to avoid scanning
        unintended locations outside the projects directory.
        """
        serena_dirs: list[Path] = []
        projects_dir = self._get_projects_dir()

        if not projects_dir.exists():
            return serena_dirs

        # search for .serena/memories directories
        for serena_dir in projects_dir.rglob(".serena"):
            # skip if .serena itself is a symlink
            if serena_dir.is_symlink():
                continue

            # skip if any parent in the path is a symlink
            try:
                rel_path = serena_dir.relative_to(projects_dir)
                current = projects_dir
                followed_symlink = False
                for part in rel_path.parts:
                    current = current / part
                    if current.is_symlink():
                        followed_symlink = True
                        break
                if followed_symlink:
                    continue
            except ValueError:
                continue  # not relative to projects_dir, skip

            memories_dir = serena_dir / "memories"
            if memories_dir.exists() and memories_dir.is_dir():
                serena_dirs.append(memories_dir)

        return serena_dirs

    def get_stale_items(self, cutoff: datetime) -> list[dict[str, Any]]:
        """Find memory files older than cutoff based on mtime."""
        items = []
        cutoff_timestamp = cutoff.timestamp()

        for memories_dir in self._find_serena_dirs():
            # grandparent will be the project name since the memories dir 
            #   will always be at <project>/.serena/memories
            project_name = memories_dir.parent.parent.name

            for memory_file in memories_dir.glob("*.md"):
                mtime = memory_file.stat().st_mtime
                if mtime < cutoff_timestamp:
                    items.append({
                        "path": memory_file,
                        "project": project_name,
                        "mtime": datetime.fromtimestamp(mtime, tz=timezone.utc),
                        "size": memory_file.stat().st_size,
                    })

        return items

    def export_items_to_trash(self, items: list[dict[str, Any]], retention: str) -> str:
        """Move files to trash, preserving project structure."""
        trash_dir = get_trash_dir(self.name)
        moved_files: list[Path] = []

        for item in items:
            dest = move_to_trash(item["path"], self.name, project_name=item["project"])
            moved_files.append(dest)

        write_manifest(trash_dir, self.name, len(items), retention,
                       get_trash_grace_period(),
                       files=moved_files)

        return str(trash_dir)

    def delete_items_from_storage(self, items: list[dict[str, Any]]) -> int:
        """Files already moved by export_items_to_trash, just return count."""
        # Files are moved (not copied) by export_items_to_trash
        return len(items)

    def wipe(self, backup: bool = True) -> dict[str, Any]:
        """Completely erase all Serena memory files."""
        items = []

        for memories_dir in self._find_serena_dirs():
            project_name = memories_dir.parent.parent.name

            for memory_file in memories_dir.glob("*.md"):
                mtime = memory_file.stat().st_mtime
                items.append({
                    "path": memory_file,
                    "project": project_name,
                    "mtime": datetime.fromtimestamp(mtime, tz=timezone.utc),
                    "size": memory_file.stat().st_size,
                })

        if not items:
            return {"storage": self.name, "wiped": 0, "message": "no memory files found"}

        # back up if requested, then delete (files moved via export_items_to_trash)
        backup_path = None
        if backup:
            backup_path = self.export_items_to_trash(items, "wipe")
        else:
            for item in items:
                Path(str(item["path"])).unlink()

        result: dict[str, Any] = {"storage": self.name, "wiped": len(items)}
        if backup_path:
            result["backup_path"] = backup_path
        return result
