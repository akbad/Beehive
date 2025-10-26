# Converting Agent CLI Subscriptions to API Endpoints

**Purpose**: This guide shows how to use [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) to expose your Gemini CLI, Claude Code, and Codex CLI agent subscriptions as OpenAI-compatible API endpoints. This enables tools like Aider to use your existing Claude Max, ChatGPT Pro, and Gemini subscriptions without requiring separate API keys.

**Author**: Generated via Claude Code
**Last Updated**: 2025-10-17

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Authentication Setup](#authentication-setup)
5. [Running the Proxy Server](#running-the-proxy-server)
6. [Configuring Aider](#configuring-aider)
7. [About Aider](#about-aider)
8. [Model Reference](#model-reference)
9. [Advanced Configuration](#advanced-configuration)
10. [Troubleshooting](#troubleshooting)
11. [Security Considerations](#security-considerations)

---

## Overview

### What is CLIProxyAPI?

CLIProxyAPI is a local proxy server that:
- **Exposes OpenAI-compatible API endpoints** (`/v1/chat/completions`, `/v1/messages`)
- **Authenticates using OAuth sessions** from your browser (same credentials as Gemini CLI, Claude Code, Codex CLI)
- **Routes requests automatically** based on model name prefixes (`claude-*`, `gemini-*`, `gpt-*`)
- **Load balances** across multiple accounts per provider
- **Supports streaming**, function calling, vision/multimodal inputs
- **Runs locally on port 8317** (configurable)

### Why Use This?

| Scenario | Solution |
|----------|----------|
| You have **Claude Max** subscription | Use `claude-*` models via proxy instead of paying for Anthropic API |
| You have **ChatGPT Pro** subscription | Use `gpt-*` models via proxy instead of paying for OpenAI API |
| You have **Gemini free tier** access | Use `gemini-*` models via proxy (free!) |
| You want to use **Aider** | Configure Aider to use the proxy endpoints |
| You want to use **multiple accounts** | Proxy automatically load-balances requests |

### Architecture

```
┌─────────────────┐
│  Aider / Tool   │
│  (API client)   │
└────────┬────────┘
         │ HTTP requests to localhost:8317
         │
┌────────▼────────────────────────────┐
│     CLIProxyAPI Proxy Server        │
│  • Manages OAuth tokens             │
│  • Routes by model name prefix      │
│  • Load balances across accounts    │
└─────┬─────────┬─────────┬───────────┘
      │         │         │
      │         │         │
┌─────▼─────┐ ┌▼────────┐ ┌▼──────────┐
│  Claude   │ │ Gemini  │ │  OpenAI   │
│  API      │ │ API     │ │  API      │
│  (OAuth)  │ │ (OAuth) │ │  (OAuth)  │
└───────────┘ └─────────┘ └───────────┘
```

---

## Prerequisites

### System Requirements
- **OS**: macOS, Linux, or Windows
- **Go**: Version 1.24 or higher (if building from source)
- **Memory**: ~50-100MB for proxy server
- **Ports**: 8317 (default server), plus OAuth callback ports:
  - Claude OAuth: 54545
  - Gemini OAuth: 8085
  - OpenAI OAuth: 1455

### Active Subscriptions
You'll need browser sessions authenticated to:
- **Claude.ai** (for Claude Code / Claude Max)
- **Google account** (for Gemini CLI / Gemini access)
- **ChatGPT** (for Codex CLI / ChatGPT Pro)

---

## Installation

### Option 1: Homebrew (Recommended for macOS/Linux)

```bash
brew install cliproxyapi
```

### Option 2: Build from Source

```bash
# Clone repository
git clone https://github.com/router-for-me/CLIProxyAPI.git
cd CLIProxyAPI

# Build
go build -o cli-proxy-api ./cmd/server

# Optional: Move to PATH
sudo mv cli-proxy-api /usr/local/bin/
```

### Verify Installation

```bash
cli-proxy-api --help
```

---

## Authentication Setup

### Overview

Each provider requires a **one-time OAuth authentication** that captures your browser session credentials. These are stored in `~/.cli-proxy-api/` as JSON token files.

### Claude (for Claude Code / Claude Max)

```bash
cli-proxy-api --claude-login
```

**What happens**:
1. Opens browser to Claude OAuth page (uses port 54545 for callback)
2. You authorize the app using your Claude.ai session
3. Saves token to `~/.cli-proxy-api/claude_*.json`

**Headless option**:
```bash
cli-proxy-api --claude-login --no-browser
# Prints login URL to copy/paste into browser
```

### Gemini (for Gemini CLI)

```bash
cli-proxy-api --login
```

**What happens**:
1. Opens browser to Google OAuth page (uses port 8085 for callback)
2. You authorize with your Google account
3. Saves token to `~/.cli-proxy-api/gemini_*.json`

**With project ID** (if needed):
```bash
cli-proxy-api --login --project_id your-gcp-project-id
```

### OpenAI (for Codex CLI / ChatGPT Pro)

```bash
cli-proxy-api --codex-login
```

**What happens**:
1. Opens browser to OpenAI OAuth page (uses port 1455 for callback)
2. You authorize using your ChatGPT session
3. Saves token to `~/.cli-proxy-api/openai_*.json`

### Multiple Accounts (Optional)

You can authenticate **multiple accounts per provider** for automatic load balancing:

```bash
# Add first Claude account
cli-proxy-api --claude-login

# Add second Claude account (from different browser profile or after switching accounts)
cli-proxy-api --claude-login

# Proxy will round-robin between accounts automatically
```

### Verify Authentication

```bash
ls ~/.cli-proxy-api/
# Should show: claude_*.json, gemini_*.json, openai_*.json
```

---

## Running the Proxy Server

### Basic Startup

```bash
cli-proxy-api
```

**Output**:
```
[INFO] Starting CLI Proxy API server on :8317
[INFO] Loaded 1 Claude account(s)
[INFO] Loaded 1 Gemini account(s)
[INFO] Loaded 1 OpenAI account(s)
[INFO] Server ready at http://localhost:8317
```

### Running as Background Service

**Using Homebrew (macOS/Linux)**:
```bash
brew services start cliproxyapi
brew services stop cliproxyapi
brew services restart cliproxyapi
```

**Using tmux**:
```bash
tmux new -s cliproxy
cli-proxy-api
# Ctrl+B, then D to detach
```

**Using screen**:
```bash
screen -S cliproxy
cli-proxy-api
# Ctrl+A, then D to detach
```

**Using nohup**:
```bash
nohup cli-proxy-api > /tmp/cliproxy.log 2>&1 &
echo $! > /tmp/cliproxy.pid
```

### Test the Server

```bash
# List available models
curl http://localhost:8317/v1/models

# Test chat completion
curl http://localhost:8317/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-2.5-pro",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

---

## Configuring Aider

### Method 1: Environment Variables (Recommended)

Create a shell script `~/.aider-with-proxy.sh`:

```bash
#!/bin/bash

# For Claude via proxy
export ANTHROPIC_API_KEY="dummy"
export ANTHROPIC_BASE_URL="http://localhost:8317/v1"

# For OpenAI via proxy
export OPENAI_API_KEY="dummy"
export OPENAI_BASE_URL="http://localhost:8317/v1"

# For Gemini via proxy (using OpenAI-compatible mode)
export GEMINI_API_KEY="dummy"

# Launch Aider
aider "$@"
```

Make executable and use:
```bash
chmod +x ~/.aider-with-proxy.sh
~/.aider-with-proxy.sh --model claude-opus-4-1-20250805
```

### Method 2: Aider Config File

Edit `~/.aider.conf.yml`:

```yaml
# Claude via proxy
anthropic-api-key: dummy
anthropic-api-base: http://localhost:8317/v1

# OpenAI via proxy
openai-api-key: dummy
openai-api-base: http://localhost:8317/v1

# Default model
model: claude-opus-4-1-20250805
```

Then run:
```bash
aider
```

### Method 3: Command Line Flags

```bash
aider \
  --anthropic-api-key dummy \
  --anthropic-api-base http://localhost:8317/v1 \
  --model claude-opus-4-1-20250805
```

### Verify Aider Connection

Start Aider and try a simple request:
```bash
aider --model gemini-2.5-pro
# In Aider prompt:
# > /help
# Should connect successfully via proxy
```

---

## About Aider

### What is Aider?

Aider is an **AI pair programming tool** that runs in your terminal and enables fast, lightweight coding workflows without the overhead of full agent CLIs. It's specifically designed for:

- **Direct code editing**: Makes changes to files using intelligent diff-based edits
- **Test-driven development**: Runs tests after changes with `--auto-test` flag
- **Git integration**: Creates structured commits automatically
- **Multiple file coordination**: Handles refactors across multiple files
- **Terminal-first workflow**: No IDE required, works with any editor

**Cost:** Free / open source; you pay your LLM provider (Claude, OpenAI, DeepSeek, Gemini, etc.)

### Why Use Aider with CLIProxyAPI?

| Without CLIProxyAPI | With CLIProxyAPI |
|---------------------|------------------|
| Need separate API keys for Claude, OpenAI, etc. | Use your existing CLI subscriptions |
| Pay per API token usage | Use subscription you already have (Claude Max, ChatGPT Pro) |
| Need to manage API quotas/billing | No additional cost beyond subscription |
| Can't use Gemini free tier | Access Gemini for free via proxy |

### Installation

```bash
# Install via pip
pip install aider-chat

# Or via pipx (isolated installation)
pipx install aider-chat

# Verify installation
aider --version
```

### Key Features

#### Architect Mode
Use `--architect` flag for planning-focused workflows:
```bash
aider --architect --model claude-opus-4-1-20250805
```

**What it does:**
- Focuses on design and architecture discussions
- Creates detailed implementation plans
- Generates task breakdowns
- Works well with Spec-Kit workflows

#### Auto-Testing
Run tests automatically after each change:
```bash
aider --test-cmd "npm test" --auto-test src/
```

**What it does:**
- Runs your test command after edits
- Shows test results in chat
- Agent can see failures and fix them
- Iterates until tests pass

#### Git Integration
Aider creates structured commits:
```bash
aider --message "feat: add user authentication"
```

**Features:**
- Descriptive commit messages
- Follows conventional commit format
- Groups related changes
- Shows git diff before committing

#### Context Management
Control which files Aider can see/edit:
```bash
# Add specific files
aider src/auth.ts src/utils.ts

# Add entire directory
aider src/**/*.ts

# Read-only context (informational)
aider --read README.md src/config.ts
```

### Common Workflows

#### 1. Quick Bug Fix
```bash
# Start with CLIProxyAPI running
ANTHROPIC_API_KEY=dummy \
ANTHROPIC_BASE_URL=http://localhost:8317/v1 \
aider --model claude-3-5-sonnet-20241022 src/buggy-file.ts

# In Aider:
# > Fix the null pointer exception on line 42
```

#### 2. Feature Implementation with Tests
```bash
aider --model gemini-2.5-pro \
  --test-cmd "pytest tests/" \
  --auto-test \
  src/feature.py tests/test_feature.py

# In Aider:
# > Implement the new rate limiting feature according to the spec
```

#### 3. Refactoring Across Files
```bash
aider --model claude-opus-4-1-20250805 src/**/*.ts

# In Aider:
# > Rename getUserById to getUserByIdV2 across all files
# > Update all call sites and add deprecation warnings
```

#### 4. Architecture Planning with Architect Mode
```bash
aider --architect \
  --model claude-opus-4-1-20250805 \
  --read docs/requirements.md

# In Aider:
# > Design the database schema and API endpoints for the new auth system
# > Create a phased implementation plan
```

#### 5. Integration with Spec-Kit
```bash
# After creating Spec-Kit artifacts (constitution, spec, plan, tasks)
aider --model gemini-2.5-pro \
  --test-cmd "npm test" \
  --auto-test \
  --read .speckit/spec.md .speckit/plan.md \
  src/

# In Aider:
# > Implement tasks 1-5 from the Spec-Kit plan. Run tests after each task.
```

### Advanced Usage

#### Using with Multiple Models
Switch models mid-session:
```bash
aider --model gemini-2.5-pro

# In Aider:
# > /model claude-opus-4-1-20250805
# > Now using Claude for complex reasoning
```

#### Code Review Mode
Use Aider for code review:
```bash
aider --model gemini-2.5-pro --read src/new-feature.ts

# In Aider:
# > Review this code for security issues, edge cases, and style
```

#### Interactive Diff Review
Review changes before applying:
```bash
aider --yes  # Auto-apply changes (default)
# or
aider --no   # Always review diffs before applying
```

#### Streaming vs Non-Streaming
```bash
# Streaming (default, faster feedback)
aider --stream

# Non-streaming (wait for complete response)
aider --no-stream
```

### When to Use Aider vs Agent CLIs

**Use Aider when:**
- Making focused code changes to specific files
- Running test-driven development cycles
- Need fast iteration on small to medium tasks
- Want automatic git commits
- Terminal-first workflow preferred
- Working with existing codebases

**Use Agent CLIs (Claude Code, Gemini CLI, Codex) when:**
- Need MCP server integration (Sourcegraph, Semgrep, Context7, etc.)
- Complex multi-step workflows requiring research
- Want shared semantic memory (Qdrant)
- Need cross-CLI orchestration (via Zen MCP clink)
- Exploratory codebase analysis
- Full agent autonomy for complex projects

**Use Both Together:**
- Agent CLIs for planning and research phases (with MCPs)
- Aider for focused implementation phases
- Spec-Kit to bridge the workflows (plan → implement)

### Aider + Spec-Kit Integration

Spec-Kit creates the process framework, Aider executes the implementation:

```bash
# Phase 1-4: Use agent CLI with Spec-Kit
claude  # or gemini/codex

# In agent CLI:
# > /speckit.constitution Performance critical. All queries <100ms.
# > /speckit.specify Add retry logic with exponential backoff
# > /speckit.plan Use Redis for distributed rate limiting
# > /speckit.tasks

# Phase 5: Hand off to Aider for implementation
aider --model claude-opus-4-1-20250805 \
  --test-cmd "npm test" \
  --auto-test \
  --read .speckit/plan.md .speckit/tasks.md \
  src/retry.ts tests/retry.test.ts

# In Aider:
# > Implement all tasks from the Spec-Kit plan. Run tests after each.
```

### Aider with MCP-Enhanced Workflows

While Aider doesn't directly support MCPs, you can use agent CLIs to gather context, then hand off to Aider:

```
┌───────────────┐
│  Spec-Kit     │  ← Process framework (constitution, spec, plan, tasks)
└───────┬───────┘
        │
        ├─→ Research Phase (Agent CLI + MCPs)
        │   ├─ Sourcegraph: Find all code touchpoints
        │   ├─ Context7: Fetch latest API docs
        │   ├─ Qdrant: Retrieve past decisions
        │   └─ Tavily: Research best practices
        │
        ├─→ Planning Phase (Agent CLI + MCPs)
        │   ├─ Use Fetch/Firecrawl for documentation
        │   ├─ Use Semgrep to understand existing patterns
        │   └─ Generate spec and plan artifacts
        │
        └─→ Execution Phase (Aider + CLIProxyAPI)
            ├─ Aider: Implement with auto-testing
            ├─ Commit changes with structured messages
            └─ Iterate until tests pass

# Validation Phase (Agent CLI + MCPs)
├─ Semgrep: Security scanning
├─ Git MCP: Review commits
└─ Qdrant: Store implementation decisions
```

**Example workflow:**

```bash
# 1. Research and plan with agent CLI (has MCP access)
claude  # Uses Sourcegraph, Context7, Semgrep, etc.
# > Research how to implement OAuth 2.0 with PKCE
# > /speckit.specify Add OAuth 2.0 with PKCE flow
# > /speckit.plan
# > /speckit.tasks

# 2. Implement with Aider (via CLIProxyAPI)
ANTHROPIC_API_KEY=dummy \
ANTHROPIC_BASE_URL=http://localhost:8317/v1 \
aider --model claude-opus-4-1-20250805 \
  --test-cmd "npm test" \
  --auto-test \
  --read .speckit/plan.md .speckit/tasks.md \
  src/oauth.ts tests/oauth.test.ts

# In Aider: implement and test

# 3. Validate with agent CLI (has MCP access)
claude
# > /semgrep scan src/oauth.ts for High/Critical issues
# > Store the OAuth implementation decision in Qdrant
```

### Tips for Using Aider Effectively

#### Start Small
```bash
# Good: Start with specific files
aider src/auth.ts

# Less ideal: Add entire codebase at once
aider src/**/*  # Can overwhelm context
```

#### Use Read-Only Context
```bash
# Add files for reference without allowing edits
aider --read docs/spec.md --read src/types.ts src/implementation.ts
```

#### Leverage Auto-Test
```bash
# Let Aider see test results and fix issues
aider --test-cmd "pytest -v" --auto-test src/ tests/

# In Aider:
# > Implement the feature
# (Aider runs tests, sees failures, fixes them, repeats)
```

#### Git Best Practices
```bash
# Review git status before starting
git status

# Let Aider handle commits
aider --auto-commits src/

# Or control commits manually
aider --no-auto-commits src/
```

#### Model Selection
- **Complex logic**: `claude-opus-4-1-20250805`
- **General coding**: `claude-3-5-sonnet-20241022` or `gemini-2.5-pro`
- **Quick fixes**: `claude-3-5-haiku-20241022` or `gemini-2.5-flash`
- **Code-specific**: `gpt-5-codex` (if you have ChatGPT Pro)

### Common Aider Commands

```bash
# In Aider session:
/help                    # Show all commands
/add <file>             # Add file to chat
/drop <file>            # Remove file from chat
/model <name>           # Switch model
/git                    # Show git status
/commit <message>       # Create commit
/undo                   # Undo last edit
/diff                   # Show pending changes
/test                   # Run test command
/tokens                 # Show token usage
/quit                   # Exit Aider
```

### Troubleshooting Aider-Specific Issues

#### Aider Can't Find Files
```bash
# Use absolute paths or ensure you're in project root
cd /path/to/project
aider src/file.ts

# Or use absolute paths
aider /full/path/to/file.ts
```

#### Context Too Large
```bash
# Reduce files in context
aider --read large-file.ts small-file.ts  # Make large file read-only

# Or use smaller model
aider --model claude-3-5-haiku-20241022
```

#### Tests Keep Failing
```bash
# Review test output carefully
aider --test-cmd "pytest -v" --auto-test

# In Aider:
# > The test is failing because of X
# > Fix the implementation to handle Y edge case
```

#### Git Conflicts
```bash
# Resolve conflicts before starting Aider
git status
# Resolve any conflicts

# Or use Aider to help resolve
aider --no-auto-commits conflicted-file.ts
# > Help me resolve this merge conflict
```

---

## Model Reference

### Claude Models (via Claude Code / Claude Max)

| Model Name | Description | Use Case |
|------------|-------------|----------|
| `claude-opus-4-1-20250805` | Most capable, largest context | Complex coding tasks |
| `claude-3-5-sonnet-20241022` | Balanced performance | General purpose |
| `claude-3-5-haiku-20241022` | Fast, cost-effective | Quick tasks |

**Example**:
```bash
aider --model claude-opus-4-1-20250805
```

### Gemini Models (via Gemini CLI)

| Model Name | Description | Use Case |
|------------|-------------|----------|
| `gemini-2.5-pro` | Most capable Gemini | Complex reasoning |
| `gemini-2.5-flash` | Fast, efficient | General tasks |
| `gemini-2.5-flash-lite` | Lightweight | Simple queries |
| `gemini-2.5-flash-image` | Image processing | Vision tasks |

**Example**:
```bash
aider --model gemini-2.5-pro
```

### OpenAI Models (via Codex CLI / ChatGPT Pro)

| Model Name | Description | Use Case |
|------------|-------------|----------|
| `gpt-5` | Latest GPT model | General purpose |
| `gpt-5-codex` | Code-specialized | Coding tasks |

**Example**:
```bash
aider --model gpt-5-codex
```

### Auto-Routing

The proxy automatically routes based on model name prefix:
- `claude-*` → Claude API (via your Claude.ai session)
- `gemini-*` → Gemini API (via your Google account)
- `gpt-*` → OpenAI API (via your ChatGPT session)

---

## Advanced Configuration

### Custom Config File

Create `~/.cli-proxy-api/config.yaml`:

```yaml
# Server settings
port: 8317                        # Default: 8317
auth-dir: "~/.cli-proxy-api"      # Token storage location

# Retry logic
request-retry: 3                  # Retry on 403, 408, 5xx errors

# Logging
debug: false                      # Verbose logging
logging-to-file: true             # Write to rotating log files

# Quota handling (for Gemini)
quota-exceeded:
  switch-project: true            # Auto-switch projects on quota hit
  switch-preview-model: true      # Use preview models when needed

# Network proxy (optional)
proxy-url: ""                     # socks5://... or http://... or https://...
```

Apply config:
```bash
cli-proxy-api --config ~/.cli-proxy-api/config.yaml
```

### Hot Reloading

The server watches `auth-dir` for changes. You can:
- Add new account tokens while server runs
- Remove accounts by deleting JSON files
- No restart required

Example:
```bash
# Server is running in terminal 1

# Terminal 2: Add new account
cli-proxy-api --claude-login

# Server automatically detects and loads new account
```

### Load Balancing

When multiple accounts are configured, the proxy uses **round-robin** distribution:

```bash
# Add 3 Claude accounts
cli-proxy-api --claude-login  # Account 1
cli-proxy-api --claude-login  # Account 2
cli-proxy-api --claude-login  # Account 3

# Requests rotate: Req1→Acct1, Req2→Acct2, Req3→Acct3, Req4→Acct1, ...
```

This helps with:
- **Rate limiting**: Spread load across accounts
- **Quotas**: Switch accounts when one hits limits
- **Reliability**: Failover if one account has issues

### Streaming Responses

Aider automatically uses streaming when supported. To test manually:

```bash
curl http://localhost:8317/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-opus-4-1-20250805",
    "messages": [{"role": "user", "content": "Count to 10"}],
    "stream": true
  }'
```

### Function Calling / Tool Use

The proxy supports OpenAI-compatible function calling:

```python
from openai import OpenAI

client = OpenAI(
    api_key="dummy",
    base_url="http://localhost:8317/v1"
)

tools = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get current weather",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {"type": "string"}
            }
        }
    }
}]

response = client.chat.completions.create(
    model="claude-opus-4-1-20250805",
    messages=[{"role": "user", "content": "What's the weather in SF?"}],
    tools=tools
)
```

### Vision / Multimodal Input

For image analysis with Gemini:

```python
from openai import OpenAI

client = OpenAI(
    api_key="dummy",
    base_url="http://localhost:8317/v1"
)

response = client.chat.completions.create(
    model="gemini-2.5-flash-image",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "What's in this image?"},
            {"type": "image_url", "image_url": {"url": "https://example.com/image.jpg"}}
        ]
    }]
)
```

---

## Troubleshooting

### Server Won't Start

**Problem**: Port 8317 already in use

```bash
# Check what's using the port
lsof -i :8317

