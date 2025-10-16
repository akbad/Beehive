# Documentation Style Guide for AI Agents

This guide defines the technical writing and formatting standards for writing documentation for this repo. AI agents should follow these patterns *exactly* when creating or modifying documentation files.


## Fundamental Writing Principles

### Voice and Tone

**Direct and Imperative**
Write instructions using imperative mood with clear, actionable verbs.

**Correct:**
```markdown
- Go to the protobuf release page.
- Download and install the file.
```

**Incorrect:**
```markdown
- You should go to the protobuf release page.
- It would be good if you downloaded and installed the file.
```

**Factual and Precise**
Avoid marketing language, superlatives, and unnecessary embellishment.

**Correct:**
```markdown
A headless Spotify client, allowing you to authenticate and retrieve a decrypted audio stream for any track.
```

**Incorrect:**
```markdown
An amazing, powerful headless Spotify client that easily allows you to authenticate and effortlessly retrieve decrypted audio streams!
```

**Second Person for Instructions**
Use "you" when addressing the reader directly in procedural content.

**Correct:**
```markdown
After modifying the `.proto` files you need to, make sure to follow these steps.
```

**Incorrect:**
```markdown
After modifying the `.proto` files one needs to, make sure to follow these steps.
After modifying the `.proto` files, make sure to follow these steps. [passive, unclear actor]
```

### Sentence Structure

**Short and Declarative**
Keep sentences concise and action-oriented.

**Correct:**
```markdown
The Session object can provide OAuth tokens via `session.tokens().get(...)`.
```

**Incorrect:**
```markdown
It should be noted that the Session object, which is the primary entry point for the library, has the capability of providing OAuth tokens through the use of the `session.tokens().get(...)` method.
```

**Minimal Passive Voice**
Use active voice wherever possible.

**Correct:**
```markdown
The `Session.Builder` is used to configure and create a session.
```

**Acceptable (when agent is obvious):**
```markdown
An active session is required for all other operations.
```

**Incorrect:**
```markdown
Sessions are created by using the builder pattern.
```

## Markdown Formatting Standards

### Headers

Use ATX-style headers (`#`) with proper hierarchy:

```markdown
# Top-level document title (use only once)

## Major sections

### Subsections

#### Rarely needed, but acceptable for deep nesting
```

**Rules:**
- Use sentence case (capitalize first word and proper nouns only)
- No trailing punctuation
- Single blank line before and after headers
- No emojis or decorative elements

**Correct:**
```markdown
## Environment setup

### Install protoc
```

**Incorrect:**
```markdown
## Environment Setup!

### Install Protoc 🔧
```

### Emphasis and Highlighting

**Bold (`**text**`)**

Use for:
- Critical concepts requiring immediate attention
- Key phrases that define scope or behavior
- Important actions in lists
- Negations or critical distinctions

**Correct:**
```markdown
- **Not** a standalone audio player: the **provided stream must be piped to another application**.
- This step is **only needed if you're changing any `.proto` serialization schema files**.
```

**Italic (`*text*`)**

Use sparingly for:
- Negations that contrast with common assumptions
- Subtle emphasis within sentences

**Correct:**
```markdown
*Not* a standalone audio player
```

**Avoid:**
- Mixing bold and italic on the same text
- Using emphasis for decoration
- Overusing emphasis (if everything is emphasized, nothing is)

### Code Formatting

**Inline Code (backticks: `` `code` ``)**

Use for:
- File names: `` `requirements.txt` ``, `` `.proto` ``
- File patterns: `` `*_pb2.py` ``, `` `protoc-*.zip` ``
- Directory paths: `` `~/Documents` ``
- Class names: `` `Session` ``, `` `AudioQuality` ``
- Method names: `` `load()` ``, `` `get()` ``
- Method calls with object: `` `session.content_feeder()` ``, `` `session.tokens().get(...)` ``
- Variable names: `` `TrackId` ``, `` `AudioQuality` ``
- Commands: `` `pip` ``, `` `protoc` ``
- Applications: `` `ffplay` ``
- URLs when used as technical references
- Configuration values
- Module names: `` `audio` ``

**Correct:**
```markdown
- The `Session.Builder` is used to configure and create a session.
- Install the `protoc-*.zip` file meant for your platform.
- Accessed via `session.content_feeder()`, this component's `load()` method retrieves the audio stream.
```

**Code Blocks**

Always specify language for syntax highlighting:

````markdown
```sh
pip install -r requirements.txt
```

```bash
protoc -I=proto --python_out=librespot/proto proto/metadata.proto
```

```python
session = Session.Builder().user_pass("username", "password").create()
```
````

**Language Codes:**
- `sh` for generic shell commands (pip, simple one-liners)
- `bash` for bash-specific syntax
- `python` for Python code
- `json` for JSON data
- `yaml` for YAML configuration

