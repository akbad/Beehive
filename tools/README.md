# *MCP and CLI tools suite*: essential must-read information

**Contents:**
- [What the setup script does](#what-the-setup-script-does)
  - [Side effects](#side-effects)
- [Tools set up by the script](#tools-set-up-by-the-script)
  - [Important: ensuring tools work properly](#important-ensuring-tools-work-properly)
- [Using the script](#using-the-script)
  - [Prerequisites](#prerequisites)
  - [Running the script](#running-the-script)
- [Configuration](#configuration)
  - [Key settings](#key-settings)
- [Data retention](#data-retention)
  - [Retention configuration](#retention-configuration)
  - [Default retention periods](#default-retention-periods)
  - [Commands](#commands)
  - [Complete wipe](#complete-wipe)
  - [Soft delete](#soft-delete)

--- 

## What the [setup script](./scripts/set-up-tools.sh) does

1. Sets up a series of essential MCPs and CLI tools (including running some MCPs & Docker containers locally) 
2. Configures [these coding agent CLIs](#supported-coding-agents) to use them

And other useful background stuff.

### Side effects

- Uses ports **8780-8785** for the servers/containers it starts.
    
    - Pulls Qdrant DB Docker image and starts a container (to back the local Qdrant MCP)

- Clones the Sourcegraph MCP and Serena repos locally so that they can be used to launch servers.

## Tools set up by the script

See [`tools.md`](tools.md) for:

- **full list of tools** set up/made available by the script
- **how to use them** (e.g. when writing prompts)

### Important: ensuring tools work properly
 
 - When using the Serena MCP with agents, you **need to activate the project *first* by providing the prompt `Activate the current dir as project using Serena`**.
     
     - Best to *always do this* when launching an agent, since Serena makes agents much more reliable & efficient at static analysis and syntax-related stuff

## Using the script

### Prerequisites

Run `./bin/check-prereqs` to verify all prerequisites are installed:

```bash
./bin/check-prereqs
```

If any are missing, install them using the instructions below.

<details>
<summary><b>npm/Node</b> - for npx-based MCP servers</summary>

Use [nvm](https://github.com/nvm-sh/nvm) to install/manage Node versions:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
    nvm install --lts && \
    nvm use --lts
```
</details>

<details>
<summary><b>uv</b> - for Python-based MCP servers and Semgrep</summary>

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```
</details>

<details>
<summary><b>Docker</b> - for Qdrant container</summary>

Install [Rancher Desktop](https://rancherdesktop.io/) or [Docker Desktop](https://docs.docker.com/get-docker/).
</details>

#### API keys

> - **Free tiers are used in this script for each service/MCP server** that isn't free/open-source in the first place; these API keys aren't used for any payments
> - API keys created here are because either:
>
>     - The service's free tier requires an API key
>     - The service offers bonus features/usage on top of the regular free tier as a bonus for signing up and using an API key  

1. Create API key at these services' websites

    - [Tavily](https://www.tavily.com/)
    - [Brave](https://brave.com/search/api/)

2. Add to as exports from shell config (`.zshrc` or `.bashrc`) **with these variable names**:

    ```bash
    export TAVILY_API_KEY=<...>
    export BRAVE_API_KEY=<...>
    ```

3. `source` your shell config to ensure they're available

### Running the script

```bash
tools/scripts/set-up-tools.sh
```

All configuration is done via YAML files. See [Configuration](#configuration) for details.

## Configuration

Beehive uses YAML configuration files at the repo root. Settings are loaded in this order (later sources override earlier):

1. **`comb.yml`** - System defaults (endpoints, package paths) - **do not edit**
2. **`queen.yml`** - Team/shared settings (agents, retention, ports, paths)
3. **`local.yml`** - Personal overrides (gitignored)
4. **Environment variables** - Highest priority for paths

For full configuration reference, see [docs/CONFIGURATION.md](../docs/CONFIGURATION.md).

### Key settings

```yaml
# queen.yml - customize these as needed

# Which agents to configure
agents:
  enabled: [claude, gemini, codex, opencode]

# MCP tool auto-approval (skips permission prompts)
mcp:
  auto_approve: no  # yes/true or no/false

# Filesystem MCP security boundary
path_to:
  fs_mcp_whitelist: ~/code

# Server ports (change if conflicts occur)
port_for:
  qdrant_db: 8780
  # ... see docs/CONFIGURATION.md for full list
```

## Data retention

Beehive automatically cleans up old memories to prevent unbounded storage growth.

### Retention configuration

Edit `queen.yml` to customize retention periods:

```yaml
retention_period_for:
  claude_mem: 30d
  serena: 90d
  qdrant: 180d
  memory_mcp: 365d

trash:
  grace_period: 30d
```

Duration format: `<number><unit>` where unit is `h` (hours), `d` (days), `w` (weeks), `m` (months), `y` (years).
Set to `"never"` to disable cleanup for a storage.

### Default retention periods

| Storage | Default | Data Type |
|:--------|:--------|:----------|
| claude-mem | 30 days | Session summaries, observations |
| Serena | 90 days | Project memories |
| Qdrant | 180 days | Solutions, patterns, insights |
| Memory MCP | 365 days | Entity relationships |

### Commands

- **Automatic cleanup**: Runs on `./bin/start-beehive` if >24h since last run
- **Manual prune**: `./bin/beehive-prune [--force] [--dry-run] [--storage L]` where `L` is a combo of letters `q` (Qdrant), `c` (claude-mem), `s` (Serena), `m` (memory-mcp); e.g., `-s smq`
- **Empty trash**: `./bin/beehive-empty-trash`
- **Wipe storage**: `./bin/beehive-wipe <storage> [<storage>...] [--no-backup] [--yes]`

### Complete wipe

To completely erase all data from one or more storages:

```bash
# Wipe a single storage (backs up to trash first)
./bin/beehive-wipe claude-mem

# Wipe multiple storages
./bin/beehive-wipe claude-mem qdrant

# Wipe all storages
./bin/beehive-wipe all

# Skip confirmation prompt
./bin/beehive-wipe all --yes

# Permanent deletion (no backup - DANGEROUS)
./bin/beehive-wipe claude-mem --no-backup --yes
```

### Soft delete

Deleted items go to `.wax/trash/` with a 30-day grace period before permanent deletion.
