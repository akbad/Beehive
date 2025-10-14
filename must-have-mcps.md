
# must-have-mcps.md

A practical guide to **must‑have MCP servers** and adjacent tools that *meaningfully* upgrade your dev flow with Codex/Gemini CLI — plus how **GitHub’s Spec‑Kit** fits alongside them.

> **Who this is for:** You work mostly in VS Code + CLI with Codex/Gemini/Claude, want safer & faster multi‑file edits, better research, and **less token waste**, and you prefer tools you can enable in minutes.

---

## TL;DR – What to install first

If you only add seven things, make it these:

1. **Filesystem (reference server)** – safe, allow‑listed file ops.
2. **Git (reference/community)** – branch/commit/diff/search via tools the model understands.
3. **Fetch (HTML → Markdown)** – ingest docs/specs efficiently.
4. **Context7** – *version‑correct* API docs/examples into context.
5. **Tavily** – search/extract/map/crawl with citations for design‑doc research.
6. **Semgrep** – SAST gate on agent‑generated diffs.
7. **A memory server** (pgvector or Weaviate) – persistent semantic memory to avoid re‑feeding context.

Then optionally add **Firecrawl** (robust crawling), **Sourcegraph** (cross‑repo code search), **Snyk** (vuln scanning), and a workflow glue tool (**Composio/Rube**).

---

## How MCP fits your agents (cheat‑sheet)

- **Gemini CLI**: supports MCP natively. Add servers with `gemini mcp add <name> <commandOrUrl> [args...]` (stores in `~/.gemini/settings.json` or project `.gemini/settings.json`). Use `/mcp` to list tools.  
- **Codex / VS Code / Claude Code**: add the same servers via each client’s MCP settings UI (or JSON). The server process just needs to be runnable on your machine or reachable over HTTP.

> **Pattern:** Servers are **just commands** your client launches (e.g., `npx`, `uvx`, or a binary). No vendor lock‑in — one server can serve **all** clients.

---

## Server-by-server: why they’re better than “vanilla”, how to install, and cost

### 1) Filesystem (official/reference)
**Why over vanilla shell:** structured, allow‑listed read/write/move/search with predictable errors — far safer and less brittle than letting an agent run arbitrary `bash` for file ops.

**Install & run (examples):**
- With a manager: `mcp-get install filesystem` → then **Gemini CLI:** `gemini mcp add fs mcp-server-filesystem`  
- Or via Node/TS ref server: `npx @modelcontextprotocol/server-filesystem`  
- Or via Python ref server: `uvx mcp_server_filesystem`

**Cost:** Free / open source.

**Try:** “Read `server/**/*.go` and propose a patch adding retries with exponential backoff; write diffs but do not commit.”

---

### 2) Git (official/reference or community)
**Why over vanilla git in shell:** first‑class tools for branch/diff/commit/search exposed via a schema the model understands; agents can reason about diffs atomically and generate PR‑ready changes.

**Install & run (examples):**
- `pipx install mcp-server-git` → `gemini mcp add git mcp-server-git`
- or `npx @modelcontextprotocol/server-git`

**Cost:** Free / open source.

**Try:** “Create branch `feat/backoff`, apply generated patch, run tests, commit with a conventional message, open a diff for review.”

---

### 3) Fetch (HTML → Markdown)
**Why over `curl`/raw HTML:** fetches pages and **converts to clean Markdown** (with chunking). This drastically **reduces tokens** and preserves structure for summarization and citing.

**Install & run (examples):**
- `pipx install mcp-server-fetch` → `gemini mcp add fetch mcp-server-fetch`
- or `npx @modelcontextprotocol/fetch-as-markdown`

**Cost:** Free / open source.

**Try:** “Fetch the Kafka idempotent producer docs; summarize integration steps for our service (bullets + code). Include links.”

---

### 4) Context7 (Upstash) — “always‑fresh” API docs
**Why:** injects **version‑correct API docs and code examples** directly into the prompt so the model doesn’t rely on stale training data. Huge drop in API hallucinations.

**Install & run (example):**
```bash
gemini mcp add context7 npx -- -y @upstash/context7-mcp \
  --api-key $CONTEXT7_API_KEY
```
*(Set your Context7 API key in the environment.)*

**Cost:** Free tier for personal/edu; paid tiers available.

**Try:** “Implement S3 multipart upload with retries and abort; **use context7** to pull the latest AWS SDK examples.”

---

### 5) Tavily – search/extract/map/crawl with citations
**Why:** production‑grade web search + structured extraction, website mapping, and crawling. Faster design‑doc research with **traceable sources**.

**Install & run:**
```bash
gemini mcp add tavily npx -- @tavily/mcp
# requires TAVILY_API_KEY in env
```

**Cost:** Free tier (credits/month), paid beyond.

**Try:** “Map ‘event‑sourced outbox’ best practices; return pros/cons, failure modes, and 5 citations.”

---

