# Serena MCP: Deep Dive

## Overview

Language-server-powered semantic code navigation, refactoring, and editing. IDE-grade symbol operations across 20+ languages. Complements Filesystem/Git MCP with semantic-level understanding.

## Available Tools

### Symbol Navigation

**1. `find_symbol` - Locate Symbols**

**What it does:** Finds symbols (classes, methods, functions) by name path

**Parameters:**
- `name_path` (required) - Pattern like "class/method" or "/class/method"
- `relative_path` (optional) - Restrict to file/directory
- `depth` (default 0) - Retrieve descendants (1 for class methods/attributes)
- `include_body` (default false) - Include source code
- `substring_matching` (default false) - Match partial names
- `include_kinds` / `exclude_kinds` - Filter by LSP symbol kinds

**Name path matching:**
- `"method"` → Matches anywhere (class/method, nested/class/method, etc.)
- `"class/method"` → Matches ancestors (class/method, nested/class/method)
- `"/class/method"` → Absolute (only top-level class/method)

**Returns:** Symbols with locations (and optionally bodies)

**Best for:** Finding symbols, understanding structure

### Symbol References

**2. `find_referencing_symbols` - Find References**

**What it does:** Finds all references to a symbol

**Parameters:**
- `name_path` (required) - Symbol to find references for
- `relative_path` (required) - File containing the symbol
- `include_kinds` / `exclude_kinds`
- `max_answer_chars`

**Returns:** Symbols referencing the target with code snippets

**Best for:** Understanding dependencies, impact analysis

### File Overview

**3. `get_symbols_overview` - High-Level Structure**

**What it does:** Returns top-level symbols in a file

**Parameters:**
- `relative_path` (required) - File to analyze
- `max_answer_chars` (default -1)

**Returns:** Top-level symbols (classes, functions, etc.)

**Best for:** First look at new file, quick structure understanding

### Editing Tools

**4. `replace_symbol_body` - Replace Implementation**

**What it does:** Replaces symbol's body (implementation)

**Parameters:**
- `name_path` (required) - Symbol to replace
- `relative_path` (required) - File containing symbol
- `body` (required) - New implementation (includes signature)

**Returns:** Confirmation

**Best for:** Swapping implementations, refactoring logic

**CRITICAL:** Body INCLUDES signature, NOT just function content

**5. `insert_after_symbol` - Insert After**

**What it does:** Inserts content after symbol definition

**Parameters:**
- `name_path` (required)
- `relative_path` (required)
- `body` (required) - Content to insert

**Returns:** Confirmation

**Best for:** Adding new methods, functions, classes

**6. `insert_before_symbol` - Insert Before**

**What it does:** Inserts content before symbol definition

**Parameters:**
- `name_path` (required)
- `relative_path` (required)
- `body` (required) - Content to insert

**Returns:** Confirmation

**Best for:** Adding imports, new symbols before existing

**7. `rename_symbol` - Rename Across Codebase**

**What it does:** Renames symbol and all references

**Parameters:**
- `name_path` (required)
- `relative_path` (required)
- `new_name` (required)

**Returns:** Result summary

**Best for:** Safe refactoring, renaming with reference updates

**Note:** For overloaded methods (Java), may need signature in name_path

### Text-Based Editing

**8. `replace_regex` - Regex-Based Replacement**

**What it does:** Replaces regex matches in file

**Parameters:**
- `relative_path` (required)
- `regex` (required) - Python regex (dot matches newlines, multiline enabled)
- `repl` (required) - Replacement string (supports \\1, \\2 backreferences)
- `allow_multiple_occurrences` (default false) - Replace all matches

**Returns:** Confirmation

**Best for:** Small edits within symbols, text replacements

**CRITICAL:** Use wildcards! Minimize regex length!

### Other Tools

**9. `search_for_pattern` - Flexible Code Search**

**What it does:** Searches for regex patterns in files

