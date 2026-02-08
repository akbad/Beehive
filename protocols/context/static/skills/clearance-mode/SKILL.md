---
description: Rigorous completion verification by defining measurable "done" criteria upfront. Activate when user says "CLEARANCE MODE ON", "define done as", "success criteria first", "verify clearance against", "grant clearance", or "prove it's done". Defines criteria by type (functional, behavioral, performance, security, quality, documentation, integration, edge case) with priority levels (MUST, SHOULD, COULD). Tracks progress, requires evidence for each criterion, and blocks clearance until all MUST criteria are satisfied.
---

# Clearance Mode: *protocol*

> <ins>***Goal:** define "done" upfront, prove each criterion is met before declaring success*</ins>
>
> *Rigorous completion verification through explicit success criteria. You will define measurable clearance criteria before starting, track progress against them, and demonstrate each is satisfied with evidence before completing.*

> [!IMPORTANT]
>
> The directives below are **non-negotiable hard constraints** to be followed **exactly as they are specified**.

## Entry/exit protocols

### Activation/deactivation

When the user says anything like:

- "CLEARANCE MODE ON"
- "define done as"
- "success criteria first"
- "verify clearance against"
- "grant clearance"
- "prove it's done"

*follow this Clearance Mode protocol* until you are told anything like:

- "clearance mode off"
- "CLEARANCE MODE OFF"
- "skip verification"

If you are unsure, confirm unambiguously with the user.

Upon exit, emit:

```
═══════════════════════════════════════
Clearance Mode OFF
Criteria defined: N
Criteria satisfied: M
Criteria waived: K
Evidence artifacts: J
Completion status: <COMPLETE | PARTIAL | INCOMPLETE>
═══════════════════════════════════════
```

### Verification rigor

Verification rigor can be configured. Default is `standard`.

| Rigor | Evidence required | Verification method |
|-------|-------------------|---------------------|
| `light` | Self-attestation | Code inspection only |
| `standard` | Demonstrable | Tests, examples, or clear code paths |
| `strict` | Reproducible | Automated tests, runnable demos |
| `auditable` | Documented | Full evidence trail with artifacts |

Activate specific rigor: "CLEARANCE MODE ON, rigor: strict"

## Core contract

### The clearance guarantee

For every task:

1. **Define** explicit, measurable clearance criteria before starting work
2. **Track** progress against criteria throughout implementation
3. **Verify** each criterion with appropriate evidence
4. **Block** completion until all criteria are satisfied or explicitly waived
5. **Document** the evidence for each satisfied criterion

### What constitutes a clearance criterion?

A clearance criterion must be:

| Property | Description | Good example | Bad example |
|----------|-------------|--------------|-------------|
| **Specific** | Clearly defined outcome | "User can reset password via email" | "Password stuff works" |
| **Measurable** | Can verify true/false | "Response time < 200ms" | "Fast enough" |
| **Testable** | Can demonstrate satisfaction | "All edge cases handled" (with list) | "Robust" |
| **Unambiguous** | One interpretation | "Returns 404 for missing user" | "Handles errors" |

### Criterion types

| Type | Symbol | Description | Evidence required |
|------|--------|-------------|-------------------|
| **Functional** | `[F]` | Feature works as specified | Test pass, demo |
| **Behavioral** | `[B]` | System behaves correctly | Test scenarios |
| **Performance** | `[P]` | Meets performance targets | Benchmarks, metrics |
| **Security** | `[S]` | Security requirements met | Audit, tests |
| **Quality** | `[Q]` | Code quality standards | Lint, review |
| **Documentation** | `[D]` | Docs complete and accurate | Doc review |
| **Integration** | `[I]` | Works with other systems | Integration tests |
| **Edge case** | `[E]` | Edge cases handled | Specific tests |

## Criteria definition

### Setup phase

Before starting ANY implementation work, define clearance criteria:

```
CLEARANCE CRITERIA SETUP REQUIRED

Before proceeding, define the criteria for "done".

Task: <user's task description>

Please define clearance criteria, or I'll propose some based on the task.

Format:
  [TYPE] <criterion description>
  [TYPE] <criterion description>
  ...

Example:
  [F] User can request password reset via email
  [F] Reset token expires after 1 hour
  [B] Invalid token shows clear error message
  [E] Rate limited to 3 requests per hour per email
  [Q] All new code has test coverage
  [D] API documentation updated

Your criteria (or "propose" for suggestions): _
```

### Criterion definition syntax

Each criterion must include:

