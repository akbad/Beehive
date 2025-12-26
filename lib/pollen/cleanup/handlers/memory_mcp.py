"""Memory MCP JSONL cleanup handler."""
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .base import CleanupHandler
from ..trash import get_trash_dir, generate_trash_filename, write_manifest
from ...config_loader import get_storage, get_trash_grace_period


class MemoryMcpHandler(CleanupHandler):
    """Cleanup handler for Memory MCP's JSONL file."""

    name = "memory-mcp"

    def _get_file_path(self) -> Path:
        """Get the Memory MCP JSONL file path."""
        return get_storage("memory_mcp")

    def _read_entities(self) -> list[dict[str, Any]]:
        """Read all entities from JSONL file."""
        file_path = self._get_file_path()
        if not file_path.exists():
            return []

        entities = []
        with open(file_path) as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        entities.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
        return entities

    def _write_entities(self, entities: list[dict[str, Any]]) -> None:
        """
        Write entities back to JSONL file, rewriting it from scratch.
        Used after deleting/modifying existing entries.
        """
        file_path = self._get_file_path()
        file_path.parent.mkdir(parents=True, exist_ok=True)

        # open file in write mode; existing file will be erased
        with open(file_path, "w") as f:
            for entity in entities:
                f.write(json.dumps(entity) + "\n")

    def get_stale_items(self, cutoff: datetime) -> list[dict[str, Any]]:
        """Find entities with created_at older than cutoff."""
        items = []
        for entity in self._read_entities():
            created_at = entity.get("created_at")
            if not created_at:
                continue  # skip entities without timestamp

            try:
                created_str = str(created_at)
                
                # timestamp will be ISO with optional Z; normalize Z to +00:00 for fromisoformat
                if created_str.endswith("Z"):
                    created_str = created_str[:-1] + "+00:00"

                created_dt = datetime.fromisoformat(created_str)
            except (ValueError, TypeError):
                try:
                    created_dt = datetime.strptime(str(created_at), "%Y-%m-%d")
                except (ValueError, TypeError):
                    continue

            # ensure created_dt is timezone-aware (use UTC since this is the timezone agents
            #   are directed to use for all memories in Beehive's context files)
            if created_dt.tzinfo is None:
                created_dt = created_dt.replace(tzinfo=timezone.utc)

            if created_dt < cutoff:
                items.append(entity)

        return items

    def export_items_to_trash(self, items: list[dict[str, Any]], retention: str) -> str:
        """Export entities to JSONL in trash directory."""
        trash_dir = get_trash_dir(self.name)
        filename = generate_trash_filename(len(items), "jsonl")
        trash_path = trash_dir / filename

        with open(trash_path, "w") as f:
            for entity in items:
                f.write(json.dumps(entity) + "\n")

        write_manifest(trash_dir, 
                       self.name, 
                       len(items), 
                       retention,
                       get_trash_grace_period(),
                       files=[trash_path])

        return str(trash_path)

    def delete_items_from_storage(self, items: list[dict[str, Any]]) -> int:
        """Rewrite JSONL without expired entities."""
        if not items:
            return 0

        # build separate sets for "name" vs "id" identifiers to avoid collisions
        # (e.g., an entity with name="foo" should not match an entity with id="foo")
        expired_names: set[str] = set()
        expired_ids: set[str] = set()
        for item in items:
            if "name" in item:
                expired_names.add(item["name"])
            elif "id" in item:
                expired_ids.add(item["id"])

        # filter out expired entities from overall set
        all_entities = self._read_entities()
        remaining = []
        deleted_count = 0

        for entity in all_entities:
            # match by the same field type: name → expired_names, id → expired_ids
            should_delete = False
            if "name" in entity:
                should_delete = entity["name"] in expired_names
            elif "id" in entity:
                should_delete = entity["id"] in expired_ids

            if should_delete:
                deleted_count += 1
            else:
                remaining.append(entity)

        # write back remaining entities
        self._write_entities(remaining)

        return deleted_count

    def wipe(self, backup: bool = True) -> dict[str, Any]:
        """Completely erase all entities from Memory MCP."""
        entities = self._read_entities()

        if not entities:
            return {"storage": self.name, "wiped": 0, "message": "no entities found"}

        # backup entities if requested
        backup_path = None
        if backup:
            backup_path = self.export_items_to_trash(entities, "wipe")

        # clear the file (prefer this method over .unlink() and .touch() to avoid race conditions
        #   with the MCP if it's running)
        self._write_entities([])

        result: dict[str, Any] = {"storage": self.name, "wiped": len(entities)}
        if backup_path:
            result["backup_path"] = backup_path
        return result
