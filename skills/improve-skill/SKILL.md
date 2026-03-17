---
name: improve-skill
description: Review and improve an existing skill file — analyze clarity, completeness, and accuracy, then apply fixes.
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint: [skill name to improve]
tags: [meta, skill-development]
version: 1.0.0
---

# Improve Skill

Review an existing skill, analyze it against quality criteria, and produce an improved version.

## Usage

`/improve-skill <skill-name>`

Examples:
- `/improve-skill changelog`
- `/improve-skill review`

## Process

### Step 1 — Locate and read the skill

Find the skill file:
- `skills/<name>/SKILL.md` (in a skill repo)
- `.claude/skills/<name>/SKILL.md` (in a project)

Read the file in full.

### Step 2 — Analyze the skill

Review against these criteria:

1. **Clarity**: Are instructions unambiguous? Could any step be misinterpreted?
2. **Completeness**: Are there obvious missing cases or scenarios?
3. **Accuracy**: Is any information outdated (URLs, tool names, methodology)?
4. **Redundancy**: Are any sections repeated or contradictory?
5. **Composability**: Does the skill properly reference other skills it depends on?
6. **Format**: Is the YAML frontmatter complete? Are code blocks formatted correctly?
7. **Examples**: Are examples realistic, correct, and sufficient?
8. **Edge cases**: Does the skill handle error conditions and unusual inputs?

### Step 3 — Propose changes

Present a tracked changes summary:

```
## Proposed Changes to <name>

### Issues found:
- Step 3 is ambiguous — could be interpreted two ways → Rewriting for clarity
- Missing: no guidance for empty input → Adding edge case section
- Redundant: Steps 4 and 6 describe the same validation → Merging

### Preserved:
- Core workflow (Steps 1-3) is clear and complete
- Examples are accurate
```

### Step 4 — Apply improvements

Write the improved file. Report what changed:
```
Updated skills/<name>/SKILL.md:
- Clarified Step 3 instructions
- Added edge case handling for empty input
- Merged redundant validation steps
```

## What NOT to Do

- Do not add complexity for its own sake — simpler is better
- Do not change the core purpose of a skill
- Do not invent problems that don't exist
- Do not rewrite a skill that is already clear and complete