**Indentation in Code Blocks:**
Use 4 spaces for indentation when showing code blocks within list items:

````markdown
- From the repository root, compile each `.proto` file:

    ```bash
    protoc -I=proto --python_out=librespot/proto proto/metadata.proto
    ```
````

### Lists

**Bulleted Lists**

Use bulleted lists (hyphens: `-`) for:
- Related items or options
- Sequential steps (this project does NOT use numbered lists for procedures)
- Component descriptions
- Feature lists

**Correct:**
```markdown
- Go to the protobuf release page.
- Download and install the file.
- Follow the regeneration steps.
```

**NOT:**
```markdown
1. Go to the protobuf release page.
2. Download and install the file.
3. Follow the regeneration steps.
```

**List Punctuation Rules:**

Complete sentences (with subject and predicate) → period at end:
```markdown
- The `Session.Builder` is used to configure and create a session.
- An active session is required for all other operations.
```

Sentence fragments (no subject or incomplete predicate) → no period:
```markdown
- Python 3.10+
- A headless Spotify client
```

Commands or technical items → no period:
```markdown
- `pip install -r requirements.txt`
- `session.content_feeder()`
```

**List Consistency:**
- Start all items at same grammatical level
- Use parallel structure
- Maintain consistent punctuation within a single list

**Correct (all fragments):**
```markdown
The main components are:

- **`Session`**: The primary entry point
- **`ContentFeeder`**: Accessed via `session.content_feeder()`
- **`audio` module**: This package contains tools for audio handling
```

**Incorrect (mixed structure):**
```markdown
The main components are:

- **`Session`** - primary entry point
- **`ContentFeeder`**: This is accessed via `session.content_feeder()`.
- **Audio module** for audio handling
```

### Blockquotes

Use blockquotes (`>`) for:
- Contextual notes before instructions
- Prerequisites or conditions
- Important warnings or clarifications

**Correct:**
```markdown
> This step is **only needed if you're changing any `.proto` serialization schema files**,
> which will subsequently require using the protoc compiler to generate updated versions of
> the `*_pb2.py` Python stubs that implement serialization/deserialization for those schemas.
```

**Structure:**
- Each line of multi-line blockquote starts with `>`
- Blockquotes can contain inline formatting (bold, code, etc.)
- Blank line before and after blockquote

### Links

**Inline Links**

Use descriptive link text, not "click here" or bare URLs:

**Correct:**
```markdown
Go to the [protobuf release matching the version pinned in `requirements.txt`](https://github.com/protocolbuffers/protobuf/releases/tag/v3.20.1).
```

**Incorrect:**
```markdown
Click [here](https://github.com/protocolbuffers/protobuf/releases/tag/v3.20.1).
Go to https://github.com/protocolbuffers/protobuf/releases/tag/v3.20.1.
```

**Anchor Links**

Use for internal document navigation:

```markdown
**make sure to follow [these steps](#protocol-buffer-generation) to regenerate the Python stubs**.
```

**Rules:**
- Lowercase, hyphen-separated
- Match header text exactly (converted to lowercase with spaces → hyphens)

## Documentation Patterns

### Establishing Scope

Start documentation with clear scope definition using "What X is" pattern:

```markdown
## What this library is

- A headless Spotify client, allowing you to **authenticate and retrieve a decrypted audio stream for any track**.
- *Not* a standalone audio player: the **provided stream must be piped to another application** (like `ffplay`) or handled by a server to be played.
```

**Pattern:**
- Positive statement of what it IS (with key capabilities in bold)
- Negative statement of what it IS NOT (with italic emphasis on negation and bold on critical distinction)
- Use fragments, not complete sentences, in this pattern

### Component Documentation

Use consistent pattern for architectural components:

```markdown
## Architecture

The main components are:

- **`ComponentName`**: Brief description of purpose. Additional context about usage via `code.example()`. Key behavioral note.

- **`AnotherComponent`**: Description with method signature like `object.method()` shown inline.
```

**Pattern:**
- Component name in bold backticks
- Colon separator
- Description starting with purpose
- Method access patterns shown inline with backticks
- Complete sentences with periods

### Instructional Sections

**Prerequisites First:**

```markdown
### Install protoc

> This step is **only needed if you're changing any `.proto` serialization schema files**.
```

**Then Instructions:**

```markdown
- Go to the release page.
- Download and install the file.
```

**Then Follow-up Actions:**

```markdown
After modifying the files, **make sure to follow [these steps](#reference)**.
```

**Pattern:**
1. Section header
2. Blockquote with context/prerequisites (if applicable)
3. Bulleted action items
4. Post-instruction notes (if applicable)

