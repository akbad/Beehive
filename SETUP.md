# Agent ecosystem: setup guide

You don't technically have to learn what the different agents and MCPs available are (other than for setting up prerequisites), they should all be used automatically by your CLI agents when needed.

## MCPs

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

## Config files

> **Warning, the setup script below will overwrite any existing agent config files at:**
>
> - `~/.claude/CLAUDE.md`
> - `~/.gemini/GEMINI.md`
> - `~/.codex/AGENTS.md`
>
> If these files already exist in your system, instead of running the script:
> 
> - append the contents of [`CLAUDE.md.template`](configs/CLAUDE.md.template) to your `CLAUDE.md`
> - append the contents of [`AGENTS.md.template`](configs/AGENTS.md.template) to your `AGENTS.md` and `GEMINI.md`

Run the config setup script:

```bash
configs/scripts/set-up-configs.sh
```

This generates config files from templates ([`AGENTS.md.template`](configs/AGENTS.md.template) and [`CLAUDE.md.template`](configs/CLAUDE.md.template)) with absolute paths to the repository, writing them directly to:
- `~/.gemini/GEMINI.md` (for Gemini CLI)
- `~/.codex/AGENTS.md` (for Codex CLI)
- `~/.claude/CLAUDE.md` (for Claude Code)

**The result will be that each agent will always be instructed to read:**

- the [compact list/decision guide of MCPs available](agents/reference/compact-mcp-list.md)
- the [handoff guide for using various agents/models together](agents/reference/handoff-guidelines.md)

> Templates are used since the config files need to use *absolute* paths to reference files in this repo. 
> 
> Thus, we use templates with `{{REPO_ROOT}}` placeholders (that get replaced with the actual repository path during setup) to make the repo portable across different machines.

### Making sure it works

#### Gemini CLI

1. Relaunch Gemini CLI
2. You should see a line under `Using:` saying `1 GEMINI.md file` (or however many you had before + 1)
3. To be fully sure, run **`/memory show`**; you should see the content from the [`AGENTS.md.template`](configs/AGENTS.md.template) written to `~/.gemini/GEMINI.md`

#### Codex CLI

1. Relaunch Codex
2. Ask Codex: `What must-read files were you told to read at startup?`
3. It should reference the clink tool and delegation rules

> **Note**: `/status` currently shows `Agents.md: <none>` (even when correclty set up) due to [a known bug](https://github.com/openai/codex/issues/3793), but the `~/.codex/AGENTS.md` file created in the setup script **is** loaded and used, as the testing steps above should confirm.

#### Claude Code

1. Restart Claude Code
2. Run **`/status`**: you should see a line saying `Memory: user (~/.claude/CLAUDE.md)`

## *Sub*agents

> The setup script at [`agents/scripts/set-up-agents.sh`](agents/scripts/set-up-agents.sh) automates all the tasks in this section. 
>
> **Warning: it will overwrite any existing files in `~/.claude/agents/*.md` whose names match any of the filenames in [`claude-subagents/`](agents/claude-subagents/)**

The two sections below set up the same agent roles on different platforms:

- Claude Code subagents are for spawning subagents within Claude Code using a Claude model
- Zen's `clink` is for spawning subagents (allows choosing both the role and the model used):
    
    - From Gemini and Codex CLIs
    - From Claude Code [if you want to use Gemini or GPT (Codex) models](mcps/models-decision-guide.md)

### `clink` subagents

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

> **Syntax for spawning (use within prompt):** `clink with [cli_name] [role] to [task]`
>
> Tool parameter list:
>     
> - `cli_name`: `gemini`, `claude`, `codex`
> - `role`: 
>       - [Any of the `clink` subagents set up using the steps above](agents/clink-role-prompts/)
>       - Zen presets also available: `default`, `planner`, `codereviewer`
> - `prompt`: The task to perform (required)
> - `files`: Optional file paths for context
> - `images`: Optional image paths
> - `continuation_id`: For resuming previous clink conversations
>
> Links to docs:
> - [Full usage guide for `clink` (in Zen docs)](https://github.com/BeehiveInnovations/zen-mcp-server/blob/main/docs/tools/clink.md#usage-examples)
> - Shortcut: [examples of spawning agents in Zen `clink` docs](https://github.com/BeehiveInnovations/zen-mcp-server/blob/main/docs/tools/clink.md#usage-examples)

### Claude Code subagents

1. Create the directory structure:

   ```bash
   mkdir -p ~/.claude/agents
   ```

2. Symlink the Claude subagent files:

   ```bash
   ln -s agent-ecosystem/agents/claude-subagents/*.md ~/.claude/agents/
   ```

3. Verify in Claude Code by running `/agents` to confirm the subagents appear

> **How to spawn subagents in Claude Code:**
> 
> 1. **Mention the agent explicitly** by name in your prompt, e.g. `Have the debugger subagent investigate this error`
> 2. Claude **automatically** invokes subagents when tasks match their descriptions*
>
> **Key properties:**
> 
> - Each subagent has its own context window (doesn't pollute main conversation)
> - For each subagent, can choose model it uses & tools available to it

## Agents

> The instructions/scripts in this section set up the ability to **launch Claude Code, Codex and Gemini CLI using a particular agent *from launch for the main conversation*** (instead of as *subagents* that you can't interact with directly).

### Strategy

#### For Claude Code 

- Use **slash commands** (e.g. `/architect`, `/frontend`) that inject role prompts into the current conversation. 
- Commands are generated to `~/.claude/commands/` from the agent files in [`claude-subagents/`](agents/claude-subagents/) using the script in the instructions below.

#### For Gemini & Codex CLIs

- Use **wrapper scripts** installed to `~/.local/bin/` that launch the CLI with a role prompt from the [`clink-role-prompts/`](agents/clink-role-prompts/) pre-loaded in the main conversation. 
- **Structure: `<codex/gemini>-<rolename>`** 
    - For example, `gemini-architect` and `codex-architect` are generated from `clink-role-prompts/architect.md`

### Instructions

- Set up the **Claude Code slash commands:**

   ```bash
   agents/scripts/set-up-claude-slash-commands.sh
   ```

- Set up the **Gemini CLI role launchers:**

   ```bash
   agents/scripts/set-up-gemini-role-launchers.sh
   ```

- Set up the **Codex CLI role launchers:**

   ```bash
   agents/scripts/set-up-codex-role-launchers.sh
   ```

- Ensure `~/.local/bin` is in your $PATH by adding the following line to your `~/.zshrc`/`~/.bashrc`:

   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```