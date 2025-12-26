"""Claude-mem SQLite cleanup handler."""
import json
import sqlite3
from datetime import datetime, timezone
from typing import Any

from .base import CleanupHandler
from ..trash import get_trash_dir, generate_trash_filename, write_manifest
from ...config_loader import get_storage, get_trash_grace_period


class ClaudeMemHandler(CleanupHandler):
    """Cleanup handler for claude-mem SQLite database."""

    name = "claude-mem"
    entity_types = ["session", "observation"]

    def _table_name_for_entity_type(self, entity_type : str):
        # note "session_summaries" is the table name used by claude-mem v4+ to store session summaries
        #   (previously "sessions")
        return "session_summaries" if entity_type == "session" else "observations"

    def _get_db_connection(self) -> sqlite3.Connection | None:
        """Get SQLite connection if database exists."""
        db_path = get_storage("claude_mem")
        return sqlite3.connect(db_path) if db_path.exists() else None

    def get_stale_items(self, cutoff: datetime) -> list[dict[str, Any]]:
        """Retrieve stale sessions and observations (relative to provided cutoff)."""
        conn = self._get_db_connection()
        if not conn:
            return []

        stale_items = []

        # format staleness cutoff with Z suffix to match stored ISO format produced by toISOString() in claude-mem
        cutoff_str = cutoff.strftime("%Y-%m-%dT%H:%M:%S.") + f"{cutoff.microsecond // 1000:03d}Z"

        try:
            cursor = conn.cursor()

            # retrieve tables to safely check existence of the ones we need
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = {row[0] for row in cursor.fetchall()}

            # find stale sessions and observations
            for entity_type in self.entity_types:

                table_name = self._table_name_for_entity_type(entity_type)
                if table_name not in tables:
                    continue

                # filter stale records
                cursor.execute(
                    f"SELECT * FROM {table_name} WHERE created_at < ?",
                    (cutoff_str,)
                )

                # extract list of column names from table
                columns = [desc[0] for desc in cursor.description]

                for row in cursor.fetchall():
                    stale_items.append({
                        "type": entity_type,
                        "table": table_name,
                        "data": dict(zip(columns, row)),  # creates tuples of (column name, value)
                    })

        finally:
            conn.close()

        return stale_items

    def export_items_to_trash(self, items: list[dict[str, Any]], retention: str) -> str:
        """Export items to a new JSON file in trash directory."""
        trash_dir = get_trash_dir(self.name)

        # triage items to export by entity type, preserving only their "data" field
        items_by_entity_type = {}
        for entity_type in self.entity_types:
            items_by_entity_type[entity_type] = [item["data"] for item in items if item["type"] == entity_type]

        trash_file_json = {
            "exported_at": datetime.now(timezone.utc).isoformat(),
            "sessions": items_by_entity_type["session"],
            "observations": items_by_entity_type["observation"],
            "counts": {
                "sessions": len(items_by_entity_type["session"]),
                "observations": len(items_by_entity_type["observation"]),
            },
        }

        # write deleted items' data to new file in the trash folder for claude-mem
        filename = generate_trash_filename(len(items), "json")
        trash_path = trash_dir / filename
        with open(trash_path, "w") as f:
            json.dump(trash_file_json, f, indent=2, default=str)

        write_manifest(trash_dir, 
                       self.name, 
                       len(items), 
                       retention,
                       get_trash_grace_period(),
                       files=[trash_path])

        return str(trash_path)

    def delete_items_from_storage(self, items: list[dict[str, Any]]) -> int:
        """Delete items from SQLite, then vacuum the database (to make the freed space available to the OS)."""
        conn = self._get_db_connection()
        if not conn:
            return 0

        deleted = 0
        try:
            cursor = conn.cursor()

            # for each entity type, retrieve ids corresponding to items to delete
            #   then delete them from that entity's table
            for entity_type in self.entity_types:
                entities_to_delete = [item for item in items if item["type"] == entity_type]
                if not entities_to_delete:
                    continue
                
                ids = [entity["data"].get("id") for entity in entities_to_delete if entity["data"].get("id")]
                if not ids:
                    continue 

                placeholders = ",".join("?" * len(ids))
                table_name = self._table_name_for_entity_type(entity_type)
                cursor.execute(f"DELETE FROM {table_name} WHERE id IN ({placeholders})", ids)
                deleted += cursor.rowcount

            conn.commit()

            # vacuum to immediately hand back freed space to OS
            cursor.execute("VACUUM")

        finally:
            conn.close()

        return deleted

    def wipe(self, backup: bool = True) -> dict[str, Any]:
        """Completely erase all data from claude-mem database."""
        conn = self._get_db_connection()
        if not conn:
            return {"storage": self.name, "wiped": 0, "message": "database does not exist"}

        try:
            cursor = conn.cursor()

            # retrieve all tables
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [row[0] for row in cursor.fetchall()]

            # survey items in database: 
            #   - determine total count of items
            #   - if backup requested, save them for subsequent re-export to backup location
            total_count = 0
            items_to_back_up = []
            for table in tables:
                if table.startswith("sqlite_"):
                    continue
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count_of_entity_type = cursor.fetchone()[0]
                total_count += count_of_entity_type

                if backup and count_of_entity_type > 0:
                    cursor.execute(f"SELECT * FROM {table}")
                    columns = [desc[0] for desc in cursor.description]
                    for row in cursor.fetchall():
                        items_to_back_up.append({
                            "type": table,
                            "table": table,
                            "data": dict(zip(columns, row)),
                        })

            # backup data if requested
            backup_path = None
            if backup and items_to_back_up:
                backup_path = self.export_items_to_trash(items_to_back_up, "wipe")

            # delete all data in all tables (except SQLite's internal ones)
            for table in tables:
                if table.startswith("sqlite_"):
                    continue
                cursor.execute(f"DELETE FROM {table}")

            conn.commit()

            # vacuum to immediately hand back freed space to OS
            cursor.execute("VACUUM")

        finally:
            conn.close()

        result: dict[str, Any] = {"storage": self.name, "wiped": total_count}
        if backup_path:
            result["backup_path"] = backup_path
        return result
