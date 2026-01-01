---
name: bureau-adversarial-mode
description: Systematic self-attack vulnerability testing after every code change. Activate when user says "ADVERSARIAL MODE ON", "attack your own code", "red-team this", or wants proactive security testing. Generates attack vectors from 5 categories (input validation, state, failure modes, concurrency, security), executes attacks, and blocks progression until vulnerabilities are fixed. Configurable depth levels from light to paranoid.
---

# Adversarial Mode: *protocol*

> <ins>***Goal:** attack your own code immediately after writing it*</ins>
>
> *Proactive vulnerability discovery through systematic self-attack. After each code change, you will generate attack vectors, attempt to break your own code, and only proceed after surviving or fixing all attacks.*

> [!IMPORTANT]
>
> The directives below are **non-negotiable hard constraints** to be followed **exactly as they are specified**.

## Entry/exit protocols

### Activation/deactivation

When the user says anything like:

- "ADVERSARIAL MODE ON"
- "implement with adversarial testing"
- "attack your own code"
- "red-team this implementation"

*follow this Adversarial Mode protocol* until you are told anything like:

- "exit adversarial mode"
- "ADVERSARIAL MODE OFF"
- "skip adversarial testing"

If you are unsure, confirm unambiguously with the user.

Upon exit, emit:

```
═══════════════════════════════════════
Adversarial Mode OFF
Changes tested: N
Attacks generated: M
Vulnerabilities found & fixed: K
Acknowledged risks: [ids, or "none"]
═══════════════════════════════════════
```

### Depth levels

Adversarial testing depth can be configured. Default is `standard`.

| Depth | When to use | Attack vectors per change |
|-------|-------------|---------------------------|
| `light` | Utility code, low-risk changes | 3-5 vectors, input validation only |
| `standard` | Most application code | 5-8 vectors, inputs + state + failures |
| `deep` | Security-critical, financial, auth | 8-12 vectors, full taxonomy |
| `paranoid` | Cryptography, access control, payments | 12+ vectors, including concurrency & timing |

Activate specific depth: "ADVERSARIAL MODE ON, depth: deep"

## Core contract

### The adversarial guarantee

For every code change that modifies behavior (not formatting, comments, or renames):

1. **Generate** targeted attack vectors based on the change
2. **Execute** attacks (mentally simulate or actually run if testable)
3. **Report** results with evidence
4. **Block** progression until all attacks are survived or fixed

### What constitutes an "attack"

An attack is a specific input, state, or condition designed to:

- Cause incorrect behavior
- Trigger an unhandled exception
- Corrupt data or state
- Bypass validation or security controls
- Exhaust resources (memory, CPU, connections)
- Expose sensitive information
- Create race conditions or deadlocks

## Attack vector taxonomy

You must draw attacks from these categories based on the code being changed:

### Category 1: Input validation attacks

| Vector | Description | Example |
|--------|-------------|---------|
| `null` | Null/None/nil where value expected | `process_user(None)` |
| `empty` | Empty string, list, dict | `parse_csv("")` |
| `boundary` | Min/max values, off-by-one | `withdraw(balance + 1)` |
| `type_confusion` | Wrong type that might coerce | `set_age("25")` vs `set_age(25)` |
| `malformed` | Syntactically invalid input | `parse_json("{invalid")` |
| `oversized` | Extremely large inputs | `process(data_1GB)` |
| `unicode` | Special characters, RTL, emoji | `username = "admin\u0000"` |
| `injection` | SQL, command, template injection | `query("; DROP TABLE users;")` |

### Category 2: State attacks

| Vector | Description | Example |
|--------|-------------|---------|
| `invalid_state` | Operation in wrong state | `ship_order(order_status="cancelled")` |
| `stale_state` | Concurrent modification | Read-modify-write without locking |
| `duplicate` | Repeated operation that should be idempotent | `charge_payment()` called twice |
| `ordering` | Out-of-order operations | `complete()` before `start()` |
| `partial` | Incomplete initialization | Object used before fully constructed |