### 6) Firecrawl – resilient scraping & deep crawls
**Why:** robust crawl/scrape (JS rendering, deep crawl, batch jobs). Great fallback when simple fetch fails or for entire doc sets/wiki sections.

**Install & run:**
```bash
gemini mcp add firecrawl npx -- firecrawl-mcp-server
# requires FIRECRAWL_API_KEY in env (or self‑host)
```

**Cost:** Free starter credits; paid plans thereafter (or self‑host).

**Try:** “Crawl our internal wiki section on ‘payments’; extract constraints and list open questions.”

---

### 7) Sourcegraph MCP – cross‑repo code search
**Why over local grep:** org‑wide **code search** across many repos with advanced queries, exposed as structured tool calls the model can use to gather evidence before refactors.

**Install & run (one option):**
```bash
git clone https://github.com/divar-ir/sourcegraph-mcp
cd sourcegraph-mcp
uv sync && uv run python -m src.main  # starts the server
gemini mcp add sgrep http --url http://localhost:8080/sourcegraph/mcp/
# set SRC_ENDPOINT and a token if searching private code
```

**Cost:** Public code search is free; private/org search requires a paid Sourcegraph plan or your own instance.

**Try:** “Find all usages of `WriteBatch` across repos; summarize breakages if we change its return type.”

---

### 8) Memory servers — persistent context

**a) Reference “Memory” server (knowledge‑graph/notes)**  
**Why:** persist long‑term decisions, ADRs, constraints, and recall by semantics → **stop re‑feeding** the same background every session.

**Install & run:** `npm i -g @modelcontextprotocol/server-memory` → `gemini mcp add memory mcp-server-memory`  
**Cost:** Free / open source.

**b) Postgres + pgvector**  
**Why:** self‑hosted, scalable semantic memory retrieval with SQL control; perfect for large repos/specs.  
**Install & run:** bring up Postgres with pgvector (Docker), then point your pgvector MCP server at it; `gemini mcp add pgmem <your_server_command>`.  
**Cost:** Free to self‑host; cloud Postgres incurs cost.

**c) Weaviate**  
**Why:** drop‑in vector DB; fast semantic recall for big doc sets.  
**Install & run:** run Weaviate (Docker/Cloud) + the Weaviate MCP server; add via `gemini mcp add wv http --url http://localhost:8080/mcp/`.  
**Cost:** OSS self‑hosted free; Weaviate Cloud paid.

**Try (for any memory):** “Save this ADR for read‑repair invariants” → later “Retrieve prior read‑repair decisions before editing the reconciler.”

---

### 9) Semgrep – SAST in the same agent loop
**Why:** deterministic static analysis with **structured findings**; catch real issues introduced by AI edits (security + correctness) before you commit.

**Install & run:** `pipx install semgrep-mcp` or clone `semgrep/mcp` and run; `gemini mcp add semgrep semgrep-mcp`  
**Cost:** Community edition free; Teams/Enterprise paid.

**Try:** “Scan only files changed in this branch; propose patches for high‑severity findings.”

---

### 10) Snyk – vuln/SCA/IaC/container scans
**Why:** agent‑triggerable scanning with actionable results in chat; pairs well with Semgrep for broader coverage.

**Install & run:** Use Snyk’s MCP (standalone or via CLI integration), then `gemini mcp add snyk <server_cmd>`; set `SNYK_TOKEN`.  
**Cost:** Free tier; paid org features.

**Try:** “Scan `packages/*` and open issues for critical vulns with suggested upgrades.”

---

### 11) Composio / Rube – glue to your work apps
**Why:** one server exposes **hundreds of app actions** (GitHub/Jira/Linear/Slack/Notion…). Turn `/speckit.tasks` into real tickets, update docs, post diffs to Slack — **no bespoke glue code**.

**Install & run:** `gemini mcp add rube npx -- @composiohq/rube` then auth the apps in their UI.  
**Cost:** Generous free plan (tool‑call quota); paid tiers for volume.

**Try:** “Create three Jira tickets from the task list; link the GH PR and post the plan in Slack #backend.”

---

### 12) MCP managers (quality‑of‑life)

**mcp‑get** – one‑command installer: `brew install mcp-get` → `mcp-get install <server>`.  
**MCP‑Proxy** – bridge stdio ↔ SSE, isolate/rate‑limit servers; great for aggregating many servers behind one endpoint.  
**Dockmaster** – desktop GUI to discover/install/configure servers across clients.

All are free / open source.

---

### (Non‑MCP) Aider – PR‑style diffs from a CLI
**Why:** laser‑focused on multi‑file patches and tests; great executor for a validated plan. Works with GPT‑5‑Codex/Sonnet keys.  
**Install:** `python -m pip install uv && uv tool install aider-chat` → `aider --model openai/gpt-5-codex`  
**Cost:** Free/OSS; you pay your model provider.

---

## Security: run tools like you would any extension

