# Agent-ready context/config files

## Role prompts

- **`role-prompts/`**: contains role prompts to be used for clink and OpenCode subagents

    - Body-only "delta" role prompts (no YAML)
    - 600–2,000 chars

- **`claude-subagents`**: contains Claude Code subagent files

    - Generated (using script) to contain:

        - YAML frontmatter
        - Body is the agent template in `role-prompts/` for the same role

    - 1,200-5,000 chars

### General role prompt pattern

- **Role and scope**: 2-3 bullets about what this agent does + boundaries
- **When to invoke checklist**: 3-6 triggers that should activate this role
- **Approach/workflow**: 3-6 bullets
- **Must-read files**: 4-5 max, see below
- **Output format**: deliverable structure
- **Constraints**: 3-6 bullets containing guardrails + handoff conditions

## Linked files (in `reference/`)

### Must-read (all roles)

#### MCP quick decision tree (`compact-mcp-list.md`)

- 1,000-1,500 chars (~330 tokens)
- Fast decision tree for MCPs available by use case (code search, web research, memory, etc.)
- Tool selection hierarchy by category (code search, web research, memory, etc.)

    - Provides first-choice tool per category, with limits

- "Tier 1" document

    - Links to per-category MCP decision guides ("tier 2") and per-MCP reference docs ("tier 3")

#### Handoff guidelines (`handoff-guidelines.md`): 

**Guide for agents: when to delegate vs. when to ask the user for guidance**

    - When to use clink to spawn another CLI (cross-model orchestration)

        - This section will include a quick guide to model selection for each `clink` role prompt

    - When to use Task tool to spawn Claude Code subagents
    - When to stop and ask user (AskUserQuestion scenarios)
    - When to hand off between agents (e.g., research → planning → implementation)
    - What requires explicit approval (commits, deployments, deletions)
    - Decision matrix: `"If X, then delegate to Y agent with Z role"`

> ### Integrating must-read files within role prompts
> 
> Reference must‑read files in role prompts *without* including their content.
> 
> #### Claude Code subagent frontmatter example:
> 
> ```markdown
> ---
> name: code-reviewer
> description: Reviews code for quality, security, maintainability
> tools: Read, Grep, Glob, Bash, mcp__semgrep
> model: sonnet
> ---
> 
> You are a senior code reviewer. Before starting, read these files:
> - `agents/reference/compact-tool-list.md` – Tier 1 tool quick ref
> - `agents/must-reads/style-guide.md` – Project coding standards
> - `agents/must-reads/handoff-guidelines.md` – When to delegate
> 
> If you need detailed Semgrep usage, read:
> - `agents/reference/tools/semgrep.md` – Tier 3 deep dive
> 
> [Rest of role prompt body...]
> ```
> 
> #### `clink` role prompt example:
> 
> ```markdown
> You are a research synthesis specialist.
> 
> At startup, read:
> - agents/reference/compact-tool-list.md (tier 1: tool selection)
> - agents/must-reads/handoff-guidelines.md (delegation rules)
> 
> When comparing web research tools, read:
> - agents/reference/category/web-research.md (tier 2: Tavily vs Brave vs Fetch)
> 
> [Rest of role prompt body...]
> ```

### Must-read (for certain roles only)

- **Style guides** (in `style-guides/`):
    
    - Code-specific: `code-style-guide.md` *(unused for now, rely instead on guides provided by repos themselves)*
    - Docs-specific: `docs-style-guide.md`

### Read as needed (progressive disclosure)

#### Per-category decision guides (read when exploring options)

- **Location**: `reference/category/*.md`

- **Size**: 3,500-5,000 characters each

- **Categories**:

    - `web-research.md` - Tavily, Brave, Fetch (simple/medium tools)
    - `code-search.md` - Serena, Grep patterns (simple tools)
    - `memory.md` - Qdrant, Memory MCP, claude-mem (simple/medium tools)
    - `documentation.md` - Context7 (simple tool)

- **Content (for each category)**:
    
    - Side-by-side comparison table (tool vs strengths vs use cases)
    - 2-3 examples per tool
    - Common parameters and patterns
    - When to escalate to tier 3 complex tools

- **Read when**: 
    
    - Need to compare alternatives within a category
    - Learning basic usage
    - "Tier 2"

### Per-MCP deep dives (read on-demand for complex tools)

- **Location**: `reference/mcp-deep-dives/*.md` (planned)
- **Size**: 4,000-6,000 characters each
- **Content per MCP**:

    - Detailed tool-by-tool breakdown
    - Advanced usage patterns and examples
    - Parameter reference tables
    - Common pitfalls and gotchas

- **Read when**: deep understanding of an MCP being used is required ("tier 3")

> ### Benefits of progressive disclosure for tool docs
>
> | Benefit | Description |
> | :------ | :---------- |
> | Low startup cost | Tier 1 only costs ~330 tokens (every agent) |
> | Progressive disclosure | Agents drill down only when needed |
> | Comparison enabled | Tier 2 shows trade-offs between related tools in the same category |
> | Depth available | Tier 3 provides comprehensive guidance for complex tools |
> | Maintenance decoupled | Update complex tool docs without touching simple ones |
> | Token efficient | Most tasks complete with tier 1 + tier 2 (~1,200-1,500 tokens total) |

## Using with PAL's `clink`

This repo's role bodies in `agents/role-prompts/` can be used as clink roles across any project. clink loads CLI client configs and role prompt files at startup.

