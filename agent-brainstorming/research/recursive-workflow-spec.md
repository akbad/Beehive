# New "recursive" research workflow specification to evaluate

> **Important notes: read these first** 
> 
> - This workflow uses 5 roles that can call each other as subagents (based on the rules in their sections) or themselves, recursively.
>       
>       - Thus, before you analyze this workflow's merits, understand it first as a collection of recursive functions (where each role below corresponds to a function).
>
> - The word *feasible* has a precise definition in this workflow specification; however, this definition isn't provided until further along in the spec, once the necessary concepts to define it have been introduced.

## `manager` role 

- **Is the entry point for the workflow**, and is **the sole agent the user interacts with** *(in this way, it can be thought of as a "chief of staff" of sorts)*

- Role: 
  
    1. Receives broad-scoped research questions and converses with the user, insightfully helping them intuitively narrow and/or split their question into: 
    
        1. 1 *feasible* query
        2. 2+ *feasible* subqueries 

        where *feasible* is precisely as defined further on in this workflow's spec.
        
        > **Critical notes about ascertaining feasibility:**
        > 
        > - The **main role** of the `manager` in this first step is that of a "masterful [postdoctoral/advanced academic] researcher" in whatever field(s) the query/subqueries relate to (and it must be prompted to think/analyze queries as such). 
        >       
        >       - This is because it has the **critically-important role** of *determining whether a single query/subquery is feasible (i.e. can be limited to a research plan tree of a maximum depth of 3 `executor`s), using its best judgment*
        >       - It is the **only role** in this workflow which has the power to force the user to narrow down and/or split queries into subqueries in order to make them feasible: therefore, it should:
        >        
        >           - **think deeply, scrupulously and insightfully** when evaluating a query's/subquery's *feasibility*
        >           - **steadfastly but respectfully refuse** to launch step 2 until it is satisfied (as a result of its own deep analysis as a "masterful researcher" in the appropriate field(s)) that the query/subqueries are [each] granular/precise/limited enough in scope to be *feasible*
        >
        > - Note the process in this bullet isn't entirely necessary: it is possible that the user is already an expert at formulating research queries (or a set of subqueries) that are granular/precise/limited enough in scope to be *feasible* (which again, crucially, depends on the `manager` to assess). 

    2. Once the narrowed research query/subqueries are finalized (i.e. the `manager` *must* agree that the query/subqueries are [each] *feasible*, **AND** the user *must* say `Authorized to execute`): 
        
        - If the result is a single *feasible* query, then the `manager` will:

            1. Delegate the query to a `planner` subagent to create a research plan for the query
            2. Delegate the returned research plan to a  `executor` subagent to run it, which will return a synthesized report/analysis
            3. Report the synthesized report/analysis to the user

        - If the result is `n >= 2` *feasible* subqueries, then the `manager` will:
          
            1. Delegate each subquery to one of `n` `planner` subagents, which will each return a research plan for the subquery
            2. Delegate each research plan to one of `n` `executor` subagents, which will return synthesized findings
            3. Provide the synthesized findings to a single `synthesizer` subagent, which will synthesize the findings into a single, coherent, insightful, easy-to-read report/analysis
            4. Report the synthesized report/analysis to the user

        - Note: if the `manager` so chooses, when delegating to a `planner` subagent, it can also include a "suggested research plan/tree" (which must follow the spec for the research plan/tree described in the `planner` section below, and of course be *feasible*) if it has thought of one/sketched one out as part of its deep analysis in step 1 above. The `planner` is free to (as it sees fit, following its best judgment):
          - implement/hammer out the details of this suggested plan and return it as its final plan
          - create a different plan inspired by the suggested one
          - not draw any inspiration from the suggested plan and return an entirely different one 

    - *For clarity, this is a hypothetical role: no file for it exists yet in this directory*

## `planner` role *(renamed from `specifier`)* 

- Creates a clear, concrete, and *feasible* **research plan** (also called **research tree**, since it will be structured as a tree as discussed below), based on how the `executor`, `synthesizer` and `extractor` below work.
- The research plan/tree must follow this spec:

    - **Root node + all interior nodes correspond to an `executor` subagent**
    - **Leaf nodes each correspond to (`n` `extractor` subagents + 1 `synthesizer` subagent)**, where the `synthesizer` will receive and generate its report/analysis from the coalesced results of each of the `n` `extractor`s

### Important notes for the `planner` role
    
- If a `planner` has received a query to implement a research plan/tree from its parent `manager` agent, this will only be if the manager is **assured** that the query it is giving the `planner` **is indeed *feasible***.
    
    - Therefore, the `planner` ***absolutely must* return a plan that (1) follows the spec above *and* (2) is *feasible*.** 
          
    - The cognitive burden is on the `planner` to think maximally deeply, scrupulously and insightfully (in the same role of a "masterful [postdoctoral/advanced academic] researcher" in the relevant field(s) as the `manager`) to ensure it creates a suitable plan  

