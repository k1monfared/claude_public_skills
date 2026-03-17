---
name: cross-skill-patterns
description: Read all skills and extract cross-cutting patterns, knowledge asymmetries, redundancy, and transferable insights.
allowed-tools: Read, Glob, Grep
tags: [meta, quality]
version: 1.0.0
---

# Cross-Skill Pattern Extraction

Read all skill files holistically to find patterns that span multiple skills — knowledge that should be shared but isn't, repeated content that could be extracted, and structural patterns that work well in some skills but are absent where they'd help.

## Usage

```
/cross-skill-patterns
```

No arguments. Always analyses all skills.

## Process

### Step 1 — Read all skills

Read every `SKILL.md` file in the skills directory. Build a mental model of the full skill corpus before identifying patterns.

### Step 2 — Apply analysis lenses

#### Lens A: Repeated Warnings / Common Pitfalls

Look for warnings or cautionary notes that appear in multiple skills. If the same warning appears in 2+ skills, it's a cross-cutting pitfall that may be under-documented elsewhere.

```
Pattern: <name>
Appears in: skill-a, skill-b
Missing from: skill-c, skill-d
Recommendation: <action>
```

#### Lens B: Knowledge Asymmetries

Skill A knows something that Skill B needs but doesn't have. Look for guidance in one skill that would benefit a related skill.

```
Asymmetry: <description>
Transfer: <what to move where>
```

#### Lens C: Extractable Shared Content

If 3+ skills contain similar blocks (boilerplate, format templates, common patterns), that content is a candidate for extraction into a shared skill or reference.

```
Redundancy: <description>
Action: <extract to shared location>
```

#### Lens D: Structural Patterns That Work

Identify sections, formats, or structural choices that make some skills clearer than others, and which skills would benefit from adopting them.

```
Good pattern: <description> in <skill>
Missing from: <skills that would benefit>
Recommendation: <action>
```

#### Lens E: Vocabulary Inconsistencies

Look for the same concept described differently across skills — different names, conflicting guidance, or inconsistent terminology.

```
Inconsistency: <description>
Recommendation: <standardize on X>
```

### Step 3 — Rank patterns by impact

- **High**: affects 5+ skills OR blocks a workflow OR creates incorrect output
- **Medium**: affects 2-4 skills OR creates confusion
- **Low**: affects 1 skill OR cosmetic

### Step 4 — Produce the report

```
## Cross-Skill Pattern Report — <date>

### High-Impact Patterns
1. <pattern>
   Affects: <skills>
   Type: <asymmetry|redundancy|pitfall|structural|vocabulary>
   Recommendation: <action>

### Medium-Impact Patterns
...

### Transferable Knowledge Summary
Top pieces of knowledge that should be propagated:
1. ...

### Skills That Could Be Simplified
- <skill>: <what could be referenced instead of repeated>
```
