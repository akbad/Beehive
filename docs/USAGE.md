# Usage guide

> [!IMPORTANT]
> This guide assumes the setup steps in [`SETUP.md`](SETUP.md) have been completed and doesn't restate information/guidance available there.

**<ins>Contents</ins>**
- [Overview](#overview)
  - [Features](#features)
  - [Repo-specific definitions](#repo-specific-definitions)
- [Using agents: quick guide](#using-agents-quick-guide)
  - [Managing CLI agent selection](#managing-cli-agent-selection)
  - [Direct use](#direct-use)
  - [As subagents](#as-subagents)
- [Tools available: overview](#tools-available-overview)
  - [MCP servers and plugins](#mcp-servers-and-plugins)
  - [Non-MCP CLI tools](#non-mcp-cli-tools)
- [Preserving context \& memories across sessions](#preserving-context--memories-across-sessions)
  - [Memory + Qdrant MCPs: main workflow for cross-CLI memory sharing](#memory--qdrant-mcps-main-workflow-for-cross-cli-memory-sharing)
- [Tool-specific guides](#tool-specific-guides)
  - [How the tools below integrate with the rest of the repo](#how-the-tools-below-integrate-with-the-rest-of-the-repo)
  - [Using Superpowers *(Claude Code/Codex only)*](#using-superpowers-claude-codecodex-only)
  - [Using `claude-mem` *(Claude Code only)*](#using-claude-mem-claude-code-only)
  - [Using GitHub SpecKit CLI](#using-github-speckit-cli)

---

## Overview

### Features

- Provides a **harmonized** ecosystem for developing using **any or all** of the following agentic coding CLIs, <ins>**together**</ins>:

    - **Claude Code**
    - **Codex**
    - **Gemini CLI**
    - **OpenCode**

- A **suite of specialized coding agent roles** with consistent behaviour on any platform, with **flexible ways of invoking them:**

    - **Direct use:** use an agent at any time in your current conversation *(Claude Code, OpenCode)* or launch instances of the CLI with the chosen agent *(Codex & Gemini CLIs)*
    - **As subagents:** delegate specific, isolated tasks to specialized agents that run in the background, <ins>automatically</ins> using [Zen MCP's `clink`](https://github.com/BeehiveInnovations/zen-mcp-server/blob/main/docs/tools/clink.md) to **enable cross-CLI subagent spawning & collaboration**

- A set of **open-source/free/freemium MCP servers** *(i.e. you won't pay a cent)* that make tasks (such as `git`, web browsing and static code analysis) **reliable and token-efficient**
- **Automatic setup scripts** for:
    
    - MCP server configuration
    - Agent role prompt installs
    - CLI configuration files for the 4 agentic coding CLIs
    - Config files for all 4 CLIs, ensuring **your CLIs automatically use the tools and agent roles set up in this repo** (and not only when explicitly prompted to)

> [!NOTE]
> #### CLI-specific restrictions
> 
> Some features are limited upstream to specific CLIs:
> 
> | Feature | Restricted to |
> | --- | --- |
> | [*claude-mem* plugin](https://github.com/thedotmack/claude-mem) | Claude Code |
> | [*Superpowers* plugin](https://github.com/obra/superpowers) | Claude Code, Codex (beta) |

### Repo-specific definitions

| Concept | Definition |
| :------ | :--------- |
| **Skill** | *Superpowers* workflow (e.g., `superpowers:test-driven-development`) + any extra Claude/Codex skills files you define |
| **Agent** |  Roles (e.g., `debugger`, `architect`) usable as agents, either [directly in your main chat](#direct-use) or [as **subagents**](#as-subagents) |
| **Subagent** | A child **agent**, isolated from the main chat, spawned to complete a particular task by *either* (1) Claude Code or OpenCode native subagents feature or (2) `clink` |
| **MCP** | MCP servers available for CLIs to use |

## Using agents: quick guide

>  [!TIP]
> **Role prompts** for agents/subagents can be found in the following directories.
> | Location | Used when? |
> | :--- | :--- |
> | [`agents/claude-subagents`](../agents/claude-subagents/) | (1) Spawning **subagents via Claude Code**'s first-party "subagents" feature or (2) spawning agents for **direct use in chat via slash commands** |
> | [`agents/role-prompts`](../agents/role-prompts/) | (1) Spawning **subagents via `clink`** (from *any* CLI, including Claude Code) or (2) spawning agents for **direct use in Codex/Gemini CLIs via wrapper scripts** or (3) spawning **OpenCode subagents** |
>
> - **Read through the files to see the full list of roles available for use.**
> - Prompts for the <ins>same role</ins> have the <ins>same body across both locations</ins> *(the `claude-subagents` files simply have some extra header YAML that makes them smoother to use with Claude Code)*

> [!TIP]
> Read [`handoff-guidelines.md`](../agents/reference/handoff-guidelines.md) to see the guidance that the CLIs will read at startup that will teach them:
> - when to delegate tasks to subagents
> - which CLIs/models to use for specific subagent tasks

### Managing CLI agent selection

Beehive configures CLIs based on the `agents` config setting:

```yaml
# queen.yml (or local.yml for personal overrides)
agents:
  - claude    # Claude Code
  - gemini    # Gemini CLI
  - codex     # Codex
  - opencode  # OpenCode
```

**Enable/disable a CLI:** Add or remove it from the `agents` list, then re-run `./bin/start-beehive`.

> [!NOTE]
> The CLI's config directory must exist for configuration to succeed (e.g., `~/.claude/` for Claude Code). See [CONFIGURATION.md](CONFIGURATION.md) for all configuration options.

There are 2 primary ways to use agents, depending on the CLI.

### Direct use

→ For using an agent <ins>interactively</ins> in the main/current chat.

#### Claude Code

Activate an agent <ins>within a Claude Code session</ins> using its **corresponding slash command** (injects the role prompt into the current conversation).

> <ins>Example</ins>: to load the [*Architect*](../agents/claude-subagents/architect.md) agent in Claude Code:
> ```bash
> $ claude
> > /architect
> # you are now interacting w/ the Architect agent  
> ```

#### Codex & Gemini CLIs

Launch the CLI using the **generated wrapper scripts**, named in the format **`<codex|gemini>-<rolename>`** (e.g. `gemini-architect`, `codex-debugger`)

> <ins>Example</ins>:
>
> - Starting Gemini CLI to interact with the [*Explainer*](../agents/role-prompts/explainer.md) agent in the main conversation:
>   ```bash
>   $ gemini-explainer
>   # Gemini CLI is now running w/ the Explainer agent active
>   # Ask it to clarify code and docs
>   ```
> - Starting Codex to interact with the [*Debugger*](../agents/role-prompts/debugger.md) agent in the main conversation:
>   ```bash
>   $ codex-debugger
>   # Codex is now running w/ the Debugger agent active
>   # Give it error logs or code snippets to analyze
>   ```

#### OpenCode

Use the [**primary agents mechanism**](https://opencode.ai/docs/agents/#primary-agents): press **Tab** to cycle through registered Beehive agents.

### As subagents

→ When you need to delegate a <ins>specific, isolated task</ins> without interrupting your main workflow or polluting your current chat's context. \
→ Subagents work in the background and report back their findings/results.

> [!IMPORTANT]
> You should **not** need to explicitly follow the steps below; after reading startup guidance, **agents will know when to spawn subagents <ins>automatically</ins>** (assuming you've set up the global config files).

#### Spawning subagents using any CLI, from any CLI (via `clink`)

For cross-CLI subagent spawning and collaboration, use Zen MCP's `clink` tool. It allows specifying:

- the agent role
- the CLI to use to spawn the agent
- the task prompt

> <ins>Example</ins>:
> ```bash
> # within any of Claude Code, Codex, Gemini CLI, or OpenCode
> > clink with gemini with architect role to map out how to
>   migrate from our monorepo to a microservices architecture

#### Within Claude Code & OpenCode (via native subagents)

> [!NOTE]
> This is for spawning subagents using the native subagent mechanisms of Claude Code and OpenCode.

Simply explicitly mention the subagent you want to use and it will automatically be invoked to handle the task.

> <ins>Example</ins>:
> ```bash
> # in Claude Code or OpenCode
> > Have the `code-reviewer` subagent review the changes
>   in `src/main.py` for best practices and potential bugs.

## Tools available: overview

> [!IMPORTANT]
> You should **not** need to explicitly use these tools most of the time; after reading the startup guidance provided by the config files, **agents will automatically select and use the appropriate MCP tools** based on the task.

### MCP servers and plugins

- **Code & security**:

    - **Sourcegraph**: For searching and navigating large, 
      public, open-source codebases.
    - **Serena**: For deep semantic code understanding, 
      analysis, and refactoring within your local codebase
      using LSPs.
    - **Semgrep**: For running fast, local static analysis and
      security scans with a vast library of rules.

- **Web research & documentation**:
    - **Tavily**: A comprehensive search API built for AI
      agents, capable of searching, crawling, and
      extracting web content.
    - **Brave**: A privacy-focused web search engine for
      general queries.
    - **Context7**: For fetching up-to-date, versioned
      documentation for a wide range of libraries and
      APIs.
    - **Fetch**: A simple, reliable tool for fetching the
      content of a single URL and converting it to
      Markdown.

- **Memory & knowledge**:
    - **Qdrant**: A vector database that provides agents with
      long-term semantic memory, allowing them to recall 
      concepts and context from past interactions.
    - **Memory**: A knowledge graph for storing structured 
      information as entities and relations, giving agents
      a persistent, queryable understanding of your 
      project.
    - **claude-mem *(Claude Code only)***: For automatic 
      context management and conversation memory.

- **Local dev tools**:
    - **Filesystem**: For efficient batch file
      operations (read_multiple_files only).

- **Orchestration**:
    - **Zen (`clink` tool only)**: enables cross-CLI collaboration/subagent spawning, [as discussed above](#spawning-subagents-using-any-cli-from-any-cli-via-clink)

> [!TIP]
> To learn more about the available MCPs and the specific guidance agents receive on how to use them, read:
>
> - [`compact-mcp-list.md`](../agents/reference/compact-mcp-list.md): quick decision guide for selecting the best tool for a given task.
> - [`mcp-deep-dives/`](../agents/reference/mcp-deep-dives/): 
> 
>     - Collection of in-depth guides for each MCP, detailing their capabilities and advanced usage patterns. Only read by agents when necessary to preserve context

### Non-MCP CLI tools

- **GitHub SpecKit:** for devising detailed specifications and subsequently using them to devise development plans and tasks *(your agents will never hallucinate or get distracted again)*

## Preserving context & memories across sessions

There are 2 methods for this:

| Method | Description |
| :--- | :--- |
| **Memory + Qdrant MCPs** | Allow creating and retrieving **semantic (Qdrant)** and **structural (Memory)** memories via <ins>manual</ins> tool calls |
| **`claude-mem` plugin *(Claude Code only, [covered in-depth here](#using-claude-mem-claude-code-only))*** | <ins>Automatically</ins> injects context into *only* Claude Code sessions, based on memories gathered *only* from previous Claude Code sessions |

### Memory + Qdrant MCPs: main workflow for cross-CLI memory sharing

> [!IMPORTANT]
> **It is extraordinarily helpful for Claude Code, Gemini CLI, Codex, and OpenCode to share memories** with one another to avoid repeating work (and, if using a less powerful model, to benefit automatically from analyses/memories saved from smarter models).

<ins>All</ins> CLIs should consistently and scrupulously:

- **Explicitly save discoveries/decisions** to Qdrant after reading code
- **Create session summaries** before ending work
- **Search for relevant memories when starting tasks** in order to benefit from past work/analysis

## Tool-specific guides

### How the tools below integrate with the rest of the repo

| Feature/tool/guide | What it defines/handles |
| :--- | :--- |
| **GitHub SpecKit** *(optional user-called CLI tool)* | **What** to build and **why** (i.e. top-down planning & specification) |
| ***Superpowers*-defined** (and other) **skills** | **How** to perform a task *(if defined for that task)*
| [**Handoff guidelines**](../agents/reference/handoff-guidelines.md) | **Who** performs each task *(i.e. when to delegate to subagents + recommended agent/model combos)* |
| [**Tool guidance**](../agents/reference/compact-mcp-list.md) | **Tools to use** for a task |

> [!NOTE]
> The [handoff guidelines](../agents/reference/handoff-guidelines.md) and [tool guidance](../agents/reference/compact-mcp-list.md) are part of the required files agents must read upon startup (as directed in the [config files set up by this repo](../configs/)).

#### Sample comprehensive workflow

1. Use `/speckit.specify` and `/speckit.tasks` to define feature and generate task list
2. Read `specs/<new-feature>/tasks.md` and delegate tasks to specialized agents via `clink`
3. Within each agent session:
    
    - [Tool guidance doc](../agents/reference/compact-mcp-list.md) ensures agents know appropriate tools to use for their task
    - [Handoff guidelines doc](../agents/reference/handoff-guidelines.md) teaches agents:
        
        - When to delegate *(i.e. recursively)*
        - The *right* agents to delegate subtasks to

    - *Superpowers* skills activate automatically (e.g., `test-driven-development`)

### Using Superpowers *(Claude Code/Codex only)*

#### What it is

A skills library that enforces mandatory workflows for common engineering tasks *(the following list is taken straight from the [Superpowers repo README](https://github.com/obra/superpowers/blob/main/README.md))*:

<ins>**Testing** (`skills/testing/`):</ins>
- **test-driven-development** - RED-GREEN-REFACTOR cycle
- **condition-based-waiting** - Async test patterns
- **testing-anti-patterns** - Common pitfalls to avoid

<ins>**Debugging** (`skills/debugging/`):</ins>
- **systematic-debugging** - 4-phase root cause process
- **root-cause-tracing** - Find the real problem
- **verification-before-completion** - Ensure it's actually fixed
- **defense-in-depth** - Multiple validation layers

<ins>**Collaboration** (`skills/collaboration/`):</ins>
- **brainstorming** - Socratic design refinement
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Batch execution with checkpoints
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **using-git-worktrees** - Parallel development branches
- **finishing-a-development-branch** - Merge/PR decision workflow
- **subagent-driven-development** - Fast iteration with quality gates

<ins>**Meta** (`skills/meta/`):</ins>
- **writing-skills** - Create new skills following best practices
- **sharing-skills** - Contribute skills back via branch and PR
- **testing-skills-with-subagents** - Validate skill quality
- **using-superpowers** - Introduction to the skills system

> [!NOTE]
> Workflows defined by the *Superpowers* plugin are **bottom-up**: it provides skills that enforce a specific *process* for building/fixing individual pieces of a codebase. 
> 
> In other words, it's less concerned with the overall feature spec; instead, it focuses more on the grassroots implementation quality.
>

#### How it integrates with this repo

| Feature/tool/guide | What it defines/handles |
| :--- | :--- |
| **GitHub SpecKit** *(optional user-called CLI tool)* | **What** to build and **why** (i.e. top-down planning & specification) |
| ***Superpowers*-defined** (and other) **skills** | **How** to perform a task *(if defined for that task)*
| [**Handoff guidelines**](../agents/reference/handoff-guidelines.md) | **Who** performs each task *(i.e. when to delegate to subagents + recommended agent/model combos)* |
| [**Tool guidance**](../agents/reference/compact-mcp-list.md) | **Tools to use** for a task |

> [!NOTE]
> The [handoff guidelines](../agents/reference/handoff-guidelines.md) and [tool guidance](../agents/reference/compact-mcp-list.md) are part of the required files agents must read upon startup (as directed in the [config files set up by this repo](../configs/)).

#### How skills activate 

1. **Automatically**

    Skills activate automatically when tasks match their descriptions: in the startup guidance agents read, they are ordered to check for applicable skills before starting any task.

2. **Manually**

    The following slash commands can be used in Claude Code *only*:

    | Command | What it does |
    | :--- | :--- |
    | **`/superpowers:brainstorm`** | Interactive design refinement using Socratic questioning |
    | **`/superpowers:write-plan`** | Create detailed implementation plan with bite-sized tasks |
    | **`/superpowers:execute-plan`** | Execute plan in batches with review checkpoints |

> [!NOTE]
> There is currently no way to *manually* activate skills in Codex (since slash commands don't exist in Codex). Instead, all skills activate automatically. 
> 
> You can check which skills are available to (be automatically loaded by) Codex by running:
> ```bash
> ~/.codex/superpowers/.codex/superpowers-codex find-skills
> ```

### Using `claude-mem` *(Claude Code only)*

#### What it is

- A **<ins>fully automatic</ins> context management plugin** that preserves conversation memory across Claude Code sessions **without manual intervention** 

    - *Adds extra convenience on top of the Memory + Qdrant MCP combination for Claude Code specifically*

- Unlike Qdrant/Memory MCPs which require explicit saving, claude-mem operates entirely through Claude Code's plugin hook system.

#### Automatic features

| Feature | Description |
| :--- | :--- |
| **Session summaries** | Every conversation is automatically summarized (request, completed, learned, next steps) |
| **Observation extraction** | Captures structured learnings after each tool use: decisions, bugfixes, features, refactors, discoveries
| **Full-text search** | All data indexed with FTS5 for fast retrieval across files, concepts, and sessions |
| **Auto-injected timeline of recent work w/ progressive disclosure** | At session start, shows layered timeline consisting of (1) Critical observations, (2) Decisions & architecture changes, and (3) Informational notes (with token costs of requesting further info included for each) |

> [!TIP]
> If `claude-mem` is properly set up, every time you start Claude Code, you should see output that looks like:
> ```bash
> $ claude
>   # ... Claude startup graphics ...
>  ⎿ SessionStart:startup says: Plugin hook error: 
>
>    📝 Claude-Mem Context Loaded
>       ℹ️  Note: This appears as stderr but is informational
>     only
>
>
>    📝 [beehive] recent context
>    ─────────────────────────────────────────────────────
>
>    Legend: 🎯 session-request | 🔴 gotcha | 🟡 
>    problem-solution | 🔵 how-it-works | 🟢 what-changed | 
>    🟣 discovery | 🟠 why-it-exists | 🟤 decision | ⚖️ 
>    trade-off
>    
>   💡 Progressive Disclosure: This index shows WHAT exists 
>   (titles) and retrieval COST (token counts).
>      → Use MCP search tools to fetch full observation 
>   details on-demand (Layer 2)
>      → Prefer searching observations over re-reading code 
>   for past decisions and learnings
>      → Critical types (🔴 gotcha, 🟤 decision, ⚖️ 
>   trade-off) often worth fetching immediately
>    # ... individual context entries will follow
> ```

#### Manual search (when needed)

While claude-mem works automatically, you can manually search its database using MCP tools:

| Search for... | Tool to use |
| :--- | :--- |
| Observations (decisions, bugs, features) | `search_observations` |
| Past session summaries | `search_sessions` |
| What the user originally asked | `search_user_prompts` |
| Work related to specific files | `find_by_file` |
| Observations by type (decision/bugfix/etc.) | `find_by_type` |
| Observations tagged with concepts | `find_by_concept` |

> [!IMPORTANT]
> **Always start searches with `format: "index"`** (50-100 tokens/result) to see what exists, then use `format: "full"` (500-1000 tokens/result) only for specific items of interest.

**Example use case:**
```
> Search claude-mem for past decisions about authentication
# Agent uses search_observations with format: "index", sees 3 relevant results
# Agent then fetches full details for the most relevant one
```

### Using GitHub SpecKit CLI

#### What it is

[GitHub SpecKit](https://github.github.io/spec-kit/) is an open-source toolkit for [**Spec-Driven Development (SDD)**](https://github.com/github/spec-kit/blob/main/spec-driven.md), which emphasizes creating extensive, exhaustive specifications that are then treated as executable roadmaps that drive implementation.

> [!NOTE]
> SpecKit is <ins>not</ins> an MCP tool; it's a simple CLI tool that uses available agentic coding CLIs. It's installed automatically by the [tool setup script](../tools/scripts/set-up-tools.sh); verify installation (and its connection to your various CLIs) by running `specify check`.

SpecKit creates this structure in your project:

```
my-project/
├── .specify/
│   └── memory/constitution.md    # Project principles
├── specs/
│   └── 001-feature/
│       ├── spec.md               # Requirements & user stories
│       ├── plan.md               # Technical plan
│       ├── tasks.md              # Task breakdown
│       ├── data-model.md         # Schemas
│       ├── api.md                # API contracts
│       └── component.md          # Architecture
└── checklists/
    └── requirements.md           # Validation gates
```

#### How to use SpecKit: overview

> [!TIP]
> Each of the commands below can optionally be followed with a prompt containing extra instructions (and this should be provided in most cases).

<ins>Setting up a new project</ins>

If a project constitution doesn't already exist in the repo at `**Run once per repo** to establish project's engineering foundations/principles to follow:

```bash
/speckit.constitution  
```

<ins>Main workflow</ins>

The tool is opinionated, splitting its provided commands to correspond to SDD's 4 phases:

1. **Specification phase:** turns requirements into detailed specifications
    - **`/speckit.specify`** to create specs, requirements, user stories

        - *File generated:* **`specs/<xxx>/spec.md`**
  
    -  **`/speckit.clarify`** to resolve underspecified requirements

2. **Planning phase:** turns architecture & constraints into a clear implementation plan

    - **`/speckit.plan`** to create technical implementation plan from spec

        - *Files generated:*
        
            | File | What it contains |
            | :--- | :--- |
            | **`plan.md`** | Technical approach & implementation strategy |
            | **`data-model.md`** | Database schemas & data structures |
            | **`api.md`** | API contracts & endpoint definitions |
            | **`component.md`** | Component architecture & dependencies |

    - **`/speckit.analyze`** to perform cross-artifact consistency checks

        > **What this command checks:**
        >     
        > - Technical plan actually implements all requirements from the spec
        > - Data model supports the architecture described in the plan
        > - API contracts match the data structures defined
        > - Tasks cover all implementation steps from the plan
        > - Completing all tasks will satisfy all acceptance criteria
        > <p></p>
        >
        > **Examples of when to run this command:**
        >
        > | Run after | What `analyze`  ensures |
        > | --- | --- |
        > | Updating requirements in `spec.md` | `plan.md` and `tasks.md` still align |
        > | Modifying data model in `data-model.md` | `api.md` and `component.md` are still consistent |
        > | Adding new user stories | That tasks cover all new requirements | 

3. **Task creation phase:** turns specification breakdown into concrete, reviewable tasks

    - **`/speckit.tasks`** to generate actionable task breakdown

        - *File generated:* **`tasks.md`**

    - **`/speckit.checklist`** to generate quality validation checklists

        - *File generated:* **`checklists/requirements.md`**

    <p></p>

    > After this phase, run **`/speckit.analyze` again** to ensure all generated tasks/checklists are consistent with the spec and other documents

4. **Implementation phase:** executes tasks sequentially and/or in parallel, with focused reviews

     - **`/speckit.implement`** (<ins>will modify code</ins>)

> [!TIP]
> For more info, read the [**GitHub SpecKit full guide**](https://github.com/github/spec-kit/blob/main/spec-driven.md).

#### When to use SpecKit

**Best for:**
- New features that need clear requirements documented
- Team projects where specs must be reviewed
- Complex features with multiple phases/subsystems
- When you need an audit trail allowing tracing up, i.e. from code → tasks → spec → requirements

**Skip for:**
- Trivially simple changes
- Quick bug fixes, experimental prototypes
- Small-scale tools/scripts where specs are overkill and would slow iteration
