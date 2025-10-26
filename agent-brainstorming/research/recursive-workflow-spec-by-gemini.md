# The Autonomous Recursive Research Workflow

> **Important notes: read these first** 
> 
> - This workflow uses 6 roles that can call each other as sub-agents (based on the rules in their sections) or themselves, recursively.
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

            1. Delegate the query to a `planner` sub-agent to create a research plan for the query.
            2. Delegate the returned research plan to an `executor` sub-agent to run it, which will return a synthesized report/analysis.
            3. Report the synthesized report/analysis to the user.

        - If the result is `n >= 2` *feasible* subqueries, then the `manager` will:
          
            1. Delegate each subquery to one of `n` `planner` sub-agents, which will each return a research plan for the subquery.
            2. Delegate each research plan to one of `n` `executor` sub-agents, which will return synthesized findings.
            3. Provide the synthesized findings to a single `synthesizer` sub-agent, which will synthesize the findings into a single, coherent, insightful, easy-to-read report/analysis.
            4. Report the synthesized report/analysis to the user.

## `Librarian` role *(new role)*

- A specialized agent responsible for discovering, assessing, and vetting information sources.
- Role:
    1. Receives a research topic or a specific information requirement from a `planner` or a looping `executor`.
    2. Performs broad web searches to gather a wide pool of potential source URLs.
    3. For each potential source, it spawns a temporary `extractor` sub-agent to perform a quick credibility and relevance scan.
    4. Based on the `extractor` scans, it filters the pool down to a list of high-quality, relevant, and credible source URLs.
    5. Returns the vetted list of source URLs to the calling agent.

## `planner` role *(renamed from `specifier`)* 

- Creates a clear, concrete, and *feasible* **research plan** (also called **research tree**).
- Role:
    1. Receives a feasible query from the `manager`.
    2. **Delegates to the `Librarian`**: Calls the `Librarian` agent with the core research topic to obtain a vetted list of source URLs.
    3. **Designs the Research Tree**: Constructs the research plan/tree where:
        - **Root and interior nodes** correspond to an `executor` sub-agent and its sub-goal.
        - **Leaf nodes** correspond to a specific task for an `extractor`. The plan for a leaf node is a tuple: `(source_url, task_type, task_detail)`.
            - `source_url`: The vetted URL from the `Librarian`.
            - `task_type`: An enum of `[SUMMARIZE, EXTRACT_KEY_FACTS, ANSWER_QUESTION]`.
            - `task_detail`: For `ANSWER_QUESTION`, this contains the specific question string.
    4. Returns the completed, precise research plan to the `manager`.

## `extractor` role *(upgraded)*

- Reads a source document and performs a directed task.
- Role:
    1. Receives a `(source_url, task_type, task_detail)` tuple from an `executor`.
    2. Ingests the content from the source URL.
    3. Performs the specified task (summarize, extract facts, or answer a specific question).
    4. **Returns a structured object**: The output is a dictionary containing the primary findings as well as discovered metadata:
        ```json
        {
          "result": "The summary or answer to the question.",
          "follow_up_questions": ["A list of new questions that arose during reading."],
          "identified_gaps": ["A list of topics the source acknowledged it did not cover."],
          "new_sources_mentioned": ["A list of URLs or references for further investigation found within the source."]
        }
        ```

## `executor` role *(upgraded)*

- Executes a research plan recursively and performs autonomous quality control.
- Role:
    1. **Execution**: The `executor` receives a research plan (or sub-plan) and delegates its tasks:
        - *Execute a research sub-plan*: Delegates the task to a newly-spawned "child" `executor`.
        - *Ingest and synthesize content*: Spawns `n` `extractor` sub-agents with their precise tasks. It then provides their coalesced structured findings to a `synthesizer` instance.
    2. **Self-Correction Loop**: After receiving the synthesized report from its child `synthesizer` or sub-`executor`s, the `executor` performs a crucial **evaluation step**:
        - It compares the received report against its original goal.
        - It specifically checks for `identified_gaps` or `follow_up_questions` noted in the report.
        - **If the report is sufficient**, it is finalized and passed up to the parent agent.
        - **If the report is insufficient**, the `executor` autonomously initiates a new action to address the deficiency. This may involve:
            - Calling the `Librarian` to find new sources to fill a specific gap.
            - Calling the `planner` to generate a new sub-plan to answer a follow-up question.
            - It then re-runs the execution step with this new task and integrates the results. This loop continues until the `executor` is satisfied with the quality of its result.

### Definition of *feasible*

> A ***feasible*** query is one that can be researched using a concrete research plan, such that the **maximum depth of the tree is 3 `executor` levels deep**. 
> 
> In other words: if an `executor` is spawned that has an `executor` both as its parent and grandparent agents (or, similarly, doesn't have a `manager` as its parent or grandparent agent), then a ***feasible*** research plan **must *not* prescribe it to spawn any executors as sub-agents:** instead, it will only spawn `extractor`s (and a `synthesizer` to synthesize the `extractor`s' findings).

## `synthesizer` role *(upgraded)*

- Synthesizes findings from multiple structured inputs into a coherent, insightful report.
- Role:
    1. Receives a list of structured objects from `extractor`s or reports from sub-`executor`s.
    2. **Synthesizes primary content**: Integrates the main `result` from each input into a unified narrative, identifying themes and contradictions as before.
    3. **Aggregates and Highlights Metadata**: Explicitly processes the `follow_up_questions` and `identified_gaps` from its inputs. The final report includes dedicated sections such as "Open Questions for Further Research" and "Identified Knowledge Gaps," making the state of the research explicit.
    4. Returns the comprehensive report to its parent `executor`.
