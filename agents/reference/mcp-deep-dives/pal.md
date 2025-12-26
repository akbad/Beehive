# PAL MCP: Deep Dive

## Critical Note

**`clink`-only setup** — This guide documents our usage of PAL MCP strictly via clink to bridge to external AI CLIs. PAL MCP is accessed by agent clients, and in this configuration we do not configure provider API keys in PAL; we rely solely on clink.

## Overview

CLI-to-CLI bridge enabling multi-model orchestration, sub-agent spawning, and context threading across different AI CLIs.

## Available Tools

### 1. `clink` - Cross-Model CLI Orchestration

**What it does:** Links current request to external AI CLI (Gemini, Codex, Claude) through PAL MCP

**Parameters:**
- `prompt` (required) - User request forwarded to CLI
- `cli_name` (optional; required if multiple CLIs are configured) - Which CLI to use: "claude" | "codex" | "gemini". Defaults to "gemini" if present, otherwise the first configured CLI.
- `role` (optional, default "default") - Role preset for selected CLI
- `continuation_id` (optional) - Thread ID for multi-turn conversations
- `absolute_file_paths` (optional) - Array of absolute file/folder paths (must be full absolute paths; do not shorten)
- `images` (optional) - Array of image paths or base64 blobs

**Available roles per CLI:**
- **claude**: codereviewer, default, planner
- **codex**: codereviewer, default, planner
- **gemini**: codereviewer, default, planner

**Returns:** Response from external CLI with context preserved

**Best for:** Cross-model orchestration, specialized tasks per model

