---
description: Impact analysis before every code change to enumerate what could break. Activate when user says "BLAST RADIUS MODE ON", "analyze impact", "show me what could break", "careful mode", or "cautious mode". Identifies all callers, dependents, tests, and contracts affected by changes. Classifies changes as safe/review/breaking/blocked and requires approval before applying. Essential for refactoring and API changes.
---

# Blast Radius Mode: *protocol*

> <ins>***Goal:** enumerate everything that could break before touching anything*</ins>
>
> *Systematic impact analysis before every change. You will identify all callers, dependents, tests, and contracts that could be affected, assess the risk, and obtain approval before proceeding.*

> [!IMPORTANT]
>
> The directives below are **non-negotiable hard constraints** to be followed **exactly as they are specified**.

## Entry/exit protocols

### Activation/deactivation

When the user says anything like:

- "BLAST RADIUS MODE ON"
- "analyze impact before changes"
- "show me what could break"
- "careful mode" / "cautious mode"

*follow this Blast Radius Mode protocol* until you are told anything like:

- "exit blast radius mode"
- "BLAST RADIUS MODE OFF"
- "skip impact analysis"

If you are unsure, confirm unambiguously with the user.

Upon exit, emit:

```
═══════════════════════════════════════
Blast Radius Mode OFF
Changes analyzed: N
Breaking changes detected: M
Approved & applied: K
Blocked by user: J
═══════════════════════════════════════
```

### Depth levels

Analysis depth can be configured. Default is `standard`.

| Depth | Caller analysis | Test discovery | Cross-service |
|-------|-----------------|----------------|---------------|
| `shallow` | Direct callers only | Direct test files | No |
| `standard` | 2 levels of callers | Test files + fixtures | No |
| `deep` | Full transitive closure | All test dependencies | Yes |
| `exhaustive` | Entire codebase scan | CI pipeline analysis | Yes + API consumers |

Activate specific depth: "BLAST RADIUS MODE ON, depth: deep"

## Core contract

### The blast radius guarantee

Before **every** code change that modifies behavior:

1. **Analyze** all dimensions of potential impact
2. **Classify** the change (safe / review / breaking)
3. **Report** findings with evidence
4. **Gate** on user approval before applying

### Changes requiring analysis

| Change type | Analysis required | Rationale |
|-------------|-------------------|-----------|
| Function signature change | **Always** | Callers may break |
| Return type change | **Always** | Type contracts may break |
| Exception type change | **Always** | Error handlers may miss |
| Behavioral change | **Always** | Dependents rely on behavior |
| New parameter (with default) | **Standard** | Usually safe but verify |
| Internal refactor (same behavior) | **Light** | Low risk but confirm |
| Formatting / comments only | **Skip** | No behavioral impact |

## Analysis dimensions

For each change, analyze these dimensions:

### Dimension 1: Caller analysis

**What**: Functions, methods, and code paths that invoke the target.

**How to discover**:
- Use `find_referencing_symbols` (Serena MCP) for symbol-level callers
- Use `grep`/`ripgrep` for dynamic calls, string references
- Check for reflection, dependency injection, event handlers

**Report format**:
```
CALLERS of update_user_email():
├── Direct (8 callers):
│   ├── src/api/users.py::handle_email_change [line 45]
│   ├── src/api/users.py::bulk_update [line 112]
│   ├── src/services/auth.py::verify_email [line 78]
│   ├── src/services/onboarding.py::complete_signup [line 34]
│   ├── src/workers/email_sync.py::sync_from_provider [line 89]
│   ├── src/admin/user_management.py::admin_edit_user [line 156]
│   ├── src/cli/user_commands.py::update_email_cmd [line 23]
│   └── tests/test_users.py::test_email_update [line 67]
│
└── Indirect (12 callers, 2nd level):
    ├── src/api/routes.py → handle_email_change
    ├── src/api/routes.py → bulk_update
    └── ... [10 more]
```

### Dimension 2: Import/module dependencies

**What**: Files that import the module containing the target.

**Report format**:
```
IMPORTERS of src/services/user_service.py:
├── Direct imports (5 files):
│   ├── src/api/users.py
│   ├── src/api/admin.py
│   ├── src/workers/user_sync.py
│   ├── src/cli/commands.py
│   └── tests/conftest.py
│
└── Re-exports via (2 files):
    ├── src/services/__init__.py (exposes UserService)
    └── src/api/__init__.py (exposes user endpoints)
```

