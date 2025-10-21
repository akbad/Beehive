# CLI Tools to Add to Agent Stack

Essential command-line tools that brilliantly complement the MCP server suite.

---

## Recommended stack

| Tool | Priority | Why Add It | Complements |
|------|----------|-----------|-------------|
| **ast-grep** | 🔥 Must have | Structural code refactoring | Semgrep MCP (security) |
| **just** | 🔥 Must have | Task automation | GitHub SpecKit (specs) |
| **jq** (+yq) | 🔥 Must have | JSON/YAML processing | All web MCPs |
| **lazygit** | ⭐ Highly recommended | Visual git UI | Git MCP |
| **httpie/xh** | ⭐ Highly recommended | API testing | Fetch/Firecrawl MCP |
| **delta** | ⭐ Highly recommended | Better git diffs | Git MCP |
| **bat** | Nice to have | Syntax-highlighted file viewing | Filesystem MCP |
| **fd** | Nice to have | Fast file finding | Filesystem MCP |

---

## Quick install

```bash
# Install via Homebrew (macOS/Linux)
brew install ast-grep just jq yq lazygit git-delta bat fd ripgrep httpie

# Or via Cargo (Rust - works everywhere)
cargo install ast-grep just git-delta bat fd-find ripgrep xh
```

---

## Tier 1: Essential additions (must have)

### ast-grep

**What it is:** AST-based structural code search and refactoring tool

**Why it's brilliant for your stack:**

- **Complements Semgrep perfectly**: Semgrep = security/bugs, ast-grep = refactoring/code patterns
- **Language-agnostic**: 20+ languages (JavaScript, TypeScript, Rust, Go, Python, etc.)
- **Pattern-based search**: Write code patterns to find code (not regex)
- **Automated refactoring**: Can rewrite code structurally
- **Works with your Filesystem MCP**: Agents can use ast-grep to find patterns, then Filesystem MCP to read/edit

**Install:** `cargo install ast-grep` (Rust) or `brew install ast-grep`

**Use cases for agents:**

- "Find all React components using deprecated lifecycle methods"
- "Refactor all `var` declarations to `const`/`let`"
- "Find all functions with more than 5 parameters"
- Structural code migrations

**Links:**

