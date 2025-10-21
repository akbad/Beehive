# Tools set up by `set-up-mcps.sh` & how to use them

## Tool list

### MCP servers

| Server/tool | Functionality | How it's run/talked to by agents | Restrictions |
| :----- | :------------ | :------------ | :----------- |
| **Zen MCP *(`clink` only)*** | multi-model orchestration; CLI-to-CLI bridge (“clink”); spawn sub-agents; context threading across tools/CLIs | HTTP with locally-run server | None |
| **Fetch MCP** | fetch HTTP/HTTPS URLs; HTML→Markdown; optional raw HTML; chunk reading via start_index; custom UA/robots handling | Stdio with private client-managed instance | None |
| **Firecrawl MCP** | crawl/scrape/extract; search; map sites; batch/deep research | **Claude & Codex**: HTTP using Firecrawl's remote server; **Gemini CLI**: stdio with local proxy that talks to Firecrawl's remote server |
| **Context7 MCP** | pull up-to-date, version-specific code docs & examples into prompts; works with Cursor/Claude/VS Code | Free tier used: only allows accessing *public* repos

> Note: **the *Fetch* MCP does not support fetching from the GitHub website** (e.g. to look up API-/code-related info about public repos) 
> 
> Instead, tell the agent to use one of these solutions, depending on what you need from GitHub: 
> 
> 1. Use `gh` CLI 
> 2. Use Sourcegraph MCP
> 3. Clone repos locally and use Git MCP to go through them**

### Non-MCP tools

## How to use each tool (e.g. in prompts)