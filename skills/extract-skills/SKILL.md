---
name: extract-skills
description: Analyze a project's skills, identify ones that can be generalized, abstract them, and add them to this repo.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: [path to project]
tags: [meta, skill-development]
version: 1.0.0
---

# Extract Skills

Given a path to a project, scan its skills, identify which ones are generic enough to be reusable, abstract away project-specific details, and add the generalized versions to this skill repo.

## Usage

`/extract-skills /path/to/project`

## Process

### Step 1 — Scan the project for skills

Look for skill files in:
- `<path>/.claude/skills/*/SKILL.md`
- `<path>/skills/*/SKILL.md`

Read every skill file found. Build an inventory:
- Skill name
- Description
- Full content
- Tags (if present)
- Dependencies (if present)

### Step 2 — Classify each skill

For each skill, determine:

| Category | Criteria | Action |
|----------|----------|--------|
| **Generic** | No project-specific data, paths, schemas, or domain terms. Works in any project as-is. | Extract directly |
| **Abstractable** | Contains useful patterns wrapped in project-specific details. The core process is reusable. | Abstract and extract |
| **Project-specific** | Deeply tied to project data, APIs, schemas, or domain. Not useful elsewhere. | Skip |

Present the classification to the user:

```
## Skill Classification for <project>

### Generic (extract as-is)
- skill-a: <reason>

### Abstractable (needs generalization)
- skill-b: <what's project-specific, what's the generic core>

### Project-specific (skip)
- skill-c: <reason>
```

Wait for user confirmation before proceeding. The user may reclassify skills or skip some.

### Step 3 — Check for overlap with existing skills

For each skill to be extracted, check if this repo already has a skill that covers the same purpose:
- Read `skills/*/SKILL.md` in this repo
- Compare by name, description, and functionality

If overlap exists, report it:
> "Skill `<name>` overlaps with existing `<existing>`. Merge, replace, or skip?"

### Step 4 — Abstract project-specific skills

For skills classified as "Abstractable":

1. **Identify project-specific elements**: paths, file names, schemas, domain terms, tool names, API endpoints
2. **Replace with generic equivalents**:
   - Specific paths → generic descriptions ("your project's data directory")
   - Domain terms → general terms ("data source" instead of "UCDP conflict dataset")
   - Project schemas → generic patterns ("your YAML config" instead of "countries.yaml")
   - Project-specific tools → tool categories ("your build tool" instead of "webpack")
3. **Preserve the core process**: The step-by-step workflow, decision logic, and quality checks should remain intact
4. **Keep what's universally useful**: Error handling, edge cases, best practices

### Step 5 — Prepare skill files

For each skill being added:

1. Create the SKILL.md with proper frontmatter:
   ```yaml
   ---
   name: <name>
   description: <generalized description>
   allowed-tools: <tools>
   argument-hint: <args>
   tags: <tags>
   version: 1.0.0
   ---
   ```
2. Ensure no project-specific references remain in the body
3. Add a note at the bottom: `Generalized from: <project-name>`

### Step 6 — Add to this repo

For each skill:

1. Create `skills/<name>/SKILL.md`
2. Add to appropriate group in `groups.json` (or create a new group if needed)
3. Run `./skill.sh build-manifest`
4. Run `./skill.sh validate`

### Step 7 — Report

```
## Extraction Report

Source: <project path>
Skills scanned: N
Extracted: N (M generic, K abstracted)
Skipped: N (project-specific)

### Added
- <skill-name>: <description> (group: <group>)
- ...

### Skipped
- <skill-name>: <reason>

### Overlaps resolved
- <skill-name>: merged with existing <existing-skill>
```

Commit the new skills.

## Guidelines

- **When in doubt, skip** — it's better to miss a skill than to add one that's too project-specific to be useful
- **Preserve quality** — the abstracted skill should be as clear and complete as the original. Don't strip out useful detail just because it was written for a specific project
- **One skill, one purpose** — if a project skill does two things, consider splitting into two generic skills
- **Check the meta-skills** — if the project has skills about creating/managing skills (like we already have), compare carefully before adding duplicates