- Note: if the `manager` so chooses, when delegating to a `planner` subagent, it can also include a "suggested research plan/tree" (which must follow the spec for the research plan/tree described in the `planner` section below, and of course be *feasible*) if it has thought of one/sketched one out as part of its deep analysis in step 1 above. The `planner` is free to (as it sees fit, following its best judgment as a "masterful [postdoctoral/advanced academic] researcher" in the relevant field(s)):
      
    - implement/hammer out the details of this suggested plan and return it as its final plan
    - create a different plan inspired by the suggested one
    - not draw any inspiration from the suggested plan and return an entirely different one 

## `extractor` role

The `extractor` reads a source document and performs one or more of the following tasks as directed (and returns the result to its parent agent, of course), based on the source's content:
  
- Extracts key facts
- Providing concise summaries
- Answering specific questions

## `executor` role

- The `executor` executes a research plan to gather findings into a synthesized report, by delegating the 1 or more *tasks* that its assigned research plan prescribes it to do.

- Role:

    - The tasks in the research plan assigned to the `executor` will be one of the following (and subsequently be delegated as specified below):

        - *Execute a research subplan for a subtopic*: the `executor` will delegate this task to a newly-spawned "child"/subagent `executor` *(i.e. which will then recursively follow these steps again itself for the research subplan/subtree assigned to it)*
        - *Ingest and synthesize content from `n` sources*: the `executor` will

            1. Spawn `n` `extractor` subagents to ingest content from `n` sources
            2. Provide their coalesced findings to a `synthesizer` instance, which will synthesize the findings and return its report/analysis to the `executor`

    - If there are *more than 2 tasks* that the `executor` delegated, then it will:
        
        1. coalesce the results from each task (which, to the attentive reader, will have each come from either an `executor` or `synthesizer` subagent)
        2. spawn a "final" `synthesizer` subagent to synthesize the coalesced results into a report/analysis that it will subsequently return to its parent `executor`/`manager` agent

### Definition of *feasible*

- Now that the necessary foundational concepts have been laid out, we can precisely define what *feasible* means (w.r.t. a research plan, and ):

    > A ***feasible*** query is one that can be researched using a concrete research plan (recall a research plan is a recursive tree made of `executor`s, `extractor`s and `synthesizer`s), such that the **maximum depth of the tree is 3 `executor` levels deep**. 
    > 
    > In other words: if an `executor` is spawned that has an `executor` both as its parent and grandparent agents (or, similarly, doesn't have a `manager` as its parent or grandparent agent), then a ***feasible*** research plan **must *not* prescribe it to spawn any executors as subagents:** instead, it will only spawn `extractor`s (and a `synthesizer` to synthesize the `extractor`s' findings).

- The purpose of this "*feasibility* restriction" in this workflow is to ensure the scope is limited enough to ensure:
    
    - Highly-accurate and high-quality performance by each role, and the workflow as a whole, at wholly answering the query
    - A careful, easy-to-read, coherent and well-thought-out treatment of each subject/topic/subtopic in both the final analysis/report, as well as the "recursive" analyses/reports "passed up" the research plan tree to parent `executors` (if applicable)

## `synthesizer` role

- Shrewdly synthesizes findings into a report/analysis that:
    
    - Is coherent, insightful, and easy-to-read
    - Contains careful, thoughtfully-explained, sufficiently-detailed-without-being-pedantic treatment of each subject/topic/subtopic in the findings it receives
    - Intuitively, clearly and astutely discerns and highlights:
        
        - Any **standout/outlier details** in the findings it receives
        - Any **important connections/relationships, correlations, causations, patterns and/or overarching themes** between and within the findings it receives, *especially* if they are (1) **subtle and/or hard-to-notice**, ***and/or*** (2) they have an **outsized impact on results**
  
- What the `synthesizer` tends to aim for when writing its report depends on if the findings came from:

    - **2+ `executor`s and/or [subagent] `synthesizer`s (i.e. when spawned as the "final" `synthesizer` by its parent `executor`):** the `synthesizer` will lean towards maintaining as many relevant details/points/notes as possible (perhaps all of them, if they're all relevant) in the report/analysis it writes (since the findings it receives will have already all been pre-processed by another `synthesizer`)
    - **2+ `extractor`s (i.e. when spawned by the `executor` to synthesize ingested content from several sources):** the `synthesizer` will lean towards trimming irrelevant details/points/notes, but will still try to keep as many as possible if they are part of a visible connection/relationship, correlation, causation, pattern and/or overarching theme (or are even remotely likely to be when combined with the results of another `synthesizer` further up the research plan/tree)


<!-- 

-- Remaining TODOs --

1. Determine which role (or possibly a new one) should pass a specific question/task to an extractor about a source
2. Determine which role (or possibly a new one) should perform scrupulous "sweeps" of the web to gather appropriate sources (which should also include spawning `extractor`s to quickly scan and assess a source's credibility, as well as the merits [based on its contents] for being included/investigated further)
3. Determine if the executor (or possibly a new role) should run in a loop (instead of "just once", delegating static tasks as pre-determined for it by its assigned research plan/tree)
4. Whether extractors should also return lists of one or more of

    - Follow-up questions they thought of (especially if they're necessary for fully understanding the content/material/situation described in their assigned source)
    - Gaps explicitly identified by their assigned source that should be further investigated
    - Further sources to investigate (if directly linked to/mentioned/referred to within their assigned source)
  
-->