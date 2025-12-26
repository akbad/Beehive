"""Tests for QdrantHandler (REST API cleanup)."""
import json
from datetime import datetime, timezone
from unittest.mock import patch, MagicMock
from urllib.error import HTTPError, URLError

from operations.cleanup.handlers.qdrant import QdrantHandler
from operations.cleanup.tests import NonJsonHttpResponse, create_mock_http_endpoint


# Define response maps to stub Qdrant HTTP API endpoints called via these tests
def _collection_exists_response():
    """Response map for existing collection check."""
    return {("GET", "/collections/coding-memory"): {"status": "ok"}}


def _scroll_response(points: list, next_offset=None):
    """Response map for scroll endpoint."""
    return {
        ("POST", "/points/scroll"): {
            "status": "ok",
            "result": {"points": points, "next_page_offset": next_offset},
        }
    }


def _delete_response(status="ok"):
    """Response map for delete endpoint."""
    return {("POST", "/points/delete"): {"status": status}}


class TestQdrantGetExpiredItems:
    """Tests for QdrantHandler.get_stale_items()."""

    def test_z_suffix_conversion(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
        stale_datetime: datetime,
        valid_datetime: datetime,
    ):
        """Z suffix is converted to +00:00 for datetime parsing."""
        old_ts = stale_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")
        new_ts = valid_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")

        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([
                {"id": 1, "payload": {"metadata": {"created_at": old_ts}}},
                {"id": 2, "payload": {"metadata": {"created_at": new_ts}}},
            ]),
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        # find the old item (id=1) but not the new one (id=2)
        ids = [item["id"] for item in items]
        assert 1 in ids
        assert 2 not in ids

    def test_pagination_with_offset(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
        stale_datetime: datetime,
    ):
        """Handler correctly paginates through large result sets."""
        old_ts = stale_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")

        # note: use list to allow mutation in nested function (int would be immutable)
        call_count = [0]

        def paginated_urlopen(req, timeout=None):
            """Simulate paginated API responses based on call count."""
            url = req.full_url if hasattr(req, 'full_url') else str(req)
            method = req.get_method() if hasattr(req, 'get_method') else 'GET'

            # set up context manager protocol for `with urlopen(...) as resp`
            mock_resp = MagicMock()
            mock_resp.__enter__ = MagicMock(return_value=mock_resp)
            mock_resp.__exit__ = MagicMock(return_value=False)

            if "collections/coding-memory" in url and method == "GET":
                mock_resp.read.return_value = json.dumps({"status": "ok"}).encode()
            elif "/points/scroll" in url:
                call_count[0] += 1
                if call_count[0] == 1:
                    # first page
                    response = {
                        "status": "ok",
                        "result": {
                            "points": [
                                {"id": i, "payload": {"metadata": {"created_at": old_ts}}}
                                for i in range(100)
                            ],
                            "next_page_offset": 100,
                        },
                    }
                else:
                    # second page (final)
                    response = {
                        "status": "ok",
                        "result": {
                            "points": [
                                {"id": i, "payload": {"metadata": {"created_at": old_ts}}}
                                for i in range(100, 150)
                            ],
                            "next_page_offset": None,
                        },
                    }
                mock_resp.read.return_value = json.dumps(response).encode()
            else:
                mock_resp.read.return_value = b'{}'

            return mock_resp

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=paginated_urlopen):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        # collected all 150 items across both pages
        assert len(items) == 150

    def test_naive_datetime_assumes_utc(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
    ):
        """Naive datetimes are assumed to be UTC."""
        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([
                # no timezone info
                {"id": 1, "payload": {"metadata": {"created_at": "2024-01-01T00:00:00"}}},
            ]),
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        assert len(items) == 1

    def test_collection_not_exists(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
    ):
        """Non-existent collection returns empty list."""
        responses_map = {
            ("GET", "/collections/coding-memory"): {"status": "error", "message": "Not found"},
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        assert items == []

    def test_http_error_handling(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
    ):
        """HTTP errors are handled gracefully."""
        def error_urlopen(req, timeout=None):
            url = req.full_url if hasattr(req, 'full_url') else str(req)
            method = req.get_method() if hasattr(req, 'get_method') else 'GET'

            if "collections/coding-memory" in url and method == "GET":
                mock_resp = MagicMock()
                mock_resp.__enter__ = MagicMock(return_value=mock_resp)
                mock_resp.__exit__ = MagicMock(return_value=False)
                mock_resp.read.return_value = json.dumps({"status": "ok"}).encode()
                return mock_resp
            elif "/points/scroll" in url:
                raise HTTPError(url, 500, "Internal Server Error", {}, None)

            mock_resp = MagicMock()
            mock_resp.__enter__ = MagicMock(return_value=mock_resp)
            mock_resp.__exit__ = MagicMock(return_value=False)
            mock_resp.read.return_value = b'{}'
            return mock_resp

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=error_urlopen):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        # returns empty list on error, not crash
        assert items == []

    def test_empty_collection(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
    ):
        """Empty collection returns empty list."""
        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([]),  # empty points list
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        assert items == []

    def test_url_error_handling(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
    ):
        """URLError (server unreachable) is handled gracefully."""
        def unreachable_urlopen(req, timeout=None):
            raise URLError("Connection refused")

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=unreachable_urlopen):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        # returns empty list when server is unreachable
        assert items == []

    def test_json_decode_error_handling(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
    ):
        """JSONDecodeError (malformed response) is handled gracefully."""
        with patch("operations.cleanup.handlers.qdrant.urlopen",
                   side_effect=create_mock_http_endpoint({
                       ("GET", "/collections/coding-memory"): NonJsonHttpResponse(b"not valid json {")
                   })):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        # returns empty list on malformed JSON
        assert items == []

    def test_exact_boundary_not_deleted(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
    ):
        """Items at exact cutoff time should NOT be deleted (< not <=)."""
        # use exact cutoff time
        boundary_ts = cutoff_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")

        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([
                {"id": 1, "payload": {"metadata": {"created_at": boundary_ts}}},
            ]),
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        # item at exact boundary should NOT be in expired list
        assert len(items) == 0

    def test_missing_payload_skipped(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
        stale_datetime: datetime,
    ):
        """Points without payload key are skipped gracefully."""
        old_ts = stale_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")

        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([
                # no payload key at all
                {"id": 1},
                # valid point for comparison
                {"id": 2, "payload": {"metadata": {"created_at": old_ts}}},
            ]),
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        ids = [item["id"] for item in items]
        assert 1 not in ids  # missing payload, skipped
        assert 2 in ids  # valid point found

    def test_missing_metadata_skipped(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
        stale_datetime: datetime,
    ):
        """Points with payload but no metadata key are skipped gracefully."""
        old_ts = stale_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")

        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([
                # has payload but no metadata
                {"id": 1, "payload": {"other_field": "value"}},
                # valid point for comparison
                {"id": 2, "payload": {"metadata": {"created_at": old_ts}}},
            ]),
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        ids = [item["id"] for item in items]
        assert 1 not in ids  # missing metadata, skipped
        assert 2 in ids  # valid point found

    def test_invalid_timestamp_skipped(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
        stale_datetime: datetime,
    ):
        """Points with unparseable timestamps are skipped gracefully."""
        old_ts = stale_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")

        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([
                # invalid timestamp format
                {"id": 1, "payload": {"metadata": {"created_at": "not-a-valid-date"}}},
                # another invalid format
                {"id": 2, "payload": {"metadata": {"created_at": "13/25/2024"}}},
                # valid point for comparison
                {"id": 3, "payload": {"metadata": {"created_at": old_ts}}},
            ]),
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)

        ids = [item["id"] for item in items]
        assert 1 not in ids  # invalid timestamp, skipped
        assert 2 not in ids  # invalid timestamp, skipped
        assert 3 in ids  # valid point found


