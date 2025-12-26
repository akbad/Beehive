#!/usr/bin/env -S uv run
"""Cleanup CLI entrypoint"""
import argparse
import sys

from ..config_loader import (
    get_config,
    get_retention,
    get_cleanup_interval,
    get_trash_grace_period,
    parse_duration,
)
from ..validate_config import full_validate
from .state import load_state, save_state, did_recently_run, now_as_iso, State
from .trash import empty_expired_trash, empty_all_trash
from .handlers import HANDLERS

# compute config-derived values once at module load
_config = get_config()
_min_interval = parse_duration(get_cleanup_interval())
_interval_hours = int(_min_interval.total_seconds() / 3600)


def run_cleanup(
    force: bool = False,
    dry_run: bool = False,
    memory_backends: list[str] | None = None,
    verbose: bool = False,
) -> dict:
    """Run cleanup for all or specific storage."""
    # Validate configuration before running cleanup
    validation_errors = full_validate(_config)
    if validation_errors:
        return {
            "error": "Configuration validation failed",
            "validation_errors": validation_errors,
            "errors": [{"storage": "config", "error": e} for e in validation_errors],
        }

    state = load_state()
    errors: list[dict] = []

    # check if we ran recently (unless forced)
    if not force and did_recently_run(state, N=_interval_hours):
        return {
            "skipped": True,
            "reason": f"Last run was <{get_cleanup_interval()} ago, skipping (override with --force/-f)",
            "last_run": state.get("last_cleanup_run"),
        }

    results = []

    # filter handlers if requested to clear specific storage only
    handlers_to_run = HANDLERS
    if memory_backends:
        requested = {s.replace("-", "_") for s in memory_backends}
        handlers_to_run = tuple(h for h in HANDLERS if h.name.replace("-", "_") in requested)  # type: ignore[assignment]
        if not handlers_to_run:
            return {"error": f"Unknown storage: {', '.join(memory_backends)}", "errors": errors}

    # run cleanup for each handler in the list (i.e. each memory backend selected)
    for handler_class in handlers_to_run:
        handler = handler_class()
        retention = get_retention(handler.name)

        if verbose:
            print(f"Cleaning {handler.name} (retention: {retention})...")

        try:
            result = handler.cleanup(retention, dry_run=dry_run)
            results.append(result)

            if result.get("error"):
                errors.append({
                    "storage": handler.name,
                    "error": result.get("error"),
                })

            if verbose:
                if result.get("skipped"):
                    print(f"  Skipped: {result.get('reason')}")
                elif result.get("dry_run"):
                    print(f"  Would delete: {result.get('would_delete')} items")
                else:
                    print(f"  Deleted: {result.get('deleted')} items")
        except Exception as e:
            results.append({
                "storage": handler.name,
                "error": str(e),
            })
            errors.append({
                "storage": handler.name,
                "error": str(e),
            })
            if verbose:
                print(f"  Error: {e}")

    # empty expired trash (unless doing a dry run)
    trash_result = {"trash_emptied": 0}
    if not dry_run:
        grace_period = get_trash_grace_period()
        deleted_count = empty_expired_trash(grace_period)
        trash_result = {"trash_emptied": deleted_count}

        if verbose and deleted_count:
            print(f"Emptied {deleted_count} items from trash (older than {grace_period})")

        # update state
        state_update = State({"last_cleanup_run": now_as_iso()})
        if deleted_count:
            state_update["last_trash_empty"] = now_as_iso()
        save_state(state_update)

    return {
        "results": results,
        **trash_result,
        "dry_run": dry_run,
        "errors": errors,
    }


def wipe_memory_backends(
    memory_backends: list[str],
    backup: bool = True,
    verbose: bool = False,
) -> dict:
    """Completely erase *all* data from the specified memory backend(s).

    Args:
        memory_backends: List of memory backends to wipe (e.g., ["claude-mem", "qdrant"])
        backup: If True, backup data to trash before wiping
        verbose: If True, print progress

    Returns:
        Dict with results per storage
    """
    config = get_config()

    # Validate configuration before wiping
    validation_errors = full_validate(config)
    if validation_errors:
        return {
            "error": "Configuration validation failed",
            "validation_errors": validation_errors,
            "results": [{"storage": "config", "error": e} for e in validation_errors],
        }

    results = []

    # map storage names to handlers
    handler_map = {h.name.replace("-", "_"): h for h in HANDLERS}

    for storage in memory_backends:
        storage_normalized = storage.replace("-", "_")
        handler_class = handler_map.get(storage_normalized)

        if not handler_class:
            results.append({
                "storage": storage,
                "error": f"Unknown storage: {storage}",
            })
            continue

        handler = handler_class()

        if verbose:
            print(f"Wiping {handler.name}...")

        try:
            result = handler.wipe(backup=backup)
            results.append(result)

            if verbose:
                if result.get("wiped", 0) > 0:
                    print(f"  Wiped: {result['wiped']} items")
                    if result.get("backup_path"):
                        print(f"  Backup: {result['backup_path']}")
                else:
                    print(f"  {result.get('message', 'Nothing to wipe')}")
        except Exception as e:
            results.append({
                "storage": handler.name,
                "error": str(e),
            })
            if verbose:
                print(f"  Error: {e}")

    return {"results": results}


