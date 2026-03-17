# Skill Management System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `skill.sh`, a shell CLI that manages Claude Code skills — install, link, scaffold, validate, and keep a manifest in sync.

**Architecture:** Single bash script (`skill.sh`) with helper functions for each command. Skills live in `skills/`, metadata in `manifest.json` (generated) and `groups.json` (hand-maintained). A git pre-commit hook keeps the manifest in sync.

**Tech Stack:** Bash (no external dependencies), JSON via `jq`-free line parsing, standard git hooks.

**Spec:** `docs/superpowers/specs/2026-03-16-skill-management-design.md`

---

## File Structure

```
skill.sh                       # The CLI — all commands, parsing, validation
skills/                        # Migrated from .claude/skills/
  changelog/SKILL.md
  explain/SKILL.md
  loglog/SKILL.md
  review/SKILL.md
templates/SKILL.md             # Scaffold template for `new` command
groups.json                    # Hand-maintained group definitions
manifest.json                  # Auto-generated from SKILL.md frontmatter
tests/test_skill.sh            # Test script for skill.sh
```

---

### Task 1: Migrate skills and set up repo structure

Move existing skills from `.claude/skills/` to top-level `skills/`, add `version` to their frontmatter, create the template, and create `groups.json`.

**Files:**
- Move: `.claude/skills/changelog/` → `skills/changelog/`
- Move: `.claude/skills/explain/` → `skills/explain/`
- Move: `.claude/skills/loglog/` → `skills/loglog/`
- Move: `.claude/skills/review/` → `skills/review/`
- Modify: `skills/changelog/SKILL.md` (add version, tags)
- Modify: `skills/explain/SKILL.md` (add version, tags)
- Modify: `skills/loglog/SKILL.md` (add version, tags)
- Modify: `skills/review/SKILL.md` (add version, tags)
- Create: `templates/SKILL.md`
- Create: `groups.json`

- [ ] **Step 1: Move skill directories**

```bash
mkdir -p skills
mv .claude/skills/changelog skills/changelog
mv .claude/skills/explain skills/explain
mv .claude/skills/loglog skills/loglog
mv .claude/skills/review skills/review
rm -d .claude/skills 2>/dev/null || true
```

- [ ] **Step 2: Add version and tags to each existing SKILL.md**

For each skill, add `version: 1.0.0` and `tags: [...]` to the YAML frontmatter, after the existing fields. The existing fields (`name`, `description`, `allowed-tools`, and `argument-hint` where present) stay unchanged. Note: `loglog` does not have `argument-hint`.

`skills/changelog/SKILL.md` frontmatter becomes:
```yaml
---
name: changelog
description: Generate changelog entries from git commits. Use when asked to create or update a changelog, release notes, or summarize changes.
allowed-tools: Read, Write, Edit, Bash
argument-hint: [version or commit range]
tags: [git, documentation]
version: 1.0.0
---
```

`skills/explain/SKILL.md`:
```yaml
---
name: explain
description: Explain code with analogies, diagrams, and step-by-step walkthroughs. Use when asked to explain how code works, document complex logic, or onboard someone to a codebase.
allowed-tools: Read, Grep, Glob
argument-hint: [file, function, or concept]
tags: [documentation, learning]
version: 1.0.0
---
```

`skills/loglog/SKILL.md`:
```yaml
---
name: loglog
description: Use when creating documentation, notes, status files, or any .log files. Loglog is a hierarchical plain-text documentation format that converts to markdown, HTML, LaTeX, and PDF.
allowed-tools: Read, Write, Edit, Bash
tags: [documentation, format]
version: 1.0.0
---
```

`skills/review/SKILL.md`:
```yaml
---
name: review
description: Review code changes for quality, security, performance, and style issues. Use when asked to review code, PRs, or diffs.
allowed-tools: Read, Bash, Grep, Glob
argument-hint: [file or PR number]
tags: [code-quality, git]
version: 1.0.0
---
```

- [ ] **Step 3: Create `templates/SKILL.md`**

```markdown
---
name: SKILL_NAME
description: Brief description of what this skill does
allowed-tools: Read, Write, Edit, Bash
argument-hint: [optional arguments]
tags: []
version: 0.1.0
---

# SKILL_NAME

Description of when and how to use this skill.
```

- [ ] **Step 4: Create `groups.json`**

```json
{
  "dev-tools": {
    "description": "Development workflow skills",
    "skills": ["changelog", "review"]
  },
  "documentation": {
    "description": "Documentation and explanation skills",
    "skills": ["explain", "loglog", "changelog"]
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add skills/ templates/ groups.json
git rm -r --cached .claude/skills/
git commit -m "Migrate skills to top-level skills/ directory

Move skills from .claude/skills/ to skills/, add version and tags
to frontmatter, create skill template and initial groups.json."
```

---

### Task 2: Build the test harness and core helpers

Create the test script and the skeleton of `skill.sh` with the foundational functions: argument parsing, `SCRIPT_DIR` resolution, color output, and the YAML frontmatter parser.

**Files:**
- Create: `tests/test_skill.sh`
- Create: `skill.sh`

- [ ] **Step 1: Create test script `tests/test_skill.sh`**

