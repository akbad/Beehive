# Code search tools: comparison & usage guides

## Quick selection table

| Tool | Best For | Scope | When to Use | Strengths |
|------|----------|-------|-------------|-----------|
| **Sourcegraph** | Public repo search | Public open-source code (sourcegraph.com); private via Sourcegraph instance | Find code examples/patterns | Regex (RE2), language, file path, revision; Deep Search |
| **Serena** | Local semantic ops | Your codebase | Refactor, navigate symbols | LSP-powered, 20+ langs |
| **Grep / ripgrep (rg)** | Fast text search | Local files | Known pattern, simple search | Very fast, glob/type filters (rg), context lines |

## Tool usage guides

### Sourcegraph (primary for public code)

**What it does:** "Google for code" across public open-source repositories on sourcegraph.com; also supports private repositories when you run a Sourcegraph instance (self-hosted or cloud) and connect your repos.

**Strengths:**
- Powerful filters: regex (RE2), language, file path, revision (`repo@rev` or `rev:`)
- Deep Search (agentic, natural language → precise queries)
- Returns exact code snippets with line numbers
- Controls for exhaustive/large searches: `count:` and `timeout:`; use `src-cli` for very large result sets

**Common Patterns:**
```
repo:github\.com/facebook/react file:\.tsx$ useState
lang:python "async def.*request"
file:Dockerfile EXPOSE
"func SendMessage" lang:go
```

**Deep Search (guided):**
- Ask natural-language questions (e.g., "find all HTTP client 5s timeouts")
- Converts to precise queries and iterates to refine
- Outputs relevant matches and reasoning

**Examples:**
```
Find React hooks usage → repo:react file:\.tsx$ use.*Hook
Find Go HTTP servers → lang:go "http.Server{"
Find Dockerfile patterns → file:Dockerfile FROM.*alpine
```

**When to use:**
- Learning how libraries/APIs are used in practice
- Finding real-world implementations
- Discovering algorithms/patterns
- Researching best practices

**Limitations:**
- On sourcegraph.com you search public code; private code search requires running a Sourcegraph instance and connecting your private repos (plan-dependent)
- Interactive searches are subject to time and match limits; the web UI displays up to 500 results; use `count:all`, `timeout:`, and/or `src-cli` for exhaustive results

**Supports many code hosts for private repos:** GitHub, GitLab, Bitbucket, Azure DevOps, Perforce, and more (when connected to your Sourcegraph instance).

### Serena (primary for local code)

**What it does:** Language-server-powered semantic navigation/refactoring

**Strengths:**
- IDE-grade symbol understanding (functions, classes, methods)
- Symbol-level operations (not whole-file)
- Find references across codebase
- Rename with all references updated
- 20+ languages (Python, TypeScript, Go, Rust, Java, etc.)
- Local, no rate limits

**Key Tools:**
- `find_symbol` - Locate by name/path
- `find_referencing_symbols` - Who calls this?
- `rename_symbol` - Refactor safely
- `insert_after_symbol` / `insert_before_symbol` - Precise insertion
- `replace_symbol_body` - Swap implementation

**Examples:**
```
find_symbol("UserService/authenticate") → find method
find_referencing_symbols → see all callers
rename_symbol("getUserData" → "fetchUserProfile")
replace_symbol_body → swap implementation
```

**When to use:**
- Refactoring operations
- Understanding code structure
- Finding all usages of symbol
- Safe renames across codebase
- Structural edits (not text replacement)

**When NOT to use:** Simple text find/replace (use Grep/Edit)

### CLI text search (ripgrep `rg` and `grep`)

**What it does:** Fast text/regex search in local files.

**Strengths:**
- ripgrep (`rg`): very fast; respects `.gitignore`; supports glob filters (`-g/--glob`) and file type filters (`-t/--type`, see `rg --type-list`); context lines (`-A/-B/-C`)
- GNU `grep`: ubiquitous; supports recursive search (`-R`), include/exclude globs, and context lines (`-A/-B/-C`)

**Regex notes:**
- `grep` uses POSIX BRE/ERE by default; PCRE features (e.g., `\w`, lookarounds, lazy quantifiers) require GNU grep with `-P` and are not available in BSD/macOS `grep` by default.
- `rg` uses Rust regex (no lookaround) by default; many builds also support PCRE2 via `-P` for advanced regex features.

**ripgrep examples:**
```
# Find Python service classes
rg -n -t py 'class \w+Service'

# Find TODOs under src/
rg -n 'TODO' -g 'src/**'

# Find API calls like fetch(…api
rg -n 'fetch\(.*api'

# Find PORT assignments in .env files
rg -n -g '*.env' '^PORT=.*'
```

**grep (GNU) equivalents:**
```
# Find Python service classes
grep -R -n -E 'class [[:alnum:]_]+Service' --include='*.py' .

# Find TODOs under src/
grep -R -n 'TODO' --include='*' src/

# Find API calls like fetch(…api
grep -R -n -E 'fetch\(.*api' .

# Find PORT assignments in .env files
grep -R -n -E '^PORT=.*' --include='*.env' .
```

**When to use:**
- Known pattern, simple search
- Text-based find (not semantic)
- Quick lookups, strings/comments

**When NOT to use:** Need semantic understanding or refactoring (use Serena)

## Decision tree

```
Need code search?
    ↓
Public repos or local?
├─ PUBLIC → Sourcegraph
│           (unlimited, real-world examples)
└─ LOCAL → Need semantic understanding?
    ├─ YES → Serena
    │        (symbols, refactoring, references)
    └─ NO → Grep
             (fast text/regex search)

Refactoring needed?
    └─ Use Serena (safe, aware of references)

Find usage examples?
    └─ Use Sourcegraph (public repos)

Simple text search?
    └─ Use Grep (instant, no overhead)
```

## Comparison: when to use each

**Use Sourcegraph when:**
- Need examples from public repos
- Learning library usage
- Researching patterns/algorithms
- Want to see real-world code

**Use Serena when:**
- Working in your codebase
- Refactoring operations
- Need symbol-level understanding
- Finding/updating references
- Structural code changes

**Use Grep when:**
- Simple text/pattern search
- Known string to find
- Quick lookups
- Searching comments/strings
- No semantic analysis needed

## Best practices

**Start with appropriate scope:**
- Public examples? → Sourcegraph
- Local refactor? → Serena
- Quick find? → Grep

**Leverage strengths:**
- Sourcegraph: Use guided search for complex queries
- Serena: Use for any operation involving symbols
- Grep: Use for speed, text patterns

**Avoid common mistakes:**
- ❌ Using Grep for refactoring (use Serena)
- ❌ Using Serena for simple text search (use Grep)
- ❌ Not using Sourcegraph guided prompts

## Common use cases

**Finding implementation patterns:**
→ Sourcegraph (`repo:.*react.* useEffect`)

**Renaming function across codebase:**
→ Serena (`rename_symbol`)

**Finding TODOs/FIXMEs:**
→ Grep (`pattern:"TODO|FIXME"`)

**Understanding symbol relationships:**
→ Serena (`find_referencing_symbols`)

**Learning API usage:**
→ Sourcegraph (`lang:python requests.post`)

## Links to deep dives

- [Sourcegraph deep dive](../mcp-deep-dives/sourcegraph.md)
- [Serena deep dive](../mcp-deep-dives/serena.md)