```
CRITERION: <id>
Type: <F | B | P | S | Q | D | I | E>
Description: <clear, testable statement>
Priority: <MUST | SHOULD | COULD>
Verification: <how to prove satisfaction>
Evidence: <what artifact demonstrates this>
```

**Priority levels:**

| Priority | Meaning | Completion requirement |
|----------|---------|------------------------|
| `MUST` | Required for completion | Cannot complete without |
| `SHOULD` | Expected, can waive with justification | Requires explicit waiver |
| `COULD` | Nice to have | Can skip without waiver |

### Proposed criteria format

When agent proposes criteria:

```
══════════════════════════════════════════════════════════════════════
PROPOSED CLEARANCE CRITERIA
Task: Implement password reset flow
══════════════════════════════════════════════════════════════════════

MUST HAVE (required for completion):
┌────┬──────┬─────────────────────────────────────────────────────────┐
│ ID │ Type │ Criterion                                               │
├────┼──────┼─────────────────────────────────────────────────────────┤
│ C1 │ [F]  │ User can request password reset via email               │
│ C2 │ [F]  │ Reset link sent to user's registered email              │
│ C3 │ [F]  │ User can set new password via reset link                │
│ C4 │ [B]  │ Reset token expires after 1 hour                        │
│ C5 │ [B]  │ Reset token is single-use (invalidated after use)       │
│ C6 │ [S]  │ Token is cryptographically secure (min 32 bytes)        │
│ C7 │ [E]  │ Invalid/expired token shows clear error message         │
└────┴──────┴─────────────────────────────────────────────────────────┘

SHOULD HAVE (expected):
┌────┬──────┬─────────────────────────────────────────────────────────┐
│ ID │ Type │ Criterion                                               │
├────┼──────┼─────────────────────────────────────────────────────────┤
│ C8 │ [S]  │ Rate limited to 3 requests per hour per email           │
│ C9 │ [Q]  │ All new code has >80% test coverage                     │
│C10 │ [D]  │ API documentation updated for new endpoints             │
└────┴──────┴─────────────────────────────────────────────────────────┘

COULD HAVE (nice to have):
┌────┬──────┬─────────────────────────────────────────────────────────┐
│ ID │ Type │ Criterion                                               │
├────┼──────┼─────────────────────────────────────────────────────────┤
│C11 │ [B]  │ User notified of reset attempt on another device        │
│C12 │ [I]  │ Reset events logged to audit system                     │
└────┴──────┴─────────────────────────────────────────────────────────┘

══════════════════════════════════════════════════════════════════════
Options:
  [A] Accept all criteria as proposed
  [M] Modify - specify changes (e.g., "remove C11, change C8 to COULD")
  [R] Replace - provide your own criteria
  [+] Add - specify additional criteria

Your choice: _
══════════════════════════════════════════════════════════════════════
```

### Criteria registry

After approval, maintain a live registry:

```
══════════════════════════════════════════════════════════════════════
CLEARANCE CRITERIA REGISTRY
Task: Implement password reset flow
══════════════════════════════════════════════════════════════════════

ID  │ Pri  │ Type │ Status │ Criterion (abbreviated)
────┼──────┼──────┼────────┼──────────────────────────────────────
C1  │ MUST │ [F]  │ ⏳     │ User can request reset via email
C2  │ MUST │ [F]  │ ⏳     │ Reset link sent to email
C3  │ MUST │ [F]  │ ⏳     │ User can set new password
C4  │ MUST │ [B]  │ ⏳     │ Token expires after 1 hour
C5  │ MUST │ [B]  │ ⏳     │ Token is single-use
C6  │ MUST │ [S]  │ ⏳     │ Token cryptographically secure
C7  │ MUST │ [E]  │ ⏳     │ Invalid token shows error
C8  │ SHLD │ [S]  │ ⏳     │ Rate limited (3/hr/email)
C9  │ SHLD │ [Q]  │ ⏳     │ >80% test coverage
C10 │ SHLD │ [D]  │ ⏳     │ API docs updated
C11 │ CULD │ [B]  │ ⏳     │ Multi-device notification
C12 │ CULD │ [I]  │ ⏳     │ Audit logging

Status: 0/12 satisfied (0%)
MUST: 0/7 | SHOULD: 0/3 | COULD: 0/2
══════════════════════════════════════════════════════════════════════
```

### Status symbols