### Examples and Clarifications

Use parenthetical additions for:
- Concrete examples: `(using `proto/metadata.proto` as an example)`
- Alternative options: `(like `ffplay`)`
- Technical clarifications: `(Vorbis, FLAC)`

**Placement:**
- After the general statement
- Inside the same sentence
- In parentheses

**Correct:**
```markdown
- Compile each `.proto` file you've modified with this command (using `proto/metadata.proto` as an example):
```

## Content Organization

### Section Ordering

Follow this hierarchy for contribution/setup guides:

1. Scope definition (What X is)
2. Prerequisites/Environment setup
3. Installation instructions
4. Configuration/Setup procedures
5. Architecture overview (if applicable)
6. Advanced topics
7. Troubleshooting (if applicable)

### Subsection Structure

```markdown
## Major Topic

### Specific Subtopic

Content introducing the subtopic.

- Action items or details
- More specifics
```

**Rules:**
- No more than 3 levels of headers in most documents (h1, h2, h3)
- Each section should have a clear purpose
- Related content grouped together

## Language and Style

### Technical Precision

**Be Specific:**

**Correct:**
```markdown
The `Session.Builder` is used to configure and create a session, typically via username/password or stored credentials.
```

**Incorrect:**
```markdown
The builder helps you make a session using various methods.
```

**Define Terminology:**

When introducing technical terms, provide immediate context:

```markdown
- **`ContentFeeder`**: Accessed via `session.content_feeder()`, this component's `load()` method retrieves the audio stream for a given `TrackId` and `AudioQuality`.
```

### Consistency

**Terminology:**
- Use consistent names for components: `Session`, not "session object" or "Session class"
- Use consistent method notation: `method()` with parentheses
- Use consistent file extensions: `.proto`, not "proto files"

**Formatting:**
- If you format a filename with backticks once, always format it with backticks
- If you bold a phrase pattern, use bold consistently for similar patterns

**Capitalization:**
- Headers: Sentence case
- Code elements: Match actual casing in code (`Session`, not `session` unless referring to instance)
- File extensions: Lowercase (`.py`, `.proto`)

### Avoiding Common Pitfalls

**Don't:**
- Use emojis or decorative elements
- Use excessive punctuation (!!!, ???, etc.)
- Use "simply", "just", "easily" (implies judgment of difficulty)
- Use "very", "extremely", "incredibly" (adds no technical value)
- Use marketing language ("powerful", "amazing", "best")
- Mix different code formatting for same elements
- Start every bullet point the same way (vary sentence structure)
- Over-explain obvious steps to experienced developers

**Do:**
- State facts clearly
- Provide context where needed
- Use precise technical terminology
- Show, don't tell (use code examples)
- Respect the reader's intelligence

## Complete Example

Here's a complete section following all style guidelines:

```markdown
## Protocol buffer generation

> These instructions are only necessary after changing `.proto` files.

- From the repository root, compile each `.proto` file you've modified with this command (using `proto/metadata.proto` as an example):

    ```bash
    protoc -I=proto --python_out=librespot/proto proto/metadata.proto
    ```

- Commit both the source `.proto` and the regenerated Python output together so they can be compared easily.
```

**Analysis:**
- ✓ Section header in sentence case
- ✓ Blockquote for contextual prerequisite
- ✓ Bold for critical condition ("only necessary after")
- ✓ Inline code for file extensions
- ✓ Bulleted list (not numbered)
- ✓ Imperative voice ("compile", "commit")
- ✓ Parenthetical example
- ✓ Indented code block with language hint
- ✓ Precise technical language
- ✓ Complete sentences end with periods
- ✓ Consistent inline code formatting

## Checklist for AI Agents

Before submitting documentation, verify:

**Structure:**
- [ ] Clear section hierarchy with appropriate header levels
- [ ] Logical flow from general to specific
- [ ] Consistent spacing (blank lines between sections)

**Formatting:**
- [ ] All code elements (files, classes, methods) in backticks
- [ ] Code blocks have language hints
- [ ] Emphasis (bold/italic) used purposefully, not decoratively
- [ ] Lists use consistent punctuation rules
- [ ] No emojis or decorative elements

**Content:**
- [ ] Imperative mood for instructions
- [ ] Active voice where possible
- [ ] Technical precision without marketing language
- [ ] Concrete examples where helpful
- [ ] Prerequisites clearly stated

**Consistency:**
- [ ] Terminology matches existing docs
- [ ] Formatting patterns match CONTRIBUTING.md
- [ ] Code notation consistent throughout
- [ ] Capitalization follows established patterns

**Clarity:**
- [ ] Purpose of each section is clear
- [ ] Steps are actionable
- [ ] Context provided where needed
- [ ] Examples illustrate concepts effectively
