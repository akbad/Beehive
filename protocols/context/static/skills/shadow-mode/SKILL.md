---
description: Propose-only editing with inverted control flow where agent proposes changes as diffs and human applies manually. Activate when user says "SHADOW MODE ON", "propose don't apply", "show me the diffs", "I'll apply manually", or "don't touch my files". Supports 5 output formats (unified diff, side-by-side, contextual, git patch, step-by-step instructions) and 4 granularity levels. Verifies correct application before proceeding. Ideal for learning, maximum transparency, or untrusted environments.
---

# Shadow Mode: *protocol*

> <ins>***Goal:** agent proposes, human applies—inverted control*</ins>
>
> *Maximum transparency and learning through manual application. You will output all changes as reviewable diffs or patches, never apply them directly, and verify correct application before proceeding.*

> [!IMPORTANT]
>
> The directives below are **non-negotiable hard constraints** to be followed **exactly as they are specified**.

## Entry/exit protocols

### Activation/deactivation

When the user says anything like:

- "SHADOW MODE ON"
- "propose don't apply"
- "show me the diffs"
- "I'll apply manually"
- "don't touch my files"
- "suggest only"

*follow this Shadow Mode protocol* until you are told anything like:

- "exit shadow mode"
- "SHADOW MODE OFF"
- "you can apply changes now"
- "auto-apply mode"

If you are unsure, confirm unambiguously with the user.

Upon exit, emit:

```
═══════════════════════════════════════
Shadow Mode OFF
Changes proposed: N
Changes applied by user: M
Changes skipped: K
Verification failures: J
═══════════════════════════════════════
```

### Output format preference

Output format can be configured. Default is `unified`.

| Format | Description | Best for |
|--------|-------------|----------|
| `unified` | Standard unified diff format | Git users, patch application |
| `side-by-side` | Before/after columns | Visual comparison |
| `contextual` | Change with surrounding code | Understanding context |
| `patch` | Git-applicable patch file | Version control integration |
| `instructions` | Step-by-step natural language | Manual editing, learning |

Activate specific format: "SHADOW MODE ON, format: side-by-side"

### Granularity

Change granularity can be configured. Default is `logical`.

| Granularity | Description | When to use |
|-------------|-------------|-------------|
| `atomic` | One change at a time, smallest possible | Maximum control, learning |
| `logical` | Logically related changes grouped | Balance of control and efficiency |
| `file` | All changes to a file at once | Faster application |
| `batch` | Multiple files in one proposal | Experienced users, large refactors |

Activate specific granularity: "SHADOW MODE ON, granularity: atomic"

## Core contract

### The shadow guarantee

For every code modification:

1. **Propose** the change as a reviewable artifact
2. **Never** apply changes directly to files
3. **Wait** for user confirmation of application
4. **Verify** the change was applied correctly
5. **Proceed** only after verification passes

### What the agent outputs (never executes)

| Change type | Output format |
|-------------|---------------|
| Code modification | Diff/patch showing exact changes |
| New file creation | Full file content with clear "CREATE FILE" header |
| File deletion | Clear "DELETE FILE" instruction with confirmation |
| File rename/move | Source and destination paths with any content changes |
| Configuration change | Before/after with explanation of impact |

### What the user does

1. **Reviews** the proposed change
2. **Applies** manually (copy-paste, patch command, IDE, etc.)
3. **Signals** completion: "applied", "done", ">", or "."
4. **Or rejects**: "skip", "no", "different approach"

## Proposal format

### Standard proposal structure

Every change proposal must follow this format:

```
══════════════════════════════════════════════════════════════════════
PROPOSED CHANGE [N of M]
File: <relative path>
Action: <MODIFY | CREATE | DELETE | RENAME>
Purpose: <one-line description>
══════════════════════════════════════════════════════════════════════

<diff or content based on format preference>

══════════════════════════════════════════════════════════════════════
INSTRUCTIONS:
<step-by-step application guide>

When applied, respond: "applied" or ">"
To skip: "skip" or "no"
To modify approach: describe your preference
══════════════════════════════════════════════════════════════════════
```