# Kill the process or use different port
cli-proxy-api --config <(echo 'port: 8318')
```

**Problem**: OAuth callback port conflicts

```bash
# Check ports 54545 (Claude), 8085 (Gemini), 1455 (OpenAI)
lsof -i :54545
lsof -i :8085
lsof -i :1455

# Free the port or wait for OAuth to complete
```

### Authentication Failures

**Problem**: "No valid authentication found"

```bash
# Re-authenticate
cli-proxy-api --claude-login
cli-proxy-api --login
cli-proxy-api --codex-login

# Check token files exist
ls -la ~/.cli-proxy-api/

# Check token files are valid JSON
cat ~/.cli-proxy-api/claude_*.json | jq .
```

**Problem**: OAuth redirect fails

- Ensure callback ports aren't blocked by firewall
- Try `--no-browser` flag and paste URL manually
- Check browser isn't blocking localhost connections

### Aider Connection Issues

**Problem**: Aider says "API key invalid"

```bash
# Verify proxy is running
curl http://localhost:8317/v1/models

# Check environment variables
echo $ANTHROPIC_BASE_URL
echo $ANTHROPIC_API_KEY

# Test with curl first
curl http://localhost:8317/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gemini-2.5-pro","messages":[{"role":"user","content":"test"}]}'
```

**Problem**: Wrong model being used

- Verify model name matches proxy conventions (`claude-*`, `gemini-*`, `gpt-*`)
- Check proxy logs for routing info
- Use `--model` flag explicitly in Aider

### Rate Limiting / Quotas

**Problem**: "Rate limit exceeded" errors

```bash
# Add more accounts for load balancing
cli-proxy-api --claude-login  # Add 2nd account

