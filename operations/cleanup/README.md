# Cleanup module

**<ins>What it does</ins>**

Handles **automatic, retention-based cleanup for Bureau's memory backends**

- Enforces configurable retention periods across all storage systems
- Provides a recoverable trash system where stale memories are initially moved to

**<ins>Contents</ins>**
- [Purpose](#purpose)
- [CLI commands](#cli-commands)
  - [`sweep` options](#sweep-options)
- [Configuration](#configuration)
- [Implementation](#implementation)
  - [Overall cleanup orchestration](#overall-cleanup-orchestration)
  - [Backend-specific handlers](#backend-specific-handlers)
  - [Trash system](#trash-system)
  - [State management](#state-management)
  - [Limiting cleanup runs](#limiting-cleanup-runs)

## Purpose

**Preventing unbounded memory growth** as they accumulate over sessions , while **enabling recovery** before permanent deletion occurs:

1. Export stale items to `.archives/trash/<backend>/`
2. Trashed items are permanently deleted after a grace period *(default 30 days; configure using `trash.grace_period` config setting)*

> [!IMPORTANT]
>
> - `trash.grace_period` **only** applies to items moved to trash **going forward**.
> - Changing this setting will <ins>*not*</ins> retroactively change the grace period for items already in the trash.

## CLI commands

| Command | Description |
|:--------|:------------|
| `sweep` | Primary cleanup CLI (run via `uv run sweep`) |
| `./bin/prune` | Wrapper for `sweep` |
| `./bin/empty-trash` | Immediately purge all trash (bypass grace period) |
| `./bin/wipe <storage>` | Completely erase a storage backend |

### `sweep` options

| Flag | Description |
|:-----|:------------|
| `-f, --force` | Run even if last run was <24h ago |
| `-n, --dry-run` | Show what would be deleted without deleting |
| `-s, --storage LETTERS` | Clean specific backends: `q`=Qdrant, `c`=claude-mem, `s`=Serena, `m`=memory-mcp |
| `-v, --verbose` | Show detailed output |
| `-q, --quiet` | Suppress all output except errors |
| `-e, --empty-trash` | Immediately empty all trash |
| `--wipe STORAGE [...]` | Completely erase data from storage(s) |
| `--no-backup` | Skip backup when wiping (DANGEROUS) |
| `--validate` | Validate configuration and exit |

**Examples:**

```bash
# Standard cleanup (respects 24h rate limit)
uv run sweep

# Force cleanup of just Qdrant and Serena
uv run sweep -f -s qs

# Dry run to see what would be deleted
uv run sweep -n -v

# Wipe all data from claude-mem (with backup)
uv run sweep --wipe claude-mem
```

## Configuration

Retention periods and cleanup behavior are configured in `directives.yml` (or `local.yml` for personal overrides):

```yaml
retention_period_for:
  claude_mem: 30d    # Claude-mem SQLite database
  serena: 90d        # Serena project memories
  qdrant: 180d       # Qdrant vector database
  memory_mcp: 365d   # Memory MCP knowledge graph

cleanup:
  min_interval: 24h  # Minimum time between cleanup runs

trash:
  grace_period: 30d  # Time before trash is permanently deleted
```

**Duration string format:** either of
  - `<number><unit>`, where unit is `h` (hours), `d` (days), `w` (weeks), `m` (months), `y` (years)
  - `always` **(to preserve memories indefinitely)**

See [CONFIGURATION.md](../../../docs/CONFIGURATION.md) for full details.

## Implementation

### Overall cleanup orchestration

`core.run_cleanup()` is the main cleanup orchestrator. When it's called:

1. [Configuration](../../../docs/CONFIGURATION.md) is validated to ensure:
    
    - Required keys exist
    - Values are the correct type
        
        > This includes verifying that the duration strings, as used for the retention period settings, are in the correct format (e.g. `30d`, `3m`).

2. Ensure it's been ≥24 hours since the last cleanup run; if not, exit.

    > To override, use `--force`/`-f`.

3. For each storage backend *(via [its corresponding handler class](handlers/)'s `cleanup()` entrypoint)*:

    1. Compute the staleness cutoff based on the retention period set for the backend (via `get_cutoff()`)

        > If the retention period is `always`, this cutoff will be set to `datetime.min` *(i.e. no items will be considered stale relative to this cutoff)*.

    2. Find stale items (via handler-specific selection logic)
    3. Move stale items to trash (via `export_items_to_trash(items)`) 
       
        - Trash directories are per-storage-backend: `.archives/trash/<backend>`

    4. Delete the stale items from the storage backend's underlying DB (via `delete_items_from_storage(items)`)

> [!NOTE]
>
> **Handlers follow a plugin-based architecture:**
>
> - The `CleanupHandler` abstract base class defines the `cleanup()` entrypoint used in step 3
> - Concrete handler subclasses implement backend-specific logic to (a) select stale items, (b) export them to trash, and (c) delete them from the underlying storage

4. Permanently delete trash entries that exceed the configured grace period
5. Update `last_cleanup_run` timestamp *(used in step 2)*

### Backend-specific handlers

Each handler is implemented corresponding to its memory storage backend's underlying data storage model:

| Handler | Backend | Approach |
|:--------|:--------|:---------|
| `ClaudeMemHandler` | SQLite database | SQL batch deletes + VACUUM |
| `QdrantHandler` | REST API | Scroll pagination + batch delete |
| `SerenaHandler` | Filesystem | Recursive glob + move |
| `MemoryMcpHandler` | JSONL file | Read-filter-rewrite |

#### claude-mem

- **Storage model:** SQLite DB located at `~/.claude-mem/claude-mem.db`

- **Tables cleaned:**

    - `session_summaries`: conversation summaries with request/response/learned fields
    - `observations`: units of knowledge (decisions, bugfixes, features, discoveries)

- **Implementation:**

    1. Query via SQL to find stale rows checking `created_at < cutoff` 
    2. Dump stale rows to JSON in `.archives/trash/claude-mem`
    3. Batch delete many rows at once (via `DELETE ... WHERE id IN (...)`) for efficiency
    4. Execute `VACUUM` to recover disk space from deleted rows 

        > - This step is required since SQLite does **not** do this automatically; it marks the space as reusable but keeps the filesize.
        > - `VACUUM` forcibly rebuilds the DB to reclaim disk space.

> [!NOTE]
> - `claude-mem` stores timestamps in JavaScript `toISOString()` format (e.g., `2024-01-01T00:00:00.000Z`)
> - The handler normalizes these (i.e. replaces `Z` with `+00:00`) to allow comparison with Python's timezone-aware datetimes.

#### Qdrant

- **Storage model:**

    - The backing Qdrant DB service is locally run as a Docker container on the port specified by the `port_for.qdrant_db` config setting (default: `8780`)
    - Memories are stored to it in the collection specified by the `qdrant.collection` setting (default: `coding-memory`)
    - The backing Qdrant DB is persisted to the directory specified by the `path_to.storage_for.qdrant` setting (default: `~/.qdrant/storage/`)

- **Implementation:**

    1. Iterate through all points using Qdrant's *Scroll API* (using pagination to fetch 100 points at a time to minimize memory use).

        > Note the [Scroll API's pagination is *cursor-based*](https://api.qdrant.tech/api-reference/points/scroll-points), meaning iterating through all points occurs in linear time *(and not quadratic like with position-based pagination)*. 
        >
        > This pagination is *required* for scrolling through collections with more than 10k points.
        >
        > ```python
        > while True:
        > result = scroll(limit=100, offset=offset)
        > points = result["points"]
        > # if not empty, process points...
        > offset = result["next_page_offset"]
        > if not offset:
        >     break
        > ```

    2. Check `payload.metadata.created_at` for each point against cutoff
    3. Write stale point data `(id, payload)` to the JSON in `.archives/trash/qdrant`
    4. Batch delete stale points (via a single POST to `/points/delete` with all stale IDs)

#### Serena

- **Storage model:** `.serena/memories/*.md` files under `path_to.serena_memories_root` (default: `~/code`)

- **Implementation:**

    1. Recursively discover all `.serena/memories/` directories at any depth within the configured `path_to.serena_memories_root` directory

        - **Symbolic links are skipped** to prevent accessing any locations outside the `path_to.serena_memories_root` directory

            > Note any symlinked directories would also cause an infinite loop in this step if `path_to.serena_memories_root` was a descendant of theirs.

    2. Identify stale memory files using the file's modification time (`st_mtime`)
    3. Move stale memory files to trash, *preserving project structure* for easy search & recovery of trashed memories if needed.

        - For example, upon moving to trash, a memory file at `~/code/my-project/.serena/memories/stale-memory.md` would be written to `.archives/trash/serena/my-project/stale-memory.md`

#### memory-mcp

- **Storage model:** JSONL file at `~/.memory-mcp/memory.jsonl`

- **Implementation:**

    1. Load the entire file line-by-line

        > This suboptimal approach is required since JSONL is append-only, offering no random access ability.

    2. Parse each JSON memory entity, checking its `created_at` field against the cutoff

        > - Note **entities stored by Memory MCP can be identified by either `name` or `id`**.
        >
        >     - Thus, a naive implementation trying to delete a memory entity with `name="foo"` could match an entity with `id="foo"` and delete it (incorrectly!).
        >
        > - The handler avoids this by using two separate sets to store stale entities' keys depending on whether the key is in the `name` or `id` field.

    3. Export stale entities to the JSONL file in `.archives/trash/memory-mcp/`
    4. Rewrite the original file filtered to contain only valid entities

### Trash system

Deleted items are:

- stored in `.archives/trash/<backend>/` 
- tracked via the `.manifest.json` in that directory
- held in the trash for `trash.grace_period` days (set to 30 by default) before permanent deletion

> [!IMPORTANT]
>
> - `trash.grace_period` **only** applies to items moved to trash **going forward**.
> - Changing this setting will <ins>*not*</ins> retroactively change the grace period for items already in the trash.

```
.archives/trash/
├── claude-mem/
│   ├── 2024-01-15T10-30-00_42-items.json
│   └── .manifest.json
├── memory-mcp/
│   ├── 2024-01-15T10-30-00_8-items.jsonl
│   └── .manifest.json
├── qdrant/
│   ├── 2024-01-15T10-30-00_15-items.json
│   └── .manifest.json
└── serena/
    ├── project-a/
    │   └── stale-memory.md
    └── .manifest.json
```

#### Manifest format

Each backend's trash directory contains a `.manifest.json` tracking all trashed batches:

```json
[
  {
    "trashed_at": "2024-01-15T10:30:00+00:00",
    "source": "claude-mem",
    "item_count": 42,
    "original_retention": "30d",
    "auto_purge_after": "2024-02-14T10:30:00+00:00Z",
    "files": [".archives/trash/claude-mem/2024-01-15T10-30-00_42-items.json"]
  }
]
```

> [!NOTE]
> The `auto_purge_after` field indicates when the trash entry will be permanently deleted; items remain recoverable until this time.

### State management

Cleanup state is persisted in `.archives/state.json`:

```json
{
  "last_cleanup_run": "2024-01-15T10:30:00+00:00",
  "last_trash_empty": "2024-01-15T10:30:00+00:00"
}
```

### Limiting cleanup runs

`did_recently_run()` makes sure cleanup only runs if it hasn't happened within the pre-defined interval (default 24h, configure using `cleanup.min_interval` config setting).

This is to prevent excessive:

- cleanup runs due to frequently-started sessions
- unnecessary I/O and API calls to backends
- user disruption from repeated cleanup operations

Manually override using `--force`  to disregard the configured interval and run cleanup anyway.
