---
description: Continuous invariant protection throughout implementation. Activate when user says "SAFEGUARD MODE ON", "protect these invariants", "safeguard these rules", "verify invariants", or "guard these rules". Defines system rules that must never break (value constraints, state machines, relationships, uniqueness, temporal, ordering, consistency), verifies after every change, and blocks changes that would violate them. Configurable intensity from light to paranoid.
---

# Safeguard Mode: *protocol*

> <ins>***Goal:** define the rules that must never break, verify after every change*</ins>
>
> *Continuous invariant protection throughout implementation. You will define system invariants upfront, generate verification checks, and block any change that would violate them.*

> [!IMPORTANT]
>
> The directives below are **non-negotiable hard constraints** to be followed **exactly as they are specified**.

## Entry/exit protocols

### Activation/deactivation

When the user says anything like:

- "SAFEGUARD MODE ON"
- "protect these invariants"
- "safeguard these rules"
- "verify invariants after changes"
- "guard these rules"

*follow this Safeguard Mode protocol* until you are told anything like:

- "safeguard mode off"
- "SAFEGUARD MODE OFF"
- "stop checking invariants"

If you are unsure, confirm unambiguously with the user.

Upon exit, emit:

```
═══════════════════════════════════════
Safeguard Mode OFF
Invariants defined: N
Changes verified: M
Violations caught: K
Violations fixed: J
Active invariants stored: [location, or "none"]
═══════════════════════════════════════
```

### Verification intensity

Verification intensity can be configured. Default is `standard`.

| Intensity | When to verify | Verification method |
|-----------|----------------|---------------------|
| `light` | After each function change | Static analysis only |
| `standard` | After each edit | Static + generated assertions |
| `strict` | After each edit | Static + runtime checks + tests |
| `paranoid` | After each line change | All methods + formal reasoning |

Activate specific intensity: "SAFEGUARD MODE ON, intensity: strict"

## Core contract

### The invariant guarantee

For every code change:

1. **Check** all defined invariants against the change
2. **Verify** no invariant is violated (statically or dynamically)
3. **Block** changes that would break invariants
4. **Report** potential violations with evidence
5. **Require** fix or explicit waiver before proceeding

### What is an invariant?

An invariant is a property that must **always** hold true throughout program execution:

| Invariant type | Description | Example |
|----------------|-------------|---------|
| **Value constraint** | Bounds on numeric/string values | `balance >= 0`, `age > 0 && age < 150` |
| **State machine** | Valid state transitions | `order: pending → confirmed → shipped` |
| **Relationship** | Properties between entities | `child.parent_id == parent.id` |
| **Cardinality** | Count constraints | `user.sessions.length <= 5` |
| **Uniqueness** | No duplicates | `emails are unique across users` |
| **Temporal** | Time-based constraints | `token.expires_at > token.created_at` |
| **Ordering** | Sequence requirements | `events sorted by timestamp` |
| **Consistency** | Cross-field agreement | `if premium then subscription != null` |

## Invariant definition

### Setup phase

Before making changes, define invariants explicitly. Prompt user if none provided:

```
INVARIANT SETUP REQUIRED

Before proceeding, define the invariants to guard.
Format: One invariant per line, with category prefix.

Example:
  [VALUE] user.balance >= 0
  [STATE] Order: pending → confirmed → shipped → delivered
  [UNIQUE] User.email must be unique
  [TEMPORAL] Session.expires_at > Session.created_at
  [CARD] User.active_sessions <= 5

Your invariants: _
```

### Invariant syntax

Each invariant definition must include:

```
INVARIANT: <id>
Type: <VALUE | STATE | RELATIONSHIP | CARDINALITY | UNIQUE | TEMPORAL | ORDERING | CONSISTENCY>
Entity: <class/table/module affected>
Rule: <formal expression or natural language description>
Scope: <where this applies: function, module, system-wide>
Severity: <CRITICAL | HIGH | MEDIUM | LOW>
Verify: <how to check: static | runtime | test | manual>
```

**Example definitions:**

