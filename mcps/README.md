# MCP a: how-tos and setup script ([scripts/set-up-mcp.sh](scripts/set-up-mcps.sh))

## What the script does

1. Sets up a series of essential MCPs and CLI tools (including running some MCPs & Docker containers locally) 
     
    > Uses ports **8780-8784** for the servers/containers it starts.

2. Configures [these coding agent CLIs](#supported-coding-agents) to use them

And other useful background stuff.

### Tools set up by the script

See [`tools.md`](tools.md) for:

- **full list of tools** set up/made available by the script
- **how to use them** (e.g. when writing prompts)

## Prerequisites

### npm/Node

- Convenient to use [nvm](https://github.com/nvm-sh/nvm) to install/manage Node versions for you
- To install nvm and use it to install the newest long-term-supported version of Node & npm:

    ```bash
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
        nvm install --lts && \
        nvm use --lts
    ```

### [Homebrew](https://brew.sh)

Needed for checking for/installing Semgrep.

### [uv](https://github.com/astral-sh/uv) with Python 3.12
    
1. Install uv on Mac and Linux:

    ```bash
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ```

2. Use uv to install and use Python 3.12:

    ```bash
    uv python install 3.12 && uv python pin 3.12
    ```

### Rancher Desktop or Docker Desktop 

Needed for running the local Qdrant container.

### API keys

> - **Free tiers are used in this script for each service/MCP server** that isn't free/open-source in the first place
> - The services just offer extra features/usage on top of the regular free tier as a bonus for signing up and using an API key  

#### Steps

1. Create API key at these services' websites

    - [Tavily](https://www.tavily.com/)
    - [Firecrawl](https://firecrawl.dev/app/api-keys)

2. Add to and export from shell config (`.zshrc` or `.bashrc`) **with these variable names**:

    - `TAVILY_API_KEY`
    - `FIRECRAWL_API_KEY`

3. `source` your shell config to ensure they're available

## Supported coding agents

- **Claude Code**
- **Codex CLI**
- **Gemini CLI**

**By default: all 3 of these will be set up to use the MCPs**

To choose specific ones, use `-a/--agent` followed by a string containing one or more of

- `c` for Claude Code
- `x` for Codex
- `g` for Gemini

So
- `-a c` sets up only Claude Code to use the MCPs
- `-a gc` sets up only Claude Code and Gemini to use the MCPs
- `-a cgx` = same as default, set up for all 3

## Useful background info 

### MCP server types

- **Official/reference** servers are developed and maintained by the creators of MCP
    
    - Are standard, primary implementations that serve as models for how to build new MCPs  

- **Community** servers are developed by the community

### Ways of running MCP servers

Most MCP servers are run as **client-managed `stdio` servers**: 

- You configure your coding agent (e.g. using `claude mcp add ...`) to use that MCP, telling the command to use to run the server (usually something like `npx -y ...`)
- Then, the coding agent will start its own private instance of the server when launched and stop it when it's exited.

Some servers support being accessed remotely (being run either as a locally-running process or by an online service that you access with a URL + API key), which allows them to be reused by many agents.

| Communication method (transport layer) w/ remote MCP servers | Use case | How it works |
| --- | --- | --- |
| **HTTP** | Best for MCPs whose toolcalls are quick & synchronous | Run the server once, `mcp add` command provides the server's URL; client then initiates exchanges w/ server via HTTP |
| **SSE *(deprecated in a lot of places, better to just always use HTTP)*** | Best for MCPs whose tools run for a long time, thus making progress updates useful; Agent CLI *and* MCP server **must support SSE** | Similar to `http`, except connection remains open instead of closing after each request. Client then stays listening, and server can "push" messages (via events) to the client whenever new data is available |

### Adding MCPs to coding agents

> The `/mcp` command in each of the agent CLIs below will **list currently-active servers** *(useful for verifying setup was successful)*

#### Gemini CLI

> [***Full Gemini MCP guide***](https://geminicli.com/docs/tools/mcp-server/)
> 
> → [*Shortcut: guide to `gemini mcp` commands*](https://github.com/google-gemini/gemini-cli/blob/main/docs/tools/mcp-server.md#managing-mcp-servers-with-gemini-mcp)

- Add servers with `gemini mcp add <name> <commandOrUrl> [args...]` 
    
    - Scope used determines which config file is changed: 

        - **Project scope *(default)*** → `~/.gemini/settings.json`
        - **User scope** → `~/.gemini/settings.json`
            
            - Use via `-s user` option

#### Claude Code

> [***Full Claude Code MCP guide***](https://docs.claude.com/en/docs/claude-code/mcp)

- **Support for SSE servers is deprecated**; prefer HTTP servers instead 
- Can add MCP servers at these scopes (with `--scope <local|project|user>`):

    - **Local (*default*)**: for current repo
    - **Project**: changes current repo's `.mcp.json` so collaborators can reuse the same MCP setup
    - **User**: for Claude Code anywhere on your device (changes config in `~/.claude`)

- Listing and using available MCPs:

    - Type `@` to see available resources from all connected MCP servers (alongside files)
    - Use the format **`@server:protocol://resource/path`** to reference a resource, for example:

        > `Compare @postgres:schema://users with @docs:file://database/user-model`

#### Codex

> [***Full Codex MCP guide***](https://developers.openai.com/codex/mcp)

- Adding MCP servers:
    
    - Options for `stdio` servers:

        1. **Edit `~/.codex/config.toml` config file** with this format:

            ```toml
            [mcp_servers.<server-name>]
            command = <server launch command>  # required
            args = <args for launch command>   # optional
            env = { "ENV_VAR" = "VALUE" }      # optional: env vars for server to use

            # alternate way of adding any env vars for server to use
            [mcp_servers.<server-name>.env]
            ENV_VAR = "VALUE"                 
            # ... repeat for each variable
            ```

            - Example:

                ```toml
                [mcp_servers.context7]
                command = "npx"
                args = ["-y", "@upstash/context7-mcp"]

                [mcp_servers.context7.env]
                SUNRISE_DIRECTION = "EAST"
                ```
            
        2. **Use shortcut command** (creates config entry for you): 

            ```bash
            codex mcp add <server-name> [--env <VAR=VALUE>]... -- <server launch command>
            ```
    
    - For `http` servers: **must edit `~/.codex/config.toml`** config file with this format:

        ```toml
        # optional: add this line if you want to use RMCP client to connect to server
        #           enables auth via OAuth for HTTP servers
        experimental_use_rmcp_client = true 

        [mcp_servers.<server-name>]
        url = <server URL>      # required
        bearer_token = <token>  # optional: bearer token to use in an `Authorization` header 
                                #           (if not using OAuth via RMCP above)
        ``` 

    - **Doesn't support SSE**; use HTTP servers instead