| Symbol | Status | Meaning |
|--------|--------|---------|
| ⏳ | `PENDING` | Not yet attempted |
| 🔄 | `IN_PROGRESS` | Currently working on |
| ✅ | `SATISFIED` | Verified with evidence |
| ❌ | `FAILED` | Attempted, not satisfied |
| ⏭️ | `WAIVED` | Explicitly skipped |
| 🚫 | `BLOCKED` | Cannot proceed (dependency) |

## Progress tracking

### During implementation

Update registry after each significant change:

```
══════════════════════════════════════════════════════════════════════
CRITERIA PROGRESS UPDATE
══════════════════════════════════════════════════════════════════════

Just completed: Created password reset endpoint

Criteria affected:
  C1: ⏳ → 🔄 IN_PROGRESS (endpoint exists, needs email integration)
  C6: ⏳ → ✅ SATISFIED
      Evidence: Using secrets.token_urlsafe(32) - 43 character token

Updated registry:
  MUST: 1/7 satisfied | SHOULD: 0/3 | COULD: 0/2
  Overall: 8% complete

Next: Implement email sending for C2
══════════════════════════════════════════════════════════════════════
```

### Progress report format

Periodically (or on request), emit full progress report:

```
══════════════════════════════════════════════════════════════════════
CLEARANCE CRITERIA PROGRESS REPORT
Task: Implement password reset flow
Time elapsed: 45 minutes
══════════════════════════════════════════════════════════════════════

MUST HAVE:
  C1 ✅ SATISFIED   User can request reset via email
                    Evidence: test_request_reset passes
  C2 ✅ SATISFIED   Reset link sent to email
                    Evidence: Email sent in test (mock verified)
  C3 🔄 IN_PROGRESS User can set new password
                    Status: Endpoint created, validation pending
  C4 ⏳ PENDING     Token expires after 1 hour
  C5 ⏳ PENDING     Token is single-use
  C6 ✅ SATISFIED   Token cryptographically secure
                    Evidence: secrets.token_urlsafe(32)
  C7 ⏳ PENDING     Invalid token shows error

SHOULD HAVE:
  C8 ⏳ PENDING     Rate limited (3/hr/email)
  C9 ⏳ PENDING     >80% test coverage
  C10 ⏳ PENDING    API docs updated

COULD HAVE:
  C11 ⏳ PENDING    Multi-device notification
  C12 ⏳ PENDING    Audit logging

══════════════════════════════════════════════════════════════════════
SUMMARY:
  MUST:   3/7 satisfied (43%)
  SHOULD: 0/3 satisfied (0%)
  COULD:  0/2 satisfied (0%)

  Overall: 3/12 criteria satisfied (25%)

  Blocking: C3 must complete before C4, C5, C7 can be verified

ESTIMATED REMAINING: 4-6 more implementation steps
══════════════════════════════════════════════════════════════════════
```

## Evidence requirements

### Evidence by criterion type

| Type | Symbol | Acceptable evidence |
|------|--------|---------------------|
| **Functional** | `[F]` | Passing test, demo screenshot/video, code walkthrough |
| **Behavioral** | `[B]` | Test scenarios covering behavior, state machine verification |
| **Performance** | `[P]` | Benchmark results, profiler output, load test metrics |
| **Security** | `[S]` | Security test pass, code audit notes, threat model check |
| **Quality** | `[Q]` | Lint pass, coverage report, static analysis results |
| **Documentation** | `[D]` | Doc diff, rendered preview, link to updated docs |
| **Integration** | `[I]` | Integration test pass, E2E test results |
| **Edge case** | `[E]` | Specific test per edge case, error scenario verification |

### Evidence format

When marking a criterion satisfied, include evidence:

```
CRITERION SATISFIED: C6

Criterion: Token is cryptographically secure (min 32 bytes)
Type: [S] Security
Priority: MUST

EVIDENCE:
┌─────────────────────────────────────────────────────────────────────┐
│ Verification method: Code inspection                                │
│                                                                     │
│ Location: src/services/password_reset.py:34                         │
│                                                                     │
│ Code:                                                               │
│   token = secrets.token_urlsafe(32)  # 32 bytes = 256 bits         │
│   # Results in 43-character URL-safe string                         │
│                                                                     │
│ Analysis:                                                           │
│   - secrets module uses OS entropy source                           │
│   - 32 bytes = 256 bits of entropy                                  │
│   - Exceeds minimum requirement                                     │
│   - URL-safe encoding for use in links                              │
│                                                                     │
│ Verdict: SATISFIES requirement                                      │
└─────────────────────────────────────────────────────────────────────┘

Status: C6 ⏳ → ✅
```

### Evidence rigor levels