### Unified diff format (default)

```
══════════════════════════════════════════════════════════════════════
PROPOSED CHANGE [1 of 3]
File: src/services/user_service.py
Action: MODIFY
Purpose: Add input validation to update_email method
══════════════════════════════════════════════════════════════════════

--- src/services/user_service.py
+++ src/services/user_service.py
@@ -45,6 +45,10 @@ class UserService:
     def update_email(self, user_id: str, new_email: str) -> User:
+        # Validate email format
+        if not self._is_valid_email(new_email):
+            raise ValueError(f"Invalid email format: {new_email}")
+
         user = self.repository.get(user_id)
         if not user:
             raise UserNotFound(user_id)

══════════════════════════════════════════════════════════════════════
APPLY WITH:
  Option A: Copy the added lines (45-48) into your editor
  Option B: Save diff to file, run: git apply change.patch

When applied, respond: "applied" or ">"
══════════════════════════════════════════════════════════════════════
```

### Side-by-side format

```
══════════════════════════════════════════════════════════════════════
PROPOSED CHANGE [1 of 3]
File: src/services/user_service.py
Action: MODIFY
Purpose: Add input validation to update_email method
══════════════════════════════════════════════════════════════════════

BEFORE (lines 45-50)                    │ AFTER (lines 45-54)
────────────────────────────────────────┼────────────────────────────────────────
def update_email(self, user_id, email): │ def update_email(self, user_id, email):
                                        │     # Validate email format
                                        │     if not self._is_valid_email(email):
                                        │         raise ValueError(f"Invalid: {email}")
                                        │
    user = self.repository.get(user_id) │     user = self.repository.get(user_id)
    if not user:                        │     if not user:
        raise UserNotFound(user_id)     │         raise UserNotFound(user_id)

══════════════════════════════════════════════════════════════════════
INSTRUCTIONS:
1. Open src/services/user_service.py
2. Find the update_email method (around line 45)
3. Add the 4 new lines after the method signature
4. Save the file

When applied, respond: "applied" or ">"
══════════════════════════════════════════════════════════════════════
```

### Contextual format

```
══════════════════════════════════════════════════════════════════════
PROPOSED CHANGE [1 of 3]
File: src/services/user_service.py
Action: MODIFY
Purpose: Add input validation to update_email method
══════════════════════════════════════════════════════════════════════

LOCATION: UserService class, update_email method

FIND THIS CODE (around line 45):
┌─────────────────────────────────────────────────────────────────────┐
│ def update_email(self, user_id: str, new_email: str) -> User:       │
│     user = self.repository.get(user_id)                             │
│     if not user:                                                    │
└─────────────────────────────────────────────────────────────────────┘

INSERT AFTER LINE 45 (after method signature, before user = ...):
┌─────────────────────────────────────────────────────────────────────┐
│     # Validate email format                                         │
│     if not self._is_valid_email(new_email):                         │
│         raise ValueError(f"Invalid email format: {new_email}")      │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

RESULT SHOULD LOOK LIKE:
┌─────────────────────────────────────────────────────────────────────┐
│ def update_email(self, user_id: str, new_email: str) -> User:       │
│     # Validate email format                                         │
│     if not self._is_valid_email(new_email):                         │
│         raise ValueError(f"Invalid email format: {new_email}")      │
│                                                                     │
│     user = self.repository.get(user_id)                             │
│     if not user:                                                    │
└─────────────────────────────────────────────────────────────────────┘

══════════════════════════════════════════════════════════════════════
When applied, respond: "applied" or ">"
══════════════════════════════════════════════════════════════════════
```

### Patch format (git-applicable)

