"""Tests for MemoryMcpHandler (Memory MCP uses JSONL storage model)."""
import json
from datetime import datetime, timezone
from pathlib import Path


from operations.cleanup.handlers.memory_mcp import MemoryMcpHandler


class TestMemoryMcpGetExpiredItems:
    """Tests for MemoryMcpHandler.get_stale_items()."""

    def test_id_name_collision_prevention(
        self,
        with_jsonl_data: Path,
        cutoff_datetime: datetime,
        apply_mock_patches: dict,
        monkeypatch,
    ):
        """Regression test: entities with same value in different fields (Issue #5).

        Entity with id="X" should NOT cause entity with name="X" to be deleted.
        Uses "stale_id_but_valid_name" - stale ID should be deleted but valid name kept.
        """
        handler = MemoryMcpHandler()
        stale_items = handler.get_stale_items(cutoff_datetime)

        # retrieve stale entity with value "stale_id_but_valid_name" and delete only this entity
        stale_id_entity = [e for e in stale_items if e.get("id") == "stale_id_but_valid_name"]
        assert len(stale_id_entity) == 1
        handler.delete_items_from_storage(stale_id_entity)

        # read back the file
        with open(with_jsonl_data) as f:
            remaining = [json.loads(line) for line in f if line.strip()]

        # entity with name="stale_id_but_valid_name" should still exist (it's valid)
        entity_names = [e.get("name") for e in remaining if "name" in e]
        entity_ids = [e.get("id") for e in remaining if "id" in e]

        assert "stale_id_but_valid_name" in entity_names
        assert "stale_id_but_valid_name" not in entity_ids

    def test_entity_with_name_only(
        self,
        with_jsonl_data: Path,
        cutoff_datetime: datetime,
        apply_mock_patches: dict,
    ):
        """Entities with 'name' field are matched by expired_names set."""
        handler = MemoryMcpHandler()
        stale_items = handler.get_stale_items(cutoff_datetime)

        stale_name_items = [e.get("name") for e in stale_items if "name" in e]
        
        # stale names should be expired
        assert "stale_id_and_name" in stale_name_items
        assert "valid_id_but_stale_name" in stale_name_items
        
        # valid names should NOT be expired
        assert "valid_id_and_name" not in stale_name_items
        assert "stale_id_but_valid_name" not in stale_name_items

    def test_entity_with_id_only(
        self,
        with_jsonl_data: Path,
        cutoff_datetime: datetime,
        apply_mock_patches: dict,
    ):
        """Entities with 'id' field are matched by expired_ids set."""
        handler = MemoryMcpHandler()
        stale_items = handler.get_stale_items(cutoff_datetime)

        stale_id_items = [e.get("id") for e in stale_items if "id" in e]
        
        # stale IDs should be expired
        assert "stale_id_and_name" in stale_id_items
        assert "stale_id_but_valid_name" in stale_id_items
        
        # valid IDs should NOT be expired
        assert "valid_id_and_name" not in stale_id_items
        assert "valid_id_but_stale_name" not in stale_id_items

    def test_entity_with_both_name_and_id(
        self,
        jsonl_file: Path,
        apply_mock_patches: dict,
    ):
        """Entities with both 'name' and 'id' metadata fields are matched by 'name' (elif logic)."""
        entities = [
            {"name": "both_name", "id": "both_id", "created_at": "2024-01-01T00:00:00Z"},
        ]

        # write a fresh JSONL DB file containing *only* this entity
        with open(jsonl_file, "w") as f:
            for e in entities:
                f.write(json.dumps(e) + "\n")

        handler = MemoryMcpHandler()
        cutoff = datetime(2024, 2, 1, tzinfo=timezone.utc)
        stale_items = handler.get_stale_items(cutoff)

        assert len(stale_items) == 1
        
        # when both fields exist, 'name' takes precedence
        assert "name" in stale_items[0]
        assert stale_items[0]["name"] == "both_name"

    def test_iso_with_z_suffix(
        self,
        jsonl_file: Path,
        apply_mock_patches: dict,
    ):
        """ISO format with Z suffix is parsed correctly."""
        with open(jsonl_file, "w") as f:
            f.write(json.dumps({"name": "z_suffix", "created_at": "2024-01-01T00:00:00Z"}) + "\n")

        handler = MemoryMcpHandler()
        cutoff = datetime(2024, 2, 1, tzinfo=timezone.utc)
        stale_items = handler.get_stale_items(cutoff)

        assert len(stale_items) == 1

    def test_iso_without_z(
        self,
        jsonl_file: Path,
        apply_mock_patches: dict,
    ):
        """ISO format with +00:00 offset is parsed correctly."""
        with open(jsonl_file, "w") as f:
            f.write(json.dumps({"name": "offset", "created_at": "2024-01-01T00:00:00+00:00"}) + "\n")

        handler = MemoryMcpHandler()
        cutoff = datetime(2024, 2, 1, tzinfo=timezone.utc)
        stale_items = handler.get_stale_items(cutoff)

        assert len(stale_items) == 1

    def test_date_only_format(
        self,
        jsonl_file: Path,
        apply_mock_patches: dict,
    ):
        """Date-only format (YYYY-MM-DD) fallback works."""
        with open(jsonl_file, "w") as f:
            f.write(json.dumps({"name": "date_only", "created_at": "2024-01-01"}) + "\n")

        handler = MemoryMcpHandler()
        cutoff = datetime(2024, 2, 1, tzinfo=timezone.utc)
        stale_items = handler.get_stale_items(cutoff)

        assert len(stale_items) == 1

    def test_naive_datetime_assumes_utc(
        self,
        jsonl_file: Path,
        apply_mock_patches: dict,
    ):
        """Naive datetimes (no timezone info) are assumed to be UTC."""
        
        # entity with time at exactly 12:00:00 UTC (no Z suffix = naive)
        with open(jsonl_file, "w") as f:
            f.write(json.dumps({"name": "naive", "created_at": "2024-01-15T12:00:00"}) + "\n")

        handler = MemoryMcpHandler()

        # if using cutoff 1 minute BEFORE the item's time → entity is NOT stale (created after cutoff)
        cutoff_before = datetime(2024, 1, 15, 11, 59, tzinfo=timezone.utc)
        stale_items = handler.get_stale_items(cutoff_before)
        assert len(stale_items) == 0

        # if using 1 minute AFTER → entity IS stale (created before cutoff)
        cutoff_after = datetime(2024, 1, 15, 12, 1, tzinfo=timezone.utc)
        stale_items = handler.get_stale_items(cutoff_after)
        assert len(stale_items) == 1

    def test_malformed_json_skipped(
        self,
        jsonl_file: Path,
        apply_mock_patches: dict,
    ):
        """Malformed JSON lines are skipped without error."""

        with open(jsonl_file, "w") as f:
            f.write(json.dumps({"name": "valid", "created_at": "2024-01-01T00:00:00Z"}) + "\n")
            f.write("not valid json\n")
            f.write(json.dumps({"name": "also_valid", "created_at": "2024-01-01T00:00:00Z"}) + "\n")

        handler = MemoryMcpHandler()
        cutoff = datetime(2024, 2, 1, tzinfo=timezone.utc)
        
        # should get both stale entities (that are valid JSON) & skip the invalid one
        stale_items = handler.get_stale_items(cutoff)

        assert len(stale_items) == 2

    def test_missing_created_at_skipped(
        self,
        with_jsonl_data: Path,
        cutoff_datetime: datetime,
        apply_mock_patches: dict,
    ):
        """Entities without created_at field are skipped."""
        handler = MemoryMcpHandler()
        items = handler.get_stale_items(cutoff_datetime)

        # no_timestamp_entity should not be in expired items
        names = [e.get("name") for e in items]
        assert "no_timestamp_entity" not in names

    def test_missing_file_returns_empty(
        self,
        apply_mock_patches: dict,
    ):
        """Non-existent JSONL file returns empty list."""
        handler = MemoryMcpHandler()
        cutoff = datetime(2024, 2, 1, tzinfo=timezone.utc)
        items = handler.get_stale_items(cutoff)

        assert items == []


