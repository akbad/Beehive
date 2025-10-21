# Must-have MCPs

A practical guide to **must‑have MCP servers** and adjacent tools that *meaningfully* upgrade dev flow when using
- Gemini CLI
- Claude Code
- Codex CLI

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
                    "--search",    // enable auto-approve for all web searches
                    "-c",          // allows overriding config values w/ key-value pairs that come after
                    "model_reasoning_effort=\"high\""
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
> - **Prompt:** Use clink with role="planner" prompt="Outline the plan for shipping the new auth service.
> - **Subsequent prompt *(resumes previous planner session)*:** Use clink with role="planner" continuation_id="<paste id>" prompt="Refine the timeline with detailed milestones."
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
> - **Prompt:** clink with cli_name="gemini" prompt="Find 2025 best practices for securing WebAuthn attestation and list references."
> - **Subsequent prompt** Use clink with cli_name="codex" prompt="Given Gemini’s findings, patch auth/webauthn_handler.py to harden attestation validation."
<p></p>

## Filesystem MCP

> For reliable filesystem access.

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

**Note:** The official Filesystem MCP server **only supports stdio transport**. Unlike other MCP servers, it does not have HTTP or SSE capabilities. Each agent must run its own instance.

#### Via `stdio` (per-agent)

The agent client will start and stop the server automatically as needed when you launch/exit the agent.

| Agent | Command |
| :--- | :--- |
| Gemini CLI | `gemini mcp add fs npx -- -y @modelcontextprotocol/server-filesystem [your-allowed-directory]` |
| Codex CLI | `codex mcp add fs -- npx -y @modelcontextprotocol/server-filesystem [your-allowed-directory]` |
| Claude Code | `claude mcp add fs -s user -- npx -y @modelcontextprotocol/server-filesystem [your-allowed-directory]` |

### Examples to try

> “Read `server/**/*.go` and propose a patch adding retries with exponential backoff; write diffs but do not commit.”
<p></p>

## Git MCP

> For reliable Git operations

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

## Fetch MCP

> For vastly more efficient and reliable webpage processing.

**Cost:** Free / open source.

### Why use over vanilla agents

- **Token efficiency:** Automatically converts HTML to clean Markdown with intelligent chunking, drastically reducing token usage compared to raw HTML while preserving document structure

- **Smart content extraction:** Strips navigation, ads, and boilerplate automatically, leaving only the meaningful content for the agent to process

- **Structured output for citations:** Maintains headings, links, and code blocks in Markdown format, making it easy for agents to cite sources accurately and preserve technical details

- **Handles dynamic content:** Can process JavaScript-rendered pages and modern web applications that basic `curl` or `wget` would fail on

- **Consistent format across sources:** Normalizes content from different websites into a uniform Markdown structure, eliminating brittleness from parsing diverse HTML layouts

### Running the server

**Note:** The official Fetch MCP server **only supports stdio transport**. Unlike some other MCP servers, it does not have HTTP or SSE capabilities. Each agent must run its own instance.

#### Via `stdio` (per-agent)

The agent client will start and stop the server automatically as needed when you launch/exit the agent.

| Agent | Command |
| :--- | :--- |
| Gemini CLI | `gemini mcp add fetch uvx -- mcp-server-fetch` |
| Codex CLI | `codex mcp add fetch -- uvx mcp-server-fetch` |
| Claude Code | `claude mcp add fetch -s user -- uvx mcp-server-fetch` |

### Examples to try

> "Fetch the Kafka idempotent producer docs at https://kafka.apache.org/documentation/#producerconfigs and summarize the integration steps for our service (bullets + code). Include links to relevant sections."
<p></p>

> "Fetch https://redis.io/docs/manual/patterns/distributed-locks/ and extract the RedLock algorithm steps into a numbered list with code examples."
<p></p>

> "Compare rate limiting strategies by fetching these three articles: [URL1], [URL2], [URL3]. Summarize pros/cons of each approach in a comparison table."
<p></p>

> "Fetch the latest Python async best practices from https://docs.python.org/3/library/asyncio.html and recommend which patterns we should adopt for our websocket service."
<p></p>

## Context7 (Upstash) 

> For "always‑fresh" API docs

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

## Qdrant MCP 

> For persistent, efficient and easily-shareable semantic memory

**Cost:** Free / open source (self-host).

### Why use over simple transcript files