**Rate limits:** None (depends on target CLI's limits)

**CRITICAL:** Always reuse last continuation_id to preserve conversation context

### 2. `listmodels` - Show Available Models

**What it does:** Lists configured AI model providers, names, aliases, capabilities

**Parameters:** None

**Returns:** Model providers, model names, aliases, capabilities

**Best for:** Understanding available models before using clink

**Rate limits:** None

### 3. `version` - Server Information

**What it does:** Shows server version, config, available tools

**Parameters:** None

**Returns:** Version info, configuration details, tool list

**Best for:** Debugging, verifying setup

**Rate limits:** None

## Tradeoffs

### Advantages
✅ **Multi-model orchestration** (use best model for each task)
✅ **Cross-CLI context** (continuation_id preserves full history)
✅ **Role-based delegation** (codereviewer, planner, etc.)
✅ **File/image context** (pass context to other CLIs)
✅ **Seamless handoff** (agent resumes with full context)

### Disadvantages
❌ **clink bridge required** (invoked from your agent CLI)
❌ **Requires PAL setup** (local server running)
❌ **Accessed via agent clients** (e.g., Claude Code, Gemini CLI)

## Common Pitfalls: When NOT to Use

### ❌ Single-Model Tasks
**Problem:** clink adds overhead for same-model operations
**Alternative:** Use current CLI directly

**Example:**
```
Bad:  clink to same CLI for simple task
Good: Handle directly in current CLI
```

### ❌ Not Reusing continuation_id
**Problem:** Loses conversation context across calls
**Alternative:** Always reuse last continuation_id

**Example:**
```
Bad:  clink without continuation_id (new conversation each time)
Good: clink(continuation_id: "last_id") → preserves full context
```

### ❌ Tasks Not Requiring Other Models
**Problem:** Unnecessary cross-CLI call
**Alternative:** Keep work in current CLI

**Example:**
```
Bad:  clink for task current model handles well
Good: Complete task in current CLI
```

### ❌ Using Without Role Specification
**Problem:** Misses specialized role capabilities
**Alternative:** Specify role for focused execution

**Example:**
```
Bad:  clink(cli_name: "codex") # Default role
Good: clink(cli_name: "codex", role: "codereviewer")
```

### ❌ Not Passing Relevant Context
**Problem:** Other CLI lacks necessary files/images
**Alternative:** Include files/images parameters

**Example:**
```
Bad:  clink without files for code review task
Good: clink(files: ["/path/to/code.js"], role: "codereviewer")
```

## When PAL MCP IS the Right Choice

✅ **Multi-model orchestration** needed
✅ **Specialized roles** per model (review, plan, implement)
✅ **Cross-CLI workflows** (research → plan → implement)
✅ **Model-specific strengths** (Gemini for X, Codex for Y)

**Decision rule:** "Does this task benefit from a different model/role?"

## Usage Patterns

**Basic clink call:**
```
clink(
  prompt: "Review this code for security issues",
  cli_name: "codex",
  role: "codereviewer",
  files: ["/path/to/auth.js"]
)
```

**Multi-turn conversation (CRITICAL):**
```
First call:
clink(
  prompt: "Plan refactoring for auth system",
  cli_name: "claude",
  role: "planner"
)
→ Returns: status: continuation_available with continuation_offer.continuation_id: "abc123"

Second call (REUSE continuation_id):
clink(
  prompt: "Now implement step 1 from the plan",
  cli_name: "codex",
  role: "default",
  continuation_id: "abc123"  # CRITICAL: Preserves context
)
```

**Role-specific delegation:**
```
Code review:
clink(cli_name: "codex", role: "codereviewer", files: [...])

Planning:
clink(cli_name: "claude", role: "planner", files: [...])

Implementation:
clink(cli_name: "gemini", role: "default", files: [...])
```

**With images:**
```
clink(
  prompt: "Analyze this diagram",
  cli_name: "gemini",
  images: ["/path/to/diagram.png"]
)
```

**Check available models:**
```
listmodels()
→ See all configured models, aliases, capabilities
```

## Multi-Model Workflow Example

**Research → Plan → Implement:**
```
Step 1 (Research):
clink(
  prompt: "Research best practices for microservices auth",
  cli_name: "claude",
  role: "default"
)
→ continuation_id: "id1"

Step 2 (Plan):
clink(
  prompt: "Create implementation plan based on research",
  cli_name: "claude",
  role: "planner",
  continuation_id: "id1"
)
→ continuation_id: "id2"

Step 3 (Implement):
clink(
  prompt: "Implement auth service from plan",
  cli_name: "codex",
  role: "default",
  continuation_id: "id2",
  files: ["/project/auth/"]
)
→ continuation_id: "id3"

Step 4 (Review):
clink(
  prompt: "Review implemented code for security",
  cli_name: "codex",
  role: "codereviewer",
  continuation_id: "id3",
  files: ["/project/auth/service.js"]
)
```

## Best Practices

**Always preserve context:**
- **CRITICAL:** Reuse continuation_id from previous calls
- Full conversation history preserved
- Files, findings, decisions carry forward

**Choose right model per task:**
- Claude: Planning, architecture, complex reasoning
- Codex: Code implementation, debugging
- Gemini: Visual analysis, broad tasks

**Use appropriate roles:**
- `codereviewer`: Security, quality, best practices
- `planner`: Architecture, migration, phased plans
- `default`: General implementation

**Pass necessary context:**
- Files: Absolute paths (don't shorten)
- Images: Paths or base64 blobs
- Prompt: Clear task description

**Workflow patterns:**
```
Research (Claude) → Plan (Claude/planner) →
Implement (Codex) → Review (Codex/codereviewer)
```

## Alternatives Summary

| Task | Instead of PAL/clink | Use This |
|------|---------------------|----------|
| Single-model task | clink | Current CLI directly |
| Same CLI, same role | clink | Direct execution |
| No multi-turn needed | clink | Single CLI call |

## Quick Reference

**Availability:** clink orchestration layer only
**Rate limits:** Depends on target CLI
**Best for:** Multi-model workflows, specialized roles
**Avoid for:** Single-model tasks, no role specialization needed

**CLIs available:** claude, codex, gemini
**Roles available:** codereviewer, default, planner (per CLI)

**CRITICAL:** Always reuse continuation_id for context preservation

**Typical workflow:**
1. Research (Claude) →
2. Plan (Claude/planner) →
3. Implement (Codex) →
4. Review (Codex/codereviewer)

**Links:**
- [Full decision guide](../../../tools/tools-decision-guide.md)
