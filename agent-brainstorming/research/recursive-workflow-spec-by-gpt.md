# Recursive research workflow specification (completed)

> Important notes: read these first
>
> - This workflow uses 6 roles that can call each other as subagents (based on the rules in their sections) or themselves, recursively.
>
>     - Understand it first as a collection of recursive functions (where each role below corresponds to a function): `manager`, `planner`, `executor`, `extractor`, `synthesizer`, and `scout`.
>
> - The word feasible has a precise definition in this workflow specification; however, this definition is provided later in the spec, after the necessary concepts have been introduced.

## `manager` role

- Is the entry point for the workflow, and is the sole agent the user interacts with (in this way, it can be thought of as a chief of staff of sorts)

- Role:

    1. Receives broad-scoped research questions and converses with the user, insightfully helping them intuitively narrow and/or split their question into:

        1. 1 feasible query
        2. 2+ feasible subqueries

        where feasible is precisely as defined further on in this workflow's spec.

        - Critical notes about ascertaining feasibility:

            - The main role of the `manager` in this first step is that of a masterful [postdoctoral/advanced academic] researcher in whatever field(s) the query/subqueries relate to (and it must be prompted to think/analyze queries as such).

            - It has the critically-important role of determining whether a single query/subquery is feasible (i.e., can be limited to a research plan tree of a maximum depth of 3 `executor`s), using its best judgment.

            - It is the only role in this workflow which has the power to force the user to narrow down and/or split queries into subqueries in order to make them feasible: therefore, it should:

                - think deeply, scrupulously and insightfully when evaluating a query's/subquery's feasibility
                - steadfastly but respectfully refuse to launch step 2 until it is satisfied (as a result of its own deep analysis as a masterful researcher in the appropriate field(s)) that the query/subqueries are each granular/precise/limited enough in scope to be feasible

        - Note: the process in this bullet is not always necessary: it is possible that the user is already an expert at formulating research queries (or a set of subqueries) that are granular/precise/limited enough in scope to be feasible (which again, crucially, depends on the `manager` to assess).

    2. Once the narrowed research query/subqueries are finalized (i.e., the `manager` must agree that the query/subqueries are each feasible, and the user must say `Authorized to execute`):

        - If the result is a single feasible query, then the `manager` will:

            1. Delegate the query to a `planner` subagent to create a research plan for the query
            2. Delegate the returned research plan to an `executor` subagent to run it, which will return a synthesized report/analysis
            3. Report the synthesized report/analysis to the user

        - If the result is `n >= 2` feasible subqueries, then the `manager` will:

            1. Delegate each subquery to one of `n` `planner` subagents, which will each return a research plan for the subquery
            2. Delegate each research plan to one of `n` `executor` subagents, which will return synthesized findings
            3. Provide the synthesized findings to a single `synthesizer` subagent, which will synthesize the findings into a single, coherent, insightful, easy-to-read report/analysis
            4. Report the synthesized report/analysis to the user

        - Note: when delegating to a `planner` subagent, the `manager` may include a suggested research plan/tree (which must follow the planner spec and be feasible). The `planner` is free to implement/refine it, take inspiration, or ignore it.

    - For clarity, this is a hypothetical role: no file for it exists yet in this directory

## `planner` role (renamed from `specifier`)

- Creates a clear, concrete, and feasible research plan (also called research tree, since it will be structured as a tree as discussed below), based on how the `executor`, `synthesizer` and `extractor` work.

- The research plan/tree must follow this spec:

    - Root node and all interior nodes correspond to an `executor` subagent

    - Leaf nodes each correspond to (n `extractor` subagents + 1 `synthesizer` subagent), where the `synthesizer` will receive and generate its report/analysis from the coalesced results of each of the `n` `extractor`s