```bash
#!/usr/bin/env bash
# Test harness for skill.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SKILL="$PROJECT_DIR/skill.sh"
PASS=0
FAIL=0
TESTS_RUN=0

# Test helper functions
assert_eq() {
    local label="$1" expected="$2" actual="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$expected" == "$actual" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS: $label"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $label"
        echo "    expected: $expected"
        echo "    actual:   $actual"
    fi
}

assert_contains() {
    local label="$1" expected="$2" actual="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$actual" == *"$expected"* ]]; then
        PASS=$((PASS + 1))
        echo "  PASS: $label"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $label"
        echo "    expected to contain: $expected"
        echo "    actual: $actual"
    fi
}

assert_exit_code() {
    local label="$1" expected="$2"
    shift 2
    TESTS_RUN=$((TESTS_RUN + 1))
    local actual_code=0
    "$@" > /dev/null 2>&1 || actual_code=$?
    if [[ "$expected" == "$actual_code" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS: $label"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $label"
        echo "    expected exit code: $expected"
        echo "    actual exit code:   $actual_code"
    fi
}

assert_file_exists() {
    local label="$1" path="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -e "$path" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS: $label"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $label (file not found: $path)"
    fi
}

assert_symlink() {
    local label="$1" path="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -L "$path" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS: $label"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $label (not a symlink: $path)"
    fi
}

# Create temp directory for test targets
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# --- YAML Parser Tests ---
echo "=== YAML Frontmatter Parser ==="

# Test: parse_frontmatter extracts key-value pairs
output=$("$SKILL" _parse_frontmatter "$PROJECT_DIR/skills/changelog/SKILL.md")
assert_contains "parses name field" '"name": "changelog"' "$output"
assert_contains "parses version field" '"version": "1.0.0"' "$output"
assert_contains "parses tags as array" '"tags": ["git", "documentation"]' "$output"
assert_contains "parses allowed-tools" '"allowed-tools": "Read, Write, Edit, Bash"' "$output"

echo ""

# Summary
echo "=== Results: $PASS passed, $FAIL failed, $TESTS_RUN total ==="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
```

- [ ] **Step 2: Run the test — verify it fails**

```bash
chmod +x tests/test_skill.sh
bash tests/test_skill.sh
```
Expected: FAIL (skill.sh doesn't exist yet)

- [ ] **Step 3: Create `skill.sh` skeleton with YAML parser**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
MANIFEST_FILE="$SCRIPT_DIR/manifest.json"
GROUPS_FILE="$SCRIPT_DIR/groups.json"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}info:${NC} $*"; }
warn()  { echo -e "${YELLOW}warn:${NC} $*" >&2; }
error() { echo -e "${RED}error:${NC} $*" >&2; }
success() { echo -e "${GREEN}ok:${NC} $*"; }

# --- Global flags ---
FORCE=false

# --- YAML Frontmatter Parser ---
# Parses YAML frontmatter from a SKILL.md file.
# Outputs JSON-like key-value pairs, one per line.
# Handles: key: value (strings) and key: [a, b, c] (inline arrays)
parse_frontmatter() {
    local file="$1"
    local in_frontmatter=false
    local result="{"
    local first=true

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if $in_frontmatter; then
                break
            else
                in_frontmatter=true
                continue
            fi
        fi

        if $in_frontmatter; then
            # Skip empty lines
            [[ -z "$line" ]] && continue

            # Extract key and value
            local key="${line%%:*}"
            local value="${line#*: }"

            # Trim whitespace from key
            key="$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            value="$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

            if ! $first; then
                result+=", "
            fi
            first=false

            # Check if value is an inline array [a, b, c]
            if [[ "$value" =~ ^\[.*\]$ ]]; then
                # Parse inline array
                local inner="${value#[}"
                inner="${inner%]}"
                local arr_result="["
                local arr_first=true
                IFS=',' read -ra items <<< "$inner"
                for item in "${items[@]}"; do
                    item="$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                    if ! $arr_first; then
                        arr_result+=", "
                    fi
                    arr_first=false
                    arr_result+="\"$item\""
                done
                arr_result+="]"
                result+="\"$key\": $arr_result"
            else
                result+="\"$key\": \"$value\""
            fi
        fi
    done < "$file"

    result+="}"
    echo "$result"
}

# --- Command: _parse_frontmatter (internal, for testing) ---
cmd__parse_frontmatter() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        error "File not found: $file"
        exit 1
    fi
    parse_frontmatter "$file"
}

# --- Usage ---
usage() {
    cat <<'USAGE'
Usage: skill.sh <command> [options]

Commands:
  list                              List all skills and groups
  info <skill>                      Show skill details
  install <skill|group> <target>    Copy skill(s) to target
  link <skill|group> <target>       Symlink skill(s) to target
  uninstall <skill|group> <target>  Remove skill(s) from target
  new <skill-name>                  Scaffold new skill from template
  build-manifest                    Regenerate manifest.json
  validate                          Check manifest and groups are in sync
  init                              Install git pre-commit hook

Target:
  --global, -g    Install to ~/.claude/skills/
  <path>          Install to <path>/.claude/skills/

Flags:
  --force, -f     Skip confirmation prompts
  --all           Apply to all skills
  --help, -h      Show this help
USAGE
}