### Dimension 3: Test coverage

**What**: Tests that exercise the target code.

**Report format**:
```
TEST COVERAGE for update_user_email():
├── Direct tests (3 files, 12 test cases):
│   ├── tests/test_user_service.py
│   │   ├── test_update_email_success
│   │   ├── test_update_email_invalid_format
│   │   ├── test_update_email_duplicate
│   │   └── test_update_email_rate_limit
│   ├── tests/test_api_users.py
│   │   ├── test_email_change_endpoint
│   │   └── test_email_change_auth_required
│   └── tests/integration/test_email_flow.py
│       └── test_full_email_change_flow
│
├── Indirect coverage (via callers): 8 additional test files
│
└── Coverage gaps identified:
    ⚠️ No test for: bulk_update() calling update_user_email()
    ⚠️ No test for: concurrent email updates
```

### Dimension 4: API contracts

**What**: Public interfaces, versioned APIs, documented contracts.

**Report format**:
```
API CONTRACTS affected:
├── Public API: YES
│   └── Endpoint: PATCH /api/v2/users/{id}/email
│       ├── Documented in: docs/api/users.md
│       ├── OpenAPI spec: openapi/users.yaml
│       └── Breaking change: Requires major version bump
│
├── Internal API: YES
│   └── Service interface: UserService.update_email()
│       ├── Used by: 3 internal services
│       └── Breaking change: Coordinate with service owners
│
└── Type contracts:
    ├── Input: UpdateEmailRequest (Pydantic model)
    ├── Output: User (Pydantic model)
    └── Changes to these types: BREAKING
```

### Dimension 5: Data dependencies

**What**: Database tables, schemas, cached data, external state.

**Report format**:
```
DATA DEPENDENCIES:
├── Database tables:
│   ├── users (columns: email, email_verified, email_updated_at)
│   ├── email_audit_log (insert on every change)
│   └── user_sessions (may invalidate on email change)
│
├── Cache keys:
│   ├── user:{id} (must invalidate)
│   └── user_by_email:{email} (must update both old and new)
│
└── External state:
    ├── Email provider (Sendgrid): verification email triggered
    └── Analytics (Segment): track event emitted
```

### Dimension 6: Cross-service impact (if applicable)

**What**: Other services, APIs, or systems that depend on this code.

**Report format**:
```
CROSS-SERVICE IMPACT:
├── Downstream consumers:
│   ├── billing-service: subscribes to user.email.changed event
│   ├── notification-service: uses email for delivery
│   └── analytics-service: tracks email domain metrics
│
├── Upstream dependencies:
│   └── auth-service: provides JWT with email claim
│
└── Event contracts:
    ├── user.email.changed (published)
    │   └── Schema: { user_id, old_email, new_email, timestamp }
    └── Breaking change to event: MAJOR impact
```

## Execution protocol

### Pre-change analysis

Before applying ANY behavioral change:

1. **Identify the target**: What function/class/module is being modified?

2. **Run dimensional analysis**: Gather data for all relevant dimensions

3. **Classify the change**:

   | Classification | Criteria | Action required |
   |----------------|----------|-----------------|
   | 🟢 `SAFE` | No callers affected, no contract changes | Inform, proceed |
   | 🟡 `REVIEW` | Callers exist but change is backward-compatible | List affected, request approval |
   | 🔴 `BREAKING` | Signature/contract change affects callers | Full impact report, explicit approval |
   | ⚫ `BLOCKED` | Change would break critical path without migration | Require migration plan first |

4. **Emit blast radius report** (format below)

5. **Wait for approval** before applying change

### Blast radius report format

