.PHONY: test typecheck ci

test:
	uv run pytest lib/pollen/cleanup/tests/ -v

typecheck:
	uv run mypy lib/pollen --ignore-missing-imports

ci: test typecheck