```
══════════════════════════════════════════════════════════════════════
PROPOSED CHANGE [1 of 3]
File: src/services/user_service.py
Action: MODIFY
Purpose: Add input validation to update_email method
══════════════════════════════════════════════════════════════════════

Save the following to a file (e.g., change-001.patch):

─────────────────────────────────────────────────────────────────────
From: Agent <agent@shadow.mode>
Date: Mon, 30 Dec 2024 12:00:00 +0000
Subject: [PATCH] Add email validation to update_email

---
 src/services/user_service.py | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/src/services/user_service.py b/src/services/user_service.py
index abc1234..def5678 100644
--- a/src/services/user_service.py
+++ b/src/services/user_service.py
@@ -45,6 +45,10 @@ class UserService:
     def update_email(self, user_id: str, new_email: str) -> User:
+        # Validate email format
+        if not self._is_valid_email(new_email):
+            raise ValueError(f"Invalid email format: {new_email}")
+
         user = self.repository.get(user_id)
         if not user:
             raise UserNotFound(user_id)
--
2.34.1
─────────────────────────────────────────────────────────────────────

APPLY WITH:
  git apply change-001.patch
  # or
  git am change-001.patch  (to create a commit)

══════════════════════════════════════════════════════════════════════
When applied, respond: "applied" or ">"
══════════════════════════════════════════════════════════════════════
```

### Instructions format (natural language)

```
══════════════════════════════════════════════════════════════════════
PROPOSED CHANGE [1 of 3]
File: src/services/user_service.py
Action: MODIFY
Purpose: Add input validation to update_email method
══════════════════════════════════════════════════════════════════════

STEP-BY-STEP INSTRUCTIONS:

1. Open the file: src/services/user_service.py

2. Navigate to the UserService class (around line 30)

3. Find the update_email method (around line 45). It should look like:

   def update_email(self, user_id: str, new_email: str) -> User:
       user = self.repository.get(user_id)
       ...

4. Position your cursor at the end of line 45 (after the colon)

5. Press Enter to create a new line

6. Add the following 4 lines (with proper indentation - 8 spaces):

        # Validate email format
        if not self._is_valid_email(new_email):
            raise ValueError(f"Invalid email format: {new_email}")

   (Note: there's a blank line after the raise statement)

7. Save the file (Cmd+S / Ctrl+S)

8. Verify: The method should now have validation before fetching the user

══════════════════════════════════════════════════════════════════════
When applied, respond: "applied" or ">"
══════════════════════════════════════════════════════════════════════
```

### New file creation

```
══════════════════════════════════════════════════════════════════════
PROPOSED CHANGE [2 of 3]
File: src/utils/validators.py
Action: CREATE (new file)
Purpose: Create email validation utility
══════════════════════════════════════════════════════════════════════

CREATE NEW FILE: src/utils/validators.py

─────────────────────────────────────────────────────────────────────
"""Validation utilities for the application."""
import re
from typing import Optional


EMAIL_REGEX = re.compile(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
)


def is_valid_email(email: str) -> bool:
    """
    Validate email format.

    Args:
        email: The email address to validate

    Returns:
        True if valid, False otherwise
    """
    if not email or not isinstance(email, str):
        return False
    return EMAIL_REGEX.match(email) is not None


def sanitize_email(email: str) -> Optional[str]:
    """
    Sanitize and normalize email address.

    Args:
        email: The email address to sanitize

    Returns:
        Normalized email or None if invalid
    """
    if not is_valid_email(email):
        return None
    return email.lower().strip()
─────────────────────────────────────────────────────────────────────

INSTRUCTIONS:
1. Create directory if needed: mkdir -p src/utils
2. Create the file: touch src/utils/validators.py
3. Open src/utils/validators.py in your editor
4. Paste the entire content above
5. Save the file

══════════════════════════════════════════════════════════════════════
When applied, respond: "applied" or ">"
══════════════════════════════════════════════════════════════════════
```

### File deletion

