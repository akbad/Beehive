# Agent-ready context/config files

## Role prompts

- **`clink-role-prompts/`**: contains role prompts to be used for clink

    - Body-only "delta" role prompts (no YAML)
    - 600–2,000 chars

- **`claude-subagents`**: contains Claude Code subagent files

    - Generated (using script) to contain:

        - YAML frontmatter
        - Body is the agent template in `clink-role-prompts/` for the same role

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

**Guide: when to delegate vs. when to ask the user for guidance**

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
> - `for-use/reference/compact-tool-list.md` – Tier 1 tool quick ref
> - `for-use/must-reads/style-guide.md` – Project coding standards
> - `for-use/must-reads/handoff-guidelines.md` – When to delegate
> 
> If you need detailed Semgrep usage, read:
> - `for-use/reference/mcps/semgrep.md` – Tier 3 deep dive
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
> - for-use/reference/compact-tool-list.md (tier 1: tool selection)
> - for-use/must-reads/handoff-guidelines.md (delegation rules)
> 
> When comparing web research tools, read:
> - for-use/reference/category/web-research.md (tier 2: Tavily vs Exa vs Fetch)
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

    - `web-research.md` - Tavily, Exa, Fetch, Brave (simple/medium tools)
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
