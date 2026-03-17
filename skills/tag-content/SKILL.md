---
name: tag-content
description: Auto-tag content files (blog posts, docs, notes) by reading their content, consulting existing tags, and updating frontmatter.
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint: [path to file, or blank for all untagged]
tags: [content, blog, organization]
version: 1.0.0
---

# Tag Content

Automatically assign tags to content files (blog posts, documentation, notes) based on their content and an existing tag vocabulary.

## Usage

```
/tag-content                          # tag all untagged content files
/tag-content path/to/post.md          # tag a specific file
/tag-content --all                    # re-tag ALL files (overwrite existing)
```

## Process

### Step 1 — Gather context

Understand the current tag ecosystem:
1. Look for a tag hierarchy file (e.g., `tags.yml`, `tags.json`, or similar) in the content directory
2. Scan all content files for existing `tags:` frontmatter to build a frequency map of current tags

If no tag vocabulary exists yet, you'll build one from scratch in Step 3.

### Step 2 — Read the target file(s)

If an argument was provided, read that specific file. Otherwise, find all content files (`.md`, `.mdx`, etc.) that either:
- Have no `tags:` line in their frontmatter
- Have no frontmatter at all
- (with `--all` flag) All files regardless of existing tags

Read the FULL content of each file, not just frontmatter.

### Step 3 — Assign tags

For each file, determine appropriate tags by analyzing:
- **Topic**: What is the content about?
- **Subtopic**: More specific categories
- **Format**: Tutorial, review, reference, opinion, announcement, etc.
- **Tone**: Technical, personal, creative, etc.

**Rules:**
- Prefer EXISTING tags over creating new ones (check the frequency map)
- Each file should have 2-6 tags (not too few, not too many)
- Tags should be lowercase
- A tag should be reusable across multiple files — don't create one-off tags
- Remove noise tags that aren't descriptive

### Step 4 — Update frontmatter

For each file:
- If it has frontmatter (`---` delimiters), add or update the `tags:` line
- If it has no frontmatter, add frontmatter with tags at the top
- Match the existing tag format in the project (comma-separated, YAML list, etc.)

### Step 5 — Update tag hierarchy (if applicable)

If the project has a tag hierarchy file, invoke the `update-tag-hierarchy` skill to incorporate any new tags:
```
/update-tag-hierarchy
```

### Step 6 — Report

Summarize:
- How many files were tagged
- Any new tags created
- Tag distribution (most/least used)

## Edge Cases

- **Files with no clear topic**: Assign broad category tags rather than leaving untagged
- **Very short files**: Use title and any available metadata to infer tags
- **Existing tags that are wrong**: When using `--all`, replace bad tags but preserve correct ones where possible
- **Non-markdown files**: Skip unless explicitly included

---

*Generalized from: notes/blog*
