"""Tests for SerenaHandler (filesystem cleanup)."""
import os
from datetime import datetime, timezone
from pathlib import Path


from operations.cleanup.handlers.serena import SerenaHandler


class TestSerenaFindSerenaDirs:
    """Tests for SerenaHandler._find_serena_dirs()."""

    def test_finds_serena_memories_dirs(
        self,
        serena_memories_root: Path,
        apply_mock_patches: dict,
    ):
        """Finds all .serena/memories directories."""
        handler = SerenaHandler()
        dirs = handler._find_serena_dirs()

        assert len(dirs) == 2
        for d in dirs:
            assert d.name == "memories"
            assert d.parent.name == ".serena"

    def test_symlink_in_parent_skipped(
        self,
        serena_memories_root: Path,
        apply_mock_patches: dict,
    ):
        """Regression test: symlinked directories are skipped (Issue #8)."""
        handler = SerenaHandler()
        dirs = handler._find_serena_dirs()

        # find only the 2 real projects, not the symlinked one
        assert len(dirs) == 2
        # note: path is memories/ → .serena/ → project_name/, so parent.parent gets project
        project_names = [d.parent.parent.name for d in dirs]
        assert "project_0" in project_names
        assert "project_1" in project_names
        assert "symlinked_project" not in project_names

    def test_serena_dir_is_symlink_skipped(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Skips .serena directories that are themselves symlinks."""
        projects_dir = tmp_path / "projects"
        projects_dir.mkdir()

        # create a real .serena/memories in a temp location
        real_serena = tmp_path / "real_serena"
        real_memories = real_serena / "memories"
        real_memories.mkdir(parents=True)
        (real_memories / "memory.md").write_text("Memory content")

        # create project with symlinked .serena
        project = projects_dir / "project"
        project.mkdir()
        serena_link = project / ".serena"
        serena_link.symlink_to(real_serena)

        monkeypatch.setattr(
            "operations.cleanup.handlers.serena.get_path",
            lambda _: projects_dir
        )

        handler = SerenaHandler()
        dirs = handler._find_serena_dirs()

        assert len(dirs) == 0

    def test_empty_projects_dir(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Empty projects directory returns empty list."""
        projects_dir = tmp_path / "empty_projects"
        projects_dir.mkdir()

        monkeypatch.setattr(
            "operations.cleanup.handlers.serena.get_path",
            lambda _: projects_dir
        )

        handler = SerenaHandler()
        dirs = handler._find_serena_dirs()

        assert dirs == []

    def test_nonexistent_projects_dir(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Non-existent projects directory returns empty list."""
        monkeypatch.setattr(
            "operations.cleanup.handlers.serena.get_path",
            lambda _: tmp_path / "nonexistent"
        )

        handler = SerenaHandler()
        dirs = handler._find_serena_dirs()

        assert dirs == []


class TestSerenaGetExpiredItems:
    """Tests for SerenaHandler.get_stale_items()."""

    def test_mtime_comparison(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Uses file mtime for expiration comparison."""
        projects_dir = tmp_path / "projects"
        project = projects_dir / "project"
        memories_dir = project / ".serena" / "memories"
        memories_dir.mkdir(parents=True)

        # create memory file and set old mtime
        memory_file = memories_dir / "old_memory.md"
        memory_file.write_text("Old memory")

        # set mtime to January 1, 2024
        # note: os.utime takes (atime, mtime) tuple; we set both to same value
        old_time = datetime(2024, 1, 1, tzinfo=timezone.utc).timestamp()
        os.utime(memory_file, (old_time, old_time))

        monkeypatch.setattr(
            "operations.cleanup.handlers.serena.get_path",
            lambda _: projects_dir
        )

        handler = SerenaHandler()
        cutoff = datetime(2024, 1, 15, tzinfo=timezone.utc)
        items = handler.get_stale_items(cutoff)

        assert len(items) == 1
        assert items[0]["path"] == memory_file
        assert items[0]["project"] == "project"

    def test_glob_only_md_files(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Only *.md files are matched."""
        projects_dir = tmp_path / "projects"
        memories_dir = projects_dir / "project" / ".serena" / "memories"
        memories_dir.mkdir(parents=True)

        # create various file types
        (memories_dir / "memory.md").write_text("Markdown")
        (memories_dir / "memory.txt").write_text("Text")
        (memories_dir / "memory.json").write_text("{}")

        # set all to old mtime
        old_time = datetime(2024, 1, 1, tzinfo=timezone.utc).timestamp()
        for f in memories_dir.iterdir():
            os.utime(f, (old_time, old_time))

        monkeypatch.setattr(
            "operations.cleanup.handlers.serena.get_path",
            lambda _: projects_dir
        )

        handler = SerenaHandler()
        cutoff = datetime(2024, 1, 15, tzinfo=timezone.utc)
        items = handler.get_stale_items(cutoff)

        # only .md file should be found
        assert len(items) == 1
        assert items[0]["path"].suffix == ".md"

    def test_project_name_extraction(
        self,
        serena_memories_root: Path,
        apply_mock_patches: dict,
    ):
        """Project name is extracted from directory structure."""
        # set old mtime on all memory files
        old_time = datetime(2024, 1, 1, tzinfo=timezone.utc).timestamp()
        for f in serena_memories_root.rglob("*.md"):
            os.utime(f, (old_time, old_time))

        handler = SerenaHandler()
        cutoff = datetime(2024, 1, 15, tzinfo=timezone.utc)
        items = handler.get_stale_items(cutoff)

        # should have items from both projects
        project_names = set(item["project"] for item in items)
        assert "project_0" in project_names
        assert "project_1" in project_names

    def test_new_files_not_expired(
        self,
        serena_memories_root: Path,
        apply_mock_patches: dict,
    ):
        """Files with recent mtime are not expired."""
        handler = SerenaHandler()
        # use a cutoff in the past (files should be newer)
        cutoff = datetime(2020, 1, 1, tzinfo=timezone.utc)
        items = handler.get_stale_items(cutoff)

        # all files were just created, so none should be expired
        assert items == []


class TestSerenaDeleteItems:
    """Tests for SerenaHandler.delete_items_from_storage()."""

    def test_move_not_copy(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Files are moved to trash, not copied."""
        projects_dir = tmp_path / "projects"
        memories_dir = projects_dir / "project" / ".serena" / "memories"
        memories_dir.mkdir(parents=True)

        memory_file = memories_dir / "memory.md"
        memory_file.write_text("Memory content")
        original_path = memory_file

        # set old mtime
        old_time = datetime(2024, 1, 1, tzinfo=timezone.utc).timestamp()
        os.utime(memory_file, (old_time, old_time))

        # setup trash dir
        trash_dir = tmp_path / ".archives" / "trash"
        monkeypatch.setattr(
            "operations.cleanup.trash.BASE_TRASH_DIR",
            trash_dir
        )
        monkeypatch.setattr(
            "operations.cleanup.handlers.serena.get_path",
            lambda _: projects_dir
        )

        handler = SerenaHandler()
        cutoff = datetime(2024, 1, 15, tzinfo=timezone.utc)
        items = handler.get_stale_items(cutoff)

        # export moves files
        handler.export_items_to_trash(items, "90d")
        deleted = handler.delete_items_from_storage(items)

        # original file should no longer exist
        assert not original_path.exists()
        assert deleted == 1

    def test_delete_returns_count(self):
        """delete_items_from_storage returns count of items (files already moved)."""
        handler = SerenaHandler()
        items = [
            {"path": Path("/fake/1.md"), "project": "p1"},
            {"path": Path("/fake/2.md"), "project": "p2"},
        ]

        # files don't exist, but delete_items_from_storage just returns count
        # (export_items_to_trash already moved them)
        deleted = handler.delete_items_from_storage(items)
        assert deleted == 2


class TestSerenaWipe:
    """Tests for SerenaHandler.wipe()."""

    def test_wipe_all_memory_files(
        self,
        serena_memories_root: Path,
        apply_mock_patches: dict,
    ):
        """Wipe removes all memory files from all projects."""
        handler = SerenaHandler()
        result = handler.wipe(backup=True)

        # 2 projects x 2 memories each = 4 files
        assert result["wiped"] == 4

        # verify files are gone
        remaining = list(serena_memories_root.rglob("*.md"))
        assert len(remaining) == 0

    def test_wipe_no_backup(
        self,
        serena_memories_root: Path,
        apply_mock_patches: dict,
    ):
        """Wipe without backup deletes files directly."""
        handler = SerenaHandler()
        result = handler.wipe(backup=False)

        assert result["wiped"] == 4
        assert "backup_path" not in result

        # files should be deleted
        remaining = list(serena_memories_root.rglob("*.md"))
        assert len(remaining) == 0

    def test_wipe_empty_projects(
        self,
        tmp_path: Path,
        monkeypatch,
    ):
        """Wipe on empty projects directory returns appropriate message."""
        projects_dir = tmp_path / "empty_projects"
        projects_dir.mkdir()

        monkeypatch.setattr(
            "operations.cleanup.handlers.serena.get_path",
            lambda _: projects_dir
        )

        handler = SerenaHandler()
        result = handler.wipe()

        assert result["wiped"] == 0
        assert "no memory files found" in result["message"]
