# How to Merge Agent Files: A Comprehensive Methodology

## Purpose

This guide provides a systematic methodology for merging two or more agent prompt files into a single, coherent, and comprehensive document. The approach ensures complete preservation of valuable content while eliminating redundancies, fixing inaccuracies, and improving overall structure.

## When to Merge vs. Keep Separate

### Merge When:
- ✅ Files share 50%+ of core concepts and responsibilities
- ✅ Naming creates user confusion (e.g., "real-time systems" vs "realtime systems")
- ✅ Significant overlap in tool usage patterns and workflows
- ✅ Domains are complementary or represent different aspects of the same expertise
- ✅ Practitioners often work across both domains in practice
- ✅ Combined file would be < 3000 lines (manageable size)

### Keep Separate When:
- ❌ Files address fundamentally different domains with minimal overlap (< 20%)
- ❌ Combined file would exceed 3500+ lines (unwieldy)
- ❌ Domains require entirely different tool sets with no shared patterns
- ❌ Clear naming can eliminate confusion (e.g., "frontend" vs "backend")
- ❌ Target audiences are distinct with no crossover use cases

---

## Phase 1: Deep Analysis (30-40% of effort)

### Step 1.1: Structural Comparison

**Create a comparison table** covering:

| Aspect | File A | File B | Notes |
|--------|--------|--------|-------|
| Total lines | [count] | [count] | Size difference |
| Role definition | [summary] | [summary] | Scope clarity |
| Core responsibilities | [# items] | [# items] | Overlap level |
| MCP tools coverage | [list] | [list] | Tool redundancy |
| Workflow patterns | [count] | [count] | Detail level |
| Code examples | [yes/no] | [yes/no] | Example quality |
| Standards/compliance | [if any] | [if any] | Certification needs |
| Deep-dive sections | [topics] | [topics] | Technical depth |

**Tool usage**:
```bash
# Get line counts
wc -l file_a.md file_b.md

# Count major sections
grep -c "^## " file_a.md file_b.md

# Extract section headers for comparison
grep "^## " file_a.md > sections_a.txt
grep "^## " file_b.md > sections_b.txt
```

### Step 1.2: Conceptual Overlap Analysis

**Identify three categories**:

1. **Overlapping Concepts** (need unification):
   - List concepts that appear in both files
   - Note how they differ in treatment/depth
   - Identify which file has superior coverage
   - Example: "Both cover latency management but File B has detailed WCET analysis"

2. **Unique to File A**:
   - List concepts/sections only in File A
   - Mark as critical (must preserve) or nice-to-have
   - Example: "Transport protocol tuning (critical), NUMA tuning (critical)"

3. **Unique to File B**:
   - List concepts/sections only in File B
   - Mark as critical or nice-to-have
   - Example: "Safety certification (critical), ISR patterns (critical)"

**Create overlap matrix**:
```
Concept               | File A | File B | Best Source | Action
----------------------|--------|--------|-------------|--------
Scheduling            | Brief  | Detail | File B      | Use B, add A's distributed context
Lock-free algorithms  | Mention| Deep   | File B      | Use B's detailed workflow
Latency budgeting     | Network| WCET   | Both       | Merge, distinguish contexts
MCP Tools: Sourcegraph| Basic  | Pattern| File B      | Use B's patterns, add A's use cases
```

### Step 1.3: Redundancy Detection

**Search for duplicated content**:

1. **Tool descriptions**:
   - Are MCP tools described in both files?
   - Compare description depth and accuracy
   - Decision: Use most detailed, add unique usage patterns from other

2. **Workflow patterns**:
   - Similar patterns with different detail levels?
   - Decision: Standardize on most detailed format

3. **Principles/guidelines**:
   - Overlapping best practices or principles?
   - Decision: Merge into unified "Fundamental Principles" section

4. **Example invocations**:
   - Similar example types?
   - Decision: Keep all unique examples, group by domain

**Redundancy checklist**:
- [ ] MCP tool descriptions compared
- [ ] Workflow pattern structures analyzed
- [ ] Principles/guidelines consolidated
- [ ] Communication guidelines unified
- [ ] Success metrics merged

### Step 1.4: Accuracy & Quality Audit

**Critical checks**:

1. **Factual accuracy**:
   ```bash
   # Check for outdated model references
   grep -n "GPT-5\|GPT-6\|Claude 4" file_a.md file_b.md

   # Check for deprecated technologies
   grep -n "deprecated\|obsolete\|legacy" file_a.md file_b.md
   ```

2. **Out-of-scope content**:
   - Operational details that don't belong in agent instructions?
   - Tool-specific limitations that are too granular?
   - Example: "Rate limit concerns" might be too operational

3. **Technical inaccuracies**:
   - Incorrect algorithm descriptions?
   - Outdated best practices?
   - Wrong version numbers or specifications?

4. **Scope creep**:
   - Content that belongs in a different agent?
   - "Integration with other agents" sections (may be out of scope)

**Create issues list**:
```markdown
## Critical Issues
1. Line 238: References GPT-5 (doesn't exist) → Fix: Use GPT-4
2. Line 450: RDMA mentioned without context → Fix: Add qualifier "for HFT/HPC"

## Minor Issues
1. Line 125: Redundant with line 87 → Fix: Consolidate
2. Section "Integration with Others" → Decision: Make optional/conditional
```

---

## Phase 2: Unified Structure Design (20-30% of effort)

### Step 2.1: Define Domain Scope

**Create explicit domain classification** (if merging cross-domain files):

```markdown
## Domain Classification & Scope

### Domain A
**When This Agent Applies**:
- [Use case 1]
- [Use case 2]
- [Use case 3]

**Characteristics**:
- Timing scale: [microseconds/milliseconds/seconds]
- Guarantees: [deterministic/statistical]
- Key concerns: [list]
- Infrastructure: [embedded/cloud/hybrid]

### Domain B
[Same structure]

### Cross-Domain Scenarios
**Hybrid Systems** requiring both expertise:
- [Scenario 1]
- [Scenario 2]
```

### Step 2.2: Design Section Hierarchy

**Recommended structure for merged agent files**:

```markdown
1. Role & Purpose (unified, mentions both domains)
2. Domain Classification & Scope (if cross-domain)
3. Core Responsibilities
   3.1 Shared Across Domains
   3.2 Domain A Specific
   3.3 Domain B Specific
4. Available MCP Tools (unified with domain tags)
5. Workflow Patterns (detailed, domain-specific subsections)
6. Fundamental Concepts (shared theory/algorithms)
7. Domain A Deep Dive (unique technical content)
8. Domain B Deep Dive (unique technical content)
9. Common Anti-Patterns (shared + domain-specific)
10. Fundamental Principles (unified)
11. Domain-Specific Standards (if applicable)
12. Communication Guidelines (unified)
13. Example Invocations (grouped by domain)
14. Success Metrics (both domains)
```

**Key principles**:
- ✅ Put shared/fundamental content early (Roles, Responsibilities, Tools)
- ✅ Group domain-specific deep dives together
- ✅ Unify cross-cutting concerns (Principles, Communication, Metrics)
- ✅ Use consistent subsection structure within domain-specific sections

### Step 2.3: MCP Tools Section Strategy

**Decision framework**:

1. **If both files describe same tools**:
   - Use most detailed descriptions as base
   - Add unique usage patterns from other file
   - Create domain-specific subsections within each tool

2. **Template for unified tool description**:
   ```markdown
   ### [Tool Name] MCP ([Primary Purpose])

   **Purpose**: [Unified description covering both domains]

   #### Domain A Usage
   **Key Searches/Operations**:
   - [Pattern 1]
   - [Pattern 2]

   **Search Pattern Library**:
   ```
   [Code examples]
   ```

   #### Domain B Usage
   [Same structure]

   **Shared Usage Strategy**:
   - [Strategy applicable to both]
   ```

3. **For tools unique to one domain**:
   - Place in unified section but clearly mark domain applicability
   - Example: "### Git MCP (Applicable to both domains)"

---

## Phase 3: Content Merge Execution (30-40% of effort)

### Step 3.1: Preparation

**Create working environment**:
```bash
# Create backups
cp file_a.md file_a.md.backup
cp file_b.md file_b.md.backup

# Create content extraction directory
mkdir merge_components
cd merge_components

# Extract sections from both files
grep -A 1000 "^## Role & Purpose" ../file_a.md > role_a.md
grep -A 1000 "^## Role & Purpose" ../file_b.md > role_b.md
# Repeat for all major sections
```

### Step 3.2: Section-by-Section Merge

**For each major section, follow this process**:

#### Role & Purpose
- [ ] Draft unified role statement covering both domains
- [ ] Mention both domain contexts explicitly
- [ ] Keep concise (3-5 paragraphs max)
- [ ] Example: "You are a [Role] with expertise across [Domain A] and [Domain B]"

#### Core Responsibilities
- [ ] List shared responsibilities first (items common to both)
- [ ] Create "Domain A Specific" subsection
- [ ] Create "Domain B Specific" subsection
- [ ] Number items for easy reference
- [ ] Cross-reference where responsibilities overlap

#### MCP Tools (critical section)
- [ ] For each tool, use template from Step 2.3
- [ ] Preserve ALL search patterns from both files
- [ ] Add domain tags to usage examples
- [ ] Consolidate "Usage Strategy" bullets
- [ ] Include code examples from both files

#### Workflow Patterns
- [ ] Standardize on most detailed format (usually step-by-step numbered lists)
- [ ] Expand brief workflows from one file to match detail level of other
- [ ] Add domain-specific workflows from each file
- [ ] Ensure consistent structure:
   ```markdown
   ### Pattern N: [Name]

   **Objective**: [Clear goal statement]

   **Steps**:
   1. [Action with tool reference]
      - [Sub-details]
      - [Expected output]
   2. [Next action]
   ...

   **Success Criteria**:
   - [ ] [Measurable outcome]
   ```

#### Fundamental Concepts
- [ ] Merge overlapping theoretical content
- [ ] Preserve ALL algorithms, formulas, equations
- [ ] Use tables for comparisons (e.g., "Hard vs Soft Real-Time")
- [ ] Include code examples from both files
- [ ] Add cross-references between related concepts

#### Domain Deep Dives
- [ ] Create separate subsections for each domain's unique content
- [ ] Preserve ALL technical depth (don't summarize)
- [ ] Include ALL code examples verbatim
- [ ] Maintain original section structure within each domain
- [ ] Add "Applicable to [Domain]" tags where helpful

#### Anti-Patterns
- [ ] Create "Shared Anti-Patterns" subsection
- [ ] Create domain-specific subsections
- [ ] Preserve ALL code examples
- [ ] Use consistent format:
   ```markdown
   #### N. [Anti-Pattern Name]

   **Problem**: [What goes wrong]

   **Anti-Pattern**:
   ```[language]
   // ❌ BAD
   [code example]
   ```

   **Solution**:
   ```[language]
   // ✅ GOOD
   [code example]
   ```
   ```

#### Principles
- [ ] Merge overlapping principles (eliminate duplication)
- [ ] Preserve unique principles from each file
- [ ] Number all principles for easy reference
- [ ] Keep concise (1-2 sentences per principle)

#### Example Invocations
- [ ] Group by domain or use case type
- [ ] Preserve ALL examples from both files
- [ ] Use consistent format with clear headers
- [ ] Include expected outputs or success criteria

### Step 3.3: Quality Checks During Merge

**After merging each major section**:

- [ ] **Completeness check**: Did I include all content from both source files?
- [ ] **Consistency check**: Is formatting consistent with other sections?
- [ ] **Clarity check**: Is domain applicability clear (if cross-domain)?
- [ ] **Example check**: Are code examples properly formatted and accurate?
- [ ] **Reference check**: Do internal cross-references still work?

**Use grep to verify content inclusion**:
```bash
# Check that key concepts from File A are present
grep -q "key_concept_from_a" merged_file.md && echo "✓ Found" || echo "✗ Missing"

# Check that all code examples were preserved
grep -c "```" file_a.md
grep -c "```" merged_file.md  # Should be >= sum of both files
```

---

## Phase 4: Verification & Refinement (10-20% of effort)

### Step 4.1: Completeness Verification

**Create verification checklist**:

```bash
# Extract all section headers from source files
grep "^##" file_a.md | sort > sections_a_sorted.txt
grep "^##" file_b.md | sort > sections_b_sorted.txt

# For each section in source files, verify presence in merged file
while read section; do
    grep -q "$section" merged_file.md && echo "✓ $section" || echo "✗ MISSING: $section"
done < sections_a_sorted.txt
```

**Content verification matrix**:

| Source | Section | In Merged? | Location | Notes |
|--------|---------|-----------|----------|-------|
| File A | [Section 1] | Yes | Line [X] | Complete |
| File A | [Section 2] | Yes | Line [Y] | Merged with B's version |
| File B | [Section 3] | Yes | Line [Z] | Complete |

### Step 4.2: Accuracy Verification

**Run automated checks**:

```bash
# Check for broken internal references
grep -n "\[.*\](#.*)" merged_file.md | while read line; do
    ref=$(echo "$line" | sed 's/.*](#\(.*\)).*/\1/')
    grep -q "^## $ref\|^### $ref" merged_file.md || echo "Broken reference: $line"
done

# Check for placeholder text
grep -n "TODO\|FIXME\|XXX\|TBD" merged_file.md

# Check for inaccuracies caught during analysis
grep -n "GPT-5\|GPT-6" merged_file.md  # Should return nothing

# Verify code block closure
awk '/^```/ {count++} END {if (count % 2 != 0) print "Unclosed code block!"}' merged_file.md
```

**Manual accuracy checks**:
- [ ] All model names are accurate (GPT-4, Claude 3.5, etc.)
- [ ] All library/framework versions are current
- [ ] All URLs are valid (if any)
- [ ] All code examples are syntactically correct
- [ ] All acronyms are defined on first use

### Step 4.3: Structural Verification

**Check document flow**:
```bash
# Verify section numbering is consistent
grep "^## " merged_file.md | nl

# Check for appropriate section hierarchy
awk '/^#/ {print length($1), $0}' merged_file.md | sort -n

# Verify all major sections are present
required_sections=(
    "Role & Purpose"
    "Core Responsibilities"
    "Available MCP Tools"
    "Workflow Patterns"
    "Example Invocations"
    "Success Metrics"
)

for section in "${required_sections[@]}"; do
    grep -q "^## $section" merged_file.md && echo "✓ $section" || echo "✗ MISSING: $section"
done
```

**Logical flow checklist**:
- [ ] Introduction before details (Role → Responsibilities → Tools)
- [ ] Theory before practice (Concepts → Workflows → Examples)
- [ ] Shared before specific (Common concepts → Domain deep dives)
- [ ] Abstract before concrete (Principles → Anti-patterns with code)

### Step 4.4: Length & Readability Check

**Assess final length**:
```bash
# Line count
wc -l merged_file.md

# Word count
wc -w merged_file.md

# Estimate reading time (250 words/min)
words=$(wc -w < merged_file.md)
echo "Estimated reading time: $((words / 250)) minutes"
```

**Guidelines**:
- ✅ **1500-2500 lines**: Ideal for comprehensive agent (like our merge)
- ⚠️ **2500-3500 lines**: Acceptable but consider if anything can be trimmed
- ❌ **3500+ lines**: Too long, consider splitting or removing tangential content

**Readability checks**:
- [ ] Headers use consistent capitalization
- [ ] Code blocks have language tags (```python, ```c, etc.)
- [ ] Lists use consistent formatting (bullets vs numbers)
- [ ] Tables are properly formatted
- [ ] No paragraphs exceed 10 lines
- [ ] Technical terms defined or linked on first use

### Step 4.5: Domain Clarity Check (if cross-domain merge)

**Verify domain applicability is clear**:

```bash
# Count domain-specific markers
grep -c "Distributed Systems" merged_file.md
grep -c "Embedded Systems" merged_file.md

# Check for ambiguous sections
grep -n "^### " merged_file.md | grep -v "Distributed\|Embedded\|Shared\|Both" | head
```

**Domain clarity checklist**:
- [ ] "Domain Classification & Scope" section present and clear
- [ ] Each workflow pattern indicates applicable domain(s)
- [ ] Domain-specific sections clearly labeled
- [ ] Example invocations grouped by domain
- [ ] Success metrics specify which domain they apply to

---

## Phase 5: Documentation & Handoff

### Step 5.1: Create Summary Report

**Document the merge** in comments at the top of the merged file or in a separate `MERGE_NOTES.md`:

```markdown
# Merge Summary

**Source Files**:
- `file_a.md` (182 lines) - Focused on [Domain A]
- `file_b.md` (951 lines) - Focused on [Domain B]

**Merged File**: `merged_file.md` (2360 lines)

**Merge Date**: [YYYY-MM-DD]

**Key Changes**:
1. **Fixed Inaccuracies**:
   - Line 238, 243: Changed GPT-5 → GPT-4 (doesn't exist)
   - Line 70: Added qualifier for RDMA (HFT/HPC specific)

2. **Structure Improvements**:
   - Added "Domain Classification & Scope" section
   - Unified MCP Tools descriptions (eliminated duplication)
   - Standardized workflow pattern format

3. **Content Additions**:
   - Merged scheduling algorithms from both files
   - Added cross-domain scenarios section
   - Expanded code examples

4. **Content Removed**:
   - Duplicate MCP tool descriptions
   - Redundant principles (consolidated)
   - [Anything else removed]

**Content Preservation**:
- ✅ ALL technical depth from File B preserved
- ✅ ALL distributed systems content from File A preserved
- ✅ ALL code examples from both files included
- ✅ ALL workflow patterns expanded to detailed format
```

### Step 5.2: Create Migration Notes (if replacing existing files)

**If this merge replaces existing agent files**:

```markdown
# Migration Guide

**Old Files** → **New File**:
- `real-time-systems-engineering.md` (DEPRECATED)
- `realtime-systems-specialist.md` (DEPRECATED)
→ `realtime-systems-specialist.md` (NEW, consolidated)

**For Users**:
- Use new consolidated file for both distributed and embedded real-time systems
- Domain applicability clearly marked in "Domain Classification" section
- All previous functionality preserved

**Breaking Changes**: None (fully backward compatible in capabilities)

**Recommended Actions**:
1. Update any references to old files
2. Review new "Domain Classification" section for clarity
3. Bookmark relevant workflow patterns for your use case
```

---

## Common Merge Scenarios & Solutions

### Scenario 1: Different Detail Levels

**Problem**: File A has brief bullet points, File B has detailed workflows.

**Solution**: Standardize on detailed format
- Use File B's detailed structure as template
- Expand File A's brief points into step-by-step workflows
- Add missing details: expected outputs, tool usage, success criteria

### Scenario 2: Conflicting Best Practices

**Problem**: Files recommend different approaches to same problem.

**Solution**: Present both with context
```markdown
### [Problem]: Two Approaches

**Approach 1** (from [Domain A]):
- [Description]
- **When to use**: [Context]
- **Trade-offs**: [Pros/cons]

**Approach 2** (from [Domain B]):
- [Description]
- **When to use**: [Context]
- **Trade-offs**: [Pros/cons]

**Recommendation**: [Guidance on which to choose when]
```

### Scenario 3: Overlapping But Different Terminology

**Problem**: Same concept called different names in each file.

**Solution**: Unify terminology with aliases
```markdown
### [Preferred Term] (also known as [Alternative Term])

[Unified description using preferred term]

**Note**: File A referred to this as "[Term A]", File B as "[Term B]".
We use "[Preferred Term]" for clarity.
```

### Scenario 4: Outdated vs Current Information

**Problem**: Files have conflicting information due to age difference.

**Solution**: Use most current, note deprecation
```markdown
### [Topic]

[Current, accurate information]

**Historical Note**: Earlier versions of this guidance recommended [old approach],
but current best practice is [new approach] due to [reason].
```

### Scenario 5: Missing Cross-References

**Problem**: Merged content creates opportunities for new internal links.

**Solution**: Add cross-references during merge
```markdown
### [Section A]

[Content that relates to Section B]

*See also*: [Section B](#section-b) for related patterns.
```

---

## Quality Metrics for Successful Merges

### Quantitative Metrics

✅ **Completeness**:
- All sections from source files present in merged file
- All code examples preserved
- All technical details intact

✅ **Efficiency**:
- Merged file length ≈ 80-120% of (File A + File B) length
- (If < 80%: possibly missing content; if > 120%: possibly redundant)

✅ **Accuracy**:
- Zero factual errors introduced
- All inaccuracies from source files corrected

### Qualitative Metrics

✅ **Clarity**:
- Domain applicability obvious for all sections
- Consistent terminology throughout
- Logical flow from introduction to examples

✅ **Usability**:
- Easy to find relevant information
- Clear examples for all major concepts
- Actionable guidance (not just theory)

✅ **Maintainability**:
- Consistent structure enables future updates
- Clear section boundaries
- Well-documented merge decisions

---

## Checklist: Complete Merge Process

### Pre-Merge
- [ ] Read both files completely
- [ ] Create structural comparison table
- [ ] Identify overlaps, unique content, redundancies
- [ ] Audit for inaccuracies and out-of-scope content
- [ ] Design unified structure
- [ ] Create backup copies of source files

### During Merge
- [ ] Merge Role & Purpose (unified statement)
- [ ] Create Domain Classification section (if cross-domain)
- [ ] Merge Core Responsibilities (shared + specific)
- [ ] Unify MCP Tools section (preserve all patterns)
- [ ] Merge Workflow Patterns (standardize on detailed format)
- [ ] Merge Fundamental Concepts (preserve all theory)
- [ ] Integrate domain-specific deep dives
- [ ] Consolidate anti-patterns and principles
- [ ] Merge example invocations (group by domain)
- [ ] Unify success metrics

### Post-Merge Verification
- [ ] Completeness: All source content present
- [ ] Accuracy: No errors introduced, inaccuracies fixed
- [ ] Structure: Logical flow, consistent hierarchy
- [ ] Length: Within acceptable range (1500-3500 lines)
- [ ] Clarity: Domain applicability clear throughout
- [ ] Code: All examples properly formatted and correct
- [ ] References: Internal links working
- [ ] Documentation: Merge notes and migration guide created

### Final Steps
- [ ] Run automated verification checks
- [ ] Manual review of critical sections
- [ ] Create summary report
- [ ] Update any external references
- [ ] Archive or deprecate source files (if applicable)

---

## Tools & Commands Reference

### File Analysis
```bash
# Line and word counts
wc -l file.md
wc -w file.md

# Section counting
grep -c "^##" file.md

# Extract all headers
grep "^#" file.md

# Find code blocks
grep -n "^```" file.md
```

### Content Verification
```bash
# Check for specific content
grep -n "keyword" file.md

# Case-insensitive search
grep -in "keyword" file.md

# Count occurrences
grep -c "keyword" file.md

# Check if content exists (silent)
grep -q "keyword" file.md && echo "Found" || echo "Not found"
```

### Structure Validation
```bash
# Verify balanced code blocks
awk '/^```/ {count++} END {print count " code block markers (should be even)"}' file.md

# Check section hierarchy
awk '/^#/ {print length($1), $0}' file.md

# Find potential issues
grep -n "TODO\|FIXME\|XXX\|TBD\|\\[\\]" file.md
```

### Comparison
```bash
# Compare section headers
diff <(grep "^##" file_a.md) <(grep "^##" file_b.md)

# Find common lines
comm -12 <(sort file_a.md) <(sort file_b.md)

# Find unique to each file
comm -23 <(sort file_a.md) <(sort file_b.md)  # Unique to A
comm -13 <(sort file_a.md) <(sort file_b.md)  # Unique to B
```

---

## Final Thoughts

**Merging agent files is an art and a science**. The science is the systematic analysis, verification, and structural design. The art is knowing when to preserve verbatim, when to paraphrase, and when to restructure entirely.

**Key Principles for Successful Merges**:

1. **Preservation First**: When in doubt, preserve content rather than remove
2. **Clarity Always**: Make domain/context applicability explicit
3. **Consistency Matters**: Standardize formats, terminology, structure
4. **Verify Everything**: Assume nothing, check everything
5. **Document Decisions**: Explain why you merged the way you did

**Remember**: The goal is not just to combine files, but to create a **superior unified resource** that serves users better than either source file alone.

---

*This methodology was developed through the successful merge of `real-time-systems-engineering.md` (182 lines) and `realtime-systems-specialist.md` (951 lines) into a comprehensive 2,360-line consolidated agent file.*
