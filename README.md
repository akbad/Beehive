# Agent ecosystem: config + agent file setup

| Folder | Contents |
| :----- | :------- |
| **`agents/`** | Agent files and docs about them |
| **`mcps/`** | Docs & setup scripts for MCPs |
| `agents-brainstorming/` | Docs + template files used when brainstorming agents |

## Quick setup

You don't technically have to learn what the different agents and MCPs available are (other than for setting up prerequisites), they should all be used automatically by your CLI agents when needed.

### MCPs

1. Read the [must-read information about the setup script](mcps/README.md) and ensure you have the listed prerequisites set up.
2. Run the [setup script](mcps/scripts/set-up-mcps.sh):
    
   ```bash
   mcps/scripts/set-up-mcps.sh [options]
   ```

3. Set up the [`claude-mem` automatic context management plugin](https://github.com/thedotmack/claude-mem) by starting up Claude Code and running these commands:

   ```
   > /plugin marketplace add thedotmack/claude-mem
   > /plugin install claude-mem
   ```

> **Overview of the MCP tools installed:**
>
> - See [`mcps/tools.md`](mcps/tools.md) for the full list (and [`mcps/tools-decision-guide.md`](mcps/tools-decision-guide.md) for more details)
> - What the agents (that you'll set up in the next section) will see:
>    
>     - [`compact-mcp-list.md`](agents/reference/compact-mcp-list.md) as a file they *have* to read
>     - Contains links to guides to MCPs [by category](agents/reference/mcps-by-category/) and [deep dive guides for the non-basic MCPs](agents/reference/mcp-deep-dives/)

### Agents

> The setup script at [`agents/scripts/set-up-agents.sh`](agents/scripts/set-up-agents.sh) automates all the tasks in this section. 
>
> **Warning: it will overwrite any existing files at `~/.claude/agents/*.md` (only files matching names in claude-subagents/)**

The two sections below set up the same agent roles on different platforms:

- Claude Code subagents are for spawning subagents within Claude Code using a Claude model
- Zen's `clink` is for spawning subagents (allows choosing both the role and the model used):
    
    - From Gemini and Codex CLIs
    - From Claude Code [if you want to use Gemini or GPT (Codex) models](mcps/models-decision-guide.md)

#### Set up `clink` subagents

1. Create the directory structure:

   ```bash
   mkdir -p ~/.zen/cli_clients/systemprompts
   ```

2. Symlink the role prompts folder:

   ```bash
   ln -s agent-ecosystem/agents/clink-role-prompts ~/.zen/cli_clients/systemprompts/clink-role-prompts
   ```

3. Copy the JSON configs:

   ```bash
   cp agent-ecosystem/agents/configs/*.json ~/.zen/cli_clients/
   ```

4. Restart Zen MCP server to reload configs

#### Set up Claude Code subagents

1. Create the directory structure:

   ```bash
   mkdir -p ~/.claude/agents
   ```

2. Symlink the Claude subagent files:

   ```bash
   ln -s agent-ecosystem/agents/claude-subagents/*.md ~/.claude/agents/
   ```

3. Verify in Claude Code by running `/agents` to confirm the subagents appear

### Config files

> The setup script at [`configs/scripts/set-up-configs/`](configs/scripts/set-up-configs.sh) automates all the tasks in this section.
>
> **Warning: it will overwrite any existing agent config files at:**
> 
> - `~/.claude/CLAUDE.md`
> - `~/.gemini/GEMINI.md`
> - `~/.codex/AGENTS.md`

1. Symlink global context files for Gemini and Codex:

   - For **Gemini CLI:**

      ```bash
      mkdir -p ~/.gemini
      ln -sf "$PWD/agent-ecosystem/agents/configs/AGENTS.md" ~/.gemini/GEMINI.md
      ```

      > **Verify Gemini automatically reads this file:**
      >
      > 1. Relaunch Gemini CLI
      > 2. You should see a line under `Using:` saying `1 GEMINI.md file`
      > 3. Run **`/memory show`**; you should see the contents of the [symlinked file](agents/configs/AGENTS.md) printed in the Gemini CLI

   - For **Codex CLI:**

      ```bash
      ln -sf "$PWD/agent-ecosystem/agents/configs/AGENTS.md" ~/.codex/AGENTS.md
      ```

      > **Verify Codex automatically reads this file:**
      >
      > 1. Relaunch Codex
      > 2. Ask Codex: "What handoff guidelines were you given at startup?"
      > 3. It should reference the clink tool and delegation rules from AGENTS.md
      >
      > **Note**: `/status` currently shows `AGENTS files: (none)` for the global file due to [a known display bug](https://github.com/openai/codex/issues/3793), but the file **is** being loaded and used.

   This ensures both CLIs always read the [handoff guidelines](agents/reference/handoff-guidelines.md) and [compact MCP list](agents/reference/compact-mcp-list.md) at startup for any project under your home directory.

2. Symlink to pre-made `CLAUDE.md` context file from your user-level Claude Code config:

   ```bash
   ln -sf "$PWD/agent-ecosystem/agents/configs/CLAUDE.md" ~/.claude/CLAUDE.md
   ```

   This ensures Claude always reads the [handoff guidelines](agents/reference/handoff-guidelines.md) and [compact MCP list](agents/reference/compact-mcp-list.md) at startup, **even when *not* spawned using an agent file.**

   > **Verify Claude automatically reads this file:**
   >
   > 1. Restart Claude Code
   > 2. Run **`/status`**: you should see a line saying `Memory: user (~/.claude/CLAUDE.md)`