- Important notes for the `planner` role

    - If a `planner` has received a query to implement a research plan/tree from its parent `manager` agent, this will only be if the `manager` is assured that the query it is giving the `planner` is indeed feasible.

        - Therefore, the `planner` absolutely must return a plan that (1) follows the spec above and (2) is feasible.

        - The cognitive burden is on the `planner` to think maximally deeply, scrupulously and insightfully (in the same role of a masterful [postdoctoral/advanced academic] researcher in the relevant field(s) as the `manager`) to ensure it creates a suitable plan.

    - When delegating to a `planner` subagent, the `manager` may include a suggested research plan/tree (which must follow the planner spec and be feasible). The `planner`, following its best judgment, may implement it, take inspiration from it, or produce a different plan.

- Planner enhancements (completed specification)

    - Extractor task specs (optional, per leaf): the `planner` may attach structured task specs that the `executor` must forward to child `extractor`s as-is.

        - Fields: `questions`, `expected_format`, `acceptance_criteria`, `priority`, `budget`, and an optional `discovery_intense` flag.

        - Purpose: improve precision and reproducibility when leaves are well-understood; if omitted, the `executor` composes targeted questions (see `executor`).

    - Phase gates (interior nodes): the `planner` defines one or more phases per interior node with explicit success criteria, budgets, and `max_iterations` per phase.

        - Examples of success criteria: corroboration count, coverage of specified themes, contradiction resolution, minimum confidence thresholds.

        - Purpose: allow bounded iteration by the `executor` with clear stop/continue signals.

    - Discovery leaf (optional): a leaf whose sole objective is curated source selection for its parent node.

        - Implementation: executed via the `executor`, which spawns a `scout` (see `scout`) to sweep and triage, optionally followed by a `synthesizer` to aggregate triage results.

        - Output: a ranked, tagged, justified list of candidate sources for subsequent content ingestion leaves.

## `extractor` role

The `extractor` reads a source document and performs one or more of the following tasks as directed (and returns the result to its parent agent), based on the source's content:

- Extracts key facts
- Provides concise summaries
- Answers specific questions

### Extractor output schema

- Primary output: the requested extraction (facts, summary, or answers) with citations and a confidence score.

- Optional insights (emitted conditionally; see triggers below):

    - `follow_up_questions[]` with confidence and rationale
    - `source_identified_gaps[]` explicitly noted limitations or future work in the source
    - `linked_candidate_sources[]` (URLs/refs mentioned in the source) with context snippets and priority

- Conditional emission triggers:

    - Low confidence on key claims in the primary output
    - Source contains explicit limitations/future work sections
    - Detected contradictions within the source or versus supplied context
    - The leaf is flagged `discovery_intense` by the `planner`

- Memory: extracted atomic facts and optional insights should be stored in a knowledge base (e.g., Qdrant) with citation and confidence metadata for de-duplication and reuse by parent agents.

## `executor` role

- The `executor` executes a research plan to gather findings into a synthesized report, by delegating the 1 or more tasks that its assigned research plan prescribes it to do.

- Task types and delegation

    - Execute a research subplan for a subtopic: the `executor` will delegate this task to a newly-spawned child/subagent `executor` (which will then recursively follow these steps again itself for the research subplan/subtree assigned to it).

    - Ingest and synthesize content from `n` sources: the `executor` will

        1. Spawn `n` `extractor` subagents to ingest content from `n` sources
        2. Provide their coalesced findings to a `synthesizer` instance, which will synthesize the findings and return its report/analysis to the `executor`

    - Discovery sweep (new): when the plan specifies a discovery leaf or the current phase requires source discovery, the `executor` will

        1. Spawn a `scout` subagent to run search/crawl, triage candidates, and deduplicate
        2. Optionally spawn a `synthesizer` to aggregate triage outputs into a concise, ranked curation with inclusion/exclusion rationales

    - If there are more than 2 tasks that the `executor` delegated, then it will:

        1. Coalesce the results from each task (which will have come from either an `executor`, `synthesizer`, `scout`, and/or `extractor` subagent)
        2. Spawn a final `synthesizer` subagent to synthesize the coalesced results into a report/analysis that it will subsequently return to its parent `executor`/`manager` agent

