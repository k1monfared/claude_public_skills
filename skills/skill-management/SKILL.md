---
name: skill-management
description: Full skill system health analysis — orchestrates audit, pattern extraction, and learnings synthesis into a unified report with prioritised actions.
allowed-tools: Read, Write, Glob, Grep
argument-hint: [optional: --act to auto-improve top 3 skills]
tags: [meta, quality, orchestration]
version: 1.0.0
---

# Skill Management

The top-level orchestrator for skill system improvement. Runs a full analysis — structural quality, cross-skill patterns, and learning synthesis — and produces a prioritised action plan.

## Usage

```
/skill-management          # produce health report only
/skill-management --act    # report + auto-improve top 3 skills
```

## Process

### Step 1 — Run structural audit

Invoke the `skill-audit` skill (no argument — full audit).

Collect:
- Per-skill scores and missing sections
- Broken cross-references

### Step 2 — Extract cross-skill patterns

Invoke `cross-skill-patterns`.

Collect:
- Ranked patterns (high/medium/low impact)
- Knowledge asymmetries and transferable insights
- Redundancy candidates
- Vocabulary inconsistencies

### Step 3 — Synthesize learnings

Invoke `synthesize-learnings`.

Collect:
- Cross-cutting themes from documented learnings
- Hypotheses for undocumented skills
- Positive patterns to preserve

### Step 4 — Build the unified priority list

Combine findings into a single ranked list.

**Scoring:**
| Signal | Points |
|--------|--------|
| Structural audit score < 50% | +3 |
| Identified in a high-impact cross-skill pattern | +3 |
| Identified in a high-impact cross-cutting theme | +3 |
| Has documented learnings waiting to be applied | +2 |
| Referenced by many other skills (hub skill) | +1 |

Sort by total score descending.

### Step 5 — Produce the Health Report

```
## Skill System Health Report — <date>

### Overall Health
Skills analysed: N
Average structural score: X% (target: >=80%)
Skills below 50%: N
High-impact patterns found: N

### Priority Improvement Queue
| Rank | Skill | Score | Primary reasons |
|------|-------|-------|-----------------|
| 1 | ... | 9 | structural 40%, pattern match |
| 2 | ... | 7 | vocabulary inconsistency |

### Cross-Skill Insights (Top 3)
1. <Theme/Pattern>
   Affects: N skills
   Action: <specific change>

### What's Working Well (preserve)
- <skill>: <positive pattern>

### Recommended Actions
1. Run /improve-skill <skill> (highest impact)
2. Propagate <pattern> to: <skills>
3. ...
```

### Step 6 — Act (if --act flag)

If `--act` was passed, automatically run `/improve-skill` on the top 3 ranked skills. Report each as it completes.

## Self-Application

This skill is subject to its own analysis. When it identifies issues with skill-audit, cross-skill-patterns, synthesize-learnings, or itself, use `/improve-skill` to fix them.

## When to Run

- After creating several new skills
- After many sessions using skills
- When workflows feel inconsistent
- Periodically (every few months of active use)
