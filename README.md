# Agent ecosystem

Unified agent infrastructure across Claude Code, Gemini CLI, and Codex CLI with shared tooling (MCPs) and role definitions.

> [!IMPORTANT]
>
> Quick links to key resources:
> - [**Setup guide**](SETUP.md)
> - [**Usage guide**](USAGE.md)

## Purpose

Agentic coding CLIs are fragmented: Claude Code, Gemini CLI, and Codex CLI each have unique strengths but incompatible tooling. 

Power users rotating between these (as is often the best option, given providers' unpredictable model throttling and capricious rate limit changes, even for paid plans) **lose time rebuilding and reconfiguring context, tools, and custom workflows**. At the same time, **many (solo- or multi-agent) orchestration frameworks have considerable learning curves and enforce opinionated orchestration patterns** (e.g. graphs, crews, pipelines), rather than adapting to users' ad-hoc workflows or permitting open-ended exploration/building.

**This repo solves that** by:

- **Providing a unified, consistent set of 14 MCP servers (+ extra plugins)** across all 3 platforms (Sourcegraph, Semgrep, Brave, Tavily, Context7, etc.)
- **Defining 39 specialized agent roles** once, usable everywhere (debugger, architect, security-compliance, etc.) and spawnable as <ins>*cross-CLI subagents*</ins>
- **Automating context injection** teaching agents when to delegate, which tools to use, and which model fits the task
- **Minimizing task delegation overhead** from ~5 minutes of setup to <30 seconds
- **Reducing the learning curve to <ins>near-zero</ins>**
    
    - Context injection teaches agents to automatically and judiciously use all functionality made available here, with minimal explicit directions needed from the user.

## Feature list

### Consistent agent roles across 3 CLI platforms

- 39 specialized roles (architect, frontend, security, observability, debugger, data-eng, etc.)
- Same role definitions work everywhere via shared prompt sources
- Choose model per task (e.g. Claude for architecture, Gemini for broad code search)

### 2 ways of invoking agents

- As **subagents** (what you're probably more used to): spawn isolated tasks with separate context, get only the results back

    - Done using both:
        
        1. Claude Code's built-in subagents feature
        2. Zen's `clink` (for Codex and Gemini CLIs, as well as cross-model/-CLI collaboration)

- **Direct** use and interaction **in main/current conversation** (using custom-generated wrappers/commands): 
    
    - **Codex, Gemini CLIs:** launch CLI with chosen agent active in main conversation
    - **Claude Code:** automatically activate any agent in the current conversation using slash commands

### 14 MCP servers 

Including: 

- Code search (Sourcegraph, Serena)
- Web research (Brave, Tavily, Firecrawl)
- API documentation (Context7)
- Memory/persistence (Qdrant, claude-mem)
- Security scanning (Semgrep)

### Automatic config injection

> Meant to enable *automatic* use of features listed above by the CLIs (even when not using any particular agent).

All agents automatically read these files at startup:

- [`agents/reference/handoff-guidelines.md`](agents/reference/handoff-guidelines.md) → when to delegate to subagents + which model to use
- [`agents/reference/compact-mcp-list.md`](agents/reference/compact-mcp-list.md) → MCP tool selection guide 
    
    - Serves as an entrypoint to documentation progressively disclosing each MCP servers' tool capabilities

Injected via these files (created in setup steps)

- `~/.claude/CLAUDE.md` (Claude Code)
- `~/.gemini/GEMINI.md` (Gemini CLI)
- `~/.codex/AGENTS.md` (Codex CLI)

with each of the 3 files above generated from templates (for portability regardless of repo clone location).

## Usage patterns

### Subagents (for isolated execution)

**Claude Code (Task tool):**
```
"Have the architect subagent design this system"
```

**Any CLI (Zen clink):**
```
"clink with gemini architect to design API structure"
"clink with codex observability to analyze these metrics"
```

### Direct use in the main conversation

**Claude Code** (via slash commands)

```bash
claude
> /explainer
# interactive conversation helping you understand the repo you spawned it in
```

**Gemini/Codex** (via wrapper scripts)

```bash
gemini-explainer                        # use explainer role w/ Gemini CLI
codex-architect --model gpt-5-codex     # architect role w/ GPT-5-Codex via Codex CLI
```

## Repo structure

```
agents/
├── claude-subagents/      # Claude Code Task tool definitions
├── clink-role-prompts/    # Zen clink role definitions (cross-CLI)
├── reference/             # MCP guides (injected via config files)
└── scripts/               # Setup automation

configs/
├── *.template             # Config templates with {{REPO_ROOT}} placeholders
└── scripts/               # Generates ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md, etc.

tools/
├── tools.md               # Complete MCP listing
├── tools-decision-guide.md
└── scripts/               # MCP installation automation
```
