---
name: skill-audit
description: Structural analysis of skill files — scores completeness, flags broken references, identifies missing sections.
allowed-tools: Read, Glob, Grep
argument-hint: [optional: skill name to audit, or blank for all]
tags: [meta, quality]
version: 1.0.0
---

# Skill Audit

Read skill files and score each one against a structural completeness rubric. This is a *structural* audit — it evaluates the quality of the skill documentation, not whether the underlying process is correct.

## Usage

```
/skill-audit           # audit all skills
/skill-audit changelog # audit a single skill
```

## Process

### Step 1 — Build the file inventory

Find all skill files:
- `skills/*/SKILL.md` (in a skill repo)
- `.claude/skills/*/SKILL.md` (in a project)

### Step 2 — Score each skill

Apply this rubric. Score each criterion 0 (absent) or 1 (present):

| Criterion | Weight |
|-----------|--------|
| Has valid YAML frontmatter (name, description, version) | 1 |
| Has a clear one-sentence purpose statement | 1 |
| Has explicit input/argument documentation | 1 |
| Has step-by-step process (at least 3 steps) | 1 |
| Has at least one worked example or sample output | 2 |
| References other skills it depends on (or states "none") | 1 |
| Has edge case / error handling guidance | 2 |
| Has tags in frontmatter | 1 |
| Has allowed-tools in frontmatter | 1 |

**Maximum score: 11**

### Step 3 — Check cross-references

For every skill referenced inside a file, verify the referenced skill actually exists. Flag broken references.

### Step 4 — Produce the audit report

```
## Skill Audit Report — <date>

### Summary
Total skills: N
Average score: X/11 (Z%)
Skills below 50%: N
Broken references: N

### Per-Skill Scores (sorted ascending — lowest first)
| Skill | Score | Missing |
|-------|-------|---------|
| example-skill | 6/11 | examples, edge cases |
| ...           |      |         |

### Broken References
- <skill> references `<other>` — file does not exist

### Top Priorities
1. <skill> — missing: <list> (score: X/11)
2. ...
```

## What This Is Not

- Does not evaluate whether skill *content* is correct
- Does not run skills to test them
- Purely static document analysis