**Parameters:**
- `substring_pattern` (required) - Regex to search
- `relative_path` (default "") - Restrict to file/directory
- `restrict_search_to_code_files` (default false)
- `paths_include_glob` / `paths_exclude_glob`
- `context_lines_before` / `context_lines_after`
- `max_answer_chars`

**Returns:** Matches with context lines

**Best for:** Finding patterns when symbol search insufficient

**10. `read_file` - Read File Content**

**What it does:** Reads file (potentially chunked)

**Parameters:**
- `relative_path` (required)
- `start_line` (optional, 0-based) - First line index to read
- `end_line` (optional, 0-based, inclusive) - Last line index to read
- `max_answer_chars`

**Returns:** File content text (line numbers not guaranteed)

**Best for:** Reading after finding symbols

**11. `create_text_file` - Write New File**

**What it does:** Creates or overwrites file

**Parameters:**
- `relative_path` (required)
- `content` (required)

**Returns:** Confirmation

**Best for:** Creating new files

**12. `list_dir` / `find_file` - File System Operations**

Standard directory listing and file search operations.

### Memory & Project Tools

**13-16. Memory operations**: write_memory, read_memory, list_memories, delete_memory

**17. execute_shell_command** - Run commands safely

**18-19. activate_project, switch_modes** - Project/mode management

**20-22. Thinking tools** - think_about_task_adherence, think_about_collected_information, think_about_whether_you_are_done

## Tradeoffs

### Advantages
✅ **Semantic understanding** (not just text)
✅ **IDE-grade operations** (symbol-aware)
✅ **Safe refactoring** (rename updates references)
✅ **20+ languages** (Python, TypeScript, Go, Rust, Java, etc.)
✅ **LSP-powered** (uses language servers)
✅ **Symbol-level edits** (precise, not whole-file)

### Disadvantages
❌ **Learning curve** (name paths, symbol concepts)
❌ **Requires language server** (downloads as needed)
❌ **Not for simple text** (use Filesystem MCP or built-ins)
❌ **Complex for small edits** (regex tool better for few lines)

## Common Pitfalls: When NOT to Use

### ❌ Simple Text Replacements
**Problem:** Symbol tools overkill for text edits
**Alternative:** Built-in Edit or Filesystem edit_file

**Example:**
```
Bad:  find_symbol + replace_symbol_body for one-line change
Good: Edit tool (string replacement)
```

### ❌ Whole-File Reads
**Problem:** Serena read_file adds overhead
**Alternative:** Built-in Read tool

**Example:**
```
Bad:  serena.read_file for basic file reading
Good: Read (built-in, optimized)
```

### ❌ Non-Code Files
**Problem:** Symbol operations require code structure
**Alternative:** Filesystem or built-in tools

**Example:**
```
Bad:  find_symbol in JSON/YAML/Markdown
Good: Read or Grep for non-code files
```

### ❌ Keyword Search (Not Symbols)
**Problem:** Symbol search requires knowing symbol names
**Alternative:** Grep for content search

**Example:**
```
Bad:  find_symbol for finding TODO comments
Good: Grep("TODO:", glob="**/*.js")
```

### ❌ Without Knowing Structure First
**Problem:** Using symbol tools blindly
**Alternative:** get_symbols_overview first

**Example:**
```
Bad:  find_symbol without knowing class/method structure
Good: get_symbols_overview → understand structure → find_symbol
```

## When Serena IS the Right Choice

✅ **Semantic refactoring** (rename, restructure)
✅ **Symbol-level operations** (find, edit methods/classes)
✅ **Understanding code structure**
✅ **Finding references** (who calls this?)
✅ **Safe renames** across codebase

**Decision rule:** "Do I need semantic understanding of code?"

## Usage Patterns

**Understand new file:**
```
1. get_symbols_overview("src/auth.ts")
   → See top-level classes, functions

2. find_symbol("UserService", depth=1)
   → Get methods of UserService class

3. find_symbol("UserService/authenticate", include_body=true)
   → Read specific method
```