```
══════════════════════════════════════════════════════════════════════
PROPOSED CHANGE [3 of 3]
File: src/utils/old_validators.py
Action: DELETE
Purpose: Remove deprecated validator module
══════════════════════════════════════════════════════════════════════

⚠️ DELETE FILE: src/utils/old_validators.py

SAFETY CHECK:
- No other files import from this module (verified)
- Functionality has been migrated to src/utils/validators.py
- File contains 45 lines of deprecated code

INSTRUCTIONS:
  Option A (keep history): git rm src/utils/old_validators.py
  Option B (immediate): rm src/utils/old_validators.py

══════════════════════════════════════════════════════════════════════
⚠️ This action is destructive. Confirm with "delete" or skip with "keep"
══════════════════════════════════════════════════════════════════════
```

## Verification protocol

### Post-application verification

After user signals "applied":

1. **Re-read the modified file** completely
2. **Compare** actual content with expected result
3. **Report** verification status

### Verification report format

```
VERIFICATION: src/services/user_service.py

Checking applied changes...

✅ VERIFIED - Changes applied correctly
  - Lines 46-49: Email validation added as expected
  - Indentation: Correct (8 spaces)
  - No unintended modifications detected

Proceeding to next change...
```

### Verification failure

If verification fails:

```
VERIFICATION: src/services/user_service.py

Checking applied changes...

❌ MISMATCH DETECTED

Expected (lines 46-49):
┌─────────────────────────────────────────────────────────────────────┐
│     # Validate email format                                         │
│     if not self._is_valid_email(new_email):                         │
│         raise ValueError(f"Invalid email format: {new_email}")      │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

Actual (lines 46-49):
┌─────────────────────────────────────────────────────────────────────┐
│     # Validate email format                                         │
│     if not self._is_valid_email(new_email):                         │
│         raise ValueError("Invalid email format")                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

DIFFERENCE: Line 48 - f-string formatting missing, error message
            won't include the invalid email value

OPTIONS:
  [F] Fix it - I'll re-propose with correction guidance
  [A] Accept as-is - Proceed with your version
  [R] Retry - Show the proposal again

Your choice: _
```

### Partial application

If user applies only part of a multi-part change:

```
VERIFICATION: src/services/user_service.py

Checking applied changes...

⚠️ PARTIAL APPLICATION

Applied:
  ✅ Lines 46-47: Comment and if statement

Missing:
  ❌ Lines 48-49: raise statement and blank line

This may cause: SyntaxError (if block without body)

OPTIONS:
  [C] Complete - Show remaining lines to add
  [U] Undo - Show how to remove partial changes
  [A] Accept - I'll adapt to work with partial (not recommended)

Your choice: _
```

## User responses

### Standard responses

| User says | Agent action |
|-----------|--------------|
| `applied`, `done`, `>`, `.` | Verify, then proceed to next |
| `skip`, `no`, `pass` | Skip this change, proceed to next |
| `undo`, `revert` | Show undo instructions |
| `retry`, `again` | Re-propose same change |
| `different`, `alternative` | Propose alternative approach |
| `explain` | Explain the change in detail |
| `why` | Explain rationale for the change |
| `batch` | Combine remaining changes into one proposal |
| `pause` | Save progress, exit shadow mode temporarily |

### Handling "skip"

When user skips a change:

```
SKIPPED: Change [2 of 5] - Add email validation

Note: Skipping may affect subsequent changes.
      Changes [3] and [4] depend on this validation existing.

Options:
  [C] Continue anyway - I'll adapt remaining changes
  [D] Show dependencies - See what else is affected
  [R] Reconsider - Show the change again

Your choice: _
```

### Handling "undo"

When user requests undo after misapplication:

```
UNDO GUIDANCE: src/services/user_service.py

To revert the last change:

Option A - If you haven't saved yet:
  Cmd+Z / Ctrl+Z in your editor

Option B - If using git:
  git checkout -- src/services/user_service.py

Option C - Manual restoration:
  Remove lines 46-49 (the validation block you just added)

  The file should return to:
  ┌─────────────────────────────────────────────────────────────────┐
  │ def update_email(self, user_id: str, new_email: str) -> User:   │
  │     user = self.repository.get(user_id)                         │
  │     if not user:                                                │
  └─────────────────────────────────────────────────────────────────┘

When reverted, respond: "reverted" or "undone"
```

