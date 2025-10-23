# Useful workflows: turning vague asks into repeatable searches

Actionable command recipes paired with equivalent MCP tool calls. Use these to convert vague phrases into concrete evidence (file:line hits) you can attach to PRs, specs, reviews, and postmortems.

## How to read and use

- Each recipe includes a ripgrep command and one or more MCP equivalents.

- Prefer MCP calls when you want structured results, cross‑repo search, or rules that run in CI.

- Add `--hidden --no-ignore -g '!**/.git/**' -g '!**/node_modules/**'` to ripgrep commands if needed.

## Tool selection quick guide

| Tool | Best for | Inputs | Outputs |
| --- | --- | --- | --- |
| Serena MCP | Workspace regex and semantic search; code and docs; later structural edits | `substring_pattern`, path globs, context lines | Matched lines with context; symbol refs (when supported) |
| Sourcegraph MCP | Cross‑repo discovery; language/file filters; shareable queries | Sourcegraph query string | File/line matches across public repos |
| Semgrep MCP | Enforceable, repeatable checks; policy as code | Rule YAML and target paths | Structured findings with rule id, severity, file:line |

## Recipes

- Entry points touching a domain (for example, “billing”)
    
    - ripgrep
        
        - `rg -n -i -P '\b(handler|controller|router|route|endpoint|consumer|producer|cron|cli)\w*\b.*\b(billing|payment)s?\b'`
    
    - Serena MCP
        
        - `serena.search_for_pattern`
        - substring_pattern: `\b(handler|controller|router|route|endpoint|consumer|producer|cron|cli)\w*\b.*\b(billing|payment)s?\b`
        - restrict_search_to_code_files: `false`
        - paths_include_glob: `**/*`
        - context_lines_before: `1`
        - context_lines_after: `1`
    
    - Sourcegraph MCP
        
        - query: `(
          \bhandler|\bcontroller|\brouter|\broute|\bendpoint|\bconsumer|\bproducer|\bcron|\bcli
          )\w*\s+.*\b(billing|payments?)\b`

- Two‑phase: entrypoints → domain usage
    
    - ripgrep
        
        - `rg -n -i -P '\b(handler|controller|router|route|endpoint|main)\b' --files-with-matches | xargs rg -n -i 'billing|payments'`
    
    - Serena MCP
        
        - Step 1: `serena.search_for_pattern` with substring_pattern: `\b(handler|controller|router|route|endpoint|main)\b`
        - Step 2: for each matched file, call `serena.search_for_pattern` with relative_path set to that file and substring_pattern: `billing|payments`

- Bypass and skip flags (policy/auth/validation bypasses)
    
    - ripgrep
        
        - `rg -n -i -P '\b(skip|bypass|ignore|disable|force)\w*\b' --glob '!**/test/**'`
    
    - Serena MCP
        
        - substring_pattern: `\b(skip|bypass|ignore|disable|force)\w*\b`
        - paths_exclude_glob: `**/test/**`
        - restrict_search_to_code_files: `false`
    
    - Semgrep MCP (custom rule)
        
        - rule id: `bypass-toggles`
        - languages: `[generic]`
        - pattern: `/(skip|bypass|ignore|disable|force)\w*/`
        - message: `Potential bypass/skip flag; verify it is not reachable in production paths`
        - severity: `WARNING`

- Direct SQL writes that may bypass validators
    
    - ripgrep
        
        - `rg -n -i -P '\b(INSERT|UPDATE|DELETE|MERGE)\b\s' --glob '!**/migrations/**'`
    
    - Serena MCP
        
        - substring_pattern: `\b(INSERT|UPDATE|DELETE|MERGE)\b\s`
        - paths_exclude_glob: `**/migrations/**`
    
    - Semgrep MCP (custom rule)
        
        - rule id: `direct-sql-write`
        - languages: `[generic]`
        - pattern: `/\b(INSERT|UPDATE|DELETE|MERGE)\b/`
        - message: `Direct SQL write; confirm validators/transactions and that this is not bypassing domain logic`
        - severity: `WARNING`

- Feature flags and gates (and missing lifecycle hints)
    
    - ripgrep
        
        - `rg -n -i -P '\b(feature[_-]?flag|flag|toggle|gate)\w*\b'`
    
    - Serena MCP
        
        - substring_pattern: `\b(feature[_-]?flag|flag|toggle|gate)\w*\b`
    
    - Sourcegraph MCP (flags missing owner/expiry)
        
        - query: `(feature[_-]?flag|toggle|gate) -owner -expiry -sunset`

- Policy enforcement points (authz/compliance hooks)
    
    - ripgrep
        
        - `rg -n -i -P '\b(policy|authorize|permission|entitle|rbac|abac|scope)s?\b'`
    
    - Serena MCP
        
        - substring_pattern: `\b(policy|authorize|permission|entitle|rbac|abac|scope)s?\b`

- Deprecations and user‑facing annotations
    
    - ripgrep
        
        - `rg -n -i -P '\b(@deprecated|deprecated|\\[Obsolete\\])\b'`
    
    - Serena MCP
        
        - substring_pattern: `\b(@deprecated|deprecated|\[Obsolete\])\b`
    
    - Sourcegraph MCP
        
        - query: `(@deprecated|deprecated|\[Obsolete\])`

- Acceptance criteria breadcrumbs in tests (GIVEN/WHEN/THEN)
    
    - ripgrep
        
        - `rg -n -i -P '\b(GIVEN|WHEN|THEN)\b' --glob '**/*test*.*'`
    
    - Serena MCP
        
        - substring_pattern: `\b(GIVEN|WHEN|THEN)\b`
        - paths_include_glob: `**/*test*.*`

- Incidents and postmortems in docs
    
    - ripgrep
        
        - `rg -n -i -P '\b(postmortem|post-mortem|rca|incident\s+report)\b' docs/`
    
    - Serena MCP
        
        - relative_path: `docs/`
        - substring_pattern: `\b(postmortem|post-mortem|rca|incident\s+report)\b`
        - restrict_search_to_code_files: `false`

- High‑leverage “pivotal” files by common names
    
    - ripgrep
        
        - `rg -n -i -P '\b(router|routes|schema|policy|config|handler|gateway|orchestrator)\w*\b' --stats`
    
    - Sourcegraph MCP
        
        - query: `file:(?i)(router|routes|schema|policy|config|handler|gateway|orchestrator)`

- Call‑site impact for a symbol (for example, `OldAPI.DoThing`)
    
    - ripgrep
        
        - `FUNC='OldAPI\\.DoThing'; rg -n -P "$FUNC" --glob '!**/test/**'`
    
    - Serena MCP (symbol references where supported)
        
        - `serena.find_referencing_symbols`
        - name_path: `OldAPI/DoThing`
        - relative_path: `path/to/file/defining/OldAPI`
    
    - Sourcegraph MCP
        
        - query: `OldAPI.DoThing -file:test`

## Notes and best practices

- Start broad, then tighten patterns; keep a scratchpad of proven queries for your codebase.

- Save MCP queries and Semgrep rules alongside runbooks so they can run in CI or as pre‑merge checks.

- Treat repeated searches as automation candidates: turn them into Semgrep rules or add them to Serena‑powered review checklists.

