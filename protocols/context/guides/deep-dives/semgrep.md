# Semgrep MCP: Deep Dive

## Overview

AST-aware security/bug/anti-pattern scanning. Local scanning (code never leaves machine). Free community edition with autofix suggestions.

## Available Tools

### 1. `semgrep_scan` - Local Code Scanning

**What it does:** Scans code files using built-in or custom Semgrep rules

**Parameters:**
- `code_files` (required) - Array of dicts with `{path: "absolute_path"}`

**Returns:** Structured findings (file/line, rule ID, severity, message, code snippet)

**Best for:** Security audits, bug detection, code quality checks

**Rate limits:** None (local scanning, free community edition)

### 2. `semgrep_scan_with_custom_rule` - Custom Rule Scanning

**What it does:** Scans code with user-defined YAML rule

**Parameters:**
- `code_files` (required) - Array of dicts with `{path, content}`
- `rule` (required) - Semgrep YAML rule string

**Returns:** Findings matching custom rule

**Best for:** Project-specific patterns, custom anti-patterns, organization standards

**Rate limits:** None

### 3. `semgrep_rule_schema` - Get Rule Schema

**What it does:** Returns schema for writing Semgrep rules

**Parameters:** None

**Returns:** Rule schema with available fields

**Best for:** Learning to write custom rules, verifying rule syntax

**Rate limits:** None

### 4. `get_supported_languages` - List Supported Languages

**What it does:** Returns list of languages Semgrep supports

**Parameters:** None

**Returns:** Supported languages

**Best for:** Checking language support before scanning

**Rate limits:** None

### 5. `get_abstract_syntax_tree` - View AST

**What it does:** Returns Abstract Syntax Tree for code

**Parameters:**
- `code` (required) - Code to parse
- `language` (required) - Programming language

**Returns:** JSON AST representation

**Best for:** Understanding code structure, debugging rules, seeing what parser sees

**Rate limits:** None

<!-- Removed platform-only semgrep_findings for CE-only guide -->

## Tradeoffs

### Advantages
✅ **AST-aware** (understands code structure, not just regex)
✅ **Local scanning** (code never leaves machine)
✅ **Multi-language** (20+ languages)
✅ **Autofix suggestions** (when rules define fixes)
✅ **Custom rules** (code-like pattern syntax)
✅ **Free community edition**
<!-- Supply chain scanning is platform-only; omitted in CE-only guide -->

### Disadvantages
❌ **Not runtime analysis** (static only)
❌ **Community edition limits** (see Semgrep docs for feature comparison)
❌ **False positives** (tune rules to reduce)
❌ **Requires rule knowledge** for custom patterns

## Common Pitfalls: When NOT to Use

### ❌ Runtime Behavior Analysis
**Problem:** Semgrep is static analysis only
**Alternative:** Runtime profiling, dynamic analysis tools

**Example:**
```
Bad:  semgrep for detecting runtime memory leaks
Good: Profiling tools, heap analysis
```

### ❌ Code Style/Formatting
**Problem:** Semgrep for code quality, not formatting
**Alternative:** Prettier, ESLint, Black

**Example:**
```
Bad:  semgrep for indentation issues
Good: prettier / eslint --fix
```

### ❌ Comprehensive Type Checking
**Problem:** Semgrep not a full type checker
**Alternative:** Language-native type checkers

**Example:**
```
Bad:  semgrep for complete type validation
Good: TypeScript compiler, mypy, Go compiler
```

### ❌ Performance Optimization
**Problem:** Semgrep finds patterns, not performance issues
**Alternative:** Profiling, benchmarking tools

**Example:**
```
Bad:  semgrep for finding slow code
Good: Profiler, benchmark tools
```

<!-- Removed platform-only pitfall related to semgrep_findings -->

## When Semgrep IS the Right Choice

✅ **Security audits** (find vulnerabilities)
✅ **Bug detection** (common anti-patterns)
✅ **Code quality checks** (enforce standards)
✅ **Custom rule enforcement** (org-specific patterns)
✅ **Supply chain scanning** (dep vulnerabilities)
✅ **Pre-commit checks** (catch issues early)

**Decision rule:** "Do I need to find security/bug/pattern issues?"