# --- Argument parsing ---
parse_args() {
    local cmd=""
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f) FORCE=true; shift ;;
            --help|-h)  usage; exit 0 ;;
            *)          args+=("$1"); shift ;;
        esac
    done

    if [[ ${#args[@]} -eq 0 ]]; then
        usage
        exit 1
    fi

    cmd="${args[0]}"
    unset 'args[0]'
    args=("${args[@]+"${args[@]}"}")

    # Route to command handler
    case "$cmd" in
        _parse_frontmatter) cmd__parse_frontmatter "${args[@]}" ;;
        list)               cmd_list "${args[@]+"${args[@]}"}" ;;
        info)               cmd_info "${args[@]}" ;;
        install)            cmd_install "${args[@]}" ;;
        link)               cmd_link "${args[@]}" ;;
        uninstall)          cmd_uninstall "${args[@]}" ;;
        new)                cmd_new "${args[@]}" ;;
        build-manifest)     cmd_build_manifest ;;
        validate)           cmd_validate ;;
        init)               cmd_init ;;
        *)                  error "Unknown command: $cmd"; usage; exit 1 ;;
    esac
}

# --- Stub commands (to be implemented in later tasks) ---
cmd_list() { error "Not yet implemented"; exit 1; }
cmd_info() { error "Not yet implemented"; exit 1; }
cmd_install() { error "Not yet implemented"; exit 1; }
cmd_link() { error "Not yet implemented"; exit 1; }
cmd_uninstall() { error "Not yet implemented"; exit 1; }
cmd_new() { error "Not yet implemented"; exit 1; }
cmd_build_manifest() { error "Not yet implemented"; exit 1; }
cmd_validate() { error "Not yet implemented"; exit 1; }
cmd_init() { error "Not yet implemented"; exit 1; }

# --- Main ---
parse_args "$@"
```

- [ ] **Step 4: Run tests — verify YAML parser tests pass**

```bash
chmod +x skill.sh
bash tests/test_skill.sh
```
Expected: All 4 YAML parser tests PASS.

- [ ] **Step 5: Commit**

```bash
git add skill.sh tests/test_skill.sh
git commit -m "Add skill.sh skeleton with YAML parser and test harness"
```

---

### Task 3: Implement `build-manifest` and `validate`

**Files:**
- Modify: `skill.sh` (replace `cmd_build_manifest` and `cmd_validate` stubs)
- Modify: `tests/test_skill.sh` (add tests)

- [ ] **Step 1: Add tests for `build-manifest` and `validate`**

Append to `tests/test_skill.sh` before the summary section:

```bash
# --- build-manifest tests ---
echo "=== build-manifest ==="

"$SKILL" build-manifest
assert_file_exists "manifest.json created" "$PROJECT_DIR/manifest.json"

manifest=$(cat "$PROJECT_DIR/manifest.json")
assert_contains "manifest has changelog" '"changelog"' "$manifest"
assert_contains "manifest has explain" '"explain"' "$manifest"
assert_contains "manifest has loglog" '"loglog"' "$manifest"
assert_contains "manifest has review" '"review"' "$manifest"
assert_contains "manifest has generated timestamp" '"generated"' "$manifest"

echo ""

# --- validate tests ---
echo "=== validate ==="

# After build-manifest, validate should pass
assert_exit_code "validate passes after build-manifest" 0 "$SKILL" validate

echo ""
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
bash tests/test_skill.sh
```
Expected: FAIL on build-manifest tests.

- [ ] **Step 3: Implement `cmd_build_manifest`**

Replace the stub in `skill.sh`:

```bash
cmd_build_manifest() {
    local result='{'
    local first_skill=true
    local skill_count=0

    result+='"skills": {'

    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local skill_file="$skill_dir/SKILL.md"
        if [[ ! -f "$skill_file" ]]; then
            warn "No SKILL.md in $(basename "$skill_dir"), skipping"
            continue
        fi

        local skill_name
        skill_name="$(basename "$skill_dir")"
        local frontmatter
        frontmatter="$(parse_frontmatter "$skill_file")"

        if ! $first_skill; then
            result+=', '
        fi
        first_skill=false

        result+="\"$skill_name\": $frontmatter"
        skill_count=$((skill_count + 1))
    done

    result+='}, '
    result+="\"generated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

    echo "$result" > "$MANIFEST_FILE"
    success "Manifest written to manifest.json ($skill_count skill(s))"
}
```

- [ ] **Step 4: Implement `cmd_validate`**

Replace the stub in `skill.sh`:

```bash
cmd_validate() {
    local errors=0

    # Check manifest exists
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        error "manifest.json not found. Run: ./skill.sh build-manifest"
        return 1
    fi

    # Check each skill dir on disk is in manifest
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"
        if ! grep -q "\"$skill_name\"" "$MANIFEST_FILE"; then
            error "Skill '$skill_name' exists on disk but not in manifest"
            errors=$((errors + 1))
        fi
    done

    # Check each manifest entry has a directory
    # Extract skill names from manifest using portable regex
    local manifest_skills
    manifest_skills=$(sed -n 's/.*"\([a-zA-Z0-9_-]*\)": {.*/\1/p' "$MANIFEST_FILE" | grep -v '^skills$')
    for skill_name in $manifest_skills; do
        if [[ ! -d "$SKILLS_DIR/$skill_name" ]]; then
            error "Skill '$skill_name' in manifest but directory missing"
            errors=$((errors + 1))
        fi
    done

    # Check groups reference valid skills
    if [[ -f "$GROUPS_FILE" ]]; then
        local group_skills
        group_skills=$(sed -n 's/.*"skills":[[:space:]]*\[\([^]]*\)\].*/\1/p' "$GROUPS_FILE" | tr ',' '\n' | sed 's/[" ]//g' | sort -u | grep -v '^$')
        for skill_name in $group_skills; do
            if [[ ! -d "$SKILLS_DIR/$skill_name" ]]; then
                error "Group references nonexistent skill: '$skill_name'"
                errors=$((errors + 1))
            fi
        done
    fi

    if [[ $errors -gt 0 ]]; then
        error "Validation failed with $errors error(s)"
        return 1
    fi

    success "Validation passed"
    return 0
}
```

- [ ] **Step 5: Run tests — verify they pass**

```bash
bash tests/test_skill.sh
```
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add skill.sh tests/test_skill.sh
git commit -m "Implement build-manifest and validate commands"
```

