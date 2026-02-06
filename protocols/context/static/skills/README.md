# Static skill templates

## Important note: *avoid* adding `name` fields to `SKILL.md` files' YML frontmatter 

Most coding agents require the `name` field in a given `SKILL.md` to match the name of the folder they're installed to. Now, when installing skills to each supported coding agent's configs, Bureau adds a prefix to the dirnames in which skills are installed; this is to **avoid any potential naming conflicts with other skills already in the **

> [!NOTE]
> The prefix added to skills' install directories is set using `BUREAU_SKILLS_PREFIX` in the [YML configs](../../../../docs/CONFIGURATION.md); by default, `bureau-` is used.

> For example, in each coding agent's config's `skills/` directory, the [*micro mode* skill](micro-mode/SKILL.md) gets installed in a subdirectory called `<BUREAU_SKILLS_PREFIX>-micro-mode` (`bureau-micro-mode` by default). 

> [!IMPORTANT]
> 
> Note this also has the effect of **changing each skill's name, as shown in each coding agent's interface, to be displayed as `<BUREAU_SKILLS_PREFIX>-<skill-name>`**

Hence, if a `name` property is included in a `SKILL.md`'s YAML frontmatter, its value must contain the `bureau-` prefix to match the name of the parent directory (one per enabled coding agent) it will be installed to. However, the parent dirs of the internal Bureau directories where the source/canonical `SKILL.md` files are stored do *not* contain this prefix in their names. Consequently, in VSCode, the line containing the `name` property gets flagged with warnings due to the `bureau-` prefix not matching the parent dir's name. 

This risks creating confusion for Bureau users who:
- add their own custom skills, and/or
- read the included `SKILL.md` files
and see the aforementioned warning, since they will likely not be aware of the explanation above.

The solution is to simply **avoid using the `name` property in all `SKILL.md` files** since it's entirely optional: the actual source of truth for a skill's name (as shown in coding agents' CLIs) is the **name of the install directory (i.e., within a coding agent's config's `skills/` directory) containing the `SKILL.md` file.**
