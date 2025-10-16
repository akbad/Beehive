# Must-have MCPs

A practical guide to **must‑have MCP servers** and adjacent tools that *meaningfully* upgrade dev flow when using
- Gemini CLI
- Claude Code
- Codex CLI

## Prerequisites

- npm
- python3
- uv (Python package manager)
- 1 or more coding agents that you use (this guide covers Claude Code, Codex CLI, Gemini CLI)
- **Context7 API key** (optional but recommended): Set `CONTEXT7_API_KEY` in your shell config (`.zshrc` or `.bashrc`)
  - Create a key at [console.upstash.com](https://console.upstash.com/)
  - Free tier available; paid tiers for higher rate limits and private repo access

## Useful background info 

### MCP server types

- **Official/reference** servers are developed and maintained by the creators of MCP
    
    - Are standard, primary implementations that serve as models for how to build new MCPs  

- **Community** servers are developed by the community

### Ways of running MCP servers

If you're **running multiple agents at once** (e.g. Claude Code, Gemini CLI, Codex CLI all running at the same time; they can all reuse the same server):

| Method | When to use | How it works |
| --- | --- | --- |
| **Shared instance (`http`)** | **For MCPs whose toolcalls are quick & synchronous** | Run the server once, `mcp add` command provides the server's URL; client then initiates exchanges w/ server via HTTP |
| **Server-sent events** (`sse`) | **For MCPs whose tools run for a long time**, thus making progress updates useful; Agent CLI *and* MCP server **must support SSE** | Similar to `http`, except connection remains open instead of closing after each request. Client then stays listening, and server can "push" messages (via events) to the client whenever new data is available |

When you're only using **one agent at a time** (e.g. *only launching one of* Claude Code, Codex or Gemini CLI):

| Method | How it works | Pros & cons |
| --- | --- | --- |
| **Client-managed servers (`stdio`)** | `mcp add` command includes the full command to run the server, which the client starts/stops as needed | Simple setup (no separate process) but inefficient for frequent use and stateless by default |

### Notes about adding MCPs to specific agent CLIs

> The `/mcp` command in each of the agent CLIs below will **list currently-active servers** *(useful for verifying setup was successful)*

#### Gemini CLI

> [***Full Gemini MCP guide***](https://github.com/google-gemini/gemini-cli/blob/main/docs/tools/mcp-server.md)
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

---

## clink (via Zen MCP)

> Links our different agent CLIs together so they can use each other for what they do best,
> but this means we *can't* use the main Zen MCP tools (like `consensus`).

### Why use over vanilla agents

- **Keep one thread while fanning out to subagents:** `clink` spins up fresh Claude, Gemini, or Codex sessions from inside your current agent so long-running reviews or research happen in isolated contexts while your main conversation stays intact.

- **Cross-CLI specialization without re-explaining:** 
    
    - Role presets (`default`, `planner`, `codereviewer`, or your own) let you delegate the same task to whichever CLI excels at it
    - The results flow back into the shared transcript so follow-up prompts inherit the full debate or investigation trail.

- **Hands-off orchestration with adjustable guardrails:** 

    - Zen launches each CLI with JSON output, automatic approvals, and continuation IDs, so the spawned agent can read files or run tools immediately
    - If you need tighter control, just trim the shipped flags and keep the orchestration benefits.

### Running the server

Zen ships with a stdio transport today, so we wrap it in the official streamable HTTP adapter for shared use. SSE is not yet available, which makes HTTP the most reliable option when you want Claude Max, Codex CLI, and Gemini CLI to share the same `clink` hub without giving Zen its own API keys.

#### Via `http` (shared zero-api hub)

1. Export a minimal environment so Zen only exposes `clink`:

    ```bash
    export ZEN_CLINK_DISABLED_TOOLS='analyze,apilookup,challenge,chat,codereview,consensus,debug,docgen,planner,precommit,refactor,secaudit,testgen,thinkdeep,tracer'
    export ZEN_MCP_PORT=3333
    ```

2. Start the shared HTTP gateway (*leave this terminal running*):

    ```bash
    uvx --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git python - <<'PY'
    import os
    from contextlib import asynccontextmanager
    from starlette.applications import Starlette
    from starlette.routing import Mount
    from mcp.server.streamable_http_manager import StreamableHTTPSessionManager
    from server import server as zen_server
    import uvicorn

    session_manager = StreamableHTTPSessionManager(zen_server)

    async def mcp_app(scope, receive, send):
        await session_manager.handle_request(scope, receive, send)

    @asynccontextmanager
    async def lifespan(app):
        async with session_manager.run():
            yield

    app = Starlette(routes=[Mount('/mcp', app=mcp_app)], lifespan=lifespan)
    uvicorn.run(app, host='127.0.0.1', port=int(os.environ.get('ZEN_MCP_PORT', '3333')))
    PY
    ```

3. Connect each CLI once (they will reuse their own credentials when `clink` launches them):

    - Gemini CLI: `gemini mcp add zen http --url http://localhost:$ZEN_MCP_PORT/mcp/`
    - Claude Code CLI: `claude mcp add --transport http zen http://localhost:$ZEN_MCP_PORT/mcp/`
    - Codex CLI: append to `~/.codex/config.toml`:

        ```toml
        [mcp_servers.zen]
        url = "http://localhost:3333/mcp/"  # swap port number with your ZEN_MCP_PORT value
        transport = "http"
        ```

    `clink` shells out to the installed CLIs, so this works even if Zen itself has no provider API keys configured.

#### Via `stdio` (one CLI at a time)

The CLI client will start and stop Zen automatically; reuse the same `ZEN_CLINK_DISABLED` string so only `clink`, `version`, and `listmodels` stay enabled.

| Agent | Command |
| :--- | :--- |
| Gemini CLI | `gemini mcp add zen env DISABLED_TOOLS="$ZEN_CLINK_DISABLED_TOOLS" uvx --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git zen-mcp-server` |
| Codex CLI | `codex mcp add zen -- env DISABLED_TOOLS="$ZEN_CLINK_DISABLED_TOOLS" uvx --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git zen-mcp-server` |
| Claude Code CLI | `claude mcp add zen -s user -- env DISABLED_TOOLS="$ZEN_CLINK_DISABLED_TOOLS" uvx --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git zen-mcp-server` |

### Config for role presets (Codex default, Sonnet planner, Gemini reviewer)

Zen loads overrides from `~/.zen/cli_clients/*.json`. 
Copy the built-in definitions and pin each role to your preferred CLI/model.

1. Create the override directory:

    ```bash
    mkdir -p ~/.zen/cli_clients
    ```

2. **Codex CLI** (`~/.zen/cli_clients/codex.json`) — GPT-5-Codex with high thinking for `default`:

    ```json
    {
        "name": "codex",
        "command": "codex",
        "additional_args": [
            "--json",
            "--dangerously-bypass-approvals-and-sandbox"
        ],
        "env": {},
        "roles": {
            "default": {
                "prompt_path": "systemprompts/clink/default.txt",
                "role_args": [
                    "--model",
                    "gpt-5-codex",
                ]
            },
            "planner": {
                "prompt_path": "systemprompts/clink/default_planner.txt",
                "role_args": []
            },
            "codereviewer": {
                "prompt_path": "systemprompts/clink/codex_codereviewer.txt",
                "role_args": []
            }
        }
    }
    ```

3. **Claude Code CLI** (`~/.zen/cli_clients/claude.json`) — Sonnet 4.5 for `planner`:

    ```json
    {
        "name": "claude",
        "command": "claude",
        "additional_args": [
            "--permission-mode",
            "acceptEdits"
        ],
        "env": {},
        "roles": {
            "default": {
                "prompt_path": "systemprompts/clink/default.txt",
                "role_args": []
            },
            "planner": {
                "prompt_path": "systemprompts/clink/default_planner.txt",
                "role_args": [
                    "--model",
                    "sonnet-4.5"
                ]
            },
            "codereviewer": {
                "prompt_path": "systemprompts/clink/default_codereviewer.txt",
                "role_args": []
            }
        }
    }
    ```

4. **Gemini CLI** (`~/.zen/cli_clients/gemini.json`) — Gemini 2.5 Pro for `codereviewer`:

    ```json
    {
        "name": "gemini",
        "command": "gemini",
        "additional_args": [
            "--telemetry",
            "false",
            "--yolo",
            "-o",
            "json"
        ],
        "env": {},
        "roles": {
            "default": {
                "prompt_path": "systemprompts/clink/default.txt",
                "role_args": []
            },
            "planner": {
                "prompt_path": "systemprompts/clink/default_planner.txt",
                "role_args": []
            },
            "codereviewer": {
                "prompt_path": "systemprompts/clink/default_codereviewer.txt",
                "role_args": [
                    "--model",
                    "gemini-2.5-pro"
                ]
            }
        }
    }
    ```

5. Restart the Zen process (or rerun `setup-mcp-servers.sh`) so the new presets load.
6. When you call `clink`, supply:
    - `cli_name="codex"` for default tasks
    - `role="planner"` to hit Sonnet 4.5
    - `role="codereviewer"` to launch Gemini 2.5 Pro

### How the config above all works together

For orchestrating multi-role work-flows *(i.e. chain multiple models together for a task)*, there are a few options:

#### Option 1: *Sequential* clink calls
    
- The main agent you're using will make separate `clink` calls, and results will flow back into the conversation.

    > For example, imagine you're using Claude Code:
    > 
    > - You (to Claude Code): "Design a new authentication module"
    > - Claude Code:
    >
    >     - Calls `clink(role="planner")` → Sonnet 4.5 creates plan → results return
    >     - Calls `clink(role="codereviewer", task="review this plan: ...")` → Gemini reviews → results return
    >     - Calls `clink(role="default", task="implement this reviewed plan: ...")` → Codex implements → results return
    >
    > - All results are in the *same* conversation thread.

- You can also *explicitly* ask for sequential `clink` calls:

    > You: "Use planner role to design auth module, codereviewer role to review it, and default role to implement"
    > 
    > Your agent then orchestrates all three clink calls *sequentially*. 

##### When to use this option

When you want:
    
- **Control & visibility** (since this way, you see all intermediate results; easier to trace and debug)
- **Synthesis** (i.e. main agent should combine insights from all roles)
- You want to **adjust mid-workflow** (i.e. change strategy based on planner output)
- *Most common use case, you'll generally want this 90% of the time*

#### Option 2: *Nested* clink calls (i.e. clink *within* clink)
  
From the main agent, ask the first `clink` subprocess to make *its own* `clink` calls.

> For example, imagine you're using Claude Code:
>
> 1. You: "Plan the auth module, then **delegate review to codereviewer role**, then **delegate implementation to default role**"
> 2. Claude (planner) → creates plan → calls `clink(role="codereviewer")` internally
> 3. Gemini (reviewer) → reviews plan → calls `clink(role="default")` internally
> 4. Codex (default) → implements → returns results up the chain

##### When to use this option:

When you want:

- **Full autonomy**
- When you're using **naturally-recursive workflows** where each step intuitively spawns its own sub-workflows
- **Context isolation** (e.g. planner output shouldn't pollute reviewer context)

### Examples to try (from simplest to most complex) 

*Each of these examples is meant to be used as a prompt pasted into to your **main agent's CLI***. Examples are also included that show how to override (on a per-prompt basis) the default model roles set in the config above.

> **Quick Codex assist *(main agent spawns GPT‑5 Codex)***
> 
> Use clink with cli_name="codex" prompt="Summarize the new retry helper in retry.js and suggest clearer naming."
<p></p>

> **Planner pass with Sonnet 4.5**
> 
> Use clink with role="planner" prompt="Create a phased rollout plan for replacing Redis with DynamoDB in the queue service."
<p></p>

> **Deep code review with Gemini 2.5 Pro**
> 
> Use clink with role="codereviewer" prompt="Review src/payments/refund_service.ts for re-entrancy bugs and summarize High/Medium/Low issues."
<p></p>

> **Explicit CLI + role combo**
>
> Use clink with cli_name="claude" role="planner" prompt="Break down how to migrate the metrics pipeline to OpenTelemetry, including risk mitigations."
<p></p>

> **Follow-up using continuation IDs**
>
> **Prompt:** Use clink with role="planner" prompt="Outline the plan for shipping the new auth service.
> **Subsequent prompt *(resumes previous planner session)*:** Use clink with role="planner" continuation_id="<paste id>" prompt="Refine the timeline with detailed milestones."
<p></p>

> **Multi-model consensus, *without* Zen’s consensus tool**
>
> - **Prompt:**: Use clink with cli_name="codex" prompt="Is optimistic concurrency safe for the cart API update? Give pros/cons."
> - **Subsequent prompt:**: Use clink with cli_name="gemini" prompt="React to Codex’s optimistic concurrency assessment and highlight disagreements."
> - **Subsequent prompt:** Summarize both viewpoints and recommend a final approach.
<p></p>

> **File-focused review *(Gemini handles the big context)***
> 
> - *\*Attach files first\**
> - **Prompt**: Use clink with role="codereviewer" prompt="Audit the attached rollout scripts for idempotency and rollbacks."
<p></p>

> **Planner + Codex implementation handoff**
> 
> - **Example 1:** Use clink with role="planner" prompt="Design a data-migration workflow for moving 10M rows without downtime."
> - **Example 2:** Use clink with cli_name="codex" prompt="Implement the migration scripts described by the planner plan, focusing on the staging/verify steps."
<p></p>

> **Override models on the fly**
>
> Use clink with cli_name="codex" prompt="Use --model gpt-5 to enumerate edge cases for the new rate limiter."
<p></p>

> **Batch research, then delegate**
> 
> **Prompt:** clink with cli_name="gemini" prompt="Find 2025 best practices for securing WebAuthn attestation and list references."
> **Subsequent prompt** Use clink with cli_name="codex" prompt="Given Gemini’s findings, patch auth/webauthn_handler.py to harden attestation validation."
<p></p>

## Filesystem MCP *(official/reference)*

**Cost:** Free / open source.

### Why use over vanilla agents

- **Enhanced security and control:** The server operates only within pre-approved, "allow-listed" directories; prevents accessing sensitive system files or directories outside project scope
- **Reliable and structured ops:** agent receives structured data (like JSON) (instead of parsing the unpredictable text output of commands like `ls` or `find`)
    
    - *Makes file discovery, reading, and writing far less error-prone*
    - Eliminates brittleness from platform differences (e.g., macOS vs. Linux shell tools)

- **Predictable error handling:** 
    
    - Server provides typed, machine-readable errors (e.g., `FileNotFound`, `AccessDenied`)
    - Allows the agent to intelligently handle failures, retry operations, or ask for clarification, rather than failing silently or misinterpreting a generic `bash` error message.

### Running the server

#### Via `http` (when using many agents together)

1. Set the port you want the server to use (best if in `.bashrc`/`.zshrc`):

    ```bash
    export FS_MCP_PORT=8081
    ```

2. Start the central server:

    ```bash
    npx -y @modelcontextprotocol/server-filesystem --port $FS_MCP_PORT [your-allowed-directory]
    ```

3. Connect agents:

    - Gemini CLI: `gemini mcp add fs http --url http://localhost:8081/mcp/`
    - Claude Code: `claude mcp add --transport http fs http://localhost:8081/mcp/`
    - Codex CLI: add to `~/.codex/config.toml`:

        ```toml
        [mcp_servers.fs]
        url = "http://localhost:8081/mcp/"
        transport = "http"
        ``` 

#### Via `stdio` (if only using one agent at a time)

The agent client will start and stop the server automatically as needed.

| Agent | Command |
| :--- | :--- |
| Gemini CLI | `gemini mcp add fs npx -- -y @modelcontextprotocol/server-filesystem [your-allowed-directory]` |
| Codex CLI | `codex mcp add fs -- npx -y @modelcontextprotocol/server-filesystem [your-allowed-directory]` |
| Claude Code | `claude mcp add fs -s user -- npx -y @modelcontextprotocol/server-filesystem [your-allowed-directory]` |

### Examples to try

> “Read `server/**/*.go` and propose a patch adding retries with exponential backoff; write diffs but do not commit.”
<p></p>

## Git MCP *(official/reference)*

**Cost:** Free / open source.

### Why use over vanilla agents

- **Structured Git operations:** Exposes 12 Git tools (`status`, `diff`, `commit`, `log`, `branch`, `checkout`, etc.) as first‑class MCP tools with typed inputs/outputs instead of parsing fragile shell command text

    - *Makes branch management, staging, and commit operations far more reliable*
    - Agent receives machine‑readable data (commit hashes, file lists, diffs) rather than unpredictable `git` CLI output variations
    - Eliminates cross‑platform shell inconsistencies (Windows vs Unix paths, line endings, locale differences)

- **Atomic reasoning about changes:**

    - Tools like `git_diff_staged` and `git_diff_unstaged` return structured diffs the agent can parse and reason about before committing
    - Agent can programmatically check status, stage specific files, review changes, and commit — all in a single interaction flow without fragile bash chaining

- **Safer operations with validation:**

    - Server provides typed errors (e.g., `BranchNotFound`, `MergeConflict`, `UnstagedChanges`)
    - Allows the agent to intelligently handle Git failures, suggest resolutions, or ask for clarification, rather than crashing on obscure Git error messages

### Running the server

#### Via `http` (when using many agents together)

1. Install the server globally:

    ```bash
    uv install mcp-server-git
    # or for isolated installs:
    uvx install mcp-server-git
    ```

2. Set the port you want the server to use:

    ```bash
    export GIT_MCP_PORT=8082
    ```

3. Start the central server

    ```bash
    python -m mcp_server_git --repository /path/to/your/repo --port $GIT_MCP_PORT
    ```

4. Connect agents:

    - Gemini CLI: `gemini mcp add git http --url http://localhost:8082/mcp/`
    - Claude Code: `claude mcp add --transport http git http://localhost:8082/mcp/`
    - Codex CLI: add to `~/.codex/config.toml`:

        ```toml
        [mcp_servers.git]
        url = "http://localhost:8082/mcp/"
        transport = "http"
        ```

#### Via `stdio` (if only using one agent at a time)

The agent client will start and stop the server automatically as needed.

| Agent | Command |
| :--- | :--- |
| Gemini CLI | `gemini mcp add git uvx -- mcp-server-git --repository /path/to/your/repo` |
| Codex CLI | `codex mcp add git -- uvx mcp-server-git --repository /path/to/your/repo` |
| Claude Code | `claude mcp add git -s user -- uvx mcp-server-git --repository /path/to/your/repo` |

**Alternative (Node‑based):** You can also use community Node implementations:
- `gemini mcp add git npx -- -y @cyanheads/git-mcp-server`
- `claude mcp add git -s user -- npx -y @cyanheads/git-mcp-server`

### Examples to try

> "Show me the current git status and all unstaged changes in the repository."
<p></p>

> "Create a new branch called `feat/retry-logic`, stage all modified files in `src/`, and show me the staged diff."
<p></p>

> "Look at the last 10 commits in the log. Find the commit that introduced the `handleTimeout` function and show me its full diff."
<p></p>

> "Compare the current branch against `main` and summarize what changed in bullet points."
<p></p>

> "Stage the changes in `lib/auth.ts`, commit them with message 'fix: resolve token expiration edge case', and show the new commit."
<p></p>

> "List all branches. If there's a branch called `stale/old-feature`, check it out and show me its status compared to main."
<p></p>

## Fetch MCP *(official/reference)*

**Cost:** Free / open source.

### Why use over vanilla agents

- **Token efficiency:** Automatically converts HTML to clean Markdown with intelligent chunking, drastically reducing token usage compared to raw HTML while preserving document structure

- **Smart content extraction:** Strips navigation, ads, and boilerplate automatically, leaving only the meaningful content for the agent to process

- **Structured output for citations:** Maintains headings, links, and code blocks in Markdown format, making it easy for agents to cite sources accurately and preserve technical details

- **Handles dynamic content:** Can process JavaScript-rendered pages and modern web applications that basic `curl` or `wget` would fail on

- **Consistent format across sources:** Normalizes content from different websites into a uniform Markdown structure, eliminating brittleness from parsing diverse HTML layouts

### Running the server

#### Via `http` (when using many agents together)

1. Set the port you want the server to use:

    ```bash
    export FETCH_MCP_PORT=8083
    ```

2. Start the central server:

    ```bash
    npx -y @modelcontextprotocol/server-fetch --port $FETCH_MCP_PORT
    ```

3. Connect agents:

    - Gemini CLI: `gemini mcp add fetch http --url http://localhost:8083/mcp/`
    - Claude Code: `claude mcp add --transport http fetch http://localhost:8083/mcp/`
    - Codex CLI: add to `~/.codex/config.toml`:

        ```toml
        [mcp_servers.fetch]
        url = "http://localhost:8083/mcp/"
        transport = "http"
        ```

#### Via `stdio` (if only using one agent at a time)

The agent client will start and stop the server automatically as needed.

| Agent | Command |
| :--- | :--- |
| Gemini CLI | `gemini mcp add fetch npx -- -y @modelcontextprotocol/server-fetch` |
| Codex CLI | `codex mcp add fetch -- npx -y @modelcontextprotocol/server-fetch` |
| Claude Code | `claude mcp add fetch -s user -- npx -y @modelcontextprotocol/server-fetch` |

**Alternative (Python):** You can also use the Python implementation:
- `gemini mcp add fetch uvx -- mcp-server-fetch`
- `claude mcp add fetch -s user -- uvx mcp-server-fetch`

### Examples to try

> "Fetch the Kafka idempotent producer docs at https://kafka.apache.org/documentation/#producerconfigs and summarize the integration steps for our service (bullets + code). Include links to relevant sections."
<p></p>

> "Fetch https://redis.io/docs/manual/patterns/distributed-locks/ and extract the RedLock algorithm steps into a numbered list with code examples."
<p></p>

> "Compare rate limiting strategies by fetching these three articles: [URL1], [URL2], [URL3]. Summarize pros/cons of each approach in a comparison table."
<p></p>

> "Fetch the latest Python async best practices from https://docs.python.org/3/library/asyncio.html and recommend which patterns we should adopt for our websocket service."
<p></p>

## Context7 (Upstash) — "always‑fresh" API docs

**Cost:** Free tier for personal/edu; paid tiers available.

### Why use over vanilla agents

- **Eliminates training data staleness:** Injects version-correct API docs and code examples directly into context, so the model references current documentation instead of potentially outdated training data from months or years ago

- **Drastic reduction in API hallucinations:** By providing authoritative, up-to-date documentation at inference time, agents stop inventing deprecated methods, wrong parameter names, or non-existent API endpoints

- **Multi-version support:** Can fetch docs for specific library versions, critical when working with legacy codebases or coordinating upgrades across microservices with different dependency versions

- **Semantic code examples:** Returns real-world usage patterns and code snippets from official docs, not just method signatures, helping agents write idiomatic code that follows best practices

- **Broad coverage:** Works across hundreds of popular libraries and frameworks (AWS SDK, Stripe, OpenAI, Anthropic, Redis, Kafka, etc.), with automatic fallback to web documentation when specialized integrations aren't available

### Running the server

Visit the [**Context7 docs**](https://github.com/upstash/context7) for agent-specific guidelines.

### Examples to try

> "Implement S3 multipart upload with exponential backoff retries and abort handling. Use context7 to pull the latest AWS SDK v3 documentation and examples."
<p></p>

> "Fetch the current Stripe Checkout Session API docs via context7 and show me how to create a session with line items, success/cancel URLs, and customer email prefill."
<p></p>

> "Use context7 to get the latest Anthropic Messages API documentation, then implement streaming responses with tool use and explain the differences from the legacy completions API."
<p></p>

> "Pull Redis sorted sets documentation through context7 and write a leaderboard service with ZADD, ZRANGE, and ZREM operations. Include atomic score updates."
<p></p>

> "Get Kafka producer configuration docs via context7 for version 3.6.x specifically (our production version). Implement an idempotent producer with transactional semantics."
<p></p>

> "Use context7 to fetch OpenTelemetry tracing setup for Node.js, then instrument our Express API with automatic span creation and context propagation."
<p></p>


**Git (choose one implementation)**  
- **Gemini (Python server via uvx):**  
  ```bash
  gemini mcp add git uvx -- mcp-server-git
  ```
  *(alt Node)* `gemini mcp add git npx -- -y @cyanheads/git-mcp-server`
- **Codex:**  
  ```bash
  codex mcp add git -- npx -y @cyanheads/git-mcp-server
  ```
- **Claude Code:**  
  ```bash
  claude mcp add git -s user -- npx -y @cyanheads/git-mcp-server
  ```

**Fetch (web → Markdown)**  
- **Gemini (Python server):**  
  ```bash
  gemini mcp add fetch uvx -- mcp-server-fetch
  ```
- **Codex:**  
  ```bash
  codex mcp add fetch -- uvx mcp-server-fetch
  ```
- **Claude Code:**  
  ```bash
  claude mcp add fetch -s user -- uvx mcp-server-fetch
  ```

### B. Planning & Research (Context7, Tavily, Firecrawl)

**Context7 (API docs into context)**  
- **Gemini:**  
  ```bash
  gemini mcp add context7 npx -- -y @upstash/context7-mcp --api-key $CONTEXT7_API_KEY
  ```
- **Codex:**  
  ```bash
  codex mcp add context7 -- npx -y @upstash/context7-mcp
  ```
- **Claude Code:**  
  ```bash
  claude mcp add context7 -s user -- npx -y @upstash/context7-mcp
  ```

**Tavily (search / extract / map / crawl)**  
- **Gemini (remote HTTP):**  
  ```bash
  gemini mcp add tavily https://mcp.tavily.com/mcp/?tavilyApiKey=$TAVILY_API_KEY
  ```
- **Codex (remote HTTP via config)** — add to `~/.codex/config.toml`:
  ```toml
  [mcp_servers.tavily]
  url = "https://mcp.tavily.com/mcp/?tavilyApiKey=${TAVILY_API_KEY}"
  ```
  *(or run locally with)* `codex mcp add tavily -- npx -y @mcptools/mcp-tavily`
- **Claude Code (HTTP):**  
  ```bash
  claude mcp add --transport http tavily https://mcp.tavily.com/mcp/?tavilyApiKey=$TAVILY_API_KEY
  ```

**Firecrawl (robust crawl/scrape; JS pages)**  
- **Gemini (npx):**  
  ```bash
  gemini mcp add firecrawl npx -- -y firecrawl-mcp
  ```
- **Codex:**  
  ```bash
  codex mcp add firecrawl -- npx -y firecrawl-mcp
  ```
- **Claude Code:**  
  ```bash
  claude mcp add firecrawl -s user -- npx -y firecrawl-mcp
  ```

### C. Memory / Token‑efficiency

**Memory (reference knowledge‑graph)**  
- **Gemini:** `gemini mcp add memory npx -- -y @modelcontextprotocol/server-memory`  
- **Codex:** `codex mcp add memory -- npx -y @modelcontextprotocol/server-memory`  
- **Claude Code:** `claude mcp add memory -s user -- npx -y @modelcontextprotocol/server-memory`

**Postgres + pgvector (community servers)**  
- Add your server command where indicated:  
  - **Gemini:** `gemini mcp add pgmem <your-pgvector-server-cmd>`  
  - **Codex:** `codex mcp add pgmem -- <your-pgvector-server-cmd>`  
  - **Claude Code:** `claude mcp add pgmem -s user -- <your-pgvector-server-cmd>`

### D. Quality & Security Rails

**Semgrep (SAST)**  
- **Gemini (local stdio):**  
  ```bash
  gemini mcp add semgrep uvx -- semgrep-mcp
  ```
  *(or connect to remote SSE when applicable)*
- **Codex:**  
  ```bash
  codex mcp add semgrep -- uvx semgrep-mcp
  ```
- **Claude Code:**  
  ```bash
  # Remote SSE (hosted by Semgrep)
  claude mcp add --transport sse semgrep https://mcp.semgrep.ai/sse
  # OR local:
  claude mcp add semgrep -s user -- uvx semgrep-mcp
  ```

**Snyk (deps/IaC/containers)**  
- **Gemini:** `gemini mcp add snyk <your-snyk-mcp-cmd>`  
- **Codex:** `codex mcp add snyk -- <your-snyk-mcp-cmd>`  
- **Claude Code:** `claude mcp add snyk -s user -- <your-snyk-mcp-cmd>`

### E. Workflow Glue

**Composio / Rube (GitHub/Jira/Slack/Notion…)**  
- **Gemini:** `gemini mcp add rube npx -- @composiohq/rube`  
- **Codex:** `codex mcp add rube -- npx @composiohq/rube`  
- **Claude Code:** `claude mcp add rube -s user -- npx @composiohq/rube`

---

### Verify & manage

- **Gemini CLI:** run `/mcp` to see active servers/tools.  
- **Codex CLI:** run `/mcp` inside the TUI; edit `~/.codex/config.toml` for finer control.  
- **Claude Code:** run `/mcp` to list; supports `.mcp.json` (project), user & enterprise‑managed configs; transports: **http**, **sse**, **stdio**.

> **Security tip:** Prefer least‑privilege (path allow‑lists, read‑only where possible). For remote HTTP/SSE servers, review auth scopes and rotate tokens regularly.

---

## Appendix — User vs Project Config (Claude Code, Codex CLI, Gemini CLI)

Use **user/global config** to “set & forget” shared servers, and **project config** for path‑scoped tools (Filesystem), policies (Semgrep/Snyk), or per‑repo memory namespaces.

> **Verify fast:** in any client session, type **`/mcp`** to list active servers & tools.

### A) Gemini CLI

**Where config lives**
- **User:** `~/.gemini/settings.json` (default for `gemini mcp add …`)
- **Project:** `.gemini/settings.json` in the repo (use `-s project` after `gemini mcp add`)

**User config (one root for many repos)**
```jsonc
{
  "mcpServers": {
    "fs": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "~/Projects"],
      "transport": "stdio",
      "enabled": true
    },
    "tavily": {
      "url": "https://mcp.tavily.com/mcp/?tavilyApiKey=${TAVILY_API_KEY}",
      "transport": "http",
      "enabled": true
    }
  }
}
```

**Project config (safer: repo‑local root)**
```jsonc
// .gemini/settings.json (checked into the repo if you wish)
{
  "mcpServers": {
    "fs": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."],
      "transport": "stdio",
      "enabled": true
    },
    "semgrep": {
      "command": "uvx",
      "args": ["semgrep-mcp"],
      "transport": "stdio",
      "env": { "SEMGREP_RULES": "./.semgrep/rules" }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": { "MEMORY_NAMESPACE": "locker" }
    }
  }
}
```

**Switch scope via commands**
```bash
# User/global
gemini mcp add fs npx -- -y @modelcontextprotocol/server-filesystem ~/Projects

# Project‑scoped (writes .gemini/settings.json in the repo)
gemini mcp add -s project fs npx -- -y @modelcontextprotocol/server-filesystem .
```

---

### B) OpenAI Codex CLI

**Where config lives**
- **Global:** `~/.codex/config.toml`
- **Profiles:** define named profiles in the same file and launch with `codex --profile <name>`

**Global config (one root for many repos)**
```toml
[mcp_servers.fs]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "~/Projects"]
transport = "stdio"
enabled = true

[mcp_servers.tavily]
url = "https://mcp.tavily.com/mcp/?tavilyApiKey=${TAVILY_API_KEY}"
transport = "http"
enabled = true
```

**Profile for a specific repo (safer root)**
```toml
[profiles.locker.mcp_servers.fs]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "."]
transport = "stdio"
enabled = true

[profiles.locker.env]
MEMORY_NAMESPACE = "locker"
SEMGREP_RULES = "./.semgrep/rules"
```

**Launch with a profile**
```bash
codex --profile locker
```

---

### C) Claude Code (CLI + VS Code)

**Where config lives**
- **User:** stored by `claude mcp add …` at user scope
- **Project:** `.mcp.json` (checked into the repo if you like)

**Project config (`.mcp.json`) — per‑repo root & policies**
```jsonc
{
  "mcpServers": {
    "fs": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."],
      "transport": "stdio",
      "enabled": true
    },
    "tavily": {
      "url": "https://mcp.tavily.com/mcp/?tavilyApiKey=${TAVILY_API_KEY}",
      "transport": "http",
      "enabled": true
    },
    "semgrep": {
      "command": "uvx",
      "args": ["semgrep-mcp"],
      "transport": "stdio",
      "env": { "SEMGREP_RULES": "./.semgrep/rules" }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": { "MEMORY_NAMESPACE": "locker" }
    }
  }
}
```

**User scope via commands**
```bash
# Broad root for many repos (least friction)
claude mcp add fs -s user -- npx -y @modelcontextprotocol/server-filesystem ~/Projects

# Repo‑local root (least privilege) — run inside the repo
claude mcp add fs -s project -- npx -y @modelcontextprotocol/server-filesystem .
```

---

### One‑root vs Many‑roots (Filesystem)

- **One root** (e.g., `~/Projects`): simplest — works across all repos inside that path.  
  *Trade‑off:* broader access; rely on allow‑lists and human‑in‑the‑loop for safety.
- **Many roots** (per‑repo `.`): most secure — each repo declares its own filesystem server in **project config**.  
  *Trade‑off:* a bit more setup when creating a new repo.

**Tip:** For monorepos, prefer **project config** at the workspace root and specify additional allow‑listed subpaths via server args if your filesystem server supports them.
