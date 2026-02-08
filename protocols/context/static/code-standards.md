# Coding style & standards

<!--
  Bureau's default coding standards file.
  Agents read this at startup and assess mode audits against it.
  Override: configure `code_standards` in directives.yml or local.yml with your own files.
-->

***Contents:***

- [Comments](#comments)
  - [Depth (key standard)](#depth-key-standard)
  - [Formatting](#formatting)
- [Naming](#naming)
- [Structure and organization](#structure-and-organization)
  - [File-level](#file-level)
  - [Function-level](#function-level)
- [Error handling](#error-handling)
- [Logging and observability](#logging-and-observability)
- [DRY and abstraction](#dry-and-abstraction)
- [Types and data modeling](#types-and-data-modeling)
- [Correctness and defensiveness](#correctness-and-defensiveness)
- [Testing](#testing)
- [Dependencies and coupling](#dependencies-and-coupling)
- [Pragmatism](#pragmatism)


## Comments

### Depth (key standard)

#### Tier 1: *always* required

- **Design rationale block** at the top of any file or major section implementing non-trivial logic

    - What the component does (1-2 sentences)
    - Why this approach was chosen (if alternatives exist)
    - Key invariants the reader must keep in mind

> [!NOTE]
>
> The design rationale block is implemented as a **comment block**, *distinct* from any language-level docstrings.

- **"Why, not what"** on every non-obvious branch, conditional, or control-flow decision

    - Explain the *reasoning* behind the decision, not what the code literally does

- **Struct field / config value contracts** for any field whose purpose isn't obvious from its name and type alone

    - State what it controls, why it exists, and any constraints on valid values

#### Tier 2: required when applicable

- **Rejected-alternatives** documentation when a design decision has non-obvious trade-offs

    - Name the alternative, say why it was rejected

- **Safety / correctness / starvation** comments when code implements a protective mechanism

    - Describe the threat (what breaks without this code)
    - Describe the invariant being enforced

- **Protocol step narration** for any multi-step algorithm or protocol implementation

    - Number the steps or use a clear sequential narrative

- **Constant justification** for any magic number, threshold, or tuning parameter

    - State whether the value is empirical or formally derived, where it came from, and whether it can be tuned

#### Tier 3: recommended for complex systems code

- **Formal spec / standard references** when implementing a protocol, standard, or well-defined algorithm

    - Cite the spec section, RFC, or formal model

- **Locking / concurrency discipline** comments when multiple locks or atomic operations are involved

    - State what lock is held and what ordering is required

### Formatting

#### Inline comments

- Start with **lowercase** (unless beginning with a proper noun)
- **Omit trailing periods**
- Lead with **action verbs** like "format", "skip", "patch", "retrieve"
- Use a `note` prefix for non-obvious implementation details or external dependencies

#### What to avoid

- Do not leave commented-out code
- Do not add type annotations in comments (put them in signatures)
- Do not add author/date stamps
- Avoid trailing comments at the end of code lines (unless concise)

#### Section headers (in long files)

- Use commented separator lines of many `─` characters to divide logical sections (and occasionally `━` for more differentiation or to delineate major sections, if there are many)

## Naming

- Where applicable, use **domain terms** from the project's ubiquitous language in types, functions, variables, and tests

    - If the domain calls it a "replica", don't name it `follower_node` or `secondary`
    - If two bounded contexts use the same word differently, disambiguate explicitly (e.g. `billing.Account` vs `auth.Account`)

- Name functions and methods as **actions** (verbs): `drain_queue`, `elect_leader`, `reconcile_state`

    - *Exception:* pure accessors and predicates read better as nouns/adjectives: `is_quorum`, `leader_id`

- Name tests like **mini-specs**: `should_reject_expired_token`, `given_partition_when_write_then_timeout`

    - The name alone should tell you what broke when the test fails

- **Name length should be proportional to scope**

    - Narrow scope (loop variable, short closure) → short names are fine: `i`, `n`, `ch`, `err`
    - Wide scope (module-level, exported, config) → precise and unambiguous: `checkpoint_interval_ms`, `max_retry_attempts`
    - A longer name that's instantly clear beats a short name that requires context — but `current_iteration_index` in a 3-line loop is noise

- **Constants and thresholds** should get descriptive names; *never* bare literals or magic numbers

    - e.g. `QUORUM_TIMEOUT_MS = 500`, and not `500` inline
    - See the *Constant justification* directive in [tier 2 of the commenting depth standard](#tier-2-required-when-applicable) for the accompanying comment requirement

## Structure and organization

### File-level

- **One concept per file** in most cases

    - A file should have a single, articulable reason to exist
    - *Exception:* tightly-coupled small types (e.g. a value object and its builder, or an enum and its parser) can coexist if separating them adds navigation overhead without clarity
    - In C/C++, the natural unit is a **data structure and its operations** (the `.c`/`.h` pair); this may span several "concepts" in the OOP sense, and that's idiomatic
    - In Go, the natural unit is a **package**, which may contain multiple files; keep each file focused on a single type or functional group within the package

- **Design rationale at the top** (as specified in [Tier 1 of the commenting depth standard](#tier-1-always-required))

- **Dependency direction matters** (see [Dependencies and coupling](#dependencies-and-coupling) for the full directive)

- **Section separators** (`─` / `━`) for files longer than ~200 lines (see *Comments > Section headers*)

### Function-level

- **Small surface area**: functions should do *one thing* and accept only the arguments they *actually need*

    - If a function is longer than ~40-50 lines, look for extractable sub-operations
    - If a function takes 5+ parameters, it's probably doing too much or needs a config/options object

        - In languages without keyword arguments or builder patterns (C, Go), functions routinely take 5-6 parameters; judge by *conceptual* cohesion, not raw count

    <p></p>

    > **Note:** these are *guidelines*, not laws. A 60-line function that reads linearly and does one coherent thing is better than three 20-line functions with tangled control flow between them.

- **Early returns** for guard clauses and precondition checks

    - Validate inputs and bail at the top; keep the happy path at the lowest nesting level
    - Avoid deep nesting: if you're 4+ levels deep, refactor

- **Explicit state transitions** for objects with lifecycle states

    - Model workflows *as methods* (`activate()`, `cancel()`, `promote_to_leader()`) and *not* bare field assignments
    - Plain data structures (config structs, packet buffers, intermediate results) don't need this; direct field writes are idiomatic and correct there

## Error handling

- **Handle errors *close* to where they occur**, with context sufficient for debugging

    - Wrap/annotate errors as they propagate upward so the final message reconstructs the call chain (e.g. Go's `fmt.Errorf("…: %w", err)`, Rust's `anyhow::Context`, Python's exception chaining, Java's cause chains)
    - Never swallow errors silently; if intentionally ignoring, comment *why*

- **Distinguish recoverable errors from fatal ones** in the type system or API (where the language allows)

    - The caller should know from the signature whether an error is retriable, permanent, or a bug

- **Error paths deserve the same rigor as happy paths**

    - Invalid inputs, network errors, timeouts, permission denials, resource exhaustion, etc. should all be *explicitly* handled
    - Seeing 20 "should succeed when..." tests and only 2 "should fail when..." tests ⇒ failure modes are undertested ⇒ code smell

- **Fail fast, fail loud** on invariant violations

    - If a precondition that *must* hold is violated, crash or panic with a clear message — don't attempt "best effort" recovery from a state that should be impossible
    - Reserve graceful degradation for *expected* failures (network partitions, timeouts), not *bugs*

## Logging and observability

- **Structured logging over unstructured strings**

    - Log entries should be machine-parseable (key-value pairs or JSON), not `printf`-style prose
    - Include **context fields** that enable filtering and correlation: request ID, node ID, operation name, relevant entity IDs

- **Log levels have precise semantics**; don't blur them

    - **`ERROR`**: something is broken and needs human attention (page-worthy in production)
    - **`WARN`**: unexpected condition that the system handled, but should be investigated if it recurs
    - **`INFO`**: expected lifecycle events (startup, shutdown, config reload, leader election, connection established)
    - **`DEBUG`**: development-time detail, never expected in production log volume

- **Correlation IDs for distributed traces**

    - Every request or operation that crosses a process/service boundary should carry a trace/correlation ID
    - Propagate it through all downstream calls and include it in every log entry for that operation

- **Log at boundaries, not at every function call**

    - Log when:

        - entering/exiting a module boundary
        - on errors, and
        - on significant state transitions

    - Interior helper functions generally shouldn't log; instead, they should return errors to callers who have enough context to log meaningfully
    - If a function is logging *and* returning an error, one of them is redundant. The caller should log the error with more context.

## DRY and abstraction

- **Extract only when the duplication is *real* and *likely to co-evolve***

    - Two code blocks that *look* similar but serve different domains or change for different reasons are *not* duplication — they're coincidence
    - Three occurrences is a reasonable threshold; two is often premature

- **Abstractions must earn their keep**

    - Every layer, interface, or indirection should have a *concrete justification*: testability, swappability, or encapsulation of a genuinely volatile decision
    - If a function is called from exactly one place and exists only to "keep things clean", inline it
    - A helper with 6 parameters used to avoid 3 lines of repetition is a net loss

- **Inline is fine when it's clearer**

    - Three similar lines of straightforward code is often better than a premature abstraction
    - Code is read far more often than written; optimize for the reader, not the writer's DRY instinct
    <p></p>

    > **Critical distinction:**
    >
    > The enemy is not repetition, per se, but rather **divergence risk**: places where the same invariant is enforced in *multiple* spots and one of them will inevitably fall out of sync with the others (without strenuous and diligent maintenance). *That* is the duplication worth killing.

- **When you *do* abstract, make the abstraction *obvious***

    - Name it after *what it does for the caller*, not *how it does it*
    - If the caller still needs to understand the internals to use it correctly, the abstraction is leaking

## Types and data modeling

- **Make invalid states *unrepresentable***

    - Use the type system to prevent nonsense: `Money`, `Email`, `NonEmptyList`, `NodeId`.

        - A type system's value is severely diminished if the types are merely raw primitives with validation scattered across callers

    - Constructors/factory methods enforce invariants; if it exists, it's valid

- **Value objects for data with rules**

    - If a value has units, formatting, validation, or equality semantics beyond raw comparison, give it a type
    - Value objects should have **value semantics**: prefer immutability; in languages where full immutability is impractical (C, Go), enforce it by convention and document the contract

- **Reference other aggregates by ID, not by object**

    - `order_id: OrderId` — not `order: Order`
    - This keeps aggregate boundaries crisp and prevents accidental coupling

- **Prefer narrow types over wide ones**

    - `NodeId` > `string`, `Port` > `int`, `Duration` > `float`
    - Why:

        - This is portable across tiny scripts and million-line codebases
        - It catches bugs at compile time that would otherwise surface in production

## Correctness and defensiveness

- **Encode invariants close to the data they constrain**

    - A constraint documented in a comment three files away is a constraint that *will* be violated
    - The best invariant is one the compiler/runtime enforces automatically

- **Handle concurrency with explicit discipline**

    - **Document protected state at the lock declaration site**: the comment on a mutex should list exactly which fields it guards
    - **Establish and document lock ordering** to prevent deadlocks. For example, if lock A must be acquired before lock B, say so *once* at the declaration and enforce everywhere
    - State what the *threat* is if the discipline is violated (see the *Locking/concurrency discipline* section in [Tier 3 of the commenting depth standards](#tier-3-recommended-for-complex-systems-code))
    - Prefer the **weakest sufficient memory ordering** (`acquire`/`release` over `seq_cst`) when the correctness argument is clear; default to stronger ordering when unsure
    - Prefer message-passing or immutable data over shared mutable state when the design allows

- **No `sleep()` in tests; no real clocks in test assertions**

    - Inject a clock/scheduler/virtual time source
    - Timing-sensitive assertions are the *#1* source of flaky tests

- **Edge cases are first-class citizens, *not* afterthoughts**

    - Partitions, crash loops, empty collections, zero-length inputs, maximum-size inputs, unicode edge cases, concurrent mutations, etc.... consider them during **design**, *not* after the happy path is "done"

## Testing

- **Test behavior, not implementation**

    - Assert on *observable outcomes* (return values, state changes, side effects), not on which internal methods were called or in what order
    - A refactor that preserves behavior should not break any test; if it does, the test is coupled to implementation, not to correctness

- **One reason to fail per test**

    - Each test should verify *one logical assertion* so that a failure pinpoints exactly what broke
    - Multiple assertions are fine when they verify facets of the *same* behavior (e.g. checking both the status code and the response body of an API call)

- **Use consistent test structure**

    - Follow **Arrange → Act → Assert** (or equivalently, Given → When → Then) in every test
    - This makes tests scannable: setup is visually separated from the action and the verification

- **Prefer real dependencies over mocks when practical**

    - Mocks are appropriate at *module boundaries* (network, disk, external APIs) but not for internal collaborators
    - Over-mocking produces tests that pass while the real system is broken: the tests are verifying a fantasy, not the actual wiring
    - When you *do* mock, mock *interfaces* (not concrete classes), and assert on *contracts*, not call counts

- **Property-based tests for invariants**

    - When a function has a well-defined invariant (idempotency, commutativity, encode-then-decode round-trip, sort stability), express it as a *property* and let the framework generate inputs
    - Property tests find edge cases that hand-written examples miss, especially around boundary values, empty inputs, and unicode

- **Test failures must be self-diagnosing**

    - A failed test should tell you *what* failed, *what was expected*, and *what was actually observed*, all *without* requiring you to attach a debugger
    - Include descriptive messages in assertions; avoid bare `assert x` without context
    - Name tests like mini-specs (see [Naming](#naming)) so the test name alone tells you what broke

## Dependencies and coupling

- **Depend on interfaces at module boundaries; depend on implementations inside modules**

    - Within a module, concrete types are fine: over-abstracting internals creates indirection without benefit
    - At module boundaries, interfaces allow swapping implementations, fakes for testing, and independent evolution

- **Dependency direction flows inward**: domain ← application ← infrastructure

    - Domain code has zero external dependencies; in particular, domain models must be **persistence-ignorant** — no ORM annotations, no SQL, no serialization concerns leaking into the domain layer
    - Application code orchestrates domain + infra but doesn't contain business rules
    - Infrastructure adapters are leaf nodes

- **Anti-corruption layers at integration boundaries**

    - When integrating with external systems, legacy code, or third-party APIs, translate their model into *your* domain's language at the boundary; don't let foreign concepts leak inward
    - The translation layer is the *only* place that knows the external system's schema, naming, and quirks

- **Keep the blast radius of changes small**

    - A change to module A should not force changes in modules B, C, and D unless they *genuinely share* the changed concern
    - If a single-line change causes a cascade of 10 file edits, the coupling is too tight

## Pragmatism

- **Correctness > velocity**, but **shipping > perfection**

    - Invest in correctness where failures are *costly* (data loss, security, corruption, distributed state)
    - Accept "good enough" where failures are *cheap* (formatting, log messages, dev tooling UX)

- **Write idiomatic code for the language you're in**

    - Don't import patterns from another language wholesale (e.g. Java-style class hierarchies in Go, OOP patterns in C, Rust borrow-checker thinking in Python)
    - Study how the language's best practitioners write code and follow those conventions: idiomatic code is readable to the community that maintains it

- **Over-engineering is as bad as under-engineering**

    - Don't add feature flags, backward-compatibility shims, or plugin systems for hypothetical future requirements
    - Don't create abstractions for one-time operations
    - The right amount of complexity is the *minimum* needed for the current task