class TestQdrantDeleteItems:
    """Tests for QdrantHandler.delete_items_from_storage()."""

    def test_delete_calls_api(
        self,
        apply_mock_patches: dict,
        cutoff_datetime: datetime,
        stale_datetime: datetime,
        valid_datetime: datetime,
    ):
        """Delete sends correct point IDs to API."""
        old_ts = stale_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")
        new_ts = valid_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")

        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([
                {"id": 1, "payload": {"metadata": {"created_at": old_ts}}},
                {"id": 2, "payload": {"metadata": {"created_at": new_ts}}},
            ]),
            **_delete_response("ok"),
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            items = handler.get_stale_items(cutoff_datetime)
            deleted = handler.delete_items_from_storage(items)

        assert deleted == 1  # only item id=1 should be expired

    def test_delete_empty_list(
        self,
        apply_mock_patches: dict,
    ):
        """Deleting empty list returns 0 without API call."""
        handler = QdrantHandler()
        deleted = handler.delete_items_from_storage([])

        assert deleted == 0

    def test_api_failure_during_delete(
        self,
        apply_mock_patches: dict,
    ):
        """API failure during delete returns 0."""
        responses_map = {
            **_delete_response("error"),
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            items = [{"id": 1, "created_at": "2024-01-01", "payload": {}}]
            deleted = handler.delete_items_from_storage(items)

        assert deleted == 0


class TestQdrantWipe:
    """Tests for QdrantHandler.wipe()."""

    def test_wipe_deletes_all_points(
        self,
        apply_mock_patches: dict,
    ):
        """Wipe removes all points from collection."""
        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([
                {"id": 1, "payload": {}},
                {"id": 2, "payload": {}},
            ]),
            **_delete_response("ok"),
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            result = handler.wipe(backup=True)

        assert result["wiped"] == 2

    def test_wipe_empty_collection(
        self,
        apply_mock_patches: dict,
    ):
        """Wipe on empty collection returns appropriate message."""
        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([]),  # Empty
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            result = handler.wipe()

        assert result["wiped"] == 0
        assert "empty" in result["message"]

    def test_wipe_without_backup(
        self,
        apply_mock_patches: dict,
    ):
        """Wipe without backup skips export step."""
        responses_map = {
            **_collection_exists_response(),
            **_scroll_response([
                {"id": 1, "payload": {}},
                {"id": 2, "payload": {}},
            ]),
            **_delete_response("ok"),
        }

        with patch("operations.cleanup.handlers.qdrant.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
            handler = QdrantHandler()
            result = handler.wipe(backup=False)

        assert result["wiped"] == 2
        assert "backup_path" not in result  # no backup was created