```
══════════════════════════════════════════════════════════════════════
BLAST RADIUS ANALYSIS
Target: src/services/user_service.py::update_user_email()
Change: Add required parameter `reason: str`
══════════════════════════════════════════════════════════════════════

CLASSIFICATION: 🔴 BREAKING
Reason: New required parameter breaks all 8 existing callers

IMPACT SUMMARY:
┌─────────────────────┬───────┬─────────────────────────────────────┐
│ Dimension           │ Count │ Risk                                │
├─────────────────────┼───────┼─────────────────────────────────────┤
│ Direct callers      │ 8     │ HIGH - all must be updated          │
│ Indirect callers    │ 12    │ MEDIUM - may need review            │
│ Test files          │ 3     │ HIGH - tests will fail              │
│ Public API          │ 1     │ HIGH - endpoint contract changes    │
│ Database tables     │ 1     │ LOW - no schema change              │
│ Cache keys          │ 2     │ MEDIUM - invalidation needed        │
│ Downstream services │ 3     │ MEDIUM - event schema unchanged     │
└─────────────────────┴───────┴─────────────────────────────────────┘

AFFECTED FILES (must update):
  1. src/api/users.py (2 call sites)
  2. src/services/auth.py (1 call site)
  3. src/services/onboarding.py (1 call site)
  4. src/workers/email_sync.py (1 call site)
  5. src/admin/user_management.py (1 call site)
  6. src/cli/user_commands.py (1 call site)
  7. tests/test_users.py (1 call site)

MIGRATION REQUIRED:
  Option A: Add default value `reason: str = "not_specified"` (backward-compatible)
  Option B: Update all 8 callers to provide reason (breaking, but cleaner)

══════════════════════════════════════════════════════════════════════
APPROVAL REQUIRED

Options:
  [A] Proceed with Option A (backward-compatible)
  [B] Proceed with Option B (I will update all callers)
  [C] Abort - rethink approach
  [D] Show me the affected code first

Your choice: _
══════════════════════════════════════════════════════════════════════
```

### Approval gates

| Classification | Approval requirement |
|----------------|---------------------|
| 🟢 `SAFE` | Implicit - inform and proceed |
| 🟡 `REVIEW` | Explicit "proceed" or equivalent |
| 🔴 `BREAKING` | Explicit choice from options provided |
| ⚫ `BLOCKED` | Cannot proceed without migration plan |

### Post-change verification

After applying an approved change:

1. **Verify callers updated**: If breaking change, confirm all callers fixed
2. **Run affected tests**: Execute tests identified in analysis
3. **Report completion**:
   ```
   BLAST RADIUS RESOLUTION:
   ✅ 8/8 callers updated
   ✅ 12/12 tests passing
   ✅ API documentation updated
   ⚠️ Cache invalidation: manual verification recommended
   ```

## Breaking change classification

### What constitutes a breaking change

| Change | Breaking? | Rationale |
|--------|-----------|-----------|
| Add required parameter | **Yes** | Callers don't provide it |
| Add optional parameter (with default) | No | Backward-compatible |
| Remove parameter | **Yes** | Callers may provide it |
| Change parameter type | **Yes** | Type mismatch |
| Change parameter order | **Yes** | Positional args break |
| Rename parameter | **Yes** (if keyword args used) | Keyword args break |
| Change return type | **Yes** | Callers expect old type |
| Add new exception type | **Maybe** | If callers catch specific exceptions |
| Remove exception type | **Maybe** | If callers rely on it |
| Change behavior (same signature) | **Maybe** | Depends on contract |

### Severity levels

| Severity | Criteria | Example |
|----------|----------|---------|
| `CRITICAL` | Breaks public API, affects external consumers | Remove endpoint parameter |
| `HIGH` | Breaks internal API, affects multiple services | Change service interface |
| `MEDIUM` | Breaks module API, affects same codebase | Change function signature |
| `LOW` | Breaks single caller, easily fixed | Rename internal helper |

## Compatibility with other modes

### With Micro Mode

Blast radius analysis triggers **before each micro edit**:

```
[Plan micro edit] → [Blast radius analysis] → [Approval] → [Apply edit] → [⏸️]
```

For efficiency, batch similar changes:
- If multiple micro edits affect the same function, analyze once for all
- Report cumulative blast radius

### With Adversarial Mode

Run in sequence:
1. Blast radius analysis (before change) - "what could break?"
2. Apply change
3. Adversarial analysis (after change) - "how could it fail?"

### With Contract-First Mode

Blast radius is especially critical for contract changes:
- Any interface modification requires `deep` analysis
- Contract changes are always classified as 🔴 `BREAKING`

## Quick reference

### Activation

```
BLAST RADIUS MODE ON                    # Standard depth
BLAST RADIUS MODE ON, depth: deep       # Full transitive analysis
BLAST RADIUS MODE ON, depth: exhaustive # Include CI and external consumers
```

### During session

```
proceed     # Approve and apply change (after review)
abort       # Cancel change, rethink approach
show code   # Display affected code snippets
expand      # Show indirect callers (next level)
migration   # Generate migration plan for breaking change
```

### Shorthand approvals

After reviewing blast radius report:

```
>           # Proceed with recommended option
A/B/C/D     # Select specific option from report
skip        # Skip analysis for this change (requires justification)
```
