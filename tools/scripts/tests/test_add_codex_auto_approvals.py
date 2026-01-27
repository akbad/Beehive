from importlib import util
from pathlib import Path

module_path = Path(__file__).resolve().parents[1] / "add-codex-auto-approvals.py"
spec = util.spec_from_file_location("add_codex_auto_approvals", module_path)
module = util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(module)
update_codex_config = module.update_codex_config


def _section_lines(content: str, section: str) -> list[str]:
    lines = content.splitlines()
    header = f"[mcp_servers.{section}]"
    start = None
    for idx, line in enumerate(lines):
        if line.strip() == header:
            start = idx + 1
            break
    if start is None:
        return []

    end = len(lines)
    for idx in range(start, len(lines)):
        if lines[idx].strip().startswith("["):
            end = idx
            break

    return [line.strip() for line in lines[start:end] if line.strip()]


def test_sets_enabled_true_for_auto_approved_servers(tmp_path):
    config_path = tmp_path / "config.toml"
    config_path.write_text(
        """
approval_policy = "on-request"

[mcp_servers.alpha]
url = "http://example.com"

[mcp_servers.beta]
url = "http://example.com"
enabled = false

[mcp_servers.gamma]
url = "http://example.com"
""".lstrip(),
        encoding="utf-8",
    )

    update_codex_config(str(config_path), ["alpha", "beta"])

    content = config_path.read_text(encoding="utf-8")
    alpha_lines = _section_lines(content, "alpha")
    beta_lines = _section_lines(content, "beta")
    gamma_lines = _section_lines(content, "gamma")

    assert "enabled = true" in alpha_lines
    assert "enabled = true" in beta_lines
    assert "enabled = true" not in gamma_lines
    assert "enabled = false" not in gamma_lines
