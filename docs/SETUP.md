# Beehive: setup guide

> [!TIP]
> You don't technically have to learn what the different agents and MCPs available are (other than for setting up prerequisites), they should all be used automatically by your CLI agents when needed.
>
> [**See the quickstart guide**](QUICKSTART.md) for quick setup steps that take only a few minutes.

## Selecting CLI agents to configure

Beehive configures CLIs based on the `agents` list in your configuration files:

```yaml
# queen.yml (or local.yml for personal overrides)
agents:
  - claude    # Claude Code
  - gemini    # Gemini CLI
  - codex     # Codex
  - opencode  # OpenCode
```

### Adding or removing CLIs

Edit `queen.yml` (for team-wide changes) or create `local.yml` (for personal overrides) and modify the `agents` list. Then re-run `./bin/start-beehive`.

> [!NOTE]
> The CLI's config directory must exist for configuration to succeed (e.g., `~/.claude/` for Claude Code).

## Beehive configuration

Beehive uses YAML configuration files at the repository root. These control which agents are configured, retention periods, server ports, and more.

### Configuration hierarchy

Configuration loads in order *(i.e. settings/config values in later sources override those from earlier ones)*:

1. **`comb.yml`** - Fixed system defaults
   - Cloud endpoints (Sourcegraph, Context7, Tavily)
   - Package-standard paths (`~/.claude-mem/`, `~/.memory-mcp/`)
   - Qdrant settings (collection name, embedding provider)

2. **`queen.yml`** - Team/shared configuration
   - Agent selection (which CLIs to configure)
   - Retention periods (how long to keep memories)
   - Server ports and startup timeouts
   - Workspace paths

3. **`local.yml`** - Personal overrides not meant to be tracked by git
   - Any value from `queen.yml` can be overridden
   - Create this file for settings you don't want to share

4. **Environment variables** - Highest priority, overrides all other settings/config sources
   - `BEEHIVE_WORKSPACE`, `MEMORY_MCP_STORAGE_PATH`, etc.

See [CONFIGURATION.md](CONFIGURATION.md) for all available options.

## MCPs

1. Read the [must-read information about the setup script](../tools/README.md) and ensure you have the listed prerequisites set up.
2. Run the [setup script](../tools/scripts/set-up-tools.sh):
    
   ```bash
   tools/scripts/set-up-tools.sh [options]
   ```