- **Semantic recall instead of raw logs:** Store ADRs, constraints, design notes, and retrieve them by meaning (`qdrant-find`) instead of replaying entire chat histories.
- **Structured metadata filters:** Tag memories with components, severity, owner, or sprint and filter when querying.
- **Shared across agents:** One Qdrant instance can serve Claude Code, Codex CLI, Gemini CLI simultaneously, so context stays consistent.
- **Ready to scale later:** Keep it local now, move to remote Qdrant (or snapshots) if you need team-wide memory later.

### Running the server

#### Via `http`

1. Run Qdrant (single node, local persistent storage):

    ```bash
    docker run -d \
      --name qdrant \
      -p 6333:6333 \
      -v ~/qdrant-data:/qdrant/storage \
      qdrant/qdrant
    ```

2. Launch the MCP wrapper (uses FastMCP over HTTP):

    ```bash
    QDRANT_URL=http://127.0.0.1:6333 \
    COLLECTION_NAME=engineering-memory \
    EMBEDDING_PROVIDER=fastembed \
    uvx mcp-server-qdrant --transport http --port 8050
    ```

3. Register with each CLI:

    - Gemini CLI: `gemini mcp add qdrant http --url http://localhost:8050/mcp/`
    - Claude Code: `claude mcp add --transport http qdrant http://localhost:8050/mcp/`
    - Codex CLI (`~/.codex/config.toml`):

        ```toml
        [mcp_servers.qdrant]
        url = "http://localhost:8050/mcp/"
        transport = "http"
        ```

#### Via `stdio`

If you prefer the CLI to manage the process (one at a time), run Qdrant locally as above, then register:

| Agent | Command |
| :--- | :--- |
| Gemini CLI | `gemini mcp add qdrant env QDRANT_URL=http://127.0.0.1:6333 env COLLECTION_NAME=engineering-memory env EMBEDDING_PROVIDER=fastembed uvx mcp-server-qdrant` |
| Codex CLI | `codex mcp add qdrant -- env QDRANT_URL=http://127.0.0.1:6333 env COLLECTION_NAME=engineering-memory env EMBEDDING_PROVIDER=fastembed uvx mcp-server-qdrant` |
| Claude Code CLI | `claude mcp add qdrant -s user -- env QDRANT_URL=http://127.0.0.1:6333 env COLLECTION_NAME=engineering-memory env EMBEDDING_PROVIDER=fastembed uvx mcp-server-qdrant` |

### Examples to try

> “Store the ADR describing our read-repair invariants with tag `component=locker`.”  
> Later: “Find prior decisions tagged component=locker mentioning ‘read repair’ before I change the reconciler.”  
<p></p>

> “Save a summary of the DynamoDB throttling postmortem (tag it high_severity, date=2024-09-12).”  
> Then: “Retrieve high_severity incidents about DynamoDB before planning retries.”  
<p></p>

> “Remember the auth team service limits (owner=security, expires=2025-06-30).”  
> Afterwards: “Pull security-owned memories that mention service limits.”
<p></p>

> “Store the auth migration blueprint in collection `architecture-decisions` with metadata `{"phase":"rollout","sprint":"2025-02"}`.”  
> Later: “Search `architecture-decisions` for entries where phase=rollout mentioning ‘auth’ to prep the release brief.”
<p></p>

> “Ahead of the infra sync, run `qdrant-find` with a filter `{"must":[{"key":"owner","match":{"value":"infra"}},{"key":"created_at","range":{"gte":"2025-01-01"}}]}` and summarize the retrieved memories into action items.”
<p></p>

## Tavily 

> For searching, extracting, mapping and crawling the web, with citations.

**Cost:** Free tier (monthly credits), paid plans for higher volume.

### Why use over basic web search MCP

- **AI-optimized search results:** Unlike traditional search APIs (Google, Bing, SerpAPI), Tavily reviews multiple sources and extracts the most relevant content from each, delivering concise, LLM-ready information optimized for agent context windows

- **Built-in citation tracking:** Every search result includes source URLs and attribution, making it trivial for agents to provide traceable sources in documentation, research summaries, and design decisions

- **Four complementary tools:** Combines `search` (real-time web queries), `extract` (raw content from URL lists), `map` (generate sitemaps from a base URL), and `crawl` (graph-based traversal with parallel path exploration) — agents can orchestrate multi-step research workflows in a single conversation

- **Production-grade filtering:** Advanced options for search depth (basic/advanced), time range filtering (recent news, last 7 days, etc.), domain-specific targeting, and maximum result limits give agents fine-grained control over result quality vs token cost

- **Remote deployment option:** Connect to Tavily's hosted MCP server instead of managing local processes — reduces setup friction and enables instant access across all agent CLIs without environment configuration

### Running the server

Tavily provides a hosted MCP server — no local installation required:

1. Get your Tavily API key from [tavily.com](https://www.tavily.com/)

2. Connect agents to the remote endpoint:

    - Gemini CLI: `gemini mcp add tavily http --url "https://mcp.tavily.com/mcp/?tavilyApiKey=$TAVILY_API_KEY"`
    - Claude Code: `claude mcp add --transport http tavily "https://mcp.tavily.com/mcp/?tavilyApiKey=$TAVILY_API_KEY"`
    - Codex CLI: add to `~/.codex/config.toml`:

        ```toml
        [mcp_servers.tavily]
        url = "https://mcp.tavily.com/mcp/?tavilyApiKey=${TAVILY_API_KEY}"
        transport = "http"
        ```

### Examples to try

> "Search for 'event-sourced outbox pattern' best practices published in the last year. Return pros/cons, common failure modes, and 5 citations with URLs."
<p></p>

> "Map the Redis documentation site (redis.io/docs) to understand its structure, then extract content from the distributed locks and transactions pages. Summarize how to implement safe distributed mutations."
<p></p>

> "Search for recent news about Rust async runtime developments (last 30 days). Filter results to include only tokio.rs and rust-lang.org. Summarize breaking changes and migration paths."
<p></p>

> "Extract the main content from these three PostgreSQL performance tuning articles: [URL1], [URL2], [URL3]. Compare their recommendations for connection pooling and create a decision matrix."
<p></p>

> "Crawl the Stripe API changelog starting from stripe.com/docs/upgrades and follow internal links up to 3 levels deep. Identify all breaking changes in the last 12 months that affect webhook signatures."
<p></p>

> "Search for 'DynamoDB single-table design' with advanced search depth, limit to 10 results, and include only stackoverflow.com and aws.amazon.com domains. Extract code examples and explain trade-offs for multi-tenant SaaS."
<p></p>

## Firecrawl 

> For resilient web scraping & deep crawls.

**Cost:** Free starter credits; paid plans for higher volume.

### Why use over basic Fetch MCP

- **JavaScript-rendered page support:** Handles 96% of the web including JS-heavy sites, SPAs, and protected pages that basic `curl` or `wget` cannot access — no proxy configuration needed

- **Interactive scraping capabilities:** Can perform actions (click, scroll, write, wait, press) before extracting content, enabling scraping of content behind interactions like "Load More" buttons or infinite scroll

- **Batch processing and parallel execution:** Process multiple URLs simultaneously with built-in retry logic, automatic backoff, and progress monitoring — ideal for extracting documentation sets or crawling entire wiki sections

- **AI-powered structured extraction:** Use natural language prompts to extract specific structured data without knowing exact selectors or page structure, powered by LLM capabilities that adapt to different page layouts

- **Comprehensive web operations:** Combines `scrape` (single page), `batch_scrape` (multiple URLs), `crawl` (recursive traversal), `map` (URL discovery), `search` (web search), and `extract` (structured data) in one unified API

- **Fire-engine proprietary backend:** Cloud API includes advanced anti-bot evasion, intelligent proxy rotation, and automatic CAPTCHA solving — not available in self-hosted deployments

### Running the server

Firecrawl provides a hosted MCP server with Fire-engine (their proprietary anti-bot, proxy management, and CAPTCHA-solving backend) — no local installation required:

1. Get your Firecrawl API key from [firecrawl.dev/app/api-keys](https://firecrawl.dev/app/api-keys)

2. Connect agents to the remote endpoint:

    - Gemini CLI: `gemini mcp add firecrawl http --url "https://mcp.firecrawl.dev/$FIRECRAWL_API_KEY/v2/mcp"`
    - Claude Code: `claude mcp add --transport http firecrawl "https://mcp.firecrawl.dev/$FIRECRAWL_API_KEY/v2/mcp"`
    - Codex CLI: add to `~/.codex/config.toml`:

        ```toml
        [mcp_servers.firecrawl]
        url = "https://mcp.firecrawl.dev/${FIRECRAWL_API_KEY}/v2/mcp"
        transport = "http"
        ```

**Note:** While Firecrawl can be self-hosted, the self-hosted version lacks Fire-engine (anti-bot evasion, proxy rotation, CAPTCHA handling), making the cloud service significantly more capable for production scraping.

### Examples to try

> "Scrape the Next.js documentation page at nextjs.org/docs/app/building-your-application/routing and extract all routing concepts into a structured markdown summary with code examples."
<p></p>

> "Crawl our internal wiki starting from wiki.company.com/engineering/payments with max depth 3. Extract all constraint definitions, decision records, and open questions into categorized lists."
<p></p>

> "Map the entire Stripe API documentation site (stripe.com/docs/api) to discover all endpoint URLs, then batch scrape the authentication and webhooks sections. Compare their security recommendations."
<p></p>

> "Search for 'GraphQL federation best practices' and extract the top 5 results. For each result, scrape the full content and create a comparison table of pros, cons, and implementation complexity."
<p></p>

> "Use the extract tool with this prompt: 'Find all pricing tiers, their features, and annual costs' on competitor-site.com/pricing. Return as structured JSON with tier name, features array, and cost in USD."
<p></p>

> "Crawl the React documentation starting from react.dev/learn, but first click the 'Show more examples' button on each page before extracting. Compile all interactive examples into a single reference document."
<p></p>

> "Batch scrape these 10 Medium articles about microservices architecture [URL1-URL10]. Extract author name, publication date, key takeaways (3-5 bullets), and any code snippets. Generate a synthesized summary."
<p></p>

## Sourcegraph 

> For efficient, precise, semantic code search across millions of open-source repos, **for free**.

**Cost:** Free for public code on Sourcegraph.com; paid plans or self-hosted required for private/org code.

### Why use over local grep/search

- **Cross-repository code search at scale:** Search across hundreds or thousands of repositories simultaneously using Sourcegraph's indexed search, far faster and more comprehensive than local `grep`, `rg`, or file-by-file exploration

- **Advanced query language with structured results:** Leverage RE2 regex, boolean operators (AND/OR with proper precedence), and powerful filters (`repo:`, `file:`, `lang:`, `rev:`) to construct precise queries that return machine-readable, structured results instead of fragile text parsing

- **Evidence gathering before refactors:** Agents can proactively search for all usages of a function, class, or API across your entire codebase to assess impact, identify breaking changes, and generate migration strategies before making edits

- **Semantic code navigation:** Beyond text matching, search for definitions, references, and implementations across repositories, enabling agents to understand call graphs, dependency relationships, and architectural patterns

- **Three complementary tools:** Combines `search` (advanced code queries), `search_prompt_guide` (context-aware query construction help), and content retrieval (fetch file contents and explore directory structures) to orchestrate comprehensive codebase analysis workflows

- **Free access to millions of open-source repos:** Search public code on Sourcegraph.com at no cost — ideal for learning from real-world codebases, finding usage examples, and researching best practices without any setup

### Running the server

The community-maintained [divar-ir/sourcegraph-mcp](https://github.com/divar-ir/sourcegraph-mcp) server provides MCP access to Sourcegraph's code search capabilities. By default, it connects to the free **Sourcegraph.com** public search (no token needed).

#### Via `http` (when using many agents together)

**Recommended for most users — connects to free Sourcegraph.com by default:**

1. Clone and set up the server:

    ```bash
    git clone https://github.com/divar-ir/sourcegraph-mcp
    cd sourcegraph-mcp
    uv sync
    ```

2. Configure environment variables (add to `.bashrc`/`.zshrc`):

    ```bash
    # For public code search (Sourcegraph.com) - FREE, no token needed
    export SRC_ENDPOINT="https://sourcegraph.com"

    # Optional: customize ports if 8080 is already in use
    export MCP_SSE_PORT=8000
    export MCP_STREAMABLE_HTTP_PORT=8080
    ```

3. Start the server (*leave this terminal running*):

    ```bash
    uv run python -m src.main
    ```

4. Connect agents:

    - Gemini CLI: `gemini mcp add sourcegraph http --url http://localhost:8080/sourcegraph/mcp/`
    - Claude Code: `claude mcp add --transport http sourcegraph http://localhost:8080/sourcegraph/mcp/`
    - Codex CLI: add to `~/.codex/config.toml`:

        ```toml
        [mcp_servers.sourcegraph]
        url = "http://localhost:8080/sourcegraph/mcp/"
        transport = "http"
        ```

#### For private code (optional)

If you need to search private repositories, you have two options:

**Option 1: Connect to your organization's Sourcegraph instance**

```bash
export SRC_ENDPOINT="https://sourcegraph.yourcompany.com"
export SRC_ACCESS_TOKEN="your-sourcegraph-token"
```

Then start the server as shown above.

**Option 2: Self-host Sourcegraph (not recommended for personal use)**

- **Minimum requirements:** 8 CPU cores, 20-24GB RAM, SSD storage
- **M1/M2 Mac limitations:** Not officially supported; requires `--platform linux/amd64` emulation (slower)
- **Resource impact:** Runs 15+ Docker containers; will consume significant system resources
- **Recommendation:** Only worthwhile for teams/orgs with substantial infrastructure

For personal use on a 16GB Mac, stick with the free Sourcegraph.com option instead of self-hosting.

### Examples to try

> "Search across all repositories for usages of the `WriteBatch` class. Summarize where it's used and what would break if we changed its return type from `Promise<void>` to `Promise<Result>`."
<p></p>

> "Find all functions that call `authenticateUser` across the organization's repos. Check if any are missing error handling or timeout logic. Generate a migration plan."
<p></p>

> "Search for all TypeScript files in repositories matching 'backend-*' that import from '@aws-sdk/client-dynamodb'. Extract the table names being accessed and create a dependency map."
<p></p>

> "Use the search_prompt_guide tool to help me construct a query for finding all API endpoints that perform database writes without transaction wrappers in our microservices."
<p></p>

> "Search for regex pattern `context\.Background\(\)` in Go files across all repos. Identify services that aren't using context for cancellation and explain the risks."
<p></p>

> "Find all occurrences of deprecated method `getUserById` (case-insensitive) across repos, fetch the file contents for each match, and generate refactoring diffs to use `getUserByIdV2` instead."
<p></p>

> "Search repositories containing 'auth' OR 'identity' for files modified in the last 30 days that mention 'JWT' or 'token'. Summarize recent security-related changes for our audit."
<p></p>


## Semgrep MCP 

> For deterministic static code and security analysis.

**Cost:** Community edition free / open source; Teams/Enterprise paid tiers.

### Why use over manual security reviews

- **Deterministic security scanning in the agent loop:** Fast, reliable static analysis with structured, machine-readable findings that agents can parse and act on — no fragile text parsing of security tool output or post-hoc vulnerability discovery

- **Catch AI-generated code issues before commit:** Enables agents to scan their own code generation immediately, detect security vulnerabilities, hardcoded secrets, and correctness bugs, then iteratively fix and re-scan until clean — bringing AppSec into the "vibe coding" workflow

- **Semantic code understanding across 30+ languages:** Goes beyond regex pattern matching with language-aware analysis that understands syntax, control flow, and data flow — reduces false positives and catches real bugs that simple linters miss

- **5000+ production-tested rules out of the box:** Instant access to community and Semgrep-maintained rules covering OWASP Top 10, CWE categories, secret detection, and language-specific best practices — no need to write security rules from scratch

- **Custom rule authoring for project-specific constraints:** Agents can use `semgrep_scan_with_custom_rule` to enforce organization-specific patterns, banned API usage, or architectural guidelines — making policy-as-code actionable during development

- **Abstract Syntax Tree (AST) introspection:** The `get_abstract_syntax_tree` tool enables agents to understand code structure programmatically, supporting advanced refactoring, migration, and analysis workflows beyond simple security scanning

- **Cloud platform integration for team-wide visibility:** Optional `semgrep_findings` tool (requires Semgrep AppSec Platform) retrieves historical findings, tracks remediation status, and maintains security posture across repositories — useful for agents generating compliance reports or prioritizing fixes

### Running the server

Semgrep MCP server (version 0.9.0 as of October 2025) supports stdio, streamable HTTP, and SSE transports. The official package is `semgrep-mcp` on PyPI, with Docker images at `ghcr.io/semgrep/mcp`.

**Follow [these steps for installing Semgrep via `homebrew` and using it to launch the Semgrep MCP](https://github.com/semgrep/semgrep/tree/develop/cli/src/semgrep/mcp#usage)**

> These steps use the free, open-source Community Edition (Semgrep CE)

#### Via `http` (when using many agents together)

Semgrep recommends **streamable HTTP** (not legacy SSE) for shared deployments:

1. Install the Semgrep binary via homebrew:

    ```bash
    brew install semgrep
    ```

3. Set the port you want the server to use:

    ```bash
    export SEMGREP_MCP_PORT=8084
    ```

4. Start the central server (*leave this terminal running*):

    ```bash
    semgrep mcp -t streamable-http --port $SEMGREP_MCP_PORT
    ```

    By default, the server listens at `127.0.0.1:8000/mcp`. Use `--port` to customize.

5. Connect agents:

    - Gemini CLI: `gemini mcp add semgrep http --url http://localhost:$SEMGREP_MCP_PORT/mcp/`
    - Claude Code: `claude mcp add --transport http semgrep http://localhost:$SEMGREP_MCP_PORT/mcp/`
    - Codex CLI: add to `~/.codex/config.toml`:

        ```toml
        [mcp_servers.semgrep]
        url = "http://localhost:8084/mcp/"
        transport = "http"
        ```

#### Via `stdio` (if only using one agent at a time)

The agent client will start and stop the server automatically as needed.

| Agent | Command |
| :--- | :--- |
| Gemini CLI | `gemini mcp add semgrep uvx -- semgrep-mcp` |
| Codex CLI | `codex mcp add semgrep -- uvx semgrep-mcp` |
| Claude Code | `claude mcp add semgrep -s user -- uvx semgrep-mcp` |

### Examples to try

> "Run a security check on `src/auth/login.py` and list any High or Critical vulnerabilities. For each finding, explain the risk and propose a fix."
<p></p>

> "Scan all TypeScript files in `backend/api/` for hardcoded secrets, API keys, or credentials. If you find any, suggest environment variable replacements."
<p></p>

> "Use a custom Semgrep rule to detect all Express.js routes that don't validate input with Zod schemas. Generate the rule, scan the codebase, and propose patches for non-compliant routes."
<p></p>

> "Get the Abstract Syntax Tree for `util/parser.ts`, identify all functions that throw exceptions, and document their error handling contracts."
<p></p>

> "Scan the files I just modified (use git diff) with Semgrep's OWASP Top 10 rules. If any Medium+ severity issues are found, fix them and re-scan until the branch is clean before I commit."
<p></p>

> "Fetch Semgrep findings from the AppSec Platform for the `payments-service` repository. Filter for unresolved Critical issues introduced in the last 7 days and generate a markdown remediation report."
<p></p>

> "List all programming languages Semgrep supports. Then scan our polyglot monorepo (Go, Python, JavaScript, Rust) and summarize vulnerability counts by language and severity."
<p></p>

> "Show me the Semgrep rule JSON Schema so I can write a custom rule banning usage of `eval()` and `exec()` in our Python codebase. After you create the rule, scan all `.py` files and report violations."
<p></p>

---

## *Essential non-MCP tool:* GitHub Spec-Kit 

> A precise, powerful specification-driven development framework

**Cost:** Free / open source (v0.0.69 as of October 2025)

### Why use alongside MCPs and agent CLIs

- **Process framework for planning artifacts:** While MCPs provide **capabilities** (search, memory, security scanning), Spec-Kit provides **workflow structure** — transforms "vibe-coding" into systematic spec → plan → tasks → implement flows with reviewable, in-repo artifacts

- **Executable specifications as contracts:** Specifications become **executable** rather than static documents — they directly generate working implementations instead of merely guiding them, treating coding agents as "literal-minded pair programmers" that need unambiguous instructions

- **Separates stable "what" from flexible "how":** Captures **intent as source of truth** independent of implementation details, enabling parallel implementations across diverse tech stacks and making specs portable across different LLM providers and agent CLIs

- **Team-friendly artifact generation:** Creates diffable, version-controlled documents (constitution, spec, plan, tasks) that live in-repo for human review before implementation — critical for teams with code review processes or when building medium/large features

- **Universal slash command interface:** Equips 12+ agent CLIs (Claude Code, Gemini CLI, Codex CLI, Cursor, Windsurf, etc.) with consistent `/speckit.*` commands for constitution, specify, plan, tasks, implement, clarify, analyze, and checklist operations

- **Prevents scope creep with checkpoints:** Forces deliberate "plan before code" discipline through structured phases — architect can review plan, team can review spec, stakeholders can review requirements before any code changes happen

- **Optional quality gates:** Use `/speckit.checklist` to generate domain-specific checklists (UX, security, accessibility) and `/speckit.analyze` for cross-artifact consistency validation before implementation

### Installation

**Persistent installation (recommended):**

```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
```

**One-time usage (for quick setup):**

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init <PROJECT_NAME>
```

**With AI agent selection:**

```bash
# For Claude Code
specify init my-project --ai claude

# For Gemini CLI
specify init my-project --ai gemini

# For Codex CLI
specify init my-project --ai codex
```

**Additional options:**
- `--script [sh|ps]` — Choose Bash (.sh) or PowerShell (.ps1) scripts
- `--here` — Initialize in current directory instead of creating new folder
- `--ignore-agent-tools` — Skip tool verification (get templates without checks)

**Verify installation:**

```bash
specify check   # Verifies installed tools (git, agent CLIs, etc.)
```

### Core workflow and slash commands

Spec-Kit implements a five-phase process accessed via slash commands in your agent CLI:

#### 1. Constitution (`/speckit.constitution`)

Establish project governing principles and non-negotiable constraints.

**Example:**
```
/speckit.constitution Performance is critical. All database queries must complete in <100ms. Zero-downtime deploys required. Property-based tests for core logic.
```

#### 2. Specify (`/speckit.specify`)

Define **WHAT** to build — requirements, user stories, success metrics.

**Example:**
```
/speckit.specify Add read-repair and anti-entropy sync to the eventually consistent KV store. Users should see consistent data within 5 seconds across all nodes.
```

#### 3. Plan (`/speckit.plan`)

Create **HOW** — technical implementation strategy, stack decisions, architecture.

**Example:**
```
/speckit.plan Go + gRPC; background reconciler running every 30s; Lamport timestamps for conflict resolution; property tests with quickcheck.
```

#### 4. Tasks (`/speckit.tasks`)

Break plan into actionable, reviewable chunks.

**Example:**
```
/speckit.tasks
```

Agent generates numbered task list with dependencies, estimates, and acceptance criteria.

#### 5. Implement (`/speckit.implement`)

Execute all tasks using agent's native tools (edit files, run tests, commit).

**Example:**
```
/speckit.implement
```

Agent orchestrates multi-file changes, runs tests, creates commits with descriptive messages.

#### Optional commands

- `/speckit.clarify` — Resolve underspecified or ambiguous areas in spec/plan
- `/speckit.analyze` — Validate consistency across constitution, spec, plan, tasks
- `/speckit.checklist` — Generate domain-specific quality checklists (UX, security, accessibility)

### When to use Spec-Kit

**Use for:**
- **Medium/large features** (3+ files, cross-cutting concerns)
- **Architectural changes** (database migrations, API redesigns, refactors)
- **Team projects** where specs/plans need human review before implementation
- **0-to-1 projects** where starting from scratch benefits from clear requirements
- **Cross-stack exploration** where you want portable specs that work across different implementations

**Skip for:**
- **One-file bug fixes** or trivial changes
- **Exploratory prototypes** where you're just experimenting
- **Solo "hack day" projects** where process overhead isn't worth it

### Integration with MCP-enhanced workflows

Spec-Kit acts as the **orchestration layer** that coordinates MCP capabilities and agent execution:

```
┌───────────────┐
│  Spec-Kit   │  ← Process framework (artifacts, workflow)
│ Constitution│
│ Specify     │
│ Plan        │
│ Tasks       │
└───────┬───────┘
       │
       ├─→ Research Phase (MCPs provide context)
       │   ├─ Sourcegraph: Find all code touch points
       │   ├─ Context7: Fetch latest API docs
       │   ├─ Qdrant: Retrieve past architectural decisions
       │   └─ Tavily: Research best practices
       │
       ├─→ Planning Phase (Agent + MCPs)
       │   ├─ Use Fetch/Firecrawl for documentation
       │   ├─ Use Semgrep to understand existing patterns
       │   └─ Generate spec and plan artifacts
       │
       └─→ Execution Phase (Agent + MCPs)
           ├─ Agent: Implement with auto-testing
           ├─ Semgrep: Security validation
           ├─ Git MCP: Structured commits
           └─ Qdrant: Store decisions for future reference
```

### Example workflow: Auth service migration

```bash
# Phase 1: Constitution
/speckit.constitution Zero downtime. Backward compatibility for 2 weeks. All endpoints <200ms p99. Security-first.

# Phase 2: Research with MCPs
# (Agent automatically uses Sourcegraph to find all auth calls, Context7 for Auth0 docs)
/speckit.specify Migrate from custom JWT auth to Auth0. Support both auth methods during transition. Feature flag controls rollout.

# Phase 3: Planning
/speckit.plan Next.js middleware for Auth0. Feature flag in Redis. Dual auth validation for 2 weeks. Metrics for both paths.

# Phase 4: Task breakdown
/speckit.tasks

# Phase 5: Review tasks, then execute
/speckit.implement

# Phase 6: Validation with Semgrep
/semgrep scan src/auth/ for High/Critical issues. Fix all findings before merging.
```

### Supported agents (as of October 2025)

**Fully supported:**

- Claude Code CLI
- GitHub Copilot
- Gemini CLI
- Codex CLI
- Cursor
- Qwen Code
- opencode
- Windsurf
- Kilo Code
- Auggie CLI
- CodeBuddy CLI
- Roo Code

### Examples to try

> "Run /speckit.constitution to define that all API endpoints must validate input with Zod, return structured errors, and have integration tests."
<p></p>

> "Use /speckit.specify to create a spec for adding rate limiting to our REST API with Redis-backed sliding window, configurable limits per endpoint, and admin override capability."
<p></p>

> "Run /speckit.plan after the spec is approved. Then use Sourcegraph to identify all API routes that need rate limiting middleware."
<p></p>

> "Generate tasks with /speckit.tasks, review them, then implement with /speckit.implement."
<p></p>

> "Use /speckit.clarify to resolve ambiguity in the caching strategy mentioned in the plan. Should we use write-through or write-behind?"
<p></p>

> "Run /speckit.analyze to check consistency between our 'performance first' constitution and the plan's proposed synchronous database calls."
<p></p>

> "Use /speckit.checklist with focus on security. Generate a checklist for validating our authentication implementation before production."
<p></p>

> **[Full workflow]** "Create a complete feature spec for webhook delivery system: `/speckit.constitution `(reliability, at-least-once semantics), /speckit.specify (retry logic, dead letter queue), /speckit.plan (architecture), /speckit.tasks (breakdown), then /speckit.implement."
<p></p>

### Caveats and evolution

- **Active development:** Version 0.0.69 as of October 2025; rapid iteration with frequent releases
- **Template updates:** Some agent profiles still catching up with latest features
- **Slash command issues:** If commands misbehave, check [GitHub issues](https://github.com/github/spec-kit/issues) or re-run `specify init` to refresh templates
- **Constitution overwriting:** Be cautious when re-initializing; the init command may overwrite existing constitution.md

---

## Security: run tools like you would any extension

- **Allow‑list paths** and prefer **read‑only** where possible.  
- **Scope tokens** narrowly (separate keys per server).  
- Prefer **HTTP on localhost** or a proxy that can quarantine new servers.  
- Keep a **human‑in‑the‑loop** on dangerous tools (write/exec).  
- Stay current: the ecosystem is new; malicious servers have already appeared in the wild. Rotate creds if you ever suspect compromise.

---

## Decision guide (what to use when)

- **Repo comprehension / giant specs** → **Gemini CLI + Fetch/Firecrawl + Memory**  
- **Org‑wide code impact** → **Sourcegraph MCP**  
- **Plan‑then‑execute** → **Spec‑Kit** to create artifacts, then **Git/Filesystem** + your agent  
- **Security/correctness gate** → **Semgrep** (+ **Snyk** for deps/IaC/containers)  
- **Ticketing & communication** → **Composio/Rube**  
- **Token efficiency** → Prefer **Fetch** (HTML→MD), store background in **Memory**, and use a proxy/manager if you connect lots of servers

---

## Pricing at a glance (subject to change)

- **Free/OSS:** Filesystem, Git, Fetch, Memory (ref), MCP‑Proxy, Dockmaster  
- **Free tier + paid:** Context7 (free personal/edu), Tavily (monthly credits), Firecrawl (starter credits), Sourcegraph (free public; paid private/org), Semgrep (Community free; Teams paid), Snyk (free tier; paid), Composio/Rube (free calls; paid tiers)

---

## For later

### Snyk – vuln/SCA/IaC/container scans
**Why:** agent‑triggerable scanning with actionable results in chat; pairs well with Semgrep for broader coverage.

**Install & run:** Use Snyk’s MCP (standalone or via CLI integration), then `gemini mcp add snyk <server_cmd>`; set `SNYK_TOKEN`.  
**Cost:** Free tier; paid org features.

**Try:** “Scan `packages/*` and open issues for critical vulns with suggested upgrades.”

### Composio / Rube – glue to your work apps
**Why:** one server exposes **hundreds of app actions** (GitHub/Jira/Linear/Slack/Notion…). Turn `/speckit.tasks` into real tickets, update docs, post diffs to Slack — **no bespoke glue code**.

**Install & run:** `gemini mcp add rube npx -- @composiohq/rube` then auth the apps in their UI.  
**Cost:** Generous free plan (tool‑call quota); paid tiers for volume.

**Try:** “Create three Jira tickets from the task list; link the GH PR and post the plan in Slack #backend.”

### MCP managers (quality‑of‑life)

**mcp‑get** – one‑command installer: `brew install mcp-get` → `mcp-get install <server>`.  
**MCP‑Proxy** – bridge stdio ↔ SSE, isolate/rate‑limit servers; great for aggregating many servers behind one endpoint.  
**Dockmaster** – desktop GUI to discover/install/configure servers across clients.

All are free / open source.

---

## Verify & manage

- **Gemini CLI:** run `/mcp` to see active servers/tools.  
- **Codex CLI:** run `/mcp` inside the TUI; edit `~/.codex/config.toml` for finer control.  
- **Claude Code:** run `/mcp` to list; supports `.mcp.json` (project), user & enterprise‑managed configs; transports: **http**, **sse**, **stdio**.

> **Security tip:** Prefer least‑privilege (path allow‑lists, read‑only where possible). For remote HTTP/SSE servers, review auth scopes and rotate tokens regularly.