**Light rigor** (self-attestation):
```
C6 ✅ Token cryptographically secure
     Evidence: Using secrets.token_urlsafe(32)
```

**Standard rigor** (demonstrable):
```
C6 ✅ Token cryptographically secure
     Evidence: Using secrets.token_urlsafe(32)
     Verification: Code at src/services/password_reset.py:34
     Analysis: 32 bytes = 256 bits entropy, exceeds requirement
```

**Strict rigor** (reproducible):
```
C6 ✅ Token cryptographically secure
     Evidence: Using secrets.token_urlsafe(32)
     Verification: Code at src/services/password_reset.py:34
     Test: test_token_security.py::test_token_entropy PASSED
     Output: Generated 1000 tokens, all unique, entropy verified
```

**Auditable rigor** (documented):
```
C6 ✅ Token cryptographically secure
     Evidence: Using secrets.token_urlsafe(32)
     Verification: Code at src/services/password_reset.py:34
     Test: test_token_security.py::test_token_entropy PASSED
     Artifact: evidence/C6_token_security_audit.md
     Reviewer: Verified by security review checklist
     Timestamp: 2024-01-15T14:32:00Z
```

## Completion verification

### Pre-completion checklist

Before declaring task complete:

```
══════════════════════════════════════════════════════════════════════
PRE-COMPLETION VERIFICATION
Task: Implement password reset flow
══════════════════════════════════════════════════════════════════════

MUST HAVE criteria:
  C1 ✅ User can request reset via email
  C2 ✅ Reset link sent to email
  C3 ✅ User can set new password
  C4 ✅ Token expires after 1 hour
  C5 ✅ Token is single-use
  C6 ✅ Token cryptographically secure
  C7 ✅ Invalid token shows error

  MUST status: 7/7 satisfied ✅

SHOULD HAVE criteria:
  C8 ✅ Rate limited (3/hr/email)
  C9 ✅ >80% test coverage (actual: 87%)
  C10 ✅ API docs updated

  SHOULD status: 3/3 satisfied ✅

COULD HAVE criteria:
  C11 ⏭️ Multi-device notification (WAIVED - out of scope)
  C12 ✅ Audit logging

  COULD status: 1/2 satisfied, 1 waived ✅

══════════════════════════════════════════════════════════════════════
COMPLETION ELIGIBLE: YES

All MUST criteria satisfied.
All SHOULD criteria satisfied.
COULD criteria: 1 satisfied, 1 explicitly waived.

Declare complete? [Y/N]: _
══════════════════════════════════════════════════════════════════════
```

### Completion declaration

```
══════════════════════════════════════════════════════════════════════
TASK COMPLETE
══════════════════════════════════════════════════════════════════════

Task: Implement password reset flow
Status: COMPLETE

FINAL CRITERIA STATUS:
  MUST:   7/7 satisfied (100%)
  SHOULD: 3/3 satisfied (100%)
  COULD:  1/2 satisfied, 1 waived (50%)

  Total: 11/12 criteria addressed

EVIDENCE SUMMARY:
  - 8 criteria verified by automated tests
  - 2 criteria verified by code inspection
  - 1 criterion verified by documentation review
  - 1 criterion waived with justification

ARTIFACTS:
  - Test suite: tests/test_password_reset.py (12 tests, all passing)
  - Coverage: 87% for new code
  - Documentation: docs/api/password_reset.md

WAIVER LOG:
  - C11 (Multi-device notification): Waived - agreed as future enhancement

══════════════════════════════════════════════════════════════════════
```

## Criteria modification

### Adding criteria mid-task

New criteria can be added during implementation:

```
USER: "We also need to log all reset attempts for compliance"

AGENT:
NEW CRITERION PROPOSED

Adding to registry:

  C13 │ MUST │ [I] │ All reset attempts logged with timestamp, IP, result
      │      │     │ Verification: Audit log inspection
      │      │     │ Evidence: Log entries in compliance_audit table

This is a MUST criterion per compliance requirements.

Accept addition? [Y/N]: _
```

### Modifying existing criteria

```
USER: "Change the token expiry to 30 minutes, not 1 hour"

AGENT:
CRITERION MODIFICATION

Current:
  C4 │ MUST │ [B] │ Token expires after 1 hour

Proposed:
  C4 │ MUST │ [B] │ Token expires after 30 minutes

Impact:
  - More secure (shorter window)
  - Current implementation uses 1 hour
  - Requires code change if already implemented

Status: C4 was ⏳ PENDING

Accept modification? [Y/N]: _
```

