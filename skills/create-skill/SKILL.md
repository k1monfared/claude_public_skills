---
name: create-skill
description: Draft a new skill from a task description, following best practices for skill structure and composability.
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint: [description of what the skill should do]
tags: [meta, skill-development]
version: 1.0.0
---

# Create Skill

Draft a new skill file from a natural language description of the task it should perform.

## Usage

`/create-skill "<description of what this skill should do>"`

Examples:
- `/create-skill "lint YAML files and report errors"`
- `/create-skill "generate API documentation from code comments"`
- `/create-skill "run database migrations safely"`

## Process

### Step 1 — Understand the task

From the description, identify:
1. **Inputs**: What arguments or data does this skill take?
2. **Outputs**: What does it produce (file, report, terminal output)?
3. **Steps**: What is the high-level process?
4. **Tools needed**: Which Claude Code tools does it use?

If the description is ambiguous, ask one clarifying question before proceeding.

### Step 2 — Check for overlap

Scan existing skills:
- `skills/*/SKILL.md` (if in a skill repo)
- `.claude/skills/*/SKILL.md` (if in a project)

If an existing skill already covers this task (even partially), report:
> "The skill `<name>` already covers <overlap>. Consider using `/improve-skill <name>` to extend it instead."

Only proceed if the task is genuinely new.

### Step 3 — Choose a name

- Use lowercase, hyphenated names
- Verb-noun or descriptive noun pattern
- Examples: `lint-yaml`, `generate-docs`, `run-migrations`

### Step 4 — Draft the SKILL.md

Follow this structure:

```yaml
---
name: <name>
description: <one-line description>
allowed-tools: <tools this skill needs>
argument-hint: [expected arguments]
tags: [relevant, tags]
version: 0.1.0
---
```

Body should include:
1. **Title** — `# <Name>`
2. **Usage** — how to invoke with examples
3. **Process** — step-by-step instructions (minimum 3 steps)
4. **At least one worked example** — showing input → output
5. **Edge cases** — what to do when things go wrong
6. **References** — other skills this composes or depends on

### Step 5 — Check composability

- Does this skill build on existing skills? Reference them explicitly.
- Could existing skills benefit from knowing about this one? Note which ones.

### Step 6 — Write the file

Write the skill file to disk. If in a skill repo with `skill.sh`, run `./skill.sh build-manifest` afterward.

Report the file path created and a brief summary.

## What Makes a Good Skill

- Clear, specific scope — does one thing well
- Has at least one worked example
- Explains edge cases and what to do when things go wrong
- References existing skills rather than duplicating them
- Uses `$ARGUMENTS` for parameterization where appropriate
- Keeps instructions unambiguous — no room for misinterpretation