- [Website](https://ast-grep.github.io/)
- [GitHub](https://github.com/ast-grep/ast-grep)

**Note:** There's an ast-grep MCP server available, but the CLI tool is often faster for one-off searches

---

### just

**What it is:** Modern command runner and task automation tool

**Why it's brilliant for your stack:**

- **Better than Make**: Simpler syntax, better error messages, cross-platform
- **Perfect for project automation**: Build, test, deploy workflows
- **Complements GitHub SpecKit**: SpecKit defines *what* to build, just defines *how* to build it
- **Agents can read justfiles**: Simple YAML-like syntax that LLMs understand easily

**Install:** `cargo install just` or `brew install just`

**Use cases for agents:**

- Standardized project task runners across multiple projects
- "Run the test suite" → `just test`
- "Build the Docker image" → `just docker-build`
- Self-documenting project commands

**Example justfile:**
```just
# Run tests
test:
    cargo test
    npm test

# Build for production
build:
    npm run build
    cargo build --release

# Run all checks
ci: test lint build
```

**Links:**

- [GitHub](https://github.com/casey/just)
- [Docs](https://just.systems/)

---

### jq

**What it is:** Command-line JSON processor

**Why it's brilliant for your stack:**

- **Essential for API work**: Parse/filter/transform JSON from APIs
- **Complements web MCPs**: Process data fetched by Firecrawl/Tavily/Fetch MCP
- **Universal**: Works with any JSON data
- **Powerful querying**: Like SQL for JSON

**Install:** `brew install jq` or via package managers

**Companion tool:** **yq** (same for YAML/XML) - `brew install yq`

**Use cases for agents:**

- Parse API responses: `curl api.com | jq '.data.items[0]'`
- Extract config values from package.json
- Transform JSON data between formats
- Filter large JSON datasets

**Example:**
```bash
# Extract specific field
echo '{"name": "John", "age": 30}' | jq '.name'
# Output: "John"

# Filter array
echo '[{"id":1,"active":true},{"id":2,"active":false}]' | jq '.[] | select(.active)'
# Output: {"id":1,"active":true}
```

**Links:**

- [Website](https://jqlang.github.io/jq/)
- [GitHub](https://github.com/jqlang/jq)

---

## Tier 2: Highly recommended

### lazygit

**What it is:** Terminal UI for git commands

**Why it's brilliant for your stack:**

- **Visual complement to Git MCP**: See diffs, branches, commits visually
- **Interactive staging**: Easier than `git add -p`
- **Better for learning**: Agents can explain git concepts by showing lazygit UI
- **Fast workflows**: Keyboard-driven, no mouse needed

**Install:** `brew install lazygit` or via package managers

**Use cases for agents:**

- "Show me a visual diff of my changes" → screenshot lazygit
- Interactive conflict resolution
- Visual branch management
- Commit history exploration

**Links:**

- [GitHub](https://github.com/jesseduffield/lazygit)

**Note:** Works alongside Git MCP (use MCP for automation, lazygit for exploration)

---

### httpie / xh

**What it is:** Human-friendly HTTP client (modern curl alternative)

**Why it's brilliant for your stack:**

- **Better than curl**: Cleaner syntax, automatic JSON formatting, colored output
- **Complements Fetch/Firecrawl MCP**: Quick API testing before automating
- **Session support**: Save auth tokens, headers
- **xh is Rust rewrite**: Faster, single binary, curl-compatible

**Install:**

- httpie: `brew install httpie` or `pip install httpie`
- xh (Rust): `cargo install xh` or `brew install xh`

**Use cases for agents:**

- Quick API endpoint testing
- Debug API calls before writing code
- Generate curl commands for documentation

**Example:**
```bash
# httpie syntax
http POST api.com/users name=John email=john@example.com

# xh syntax (same)
xh post api.com/users name=John email=john@example.com

# With authentication
http GET api.com/protected Authorization:"Bearer token123"
```

**Links:**

- [httpie](https://httpie.io/)
- [xh GitHub](https://github.com/ducaale/xh)

---

### delta

**What it is:** Syntax-highlighting pager for git diffs

**Why it's brilliant for your stack:**

- **Better git diffs**: Syntax highlighting, line numbers, side-by-side view
- **Complements Git MCP**: Makes diff output more readable for agents
- **Language-aware**: Highlights based on file type

**Install:** `brew install git-delta` or `cargo install git-delta`

**Configuration:** Add to `~/.gitconfig`:

```ini
[core]
    pager = delta

[delta]
    features = side-by-side line-numbers decorations
    syntax-theme = Monokai Extended

[interactive]
    diffFilter = delta --color-only
```

**Use cases for agents:**

- Better code review workflows
- Easier to explain changes to users
- Screenshot-friendly diffs

**Links:**

- [GitHub](https://github.com/dandavison/delta)

---

## Tier 3: Nice to have (modern Unix tools)

### bat

**What it is:** `cat` with syntax highlighting and git integration

**Why it's good:**

- Syntax highlighting for file viewing
- Shows git modifications in margin
- Complements Filesystem MCP read operations
- Paging support (auto-pages long files)

**Install:** `brew install bat` or `cargo install bat`

**Example:**

```bash
# View file with syntax highlighting
bat src/main.rs

# View multiple files
bat src/*.js

# Show git diff in margin
bat --diff src/app.ts
```

**Links:**

- [GitHub](https://github.com/sharkdp/bat)

---

### fd

**What it is:** Fast, user-friendly `find` alternative

**Why it's good:**

- Simpler syntax than `find`
- Respects `.gitignore` by default
- Parallel search (extremely fast)
- Colored output

**Install:** `brew install fd` or `cargo install fd-find`

**Use cases:**

```bash
# Find all TypeScript files
fd -e ts

# Find all test files
fd test

# Find in specific directory
fd pattern src/

# Execute command on results
fd -e js -x prettier --write
```

**Links:**

- [GitHub](https://github.com/sharkdp/fd)

---

### ripgrep (rg)

**Status:** ✅ Already in your setup as a dependency

**What it is:** Fast, recursive grep alternative

**Why it's essential:**

- Extremely fast (parallelized search)
- Respects `.gitignore`
- Better than grep for code search
- Required by Claude Code

**Install:** `brew install ripgrep` or `cargo install ripgrep`

**Links:**

- [GitHub](https://github.com/BurntSushi/ripgrep)

---

## Why these tools?

1. **Fill gaps**: Each tool covers something your MCPs don't handle well
2. **Agent-friendly**: Simple syntax that LLMs can learn and use
3. **Cross-platform**: Work on macOS/Linux/Windows
4. **Fast**: Rust-based tools are incredibly fast
5. **Actively maintained**: All have strong communities
6. **Composable**: Work great with your existing MCP stack

---

## Tool relationships

**Code analysis stack:**

- Semgrep MCP → Security/bug detection
- ast-grep → Structural search/refactoring
- ripgrep → Fast text search
- fd → Fast file finding

**Git stack:**

- Git MCP → Automation
- lazygit → Visual exploration
- delta → Beautiful diffs

**Data processing stack:**

- jq → JSON processing
- yq → YAML/XML processing
- All web MCPs → Fetch data

**File operations:**

- Filesystem MCP → Read/write/edit
- bat → View with syntax highlighting
- fd → Find files

**API/web stack:**

- Fetch/Firecrawl/Tavily MCP → Automated fetching
- httpie/xh → Interactive testing

**Task running:**

- GitHub SpecKit → Define what to build
- just → Define how to build it
