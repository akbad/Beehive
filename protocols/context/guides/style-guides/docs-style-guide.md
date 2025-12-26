# Guide for working on this repo

## Style guide

### Markdown

- Any and all indents in the file should be with 4 spaces (and not 2, for example)
- Headers:
    
    - Should not include numbering (as if they were numbered lists)

        ```markdown
        <!-- BAD -->

        # Doc title
        
        ## 1) Introduction

        Some intro content.

        ## 2) Table of contents

        Table of contents would go here.
        ``` 

        ```markdown
        <!-- GOOD --> 
        <!-- Instead of using numbering, section headers simply flow in a natural order. No need to overthink it! -->

        # Doc title
        
        ## Table of contents

        Table of contents would go here.
        
        ## Introduction

        Some intro content.
        ``` 
        
    - Should be capitalized in **sentence-case/downstyle**: i.e., the *only* words that should be capitalized are
    
        - The first word in the header
        - Any proper nouns 

- All lists, as well as any sets of list elements with the same indentation, should be preceded and followed by a newline. 
    
    - Examples:

        ```markdown
        Some preceding content, separated from the list by the newline that precedes it...

        - Level 1 bullet
        - Level 1 bullet
        - Level 1 bullet
            
            - Level 2 bullet
            - Level 2 bullet

        -  Level 1 bullet

            1. Level 2 numbered element
            2. Level 2 numbered element

                - Level 3 bullet

        - Level 1 bullet
        - Level 1 bullet

        Content following the list, separated from the list by the newline that follows it...
        ```

        ```markdown
        Some preceding content, separated from the list by the newline that precedes it...

        - Level 1 bullet
        - Level 1 bullet

            - Level 2 bullet, preceded by newline
            - Level 2 bullet

                - Level 3 bullet
            
            - Level 2 bullet
                
                1. Level 3 numbered list element; our rules apply to bulleted lists, numbered lists, any kind of list!
                2. Level 3 numbered list element
                - Level 3 bullet
            
            - Level 2 bullet
            - Level 2 bullet
            1. Level 2 numbered list element (interspersed bullets and numbered elements are rare but possible at any indentation level! Just use your common sense, follow the rules and you'll be fine!)

                - Level 3 bullet

        Content following the list, separated from the list by the newline that follows it...
        ``` 
