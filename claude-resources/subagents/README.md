# Claude subagent templates

This folder contains drop-in Claude Code subagent templates you can paste into `.claude/agents/`. 

## Usage notes

### General

- Choosing models:
    
    - Can specify model per-agent at the top of the Markdown file defining it
    - Use `model: inherit` if you want them to reuse your current session's model
    - Can also set a default for all subagents via env (`CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (or keep `inherit`)

- Put policy gates (allow/ask/deny) in your `.claude/settings.json`, for example:

    ```json
    {
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
    }
    ```