- Question delivery to `extractor`s

    - If the `planner` provided Extractor Task Specs for a leaf, the `executor` must pass them verbatim to the `extractor`s.

    - Otherwise, the `executor` composes per-source targeted questions and a minimal rubric from the subtopic objective and prior findings. The rubric should specify scope, key spans/sections to consider, and target confidence.

    - This composition and refinement happens within the same `executor` level and must not introduce deeper `executor` levels.

- Bounded iterative execution

    - The `executor` may iterate within a phase using a bounded loop when planner-defined success criteria are not met. Each iteration may add or refine sources and questions but must not deepen the `executor` tree.

    - Controls:

        - Respect `max_iterations` and budget constraints per phase as defined by the `planner`
        - Maintain per-iteration delta logs (what changed and why)
        - Prefer monotonic improvement toward success criteria (confidence, coverage, contradiction resolution)

    - Feasibility: iterative activity must never increase the depth of `executor` levels; within a node, it may only adjust sources, extractor questions, and syntheses.

### Definition of feasible

- Now that the necessary foundational concepts have been laid out, we can precisely define what feasible means (with respect to a research plan):

    - A feasible query is one that can be researched using a concrete research plan (recall a research plan is a recursive tree made of `executor`s, `extractor`s and `synthesizer`s), such that the maximum depth of the tree is 3 `executor` levels deep.

    - In other words: if an `executor` is spawned that has an `executor` both as its parent and grandparent agents (or, similarly, does not have a `manager` as its parent or grandparent agent), then a feasible research plan must not prescribe it to spawn any `executor`s as subagents: instead, it will only spawn `extractor`s (and a `synthesizer` to synthesize the `extractor`s' findings).

- The purpose of this feasibility restriction in this workflow is to ensure the scope is limited enough to ensure:

    - Highly-accurate and high-quality performance by each role, and the workflow as a whole, at wholly answering the query

    - A careful, easy-to-read, coherent and well-thought-out treatment of each subject/topic/subtopic in both the final analysis/report, as well as the recursive analyses/reports passed up the research plan tree to parent `executor`s (if applicable)

## `synthesizer` role

- Shrewdly synthesizes findings into a report/analysis that:

    - Is coherent, insightful, and easy-to-read
    - Contains careful, thoughtfully-explained, sufficiently-detailed-without-being-pedantic treatment of each subject/topic/subtopic in the findings it receives
    - Intuitively, clearly and astutely discerns and highlights:

        - Any standout/outlier details in the findings it receives
        - Any important connections/relationships, correlations, causations, patterns and/or overarching themes between and within the findings it receives, especially if they are (1) subtle and/or hard-to-notice, and/or (2) they have an outsized impact on results

- Additional note on discovery outputs: when invoked for a discovery leaf (directly or via `scout`), the `synthesizer` returns a concise, ranked curation with inclusion/exclusion rationales and coverage balance tags to guide subsequent ingestion.

## `scout` role

- Purpose: perform scrupulous, timeboxed web sweeps and triage to assemble a high-quality, diverse, and relevant set of sources for a subtopic.

- Abilities:

    - Run search/crawl (e.g., Tavily/Firecrawl) with well-scoped queries derived from the subtopic and planner guidance
    - De-duplicate and cluster candidates; ensure coverage across key themes and perspectives
    - Spawn fast `extractor`s to quick-scan candidate sources for credibility, relevance, and content quality
    - Optionally spawn a `synthesizer` to aggregate triage findings into a ranked, tagged shortlist

- Constraints:

    - May spawn `extractor`s and a `synthesizer` but never `executor`s
    - Must adhere to strict time/token budgets as defined by its parent `executor` or the `planner`
    - Must return structured outputs with authority, recency, coverage, diversity, and rationale tags

- Output:

    - A curated, ranked, justified list of candidate sources with tags and suggested coverage balance; suitable for subsequent ingestion by `extractor`s within the current `executor` node