---

### Task 4: Implement `list` and `info`

**Files:**
- Modify: `skill.sh` (replace `cmd_list` and `cmd_info` stubs)
- Modify: `tests/test_skill.sh` (add tests)

- [ ] **Step 1: Add tests**

```bash
# --- list tests ---
echo "=== list ==="

list_output=$("$SKILL" list)
assert_contains "list shows changelog" "changelog" "$list_output"
assert_contains "list shows review" "review" "$list_output"
assert_contains "list shows groups" "dev-tools" "$list_output"

echo ""

# --- info tests ---
echo "=== info ==="

info_output=$("$SKILL" info changelog)
assert_contains "info shows name" "changelog" "$info_output"
assert_contains "info shows version" "1.0.0" "$info_output"
assert_contains "info shows tags" "git" "$info_output"
assert_contains "info shows group membership" "dev-tools" "$info_output"

echo ""
```

- [ ] **Step 2: Run tests — verify they fail**

Expected: FAIL.

- [ ] **Step 3: Implement lazy validation helper**

Add to `skill.sh` before the command functions:

```bash
# --- Lazy validation ---
# Quick sync check before commands that read manifest/groups.
# Warns on stale manifest, errors on broken references.
lazy_validate() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        warn "manifest.json not found. Generating..."
        cmd_build_manifest
        return
    fi

    # Check for skill dirs not in manifest (stale — warn)
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"
        if ! grep -q "\"$skill_name\"" "$MANIFEST_FILE"; then
            warn "Skill '$skill_name' not in manifest. Run: ./skill.sh build-manifest"
        fi
    done

    # Check manifest entries point to real directories (error)
    local manifest_skills
    manifest_skills=$(sed -n 's/.*"\([a-zA-Z0-9_-]*\)": {.*/\1/p' "$MANIFEST_FILE" | grep -v '^skills$')
    for skill_name in $manifest_skills; do
        if [[ ! -d "$SKILLS_DIR/$skill_name" ]]; then
            error "Skill '$skill_name' in manifest but directory missing. Run: ./skill.sh build-manifest"
            exit 1
        fi
    done

    # Check groups reference valid skills (error)
    if [[ -f "$GROUPS_FILE" ]]; then
        local group_skills
        group_skills=$(sed -n 's/.*"skills":[[:space:]]*\[\([^]]*\)\].*/\1/p' "$GROUPS_FILE" | tr ',' '\n' | sed 's/[" ]//g' | sort -u | grep -v '^$')
        for skill_name in $group_skills; do
            if [[ ! -d "$SKILLS_DIR/$skill_name" ]]; then
                error "Group references nonexistent skill: '$skill_name'"
                exit 1
            fi
        done
    fi
}
```

- [ ] **Step 4: Implement `cmd_list`**

```bash
cmd_list() {
    lazy_validate

    echo "Skills:"
    echo ""
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"
        local frontmatter
        frontmatter="$(parse_frontmatter "$skill_dir/SKILL.md")"

        local version description
        version=$(echo "$frontmatter" | sed -n 's/.*"version": "\([^"]*\)".*/\1/p')
        description=$(echo "$frontmatter" | sed -n 's/.*"description": "\([^"]*\)".*/\1/p')

        printf "  %-20s %-8s %s\n" "$skill_name" "v$version" "$description"
    done

    if [[ -f "$GROUPS_FILE" ]]; then
        echo ""
        echo "Groups:"
        echo ""
        # Parse groups from JSON
        local current_group=""
        while IFS= read -r line; do
            if [[ "$line" =~ \"([a-zA-Z0-9_-]+)\":[[:space:]]*\{ ]]; then
                current_group="${BASH_REMATCH[1]}"
            fi
            if [[ -n "$current_group" && "$line" =~ \"description\":[[:space:]]*\"([^\"]+)\" ]]; then
                local desc="${BASH_REMATCH[1]}"
                printf "  %-20s %s\n" "$current_group" "$desc"
            fi
            if [[ -n "$current_group" && "$line" =~ \"skills\":[[:space:]]*\[([^\]]+)\] ]]; then
                local skills_str="${BASH_REMATCH[1]}"
                local skills_clean
                skills_clean=$(echo "$skills_str" | sed 's/"//g; s/,/ /g; s/^[[:space:]]*//; s/[[:space:]]*$//')
                echo "    skills: $skills_clean"
                current_group=""
            fi
        done < "$GROUPS_FILE"
    fi
}
```

- [ ] **Step 5: Implement `cmd_info`**