- Prereqs
    - Run PAL MCP with clink enabled (for example via this repo's setup script). Uses stdio transport.
    - Create user‑level CLI client configs under `~/.pal/cli_clients/*.json` (or point `CLI_CLIENTS_CONFIG_PATH` to your configs).

- Config search precedence
    - Repo built‑ins: `conf/cli_clients`
    - `CLI_CLIENTS_CONFIG_PATH` (directory or single JSON)
    - User overrides: `~/.pal/cli_clients`

- Map roles to these prompt files
    - Option A (absolute paths): point `prompt_path` at files in `agents/role-prompts/`.
    - Option B (symlink + relative): symlink this folder under `~/.pal/cli_clients/systemprompts/` and use a relative `prompt_path`.

Example (`~/.pal/cli_clients/gemini.json`):

```json
{
  "name": "gemini",
  "command": "gemini",
  "additional_args": ["--yolo", "-o", "json"],
  "env": {},
  "roles": {
    "frontend": {
      "prompt_path": "/path/to/beehive/agents/role-prompts/frontend.md"
    },
    "testing": {
      "prompt_path": "/path/to/beehive/agents/role-prompts/testing.md"
    }
  }
}
```

Or using a symlinked layout:

```bash
mkdir -p ~/.pal/cli_clients/systemprompts/clink
ln -s "$PWD/beehive/agents/role-prompts" \
      ~/.pal/cli_clients/systemprompts/clink/for-use-prompts
```

```json
{
    "name": "codex",
    "command": "codex",
    "additional_args": ["--json", "--dangerously-bypass-approvals-and-sandbox"],
    "roles": {
        "architecture_audit": {
            "prompt_path": "systemprompts/clink/for-use-prompts/architecture-audit.md"
        }
    }
}
```

- Prompt resolution rules
    - Relative `prompt_path` resolves relative to the JSON's directory, then falls back to the PAL project root.
    - Absolute paths are used as‑is.
    - Role names are per‑CLI. If duplicate CLI `name` definitions exist across search paths, later ones override earlier.

- Verify and use
    - Restart the PAL server to reload configs.
    - Invoke from your agent: `clink with gemini role=frontend to assess UI components in src/ui/`.
    - You can pass file paths as context, for example: `clink with codex role=architecture_audit on src/, services/auth/`.
    - If only one CLI is configured, clink can default to it and allow omitting `cli_name`.
    - Troubleshoot: bad paths raise "Prompt file not found: …". Check PAL server logs for details.
    - The clink tool schema enumerates available `cli_name` and `role` values—use it to confirm your roles are loaded.
    - The example JSONs include permissive flags (for example, Codex `--dangerously-bypass-approvals-and-sandbox`). Remove or adjust them for stricter guardrails.

Tip: Keep role bodies short and reference Tier‑1/2/3 docs from `agents/reference/` in the prompt text (don’t inline).

## Using with Claude Code subagents

This repo’s subagent files in `agents/claude-subagents/` are ready to install.

- Where they live (precedence)
    - Project: `.claude/agents/` (overrides user for same `name`)
    - User: `~/.claude/agents/` (available everywhere)

- Install (copy or symlink)

```bash
mkdir -p ~/.claude/agents
ln -s "$PWD/beehive/agents/claude-subagents/frontend.md" ~/.claude/agents/frontend.md
ln -s "$PWD/beehive/agents/claude-subagents/testing.md" ~/.claude/agents/testing.md
```

- Minimal, correct frontmatter (already included):

```markdown
---
name: frontend
description: Use for frontend implementation reviews and UI architecture decisions; prefer concrete, file:line guidance and least‑invasive fixes.
tools: Read, Grep, Glob, Bash
model: inherit
---
```

- Make delegation proactive
    - Write specific triggers in `description` (for example, “Use after UI code changes; review only the diff.”).
    - Grant only the tools the role needs (omit `tools` to inherit all; include to restrict).
    - Prefer `model: inherit`; set default via `CLAUDE_CODE_SUBAGENT_MODEL` if desired.
    - Name must be unique, lowercase, hyphenated (for example, `architecture-agent`).

- Verify and use
    - Run `/agents` in Claude to confirm the subagents appear.
    - Use natural prompts and let Claude auto‑delegate, or explicitly invoke a subagent by name.
    - You can define session‑only subagents via CLI:

```bash
claude --agents '{
    "code-reviewer": {
        "description": "Expert code reviewer. Use proactively after code changes.",
        "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
        "tools": ["Read", "Grep", "Glob", "Bash"],
        "model": "sonnet"
    }
}'
```

Note: Role bodies should reference `agents/reference/compact-mcp-list.md` (Tier 1) and any relevant Tier‑2/3 guides. We'll add `agents/handoff-guidelines.md` next and reference it as a must‑read for delegation rules.

## Using with OpenCode subagents

This repo's role prompts in `agents/role-prompts/` are automatically configured as OpenCode subagents by the setup script.

- Where they live
    - Role prompts are symlinked to `~/.config/opencode/agent/bees/`
    - Agents are registered in `~/.config/opencode/opencode.json` under the `agent` key with `mode: "subagent"`

- Install (via setup script)

```bash
agents/scripts/set-up-agents.sh
```

The setup script:
1. Creates symlinks from `agents/role-prompts/*.md` to `~/.config/opencode/agent/bees/`
2. Registers each agent in `opencode.json` with `mode: "all"`

- Verify and use
    - Press **Tab** in OpenCode to cycle through available agents — Beehive agents should appear
    - Use natural prompts and let OpenCode auto-delegate, or explicitly mention a subagent by name
    - Example: `Have the debugger agent investigate this stack trace`
