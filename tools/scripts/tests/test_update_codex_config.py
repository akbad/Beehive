from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "update-codex-config.py"
SPEC = importlib.util.spec_from_file_location("add_codex_auto_approvals", SCRIPT_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


def test_update_preserves_hash_in_root_path(tmp_path: Path) -> None:
    config = '[sandbox_workspace_write]\nwritable_roots = ["/path/with#hash"]\n'
    path = tmp_path / "config.toml"
    path.write_text(config)

    MODULE.update_codex_config(
        str(path),
        auto_approve=False,
        writable_roots=["/new-root"],
    )

    updated = path.read_text()
    assert '"/path/with#hash"' in updated
    assert '"/new-root"' in updated


def test_merge_roots_is_idempotent() -> None:
    merged = MODULE.merge_roots(["/a", "/b"], ["/b", "/c"])
    assert merged == ["/a", "/b", "/c"]


def test_set_up_tools_uses_configurable_npm_root() -> None:
    script_path = Path(__file__).resolve().parents[1] / "set-up-tools.sh"
    content = script_path.read_text()

    assert "BUREAU_NPM_WRITABLE_ROOT" in content
    assert "NPM_WRITABLE_ROOT" in content
    assert '--ensure-writable-root "$NPM_WRITABLE_ROOT"' in content