```bash
cmd_info() {
    local skill_name="${1:-}"
    if [[ -z "$skill_name" ]]; then
        error "Usage: skill.sh info <skill>"
        exit 1
    fi

    local skill_dir="$SKILLS_DIR/$skill_name"
    if [[ ! -d "$skill_dir" ]]; then
        error "Skill not found: $skill_name"
        exit 1
    fi

    lazy_validate

    local frontmatter
    frontmatter="$(parse_frontmatter "$skill_dir/SKILL.md")"

    echo "Skill: $skill_name"
    echo ""

    # Extract and display fields
    local field value
    for field in description version allowed-tools argument-hint tags; do
        value=$(echo "$frontmatter" | sed -n "s/.*\"$field\": \(\"[^\"]*\"\|\[[^]]*\]\).*/\1/p")
        if [[ -n "$value" ]]; then
            printf "  %-16s %s\n" "$field:" "$value"
        fi
    done

    # Show group membership
    if [[ -f "$GROUPS_FILE" ]]; then
        local groups=""
        local current_group=""
        while IFS= read -r line; do
            if [[ "$line" =~ \"([a-zA-Z0-9_-]+)\":[[:space:]]*\{ ]]; then
                current_group="${BASH_REMATCH[1]}"
            fi
            if [[ -n "$current_group" && "$line" =~ \"skills\" && "$line" == *"\"$skill_name\""* ]]; then
                groups+="$current_group "
            fi
        done < "$GROUPS_FILE"

        if [[ -n "$groups" ]]; then
            printf "  %-16s %s\n" "groups:" "$groups"
        fi
    fi
}
```

- [ ] **Step 6: Run tests — verify they pass**

```bash
bash tests/test_skill.sh
```
Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add skill.sh tests/test_skill.sh
git commit -m "Implement list and info commands"
```

---

### Task 5: Implement `new` command

**Files:**
- Modify: `skill.sh` (replace `cmd_new` stub)
- Modify: `tests/test_skill.sh` (add tests)

- [ ] **Step 1: Add tests**

```bash
# --- new tests ---
echo "=== new ==="

# Test: new creates a skill directory
"$SKILL" new test-skill
assert_file_exists "new creates directory" "$PROJECT_DIR/skills/test-skill/SKILL.md"

# Verify SKILL_NAME was replaced
content=$(cat "$PROJECT_DIR/skills/test-skill/SKILL.md")
assert_contains "new replaces SKILL_NAME in frontmatter" 'name: test-skill' "$content"
assert_contains "new replaces SKILL_NAME in heading" '# test-skill' "$content"

# Test: new errors if skill already exists
assert_exit_code "new errors on existing skill" 1 "$SKILL" new test-skill

# Clean up test skill
rm -rf "$PROJECT_DIR/skills/test-skill"
"$SKILL" build-manifest > /dev/null 2>&1

echo ""
```

- [ ] **Step 2: Run tests — verify they fail**

Expected: FAIL.

- [ ] **Step 3: Implement `cmd_new`**

```bash
cmd_new() {
    local skill_name="${1:-}"
    if [[ -z "$skill_name" ]]; then
        error "Usage: skill.sh new <skill-name>"
        exit 1
    fi

    local skill_dir="$SKILLS_DIR/$skill_name"
    if [[ -d "$skill_dir" ]]; then
        error "Skill already exists: $skill_name"
        exit 1
    fi

    local template="$TEMPLATES_DIR/SKILL.md"
    if [[ ! -f "$template" ]]; then
        error "Template not found: $template"
        exit 1
    fi

    mkdir -p "$skill_dir"
    sed "s/SKILL_NAME/$skill_name/g" "$template" > "$skill_dir/SKILL.md"

    success "Created skill: $skill_name"
    info "Edit skills/$skill_name/SKILL.md to customize"

    # Auto-regenerate manifest
    cmd_build_manifest
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
bash tests/test_skill.sh
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add skill.sh tests/test_skill.sh
git commit -m "Implement new command for scaffolding skills"
```

---

### Task 6: Implement target resolution and `install` command

**Files:**
- Modify: `skill.sh` (add `resolve_target`, `resolve_skills`, replace `cmd_install` stub)
- Modify: `tests/test_skill.sh` (add tests)

- [ ] **Step 1: Add tests**

```bash
# --- install tests ---
echo "=== install ==="

TARGET_DIR="$TMPDIR/project1"
mkdir -p "$TARGET_DIR"

# Install single skill
"$SKILL" install changelog "$TARGET_DIR" --force
assert_file_exists "install copies SKILL.md" "$TARGET_DIR/.claude/skills/changelog/SKILL.md"
assert_file_exists "install creates .skill-source" "$TARGET_DIR/.claude/skills/changelog/.skill-source"

# Verify .skill-source content
source_content=$(cat "$TARGET_DIR/.claude/skills/changelog/.skill-source")
assert_contains "source has skill name" '"skill": "changelog"' "$source_content"
assert_contains "source has method copy" '"method": "copy"' "$source_content"

# Install group
TARGET_DIR2="$TMPDIR/project2"
mkdir -p "$TARGET_DIR2"
"$SKILL" install dev-tools "$TARGET_DIR2" --force
assert_file_exists "group install: changelog" "$TARGET_DIR2/.claude/skills/changelog/SKILL.md"
assert_file_exists "group install: review" "$TARGET_DIR2/.claude/skills/review/SKILL.md"

# Install --all
TARGET_DIR_ALL="$TMPDIR/project-all"
mkdir -p "$TARGET_DIR_ALL"
"$SKILL" install --all "$TARGET_DIR_ALL" --force
assert_file_exists "install --all: changelog" "$TARGET_DIR_ALL/.claude/skills/changelog/SKILL.md"
assert_file_exists "install --all: explain" "$TARGET_DIR_ALL/.claude/skills/explain/SKILL.md"
assert_file_exists "install --all: loglog" "$TARGET_DIR_ALL/.claude/skills/loglog/SKILL.md"
assert_file_exists "install --all: review" "$TARGET_DIR_ALL/.claude/skills/review/SKILL.md"

echo ""
```

- [ ] **Step 2: Run tests — verify they fail**

Expected: FAIL.

- [ ] **Step 3: Implement helper functions**

Add to `skill.sh`:

```bash
# --- Target resolution ---
# Resolves a target argument to a full path.
# --global/-g → ~/.claude/skills/
# <path> → <path>/.claude/skills/
resolve_target() {
    local target="$1"
    case "$target" in
        --global|-g) echo "$HOME/.claude/skills" ;;
        *)           echo "$target/.claude/skills" ;;
    esac
}

