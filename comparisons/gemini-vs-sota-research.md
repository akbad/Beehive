
# Gemini 2.5 Pro vs. Claude Opus 4.1 & GPT‑5/GPT‑5‑Codex

**Last updated:** October 17, 2025

This report answers whether **Gemini 2.5 Pro (via Gemini CLI)** *fully* competes with **Claude Opus 4.1 (via Claude Code)** and **GPT‑5 and/or GPT‑5‑Codex (on High thinking via Codex CLI)** for:

1) regular daily coding tasks,  
2) large‑scale refactors on complex production codebases, and  
3) complex system/application design & optimization.

It is self‑contained and cites primary sources, public leaderboards, product docs, and representative community reports. It also includes **reproducible commands** and a **decision checklist**.

---

## TL;DR (Short Answer)

1. **Daily coding tasks:** **Yes — Gemini 2.5 Pro competes strongly.** On practical code‑editing tests like **Aider Polyglot**, Gemini 2.5 Pro ranks among the very best (top‑2 on 2025‑06‑06), trailing only GPT‑5 (High) in the latest public run we could find. In day‑to‑day work, UX differences between **Gemini CLI**, **Claude Code**, and **Codex CLI** often matter more than small benchmark gaps.  
  Evidence: Aider Polyglot leaderboard; Gemini CLI feature set (ReAct loop, MCP, GitHub Actions). [^aider-polyglot] [^gemini-cli-docs] [^gemini-cli-github] [^gemini-cli-actions]

2. **Large‑scale refactors:** **Partially.** Gemini 2.5 Pro shows **major gains on agentic coding** (e.g., **SWE‑bench Verified single/multi‑attempt: 59.6% / 67.2%**) but **Claude Opus 4.1 currently leads** on the headline full‑set result (**74.5%**) and has **documented long‑duration autonomy** (e.g., Rakuten’s **7‑hour autonomous refactor**). GPT‑5/GPT‑5‑Codex are strong as well (with robust sandbox/approval controls in Codex), but public, apples‑to‑apples refactor evidence still most favors Claude for very large, precision‑sensitive changes.  
  Evidence: Anthropic Opus 4.1 post; Rakuten case; DeepMind Gemini 2.5 Pro page & report; SWE‑bench Verified. [^opus41] [^rakuten] [^gemini25] [^gemini25-report] [^swebench-verified]

3. **Complex system/application design & optimization:** **Mixed.** All three models are high‑reasoning systems. **GPT‑5** introduces new developer controls (verbosity & reasoning effort) and ships with a hardened **Codex CLI** (sandbox + approvals). **Claude Opus 4.1** demonstrates state‑of‑the‑art coding/agentic performance and enterprise case studies; **Gemini 2.5 Pro** excels at **long context** and scientific/technical reasoning (e.g., **GPQA Diamond**, **LiveCodeBench**) and comes with strong integration options (MCP, GitHub Actions, Zed IDE via ACP, etc.). On broader “real‑work” tasks (e.g., **OpenAI’s GDPval**), results vary by occupation; OpenAI reports GPT‑5 improvements overall while independent coverage highlights **Claude** also doing extremely well in several sectors. Vendors optimize for different trade‑offs, so team fit often trumps single “winner.”  
  Evidence: GPT‑5 pages; Codex CLI docs; Gemini 2.5 benchmarks; GDPval announcement & coverage. [^gpt5] [^gpt5-dev] [^codex-docs] [^codex-repo] [^gemini25] [^gdpval] [^gdpval-paper] [^tech-coverage-gdpval]

**Bottom line:** 

- For **everyday coding**, Gemini 2.5 Pro **absolutely competes**. 
- For **huge refactors**, **Claude Code + Opus 4.1** still has the **strongest published evidence** (performance + autonomy).
- For **system design/optimization**, it’s **use‑case dependent**: 
    
    - GPT‑5 (esp. with Codex) and Claude often lead on reliability and planning
    - Gemini is excellent for large‑context, multimodal, and end‑to‑end automation with CLI/Actions. 

---

## Evidence at a glance (key benchmarks & claims)

> Benchmarks are sensitive to **scaffolds/agents**, **attempt budgets**, and **evaluation harnesses**. Treat them as **signals**, not absolute truth. Where possible, prefer primary sources and note dates.

### Code editing — Aider Polyglot (multi‑language Exercism edits)

