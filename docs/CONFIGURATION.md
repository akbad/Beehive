# Configuration reference

Beehive uses a YAML-based configuration system with a three-tier hierarchy that allows team-wide defaults while supporting personal overrides.

## Config file precedence

Configuration is loaded and merged in this order (later sources override earlier):

| Priority | File | Purpose | Tracked by git? |
|:---------|:-----|:--------|:------------------|
| 1 (lowest) | `comb.yml` | Fixed system defaults | Yes |
| 2 | `queen.yml` | Team-tunable settings | Yes |
| 3 | `local.yml` | Personal overrides | No |
| 4 (highest) | Environment variables | Runtime overrides | N/A |

### When to use each file

- **`comb.yml`**: Don't edit unless you're changing upstream service endpoints or package conventions. These are values that rarely (if ever) need changing.

- **`queen.yml`**: Edit to change team-wide defaults like retention periods, enabled agents, ports, or paths. Changes here affect everyone using this Beehive installation.

- **`local.yml`**: Create this file for personal overrides that shouldn't be shared (e.g., different workspace paths, custom retention periods, disabling certain agents locally).

## Configuration sections

### `agents`

**File:** `queen.yml`

List of CLI agents that Beehive should configure during setup.

```yaml
agents:
  - claude    # Claude Code
  - gemini    # Gemini CLI
  - codex     # OpenAI Codex CLI
  - opencode  # OpenCode
```

Remove an agent from the list to skip configuring it. Note that the CLI's config directory must also exist (e.g., `~/.claude/` for Claude Code).

### `mcp`

**File:** `queen.yml`

MCP tool permissions.

```yaml
mcp:
  auto_approve: no  # yes/true or no/false
```

When set to `yes` or `true`, agents won't prompt for permission before using MCP tools and other common functionality (e.g. trivial bash commands). This is convenient for trusted setups but bypasses the safety confirmation dialogs.

**Accepted values:**
- `yes` or `true` - Enable auto-approval
- `no` or `false` - Require manual approval (default)

### `retention_period_for`

**File:** `queen.yml`

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

**File:** `queen.yml`

Controls automatic cleanup behavior.

```yaml
cleanup:
  min_interval: 24h  # Minimum time between cleanup runs
```

Cleanup runs automatically on `./bin/start-beehive` if enough time has passed since the last run.

### `trash`

**File:** `queen.yml`

Controls the soft-delete trash system.

```yaml
trash:
  grace_period: 30d  # Time before trash is permanently deleted
```

Deleted items go to `.wax/trash/` and remain recoverable until the grace period expires.

### `startup_timeout_for`

**File:** `queen.yml`

Timeouts for startup operations (in seconds).

```yaml
startup_timeout_for:
  mcp_servers: 200     # MCP server startup timeout
  docker_daemon: 120   # Docker daemon startup timeout
```

Increase these values on slower machines.

### `port_for`

**File:** `queen.yml`

Ports for locally-run servers and containers.

```yaml
port_for:
  qdrant_db: 8780        # Qdrant database
  zen_mcp: 8781          # Zen MCP server
  qdrant_mcp: 8782       # Qdrant MCP server
  sourcegraph_mcp: 8783  # Sourcegraph MCP server
  semgrep_mcp: 8784      # Semgrep MCP server
  serena_mcp: 8785       # Serena MCP server
```

Change these if you have port conflicts.

### `path_to`

**File:** `queen.yml` (user-tunable) and `comb.yml` (package defaults)

#### User-tunable paths (in `queen.yml`)

```yaml
path_to:
  workspace: ~/code        # Base workspace directory
```

**Path derivation:** When `workspace` is set, the following paths are automatically derived from it (unless explicitly overridden):

- `serena_projects` → same as `workspace`
- `fs_mcp_whitelist` → same as `workspace`
- `mcp_clones` → `{workspace}/mcp-servers`

This means you only need to configure `workspace` in `local.yml` to change all workspace-related paths at once.

#### Storage paths (nested under `path_to`)

Storage paths for memory backends are configured under `path_to.storage_for`:

```yaml
path_to:
  storage_for:
    claude_mem: ~/.claude-mem/claude-mem.db   # Claude-mem database
    memory_mcp: ~/.memory-mcp/memory.jsonl    # Memory MCP JSONL storage
    qdrant: ~/.qdrant/storage                 # Qdrant Docker volume mount
```

### `endpoint_for`

**File:** `comb.yml`

Cloud-hosted MCP service endpoints.

```yaml
endpoint_for:
  sourcegraph: https://sourcegraph.com
  context7: https://mcp.context7.com/mcp
  tavily: https://mcp.tavily.com/mcp/?tavilyApiKey=${TAVILY_API_KEY}
```

These rarely need changing unless you're using self-hosted instances.

### `qdrant`

**File:** `comb.yml`

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
| `BEEHIVE_WORKSPACE` | `path_to.serena_projects` | Base project directory |
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

Or if you need to override individual derived paths:

```yaml
# local.yml
path_to:
  workspace: ~/Projects
  mcp_clones: ~/CustomMCPLocation  # Override just this one
```

### Change ports to avoid conflicts

```yaml
# local.yml
port_for:
  qdrant_db: 9780
  zen_mcp: 9781
```

## Related commands

| Command | Description |
|:--------|:------------|
| `./bin/start-beehive` | Start Beehive (runs cleanup if needed) |
| `./bin/beehive-prune` | Manually run cleanup |
| `./bin/beehive-empty-trash` | Permanently delete trash contents |
| `./bin/beehive-wipe <storage>` | Wipe a storage backend |
| `./bin/check-prereqs` | Verify prerequisites are installed |