# Enable quota switching in config
cat > ~/.cli-proxy-api/config.yaml <<EOF
quota-exceeded:
  switch-project: true
  switch-preview-model: true
EOF
```

**Problem**: Gemini quota exhausted

- Wait for quota reset (usually daily)
- Add additional Google accounts
- Use preview models (`gemini-2.5-flash-preview`)

### Debugging

**Enable verbose logging**:
```yaml
# ~/.cli-proxy-api/config.yaml
debug: true
logging-to-file: true
```

**Check logs**:
```bash
# Find log directory (usually ~/.cli-proxy-api/logs/)
ls -la ~/.cli-proxy-api/logs/

# Tail logs
tail -f ~/.cli-proxy-api/logs/proxy.log
```

**Test individual providers**:
```bash
# Test Claude
curl http://localhost:8317/v1/chat/completions \
  -d '{"model":"claude-opus-4-1-20250805","messages":[{"role":"user","content":"hi"}]}'

# Test Gemini
curl http://localhost:8317/v1/chat/completions \
  -d '{"model":"gemini-2.5-pro","messages":[{"role":"user","content":"hi"}]}'

# Test OpenAI
curl http://localhost:8317/v1/chat/completions \
  -d '{"model":"gpt-5","messages":[{"role":"user","content":"hi"}]}'
