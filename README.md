# Beehive

Versatile tools across Gemini CLI, Claude Code, Codex and OpenCode, with the intelligence to leverage & orchestrate them autonomously.

> [!IMPORTANT]
> ### Shortcuts to key resources
> 
> - [**Quick setup guide**](QUICKSTART.md)
> - [**Full setup guide**](SETUP.md)
> - [**Usage guide**](USAGE.md)

## Purpose

Agentic coding CLIs, such as Claude Code, Gemini CLI, and Codex, are fragmented: each have unique strengths but incompatible tooling. 

Power users rotating between these (as is often the best option, given providers' unpredictable model throttling and capricious rate limit changes, even for paid plans) **lose time rebuilding and reconfiguring context, tools, and custom workflows**. At the same time, **many (solo- or multi-agent) orchestration frameworks have considerable learning curves and enforce opinionated orchestration patterns** (e.g. graphs, crews, pipelines), rather than adapting to users' ad-hoc workflows or permitting open-ended exploration/building.

**This repo solves that** by:

- **Providing a unified, consistent set of 13 MCP servers (+ extra plugins)** across all 3 platforms (Sourcegraph, Semgrep, Brave, Tavily, Context7, etc.)
- **Defining 39 specialized agent roles** once, usable everywhere (debugger, architect, security-compliance, etc.) and spawnable as *cross-CLI subagents*
- **Minimizing task delegation overhead** from ~5 minutes of setup to <30 seconds
- **Reducing the learning curve to <ins>near-zero</ins>** 

  - **Automated context injection** ensures agents *automatically and judiciously* use all functionality made available by this repo
  - **Minimal explicit directions needed** from the user

## Feature list

### Consistent agent roles across 4 CLI platforms

- 39 specialized roles (architect, debugger, etc.)
- Same role definitions work everywhere via shared prompt sources
- Choose model per task (e.g. Claude for architecture, Gemini for broad code search)

### 2 ways of invoking agents

- As **subagents** (what you're probably more used to): spawn isolated tasks with separate context, get only the results back

    - Done using both:
        
        1. Claude Code and OpenCode's built-in subagents features
        2. PAL's `clink` (for Codex and Gemini CLIs, as well as cross-model/-CLI collaboration)

- **Direct** use and interaction **in main/current conversation** (using custom-generated wrappers/commands): 
    
    - **Codex, Gemini CLIs:** launch CLI with chosen agent active in main conversation (using automatically-configured wrappers like `codex-debugger` and `gemini-architect`)
    - **Claude Code:** automatically activate any agent in the current conversation using slash commands (that are automatically set up by Beehive)
    - **OpenCode:** use any Beehive agent as a [primary agent](https://opencode.ai/docs/agents/#primary-agents)

### 13 MCP servers

Including:

- Code search (Sourcegraph, Serena)
- Web research (Brave, Tavily, Fetch)
- API documentation (Context7)
- Memory/persistence (Qdrant, claude-mem)
- Security scanning (Semgrep)
- Browser automation (Playwright)

### Automatic config injection

> Meant to enable *automatic* use of features listed above by the CLIs (even when not using any particular agent).

All agents automatically read these files at startup:

- [`agents/reference/handoff-guidelines.md`](agents/reference/handoff-guidelines.md) → when to delegate to subagents + which model to use
- [`agents/reference/compact-mcp-list.md`](agents/reference/compact-mcp-list.md) → MCP tool selection guide

    - Serves as an entrypoint to documentation progressively disclosing each MCP servers' tool capabilities

Injected via these files (created in setup steps)

- `~/.claude/CLAUDE.md` (Claude Code)
- `~/.gemini/GEMINI.md` (Gemini CLI)
- `~/.codex/AGENTS.md` (Codex)

with each of the 3 files above generated from templates (for portability regardless of repo clone location).

> [!NOTE]
> **CLI agent selection**
>
> - Configure which CLIs to set up via the `agents` list in `queen.yml` (or `local.yml` for personal overrides)
> - See [SETUP.md](SETUP.md#selecting-cli-agents-to-configure) or [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for details

## Usage patterns

### Subagents (for isolated execution)

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

### Direct use in the main conversation

**Claude Code** (via slash commands)

```bash
claude
> /explainer
# begin interactive conversation helping you understand the repo you spawned it in
```

**Gemini/Codex** (via wrapper scripts)

```bash
gemini-explainer                        # use explainer role w/ Gemini CLI
codex-architect --model gpt-5-codex     # architect role w/ GPT-5-Codex via Codex
```

**OpenCode** (via the [primary agents mechanism](https://opencode.ai/docs/agents/#primary-agents))

You can cycle through available agents simply using the Tab key.

## Repo structure

```
agents/
├── role-prompts/          # Agent role prompts for both PAL's clink and OpenCode
├── claude-subagents/      # Same role prompts as above, except with Claude Code-specific YAML frontmatter
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

## Configuration

Beehive uses a YAML-based configuration system with team defaults and personal overrides:

| File | Purpose | Committed? |
|:-----|:--------|:-----------|
| `comb.yml` | Fixed system defaults (endpoints, package paths) | Yes |
| `queen.yml` | Team settings (agents, retention periods, ports, paths) | Yes |
| `local.yml` | Personal overrides | No (gitignored) |

Configuration loads in order: `comb.yml` → `queen.yml` → `local.yml` → environment variables.

See [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for full reference.