```
INVARIANT: non_negative_balance
Type: VALUE
Entity: Account
Rule: account.balance >= 0 at all times
Scope: system-wide
Severity: CRITICAL
Verify: static + runtime

INVARIANT: order_state_machine
Type: STATE
Entity: Order
Rule: status transitions only: pending → confirmed → shipped → delivered → completed
       OR pending → cancelled (terminal)
       No skips, no reversals except via explicit refund flow
Scope: Order module
Severity: CRITICAL
Verify: static + test

INVARIANT: cache_size_bound
Type: CARDINALITY
Entity: CacheManager
Rule: cache.size <= cache.max_size
Scope: CacheManager class
Severity: HIGH
Verify: runtime assertion

INVARIANT: user_email_unique
Type: UNIQUE
Entity: User
Rule: No two users share the same email address
Scope: system-wide
Severity: CRITICAL
Verify: database constraint + test
```

### Invariant registry format

Maintain a running registry of all active invariants:

```
══════════════════════════════════════════════════════════════════════
INVARIANT REGISTRY
Task: <current task description>
══════════════════════════════════════════════════════════════════════

ID                    │ Type   │ Entity        │ Severity │ Status
──────────────────────┼────────┼───────────────┼──────────┼─────────
non_negative_balance  │ VALUE  │ Account       │ CRITICAL │ ✅ ACTIVE
order_state_machine   │ STATE  │ Order         │ CRITICAL │ ✅ ACTIVE
cache_size_bound      │ CARD   │ CacheManager  │ HIGH     │ ✅ ACTIVE
user_email_unique     │ UNIQUE │ User          │ CRITICAL │ ✅ ACTIVE

Total: 4 invariants (4 active, 0 suspended, 0 violated)
══════════════════════════════════════════════════════════════════════
```

## Verification protocol

### Pre-change analysis

Before applying any code change:

1. **Identify affected invariants**: Which invariants touch the code being modified?
2. **Flag high-risk changes**: Changes to code that enforces an invariant
3. **Warn on invariant removal**: Any code deletion that removes invariant enforcement

```
PRE-CHANGE INVARIANT ANALYSIS
Change: Modify withdraw() in Account class

Affected invariants:
├── non_negative_balance (CRITICAL) ⚠️ DIRECTLY AFFECTED
│   └── This function enforces the balance >= 0 constraint
├── audit_trail_complete (HIGH)
│   └── withdraw() creates audit entries
└── No other invariants affected

Risk level: HIGH - modifying invariant enforcement code
Proceed with caution: YES/NO?
```

### Post-change verification

After every code change, verify all affected invariants:

1. **Static analysis**: Inspect code paths for possible violations
2. **Assertion generation**: Create runtime assertions if not present
3. **Test verification**: Run relevant tests that exercise invariants
4. **Manual confirmation**: For invariants that can't be automated

### Verification report format

```
══════════════════════════════════════════════════════════════════════
INVARIANT VERIFICATION: <file>::<function>
Change: <brief description>
══════════════════════════════════════════════════════════════════════

INVARIANTS CHECKED:

[1] non_negative_balance (CRITICAL)
    Method: Static analysis of all code paths
    Result: ✅ PRESERVED
    Evidence: All paths through withdraw() check balance before decrement

[2] order_state_machine (CRITICAL)
    Method: State transition analysis
    Result: ✅ PRESERVED
    Evidence: New code only allows valid transitions per state machine

[3] cache_size_bound (HIGH)
    Method: Runtime assertion exists
    Result: ⚠️ WEAKENED
    Evidence: New code path bypasses size check on cache.force_insert()
    Location: line 45-48
    Recommendation: Add size check or document exception

[4] audit_trail_complete (HIGH)
    Method: Code inspection
    Result: ❌ VIOLATED
    Evidence: New early return on line 23 skips audit logging
    Must fix before proceeding

══════════════════════════════════════════════════════════════════════
SUMMARY: 4 checked | 2 preserved | 1 weakened | 1 violated
ACTION REQUIRED: Fix [4] before proceeding
══════════════════════════════════════════════════════════════════════
```

### Result classifications

| Symbol | Status | Meaning | Action |
|--------|--------|---------|--------|
| ✅ | `PRESERVED` | Invariant still holds | None required |
| ⚠️ | `WEAKENED` | Invariant partially compromised | Warn, recommend fix |
| ❌ | `VIOLATED` | Invariant broken | **Must fix before proceeding** |
| 🔄 | `TRANSFERRED` | Enforcement moved to different location | Document new location |
| ⏸️ | `SUSPENDED` | Temporarily disabled (with approval) | Track, re-enable later |

## Violation handling

### On VIOLATED result

1. **Stop immediately** — do not proceed with additional changes
2. **Identify root cause** — what in the change breaks the invariant?
3. **Propose fix** — concrete code to restore invariant
4. **Apply fix** — implement the restoration
5. **Re-verify** — confirm invariant now holds
6. **Continue only after** — all VIOLATED become PRESERVED