# --- Skill resolution ---
# Given a name that could be a skill or a group, returns list of skill names.
resolve_skills() {
    local name="$1"

    # Check if it's --all
    if [[ "$name" == "--all" ]]; then
        for skill_dir in "$SKILLS_DIR"/*/; do
            [[ -d "$skill_dir" ]] && basename "$skill_dir"
        done
        return
    fi

    # Check if it's a skill
    if [[ -d "$SKILLS_DIR/$name" ]]; then
        echo "$name"
        return
    fi

    # Check if it's a group
    if [[ -f "$GROUPS_FILE" ]]; then
        local in_group=false
        while IFS= read -r line; do
            if [[ "$line" =~ \"$name\":[[:space:]]*\{ ]]; then
                in_group=true
            fi
            if $in_group && [[ "$line" =~ \"skills\":[[:space:]]*\[([^\]]+)\] ]]; then
                local skills_str="${BASH_REMATCH[1]}"
                echo "$skills_str" | sed 's/"//g; s/,/\n/g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'
                return
            fi
        done < "$GROUPS_FILE"
    fi

    error "Unknown skill or group: $name"
    exit 1
}

# --- Confirm prompt ---
confirm() {
    local message="$1"
    if $FORCE; then
        return 0
    fi
    read -r -p "$message [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}
```

- [ ] **Step 4: Implement `cmd_install`**

```bash
cmd_install() {
    if [[ $# -lt 2 ]]; then
        error "Usage: skill.sh install <skill|group> <target>"
        exit 1
    fi

    # Parse args — find the --force flag anywhere
    local skill_or_group="" target=""
    local positional=()
    for arg in "$@"; do
        case "$arg" in
            --force|-f) FORCE=true ;;
            *) positional+=("$arg") ;;
        esac
    done

    skill_or_group="${positional[0]}"
    target="${positional[1]}"

    lazy_validate

    local target_dir
    target_dir="$(resolve_target "$target")"
    mkdir -p "$target_dir"

    local skills
    skills="$(resolve_skills "$skill_or_group")"

    local count=0
    while IFS= read -r skill_name; do
        [[ -z "$skill_name" ]] && continue
        local src="$SKILLS_DIR/$skill_name"
        local dest="$target_dir/$skill_name"

        if [[ -L "$dest" ]]; then
            warn "'$skill_name' exists as a symlink at target"
            if ! confirm "Replace symlink with copy?"; then
                info "Skipping $skill_name"
                continue
            fi
            rm "$dest"
        elif [[ -d "$dest" ]]; then
            warn "'$skill_name' already exists at target"
            if ! confirm "Overwrite?"; then
                info "Skipping $skill_name"
                continue
            fi
            rm -rf "$dest"
        fi

        cp -r "$src" "$dest"

        # Write .skill-source marker
        local version
        version=$(parse_frontmatter "$src/SKILL.md" | sed -n 's/.*"version": "\([^"]*\)".*/\1/p')

        cat > "$dest/.skill-source" <<EOF
{
  "source": "claude_public_skills",
  "skill": "$skill_name",
  "version": "$version",
  "installed": "$(date +%Y-%m-%d)",
  "method": "copy"
}
EOF

        success "Installed $skill_name → $dest"
        count=$((count + 1))
    done <<< "$skills"

    info "$count skill(s) installed to $target_dir"
}
```

- [ ] **Step 5: Run tests — verify they pass**

```bash
bash tests/test_skill.sh
```
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add skill.sh tests/test_skill.sh
git commit -m "Implement install command with target resolution and conflict handling"
```

---

### Task 7: Implement `link` command

**Files:**
- Modify: `skill.sh` (replace `cmd_link` stub)
- Modify: `tests/test_skill.sh` (add tests)

- [ ] **Step 1: Add tests**

```bash
# --- link tests ---
echo "=== link ==="

TARGET_DIR3="$TMPDIR/project3"
mkdir -p "$TARGET_DIR3"

# Link single skill
"$SKILL" link changelog "$TARGET_DIR3" --force
assert_symlink "link creates symlink" "$TARGET_DIR3/.claude/skills/changelog"

# Verify symlink points to correct source
link_target=$(readlink "$TARGET_DIR3/.claude/skills/changelog")
assert_eq "symlink target is correct" "$PROJECT_DIR/skills/changelog" "$link_target"

# Link same skill again — should be no-op
output=$("$SKILL" link changelog "$TARGET_DIR3" --force 2>&1)
assert_contains "re-link is no-op" "already linked" "$output"

# Link group
TARGET_DIR4="$TMPDIR/project4"
mkdir -p "$TARGET_DIR4"
"$SKILL" link dev-tools "$TARGET_DIR4" --force
assert_symlink "group link: changelog" "$TARGET_DIR4/.claude/skills/changelog"
assert_symlink "group link: review" "$TARGET_DIR4/.claude/skills/review"

echo ""
```