3. **Claude Code only:** install the [`claude-mem` automatic context management](https://github.com/thedotmack/claude-mem) and the [Obra Superpowers](https://github.com/obra/superpowers) plugins via Claude's `/plugin` commands:

   ```
   > /plugin marketplace add thedotmack/claude-mem
   > /plugin install claude-mem
   
   > /plugin marketplace add obra/superpowers-marketplace
   > /plugin install superpowers@superpowers-marketplace
   ```

> [!TIP]
> If `claude-mem` is properly set up, every time you start Claude Code, you should see output that looks like:
> ```bash
> $ claude
>   # ... Claude startup graphics ...
>  ⎿ SessionStart:startup says: Plugin hook error: 
>
>    📝 Claude-Mem Context Loaded
>       ℹ️  Note: This appears as stderr but is informational
>     only
>
>
>    📝 [beehive] recent context
>    ────────────────────────────────────────────────────────
>
>    Legend: 🎯 session-request | 🔴 gotcha | 🟡 
>    problem-solution | 🔵 how-it-works | 🟢 what-changed | 
>    🟣 discovery | 🟠 why-it-exists | 🟤 decision | ⚖️ 
>    trade-off
>    # ... individual context entries will follow
> ```

4. **Codex only:** the setup script automatically installs the Superpowers skills library (no manual command needed). When `tools/scripts/set-up-tools.sh` runs, it clones or updates `obra/superpowers` under `~/.codex/superpowers`, installs dependencies, and verifies the bootstrap CLI so Codex sessions immediately load the skills. The process is idempotent, so rerunning the setup reuses the existing checkout safely.

> **Overview of the MCP tools installed:**
>
> - See [`tools/tools.md`](../tools/tools.md) for the full list (and [`tools/tools-decision-guide.md`](../tools/tools-decision-guide.md) for more details)
> - What the agents (that you'll set up in the next section) will see:
>    
>     - [`compact-mcp-list.md`](../agents/reference/compact-mcp-list.md) as a file they *have* to read
>     - Contains links to guides to MCPs [by category](../agents/reference/mcps-by-category/) and [deep dive guides for the non-basic MCPs](../agents/reference/mcp-deep-dives/)

## Config files

> [!WARNING]
> **By default, the setup script below will overwrite (with a symlink) any existing agent config files at:**
>
> - `~/.claude/CLAUDE.md`
> - `~/.gemini/GEMINI.md`
> - `~/.codex/AGENTS.md`
>
> **For OpenCode**, the setup script *merges* MCP configurations into `~/.config/opencode/opencode.json`, preserving your existing settings.
>
> If the markdown config files above already exist in your system, instead of running the script:
>
> - append the contents of [`CLAUDE.template.md`](../configs/context/templates/CLAUDE.template.md) to your `CLAUDE.md`
> - append the contents of [`AGENTS.template.md`](../configs/context/templates/AGENTS.template.md) to your `AGENTS.md` and `GEMINI.md`

Run the config setup script:

```bash
configs/scripts/set-up-configs.sh
```

This generates config files from templates ([`AGENTS.template.md`](../configs/context/templates/AGENTS.template.md) and [`CLAUDE.template.md`](../configs/context/templates/CLAUDE.template.md)) with absolute paths to the repository, writing them directly to:
- `~/.gemini/GEMINI.md` (for Gemini CLI)
- `~/.codex/AGENTS.md` (for Codex)
- `~/.claude/CLAUDE.md` (for Claude Code)
- `~/.config/opencode/opencode.json` (for OpenCode — MCP configs merged from [`opencode.json`](../configs/config/templates/opencode.json) template)

**The result will be that each agent will always be instructed to read:**

- the [compact list/decision guide of MCPs available](../agents/reference/compact-mcp-list.md)
- the [handoff guide for using various agents/models together](../agents/reference/handoff-guidelines.md)

> Templates are used since the config files need to use *absolute* paths to reference files in this repo. 
> 
> Thus, we use templates with `{{REPO_ROOT}}` placeholders (that get replaced with the actual repository path during setup) to make the repo portable across different machines.

### Making sure it works

#### Gemini CLI

1. Relaunch Gemini CLI
2. You should see a line under `Using:` saying `1 GEMINI.md file` (or however many you had before + 1)
3. To be fully sure, run **`/memory show`**; you should see the content from the [`AGENTS.template.md`](../configs/context/templates/AGENTS.template.md) written to `~/.gemini/GEMINI.md`

#### Codex

1. Relaunch Codex
2. Ask Codex: `What must-read files were you told to read at startup?`
3. It should reference the clink tool and delegation rules
4. Run `~/.codex/superpowers/.codex/superpowers-codex find-skills` to confirm the Superpowers skills list renders without errors

> **Note**: `/status` currently shows `Agents.md: <none>` (even when correclty set up) due to [a known bug](https://github.com/openai/codex/issues/3793), but the `~/.codex/AGENTS.md` file created in the setup script **is** loaded and used, as the testing steps above should confirm.

#### Claude Code

1. Restart Claude Code
2. Run **`/status`**: you should see a line saying `Memory: user (~/.claude/CLAUDE.md)`

#### OpenCode

1. Restart OpenCode
2. Run **`/status`**: you should see Beehive's MCP servers listed (e.g., `pal`, `qdrant`, `sourcegraph`, `context7`, etc.) with their statuses shown as "connected"
3. Verify agents are available by pressing Tab to cycle through registered agents — Beehive agents like `architect`, `debugger`, `frontend` should appear

## *Sub*agents

> The setup script at [`agents/scripts/set-up-agents.sh`](../agents/scripts/set-up-agents.sh) automates all the tasks in this section.
>
> **Warning: it will overwrite any existing files in `~/.claude/agents/*.md` whose names match any of the filenames in [`claude-subagents/`](../agents/claude-subagents/)**

The sections below set up the same agent roles on different platforms:

- **Claude Code & OpenCode** subagents are for spawning subagents using their native mechanisms
- **PAL's `clink`** is for spawning subagents (allows choosing both the role and the model used):

    - From Gemini CLI and Codex
    - From Claude Code [if you want to use Gemini or GPT (Codex) models](../tools/models-decision-guide.md)

### `clink` subagents

1. Symlink the role prompts folder into PAL's `systemprompts/`:

   ```bash
   mkdir -p ~/.pal/cli_clients/systemprompts
   ln -s beehive/agents/role-prompts ~/.pal/cli_clients/systemprompts/role-prompts
   ```

2. Copy the PAL configs for each CLI to the user-scoped PAL config folder:

   ```bash
   cp beehive/agents/configs/pal/*.json ~/.pal/cli_clients/
   ```

3. Restart PAL MCP server to reload updated configs

> **Syntax for spawning (use within prompt):** `clink with [cli_name] [role] to [task]`
>
> Tool parameter list:
>     
> - `cli_name`: `gemini`, `claude`, `codex`
> - `role`: 
>       - [Any of the `clink` subagents set up using the steps above](../agents/role-prompts/)
>       - PAL presets also available: `default`, `planner`, `codereviewer`
> - `prompt`: The task to perform (required)
> - `files`: Optional file paths for context
> - `images`: Optional image paths
> - `continuation_id`: For resuming previous clink conversations
>
> Links to docs:
> - [Full usage guide for `clink` (in PAL docs)](https://github.com/BeehiveInnovations/pal-mcp-server/blob/main/docs/tools/clink.md#usage-examples)
> - Shortcut: [examples of spawning agents in PAL `clink` docs](https://github.com/BeehiveInnovations/pal-mcp-server/blob/main/docs/tools/clink.md#usage-examples)

### Claude Code subagents

1. Create the directory structure:

   ```bash
   mkdir -p ~/.claude/agents
   ```

2. Symlink the Claude subagent files:

   ```bash
   ln -s beehive/agents/claude-subagents/*.md ~/.claude/agents/
   ```

3. Verify in Claude Code by running `/agents` to confirm the subagents appear

> [!TIP]
> **To spawn subagents in Claude Code:**
>
> 1. **Mention the agent explicitly** by name in your prompt, e.g. `Have the debugger subagent investigate this error`
> 2. Claude **automatically** invokes subagents when tasks match their descriptions*
>
> **Key properties:**
>
> - Each subagent has its own context window (doesn't pollute main conversation) from [`role-prompts/`](../agents/role-prompts/)
> - For each subagent, can choose model it uses & tools available to it

### OpenCode subagents

1. The setup script symlinks role prompts to `~/.config/opencode/agent/bees/`
2. Each role is registered in `~/.config/opencode/opencode.json` under the `agent` key with `mode: "subagent"`
3. Verify by pressing Tab in OpenCode to cycle through available agents — Beehive agents should appear

> [!TIP]
> **To spawn subagents in OpenCode:**
>
> - **Mention the agent** by name in your prompt, e.g. `Use the debugger agent to investigate this error`
> - OpenCode **automatically** delegates to subagents when tasks match their descriptions

## Agents

> [!NOTE]
> The instructions/scripts in this section set up the ability to **launch Claude Code, Codex, Gemini CLI, and OpenCode using a particular agent *from launch for the main conversation*** (instead of as *subagents* that you can't interact with directly).

### Strategy

#### For Claude Code

- Use **slash commands** (e.g. `/architect`, `/frontend`) that inject role prompts into the current conversation.
- Commands are generated to `~/.claude/commands/` from the agent files in [`claude-subagents/`](../agents/claude-subagents/) using the script in the instructions below.

#### For Gemini CLI & Codex

- Use **wrapper scripts** installed to `~/.local/bin/` that launch the CLI with a role prompt from the [`role-prompts/`](../agents/role-prompts/) pre-loaded in the main conversation.
- **Structure: `<codex/gemini>-<rolename>`**
    - For example, `gemini-architect` and `codex-architect` are generated from `role-prompts/architect.md`

#### For OpenCode

- Use the [**primary agents mechanism**](https://opencode.ai/docs/agents/#primary-agents) — press **Tab** to cycle through registered agents.
- Agents are automatically registered to `~/.config/opencode/opencode.json` by the setup script from [`role-prompts/`](../agents/role-prompts/).

### Instructions

- Set up the **Claude Code slash commands:**

   ```bash
   agents/scripts/set-up-claude-slash-commands.sh
   ```

- Set up the **Gemini CLI role launchers:**

   ```bash
   agents/scripts/set-up-gemini-role-launchers.sh
   ```

- Set up the **Codex role launchers:**

   ```bash
   agents/scripts/set-up-codex-role-launchers.sh
   ```

- Ensure `~/.local/bin` is in your $PATH by adding the following line to your `~/.zshrc`/`~/.bashrc`:

   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```
