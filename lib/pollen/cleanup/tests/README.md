# Cleanup module: test suite

- This test harness provides isolated, deterministic testing for all cleanup handlers
  
> [!IMPORTANT]
> Tests never touch real user data: each test gets a fresh `tmp_path` from pytest.

> [!NOTE]
> All fixtures are defined in `conftest.py`.
>
> This is a special file that **pytest auto-loads**, making its fixtures available *<ins>without</ins> explicit imports* to all tests in this directory and its subdirectories.

## Running tests

- To run *all* cleanup tests:
  
    ```bash
    uv run pytest lib/pollen/cleanup/tests/ -v
    ```

- To only test a specific handler:

    ```bash
    uv run pytest lib/pollen/cleanup/tests/test_handlers/test_claude_mem.py -v
    ```

- To receive a coverage report post-run:

    ```bash
    uv run pytest lib/pollen/cleanup/tests/ --cov=lib.pollen.cleanup
    ```

> [!TIP]
>
> Add `--cov-report=term-missing` to see exact uncovered spots.

Pytest knows where to find tests via `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["lib/pollen/cleanup/tests"]
pythonpath = ["."]  # enables `lib.pollen.x` imports
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

Pytest **discovers tests without registration** via naming conventions: 

- files matching `test_*.py`
- classes starting with `Test`
- methods starting with `test_`

## Fixture architecture

- Fixtures are reusable test dependencies *(e.g. mock data, temp directories, database connections)*
- To use a fixture, simply **name it as a parameter**
- Pytest injects it automatically and handles cleanup
- Example:

    ```python
    # use mock_settings and cutoff_datetime fixtures
    def test_finds_old_items(self, mock_settings, cutoff_datetime):
        handler = ClaudeMemHandler()
        items = handler.get_expired_items(cutoff_datetime)
    ```

> [!NOTE]
> Pytest also provides built-in fixtures such as: 
> 
> - `tmp_path` *(creates a new temp directory per test)*
> - `monkeypatch` *(stubs functions safely)* 
> 
> These are used throughout the test suite alongside custom fixtures.