### Category 3: Failure mode attacks

| Vector | Description | Example |
|--------|-------------|---------|
| `network_fail` | Connection refused, timeout, DNS failure | External API unreachable |
| `disk_full` | Write failures due to storage | Log rotation fails |
| `oom` | Memory exhaustion | Large file loaded entirely |
| `timeout` | Operation exceeds time limit | Database query hangs |
| `dependency_fail` | Downstream service unavailable | Cache server down |

### Category 4: Concurrency attacks

| Vector | Description | Example |
|--------|-------------|---------|
| `race_condition` | Timing-dependent correctness | Check-then-act without synchronization |
| `deadlock` | Circular wait on resources | Lock A then B vs Lock B then A |
| `starvation` | Resource never available | Unfair scheduling |
| `lost_update` | Concurrent writes clobber each other | Two threads increment counter |

### Category 5: Security attacks

| Vector | Description | Example |
|--------|-------------|---------|
| `authz_bypass` | Access without proper authorization | Direct object reference |
| `authn_bypass` | Circumvent authentication | Token reuse, session fixation |
| `info_leak` | Sensitive data in logs/errors | Stack trace with credentials |
| `privilege_escalation` | Gain elevated access | User becomes admin |
| `timing_attack` | Information via timing differences | Password comparison timing |

## Execution protocol

### When to attack

Trigger adversarial testing after:

1. **Completing a function or method** (new or modified)
2. **Modifying control flow** (if/else, loops, error handling)
3. **Changing data validation or transformation**
4. **Touching security-related code** (auth, crypto, access control)
5. **Modifying state management** (database, cache, session)

Do NOT trigger for:

- Pure formatting changes
- Comment-only changes
- Renaming without logic change
- Import reordering

### Attack generation process

For each triggering change:

1. **Identify attack surface**: What inputs, states, and failure modes does this code interact with?

2. **Select relevant categories**: Based on what the code does:
   - Handles user input → Category 1 (inputs)
   - Manages state/database → Category 2 (state)
   - Calls external services → Category 3 (failures)
   - Uses threads/async → Category 4 (concurrency)
   - Controls access → Category 5 (security)

3. **Generate specific vectors**: Create concrete attack scenarios, not abstract categories

4. **Prioritize by risk**: High-severity vectors first

### Attack report format

After generating attacks, emit a report in a similar format to the following exemplar:

```
══════════════════════════════════════════════════════════
ADVERSARIAL ANALYSIS: <file>::<function>
Depth: <light|standard|deep|paranoid>
══════════════════════════════════════════════════════════

ATTACK VECTORS:

[1] null_user_id (Category: input/null)
    Attack: Call get_user(user_id=None)
    Expected: Should raise ValueError or return None safely
    Result: ✅ SURVIVED — raises ValueError("user_id required")

[2] sql_injection (Category: security/injection)
    Attack: get_user(user_id="1; DROP TABLE users;--")
    Expected: Should use parameterized query, not string concat
    Result: ✅ SURVIVED — using parameterized query

[3] negative_balance (Category: input/boundary)
    Attack: withdraw(amount=-100)
    Expected: Should reject negative amounts
    Result: ❌ BROKEN — accepts negative, effectively deposits
    Fix: Add validation `if amount <= 0: raise ValueError`

[4] concurrent_withdraw (Category: concurrency/race)
    Attack: Two threads withdraw(50) when balance=75
    Expected: One should fail, total withdrawn ≤ 75
    Result: ⚠️ POTENTIAL — no locking visible, needs verification
    Mitigation: Add SELECT FOR UPDATE or application-level lock

══════════════════════════════════════════════════════════
SUMMARY: 4 vectors | 2 survived | 1 broken | 1 potential
ACTION REQUIRED: Fix [3], verify [4] before proceeding
══════════════════════════════════════════════════════════
```

### Result classifications

