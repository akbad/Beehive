# Bureau

> *Endowing agents with the intelligence to **leverage versatile custom tools** and **orchestrate each other, autonomously.***
> 
> *Supports Gemini CLI, Claude Code, Codex and OpenCode.*

> [!IMPORTANT]
> ### Shortcuts to key resources
>
> - [**Setup guide**](docs/SETUP.md)
> - [**Usage guide**](docs/USAGE.md)
> - [**Configuration reference**](docs/CONFIGURATION.md)

## What Bureau provides

- A unified, cohesive set of MCP servers and plugins
- 66 specialized agent roles that are:
    
    - spawnable as **cross-CLI subagents** with *minimal* task delegation overhead
    - usable in *every* supported CLI as both: 
        
        - **isolated subagents** 
        - **interactive main agents**

- A **<ins>*near-zero* learning curve</ins>** via:
  
  1. **context injection** that ensures:

     - **agents *automatically and judiciously* use all functionality** Bureau configures them to have access to
     - *minimal/no* explicit directions are needed from the user
  
  2. sensible default settings for quick setup, accompanied by **extensive configuration options** for power users

- **<ins>Setup that takes *minutes*</ins>**, including **automated installation & configuration** of all the functionality above for each supported CLI

### Why?

Agentic coding CLIs, such as Claude Code, Gemini CLI, and Codex, are fragmented: each have unique strengths but incompatible tooling. 

Further, users often rotate between CLIs due to:
    
- their corresponding models being better suited for particular development tasks, workflows and/or styles
- new features and model releases 
- providers' capricious and scarcely-communicated model throttling and rate limit shifts

But **rotating often means losing time rebuilding and reconfiguring context, tools, and custom workflows**. 

Meanwhile, many agentic orchestration frameworks intending to help solve this problem have:

- **considerable learning curves**
- **opinionated workflows/patterns *pushed*** upon users
    
rather than adapting to users' ad-hoc workflows, permitting open-ended exploration/building, or **simply getting out of the way**.

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
> See details for these 2 invocation methods in the [*agent role usage patterns* section below](#agent-role-usage-patterns). 

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

- Guidance on automatically activating [skills](https://github.com/obra/superpowers/tree/main/skills) highly relevant and useful for key dev workflows/tasks *(provided by the [Superpowers plugin](https://github.com/obra/superpowers), currently **only for Claude Code or Codex**)*

Injected via these files (created in setup steps)

- `~/.claude/CLAUDE.md` (Claude Code)
- `~/.gemini/GEMINI.md` (Gemini CLI)
- `~/.codex/AGENTS.md` (Codex)

with each of the 3 files above generated from templates (for portability regardless of repo clone location).

### Spec-driven development *(maintainer favourite)* 

> *This is provided by the [GitHub's open-source `spec-kit` CLI](https://github.com/github/spec-kit), which Bureau's setup scripting automatically installs via `uv tool install` for global availability.*

**Significantly reduces agents' mistakes, bugs and unintended implementation omissions** by providing an intuitive, painless workflow *driven by intra-CLI commands* where agents: 
    
- write a comprehensive spec for intended changes, interactively asking questions as necessary,
- turn their specs into implementation plans, which are then turned into concrete tasklists
- implement in detail based on the docs above
- can seamlessly handle on-the-fly updates, accordingly synchronize/adjust specs, plans, tasks, etc. in a cascading fashion

> [!TIP]
> 
> To get started fast, **read [Bureau's 5-minute guide to `spec-kit`](docs/USAGE.md#using-github-speckit-cli)**.

## Agent role usage patterns

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
| `directives.yml` | Streamlined collection of user-oriented, often-tweaked settings | Yes |
| **`local.yml`** | **Personal customizations/overrides** (gitignored) | **No** (gitignored) |

Configuration loads based on the following hierarchy *(later config sources override earlier ones)*: \
**`charter.yml` → `directives.yml` → `local.yml` → environment variables**

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