# Entrypoint for cleanup CLI: called via `uv run sweep-hive [args]`
def main():
    STORAGE_MAP = {
        "q": "qdrant",
        "c": "claude-mem",
        "s": "serena",
        "m": "memory-mcp",
    }

    def parse_storage_letters(value: str) -> list[str]:
        letters = list(dict.fromkeys(value.lower()))  # dedupe, preserve order
        invalid = [ch for ch in letters if ch not in STORAGE_MAP]
        if invalid:
            raise argparse.ArgumentTypeError(f"Invalid storage letter(s): {', '.join(invalid)} (use any of q/c/s/m)")
        return [STORAGE_MAP[ch] for ch in letters]

    parser = argparse.ArgumentParser(
        description="Beehive cleanup: remove old memories based on retention settings"
    )
    parser.add_argument(
        "--force", "-f",
        action="store_true",
        help="Run even if last run was less than 24 hours ago"
    )
    parser.add_argument(
        "--dry-run", "-n",
        action="store_true",
        help="Show what would be deleted without actually deleting"
    )
    parser.add_argument(
        "--storage", "-s",
        type=parse_storage_letters,
        metavar="LETTERS",
        help="Clean specific storage services by letter: q=Qdrant, c=claude-mem, s=Serena, m=memory-mcp (e.g., -s smq)"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show detailed output"
    )
    parser.add_argument(
        "--quiet", "-q",
        action="store_true",
        help="Suppress all output except errors"
    )
    parser.add_argument(
        "--empty-trash", "-e",
        action="store_true",
        help="Immediately empty all trash, bypassing grace period"
    )
    parser.add_argument(
        "--wipe",
        nargs="+",
        metavar="STORAGE",
        help="Completely erase data from storage(s): claude-mem, serena, qdrant, memory-mcp"
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Skip backup when wiping (DANGEROUS - data will be permanently lost)"
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate configuration and exit"
    )

    args = parser.parse_args()

    # if CLI arg set, validate config and exit
    if args.validate:
        config = get_config()
        errors = full_validate(config)
        if errors:
            print("Configuration validation failed:", file=sys.stderr)
            for error in errors:
                print(f"  - {error}", file=sys.stderr)
            return 1
        print("Configuration is valid.")
        return 0

    # if CLI arg set, empty existing trash contents immediately (bypass grace period)
    if args.empty_trash:
        result = empty_all_trash()
        if not args.quiet:
            print(f"Emptied {result['emptied']} items from trash")
        return 0

    # if CLI arg set, wipe all data from specified storage(s)
    if args.wipe:
        result = wipe_memory_backends(
            memory_backends=args.wipe,
            backup=not args.no_backup,
            verbose=args.verbose and not args.quiet
        )

        if not args.quiet:
            total_wiped = sum(r.get('wiped', 0) for r in result['results'])
            errors = [r for r in result['results'] if r.get('error')]

            if errors:
                for e in errors:
                    print(f"Error ({e['storage']}): {e['error']}", file=sys.stderr)
                return 1
            elif args.verbose:
                import json
                print(json.dumps(result, indent=2, default=str))
            else:
                print(f"Wiped {total_wiped} items from {len(args.wipe)} storage(s)")

        return 0

    # core cleanup orchestrator: 
    # - executes per-storage-backend handlers
    # - collects results
    # - cleans up trash/state
    result = run_cleanup(
        force=args.force,
        dry_run=args.dry_run,
        memory_backends=args.storage,
        verbose=args.verbose and not args.quiet,
    )

    # top-level error (e.g., unknown storage)
    if result.get("error"):
        if not args.quiet:
            print(f"Error: {result.get('error')}", file=sys.stderr)
        return 1

    if not args.quiet:
        if result.get("skipped"):
            print(result.get("reason"))
            return 0
        if args.verbose:
            import json
            print(json.dumps(result, indent=2, default=str))
        if result.get("errors"):
            for err in result["errors"]:
                print(f"[{err.get('storage')}] {err.get('error')}", file=sys.stderr)
            return 1
    else:
        if result.get("errors"):
            return 1

    return 0