### Waiving criteria

SHOULD and COULD criteria can be waived with justification:

```
USER: "Skip the multi-device notification for now"

AGENT:
WAIVER REQUEST: C11

Criterion: Multi-device notification when reset attempted
Priority: COULD (nice to have)

Waiver justification required: _
```

After justification:

```
CRITERION WAIVED: C11

Criterion: Multi-device notification when reset attempted
Priority: COULD
Justification: "Out of scope for MVP, will address in v2"
Waived by: User
Timestamp: 2024-01-15T15:00:00Z

Status: C11 ⏳ → ⏭️ WAIVED

Note: COULD criteria do not require justification but it's recorded.
      SHOULD criteria require justification.
      MUST criteria cannot be waived (task incomplete).
```

### Cannot waive MUST criteria

```
USER: "Skip the token expiry, we'll add it later"

AGENT:
⚠️ WAIVER DENIED: C4

Criterion: Token expires after 1 hour
Priority: MUST

MUST criteria cannot be waived. They are required for task completion.

Options:
  [D] Downgrade to SHOULD (requires strong justification)
  [P] Postpone entire task
  [I] Implement criterion now

Your choice: _
```

## Failure handling

### Criterion failure

When a criterion cannot be satisfied:

```
CRITERION FAILED: C9

Criterion: >80% test coverage
Type: [Q] Quality
Priority: SHOULD

Attempt result:
  - Current coverage: 72%
  - Target: 80%
  - Gap: 8 percentage points

Analysis:
  - Missing coverage in error handling paths
  - Complex branching in validate_token()

Options:
  [R] Retry - Add more tests to reach 80%
  [W] Waive - Accept 72% with justification (SHOULD allows waiver)
  [L] Lower - Change target to 70% (requires approval)
  [B] Block - Mark as blocker, pause task

Your choice: _
```

### Blocked criteria

When a criterion is blocked by external factors:

```
CRITERION BLOCKED: C8

Criterion: Rate limited to 3 requests per hour per email
Type: [S] Security
Priority: SHOULD

Blocker: Redis dependency not available in test environment

Impact:
  - Cannot verify rate limiting works correctly
  - Implementation complete but unverified

Options:
  [M] Mock - Test with mocked Redis (partial verification)
  [D] Defer - Mark as verified-in-staging
  [S] Skip - Waive with justification
  [U] Unblock - Help me set up Redis

Your choice: _
```

## Partial completion

### Partial completion report

If task cannot be fully completed:

```
══════════════════════════════════════════════════════════════════════
PARTIAL COMPLETION REPORT
Task: Implement password reset flow
Status: PARTIAL (blocked)
══════════════════════════════════════════════════════════════════════

COMPLETED:
  C1 ✅ User can request reset via email
  C2 ✅ Reset link sent to email
  C3 ✅ User can set new password
  C6 ✅ Token cryptographically secure
  C7 ✅ Invalid token shows error

NOT COMPLETED:
  C4 ❌ Token expires after 1 hour
       Blocker: Scheduler service unavailable
  C5 ❌ Token is single-use
       Blocker: Depends on C4 infrastructure
  C8 🚫 Rate limiting
       Blocker: Redis not configured

WAIVED:
  C11 ⏭️ Multi-device notification (out of scope)

══════════════════════════════════════════════════════════════════════
SUMMARY:
  MUST: 5/7 satisfied (71%) - 2 blocked
  Cannot declare complete until blockers resolved.

RECOMMENDED ACTIONS:
  1. Deploy scheduler service (unblocks C4, C5)
  2. Configure Redis (unblocks C8)
  3. Resume Clearance Mode to complete

Progress stored: [memory location]
══════════════════════════════════════════════════════════════════════
```

### Handoff for partial completion

When handing off partially complete work:

```
HANDOFF PACKAGE

Task: Implement password reset flow
Status: 5/7 MUST criteria satisfied
Remaining: C4 (token expiry), C5 (single-use)

Blockers requiring resolution:
  1. Scheduler service needed for token expiry job
  2. Background job infrastructure for token invalidation

Completed work:
  - Password reset endpoint: POST /api/reset-password
  - Token generation: src/services/password_reset.py
  - Email sending: integrated with SendGrid
  - Error handling: all edge cases covered

Resume instructions:
  1. Resolve scheduler blocker
  2. Activate: "CLEARANCE MODE ON, continue"
  3. Registry will load from stored session
```

## Session persistence

### Storing criteria registry

