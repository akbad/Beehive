# *MCP and CLI tools suite*: essential must-read information

**Contents:**
- [What the setup script does](#what-the-setup-script-does)
  - [Side effects](#side-effects)
- [Tools set up by the script](#tools-set-up-by-the-script)
  - [Important: ensuring tools work properly](#important-ensuring-tools-work-properly)
- [Using the script](#using-the-script)
  - [Prerequisites](#prerequisites)
  - [Running the script](#running-the-script)

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

#### npm/Node

- Convenient to use [nvm](https://github.com/nvm-sh/nvm) to install/manage Node versions for you
- To install nvm and use it to install the newest long-term-supported version of Node & npm:

    ```bash
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
        nvm install --lts && \
        nvm use --lts
    ```

#### [Homebrew](https://brew.sh)

Needed for checking for/installing Semgrep.

#### [uv](https://github.com/astral-sh/uv) with Python 3.12
    
1. Install uv on Mac and Linux:

    ```bash
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ```

2. Use uv to install and use Python 3.12:

    ```bash
    uv python install 3.12 && uv python pin 3.12
    ```

#### Rancher Desktop or Docker Desktop 

Needed for running the local Qdrant container.

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
scripts/set-up-tools.sh [options]
```

#### Options

- `-a/--agent <str>`: for choosing specific agents to set up/configure to use the tools

    - **Supported agents: Claude Code, Codex CLI, Gemini CLI**

        - **Default: all supported agents will be set up**

    - To choose specific ones, use `-a/--agent` followed by a string containing one or more of

        - `c` for Claude Code
        - `x` for Codex
        - `g` for Gemini

    - For example:

        - `-a c` sets up only Claude Code to use the MCPs
        - `-a gc` sets up only Claude Code and Gemini to use the MCPs
        - `-a cgx` = same as default, set up for all 3

- `-y/--yes`: additionally configures agents chosen with `-a/--agent` above (or all supported agents by default) to have **auto-approved use of all the MCP tools set up here** *(so you don't get asked for permission each time/for each new tool you try to use)*

- `-f/--fsdir <path>`: for specifying the directory that the Filesystem MCP is allowed to make edits within
    
    - **Default: `~/Code`**

- `-c/--clonedir <path>`: for specifying the directory that you want to place the cloned MCP servers' repos in

    - **Default: `~/Code/mcp-servers/`**