- [ ] **Step 2: Run tests — verify they fail**

Expected: FAIL.

- [ ] **Step 3: Implement `cmd_link`**

```bash
cmd_link() {
    if [[ $# -lt 2 ]]; then
        error "Usage: skill.sh link <skill|group> <target>"
        exit 1
    fi

    local skill_or_group="" target=""
    local positional=()
    for arg in "$@"; do
        case "$arg" in
            --force|-f) FORCE=true ;;
            *) positional+=("$arg") ;;
        esac
    done

    skill_or_group="${positional[0]}"
    target="${positional[1]}"

    lazy_validate

    local target_dir
    target_dir="$(resolve_target "$target")"
    mkdir -p "$target_dir"

    local skills
    skills="$(resolve_skills "$skill_or_group")"

    local count=0
    while IFS= read -r skill_name; do
        [[ -z "$skill_name" ]] && continue
        local src="$SKILLS_DIR/$skill_name"
        local dest="$target_dir/$skill_name"

        if [[ -L "$dest" ]]; then
            local existing_target
            existing_target="$(readlink "$dest")"
            if [[ "$existing_target" == "$src" ]]; then
                info "'$skill_name' already linked"
                continue
            else
                warn "'$skill_name' symlinked to different source: $existing_target"
                if ! confirm "Update symlink?"; then
                    info "Skipping $skill_name"
                    continue
                fi
                rm "$dest"
            fi
        elif [[ -d "$dest" ]]; then
            warn "'$skill_name' exists as a directory (not symlink) at target"
            if ! $FORCE; then
                warn "Use --force to replace directory with symlink"
                info "Skipping $skill_name"
                continue
            fi
            rm -rf "$dest"
        fi

        ln -s "$src" "$dest"
        success "Linked $skill_name → $dest"
        count=$((count + 1))
    done <<< "$skills"

    info "$count skill(s) linked to $target_dir"
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
bash tests/test_skill.sh
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add skill.sh tests/test_skill.sh
git commit -m "Implement link command with symlink conflict handling"
```

---

### Task 8: Implement `uninstall` command

**Files:**
- Modify: `skill.sh` (replace `cmd_uninstall` stub)
- Modify: `tests/test_skill.sh` (add tests)

- [ ] **Step 1: Add tests**

```bash
# --- uninstall tests ---
echo "=== uninstall ==="

# Uninstall a copied skill (from install tests — TARGET_DIR)
"$SKILL" uninstall changelog "$TARGET_DIR" --force
assert_exit_code "uninstall removes installed skill" 0 test ! -d "$TARGET_DIR/.claude/skills/changelog"

# Uninstall a linked skill (from link tests — TARGET_DIR3)
"$SKILL" uninstall changelog "$TARGET_DIR3" --force
assert_exit_code "uninstall removes linked skill" 0 test ! -L "$TARGET_DIR3/.claude/skills/changelog"

# Uninstall refuses on skill without .skill-source marker or symlink
# Use a known skill name (changelog) but place it manually without the marker
FOREIGN_DIR="$TMPDIR/foreign"
mkdir -p "$FOREIGN_DIR/.claude/skills/changelog"
echo "manually placed" > "$FOREIGN_DIR/.claude/skills/changelog/SKILL.md"
# No .skill-source file — should refuse
assert_exit_code "uninstall refuses foreign skill" 1 "$SKILL" uninstall changelog "$FOREIGN_DIR"
# Verify it was NOT deleted
assert_file_exists "foreign skill preserved" "$FOREIGN_DIR/.claude/skills/changelog/SKILL.md"

echo ""
```

- [ ] **Step 2: Run tests — verify they fail**

Expected: FAIL.

- [ ] **Step 3: Implement `cmd_uninstall`**

```bash
cmd_uninstall() {
    if [[ $# -lt 2 ]]; then
        error "Usage: skill.sh uninstall <skill|group> <target>"
        exit 1
    fi

    local skill_or_group="" target=""
    local positional=()
    for arg in "$@"; do
        case "$arg" in
            --force|-f) FORCE=true ;;
            *) positional+=("$arg") ;;
        esac
    done

    skill_or_group="${positional[0]}"
    target="${positional[1]}"

    local target_dir
    target_dir="$(resolve_target "$target")"

    local skills
    skills="$(resolve_skills "$skill_or_group")"

    local count=0
    while IFS= read -r skill_name; do
        [[ -z "$skill_name" ]] && continue
        local dest="$target_dir/$skill_name"

        if [[ ! -e "$dest" && ! -L "$dest" ]]; then
            warn "'$skill_name' not found at target"
            continue
        fi

        # Check if it's a symlink (we created it)
        if [[ -L "$dest" ]]; then
            rm "$dest"
            success "Uninstalled $skill_name (symlink removed)"
            count=$((count + 1))
            continue
        fi

        # Check for .skill-source marker (we installed it)
        if [[ -f "$dest/.skill-source" ]]; then
            rm -rf "$dest"
            success "Uninstalled $skill_name (directory removed)"
            count=$((count + 1))
            continue
        fi

        # Not ours — refuse unless --force
        if $FORCE; then
            rm -rf "$dest"
            success "Uninstalled $skill_name (forced)"
            count=$((count + 1))
        else
            error "'$skill_name' was not installed by skill.sh (no .skill-source marker)"
            error "Use --force to remove anyway"
            return 1
        fi
    done <<< "$skills"

    info "$count skill(s) uninstalled from $target_dir"
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
bash tests/test_skill.sh
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add skill.sh tests/test_skill.sh
git commit -m "Implement uninstall command with source tracking safety"
```