| Model | Score | Rank | Benchmark date |
| :---- | :---- | :--- | :------------- |
| **GPT-5 (High)** | **88.0%** | #1 | 2025-06-06 |
| **Gemini 2.5 Pro (Preview)** | **83.1%** | #2 | 2025-06-06 |

Source: **Aider LLM Leaderboards**. [^aider-polyglot]

### Agentic coding — SWE‑bench Verified (500 human‑validated GitHub issues)

| Model | Score | Notes & sources |
| :---- | :---- | :---- | 
| **Claude Opus 4.1** | **74.5%** | Full 500 set; no extended thinking. [^opus41] | 
| **Gemini 2.5 Pro** | **59.6% (single‑attempt)**, **67.2% (multi‑attempt)** | (pr DeepMind model page/report [^gemini25] [^gemini25-report] |
> **Benchmark background:** OpenAI + SWE‑bench teams introduced the **Verified** subset to address evaluation pitfalls (updated 2025‑02‑24). [^swebench-verified]

### Long‑context & coding reasoning signals (select)

- **Gemini 2.5 Pro**: [^gemini25] [^gemini25-report] 
    
    - Strong **LiveCodeBench** and **Aider Polyglot** jumps over prior Gemini versions
    - **GPQA Diamond** and **MMMU** also high. 
 
- **Claude Opus 4.1**: [^opus41] [^rakuten]  

    - Opus 4.1 post highlights **multi‑file refactor** gains and **74.5% SWE‑bench Verified**; Rakuten **7‑hour** autonomy case. 

- **GPT‑5 / GPT‑5‑Codex**: [^gpt5-dev] [^codex-docs] [^codex-repo]
    
    - New **verbosity** and **reasoning‑effort** controls
    - **Codex CLI** with **sandbox & approvals**, **non‑interactive** runs, and **GitHub Action/IDE** integrations

### “Real‑work” evals
- **GDPval v0 (OpenAI)** evaluates 44 occupations with real deliverables. Early coverage highlights **strong GPT‑5 gains** vs 4‑series and **competitive Claude performance**; results vary by occupation. (GDPval is broad knowledge work; it includes **software dev** but is not a pure coding/refactor test.) [^gdpval] [^gdpval-paper] [^tech-coverage-gdpval]

---

## Category 1: regular daily coding tasks

**Verdict:** **Yes — Gemini 2.5 Pro competes** (w.r.t. code search, small fixes, test writing, lightweight features, and “edit this file / explain this error") Gemini 2.5 Pro via **Gemini CLI** is competitive with GPT‑5 and Claude, with modern agentic features.

- **Quality**: On **Aider Polyglot**, Gemini 2.5 Pro ranks near the top, behind GPT‑5 (High) in the latest public run. [^aider-polyglot]  

**Practical take:** For everyday tasks, **all three** are excellent. If your team prefers **tight approval controls and OS sandboxing**, Codex CLI is compelling; if you want **structured planning (Plan Mode)** and **multi‑file edit discipline**, Claude Code shines; if you want **Google’s toolchain** (GCP, Vertex, Search, Veo/Imagen, GitHub Actions) and **long‑context perks**, Gemini CLI is great.

> More relevant details about Gemini CLI:
> 
> - **UX/Features**: **Gemini CLI** is an **open‑source agent** that runs a **ReAct loop**, integrates your local tools, and connects to **MCP servers**; Google is also shipping **GitHub Actions** for repo automation and triage/review. [^gemini-cli-docs] [^gemini-cli-github] [^gemini-cli-actions]  
> - **Ecosystem**: Integrations are expanding (e.g., **Zed IDE’s Agent Client Protocol**), plus **Vertex AI** and **Code Assist** options. [^gemini-vertex] [^zed-acp]  
> - **Limitations to keep in mind**: Early Gemini CLI builds had **limited remote MCP** support; current docs and community posts show **growing support via FastMCP/Docker** but behavior may differ by transport/protocol. [^mcp-docs]

---

## Category 2: large-scale refactors on complex production databases

**Verdict:** **Partially — Gemini is strong but Claude currently has the clearest edge in published evidence.**

- **Claude Opus 4.1** leads on **SWE‑bench Verified** (**74.5%**), with claims of **notable multi‑file refactor gains**, and **real‑world autonomy** 
  
    - Example: **Rakuten’s 7‑hour open‑source refactor** run with sustained performance. [^opus41] [^rakuten]  

- **Gemini 2.5 Pro** shows **big improvements** in agentic coding (**59.6% single / 67.2% multi‑attempt** on the Verified set) and strong code‑editing performance
    
    - It can absolutely drive refactors with **Gemini CLI** + approvals. [^gemini25] [^gemini25-report]  

- **GPT‑5 / GPT‑5‑Codex**: 

    - While public refactor‑specific benchmarks are thin, **Codex CLI** is explicitly designed for **safe large edits** (workspace sandbox; granular approvals; non‑interactive runs). 
    - Many teams value these **guardrails** during high‑risk refactors. [^codex-docs] [^codex-security]

**What the refactor‑specific research says:** Newer benchmarks like **RefactorBench** (multi‑file stateful refactors) and **SWE‑Refactor** (1,099 real‑world Java refactors) show **current agents struggle and are scaffold‑sensitive**, with low‑to‑moderate success under baseline agents. There is **not yet** a definitive, vendor‑neutral, **head‑to‑head** across **GPT‑5 / Opus 4.1 / Gemini 2.5** on these new refactor suites. [^refactorbench] [^swe-refactor]

**Practical take:** For **mission‑critical refactors**, the safer choice today is often **Claude Code + Opus 4.1** (published track record + autonomy). **Gemini 2.5 + Gemini CLI** is viable and improving quickly; expect success **with strong engineering rails** (comprehensive tests, checkpoints, gated approvals, CI, and reproducible runbooks). **Codex CLI** is compelling if you prioritize **OS‑level sandboxing and explicit approvals** during high‑risk edits.

---

## 3) Complex system/application design & optimization

**Verdict:** **Mixed — pick based on team needs and control surfaces.**

- **GPT‑5** emphasizes **developer control** (verbosity + reasoning‑effort), paired with **Codex CLI** for **sandboxed execution**, "show diff → approve"‑style workflows, **IDE/Action** integrations, and **non‑interactive** batch runs. This combo is strong for **planning → implement → verify** loops. [^gpt5-dev] [^codex-docs] [^codex-security] [^codex-repo]  
- **Claude Opus 4.1** excels at **agentic planning and deep code changes**, and **Claude Code** offers **Plan Mode** (read‑only analysis) and configurable approval policies — useful for complex design reviews and staged rollouts. [^opus41] [^plan-mode] [^cc-settings]  
- **Gemini 2.5 Pro** shines with **long‑context**, **multimodal inputs**, and growing **automation surfaces** (CLI + GitHub Actions). For design/optimization spanning **many files** or **docs + code + UI**, Gemini’s context window and integrations can be advantageous. [^gemini25] [^gemini-cli-docs] [^gemini-cli-actions]

On “real‑work” breadth, **GDPval v0** suggests **both GPT‑5 and Claude** are at/near expert level in many tasks, with **domain variation** and **methodological caveats**. Google has **not** published a GDPval‑style result for Gemini at the time of writing. [^gdpval] [^gdpval-paper] [^tech-coverage-gdpval]

---

## Tooling & UX Differences That Matter in Practice

| Area | **Gemini CLI** | **Claude Code** | **Codex CLI** |
|---|---|---|---|
| **Agent loop** | ReAct loop; built‑in tools + **MCP servers** (local/remote via FastMCP/Docker) | Agentic CLI; **Plan Mode** (read‑only); multi‑file edits; approvals | Agentic CLI; **OS sandbox** (macOS seatbelt, Linux), **granular approvals**, non‑interactive `exec` |
| **Approvals & safety** | Command/file approvals; evolving remote MCP support | Default prompts; modes incl. **Plan**, auto‑accept; **`--dangerously-skip-permissions`** exists (use with care) | **Configurable approvals** (`read‑only` → `auto` → `full access`), **workspace sandbox**, network controls |
| **IDE/CI** | GitHub **Actions** beta (triage/review/PR); Zed ACP; Code Assist/Vertex | Native VS Code extension; CLI ↔ IDE; community playbooks | VS Code extension; GitHub Action; **`codex exec`** for CI jobs |
| **Context & modalities** | Strong long‑context; multimodal (text/code/images/video via Veo/Imagen) | Multimodal in app; Code‑focused in CLI | Multimodal inputs (image attachments), logs/diffs |
| **Docs & OSS** | Open‑source CLI; Google docs & codelabs | Official docs + engineering blogs; active community | Open‑sourced **codex** repo; official dev docs |

Sources: [^gemini-cli-docs] [^gemini-cli-github] [^gemini-cli-actions] [^zed-acp] [^plan-mode] [^cc-settings] [^codex-repo] [^codex-docs] [^codex-security]

---

## Recommendations (by scenario)

- **You want the most proven autonomy for big refactors right now:** **Claude Code + Opus 4.1**. Start in **Plan Mode**, stage changes behind feature flags, and enforce approvals + CI. Track work with git branches and checkpoints (PRs per module). [^opus41] [^plan-mode]
- **You want deep control/sandboxing and reproducible batch jobs:** **Codex CLI + GPT‑5/GPT‑5‑Codex**. Use `workspace-write` sandbox + `on-request` approvals for safety; move to `full‑auto` only in disposable environments. Combine with `codex exec` in CI. [^codex-security] [^codex-docs]
- **You want long‑context, Google ecosystem, and repo automation:** **Gemini CLI + Gemini 2.5 Pro**. Leverage **GitHub Actions** for triage/reviews/tests, and **MCP** tools for environment control. Validate with incremental PRs. [^gemini-cli-actions] [^mcp-docs]

**Across all three:** Invest in **tests** (unit + property + integration), **approval policies**, **runbooks**, and **observability** (traces, artifacts, logs). These determine outcomes more than choosing Model A vs Model B by a few percentage points.

---

## Benchmarks to try

> The exact numbers you’ll see depend on scaffolds, attempt budgets, and harness versions.

### A) Code editing — Aider Polyglot
- Leaderboard & methodology: https://aider.chat/docs/leaderboards/ [^aider-polyglot]  
- Run Aider locally with your provider/model keys; compare `gpt‑5‑high`, `gemini‑2.5‑pro`, `claude‑opus‑4.1` variants.

### B) Agentic coding — SWE‑bench Verified
- Background & download: https://openai.com/index/introducing-swe-bench-verified/ [^swebench-verified]  
- Official site: https://www.swebench.com/  
- Use a standard scaffold (e.g., SWE‑agent/mini‑SWE‑agent) and **report single vs multi‑attempt**.

### C) Refactor‑specific suites
- **RefactorBench** (multi‑file, stateful): paper + GitHub. [^refactorbench]  
- **SWE‑Refactor** (1,099 mined Java refactors): paper/Zenodo. [^swe-refactor]  
- These are new: expect low baselines and large variance by agent.

---

## Decision Checklist (Use This to Choose)

1. **Risk profile:** Do you need **OS‑level sandboxing and granular approvals**? → **Codex CLI**. Comfortable with **Plan → gated edit** with strong tests? → **Claude Code**. Want **Google‑native** integrations and **Actions**? → **Gemini CLI**.  
2. **Workload shape:** Mostly **small/medium edits**? All three. **Huge refactors** with tight precision? **Claude Opus 4.1** has best public evidence today. **Repo automation and triage**? **Gemini CLI Actions** are attractive.  
3. **Context requirements:** Very long context / multimodal (screenshots/diagrams)? **Gemini 2.5 Pro** and **GPT‑5** both strong; pick your toolchain.  
4. **Guardrails & governance:** Who approves what? What’s the **rollback**? Are you logging diffs, command traces, and artifacts? Map this to the CLI’s approval model.  
5. **Licensing & infra:** Enterprise needs (SSO, VPC, on‑prem runners) and **where your data lives** (OpenAI, Anthropic, Google Cloud).

---

## Sources & Further Reading

### Official model & benchmark pages
- **Aider LLM Leaderboards** (code editing, incl. Polyglot): https://aider.chat/docs/leaderboards/  — see 2025‑06‑06 run (GPT‑5 High: **88.0%**; Gemini 2.5 Pro Preview 06‑05: **83.1%**). [^aider-polyglot]  
- **Gemini 2.5 Pro** (DeepMind model page): https://deepmind.google/models/gemini/pro/ — includes **Aider Polyglot** and **SWE‑bench Verified** single/multi‑attempt results. [^gemini25]  
- **Gemini 2.5 report (PDF)**: https://storage.googleapis.com/deepmind-media/gemini/gemini_v2_5_report.pdf — documents **Aider Polyglot 82.2%** and **SWE‑bench Verified up to 67.2%** (multi‑attempt). [^gemini25-report]  
- **Claude Opus 4.1** announcement (Aug 5, 2025): https://www.anthropic.com/news/claude-opus-4-1 — **74.5% SWE‑bench Verified**; notes refactor strengths. [^opus41]  
- **SWE‑bench Verified** background (OpenAI): https://openai.com/index/introducing-swe-bench-verified/ — methodology; updates as of 2025‑02‑24. [^swebench-verified]

### CLI/Tool docs
- **Gemini CLI** docs: https://developers.google.com/gemini-code-assist/docs/gemini-cli  •  Repo: https://github.com/google-gemini/gemini-cli  •  MCP servers doc: https://google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html  •  GitHub Actions: Google blog posts. [^gemini-cli-docs] [^gemini-cli-github] [^mcp-docs] [^gemini-cli-actions]  
- **Claude Code** product/docs: https://www.claude.com/product/claude-code  •  Best practices (Plan Mode etc.): https://www.anthropic.com/engineering/claude-code-best-practices  •  Settings: https://docs.claude.com/en/docs/claude-code/settings [^claude-code] [^cc-best] [^cc-settings]  
- **Codex CLI**: Repo: https://github.com/openai/codex  •  CLI docs: https://developers.openai.com/codex/cli/  •  Security (sandbox & approvals): https://developers.openai.com/codex/security/ [^codex-repo] [^codex-docs] [^codex-security]

### Case studies & community signals
- **Rakuten + Claude Code** (7‑hour autonomous refactor; 79% time‑to‑market reduction): https://www.claude.com/customers/rakuten  •  also referenced in Claude 4/4.1 posts and press. [^rakuten]  
- **Gemini CLI GitHub Actions (no‑cost beta)**: Google blogs (Aug 2025) — automation for triage/review. [^gemini-cli-actions]  
- **Zed IDE integration via ACP** (Gemini CLI): AndroidCentral coverage (Aug 28, 2025). [^zed-acp]

### Broader “real‑work” evaluation
- **GDPval v0** (OpenAI): announcement & paper. [^gdpval] [^gdpval-paper]  •  Balanced coverage of model standings (OpenAI & press). [^tech-coverage-gdpval]

### Refactor‑specific research
- **RefactorBench** (Microsoft Research; multi‑file, stateful): paper + Microsoft page + GitHub. [^refactorbench]  
- **SWE‑Refactor** (1,099 mined Java refactors): OpenReview + Zenodo. [^swe-refactor]

---

## FAQ

**Q: If Gemini 2.5 Pro is #2 on Aider Polyglot, why not use it for big refactors?**  
**A:** You can — and many teams do — but **SWE‑bench Verified** (agentic, multi‑file, with tests) and **documented long‑duration autonomy** still most favor **Claude Opus 4.1** today. Gemini’s gains are real (esp. 67.2% multi‑attempt), so the gap is narrowing. Validate on **your codebase** with strong rails (tests, approvals, CI). [^gemini25] [^gemini25-report] [^opus41]

**Q: Where do GPT‑5/GPT‑5‑Codex fit?**  
**A:** **Codex CLI** gives **excellent safety/approvals** and **non‑interactive** runs for batch refactors; **GPT‑5** adds **verbosity + reasoning‑effort** controls that help balance speed vs depth on design/optimization tasks. Use Codex when governance/sandboxing is paramount. [^gpt5-dev] [^codex-docs] [^codex-security]

**Q: Are there neutral, refactor‑only leaderboards?**  
**A:** The space is new. **RefactorBench** and **SWE‑Refactor** are promising but there’s no widely‑accepted, vendor‑neutral head‑to‑head for **GPT‑5 / Opus 4.1 / Gemini 2.5** yet. Expect volatility by scaffold/agent. [^refactorbench] [^swe-refactor]

---

## Notes & Citations

[^aider-polyglot]: **Aider LLM Leaderboards — Polyglot** (latest runs, incl. 2025‑06‑06): https://aider.chat/docs/leaderboards/  
[^gemini25]: **Gemini 2.5 Pro (DeepMind model page)** — includes **Aider Polyglot** and **SWE‑bench Verified** single/multi‑attempt results: https://deepmind.google/models/gemini/pro/  
[^gemini25-report]: **“Gemini 2.5: Pushing the Frontier…”** (DeepMind report, 2025‑06‑16), coding sections inc. **Aider Polyglot 82.2%** and **SWE‑bench Verified up to 67.2%**: https://storage.googleapis.com/deepmind-media/gemini/gemini_v2_5_report.pdf  
[^opus41]: **Anthropic — Claude Opus 4.1 (Aug 5, 2025)** — **74.5% SWE‑bench Verified**; multi‑file refactor improvements: https://www.anthropic.com/news/claude-opus-4-1  
[^rakuten]: **Rakuten + Claude Code** customer story (7‑hour autonomous refactor; 79% time‑to‑market reduction): https://www.claude.com/customers/rakuten  
[^swebench-verified]: **OpenAI — Introducing SWE‑bench Verified** (methodology; updated 2025‑02‑24): https://openai.com/index/introducing-swe-bench-verified/  
[^gpt5]: **OpenAI — Introducing GPT‑5** and dev posts (verbosity/reasoning controls): https://openai.com/index/introducing-gpt-5/ ; https://openai.com/index/introducing-gpt-5-for-developers/  
[^gpt5-dev]: **“Introducing GPT‑5 for developers”** — **verbosity** (`low/medium/high`) and **reasoning_effort** settings exposed in API/SDKs: https://openai.com/index/introducing-gpt-5-for-developers/  
[^codex-repo]: **OpenAI Codex** (open‑sourced CLI/agent): https://github.com/openai/codex  
[^codex-docs]: **Codex CLI docs** (usage, `exec`): https://developers.openai.com/codex/cli/  
[^codex-security]: **Codex security/approvals** (sandbox modes; approval policies): https://developers.openai.com/codex/security/  
[^gemini-cli-docs]: **Gemini CLI | Gemini Code Assist**: https://developers.google.com/gemini-code-assist/docs/gemini-cli  
[^gemini-cli-github]: **google‑gemini/gemini‑cli** (open‑source): https://github.com/google-gemini/gemini-cli  
[^mcp-docs]: **Gemini CLI — MCP servers**: https://google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html  
[^gemini-cli-actions]: **Google Developer Blog / Google Blog — Gemini CLI GitHub Actions (beta)**: https://blog.google/technology/developers/introducing-gemini-cli-github-actions/ ; https://developers.googleblog.com/en/new-in-gemini-code-assist/  
[^gemini-vertex]: **Vertex AI — Gemini 2.5 Pro model page**: https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-5-pro  
[^zed-acp]: **Zed IDE + Gemini CLI integration via ACP** (coverage): https://www.androidcentral.com/apps-software/ai/gemini-cli-zed-code-editor-partnership  
[^gdpval]: **OpenAI — GDPval** announcement page: https://openai.com/index/gdpval/  
[^gdpval-paper]: **GDPval (PDF)**: https://cdn.openai.com/pdf/d5eb7428-c4e9-4a33-bd86-86dd4bcf12ce/GDPval.pdf  
[^tech-coverage-gdpval]: Representative coverage (balanced): TechCrunch, Axios, Fortune, etc. E.g., TechCrunch explainer: https://techcrunch.com/2025/09/25/openai-says-gpt-5-stacks-up-to-humans-in-a-wide-range-of-jobs/ ; Axios brief: https://www.axios.com/2025/09/25/chatgpt-gdp-val-ai-study ; Fortune summary: https://fortune.com/2025/09/30/ai-models-are-already-as-good-as-experts-at-half-of-tasks-a-new-openai-benchmark-gdpval-suggests/  
[^refactorbench]: **RefactorBench** (paper & MSR page & GitHub): arXiv: https://arxiv.org/abs/2503.07832 ; MSR page: https://www.microsoft.com/en-us/research/publication/refactorbench-evaluating-stateful-reasoning-in-language-agents-through-code/ ; GitHub: https://github.com/microsoft/RefactorBench  
[^swe-refactor]: **SWE‑Refactor** (OpenReview + Zenodo): https://openreview.net/forum?id=caPQXR9eeJ ; https://zenodo.org/records/17196850  

---

## Conclusion

- **Everyday coding:** Gemini 2.5 Pro competes head‑on — pick the CLI/UX that best fits your guardrails and workflow.  
- **Large refactors:** Claude Opus 4.1 + Claude Code has the **strongest public track record** today; Gemini and GPT‑5/Codex are viable with the right rails.  
- **System design/optimization:** Choose based on **control surfaces** (approvals/sandboxing), **context length**, and **integration surface** (MCP/Actions/IDE).

> Most teams will see the biggest gains by standardizing **approvals**, **tests**, **PR gates**, and **CI automation** — then slotting any of the three model+CLI stacks into that process.
