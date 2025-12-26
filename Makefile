.PHONY: test typecheck ci

test:
	uv run pytest operations/cleanup/tests/ -v

typecheck:
	uv run mypy operations --ignore-missing-imports

ci: test typecheck