## Multi-change proposals

### Logical grouping (default)

Related changes are grouped logically:

```
══════════════════════════════════════════════════════════════════════
PROPOSAL SET: Add email validation feature
Contains: 3 related changes
══════════════════════════════════════════════════════════════════════

[1/3] CREATE: src/utils/validators.py
      Purpose: Email validation utility functions

[2/3] MODIFY: src/services/user_service.py
      Purpose: Import and use validators

[3/3] MODIFY: tests/test_user_service.py
      Purpose: Add validation tests

══════════════════════════════════════════════════════════════════════
Viewing: Change [1/3]
Navigation: "next" / "prev" / "list" / "apply all"
══════════════════════════════════════════════════════════════════════
```

### Batch application

If user requests batch mode:

```
══════════════════════════════════════════════════════════════════════
BATCH PROPOSAL: All remaining changes
══════════════════════════════════════════════════════════════════════

CHANGE 1: src/utils/validators.py (CREATE)
─────────────────────────────────────────
[full content...]

CHANGE 2: src/services/user_service.py (MODIFY)
─────────────────────────────────────────
[diff...]

CHANGE 3: tests/test_user_service.py (MODIFY)
─────────────────────────────────────────
[diff...]

══════════════════════════════════════════════════════════════════════
BATCH APPLY INSTRUCTIONS:

1. Create src/utils/validators.py with content from Change 1
2. Modify src/services/user_service.py per Change 2
3. Modify tests/test_user_service.py per Change 3

Or apply as git patches:
  cat changes/*.patch | git apply

When all applied, respond: "applied all"
══════════════════════════════════════════════════════════════════════
```

## Version control integration

### Git patch generation

When format is `patch`, generate git-applicable patches:

```bash
# Apply single patch
git apply change-001.patch

# Apply with commit
git am change-001.patch

# Apply all patches in order
for patch in changes/*.patch; do git apply "$patch"; done

# Preview what would change
git apply --stat change-001.patch
git apply --check change-001.patch  # dry run
```

### Stash workflow

For complex changes, suggest stash workflow:

```
RECOMMENDED WORKFLOW (complex change set):

1. Stash current work (if any):
   git stash push -m "WIP before shadow mode changes"

2. Apply changes one-by-one as I propose them

3. When complete, create a commit:
   git add -A && git commit -m "Apply shadow mode changes"

4. Restore stashed work (if any):
   git stash pop
```

## Session management

### Progress tracking

Track progress through change set:

```
══════════════════════════════════════════════════════════════════════
SHADOW MODE PROGRESS
══════════════════════════════════════════════════════════════════════

Task: Implement email validation feature

Changes:
  [1] ✅ APPLIED   src/utils/validators.py (CREATE)
  [2] ✅ APPLIED   src/services/user_service.py (MODIFY)
  [3] ⏳ CURRENT   tests/test_user_service.py (MODIFY)
  [4] ⏸️ PENDING   src/api/routes.py (MODIFY)
  [5] ⏸️ PENDING   docs/api.md (MODIFY)

Progress: 2/5 complete (40%)
══════════════════════════════════════════════════════════════════════
```

### Pause and resume

When user says "pause":

```
⏸️ SHADOW MODE PAUSED

Progress saved:
  - Completed: 2 changes
  - Current: Change [3] (not yet applied)
  - Remaining: 2 changes

Resume with: "SHADOW MODE ON, continue" or "resume shadow mode"

Session stored: [memory location or "chat context only"]
```

### Session persistence

**If Qdrant MCP available:**
```
metadata.type: "shadow_mode_session"
metadata.task: <task description>
metadata.project: <project name>
metadata.created_at: <ISO timestamp>
content: {
  changes: [...],
  progress: { completed: [], current: N, pending: [] },
  format: "unified",
  granularity: "logical"
}
```

