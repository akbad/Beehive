# Style guidance for agents

> [!IMPORTANT]
>
> - *All* of the following guidelines/directives:
>   
>   - **must** be read/executed (as appropriate) *before* beginning any task.
>   - apply to ***any and all* file additions/edits you make.**
> 
> - If a Markdown file you're editing has ***any*** portion that does not obey any of the directives, **fix the issue(s) immediately**
>     
>   - *Exception: **emojis** (see below)*

## Formatting and content structure

### General directives

> [!IMPORTANT]
>
> ### Key directives
>
> Ensure, above all, that your content is:
>
> - **formatted such that it is easy to *quickly read/scan through*** by humans
> - **written *coherently and cohesively*, such that it is *easy to develop a mental model for***
>
> The directives below are meant to ensure these 2 outcomes based on the user's preferences: follow them well.

Content you write should:

- Be structured, in most cases, as a **bulleted list with nesting of bullets** (to as many levels as you desire) to ensure that the content, via its structure, best fits the *"key directives"* above.

    - Bullets should contain at most **1 full sentence** (unless there is a *very* compelling reason to include more in the same bullet). To add more content past this, place it in nested bullets under the main one.
    - Do *not* change/overwrite tables of contents to match this format: these are managed by a custom VSCode extension and should remain as-is.

- Include **rich formatting** *(but don't overdo it; too much of these, inversely, makes a document **harder** to read!)*:

    - bolds
    - italics
    - underlines (via `<ins> ... </ins>`)
    - GitHub-flavoured Markdown alerts (`[!NOTE]`, `[!IMPORTANT]`, `[!CAUTION]`, etc.)

- Include tables where appropriate. However:

    - Any given cell of a table should **never** contain more than 20-25 words.
    - If you have more content to include in a given row of a table than can be fit/expressed/condensed reasonably into 20-25 words without sounding unnaturally/incomprehensibly terse, then either:

        - Convert your content to use the bulleted-list formatting described above
        - Add the excess content related to the table item/row to a separate content section (i.e. anchored by a header of the appropriate level) and link to it from within the table row/column/cell as appropriate

            > Instead of a whole linked section, you can a footer if the excess content is pedantic/low-volume. Use your best judgment w.r.t. this.

- Any code blocks you include should have one or both of:

    - Extensive comments explaining any non-obvious/obscure code
    - Well-structured, accompanying English descriptions that use the bulleted-list format described above to match pseudocode structurally.

> [!NOTE]
>
> The "bulleted list" directive above can be ignored if:
>
> - the user gives you *direct instructions* to structure the content alternatively you believe there is a *very strong* reason to structure your content in an alternate fashion *(e.g. essay-style, using long paragraphs)*
> - there is a *very compelling/strong* reason to structure the content alternatively
>
> **IMPORTANT: Before proceeding with any alternative content structure, you *must* ask the user and get their approval via a clear confirmation.**

### Hard directives you *must* follow

### <ins>Always</ins> use

- Indents with **4 spaces** *(<ins>not</ins> 2)*
- **Sentence case/downstyle** in any "capitalized" formatting (e.g. headers)
- Empty lines around groups of list bullets, including around nested groups of bullets *within* a list *(i.e. as done in this document)*

    > *<ins>Examplars</ins>*
    >
    > ```markdown
    > Some preceding content, separated from the list by the newline that precedes it...
    >
    > - Level 1 bullet
    > - Level 1 bullet
    > - Level 1 bullet
    >
    >     - Level 2 bullet
    >
    > - Level 1 bullet
    >
    >     1. Level 2 numbered element
    >     2. Level 2 numbered element
    >
    >         - Level 3 bullet
    >
    > - Level 1 bullet
    > - Level 1 bullet
    >
    > Content following the list, separated from the list by the newline that follows it...
    > ```
    >
    > ```markdown
    > ## Some preceding header, separated from the list below by a newline, as always...
    >
    > - Level 1 bullet
    > - Level 1 bullet
    >
    >     - Level 2 bullet, preceded by newline
    >     - Level 2 bullet
    >
    >         - Level 3 bullet
    >
    >     - Level 2 bullet
    >
    >         1. Level 3 numbered list element; our rules apply to bulleted lists, numbered lists, any kind of list!
    >         2. Level 3 numbered list element
    >         - Level 3 bullet
    >
    >     - Level 2 bullet
    >     - Level 2 bullet
    >     1. Level 2 numbered list element (interspersed bullets and numbered elements are rare but possible at any indentation level! Just use your common sense, follow the rules and you'll be fine!)
    >
    >         - Level 3 bullet
    >
    > Content following the list, separated from the list by the newline that follows it...
    > ```

### <ins>Never</ins> use

- Section numbers in headers *(unless explicitly requested by the user)*
- Horizontal separators (i.e. `---`)
- Emojis

    - *If they are already there, do <ins>not</ins> delete them* **(this is an exception to the rule above)**
    - Don't add any more of your own without asking first.

        - In particular, only suggest emojis if you believe there is a *very strong* reason to add them *(i.e. to increase salience of key headings/classifications/other content to ensure a more convenient reading experience for the user)*.