### On WEAKENED result

1. **Document the weakening** clearly
2. **Assess risk** — could this lead to violation under certain conditions?
3. **Propose strengthening** — how to restore full protection
4. **Ask user**: "Accept weakened invariant, or fix now?"
5. **If accepted**: Mark as acknowledged, continue monitoring
6. **If fix**: Apply strengthening, re-verify

### Violation report format

```
⚠️ INVARIANT VIOLATION DETECTED

Invariant: non_negative_balance
Severity: CRITICAL
Status: ❌ VIOLATED

VIOLATION DETAILS:
┌─────────────────────────────────────────────────────────────────────┐
│ Location: src/accounts/account.py::withdraw() line 34              │
│                                                                     │
│ Code path that violates:                                            │
│   1. User requests withdrawal of $100                               │
│   2. Concurrent request reduces balance to $50                      │
│   3. First request proceeds (no re-check after lock acquisition)   │
│   4. Balance becomes -$50 ← VIOLATION                              │
│                                                                     │
│ Root cause: Race condition - balance checked before lock, used     │
│             after lock without re-validation                        │
└─────────────────────────────────────────────────────────────────────┘

PROPOSED FIX:
```python
def withdraw(self, amount):
    with self.lock:
        # Re-check balance after acquiring lock
        if self.balance < amount:
            raise InsufficientFunds(f"Balance {self.balance} < {amount}")
        self.balance -= amount
```

APPLY FIX? [Y/N]: _
```

### Waiver protocol

In rare cases, an invariant may need temporary suspension:

```
INVARIANT WAIVER REQUEST

Invariant: cache_size_bound
Reason for waiver: Emergency bulk import requires temporary over-capacity
Duration: Until import completes (estimated 5 minutes)
Risk acknowledged: YES
Compensating control: Manual monitoring of memory usage

User approval required: _
```

**Waivers require:**
- Explicit user approval
- Documented reason
- Defined duration or condition for restoration
- Compensating controls identified
- Automatic reminder to restore

## Invariant types deep dive

### Value constraints

```
[VALUE] account.balance >= 0
[VALUE] 0 < user.age < 150
[VALUE] password.length >= 8
[VALUE] retry_count <= max_retries
```

**Verification methods:**
- Static: Range analysis, symbolic execution
- Runtime: Assertions, property-based tests
- Database: CHECK constraints

### State machines

Define valid states and transitions:

```
[STATE] Order lifecycle:
  States: {pending, confirmed, processing, shipped, delivered, cancelled, refunded}

  Transitions:
    pending → confirmed (on: payment_received)
    pending → cancelled (on: user_cancel, timeout)
    confirmed → processing (on: start_fulfillment)
    processing → shipped (on: carrier_pickup)
    shipped → delivered (on: delivery_confirmed)
    delivered → refunded (on: refund_approved)

  Terminal: {delivered, cancelled, refunded}

  Forbidden:
    * → pending (no restart)
    cancelled → * (terminal)
    shipped → processing (no reversal)
```

**Verification methods:**
- Static: State transition analysis, exhaustive path checking
- Runtime: State machine assertions, event sourcing validation
- Test: Property-based tests with random transitions

### Relationships

```
[REL] Every Order has exactly one Customer
[REL] LineItem.quantity * LineItem.unit_price == LineItem.total
[REL] Parent.children contains Child implies Child.parent == Parent
[REL] User.role IN Organization.allowed_roles
```

**Verification methods:**
- Static: Type checking, reference analysis
- Runtime: Foreign key constraints, computed property checks
- Test: Referential integrity tests

### Cardinality

```
[CARD] User.sessions.count <= 5
[CARD] Order.line_items.count >= 1
[CARD] Team.members.count BETWEEN 2 AND 10
[CARD] Singleton.instances.count == 1
```

**Verification methods:**
- Static: Collection size analysis
- Runtime: Length assertions, database constraints
- Test: Boundary tests

### Uniqueness

```
[UNIQUE] User.email (system-wide)
[UNIQUE] Order.order_number (system-wide)
[UNIQUE] Session.token (system-wide)
[UNIQUE] Product.sku (per Vendor)
```

**Verification methods:**
- Static: Unique index verification
- Runtime: Database UNIQUE constraints, set membership checks
- Test: Duplicate insertion tests

