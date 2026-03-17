---
name: update-tag-hierarchy
description: Update a tag hierarchy file based on current tags across all content files. Ensures new tags are categorized and groups are well-organized.
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint: (no arguments)
tags: [content, blog, organization]
version: 1.0.0
---

# Update Tag Hierarchy

Reorganize a tag hierarchy file to reflect the current set of tags across all content files.

## Usage

```
/update-tag-hierarchy
```

No arguments. Scans all content files and updates the hierarchy.

## Process

### Step 1 — Collect current tags

Scan all content files (`.md`, `.mdx`, etc.) and extract every unique tag from frontmatter. Build a frequency map: `{tag: count}`.

### Step 2 — Read current hierarchy

Find and read the tag hierarchy file. Common locations:
- `tags.yml` / `tags.yaml`
- `tags.json`
- `_data/tags.yml` (Jekyll)
- `content/tags.yml`

If no hierarchy file exists, create one.

### Step 3 — Identify gaps

Compare tags found in content vs tags in the hierarchy:
- **New tags** not in any group — need to be placed
- **Dead tags** in hierarchy but not used by any content — remove
- **Groups with too many or too few items** — consider splitting or merging

### Step 4 — Categorize new tags

Place each uncategorized tag into the most appropriate existing group.

**Guidelines for grouping:**
- Look at the existing group structure and follow its patterns
- A group should have a coherent theme
- If a tag doesn't fit any group, either:
  - Create a new group (only if 3+ tags would belong)
  - Add it to the closest existing group
  - Place it in an "Other" catch-all (keep this minimal)

### Step 5 — Write the hierarchy

**YAML format** (most common):
```yaml
# Tag hierarchy for navigation/sidebar display.
# Keys are group names (may also be tags themselves).
# Values are lists of child tags.
group-name:
  - subtopic:
      - leaf-tag-a
      - leaf-tag-b
  - leaf-tag-c
```

**Rules:**
- If parent names are clickable in your system, they must be actual tags that exist in content
- Don't repeat a parent tag as its own child
- Sub-groups should have 3+ children to justify nesting
- Keep depth to 3 levels max
- Sort groups logically (biggest/most important first)

### Step 6 — Verify

If the project has a build step, run it to ensure the updated hierarchy doesn't break anything. Report:
- Total tags, how many in groups, how many uncategorized
- New groups created or removed
- Dead tags cleaned up

## Edge Cases

- **No existing hierarchy**: Create one from scratch by clustering tags by topic
- **JSON format**: Adapt the output format to match what the project uses
- **Flat tag list (no hierarchy)**: Just maintain a sorted list of valid tags
- **Tags with special characters**: Preserve them as-is, ensure proper quoting in YAML

---

*Generalized from: notes/blog*
