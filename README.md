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

- **Built-in workflow skills** — structured, multi-step protocols (like [two-phase code assessment](protocols/context/static/skills/assess-mode/SKILL.md)) that agents activate automatically when they recognise a matching task

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

- [`protocols/context/static/handoff-guide.md`](protocols/context/static/handoff-guide.md) → when to delegate to subagents + which model to use
- [`protocols/context/static/tools-guide.md`](protocols/context/static/tools-guide.md) → MCP tool selection guide

    - Serves as an entrypoint to documentation progressively disclosing each MCP servers' tool capabilities

- **Custom Bureau skills**: structured workflow protocols (e.g. `bureau-assess-mode`) installed for all supported CLIs and activated automatically by matching prompts
- **[Superpowers](https://github.com/obra/superpowers) skills** — community-maintained skill library *(currently Claude Code and Codex only)*

Injected via these files

- `~/.claude/CLAUDE.md` (Claude Code)
- `~/.gemini/GEMINI.md` (Gemini CLI)
- `~/.codex/AGENTS.md` (Codex)

with each of the 3 files above generated from [templates](protocols/context/templates/) and symlinked (for portability).

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

### Workflow skills that actually help

> *Structured, multi-step protocols that agents activate automatically when they recognise a matching task.*

> [!NOTE]
> 
> All skill names below appear in agent interfaces prefixed with `bureau-` (e.g. `assess-mode` → `bureau-assess-mode`).

#### Skills installed by default

| Skill | What it does |
| :--- | :--- |
| **[Assess mode](protocols/context/static/skills/assess-mode/SKILL.md)** | **Two-phase guided review**: first builds a mental model of changes (with 3 comprehension styles to choose from), then audits every file against [configurable quality standards](docs/CONFIGURATION.md#assess_mode). Interactive tour when used as a main agent; structured report when delegated to a subagent. |
| **[Micro mode](protocols/context/static/skills/micro-mode/SKILL.md)** | **Step-gated editing with DAG-based planning:** offers maximum control over each atomic edit, with pause points after every change. |

#### Additional skills available in the catalog

The [`protocols/context/static/skills/`](protocols/context/static/skills/) directory ships several more skills that can be enabled on demand:

| Skill | What it does |
| :--- | :--- |
| [Scrimmage mode](protocols/context/static/skills/scrimmage-mode/SKILL.md) | Systematic self-attack testing after every code change: generates attack vectors across 5 categories (input validation, state, failure modes, concurrency, security) and blocks progression until vulnerabilities are fixed. |
| [Blast radius mode](protocols/context/static/skills/blast-radius-mode/SKILL.md) | Runs impact analysis before edits by enumerating callers, dependents, tests, and contracts affected, then classifying changes as *safe/needs review/breaking/blocked*. |
| [Clearance mode](protocols/context/static/skills/clearance-mode/SKILL.md) | Rigorous completion verification that defines measurable "done" criteria upfront and blocks clearance until they're satisfied, with evidence. |
| [Safeguard mode](protocols/context/static/skills/safeguard-mode/SKILL.md) | Defines system invariants (value constraints, state machines, relationships, ordering) that must never break and verifies them after all changes. |
| [Prompt engineering](protocols/context/static/skills/prompt-engineering/SKILL.md) | Guided prompt creation and refinement for system prompts, agent instructions, skill definitions, or any LLM-facing text. |
| [Shadow mode](protocols/context/static/skills/shadow-mode/SKILL.md) | Propose-only editing: the agent shows diffs without touching files, with the user applying changes manually. Ideal for learning, maximum transparency, or untrusted environments. |

To enable any of these, add them to the `skills.enabled` [config setting](docs/CONFIGURATION.md#skills):

```yaml
skills:
  enabled: [micro-mode, assess-mode, shadow-mode, scrimmage-mode]
```

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
├── bin/            # CLI entry points (open-bureau, close-bureau, ensure-prereqs)
├── agents/         # Agent definitions and setup
├── protocols/      # Context/guidance files for agents
├── tools/          # MCP servers and their documentation
├── operations/     # Python modules (config loading, cleanup, etc.)
│
│   GITIGNORED:
├── .archives/      # Operational state (trash, cleanup timestamps)
└── .mcp-servers/   # Cloned MCP server repos (shared across Bureau worktrees)
```
