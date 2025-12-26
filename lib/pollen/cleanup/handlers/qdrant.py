"""Qdrant vector database cleanup handler."""
import json
from datetime import datetime, timezone
from typing import Any
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError

from .base import CleanupHandler
from ..trash import get_trash_dir, generate_trash_filename, write_manifest
from ...config_loader import get_qdrant_url, get_qdrant_collection, get_trash_grace_period


class QdrantHandler(CleanupHandler):
    """Cleanup handler for Qdrant vector database."""

    name = "qdrant"

    def _http_request(self, method: str, endpoint: str, data: dict | None = None) -> dict:
        """Make HTTP request to (locally-running) Qdrant server."""
        url = f"{get_qdrant_url()}{endpoint}"
        headers = {"Content-Type": "application/json"}

        body = json.dumps(data).encode() if data else None
        req = Request(url, data=body, headers=headers, method=method)

        try: 
            # send request with 30s timeout
            with urlopen(req, timeout=30) as resp:
                # read response bytes, decode to string, parse as JSON and return resulting dict
                return json.loads(resp.read().decode())
            
        except HTTPError as e:  # must catch before URLError since it's a subclass of it
            return {"error": f"Qdrant HTTP {e.code}: {e.reason}"}
        
        except URLError as e:
            return {"error": f"Qdrant unavailable: {e.reason}"}
        
        except json.JSONDecodeError:
            return {"error": "Invalid JSON response from Qdrant"}

    def _collection_exists(self) -> bool:
        """Check if collection exists."""
        result = self._http_request("GET", f"/collections/{get_qdrant_collection()}")
        return result.get("status") == "ok"

    def get_stale_items(self, cutoff: datetime) -> list[dict[str, Any]]:
        """Query points with metadata.created_at older than cutoff."""
        if not self._collection_exists():
            return []

        items = []
        offset: int | None = 0

        while True:
            # scroll through all points using offset (starting ID to read points from)
            scroll_params: dict[str, Any] = {
                "limit": 100,
                "with_payload": True,
                "offset": offset,
            }

            result = self._http_request(
                "POST",
                f"/collections/{get_qdrant_collection()}/points/scroll",
                scroll_params
            )

            if result.get("status") != "ok":
                break

            result_data = result.get("result") or {}
            points = result_data.get("points", [])
            if not points:
                # reached the end of the collection
                break

            for point in points:
                payload = point.get("payload") or {}
                metadata = payload.get("metadata") or {}
                created_at = metadata.get("created_at")
                
                # skip points that don't have a timestamp
                if not created_at:
                    continue

                # parse date (handling both ISO format and YYYY-MM-DD)
                # while ensuring timezone-aware comparison (always UTC)
                try:
                    created_str = str(created_at)
                    if "T" in created_str:
                        # handle ISO format, including 'Z' suffix
                        if created_str.endswith("Z"):
                            created_str = created_str[:-1] + "+00:00"
                        point_date = datetime.fromisoformat(created_str)
                    else:
                        point_date = datetime.strptime(created_str, "%Y-%m-%d")

                    # ensure point_date is timezone-aware (use UTC since this is the timezone agents 
                    #   are directed to use for all memories in Beehive's context files)
                    if point_date.tzinfo is None:
                        point_date = point_date.replace(tzinfo=timezone.utc)

                    if point_date < cutoff:
                        items.append({
                            "id": point["id"],
                            "created_at": created_at,
                            "payload": payload,
                        })
                except (ValueError, TypeError):
                    continue

            offset = result_data.get("next_page_offset")
            if not offset:
                break

        return items

    def export_items_to_trash(self, items: list[dict[str, Any]], retention: str) -> str:
        """Export points to JSON in trash directory."""
        trash_dir = get_trash_dir(self.name)
        filename = generate_trash_filename(len(items), "json")
        trash_path = trash_dir / filename

        export_data = {
            "exported_at": datetime.now(timezone.utc).isoformat(),
            "collection": get_qdrant_collection(),
            "points": items,
        }

        with open(trash_path, "w") as f:
            json.dump(export_data, f, indent=2)

        write_manifest(trash_dir, self.name, len(items), retention,
                       get_trash_grace_period(),
                       files=[trash_path])

        return str(trash_path)

    def delete_items_from_storage(self, items: list[dict[str, Any]]) -> int:
        """Delete points from Qdrant by ID."""
        if not items:
            return 0

        point_ids = [item["id"] for item in items]

        result = self._http_request(
            "POST",
            f"/collections/{get_qdrant_collection()}/points/delete",
            {"points": point_ids}
        )

        if result.get("status") == "ok":
            return len(point_ids)
        return 0

    def _get_all_points(self) -> list[dict[str, Any]]:
        """Retrieve all points from the collection."""
        if not self._collection_exists():
            return []

        items = []
        offset = None

        while True:
            scroll_data: dict[str, Any] = {
                "limit": 100,
                "with_payload": True,
            }
            if offset:
                scroll_data["offset"] = offset

            result = self._http_request(
                "POST",
                f"/collections/{get_qdrant_collection()}/points/scroll",
                scroll_data
            )

            if result.get("status") != "ok":
                break

            result_data = result.get("result") or {}
            points = result_data.get("points", [])
            if not points:
                break

            for point in points:
                payload = point.get("payload") or {}
                items.append({
                    "id": point["id"],
                    "payload": payload,
                })

            offset = result_data.get("next_page_offset")
            if not offset:
                break

        return items

    def wipe(self, backup: bool = True) -> dict[str, Any]:
        """Completely erase all points from Qdrant collection."""
        items = self._get_all_points()

        if not items:
            return {"storage": self.name, "wiped": 0, "message": "collection empty or does not exist"}

        # back up data if requested
        backup_path = None
        if backup:
            backup_path = self.export_items_to_trash(items, "wipe")

        # delete all points via corresponding Qdrant endpoint
        point_ids = [item["id"] for item in items]
        result = self._http_request(
            "POST",
            f"/collections/{get_qdrant_collection()}/points/delete",
            {"points": point_ids}
        )

        wiped = len(point_ids) if result.get("status") == "ok" else 0

        result_dict: dict[str, Any] = {"storage": self.name, "wiped": wiped}
        if backup_path:
            result_dict["backup_path"] = backup_path
        return result_dict