## Usage Patterns

**Basic security scan:**
```
semgrep_scan(
  code_files: [
    {path: "/absolute/path/to/auth.js"},
    {path: "/absolute/path/to/api.py"}
  ]
)
→ Findings with severity, location, fix suggestions
```

**Custom rule scan:**
```
semgrep_scan_with_custom_rule(
  code_files: [{path: "...", content: "..."}],
  rule: """
rules:
  - id: check-hardcoded-secrets
    pattern: |
      password = "..."
    message: Hardcoded password detected
    severity: ERROR
    languages: [python]
"""
)
```

<!-- Removed supply chain usage pattern for CE-only guide -->

**Get AST for rule writing:**
```
get_abstract_syntax_tree(
  code: "function foo() { return bar(); }",
  language: "javascript"
)
→ JSON AST showing parser structure
```

<!-- Removed platform-only historical findings example -->

**Check language support:**
```
get_supported_languages()
→ List of supported languages
```

## Rule Writing Workflow

**1. Understand target pattern:**
```
get_abstract_syntax_tree(code, language)
→ See how parser views code
```

**2. Get rule schema:**
```
semgrep_rule_schema()
→ Available fields for rules
```

**3. Write custom rule:**
```yaml
rules:
  - id: my-custom-check
    pattern: |
      dangerous_function(...)
    message: "Avoid dangerous_function"
    severity: WARNING
    languages: [python]
    fix: safe_function(...)
```

**4. Test rule:**
```
semgrep_scan_with_custom_rule(
  code_files: [...],
  rule: "..." # Custom YAML
)
```

## Best Practices

**When to scan:**
- **Pre-commit:** Scan changed files
- **Post-dependency-update:** Supply chain scan
- **Security review:** Full repo scan
- **CI/CD:** Automated scanning

**Severity triage:**
- Critical/High: Address immediately
- Medium: Plan fixes
- Low/Info: Backlog or suppress

**Custom rules:**
- Start with semgrep registry (existing rules)
- Write org-specific patterns
- Include autofix when possible
- Test on sample code first

**Supply chain:**
- Scan after any dependency change
- Check lockfile updates
- Review transitive dependencies

<!-- Removed platform-only findings management guidance -->

## Integration Workflows

**Security review workflow:**
```
1. semgrep_scan(all_files) → Find issues
2. Review findings by severity
3. Apply autofix suggestions
4. semgrep_scan(fixed_files) → Verify fixes
```

**Custom pattern enforcement:**
```
1. semgrep_rule_schema() → Learn schema
2. get_abstract_syntax_tree() → Understand patterns
3. Write custom rule (YAML)
4. semgrep_scan_with_custom_rule() → Test
5. Add to CI/CD
```

<!-- Removed dependency security workflow (supply chain) -->

## Alternatives Summary

| Task | Instead of Semgrep | Use This |
|------|--------------------|----------|
| Runtime analysis | semgrep | Profiling tools |
| Formatting | semgrep | Prettier, ESLint |
| Type checking | semgrep | Language type checkers |
| Performance | semgrep | Profilers, benchmarks |
<!-- Removed platform-only alternatives row -->

## Quick Reference

**Rate limits:** None (local CE scans)
**Best for:** Security, bugs, anti-patterns
**Avoid for:** Runtime, formatting, types, performance

**Languages:** 20+ (check with get_supported_languages)
**Rule types:** Built-in registry + custom YAML
**Autofix:** Available when rules define fixes

**Links:**
- [Semgrep Pro vs OSS features](https://semgrep.dev/docs/semgrep-pro-vs-oss)
- [Full decision guide](../../../tools/tools-decision-guide.md)

## Local Reporting (CE)

Use the Semgrep CE CLI to export results for local reporting dashboards:

```
# JSON output
semgrep scan --json --json-output=semgrep.json

# SARIF output (for code scanning integrations)
semgrep scan --sarif --sarif-output=semgrep.sarif

# Plain text output
semgrep scan --text --text-output=semgrep.txt

# Combine outputs (prints SARIF to stdout, writes JSON to file)
semgrep scan --sarif --json-output=findings.json
```

Tip: You can mix formats with --output/--<format>-output to produce multiple files in one run.