```

---

## Security Considerations

### Local-Only Access

By default, the proxy **only accepts connections from localhost**. Do not expose port 8317 publicly.

**Bad**:
```bash
# DON'T DO THIS
cli-proxy-api --host 0.0.0.0  # Exposes to network
```

**Good**:
```bash
# Default behavior (localhost only)
cli-proxy-api
```

### Token Storage

Authentication tokens are stored in `~/.cli-proxy-api/`:

```bash
# Secure the directory
chmod 700 ~/.cli-proxy-api
chmod 600 ~/.cli-proxy-api/*.json

# Backup tokens (optional)
tar -czf ~/cliproxy-backup.tar.gz ~/.cli-proxy-api/
```

**Never commit tokens to git**:
```bash
# Add to .gitignore
echo ".cli-proxy-api/" >> ~/.gitignore_global
```

### Network Proxy (Optional)

If you need to route requests through a proxy:

```yaml
# ~/.cli-proxy-api/config.yaml
proxy-url: "http://localhost:8888"  # or socks5://...
```

### Management API

The proxy includes a management API (disabled by default). If enabled, set a strong secret:

```yaml
# ~/.cli-proxy-api/config.yaml
management:
  enabled: false  # Keep disabled unless needed
  secret: "your-bcrypt-hashed-secret"
```

### Token Expiry

OAuth tokens expire periodically. Signs of expired tokens:
- "Unauthorized" errors in Aider
- Proxy logs show auth failures

**Solution**: Re-authenticate:
```bash
cli-proxy-api --claude-login
cli-proxy-api --login
cli-proxy-api --codex-login
```

---

## Quick Reference

### Common Commands

```bash
# Install
brew install cliproxyapi

# Authenticate all providers
cli-proxy-api --claude-login
cli-proxy-api --login
cli-proxy-api --codex-login

# Start server
cli-proxy-api

# Start as background service
brew services start cliproxyapi

# Test server
curl http://localhost:8317/v1/models

# Use with Aider (Claude)
ANTHROPIC_API_KEY=dummy \
ANTHROPIC_BASE_URL=http://localhost:8317/v1 \
aider --model claude-opus-4-1-20250805

# Use with Aider (Gemini)
OPENAI_API_KEY=dummy \
OPENAI_BASE_URL=http://localhost:8317/v1 \
aider --model gemini-2.5-pro

# Use with Aider (OpenAI)
OPENAI_API_KEY=dummy \
OPENAI_BASE_URL=http://localhost:8317/v1 \
aider --model gpt-5-codex
```

### Environment Variables for Aider

```bash
# Create ~/.aider-proxy-env
export ANTHROPIC_API_KEY="dummy"
export ANTHROPIC_BASE_URL="http://localhost:8317/v1"
export OPENAI_API_KEY="dummy"
export OPENAI_BASE_URL="http://localhost:8317/v1"

# Use it
source ~/.aider-proxy-env
aider --model claude-opus-4-1-20250805
```

### Model Quick Reference

```bash
# Claude (best for complex coding)
aider --model claude-opus-4-1-20250805

# Gemini (free, good performance)
aider --model gemini-2.5-pro

# OpenAI (if you have ChatGPT Pro)
aider --model gpt-5-codex
```

---

## Additional Resources

- **CLIProxyAPI GitHub**: https://github.com/router-for-me/CLIProxyAPI
- **Aider Documentation**: https://aider.chat/docs/
- **Claude API Docs**: https://docs.anthropic.com/
- **Gemini API Docs**: https://ai.google.dev/docs
- **OpenAI API Docs**: https://platform.openai.com/docs

---

## Changelog

- **2025-10-17**: Initial documentation created
  - Covers Gemini CLI, Claude Code, Codex CLI integration
  - Includes Aider configuration examples
  - Added comprehensive "About Aider" section with:
    - Installation and key features
    - Common workflows and advanced usage patterns
    - Integration with Spec-Kit and MCP-enhanced workflows
    - When to use Aider vs Agent CLIs
    - Tips, best practices, and troubleshooting
  - Added troubleshooting and security sections

---

## Contributing

This document is maintained as part of the `my-agent-files` repository. To suggest improvements, please submit issues or pull requests.
