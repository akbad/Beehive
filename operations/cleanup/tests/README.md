# Cleanup module: test suite

- This test harness provides isolated, deterministic testing for all cleanup handlers
  
> [!IMPORTANT]
> Tests never touch real user data: each test gets a fresh `tmp_path` directory created by pytest that is isolated (including from other tests) and automatically cleaned up upon test completion.

## Running tests

- To run *all* cleanup tests:
  
    ```bash
    uv run pytest operations/cleanup/tests/ -v
    ```
    
    - To print a detailed coverage table post-run:

        ```bash
        uv run pytest operations/cleanup/tests/ --cov=operations.cleanup
        ```
        
        > Add `--cov-report=term-missing` to add a column showing exact line numbers uncovered by tests.

- To only test a specific handler:

    ```bash
    uv run pytest operations/cleanup/tests/test_handlers/test_claude_mem.py -v
    ```


## File structure

```
tests/
├── conftest.py              # Shared fixtures auto-loaded by pytest
├── test_state.py            # State management tests
├── test_trash.py            # Trash/soft-delete tests
└── test_handlers/
    ├── test_claude_mem.py   # SQLite handler
    ├── test_memory_mcp.py   # JSONL handler
    ├── test_serena.py       # Filesystem handler
    └── test_qdrant.py       # HTTP API handler
```

### How Pytest finds tests

Note Pytest determines where to find tests via the following in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["operations/cleanup/tests"]
pythonpath = ["."]  # enables `operations.x` imports
```

Pytest **discovers tests without registration** via naming conventions: 

- files matching `test_*.py`
- classes starting with `Test`
- methods starting with `test_`

## Fixture architecture

- Fixtures are reusable test dependencies *(e.g. mock data, temp directories, database connections)*

    - All fixtures are defined in `conftest.py`: this is a special file that **pytest auto-loads**, making its fixtures available *<ins>without</ins> explicit imports* to all tests in this directory and its subdirectories.

- To use a fixture, simply **name it as a parameter** in the test function signature
    
    - Pytest injects it automatically and handles cleanup

- Example:

    ```python
    # use apply_mock_patches and cutoff_datetime fixtures
    def test_finds_old_items(self, apply_mock_patches, cutoff_datetime):
        handler = ClaudeMemHandler()
        items = handler.get_stale_items(cutoff_datetime)
    ```

> [!NOTE]
> Pytest also provides built-in fixtures such as: 
> 
> - `tmp_path` *(creates a new temp directory per test)*
> - `monkeypatch` *(stubs functions safely)* 
> 
> These are used throughout the test suite alongside custom fixtures.

### Datetime fixtures

> [!NOTE]
> - Using fixed dates instead of `datetime.now()` eliminates test flakiness caused by timing differences across test runs.
> - Items are expired if they have datetimes *strictly less than* the cutoff.

| Fixture | Value | Purpose |
| :--- | :--- | :--- |
| `cutoff_datetime` | `2024-01-15 12:00:00 UTC` | Reference point for all expiration tests |
| `stale_datetime` | `2024-01-01 00:00:00 UTC` | For stale/expired test items |
| `valid_datetime` | `2024-02-01 00:00:00 UTC` | For valid/non-expired test items |
| `boundary_datetime` | Same as cutoff | For testing `<` vs `<=` edge case |

### Backend-specific fixtures

#### SQLite (for the `claude-mem` handler)

| Fixture | Description |
| :--- | :--- |
| `sqlite_db` | Empty database with `session_summaries` and `observations` tables (to match `claude-mem`'s schema) |
| `with_sqlite_data` | Pre-populates database created by `sqlite_db` with one stale and one valid record in both tables |

> [!NOTE]
> Timestamps use the `Z` suffix format (e.g. `2024-01-01T00:00:00.000Z`), which signifies the UTC timezone, to match claude-mem's JS `toISOString()` output (IS0 8601).

#### JSONL (for the `memory-mcp` handler)

| Fixture | Description |
| :--- | :--- |
| `jsonl_file` | Creates empty JSONL file |
| `with_jsonl_data` | Creates 8 entities, covering ID/name collision testing (4 value patterns × 2 fields) plus 1 no-timestamp entity |

#### Serena directories (for the `serena` handler)

| Fixture | Description |
| :--- | :--- |
| `serena_memories_root` | Directory tree with 2 regular projects + 1 symlinked project (to test that it won't be touched), each real project containing `.serena/memories/*.md` |

#### Qdrant (for the HTTP API handler)

HTTP mock helpers live in `operations/cleanup/tests/http_mocks.py`.

| Helper | Description |
| :--- | :--- |
| `create_mock_http_endpoint(responses_map)` | Factory for mocking HTTP endpoints; `responses_map` maps `(method, url_substring)` → response dict, Exception, or `NonJsonHttpResponse` |
| `NonJsonHttpResponse` | Wrapper for raw bytes when testing malformed/non-JSON responses |

**Usage:**

```python
responses_map = {
    ("GET", "/collections/coding-memory"): {"status": "ok"},
    ("POST", "/points/scroll"): {"status": "ok", "result": {"points": [...]}},
}
with patch("urllib.request.urlopen", side_effect=create_mock_http_endpoint(responses_map)):
    # test code here
```

For malformed JSON:
```python
responses_map = {
    ("GET", "/collections/coding-memory"): NonJsonHttpResponse(b"not valid json {")
}
```

### Trash/state fixtures

| Fixture | Description |
| :--- | :--- |
| `archives_dir` | Temporary `.archives/` directory |
| `trash_dir` | Temporary `.archives/trash/` subdirectory |
| `state_file` | Path to `state.json` (may or may not exist) |

### The `apply_mock_patches` meta-fixture

This fixture is the **central orchestrator** patching all configuration functions to use test-oriented paths (instead of real user paths).

| Target | Patched To |
| :--- | :--- |
| `get_storage("claude_mem")` | `tmp_path/claude-mem.db` |
| `get_storage("memory_mcp")` | `tmp_path/memory.jsonl` |
| `get_path("serena_memories_root")` | `tmp_path/projects/` |
| `get_qdrant_url()` | `http://127.0.0.1:8780` |
| `get_qdrant_collection()` | `coding-memory` |
| `get_archives_dir()` | `tmp_path/.archives/` |
| `get_base_trash_dir()` | `tmp_path/.archives/trash/` |
| `get_state_path()` | `tmp_path/.archives/state.json` |

#### Usage

`apply_mock_patches` should be added to test functions' params to retrieve isolated test-oriented configs:

```python
def test_something(apply_mock_patches, with_sqlite_data):
    # All handlers now use temporary, test-specific paths
    handler = ClaudeMemHandler()
    items = handler.get_stale_items(cutoff)
```


## Note on monkeypatching

The `monkeypatch` fixture (built into pytest) allows temporarily replacing functions during a test.

> [!IMPORTANT]
> Always patch at the **import path** (where the function is used), not the module where it's defined.
>
> This is because Python's import system makes a separate, local reference to the original function when a module imports it.
>
> Patching at the source would leave the reference in the point of use, i.e. the importing module (where we want the patch to actually take effect), pointing to the original function and not the patched version meant for testing.

```python
# Correct: patches where the handler imports get_path
monkeypatch.setattr(
    "operations.cleanup.handlers.claude_mem.get_path",
    lambda _: with_sqlite_data
)

# Wrong: patches the source module (handler still uses its cached import)
monkeypatch.setattr("operations.settings.get_path", ...)
```