**Refactor symbol:**
```
1. find_symbol("UserService/authenticate", include_body=true)
   → Get current implementation

2. replace_symbol_body(
     name_path="UserService/authenticate",
     relative_path="src/auth.ts",
     body="async authenticate(username, password) { ... }"
   )
   → Replace implementation (includes signature!)
```

**Add new method:**
```
insert_after_symbol(
  name_path="UserService/authenticate",
  relative_path="src/auth.ts",
  body="\n  async logout(userId) {\n    ...\n  }\n"
)
→ Inserts inside the UserService class, immediately after authenticate()
```

**Rename safely:**
```
rename_symbol(
  name_path="getUserData",
  relative_path="src/api.ts",
  new_name="fetchUserProfile"
)
→ Renames function and all references codebase-wide
```

**Find who uses a function:**
```
find_referencing_symbols(
  name_path="authenticate",
  relative_path="src/auth.ts"
)
→ All places that call authenticate()
```

**Small edit with regex:**
```
replace_regex(
  relative_path="src/config.ts",
  regex="PORT.*=.*5000",
  repl="PORT = 3000"
)
→ Change port number
```

## Symbol vs Regex Editing

**Use symbol tools when:**
- Replacing entire method/class/function
- Adding new symbols (methods, functions, classes)
- Renaming symbols codebase-wide

**Use regex tool when:**
- Editing few lines within symbol
- Text replacements smaller than symbol
- Pattern-based small changes

**Example comparison:**
```
Task: Change one line in 50-line method

Symbol approach:
  find_symbol(include_body=true) → Read 50 lines
  replace_symbol_body → Write all 50 lines back

Regex approach (better):
  replace_regex("old line", "new line")
  → Target just the changed line
```

## Best Practices

**Exploration pattern:**
```
1. get_symbols_overview (high-level)
2. find_symbol with depth=0 (symbol metadata)
3. find_symbol with depth=1 (children)
4. find_symbol with include_body=true (implementation)
```

**Name path usage:**
- Simple: `"method"` → Matches anywhere
- Relative: `"class/method"` → Requires ancestors
- Absolute: `"/class/method"` → Top-level only
- Substring: Add `substring_matching=true`

**Minimize reads:**
- Don't read bodies unless needed
- Use depth wisely (0 for metadata, 1 for children)
- Read structure first, implementations later

**Editing strategy:**
- Symbol-level: Use symbol tools
- Line-level: Use replace_regex
- Multi-file rename: Use rename_symbol
- Verify with find_referencing_symbols

**Regex best practices:**
```
✅ Use wildcards: "start.*?end"
❌ Write long regexes: "line1\nline2\nline3..."
✅ Minimal matches with context
❌ Matching entire sections verbatim
```

## Alternatives Summary

| Task | Instead of Serena | Use This |
|------|------------------|----------|
| Simple text replace | replace_symbol_body | Edit (built-in) |
| Whole-file read | read_file | Read (built-in) |
| Non-code files | symbol tools | Read / Grep |
| Keyword search | find_symbol | Grep |
| Without structure | find_symbol | get_symbols_overview first |

## Quick Reference

**Rate limits:** None (local language servers)
**Languages:** 20+ (Python, TS, Go, Rust, Java, C++, etc.)
**Best for:** Semantic refactoring, symbol operations
**Avoid for:** Simple text edits, non-code files, keyword search

**Symbol kinds (LSP):**
1=file, 2=module, 3=namespace, 4=package, 5=class, 6=method, 7=property, 8=field, 9=constructor, 10=enum, 11=interface, 12=function, 13=variable, 14=constant, etc.

**Name path patterns:**
- `"name"` → anywhere
- `"parent/name"` → with ancestors
- `"/top/name"` → absolute (top-level)

**Critical reminders:**
- replace_symbol_body: Body INCLUDES signature
- replace_regex: Use wildcards (minimize length)
- Always get_symbols_overview first for new files

**Links:**
- [Category guide: Code search](../category/code-search.md)
- [Full decision guide](../../../tools/tools-decision-guide.md)
