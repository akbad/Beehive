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
   cp agent-ecosystem/agents/zen-client-cli-configs/*.json ~/.zen/cli_clients/
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
