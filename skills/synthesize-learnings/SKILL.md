---
name: synthesize-learnings
description: Meta-analyse usage patterns and session history to extract cross-cutting themes and improvement hypotheses for skills.
allowed-tools: Read, Glob, Grep
tags: [meta, quality]
version: 1.0.0
---

# Synthesize Learnings

Analyse documented learnings, usage history, and session notes to find patterns that cut across skills — themes that individual skill improvements would miss, and hypotheses for skills that lack documented feedback.

## Usage

```
/synthesize-learnings
```

No arguments. Analyses all available learnings.

## Process

### Step 1 — Gather learning sources

Look for learning/feedback data in these locations:
- `learnings/*.md` or `meta/learnings/*.md` (if the project tracks learnings)
- Git commit messages mentioning skill names
- Any `CHANGELOG.md` entries related to skills
- Session notes or retrospectives if available

For each entry found, tag it:
- **Skill name**: which skill it relates to
- **Type**: `gap` (missing content), `confusion` (ambiguous instruction), `edge_case` (unhandled scenario), `outdated` (stale info), `friction` (unnecessary complexity), `worked_well` (preserve this)
- **Scope**: `local` (specific to one skill) or `generalizable` (applies to others)

### Step 2 — Find cross-cutting themes

Group generalizable learnings by theme. Common theme types:
- **Repeated confusion**: Multiple skills have the same ambiguity
- **Missing edge cases**: Similar error conditions unhandled across skills
- **Structural gaps**: A useful section in one skill that others lack
- **Positive patterns**: Things that work well and should be preserved everywhere

### Step 3 — Hypothesize for skills without learnings

For skills with no documented learnings, apply inference:
1. **Analogy**: Does this skill resemble one that has learnings? Similar issues likely apply.
2. **Structural**: Does this skill have patterns (complex multi-step, external dependencies) known to generate confusion?
3. **Usage frequency**: Frequently-used skills likely have undocumented friction.

### Step 4 — Produce the synthesis report

```
## Learnings Synthesis — <date>

### Sources Analyzed
Files read: N
Total entries: N
Generalizable: N (X%)

### Cross-Cutting Themes

#### Theme 1: <name> (High/Medium/Low impact)
Skills with evidence: <list>
Skills likely affected: <list>
Insight: <what this means>
Action: <recommended fix>

### Hypotheses for Undocumented Skills
| Skill | Basis | Hypotheses | Priority |
|-------|-------|-----------|---------|
| ... | analogy | ... | medium |

### Positive Patterns to Preserve
- <skill>: <what works well>

### Recommended Actions
1. Propagate Theme 1 fix to: <skills>
2. Start logging learnings for: <high-use skills>
3. Run /improve-skill on: <skills with most issues>
```

## When to Run

- After several sessions using skills (enough friction to surface patterns)
- When workflows feel inconsistent
- Periodically to catch drift
