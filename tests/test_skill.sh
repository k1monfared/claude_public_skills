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

# --- new tests ---
echo "=== new ==="

"$SKILL" new test-skill
assert_file_exists "new creates directory" "$PROJECT_DIR/skills/test-skill/SKILL.md"

content=$(cat "$PROJECT_DIR/skills/test-skill/SKILL.md")
assert_contains "new replaces SKILL_NAME in frontmatter" 'name: test-skill' "$content"
assert_contains "new replaces SKILL_NAME in heading" '# test-skill' "$content"

assert_exit_code "new errors on existing skill" 1 "$SKILL" new test-skill

rm -rf "$PROJECT_DIR/skills/test-skill"
"$SKILL" build-manifest > /dev/null 2>&1

echo ""

# --- install tests ---
echo "=== install ==="

TARGET_DIR="$TMPDIR/project1"
mkdir -p "$TARGET_DIR"

"$SKILL" install changelog "$TARGET_DIR" --force
assert_file_exists "install copies SKILL.md" "$TARGET_DIR/.claude/skills/changelog/SKILL.md"
assert_file_exists "install creates .skill-source" "$TARGET_DIR/.claude/skills/changelog/.skill-source"

source_content=$(cat "$TARGET_DIR/.claude/skills/changelog/.skill-source")
assert_contains "source has skill name" '"skill": "changelog"' "$source_content"
assert_contains "source has method copy" '"method": "copy"' "$source_content"

TARGET_DIR2="$TMPDIR/project2"
mkdir -p "$TARGET_DIR2"
"$SKILL" install dev-tools "$TARGET_DIR2" --force
assert_file_exists "group install: changelog" "$TARGET_DIR2/.claude/skills/changelog/SKILL.md"
assert_file_exists "group install: review" "$TARGET_DIR2/.claude/skills/review/SKILL.md"

TARGET_DIR_ALL="$TMPDIR/project-all"
mkdir -p "$TARGET_DIR_ALL"
"$SKILL" install --all "$TARGET_DIR_ALL" --force
assert_file_exists "install --all: changelog" "$TARGET_DIR_ALL/.claude/skills/changelog/SKILL.md"
assert_file_exists "install --all: explain" "$TARGET_DIR_ALL/.claude/skills/explain/SKILL.md"
assert_file_exists "install --all: loglog" "$TARGET_DIR_ALL/.claude/skills/loglog/SKILL.md"
assert_file_exists "install --all: review" "$TARGET_DIR_ALL/.claude/skills/review/SKILL.md"

echo ""

# --- link tests ---
echo "=== link ==="

TARGET_DIR3="$TMPDIR/project3"
mkdir -p "$TARGET_DIR3"

"$SKILL" link changelog "$TARGET_DIR3" --force
assert_symlink "link creates symlink" "$TARGET_DIR3/.claude/skills/changelog"

link_target=$(readlink "$TARGET_DIR3/.claude/skills/changelog")
assert_eq "symlink target is correct" "$PROJECT_DIR/skills/changelog" "$link_target"

output=$("$SKILL" link changelog "$TARGET_DIR3" --force 2>&1)
assert_contains "re-link is no-op" "already linked" "$output"

TARGET_DIR4="$TMPDIR/project4"
mkdir -p "$TARGET_DIR4"
"$SKILL" link dev-tools "$TARGET_DIR4" --force
assert_symlink "group link: changelog" "$TARGET_DIR4/.claude/skills/changelog"
assert_symlink "group link: review" "$TARGET_DIR4/.claude/skills/review"

echo ""

# Summary
echo "=== Results: $PASS passed, $FAIL failed, $TESTS_RUN total ==="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