- **Allow‑list paths** and prefer **read‑only** where possible.  
- **Scope tokens** narrowly (separate keys per server).  
- Prefer **HTTP on localhost** or a proxy that can quarantine new servers.  
- Keep a **human‑in‑the‑loop** on dangerous tools (write/exec).  
- Stay current: the ecosystem is new; malicious servers have already appeared in the wild. Rotate creds if you ever suspect compromise.

---

## Quick‑start commands (Gemini CLI)

> These examples register servers into your **user** config. Use `--scope project` to store in `.gemini/settings.json` for a single repo.

```bash
# Baseline
gemini mcp add fs mcp-server-filesystem
gemini mcp add git mcp-server-git
gemini mcp add fetch mcp-server-fetch

# Research
gemini mcp add context7 npx -- -y @upstash/context7-mcp --api-key $CONTEXT7_API_KEY
gemini mcp add tavily npx -- @tavily/mcp
gemini mcp add firecrawl npx -- firecrawl-mcp-server

# Code search & memory
gemini mcp add sgrep http --url http://localhost:8080/sourcegraph/mcp/
gemini mcp add memory mcp-server-memory
# or bring your own vector store and add its server:
gemini mcp add pgmem <your-pgvector-server-cmd>

# Quality & workflow
gemini mcp add semgrep semgrep-mcp
gemini mcp add snyk <your-snyk-mcp-cmd>
gemini mcp add rube npx -- @composiohq/rube
```

> Tip: Run `/mcp` in Gemini CLI to list tools exposed by each server.

---

## Where **GitHub’s Spec‑Kit** fits (spec‑driven development)

**What it is:** An open‑source toolkit + **Specify CLI** that scaffolds a **spec → plan → tasks → implement** flow and equips your agent with consistent **slash commands**:
- `/speckit.constitution` – project principles/guardrails  
- `/speckit.specify` – **WHAT** to build (requirements)  
- `/speckit.plan` – **HOW** (stack/architecture)  
- `/speckit.tasks` – actionable task list  
- `/speckit.implement` – apply multi‑file edits with your chosen agent

**Why it’s useful with MCP:** MCP gives your agent *capabilities*; Spec‑Kit gives your project a **repeatable process & artifacts**. Together: you get **ground truth** (spec/plan) and **grounded tools** (search, memory, scanners) so the agent executes reliably.

**Install (one‑liners):**
```bash
# Using uvx (Python):
uvx --from git+https://github.com/github/spec-kit.git specify init <PROJECT_NAME>
specify check   # verifies local tools (git, gemini, copilot, cursor, codex, etc.)
```

**When to use it:**
- **Medium/large features** or **cross‑cutting refactors** where you want a reviewable **spec & plan** before code changes.  
- Teams/review flows: the artifacts live in‑repo and are easy to diff/comment on.  
- Not needed for tiny fixes; skip on one‑file chores to avoid overhead.

**How to run it next to these MCPs (example with your Dynamo‑style KV “locker”):**
```
/speckit.constitution Performance, deterministic tests, zero-downtime deploys.
/speckit.specify Add read-repair and anti-entropy sync to the eventually consistent KV.
/speckit.plan Go + gRPC; background reconciler; vector clocks; property tests.
/speckit.tasks
```
Then let your agent use **Sourcegraph** to find touch points, **Context7** for API usage, **Semgrep/Snyk** to gate changes, and **Git**/**Filesystem** to apply diffs. Persist decisions in **Memory**.

**Caveats:** It’s evolving; some IDE profiles are still catching up. If a slash command misbehaves in your client, check the repo’s issues or update the templates, then re‑run `specify init` to refresh prompts.

---

## Decision guide (what to use when)

- **Repo comprehension / giant specs** → **Gemini CLI + Fetch/Firecrawl + Memory**  
- **Org‑wide code impact** → **Sourcegraph MCP**  
- **Plan‑then‑execute** → **Spec‑Kit** to create artifacts, then **Git/Filesystem** + your agent  
- **Security/correctness gate** → **Semgrep** (+ **Snyk** for deps/IaC/containers)  
- **Ticketing & communication** → **Composio/Rube**  
- **Token efficiency** → Prefer **Fetch** (HTML→MD), store background in **Memory**, and use a proxy/manager if you connect lots of servers

---

## Appendix – Pricing at a glance (subject to change)

- **Free/OSS:** Filesystem, Git, Fetch, Memory (ref), MCP‑Proxy, Dockmaster, Aider  
- **Free tier + paid:** Context7 (free personal/edu), Tavily (monthly credits), Firecrawl (starter credits), Sourcegraph (free public; paid private/org), Semgrep (Community free; Teams paid), Snyk (free tier; paid), Composio/Rube (free calls; paid tiers)

---

**Maintainer notes**  
Keep this file in your repo (e.g., `/docs/must-have-mcps.md`) and update quarterly. Store API keys as env vars; never hard‑code tokens in your MCP config.