---

### Task 9: Implement `init` (git pre-commit hook)

**Files:**
- Modify: `skill.sh` (replace `cmd_init` stub)
- Modify: `tests/test_skill.sh` (add tests)

- [ ] **Step 1: Add tests**

```bash
# --- init tests ---
echo "=== init ==="

# Save existing pre-commit hook if any
HOOK_FILE="$PROJECT_DIR/.git/hooks/pre-commit"
HOOK_BACKUP=""
if [[ -f "$HOOK_FILE" ]]; then
    HOOK_BACKUP="$TMPDIR/pre-commit.backup"
    cp "$HOOK_FILE" "$HOOK_BACKUP"
    rm "$HOOK_FILE"
fi

"$SKILL" init
assert_file_exists "init creates pre-commit hook" "$HOOK_FILE"

hook_content=$(cat "$HOOK_FILE")
assert_contains "hook runs build-manifest" "build-manifest" "$hook_content"
assert_contains "hook runs validate" "validate" "$hook_content"

# Clean up — restore original hook or remove the one we created
if [[ -n "$HOOK_BACKUP" ]]; then
    cp "$HOOK_BACKUP" "$HOOK_FILE"
else
    rm -f "$HOOK_FILE"
fi

echo ""
```

- [ ] **Step 2: Run tests — verify they fail**

Expected: FAIL.

- [ ] **Step 3: Implement `cmd_init`**

```bash
cmd_init() {
    local git_dir="$SCRIPT_DIR/.git"
    if [[ ! -d "$git_dir" ]]; then
        error "Not a git repository"
        exit 1
    fi

    local hook_dir="$git_dir/hooks"
    local hook_file="$hook_dir/pre-commit"

    mkdir -p "$hook_dir"

    # Check if hook already exists
    if [[ -f "$hook_file" ]]; then
        if grep -q "skill.sh" "$hook_file"; then
            info "Pre-commit hook already installed"
            return 0
        fi
        warn "Existing pre-commit hook found"
        if ! confirm "Append skill.sh checks to existing hook?"; then
            info "Skipping hook installation"
            return 0
        fi
        # Append to existing hook
        cat >> "$hook_file" <<'HOOK'

# --- skill.sh manifest sync ---
REPO_DIR="$(git rev-parse --show-toplevel)"
"$REPO_DIR/skill.sh" build-manifest
git add "$REPO_DIR/manifest.json"
"$REPO_DIR/skill.sh" validate
HOOK
    else
        cat > "$hook_file" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail

# --- skill.sh manifest sync ---
REPO_DIR="$(git rev-parse --show-toplevel)"
"$REPO_DIR/skill.sh" build-manifest
git add "$REPO_DIR/manifest.json"
"$REPO_DIR/skill.sh" validate
HOOK
    fi

    chmod +x "$hook_file"
    success "Pre-commit hook installed at $hook_file"
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
bash tests/test_skill.sh
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add skill.sh tests/test_skill.sh
git commit -m "Implement init command for git pre-commit hook"
```

---

### Task 10: Generate initial manifest and final polish

**Files:**
- Generate: `manifest.json`
- Modify: `readme.log` (update project description)
- Modify: `STATUS.log` (update project status)

- [ ] **Step 1: Generate manifest**

```bash
./skill.sh build-manifest
```

- [ ] **Step 2: Run full validation**

```bash
./skill.sh validate
```
Expected: "Validation passed"

- [ ] **Step 3: Run full test suite**

```bash
bash tests/test_skill.sh
```
Expected: All tests PASS, 0 failures.

- [ ] **Step 4: Update readme.log**

Update to reflect the project's actual purpose and usage:

```
- Claude Public Skills
    - A collection of reusable Claude Code skills with a management CLI.
    - Skills are developed here and can be installed or linked into any project.

- Quick Start
    - Clone: git clone <repo-url>
    - List skills: ./skill.sh list
    - Install a skill: ./skill.sh install changelog --global
    - Link for development: ./skill.sh link --all --global
    - Create new skill: ./skill.sh new my-skill

- Commands
    - list: Show all available skills and groups
    - info <skill>: Show skill details
    - install <skill|group> <target>: Copy skill(s) to target
    - link <skill|group> <target>: Symlink skill(s) to target
    - uninstall <skill|group> <target>: Remove skill(s) from target
    - new <name>: Scaffold a new skill from template
    - build-manifest: Regenerate manifest.json
    - validate: Check everything is in sync
    - init: Install git pre-commit hook

- Targets
    - --global or -g: Install to ~/.claude/skills/
    - <path>: Install to <path>/.claude/skills/

- Flags
    - --force or -f: Skip confirmation prompts
    - --all: Apply to all skills
```

- [ ] **Step 5: Update STATUS.log**

Update stage to MVP, fill in tech stack and key files.

- [ ] **Step 6: Commit**

```bash
git add manifest.json readme.log STATUS.log
git commit -m "Generate initial manifest and update project docs"
```

- [ ] **Step 7: Run full test suite one final time**

```bash
bash tests/test_skill.sh
```
Expected: All tests PASS.
