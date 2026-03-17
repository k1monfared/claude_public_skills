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

# Summary
echo "=== Results: $PASS passed, $FAIL failed, $TESTS_RUN total ==="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