**If Memory MCP available (preferred):**
```
Entity: ExitCriteriaSet
Attributes:
  - task: <task description>
  - project: <project name>
  - created_at: <ISO timestamp>
  - status: <IN_PROGRESS | COMPLETE | PARTIAL>

Relations:
  - (ExitCriteriaSet)-[:CONTAINS]->(ExitCriterion)

Entity: ExitCriterion
Attributes:
  - id: <criterion id>
  - type: <F|B|P|S|Q|D|I|E>
  - priority: <MUST|SHOULD|COULD>
  - description: <criterion text>
  - status: <PENDING|IN_PROGRESS|SATISFIED|FAILED|WAIVED|BLOCKED>
  - evidence: <evidence text if satisfied>
  - waiver_reason: <reason if waived>
```

**If Qdrant MCP available (fallback):**
```
metadata.type: "clearance_session"
metadata.task: <task description>
metadata.project: <project name>
metadata.created_at: <ISO timestamp>
content: JSON-serialized criteria registry with all statuses
```

### Loading existing criteria

At session start:

```
CLEARANCE MODE ON

Checking for existing criteria...
Found: Criteria set for "Implement password reset flow" (5/7 complete)

Options:
  [C] Continue - Resume with existing criteria
  [R] Reset - Start fresh with new criteria
  [V] View - Show existing criteria before deciding

Your choice: _
```

## Compatibility with other modes

### With Micro Mode

Each micro edit maps to criteria progress:

```
[Micro edit] → [Update criteria status] → [Report progress] → [⏸️]
```

Progress report after each micro edit shows which criteria are affected.

### With Scrimmage Mode

Auto-generate security criteria from scrimmage findings:

```
SCRIMMAGE FINDING → CLEARANCE CRITERION

Finding: SQL injection possible in user lookup
Severity: CRITICAL

Auto-adding criterion:
  C14 │ MUST │ [S] │ All database queries use parameterized statements
      │      │     │ Evidence: Code review, SQLi test suite pass

Accept? [Y/N]: _
```

### With Blast Radius Mode

Generate criteria for affected areas:

```
BLAST RADIUS → CLEARANCE CRITERIA

Blast radius shows 8 callers affected by signature change.

Auto-adding criteria:
  C15 │ MUST │ [F] │ All 8 callers updated to new signature
  C16 │ SHLD │ [Q] │ All affected tests passing

Accept? [Y/N]: _
```

### With Safeguard Mode

Map invariants to criteria:

```
INVARIANTS → CLEARANCE CRITERIA

Active invariants can become clearance criteria:

  non_negative_balance → C17 │ MUST │ [B] │ Balance never goes negative
  order_state_machine  → C18 │ MUST │ [B] │ Order states follow valid transitions

This ensures invariants are explicitly verified at completion.

Add invariant-based criteria? [Y/N]: _
```

### With Shadow Mode

Show criteria progress in each proposal:

```
PROPOSED CHANGE [3 of 5]
[diff...]

CRITERIA IMPACT:
  - This change satisfies: C3 (user can set new password)
  - Progress after: 4/7 MUST criteria satisfied

Apply when ready: _
```

## Quick reference

### Activation

```
CLEARANCE MODE ON                        # Standard rigor
CLEARANCE MODE ON, rigor: strict         # Require automated tests
CLEARANCE MODE ON, continue              # Resume previous session
```

### Defining criteria

```
[F] <functional criterion>               # Feature works
[B] <behavioral criterion>               # Behaves correctly
[P] <performance criterion>              # Meets perf targets
[S] <security criterion>                 # Security requirement
[Q] <quality criterion>                  # Code quality
[D] <documentation criterion>            # Docs complete
[I] <integration criterion>              # Works with systems
[E] <edge case criterion>                # Edge case handled
```

### During session

```
progress          # Show current criteria status
criteria          # List all criteria
add <criterion>   # Add new criterion
modify <id>       # Change criterion
waive <id>        # Waive SHOULD/COULD criterion
evidence <id>     # Show evidence for criterion
verify <id>       # Manually verify criterion
complete          # Attempt completion declaration
```

### Priorities

```
MUST              # Required, cannot waive
SHOULD            # Expected, can waive with justification
COULD             # Nice to have, can waive freely
```

### Criterion status updates

```
satisfy <id>      # Mark as satisfied (prompts for evidence)
fail <id>         # Mark as failed (prompts for reason)
block <id>        # Mark as blocked (prompts for blocker)
unblock <id>      # Remove blocked status
reset <id>        # Reset to pending
```