class TestMemoryMcpDeleteItems:
    """Tests for MemoryMcpHandler.delete_items_from_storage()."""

    def test_delete_rewrites_file(
        self,
        with_jsonl_data: Path,
        cutoff_datetime: datetime,
        apply_mock_patches: dict,
    ):
        """Deletion rewrites JSONL file without expired entities."""
        handler = MemoryMcpHandler()
        stale_items = handler.get_stale_items(cutoff_datetime)
        deleted = handler.delete_items_from_storage(items=stale_items)

        # 4 stale entities: 
        # - 2 entities, each with either of name or id = "stale_id_and_name"
        # - 1 entity with name = "valid_id_but_stale_name"
        # - 1 entity with id = "stale_id_but_valid_name"
        assert deleted == 4

        # read back file
        with open(with_jsonl_data) as f:
            remaining = [json.loads(line) for line in f if line.strip()]

        remaining_names = [e.get("name") for e in remaining if "name" in e]
        remaining_ids = [e.get("id") for e in remaining if "id" in e]

        # stale entities should be deleted
        assert "stale_id_and_name" not in remaining_names
        assert "stale_id_and_name" not in remaining_ids
        assert "valid_id_but_stale_name" not in remaining_names
        assert "stale_id_but_valid_name" not in remaining_ids
        
        # valid entities should remain
        assert "valid_id_and_name" in remaining_names
        assert "valid_id_and_name" in remaining_ids
        assert "stale_id_but_valid_name" in remaining_names
        assert "valid_id_but_stale_name" in remaining_ids

    def test_delete_empty_list_returns_zero(
        self,
        jsonl_file: Path,
        apply_mock_patches: dict,
    ):
        """Deleting empty list returns 0."""
        handler = MemoryMcpHandler()
        deleted = handler.delete_items_from_storage([])
        assert deleted == 0


class TestMemoryMcpWipe:
    """Tests for MemoryMcpHandler.wipe()."""

    def test_wipe_clears_file(
        self,
        with_jsonl_data: Path,
        apply_mock_patches: dict,
    ):
        """Wipe removes all entities from file."""
        handler = MemoryMcpHandler()
        result = handler.wipe(backup=True)

        # all 9 entities added by the fixture (with_jsonl_data) should be gone
        assert result["wiped"] == 9 

        # ensure file is empty
        with open(with_jsonl_data) as f:
            remaining = [line for line in f if line.strip()]
        assert len(remaining) == 0

    def test_wipe_empty_file(
        self,
        jsonl_file: Path,
        apply_mock_patches: dict,
    ):
        """Wipe on empty file returns appropriate message."""
        handler = MemoryMcpHandler()
        result = handler.wipe()

        assert result["wiped"] == 0
        assert "no entities found" in result["message"]
