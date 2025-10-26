# How to Merge Agent Files: A Comprehensive Methodology

## Purpose

This guide provides a systematic methodology for merging two or more agent prompt files into a single, coherent document that is **concise, readable, and complete**. The key principle: **preserve all critical content while trusting that brief is good enough**.

## When to Merge vs. Keep Separate

### Merge When:
- ✅ Files share 50%+ of core concepts and responsibilities
- ✅ Naming creates user confusion (e.g., "real-time systems" vs "realtime systems")
- ✅ Significant overlap in tool usage patterns and workflows
- ✅ Domains are complementary or represent different aspects of the same expertise
- ✅ Practitioners often work across both domains in practice
- ✅ **Merged result would be 400-800 lines (readable at one sitting)**

### Keep Separate When:
- ❌ Files address fundamentally different domains with minimal overlap (< 20%)
- ❌ Domains require entirely different tool sets with no shared patterns
- ❌ Clear naming can eliminate confusion (e.g., "frontend" vs "backend")
- ❌ Target audiences are distinct with no crossover use cases

---

## Phase 1: Deep Analysis (30-40% of effort)

### Step 1.1: Structural Comparison

**Create a comparison table**:

| Aspect | File A | File B | Notes |
|--------|--------|--------|-------|
| Total lines | [count] | [count] | Size difference |
| Role definition | [summary] | [summary] | Scope clarity |
| Core responsibilities | [# items] | [# items] | Overlap level |
| MCP tools coverage | [list] | [list] | Tool redundancy |
| Workflow patterns | [count] | [count] | Detail level |
| Code examples | [yes/no] | [yes/no] | Quality (not quantity) |

**Tool usage**:
```bash
# Get line counts
wc -l file_a.md file_b.md

# Count major sections
grep -c "^## " file_a.md file_b.md

# Extract section headers
grep "^## " file_a.md > sections_a.txt
grep "^## " file_b.md > sections_b.txt
```

### Step 1.2: Conceptual Overlap Analysis

**Identify three categories**:

1. **Overlapping Concepts** (need unification, NOT duplication):
   - List concepts that appear in both files
   - Identify which file has superior coverage
   - **Critical**: You will UNIFY these, not duplicate with "Domain A Context" and "Domain B Context" subsections

2. **Unique to File A** (mark as critical or nice-to-have):
   - Only preserve critical content
   - Nice-to-have content should be omitted unless it's truly valuable

3. **Unique to File B** (mark as critical or nice-to-have):
   - Only preserve critical content
   - Omit tangential or overly detailed explanations

**Create overlap matrix**:
```
Concept               | File A | File B | Best Source | Action
----------------------|--------|--------|-------------|--------
Scheduling            | Brief  | Detail | File B      | Use B's concise explanation, add A's context as 1-liner
Lock-free algorithms  | Mention| Deep   | File B      | Use B's pattern, skip redundant explanation
MCP Tools: Sourcegraph| Basic  | Pattern| File B      | Merge into single unified section with domain tags
```

### Step 1.3: Bloat Detection & Redundancy Check

**Critical bloat patterns to identify**:

1. **Duplicate explanations with domain subsections**:
   - ❌ BAD: "### Distributed Usage... ### Embedded Usage..." (doubles content)
   - ✅ GOOD: Unified explanation with inline domain tags

2. **Verbose templates**:
   - ❌ BAD: Every tool has "Purpose, Key Tools, Usage Strategy, Example Queries, When to Use" subsections
   - ✅ GOOD: "**Purpose**: [one line]. **Usage**: [key points]"

3. **Over-elaborated workflows**:
   - ❌ BAD: Each step has 3-5 sub-bullets with examples and expected outputs
   - ✅ GOOD: Numbered steps with essential information only

4. **Redundant "Usage Strategy" sections**:
   - Often repeats information already in "Key Patterns" or "Purpose"
   - Omit if not adding new information

5. **Excessive code scaffolding**:
   - ❌ BAD: Setup code, teardown code, extensive comments around every example
   - ✅ GOOD: Minimal code showing the essential pattern

**Redundancy checklist**:
- [ ] MCP tool descriptions compared (will merge, not duplicate)
- [ ] Workflow patterns analyzed (will use concise format)
- [ ] Principles consolidated (no redundant explanations)
- [ ] Code examples reviewed (keep minimal, essential only)

### Step 1.4: Accuracy & Quality Audit

**Critical checks**:

1. **Factual accuracy**:
   ```bash
   # Check for outdated model references
   grep -n "GPT-5\|GPT-6\|Claude 4" file_a.md file_b.md

   # Check for deprecated technologies
   grep -n "deprecated\|obsolete\|legacy" file_a.md file_b.md
   ```

2. **Out-of-scope content** (candidates for removal):
   - Operational details that don't belong in agent instructions
   - Tool-specific limitations that are too granular
   - "Integration with other agents" sections (often out of scope)
   - Rate limit concerns (too operational)

3. **Scope creep detection**:
   - Content that belongs in a different agent?
   - Tangential examples that don't serve the core purpose?

**Create issues list**:
```markdown
## Critical Issues
1. Line 238: References GPT-5 (doesn't exist) → Fix: Use GPT-4
2. Line 450: RDMA mentioned without context → Fix: Add qualifier "for HFT/HPC"

## Bloat to Remove
1. Section "Integration with Others" → Remove (out of scope)
2. Lines 200-250: Verbose MCP tool template → Condense to 10 lines
3. Workflow patterns have excessive sub-bullets → Trim to essential steps
```

---

## Phase 2: Unified Structure Design (20-30% of effort)

### Step 2.1: Define Domain Scope (Concisely)

**For cross-domain merges, use this CONCISE format**:

```markdown
## Domain Scope

**Domain A**: [Use cases]. [Characteristics: timing, guarantees, concerns].

**Domain B**: [Use cases]. [Characteristics: timing, guarantees, concerns].

**Hybrid**: [Cross-domain scenarios].
```

**Do NOT expand into**:
- ❌ Separate ### subsections for each domain
- ❌ Bulleted lists with 5+ items per domain
- ❌ Detailed "Characteristics" subsections with 5 bullets each

**Keep it to 3-5 lines per domain maximum.**

### Step 2.2: Design Section Hierarchy

**Recommended structure**:

```markdown
1. Role & Purpose (2-3 paragraphs max)
2. Domain Scope (3-5 lines per domain)
3. Core Responsibilities
   - Shared (numbered list)
   - Domain A Specific (numbered list)
   - Domain B Specific (numbered list)
4. Available MCP Tools (concise, unified)
5. Workflow Patterns (numbered steps, minimal sub-bullets)
6. Fundamentals (key concepts only)
7. Anti-Patterns (code examples, keep brief)
8. Domain-Specific Details (if needed, keep short)
9. Principles (numbered list)
10. Communication Guidelines (bullet list)
11. Example Invocations (grouped by domain)
12. Success Metrics (bullet list per domain)
```

**Key principle**: Flat is better than nested. Avoid deep subsection hierarchies.

### Step 2.3: MCP Tools Section Strategy (CRITICAL - Avoid Bloat)

**Bloat anti-pattern to AVOID**:
```markdown
### Sourcegraph MCP (Critical Path Discovery)

**Purpose**: [Paragraph explaining purpose in detail]

#### Distributed Systems Usage

**Key Searches**:
- [Search 1 with explanation]
- [Search 2 with explanation]
- [etc]

**Search Pattern Library**:
```
[Code block with patterns that duplicate Key Searches]
```

**Usage Strategy**:
- [Bullet 1 repeating information from above]
- [Bullet 2 repeating information from above]
- [etc]

#### Embedded Systems Usage

[Same verbose structure repeated]

**Usage Strategy**:
[More repeated information]
```

**Concise format to USE**:
```markdown
### Sourcegraph MCP

**Purpose**: [One sentence].

**Key Patterns**:
```
# Domain A: [pattern]
# Domain B: [pattern]
```

**Usage**: [Brief bullets only if adding new info]
```

**Guidelines**:
- ✅ Merge domain-specific usage into single section with inline tags
- ✅ Use code blocks with comments to distinguish domains
- ✅ Eliminate "Usage Strategy" if it repeats "Purpose" or "Key Patterns"
- ✅ Keep total per tool to 15-30 lines max (not 50-70 lines)

### Step 2.4: Workflow Pattern Format (Trust Brief)

**Bloat anti-pattern to AVOID**:
```markdown
### Pattern 1: Distributed Latency Analysis

**Objective**: [Detailed paragraph]

**Steps**:
1. **Establish end-to-end latency budget** from SLOs
   - Decompose into per-hop budgets (e.g., 10ms total = 2ms producer + 3ms transport + 4ms processing + 1ms response)
   - Document P50, P90, P99, and max targets for each hop
   - Create spreadsheet tracking budget allocation
   - [More sub-bullets]
2. **Use Sourcegraph** to map critical path:
   - Identify entry points, message producers, consumers, handlers
   - Trace data flow through serialization, transport, deserialization
   - Find queue handoffs and async boundaries
   - Document call graph with latency annotations
   - [More sub-bullets]
[etc - 8 steps with 3-5 sub-bullets each = 100+ lines]
```

**Concise format to USE**:
```markdown
### Pattern 1: Distributed Latency Analysis

1. Establish per-hop latency budget from SLOs
2. Use Sourcegraph to map critical path (producer → transport → consumer)
3. Instrument with distributed tracing (P50/P90/P99 per hop)
4. Identify bottlenecks: serialization, network, queues, locks, GC
5. Use Semgrep to detect blocking in async code
6. Prototype under load, compare metrics
7. Stage with feature flags, monitor for regression
8. Document in Qdrant
```

**Guidelines**:
- ✅ Numbered steps without sub-bullets (or minimal sub-bullets)
- ✅ Each step is one line when possible
- ✅ Trust the reader to understand details from context
- ✅ Target 8-15 lines per workflow, not 50-100 lines
- ❌ Don't add "Objective" if the title is clear
- ❌ Don't add "Success Criteria" unless truly necessary
- ❌ Don't elaborate examples in sub-bullets

---

## Phase 3: Content Merge Execution (30-40% of effort)

### Step 3.1: Role & Purpose (Keep Concise)

**Template**:
```markdown
## Role & Purpose

You are a **[Role]** with expertise across [N] domains:

1. **Domain A**: [One-line description]
2. **Domain B**: [One-line description]

You excel at [key skills - one sentence].
```

**Target**: 2-3 paragraphs maximum (10-15 lines)

**Avoid**:
- ❌ Elaborating on each domain with multiple paragraphs
- ❌ Repeating information that will appear in "Domain Scope"

### Step 3.2: Core Responsibilities (Numbered Lists)

**Format**:
```markdown
## Core Responsibilities

### Shared
1. **[Responsibility]**: [Brief description]
2. **[Responsibility]**: [Brief description]
[etc]

### Domain A Specific
7. **[Responsibility]**: [Brief description]
[etc]

### Domain B Specific
10. **[Responsibility]**: [Brief description]
[etc]
```

**Guidelines**:
- ✅ Each responsibility is one line
- ✅ Number continuously across subsections
- ❌ Don't expand into paragraphs
- ❌ Don't add examples or elaboration

### Step 3.3: MCP Tools (Unified, Concise)

**For each tool**:

1. Read both source files' descriptions
2. Write one-sentence "Purpose"
3. **Merge domain-specific patterns** into single code block with inline comments
4. Add "Usage" bullets ONLY if they add new information not in patterns
5. Keep total to 15-30 lines per tool

**Example**:
```markdown
### Context7 MCP

**Purpose**: Get framework/protocol documentation.

**Topics**:
- Domain A: [List 3-5 topics]
- Domain B: [List 3-5 topics]

**Usage**: [2-3 bullets max]
```

**Total for all 9 tools**: Target 100-150 lines (not 400+ lines)

### Step 3.4: Workflow Patterns (Trust Brief)

**For each workflow**:

1. Identify if one source has the pattern, or both
2. If both have it, choose the more concise version as base
3. **Do NOT expand** brief bullet points into multi-level sub-bullets
4. Use numbered steps (8-15 per workflow)
5. Each step should be one line when possible

**Avoid**:
- ❌ Sub-bullets explaining what each step does
- ❌ "Expected output" or "Example" subsections
- ❌ Repeating tool names with full explanations (just say "Use Sourcegraph")

**Total for 5-6 workflows**: Target 60-100 lines (not 300+ lines)

### Step 3.5: Fundamentals (Essential Theory Only)

**Include**:
- ✅ Key algorithms with formulas (RMS, EDF)
- ✅ Critical comparisons (hard vs soft RT) in table format
- ✅ Essential definitions (2-3 sentences each)

**Exclude**:
- ❌ Extensive code examples (save for Anti-Patterns section)
- ❌ Detailed derivations or proofs
- ❌ Redundant explanations of concepts covered elsewhere

**Example format**:
```markdown
### Scheduling Algorithms

**Rate Monotonic (RMS)**: Static priority by period. Schedulable if U ≤ n(2^(1/n) - 1). Optimal for fixed-priority.

**EDF**: Dynamic priority by deadline. Schedulable if U ≤ 1.0. Higher utilization than RMS, more overhead.

**PIP**: Low-priority holding mutex inherits priority of blocked high-priority. Prevents inversion.
```

**Target for entire Fundamentals section**: 60-100 lines (not 200-400 lines)

### Step 3.6: Anti-Patterns (Code + Brief Explanation)

**Format per anti-pattern**:
```markdown
### N. [Pattern Name]

**Problem**: [One sentence].

**Solution**: [One sentence or brief code example].

```[language]
// ❌ BAD: [minimal bad example]

// ✅ GOOD: [minimal good example]
```
```

**Guidelines**:
- ✅ Keep code examples to 3-10 lines each
- ✅ Focus on the essential difference
- ❌ Don't add extensive setup/teardown code
- ❌ Don't explain what the code does line-by-line (trust the reader)

**Target for 7-10 anti-patterns**: 80-120 lines (not 300+ lines)

### Step 3.7: Domain-Specific Details (Minimal)

**Only include if truly unique** and not covered in earlier sections.

**Format**:
```markdown
### Domain A: [Topic]

**[Subtopic]**: [Brief description with key details]

**[Subtopic]**: [Brief description with key details]
```

**Example**:
```markdown
### Distributed: Transport & Serialization

**TCP Tuning**: `TCP_NODELAY`, buffer sizes, BBR congestion control.

**QUIC**: 0-RTT resumption, multiplexing without head-of-line blocking.

**Serialization**: FlatBuffers/Cap'n Proto (zero-copy), Protocol Buffers (compact), ensure bounded sizes.
```

**Target for domain details**: 30-60 lines total (not 150+ lines)

### Step 3.8: Example Invocations (Grouped, Concise)

**Format**:
```markdown
## Example Invocations

**Domain A**: "[Concise request with key requirements]"

**Domain B**: "[Concise request with key requirements]"

**Cross-domain**: "[Hybrid scenario]"
```

**Guidelines**:
- ✅ Each example is 1-3 sentences
- ❌ Don't elaborate with multiple paragraphs
- ❌ Don't include expected outputs (trust the reader)

**Target**: 20-40 lines for 5-8 examples (not 100+ lines)

---

## Phase 4: Verification & Refinement (10-20% of effort)

### Step 4.1: Length Verification (Critical)

**Target merged length**: **40-60% of combined source files**

```bash
# Calculate target range
total=$(($(wc -l < file_a.md) + $(wc -l < file_b.md)))
min=$((total * 40 / 100))
max=$((total * 60 / 100))

echo "Source files: $total lines"
echo "Target range: $min - $max lines"

# Check merged file
merged=$(wc -l < merged_file.md)
echo "Merged file: $merged lines"

if [ $merged -gt $max ]; then
    echo "⚠️ WARNING: Merged file is too long! Look for bloat."
fi
```

**If merged file exceeds 60% of combined length**:
- 🚨 You likely have bloat - review for verbose templates, duplicated domain sections, over-elaborated workflows

**If merged file is less than 30% of combined length**:
- ⚠️ May be missing critical content - verify completeness

**Sweet spot**: 40-50% of combined length (true merge, not accumulation)

**Example**:
- Source A: 182 lines
- Source B: 951 lines
- Combined: 1,133 lines
- **Target: 450-680 lines** (40-60%)
- **Actual good result: 447 lines** (39% - acceptable, concise and complete)
- **Bloated first attempt: 2,360 lines** (208% - massive over-elaboration)

### Step 4.2: Bloat Pattern Detection

**Run these checks on merged file**:

```bash
# Check for verbose subsections
grep -n "^#### " merged_file.md | wc -l
# If > 20 subsections, you likely have over-nested structure

# Check for repeated "Usage Strategy" sections
grep -c "Usage Strategy" merged_file.md
# Should be 0-2, not 9+ (one per tool)

# Check average workflow pattern length
awk '/^### Pattern [0-9]/{p=1; count++; lines=0; next} p && /^###/{p=0; total+=lines} p{lines++} END{print total/count " lines per workflow"}' merged_file.md
# Should be 10-20 lines, not 50-100 lines

# Check for domain duplication
grep -c "#### Distributed.*Usage\|#### Embedded.*Usage" merged_file.md
# Should be 0 (unified format) not 18+ (duplicated)
```

### Step 4.3: Completeness Verification

**Verify all critical content present**:

```bash
# Create content checklist from source files
echo "## Critical Content Checklist" > checklist.txt

# Extract unique responsibilities
grep "^\*\*.*:\*\*" file_a.md file_b.md | sort -u >> checklist.txt

# For each critical item, verify in merged file
while read item; do
    grep -q "$item" merged_file.md && echo "✓ $item" || echo "✗ MISSING: $item"
done < checklist.txt
```

**Manual checks**:
- [ ] All core responsibilities present
- [ ] All MCP tools covered
- [ ] Key algorithms/formulas preserved
- [ ] Essential code examples included
- [ ] Domain-specific critical content preserved

### Step 4.4: Quality Checks

**Verify conciseness without loss**:
- [ ] Each section serves a purpose (no filler)
- [ ] Code examples are minimal but complete
- [ ] No redundant explanations between sections
- [ ] Cross-references work (if any)
- [ ] No "TODO" or placeholder text

**Readability checks**:
- [ ] Headers use consistent capitalization
- [ ] Code blocks have language tags
- [ ] Tables are properly formatted
- [ ] No paragraphs exceed 8 lines
- [ ] Lists are formatted consistently

---

## Phase 5: Documentation & Handoff

### Step 5.1: Create Merge Summary

```markdown
# Merge Summary

**Source Files**:
- `file_a.md` ([X] lines) - Focused on [Domain A]
- `file_b.md` ([Y] lines) - Focused on [Domain B]

**Merged File**: `merged_file.md` ([Z] lines = [%] of combined)

**Key Changes**:
1. **Fixed Inaccuracies**: [List]
2. **Eliminated Bloat**:
   - Unified domain-specific subsections → inline tags
   - Condensed verbose MCP tool templates → concise format
   - Trimmed workflow patterns → essential steps only
3. **Content Preserved**: All critical content retained

**Size Comparison**:
- Source total: [X+Y] lines
- Merged: [Z] lines ([%] of source)
- Target was: 40-60% ✓ or ✗
```

---

## Critical Anti-Patterns to Avoid

### 1. Domain Duplication Bloat ❌

**DON'T DO THIS**:
```markdown
### Tool Name

#### Distributed Systems Usage
[Full explanation]
[Patterns]
**Usage Strategy**: [Bullets]

#### Embedded Systems Usage
[Full explanation - often 80% same as above]
[Patterns]
**Usage Strategy**: [Bullets repeating information]
```

**DO THIS INSTEAD** ✅:
```markdown
### Tool Name

**Purpose**: [One sentence for both domains].

**Key Patterns**:
```
# Distributed: [pattern]
# Embedded: [pattern]
```

**Usage**: [Unified bullets, domain-tagged if needed]
```

**Impact**: Reduces 60-80 lines to 15-20 lines without loss.

### 2. Verbose Workflow Elaboration ❌

**DON'T DO THIS**:
```markdown
1. **Establish latency budget** from SLOs
   - Decompose into per-hop budgets
   - Example: 10ms total = 2ms producer + 3ms transport + 4ms processing + 1ms response
   - Document P50, P90, P99, and max targets for each hop
   - Create spreadsheet or dashboard tracking allocations
   - Review with stakeholders for approval
```

**DO THIS INSTEAD** ✅:
```markdown
1. Establish per-hop latency budget from SLOs
```

**Impact**: Trust the reader knows or can infer details. 1 line vs 6 lines per step.

### 3. Redundant "Usage Strategy" Sections ❌

**DON'T DO THIS**:
```markdown
**Purpose**: Search code for patterns.

**Key Patterns**:
```
"pattern1"
"pattern2"
```

**Usage Strategy**:
- Use pattern1 to find X
- Use pattern2 to find Y
- Compare results across files
```

**DO THIS INSTEAD** ✅:
```markdown
**Purpose**: Search code for patterns.

**Key Patterns**:
```
"pattern1"  # Finds X
"pattern2"  # Finds Y
```
```

**Impact**: Eliminate section that just repeats pattern purpose in different words.

### 4. Over-Scaffolded Code Examples ❌

**DON'T DO THIS**:
```c
// Initialize system components
initializeHardware();
configureInterrupts();

// ❌ BAD: Dynamic allocation in ISR
void ISR_Handler(void) {
    // Allocating memory at runtime
    uint8_t *buffer = malloc(256);

    // Process data
    processData(buffer);

    // Clean up
    free(buffer);
}

// Proper cleanup and system shutdown
shutdownHardware();
```

**DO THIS INSTEAD** ✅:
```c
// ❌ NEVER in ISR
void ISR_Handler(void) {
    uint8_t *buf = malloc(256);  // FORBIDDEN
}

// ✅ Use pre-allocated pool or static buffer
```

**Impact**: 3-5 lines vs 15+ lines. Reader understands the point without scaffolding.

### 5. Excessive "Objective" and "Success Criteria" ❌

**DON'T DO THIS**:
```markdown
### Pattern 3: Lock-Free Implementation

**Objective**: Implement deterministic shared data access without locks to eliminate contention and ensure predictable performance in both distributed and embedded real-time systems.

[Workflow steps]

**Success Criteria**:
- ✓ No data races detected by sanitizers
- ✓ Deterministic performance under contention
- ✓ Progress guarantees documented
- ✓ Test coverage > 95%
- ✓ Benchmark results show improvement over mutex-based approach
```

**DO THIS INSTEAD** ✅:
```markdown
### Pattern 3: Lock-Free Implementation

[Workflow steps]
```

**Impact**: Title is self-explanatory. Success criteria are obvious. Save 8-10 lines.

---

## Quality Metrics for Successful Merges

### Quantitative Metrics

✅ **Conciseness**: Merged file is **40-60% of combined source length**
- Below 30%: Possibly missing content
- 40-50%: Ideal (true merge, well-consolidated)
- 60-80%: Acceptable but check for bloat
- Above 80%: Almost certainly has bloat

✅ **Section Length Targets**:
- MCP Tools: 100-150 lines total (not 400+)
- Workflow Patterns: 60-100 lines total (not 300+)
- Anti-Patterns: 80-120 lines (not 300+)
- Fundamentals: 60-100 lines (not 200+)
- Domain Details: 30-60 lines (not 150+)

✅ **Completeness**: All critical content from source files present

✅ **Accuracy**: Zero factual errors introduced, all inaccuracies fixed

### Qualitative Metrics

✅ **Clarity**: Domain applicability obvious, consistent terminology

✅ **Usability**: Easy to find information, actionable guidance

✅ **Trust**: Brief explanations without over-elaboration

✅ **Maintainability**: Flat structure, consistent format, easy to update

---

## Checklist: Complete Merge Process

### Pre-Merge
- [ ] Read both files completely
- [ ] Create structural comparison table
- [ ] Identify overlaps (will unify), unique content (will preserve if critical)
- [ ] Detect bloat patterns in source files
- [ ] Audit for inaccuracies and out-of-scope content
- [ ] Set target length: 40-60% of combined
- [ ] Create backup copies

### During Merge - Apply Conciseness Principles
- [ ] Role & Purpose: 2-3 paragraphs max
- [ ] Domain Scope: 3-5 lines per domain
- [ ] Core Responsibilities: Numbered lists, one line each
- [ ] MCP Tools: Unified format, 15-30 lines per tool
- [ ] Workflow Patterns: Numbered steps, minimal sub-bullets
- [ ] Fundamentals: Essential theory only
- [ ] Anti-Patterns: Brief code examples
- [ ] Domain Details: Only if truly unique
- [ ] Example Invocations: 1-3 sentences each

### During Merge - Avoid These Mistakes
- [ ] ❌ No domain duplication with separate subsections
- [ ] ❌ No verbose workflow elaboration with multi-level bullets
- [ ] ❌ No redundant "Usage Strategy" sections
- [ ] ❌ No over-scaffolded code examples
- [ ] ❌ No unnecessary "Objective" or "Success Criteria"
- [ ] ❌ No deep subsection nesting (#### and beyond)

### Post-Merge Verification
- [ ] Length check: 40-60% of combined ✓
- [ ] Bloat pattern detection (subsection count, repeated sections)
- [ ] Completeness: All critical content present
- [ ] Accuracy: No errors, inaccuracies fixed
- [ ] Quality: Concise, readable, actionable
- [ ] Create merge summary documenting size and changes

---

## Tools & Commands Reference

### File Analysis
```bash
# Line and word counts
wc -l file.md

# Count major sections
grep -c "^## " file.md

# Extract all headers
grep "^#" file.md

# Check for bloat: subsection count
grep -c "^#### " file.md  # Should be minimal
```

### Content Verification
```bash
# Check for specific content
grep -n "keyword" file.md

# Count occurrences
grep -c "keyword" file.md

# Verify content exists
grep -q "keyword" file.md && echo "Found" || echo "Not found"
```

### Length & Bloat Checks
```bash
# Calculate target length
total=$(($(wc -l < file_a.md) + $(wc -l < file_b.md)))
echo "Target: $((total * 40 / 100)) - $((total * 60 / 100)) lines"

# Check merged length
wc -l merged_file.md

# Detect domain duplication bloat
grep -c "#### Distributed.*Usage\|#### Embedded.*Usage" merged_file.md

# Detect redundant sections
grep -c "Usage Strategy" merged_file.md
```

---

## Final Thoughts

**The core principle**: **Trust that brief is good enough.**

**Common mistakes that lead to bloat**:
1. **Being too conservative**: Trying to keep everything from both files verbatim
2. **Adding unnecessary structure**: Creating verbose templates for every section
3. **Not trusting the reader**: Over-explaining what can be inferred from context
4. **Duplicating instead of merging**: Separate "Domain A" and "Domain B" subsections instead of unified format

**The goal** is not just to combine files, but to create a **superior unified resource** that is:
- **Concise**: Respects the reader's time
- **Complete**: Preserves all critical content
- **Readable**: Can be consumed in one sitting (400-800 lines)
- **Actionable**: Provides clear, brief guidance

**Remember**: If your merged file is larger than 60% of the combined source files, you have bloat. Go back and apply these principles more aggressively.

---

*This methodology was refined through real-world application, where an initial bloated merge of 2,360 lines (208% of source) was successfully trimmed to 447 lines (39% of source) while preserving 100% of critical content.*
