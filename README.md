# Bureau

> *Endowing agents with the intelligence to **leverage versatile custom tools** and **orchestrate each other, autonomously.***
> 
> *Supports Gemini CLI, Claude Code, Codex and OpenCode.*

> [!IMPORTANT]
> ### Shortcuts to key resources
>
> - [**Setup guide *(5 minutes)***](docs/SETUP.md)
> - [**Usage guide**](docs/USAGE.md)
> - [**Configuration**](docs/CONFIGURATION.md)

## Purpose

Agentic coding CLIs, such as Claude Code, Gemini CLI, and Codex, are fragmented: each have unique strengths but incompatible tooling. 

- Power users rotating between these (as is often the best option, given providers' unpredictable model throttling and capricious rate limit changes, even for paid plans) **lose time rebuilding and reconfiguring context, tools, and custom workflows**. 
- Meanwhile, many agentic orchestration frameworks intending to help solve this problem:
  
    - have **considerable learning curves** 
    - enforce **opinionated orchestration patterns** (e.g. graphs, crews, pipelines)
    
    rather than adapting to users' ad-hoc workflows or permitting open-ended exploration/building.

**<ins>Bureau solves that</ins>** by:

- **Providing a unified, cohesive set of MCP servers (+ extra plugins)** across all 3 platforms covering a wide range of daily task categories
- **Defining 66 specialized agent roles** once and making them:
    - usable everywhere
    - spawnable as ***cross-CLI* subagents**
- **Minimizing task delegation overhead** from minutes of setup to *<30 seconds*
- **Reducing the learning curve** to ***near-zero*** (while offering thorough customization for power users):

  - **Automated context injection** ensures agents *automatically and judiciously* use all functionality Bureau configures them to have access to
  - **Minimal explicit directions needed** from the user
  - **Sensible defaults** for quick setup 

## Feature list

### Consistent agent roles across 4 CLI platforms

- [66 specialized roles](agents/role-prompts/) (architect, debugger, etc.) configured for use in *all* supported CLIs
- Can choose a specific model per task (e.g. Claude for architecture, Gemini for broad code search)

### 2 ways of invoking agents

#### As <ins>subagents</ins> 

> *Isolated agents that use a **separate context** and return results **only***
    
| CLI | Subagent usage method |
| :--- | :--- |
| **Claude Code** & **OpenCode** <ins>only</ins> | Native/built-in subagent functionality |
| **All** CLIs, including ***cross-CLI* subagents** | PAL MCP's [`clink` tool](https://github.com/BeehiveInnovations/pal-mcp-server/blob/main/docs/tools/clink.md) |

#### As <ins>interactive main agents</ins>

> *For **direct use** in the **main conversation*** 

| CLI | Main agent activation method |
| :--- | :--- | 
| **Claude Code** | Activate at any time using **custom slash commands** set up by Bureau |
| **OpenCode** | Use built-in [primary agent functionality](https://opencode.ai/docs/agents/#primary-agents) |
| **Codex** & **Gemini CLI** | Use **custom role-specific launch wrappers** (e.g. `codex-debugger`, `gemini-architect`) set up by Bureau |

> [!TIP]
> See details on how to use these 2 agent invocation methods in the [*Usage patterns* section below](#usage-patterns). 

### Cohesive MCP server set

Handling essential tasks like:

- **Code search** 
    - *Sourcegraph* ➔ remote, public repos
    - *Serena* ➔ local projects
- **Web research** (*Brave*, *Tavily*, *Fetch*)
- **Retrieving API docs** (*Context7*)
- **Memory persistence**
    - *Qdrant* ➔ semantic memories
    - *Memory MCP* ➔ structural memories 
    - *claude-mem* ➔ automatic context storage/injection w/ progressive disclosure *(Claude Code only)*
- Security scanning (*Semgrep*)
- Browser automation (*Playwright*)

### Automatic config injection

> Enables *automatic* and *timely* use of the functionality listed above by all supported CLI agents.

All agents automatically read these files at startup:

- [`protocols/context/guides/handoff-guide.md`](protocols/context/guides/handoff-guide.md) → when to delegate to subagents + which model to use
- [`protocols/context/guides/tools-guide.md`](protocols/context/guides/tools-guide.md) → MCP tool selection guide

    - Serves as an entrypoint to documentation progressively disclosing each MCP servers' tool capabilities

Injected via these files (created in setup steps)

- `~/.claude/CLAUDE.md` (Claude Code)
- `~/.gemini/GEMINI.md` (Gemini CLI)
- `~/.codex/AGENTS.md` (Codex)

with each of the 3 files above generated from templates (for portability regardless of repo clone location).

> [!NOTE]
> 
> **Enabling/disabling CLI agents for use with Bureau**
>
> - Configure which CLIs to set up by overriding the `agents` list (in `directives.yml`) in your `local.yml`
> - See [docs/CONFIGURATION.md](docs/CONFIGURATION.md#agents) for details

## Usage patterns

### Spawning subagents

**Claude Code & OpenCode** *(via native subagents):*
```
"Have the architect subagent design this system"
"Use the debugger agent to investigate this stack trace"
"Spawn the security-compliance agent to audit these changes"
```

**Any CLI** *(via PAL MCP's `clink`):*
```
"clink with gemini architect to design API structure"
"clink with codex observability to analyze these metrics"
```

### Activating interactive main agents

#### Claude Code
  
Use Bureau-configured slash commands:

```bash
$ claude
# ... startup output ...
> /explainer
# explainer role activated, interactive conversation begins
```

#### Gemini CLI & Codex

> [!IMPORTANT] 
> **`~/.local/bin/` must be in your `$PATH`** to use the method.

Use Bureau-configured launch wrapper scripts:

```bash
# launch Gemini CLI w/ explainer role active
$ gemini-explainer

# launch Codex using GPT-5.2-Codex w/ architect role active
$ codex-architect --model gpt-5.2-codex
```
#### OpenCode

Use the built-in [primary agents mechanism](https://opencode.ai/docs/agents/#primary-agents): simply cycle through available agents using the `Tab` key.

> [!NOTE]
> Bureau-provided agents will be named/shown as `Bureau-Agents/<rolename>` in the OpenCode interface.

## Configuration

| File | Purpose | Tracked? |
| :--- | :--- | :--- |
| `charter.yml` | Fixed, rarely-changed system defaults | Yes |
| `directives.yml` | User-oriented, often-tweaked settings | Yes |
| **`local.yml`** | **Personal customizations/overrides** (gitignored) | **No** (gitignored) |

> [!IMPORTANT]
> Configuration loads based on the following hierarchy *(later config sources override earlier ones)*: \
> **`charter.yml` → `directives.yml` → `local.yml` → environment variables**

See [`docs/CONFIGURATION.md`](docs/CONFIGURATION.md) for full reference.

## Repo structure

```
bureau/
├── bin/            # CLI entry points (open-bureau, close-bureau, check-prereqs)
├── agents/         # Agent definitions and setup
├── protocols/      # Context/guidance files for agents
├── tools/          # MCP servers and their documentation
├── operations/     # Python modules (config loading, cleanup, etc.)
│
│   GITIGNORED:
├── .archives/      # Operational state (trash, cleanup timestamps)
└── .mcp-servers/   # Cloned MCP server repos (shared across Bureau worktrees)
```
