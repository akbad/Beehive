# Agent templates (called `role prompts` by Zen MCP & its `clink` tool)

This directory contains template files defining useful subagents to use with agentic coding CLIs.

## Guides for spawning subagents

- [**Within Claude Code**](#claude-code)
- [**Within *any* agentic coding CLI (via `clink`)**](#any-agentic-coding-cli)

---

## Claude Code

> Link: [***Full Claude Code subagents guide***](https://docs.claude.com/en/docs/claude-code/sub-agents)
<p></p>

> These instructions are **Claude Code-specific**; look further down for general instructions to use subagents from *any* agentic coding CLI.

### Setting up subagents

- Simply paste these files into your `.claude/agents` directory
- List them within the Claude Code using the `/agents` command

### Using subagents
    
- Claude will **automatically use subagents** when appropriate
    
    - Proactively delegates tasks based on:

        - `description` fields in subagent files *(make specific and action-oriented for best results)*
        - Task description in the current prompt
        <p></p>
    
    > **To encourage more proactive subagent use**, add phrases like these to subagent file's **`description` field**:
    >
    > - `use PROACTIVELY`
    > - `MUST BE USED`

- Can **invoke subagents explicitly:**

    ```
    Use the code-reviewer subagent to check my recent changes
    ```

    - Can also **chain subagents together** for complex workflows:

        ```
        First use the perf-engineer subagent to find performance issues, then use the perf-optimizer subagent to fix them
        ```

### Details

- Options for specifying models:
    
    - Can specify model per-agent at the top of the Markdown file defining it

        - Use `model: inherit` if you want them to reuse your current session's model

    - Can also set a default for all subagents via `CLAUDE_CODE_SUBAGENT_MODEL` env var (e.g. `CLAUDE_CODE_SUBAGENT_MODEL=sonnet`)

- Put policy gates (allow/ask/deny) in your `.claude/settings.json`, for example:

    ```json
    "permissions": {
        "allow": [
        "Bash(git diff:*)",
        "Bash(npm run test:*)", "Bash(pytest:*)", "Bash(go test:*)"
        ],
        "ask": [ "Bash(git push:*)" ],
        "deny": [
        "Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)"
        ]
    },
    "enableAllProjectMcpServers": true
    ```

## *Any* agentic coding CLI

- The Markdown files in this directory are really just prompt payloads with a little front-matter metadata.
- They can thus easily be reused with Gemini or Codex (or any other agentic coding CLI) by feeding the prompt to each CLI when you spawn it, either:
     
    - **using `clink` (workflow discussed below)** 
    - manually (by linking to the agent template files when writing prompts to the CLIs; not shown here).

### Workflow using `clink`

> Make sure you have the Zen MCP installed and running.

Using the [`backend-architect`](from-cc-templates/backend-architect.md) role as an example:

1. Separate and save each of the role prompts for reuse:

    - Extract the body (i.e. from *"You are..."* onwards) as the main role prompt
    - Save it in `~/.zen/prompts/` as a plaintext or Markdown file *(e.g.`~/.zen/prompts/backend-architect.md`)*

2. Add it as a role to each CLI's Zen config file's `roles`:

    - **Codex CLI:**

        ```json
        // ~/.zen/cli_clients/codex.json

        "roles": {
            // our new entry
            "backend-architect": {
                "prompt_path": "~/.zen/prompts/backend-architect.md",
                "role_args": ["--model", "gpt-5-codex"]
            }

            // ...
        }
        ```
    
    - **Gemini CLI:**
        ```json
        // ~/.zen/cli_clients/gemini.json

        "roles": {
            // our new entry
            "backend-architect": {
                "prompt_path": "~/.zen/prompts/backend-architect.md",
                "role_args": ["--model", "gemini-2.5-pro"]
            }

            // ...
        }
        ```

    - *Similar for Claude Code and other CLIs*

3. Restart the Zen/`clink` process so that it picks up the updated config from step 2; now, any of the roles from step 2 can be launched using `clink`.

4. **Key functionality**: launch the roles *as subagents* from ***within** a running Codex/Gemini CLI instance*:

    > Example prompt: `Use clink with cli_name="codex" role="backend-architect" prompt="Draft a scalable and maintainable architecture for the payment processing microservice."`
    > 
    > This will spawn a subagent instance of codex (with its system prompt set to be the contents of `backend-architect.md`) that will perform the desired task and return the results to the original conversation in the agent that it was launched from.