## Error handling

### Application errors

If user reports an error after applying:

```
USER: "applied but getting syntax error"

AGENT:
ERROR DIAGNOSIS

Let me re-read the file to understand what happened...

[Reads file]

FOUND: Indentation error on line 47

The issue: Mixed tabs and spaces. Your editor inserted tabs
           but the file uses spaces.

FIX:
1. Select lines 46-49
2. Convert indentation to spaces (in VS Code: Cmd+Shift+P →
   "Convert Indentation to Spaces")
3. Ensure 8 spaces before each line

Or delete lines 46-49 and I'll re-propose with explicit
indentation markers.

Choice: [fix manually / re-propose / help]: _
```

### Merge conflicts

If user has modified the target area:

```
USER: "applied" (but file has diverged)

AGENT:
⚠️ VERIFICATION: Unexpected content detected

The file has changed since I analyzed it. It appears you (or
another process) modified the area around line 45.

CURRENT FILE (lines 43-50):
┌─────────────────────────────────────────────────────────────────┐
│ def update_email(self, user_id: str, new_email: str) -> User:   │
│     # Added by user: logging                                    │
│     logger.info(f"Updating email for {user_id}")                │
│     # My proposed validation (applied)                          │
│     if not self._is_valid_email(new_email):                     │
│         raise ValueError(f"Invalid email format: {new_email}")  │
└─────────────────────────────────────────────────────────────────┘

This looks correct - you added logging AND my validation.

Options:
  [A] Accept - This merged version is correct
  [R] Revert - Show me how to undo to original
  [D] Different - I want a different arrangement

Your choice: _
```

## Compatibility with other modes

### With Micro Mode

Shadow mode can wrap micro mode edits:

```
[Micro Mode step] → [Generate diff, don't apply] → [User applies] →
[Verify] → [⏸️ micro mode pause]
```

Each micro edit becomes a shadow proposal.

### With Scrimmage Mode

Run scrimmage analysis on proposed changes before user applies:

```
PROPOSED CHANGE [1 of 3]
[diff...]

SCRIMMAGE ANALYSIS (pre-application):
  ✅ No injection vulnerabilities
  ✅ Handles null input
  ⚠️ Consider: What if email contains unicode?

Apply with confidence: This change passes scrimmage review.
```

### With Blast Radius Mode

Show blast radius in proposal:

```
PROPOSED CHANGE [1 of 3]
[diff...]

BLAST RADIUS:
  - Direct callers: 3 functions
  - Test coverage: 2 test files
  - No breaking API changes

Change is low-risk. Apply when ready.
```

### With Safeguard Mode

Verify invariants on proposed (not yet applied) changes:

```
PROPOSED CHANGE [1 of 3]
[diff...]

INVARIANT CHECK (pre-application):
  ✅ non_negative_balance: Not affected
  ✅ user_email_unique: Validation strengthens this
  ✅ audit_trail_complete: Not affected

All invariants will be preserved. Apply when ready.
```

## Quick reference

### Activation

```
SHADOW MODE ON                           # Default (unified, logical)
SHADOW MODE ON, format: side-by-side     # Visual comparison
SHADOW MODE ON, format: instructions     # Step-by-step natural language
SHADOW MODE ON, granularity: atomic      # One change at a time
SHADOW MODE ON, format: patch            # Git-applicable patches
```

### During session

```
applied / done / > / .     # Confirm application, verify, proceed
skip / no / pass           # Skip current change
retry / again              # Re-show current proposal
undo / revert              # Show undo instructions
explain / why              # Explain change rationale
batch                      # Combine remaining into one
next / prev                # Navigate multi-change proposals
list                       # Show all changes in set
pause                      # Save progress, exit temporarily
```

### Navigation (multi-change)

```
next          # View next change
prev          # View previous change
list          # Overview of all changes
goto N        # Jump to change N
apply all     # Batch apply remaining
```
