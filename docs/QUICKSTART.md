# Quick setup guide

Since the automated context injection enables agents to automatically and autonomously leverage Beehive's features, those who want to skip the learning curve *entirely* can follow these steps to set up as fast as possible.

> [!IMPORTANT]
> ### Default configuration values (and how to change them)
>
> | Setting | Default | How to customize |
> | :--- | :--- | :--- |
> | Filesystem MCP whitelist | `~/code` | Set `path_to.fs_mcp_whitelist` in `local.yml` |
> | MCP server clone directory | `~/code/mcp-servers` | Set `path_to.mcp_clones` in `local.yml` |
> | Enabled CLI agents | All 4 (claude, gemini, codex, opencode) | Set `agents` list in `local.yml` |
> | Memory retention | 30d-365d depending on storage | Set `retention_period_for.*` in `local.yml` |
>
> Create `local.yml` at the repo root for personal overrides (it's gitignored).
>
> See [CONFIGURATION.md](CONFIGURATION.md) for all options. 

## Setup steps

### Selecting CLI agents to configure

By default, all 4 CLIs are enabled in `queen.yml`. To customize which CLIs are configured, edit the `agents` list in `local.yml`:

```yaml
# local.yml
agents:
  - claude
  - gemini
  # codex and opencode omitted = not configured
```

### Run the startup/bootstrap script

```bash
./bin/start-beehive
```

> [!TIP]
> Add the [root-level `bin/` directory](../bin/) to your shell's `$PATH` to be able to start up (and take down) Beehive's services from anywhere on your machine.

### *If using Claude Code:* install the [`claude-mem` automatic context management](https://github.com/thedotmack/claude-mem) and the [Obra Superpowers](https://github.com/obra/superpowers) plugins

After launching Claude Code, run:

```
> /plugin marketplace add thedotmack/claude-mem
> /plugin install claude-mem

> /plugin marketplace add obra/superpowers-marketplace
> /plugin install superpowers@superpowers-marketplace
```

> [!NOTE]
> The Superpowers plugin also works for Codex. The setup script automatically installs it under `~/.codex/superpowers/` — no manual command needed.

### Verify setup

See the [verification steps in SETUP.md](SETUP.md#making-sure-it-works) to confirm everything is working correctly for each CLI.