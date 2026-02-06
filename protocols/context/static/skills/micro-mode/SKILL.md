---
description: Step-gated editing with DAG-based planning and continuous user steering. Activate when user says "MICRO MODE ON", "implement in micro mode", or wants maximum control over each atomic edit with pause points after every change. Each edit is limited to one function and 30 lines. User resumes with ">" or ".". Ideal for careful refactoring, high-risk changes, or when user wants to review every modification before proceeding.
---

# Micro Mode: *protocol*

> <ins>***Goal:** step-gated edits in auto-accept mode*</ins>
>
> *Maximum throughput with continuous, real-time user steering. You will make exactly **one atomic "micro edit"** at a time, then pause. The user can course-correct immediately; you must rebase on the user's edits before continuing.*

> [!IMPORTANT]
>
> The directives below are **non-negotiable hard constraints** to be followed **exactly as they are specified**.

## Entry/exit protocols

### Activation/deactivation

When the user says anything like:

- "MICRO MODE ON"
- complete this task in micro mode
- implement in micro mode

*follow this Micro Mode protocol* until you are told anything like:

- exit micro mode
- finish the task/implementation without micro mode
- "MICRO MODE OFF"

If you are unsure, confirm unambiguously with the user.

Upon exit, you must output in this exact format:

```
═══════════════════════════════════════
Micro Mode OFF
Completed: N/M steps
Remaining: [step-ids, or "none"]
DAG stored: [location, or "chat only"]
═══════════════════════════════════════
```

If there are no steps/nodes remaining and the DAG is persisted to a memory tool (Neo4j-based graph memory or Qdrant), delete the DAG from memory.

### Partial completion (pausing for later)

If the user says anything like:

- "pause for now"
- "stop here"
- "let's continue later"
- "save progress"

You must:

1. **Persist the DAG** to memory (see [Session persistence](#session-persistence)) and ensure it is updated to reflect current progress
2. **Emit pause summary**:

    ```
    ⏸️ Micro Mode PAUSED
    Completed: N/M steps
    Next ready: [step-ids]
    Blocked: [step-ids, or "none"]
    DAG stored: [location]
    Resume: "MICRO MODE ON, continue"
    ```

3. Exit micro mode protocol (but do **not** emit deactivation summary: this is a pause, not an exit)

## Core contract

### Definition: *micro edits*

One step may modify **at most**:

- **one function** (primary target)
- **≤30 total lines changed** *(added + removed)*

> [!NOTE]
> - **Line counting**: Count gross changes. Replacing 5 lines with 3 new lines = 8 changes (5 removed + 3 added).
> - **Multi-file exception**: A function rename (definition + call-site updates) counts as *one* micro edit if call-site changes are mechanical and total <10 additional lines.

If a change exceeds these limits, you *must* split it into multiple micro-steps, in this preferred order:

1. interface / signature / scaffolding
2. core logic
3. edge cases
4. tests
5. cleanup or refactor

### Hard stop after every edit

After exactly one *micro edit*:

1. output `⏸️`
2. then stop.

### Resume tokens (enabling fast control loop)

The user resumes execution by sending **one character**:

- `>` (preferred)
- `.` (equivalent)

Alternatives like "continue", "proceed", "go on" or "next edit" are also permitted for flexibility.

## User course-corrections

If the user:

- edits your code manually, or
- says anything like:

    - "I tweaked it"
    - "I changed it"
    - "Read my version"
    - "Take a look at my edits"
    - "Rebase on my edits"

You must:

1. Re-open and re-read the affected file(s) **fully**
2. Briefly confirm you are now using the current contents
3. Wait for one of the [*resume tokens* listed above](#resume-tokens-enabling-fast-control-loop) before proceeding

**Never** assume previous patch state.

## Planning: DAG / topological ordering

### Initial planning phase *(once per task/plan/implementation)*

Before editing anything, construct a **DAG of *micro edits***:

- Each node is a *micro edit*
- Each edge is a *blocking dependency* (between edits)

You must execute steps in **topological order**, never violating dependencies.

> [!IMPORTANT]
>
> #### <ins>No implicit dependencies</ins>
>
> All dependencies between steps must be **explicitly encoded** in the DAG.
>
> If step B depends on step A:
> - you must create/record a `A BLOCKS B` relationship
> - you may not rely on implied ordering
>
> If you discover a new dependency mid-task:
> - update the DAG
> - explain the change briefly
> - continue in topological order

#### Node definition *(stable ids required)*

Each node must include:

- `id` *(string, unique)*: stable, human-addressable (e.g. `parse_headers`, `validate_cfg`)
- `file` *(string)*
- `function` *(string)*
- `signature` *(string)*: signature of the function above
- `goal` *(string)*: intent/goal/nature of the change, in one sentence
- `deps` *(list of 0 or more `id`s)*: list of IDs of nodes corresponding to steps that must be completed first/that this step depends on
- `risk` *(string enum)*: *exactly one* of `low | medium | high`

    - `risk: high` *micro edits*, in particular, are defined as those touching:

        - APIs / interfaces
        - types or schemas
        - concurrency / ordering
        - serialization formats
        - invariants relied on downstream

- `type` *(string enum)*: *exactly one* of `API | IMPL | FIX | TEST | DOC`
- `status` *(string enum)*: *exactly one* of `planned|ready|in_progress|done|blocked`

    - All nodes should have `status` set as one of the following at DAG creation:

        | Value of node's `deps` list | Resulting `status` value to set |
        | --- | --- | --- |
        | Empty | `ready` |
        | Non-empty | `planned` |

    - Status values are defined as follows:

        | `status` value | Definition |
        | --- | --- |
        | `ready` | Node's `deps` list (i.e. blocking micro edits) is *empty* |
        | `planned` | Node's `deps` list is *non-empty* |
        | `blocked` | Waiting on clarification or external decision as to how or whether to implement the node's *micro edit* |
        | `done` | Node's *micro edit* was successfully applied and accepted |
        | `in_progress` | Currently working on node's *micro edit* |

> Stable IDs allow the user to give unambiguous instructions like:
> - "redo `validate_cfg`"
> - "skip `parse_headers`"
> - "run high-risk steps first"

#### Scheduling by `type` and `risk`

> *To surface design errors **before** building on top of them.*

When multiple steps are ready (deps satisfied), prefer executing based on the following heuristics in the hierarchy given (unless explicitly told otherwise, or there is a clear reason not to):

1. **steps with higher `risk` earlier**
2. nodes prioritized by `type` in this order ***(where `deps` allow)***:

  **`API → IMPL → FIX → TEST → DOC`**

### Mandatory execution loop (for every step)

> [!IMPORTANT]
>
> At any point in the execution of the loop below before the planned implementation/task at hand is complete, if the user gives a prompt explicitly outside of this loop's prescribed steps (e.g. asking a question about the code), you must **ensure the DAG is updated to reflect the current progress state before continuing**.

Until the planned implementation/task is complete, execute the steps below, in the order given and in a loop:

1. If there is currently a node with `status=in_progress` but whose changes have (ostensibly very recently) been completed (with or without changes from user), set that node's `status=done`
2. Select the next **`status=ready`** DAG node (deps satisfied) according to the [scheduling heuristics above](#scheduling-by-type-and-risk) and set that node's `status=in_progress`.
3. ***Always* re-read the target function's current contents**.

    - If the user modified it since last read (or compared to what you were expecting), acknowledge and adapt.

4. Emit the *step header* in the *exact* format below:

    ```
    Step <id>: <file>::<function>
    Signature: <exact function signature line as currently in file>
    Goal: <one sentence>
    Type: <API|IMPL|FIX|TEST|DOC>
    Risk: <low|medium|high>
    Why now: <deps satisfied>
    ```

5. Perform *stale state detection* before editing by summarizing the target function in **exactly two bullets**:

    - inputs / outputs
    - its current behavior and/or invariants

    If your summary contradicts the file contents, **pause and re-read** before proceeding.

6. Apply the *micro edit* (≤30 lines, one function)

7. Emit the *step footer* in the *exact* format below:

    ```
    Changed: <file>::<function> (±N lines)
    Check: <command> → <result>
    Next candidates: <ready step ids>
    User: ">" or "." to continue
    ```

8. Output `⏸️` and stop.

#### <ins>DAG storage and updates</ins>

- If a Neo4j-based graph memory MCP is available (preferred):

    - It is the **source of truth** for the DAG.
    - Nodes should be called `MicroEdits`; their labels' names, types and semantics should match the [Node definition](#node-definition-stable-ids-required)'s fields *exactly* **(except for `deps`)**
    - `deps` should be encoded as `(A)-[:BLOCKS]->(B)` relationships (where `A` must complete before `B`).

- If Qdrant MCP is available (fallback):

    - Store after each status change with:
    - `metadata.type`: `"micro_mode_dag"`
    - `metadata.task`: brief task description
    - `metadata.project`: project/repo name
    - `metadata.created_at`: ISO 8601 timestamp
    - Content: JSON-serialized DAG (all nodes with current status)

- Otherwise, maintain the DAG explicitly in any structural memory tools available (or, as a last resort, in chat) and update it if needed/as appropriate after every prompt.

#### <ins>Working set discipline</ins>: 3-file limit

At any time, your active working set may include **at most 3 files**.

Introducing a 4th file requires:
- pausing
- explaining why
- waiting for a [resume token](#resume-tokens-enabling-fast-control-loop) before proceeding

Purpose: minimize review friction and cognitive cache misses.

### <ins>*Revert-by-default* rule</ins> (for auto-reverts & redos)

If the user says anything like:

- "no"
- "wrong direction"
- "redo"
- "undo that"
- or manually reverts your change

You must:
1. treat the working tree as authoritative
2. assume the step you just performed is invalid
3. reattempt the step from scratch
4. pause after completion

Never defend the rejected implementation.

### Contingency plans

1. If, for any reason, you must:

   - roll back in the execution sequence by several micro-edits
   - edit/add new nodes (i.e. due to changes in implementation and/or approach)

   You must:

   - **thoroughly and scrupulously recompute deps for *all* nodes**
   - **set the status of *all* nodes in the graph accordingly** (e.g. if rolling back a node's change, set its status `done` to `ready` or `planned` as appropriate).

2. If a micro edit causes a failure (e.g. syntax error, test failure, type error, lint violation):

   1. **Mark the node** `status=blocked`
   2. **Emit error notice**:

       ```
       ⚠️ Step <id> failed
       Error: <one-line summary>
       Cause: <brief diagnosis if identifiable>
       ```

   3. **Wait for user guidance**: do not proceed to dependent steps while a blocker exists
   4. **On resolution**: set `status=ready`, re-attempt the step from scratch

> [!NOTE]
>
> A blocked step does **not** block independent parallel branches in the DAG. Continue with other `status=ready` nodes if available, or pause if all remaining nodes depend on the blocked one.

## Compatibility with other Bureau-configured workflows

### Superpowers skills *(Claude Code & Codex)*

Micro Mode is **compatible** with Superpowers skills:

- **TDD skill**: Each test-first step and implementation step becomes a micro edit. The TDD cycle (Red → Green → Refactor) maps to the DAG naturally.
- **Systematic debugging**: Investigation steps remain conversational; only actual code fixes become micro edits.
- **Code review**: Review findings can inform DAG construction; fixes are micro edits.

### Handoff guidelines

Micro Mode operates **within** a single agent session. If you need to delegate:

1. **Pause** micro mode (persist DAG)
2. **Delegate** via `clink` or `Task` tool
3. **Resume** micro mode after delegation completes

Do not attempt to run micro mode across multiple agents simultaneously.
