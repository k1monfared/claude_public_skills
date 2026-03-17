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
cmd_init() { error "Not yet implemented"; exit 1; }

# --- Main ---
parse_args "$@"
