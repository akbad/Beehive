# Configuration reference

Bureau uses a YAML-based configuration system with a three-tier hierarchy that allows team-wide defaults while supporting personal overrides.

> [!IMPORTANT]
>
> **[`open-bureau`](../bin/open-bureau) <ins>must</ins> be re-run after editing any config values** in *any* of [the configuration sources used by Bureau](#configuration-sources-and-precedence).

***Contents***:

- [Configuration sources and precedence](#configuration-sources-and-precedence)
  - [When to use each file](#when-to-use-each-file)
- [Settings](#settings)
  - [`agents`](#agents)
  - [`mcp`](#mcp)
  - [`pal`](#pal)
  - [`retention_period_for`](#retention_period_for)
  - [`cleanup`](#cleanup)
  - [`trash`](#trash)
  - [`startup_timeout_for`](#startup_timeout_for)
  - [`port_for`](#port_for)
  - [`path_to`](#path_to)
  - [`endpoint_for`](#endpoint_for)
  - [`qdrant`](#qdrant)
- [Environment variable overrides](#environment-variable-overrides)
- [Examples](#examples)
  - [Disable specific CLI agents locally](#disable-specific-cli-agents-locally)
  - [Enable MCP tool auto-approval](#enable-mcp-tool-auto-approval)
  - [Keep memories longer](#keep-memories-longer)
  - [Use different workspace directory](#use-different-workspace-directory)
  - [Change ports to avoid conflicts](#change-ports-to-avoid-conflicts)
- [Security note for subagents spawned via PAL MCP's `clink`](#security-note-for-subagents-spawned-via-pal-mcps-clink)
  - [Solutions](#solutions)
- [Related commands](#related-commands)


## Configuration sources and precedence

Configuration is loaded and merged in this order (later sources override earlier):

| Priority | File | Purpose | Tracked by git? |
|:---------|:-----|:--------|:------------------|
| 1 (lowest) | **`charter.yml`** | Fixed system defaults | Yes |
| 2 | **`directives.yml`** | Streamlined collection of team-/user-oriented settings that are often tweaked | Yes |
| 3 | **`local.yml`** | Personal overrides | No |
| 4 (highest) | **Environment variables** | Runtime overrides *(should be used rarely; for more persistent personal overrides, use `local.yml`)* | N/A |

### When to use each file

#### `charter.yml`

- Don't edit unless you're changing upstream service endpoints or package conventions. 
- These are values that rarely (if ever) need changing.

#### `directives.yml` 

- *Read* to see examples of how to set config values (to then override in your `local.yml`).
- *Edit* to change team-wide defaults like retention periods, enabled agents, ports, or paths. 

    - Changes here affect everyone using *that* particular Bureau installation.

#### `local.yml` 

Create and write to this file for personal overrides that shouldn't be shared, e.g.: 

- custom workspace paths 
- custom retention periods for memories (configured per-MCP)
- disabling Bureau configuration for agent CLIs you don't use

## Settings

### `agents`

**File:** `directives.yml`

List of CLI agents that Bureau should configure during setup.

```yaml
agents:
  - claude    # Claude Code
  - gemini    # Gemini CLI
  - codex     # OpenAI Codex CLI
  - opencode  # OpenCode
```

Remove an agent from the list to skip configuring it. Note that the CLI's config directory must also exist (e.g., `~/.claude/` for Claude Code).

### `mcp`

**File:** `directives.yml`

MCP tool permissions.

```yaml
mcp:
  auto_approve: no  # yes/true or no/false
```

When set to `yes` or `true`, agents won't prompt for permission before using MCP tools and other common functionality (e.g. trivial bash commands). This is convenient for trusted setups but bypasses the safety confirmation dialogs.

**Accepted values:**
- `yes` or `true` - Enable auto-approval
- `no` or `false` - Require manual approval (default)

### `pal`

**File:** `directives.yml`

Configures the PAL MCP server's `clink` tool, which spawns subagents across different coding CLIs (Claude, Codex, Gemini). These settings control which models are used and which role prompts are available.

#### `pal.base-roles`

Baseline set of role prompts made available to ALL coding CLIs.

```yaml
pal:
  base-roles: all    # options: "all", "none", or list of role names
```

**Values** *(these also apply to `extra-roles` below)*:
- `all` - All discovered roles from `agents/role-prompts/`
- `none` - No roles (except the default role)
- `[list]` - Explicit list of role names corresponding to filestems in `agents/role-prompts/` (e.g., `[architect, debugger]`)

#### Per-CLI settings (`pal.<claude|codex|gemini>`)

Each CLI has its own configuration block with model and role settings.

The options (with their default values) are shown below:

**Claude:**
```yaml
pal:
  claude:
    model: sonnet      # Any valid Claude model
    extra-roles: none  # Extra roles beyond base-roles to include for Claude
```

**Codex:**
```yaml
pal:
  codex:
    model: gpt-5.2-codex   # Any valid Codex model
    effort: medium         # Options: minimal, low, medium, high, xhigh
    extra-roles: none      # Extra roles beyond base-roles to include for Codex
```

**Gemini:**
```yaml
pal:
  gemini:
    extra-roles: none  # Extra roles beyond base-roles to include for Gemini
```

### `retention_period_for`

**File:** `directives.yml`

Retention periods for each memory backend. Memories older than these thresholds are automatically moved to trash during cleanup.

```yaml
retention_period_for:
  claude_mem: 30d    # Claude-mem SQLite database
  serena: 90d        # Serena project memories
  qdrant: 180d       # Qdrant vector database
  memory_mcp: 365d   # Memory MCP knowledge graph
```

**Storage backends and cleanup methods:**

| Backend | Default retention period | Cleanup method |
|:--------|:--------|:---------------|
| `claude_mem` | 30d | SQLite DELETE + VACUUM |
| `serena` | 90d | Move `.md` files to trash |
| `qdrant` | 180d | REST API scroll + delete |
| `memory_mcp` | 365d | JSONL file rewrite |

**Duration format:** `<number><unit>` where unit is:
- `h` - hours (e.g., `24h`)
- `d` - days (e.g., `30d`)
- `w` - weeks (e.g., `2w`)
- `m` - months (e.g., `3m`)
- `y` - years (e.g., `1y`)
- `always` - disable cleanup for this storage

### `cleanup`

**File:** `directives.yml`

Controls automatic cleanup behavior.

```yaml
cleanup:
  min_interval: 24h  # Minimum time between cleanup runs
```

Cleanup runs automatically on `./bin/open-bureau` if enough time has passed since the last run.

### `trash`

**File:** `directives.yml`

Controls the soft-delete trash system.

```yaml
trash:
  grace_period: 30d  # Time before trash is permanently deleted
```

Deleted items go to `.archives/trash/` and remain recoverable until the grace period expires.

### `startup_timeout_for`

**File:** `directives.yml`

Timeouts for startup operations (in seconds).

```yaml
startup_timeout_for:
  mcp_servers: 200     # MCP server startup timeout
  docker_daemon: 120   # Docker daemon startup timeout
```

Increase these values on slower machines.

### `port_for`

**File:** `directives.yml`

Ports for locally-run servers and containers.

```yaml
port_for:
  qdrant_db: 8780        # Qdrant database
  qdrant_mcp: 8782       # Qdrant MCP server
  sourcegraph_mcp: 8783  # Sourcegraph MCP server
  semgrep_mcp: 8784      # Semgrep MCP server
  serena_mcp: 8785       # Serena MCP server
```

Change these if you have port conflicts.

### `path_to`

**File:** `directives.yml` (user-tunable) and `charter.yml` (package defaults)

File and directory paths used by Bureau and its tools.

| Setting | Default | Description |
|:--------|:--------|:------------|
| `workspace` | `~/code` | Base workspace directory; other paths derive from this |
| `serena_projects` | (= `workspace`) | Where Serena looks for project memories |
| `fs_mcp_whitelist` | (= `workspace`) | Directory boundary for Filesystem MCP access |
| `mcp_clones` | `.mcp-servers/` | Clone location for MCP server source code |
| `storage_for.claude_mem` | `~/.claude-mem/claude-mem.db` | Claude-mem SQLite database path |
| `storage_for.memory_mcp` | `~/.memory-mcp/memory.jsonl` | Memory MCP knowledge graph storage |
| `storage_for.qdrant` | `~/.qdrant/storage` | Qdrant Docker volume mount point |

> [!NOTE]
> 
> #### Paths automatically derived from `workspace`
> 
> When `workspace` is set, the following paths are automatically derived from it (unless explicitly overridden):
> 
> - `serena_projects` → same as `workspace`
> - `fs_mcp_whitelist` → same as `workspace`
> 
> This means you only need to configure `workspace` in `local.yml` to change all workspace-related paths at once.

#### YML example

```yaml
path_to:
  # User-tunable paths
  workspace: ~/code                           # Base workspace directory
  serena_projects: ~/code                     # Serena project search location
  fs_mcp_whitelist: ~/code                    # Filesystem MCP security boundary
  mcp_clones: .mcp-servers/                   # MCP server clone location (in repo root)

  # Storage paths for memory backends
  storage_for:
    claude_mem: ~/.claude-mem/claude-mem.db   # Claude-mem SQLite database
    memory_mcp: ~/.memory-mcp/memory.jsonl    # Memory MCP JSONL storage
    qdrant: ~/.qdrant/storage                 # Qdrant Docker volume mount
```

### `endpoint_for`

**File:** `charter.yml`

Cloud-hosted MCP service endpoints.

```yaml
endpoint_for:
  sourcegraph: https://sourcegraph.com
  context7: https://mcp.context7.com/mcp
  tavily: https://mcp.tavily.com/mcp/?tavilyApiKey=${TAVILY_API_KEY}
```

These rarely need changing unless you're using self-hosted instances.

### `qdrant`

**File:** `charter.yml`

Qdrant vector database settings.

```yaml
qdrant:
  collection: coding-memory    # Collection name
  embedding_provider: fastembed  # Embedding model provider
```

## Environment variable overrides

Some configuration values can be overridden via environment variables:

| Environment Variable | Overrides | Description |
|:---------------------|:----------|:------------|
| `BUREAU_WORKSPACE` | `path_to.serena_projects` | Base project directory |
| `MEMORY_MCP_STORAGE_PATH` | `path_to.storage_for.memory_mcp` | Memory MCP storage path |
| `CLAUDE_MEM_STORAGE_PATH` | `path_to.storage_for.claude_mem` | Claude-mem database path |
| `QDRANT_STORAGE_PATH` | `path_to.storage_for.qdrant` | Qdrant storage directory |
| `QDRANT_COLLECTION_NAME` | `qdrant.collection` | Qdrant collection name |
| `QDRANT_EMBEDDING_PROVIDER` | `qdrant.embedding_provider` | Embedding provider |

## Examples

### Disable specific CLI agents locally

Create `local.yml`:
```yaml
agents:
  - claude
  - gemini
  # codex and opencode omitted = not configured
```

### Enable MCP tool auto-approval

```yaml
# local.yml
mcp:
  auto_approve: yes
```

### Keep memories longer

```yaml
# local.yml
retention_period_for:
  claude_mem: 90d
  qdrant: 365d
  memory_mcp: always  # Always keep
```

### Use different workspace directory

```yaml
# local.yml
path_to:
  workspace: ~/Projects  # All other paths derive from this automatically
```

Or if you need to override individual paths:

```yaml
# local.yml
path_to:
  workspace: ~/Projects
  mcp_clones: ~/CustomMCPLocation  # Override the default (.mcp-servers/ in repo root)
```

### Change ports to avoid conflicts

For example, if port `8780` (the default Qdrant DB listening port) is already in use on your device, you could do:

```yaml
# local.yml
port_for:
  qdrant_db: 9780
```

## Security note for subagents spawned via PAL MCP's `clink`

When you delegate tasks via `clink`, the spawned CLI (Claude, Codex, or Gemini) runs with flags that bypass interactive approvals:

| CLI    | Flag                                         | Effect                        |
|:-------|:---------------------------------------------|:------------------------------|
| Claude | `--permission-mode acceptEdits`              | Auto-accepts file edits       |
| Codex  | `--dangerously-bypass-approvals-and-sandbox` | Bypasses all safety checks    |
| Gemini | `--yolo`                                     | Permissive mode (auto-approve)|

**This is intentional:** 

- Subagents are spawned programmatically (whether autonomously or via explicit prompting) by a parent agent that already has your trust. 
- Requiring interactive approval for each subagent action would break the automation flow: the whole point of delegation is autonomous execution.

### Solutions

Stash/commit changes before delegating complex tasks. If you need stronger isolation, direct agents to run `clink`-spawned agents in worktrees with fresh branches, merging the subsequent changes only if they're approved by you.

Also, don't delegate commands you wouldn't run yourself; the parent agent's judgment is only as strong as yours.

## Related commands

| Command | Description |
|:--------|:------------|
| `./bin/open-bureau` | Start Bureau (runs cleanup if needed) |
| `./bin/bureau-prune` | Manually run cleanup |
| `./bin/bureau-empty-trash` | Permanently delete trash contents |
| `./bin/bureau-wipe <storage>` | Wipe a storage backend |
| `./bin/check-prereqs` | Verify prerequisites are installed |