### Temporal

```
[TEMPORAL] token.expires_at > token.created_at
[TEMPORAL] order.shipped_at > order.confirmed_at (if both exist)
[TEMPORAL] subscription.end_date >= subscription.start_date
[TEMPORAL] event.processed_at <= NOW() + tolerance
```

**Verification methods:**
- Static: Temporal logic analysis
- Runtime: DateTime comparisons, monotonic clock checks
- Test: Time-based property tests

### Ordering

```
[ORDER] events sorted by timestamp ASC
[ORDER] priority_queue maintains heap property
[ORDER] version_history sorted by version DESC
[ORDER] search_results sorted by relevance DESC, then date DESC
```

**Verification methods:**
- Static: Sort stability analysis
- Runtime: is_sorted assertions, heap property checks
- Test: Ordering preservation tests

### Consistency

```
[CONSIST] if user.is_premium then user.subscription != null
[CONSIST] if order.status == 'shipped' then order.tracking_number != null
[CONSIST] sum(line_items.total) == order.subtotal
[CONSIST] cache.keys == database.active_records.ids
```

**Verification methods:**
- Static: Conditional analysis, sum verification
- Runtime: Consistency checks on state changes
- Test: Property-based consistency tests

## Invariant persistence

### Storing invariants for future sessions

When pausing or completing a session, persist invariants:

**If Memory MCP available (preferred):**
```
Entity: InvariantSet
Attributes:
  - project: <project name>
  - task: <task description>
  - created_at: <ISO timestamp>

Relations:
  - (InvariantSet)-[:CONTAINS]->(Invariant)

Entity: Invariant
Attributes:
  - id: <invariant id>
  - type: <VALUE|STATE|...>
  - entity: <affected entity>
  - rule: <formal rule>
  - severity: <CRITICAL|HIGH|...>
  - status: <ACTIVE|SUSPENDED|...>
```

**If Qdrant MCP available (fallback):**
```
metadata.type: "invariant_set"
metadata.project: <project name>
metadata.task: <task description>
metadata.created_at: <ISO timestamp>
content: JSON-serialized invariant registry
```

### Loading invariants

At session start, check for existing invariants:

```
SAFEGUARD MODE ON

Checking for existing invariants...
Found: 4 invariants from previous session (2024-01-15)

Load existing invariants? [Y/N/Review first]: _
```

## Compatibility with other modes

### With Micro Mode

Invariant verification triggers **after each micro edit**:

```
[Micro edit] → [Invariant verification] → [Fix if violated] → [⏸️]
```

For efficiency:
- Only verify invariants relevant to the changed code
- Batch verification for related micro edits

### With Scrimmage Mode

Complementary relationship:
- **Safeguard Mode**: Prevents known violations (defined rules)
- **Scrimmage Mode**: Discovers unknown vulnerabilities (attack vectors)

Run in parallel:
1. Safeguard Mode checks defined rules
2. Scrimmage Mode attacks beyond defined rules
3. Discovered vulnerabilities can become new invariants

### With Blast Radius Mode

Sequence:
1. **Blast Radius**: Analyze what could be affected
2. **Safeguard Mode**: Verify no invariants in blast radius are violated
3. **Apply change** only if both pass

### With Clearance Mode

Auto-add invariant criteria:
```
CLEARANCE CRITERIA (auto-added by Safeguard Mode):
□ All defined invariants verified post-implementation
□ No VIOLATED status on any invariant
□ All WEAKENED invariants acknowledged or fixed
□ Invariant tests added for CRITICAL invariants
```

## Quick reference

### Activation

```
SAFEGUARD MODE ON                            # Standard intensity
SAFEGUARD MODE ON, intensity: strict         # With runtime checks
SAFEGUARD MODE ON, load: previous            # Load from previous session
```

### Defining invariants

```
define invariant: <natural language description>
add invariant: [TYPE] <rule>
remove invariant: <id>
suspend invariant: <id> (reason: <reason>, until: <condition>)
restore invariant: <id>
```

### During session

```
list invariants       # Show all active invariants
verify all            # Run full verification
verify <id>           # Verify specific invariant
waiver <id>           # Request temporary suspension
strengthen <id>       # Propose stronger enforcement
```

### Shorthand responses

After verification report:

```
>              # Proceed (all invariants preserved)
fix            # Apply proposed fix
waiver         # Request temporary suspension
strengthen     # Add stronger enforcement
skip           # Skip verification (requires justification)
```
