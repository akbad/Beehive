"""Trash management for Beehive cleanup."""
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from ..config_loader import parse_duration, get_trash_dir as get_base_trash_dir
from .state import now_as_iso

BASE_TRASH_DIR = get_base_trash_dir()


def get_trash_dir(backend_name: str) -> Path:
    """
        Find trash directory for a specific memory backend.
        Trash directories are defined per backend: .wax/trash/<backend-name>
    """
    trash_path = BASE_TRASH_DIR / backend_name
    trash_path.mkdir(parents=True, exist_ok=True)
    return trash_path


def generate_trash_filename(item_count: int, extension: str = "json") -> str:
    """Generate a timestamped trash filename."""
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%S")
    return f"{timestamp}_{item_count}-items.{extension}"


def write_manifest(trash_path: Path, storage_name: str, item_count: int,
                   retention: str, grace_period: str = "30d",
                   files: list[Path] | None = None) -> None:
    """Write manifest file for trashed items."""
    now = now_as_iso()
    grace_delta = parse_duration(grace_period)
    purge_after = datetime.now(timezone.utc) + grace_delta

    manifest = {
        "trashed_at": now,
        "source": storage_name,
        "item_count": item_count,
        "original_retention": retention,
        "auto_purge_after": purge_after.isoformat() + "Z",
        "files": [str(f) for f in files] if files else [],
    }

    manifest_path = trash_path / ".manifest.json"

    # append to existing manifest or create new
    existing = []
    if manifest_path.exists():
        try:
            with open(manifest_path) as f:
                existing = json.load(f)
                if not isinstance(existing, list):
                    existing = [existing]
        except (json.JSONDecodeError, IOError):
            existing = []

    existing.append(manifest)

    with open(manifest_path, "w") as f:
        json.dump(existing, f, indent=2)


def move_to_trash(source_path: Path, 
                  storage_name: str,
                  project_name: Optional[str] = None  # for memories from Serena
                 ) -> Path:
    """Move an *existing* file/dir to trash (preserving Serena files' structure)."""
    trash_base = get_trash_dir(storage_name)

    if project_name:
        # the file belongs to a Serena project
        trash_dest = trash_base / project_name / source_path.name
        trash_dest.parent.mkdir(parents=True, exist_ok=True)
    else:
        trash_dest = trash_base / source_path.name

    shutil.move(str(source_path), str(trash_dest))
    return trash_dest


def empty_expired_trash(grace_period: str) -> int:
    """Remove items in the trash that are older than the grace period, 
        returning the count of items removed."""
    if not BASE_TRASH_DIR.exists():
        return 0

    grace_delta = parse_duration(grace_period)
    removed_count = 0
    
    # delete everything moved to trash before this date
    cutoff = datetime.now(timezone.utc) - grace_delta

    for storage_dir in BASE_TRASH_DIR.iterdir():
        if not storage_dir.is_dir():
            continue

        manifest_path = storage_dir / ".manifest.json"
        if not manifest_path.exists():
            continue

        try:
            with open(manifest_path) as f:
                manifests = json.load(f)
                if not isinstance(manifests, list):
                    manifests = [manifests]
        except (json.JSONDecodeError, IOError):
            continue

        remaining = []
        for entry in manifests:
            # check each trash entry for expiration
            trashed_at = entry.get("trashed_at", "")
            files = [Path(p) for p in entry.get("files", [])]
            try:
                trashed_dt = datetime.fromisoformat(trashed_at)
                # Ensure timezone-aware comparison (assume UTC for naive datetimes)
                if trashed_dt.tzinfo is None:
                    trashed_dt = trashed_dt.replace(tzinfo=timezone.utc)
                expired = trashed_dt < cutoff
            except (ValueError, TypeError):
                expired = False

            if expired:
                # delete listed files; if files list is absent, skip silently
                for fpath in files:
                    if fpath.is_absolute():
                        try:
                            rel = fpath.relative_to(storage_dir)
                            full_path = storage_dir / rel
                        except ValueError:
                            full_path = fpath
                    else:
                        full_path = storage_dir / fpath
                    try:
                        if full_path.is_file():
                            full_path.unlink()
                            removed_count += 1
                        elif full_path.is_dir():
                            shutil.rmtree(full_path)
                    except FileNotFoundError:
                        pass  # Already deleted, continue
                
                # if files list is absent, fall back to deleting all non-manifest 
                #   files whose last edited time is older than the cutoff
                if not files:
                    for candidate in storage_dir.rglob("*"):
                        if candidate.name == ".manifest.json":
                            continue
                        try:
                            if candidate.stat().st_mtime < cutoff.timestamp() and candidate.is_file():
                                candidate.unlink()
                                removed_count += 1
                        except FileNotFoundError:
                            continue
            else:
                remaining.append(entry)

        if remaining:
            # if there are any files not meant to be deleted, rewrite the manifest
            #   at the manifest_path in this storage_dir
            with open(manifest_path, "w") as f:
                json.dump(remaining, f, indent=2)
        else:
            # remove entire storage_dir from the trash filetree if empty
            shutil.rmtree(storage_dir)

    return removed_count


def empty_all_trash() -> dict:
    """Immediately empty *all* trash, overriding the default grace period."""
    if not BASE_TRASH_DIR.exists():
        return {"emptied": 0, "message": "Trash directory does not exist"}

    # count items to be permanently deleted (excluding directories & manifest files)
    count = 0
    for storage_dir in BASE_TRASH_DIR.iterdir():
        if storage_dir.is_dir():
            for item in storage_dir.rglob("*"):
                if item.is_file() and item.name != ".manifest.json":
                    count += 1
            shutil.rmtree(storage_dir)

    return {"emptied": count, "message": "All trash emptied"}