| Symbol | Status | Meaning | Action |
|--------|--------|---------|--------|
| ✅ | `SURVIVED` | Code handles attack correctly | None required |
| ❌ | `BROKEN` | Attack succeeded, vulnerability confirmed | **Must fix before proceeding** |
| ⚠️ | `POTENTIAL` | Cannot verify without runtime test | Document, recommend verification |
| 🛡️ | `MITIGATED` | Vulnerability exists but mitigated elsewhere | Document mitigation |
| 📝 | `ACKNOWLEDGED` | User accepted risk explicitly | Log acknowledgment |

## Failure handling

### On BROKEN result

1. **Stop immediately** — do not proceed to next change
2. **Propose fix** — concrete code change to address vulnerability
3. **Apply fix** — implement the mitigation
4. **Re-attack** — verify the fix actually works
5. **Continue only after** — all BROKEN vectors become SURVIVED or MITIGATED

### On POTENTIAL result

1. **Document the risk** clearly
2. **Propose verification method** (test to write, manual check needed)
3. **Ask user**: "Acknowledge risk and proceed, or pause to verify?"
4. **If acknowledged**: Mark as 📝 ACKNOWLEDGED with user's response
5. **If verify**: Pause, write verification, confirm result

### Escalation

If you discover a vulnerability that:

- Affects code outside current scope
- Indicates systemic issue (pattern appears elsewhere)
- Has high severity (auth bypass, data corruption, RCE)

**Escalate immediately**:

```
⚠️ ESCALATION: High-severity vulnerability pattern detected

Finding: SQL injection via string concatenation
Location: src/db/queries.py::get_user (current change)
Pattern also appears in:
  - src/db/queries.py::get_orders (line 45)
  - src/db/queries.py::search_products (line 89)
  - src/api/admin.py::lookup_user (line 23)

Recommend: Pause current work, address systemic issue first.
Proceed with current fix only? [y/n]
```

## Attack persistence

### Storing attacks for regression

When attacks are generated, optionally persist them as test cases:

**If test framework is available**:

```python
# Auto-generated adversarial test from Adversarial Mode
# Attack vector: null_user_id (Category: input/null)
def test_adversarial_get_user_null_input():
    """Adversarial: get_user should handle None user_id safely."""
    with pytest.raises(ValueError, match="user_id required"):
        get_user(user_id=None)
```

**Offer to generate**: After each attack session, ask:
"Generate test cases for these attack vectors? [y/n]"

### Session persistence

If pausing adversarial session:

1. Store pending attack vectors to memory (Qdrant with `metadata.type: "adversarial_session"`)
2. On resume: reload vectors, continue from last position

## Compatibility with other modes

### With Micro Mode

Adversarial testing triggers **after each micro edit**, not after each line:

```
[Micro Mode Step] → [Apply micro edit] → [Adversarial analysis] → [Fix if broken] → [⏸️]
```

The micro edit is not complete until adversarial analysis passes.

### With Contract-First Mode

Adversarial testing applies to **implementation phase only**, not contract design:

1. Contract-First: Design interfaces (no adversarial testing)
2. Contract-First: User approves interfaces
3. Implementation begins → Adversarial Mode activates

### With Exit Criteria Mode

Add adversarial criteria automatically:

```
EXIT CRITERIA (auto-added by Adversarial Mode):
□ All code changes passed adversarial analysis
□ No BROKEN vectors remain unfixed
□ All POTENTIAL vectors either verified or acknowledged
□ No unaddressed escalations
```

## Quick reference

### Activation

```
ADVERSARIAL MODE ON                    # Standard depth
ADVERSARIAL MODE ON, depth: deep       # Deep testing
ADVERSARIAL MODE ON, depth: paranoid   # Maximum scrutiny
```

### During session

```
>        # Proceed (after all attacks pass)
skip     # Skip adversarial testing for this one change (requires justification)
deeper   # Increase depth for current analysis
reattack # Re-run attacks after manual changes
```

### Key commands

```
show vectors     # List all attack vectors for current change
add vector X     # Add custom attack vector
focus category Y # Prioritize specific attack category
persist tests    # Generate test cases from attacks
```
