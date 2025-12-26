# CI pipeline

## Key information

## Workflows

### `uv run` (reusable `uv` setup & command execution)

- Defined in [`.github/workflows/uv-run.yml`](../.github/workflows/uv-run.yml).
- Handles: checkout, `uv install` and `uv sync`    
- Caches dependencies (persisted until `uv.lock` changes)

- Executes the given command it was launched with after ensuring `uv` environment is set up

### `ci`

- Defined in [`.github/workflows/ci.yml`](../.github/workflows/ci.yml).

#### Unit tests (`test` job)

- Calls the [`uv run` workflow](#uv-run-reusable-uv-setup--command-execution) with the command:

    ```sh
    uv run pytest lib/pollen/cleanup/tests -v
    ```

    which runs the test suite at the location given in the command.

- The job passes iff all tests pass.

#### Type checking (`typecheck` job)

- Calls the [`uv run` workflow](#uv-run-reusable-uv-setup--command-execution) with the command:

    ```sh
    uv run mypy lib/pollen --ignore-missing-imports
    ```

- The job passes iff all typechecking passes.