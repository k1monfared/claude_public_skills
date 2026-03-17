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

# --- Target resolution ---
resolve_target() {
    local target="$1"
    case "$target" in
        --global|-g) echo "$HOME/.claude/skills" ;;
        *)           echo "$target/.claude/skills" ;;
    esac
}

# --- Skill resolution ---
resolve_skills() {
    local name="$1"

    if [[ "$name" == "--all" ]]; then
        for skill_dir in "$SKILLS_DIR"/*/; do
            [[ -d "$skill_dir" ]] && basename "$skill_dir"
        done
        return
    fi

    if [[ -d "$SKILLS_DIR/$name" ]]; then
        echo "$name"
        return
    fi

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

# --- Lazy validation ---
lazy_validate() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        warn "manifest.json not found. Generating..."
        cmd_build_manifest
        return
    fi

    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"
        if ! grep -q "\"$skill_name\"" "$MANIFEST_FILE"; then
            warn "Skill '$skill_name' not in manifest. Run: ./skill.sh build-manifest"
        fi
    done

    local manifest_skills
    manifest_skills=$(sed -n 's/.*"\([a-zA-Z0-9_-]*\)": {.*/\1/p' "$MANIFEST_FILE" | grep -v '^skills$')
    for skill_name in $manifest_skills; do
        if [[ ! -d "$SKILLS_DIR/$skill_name" ]]; then
            error "Skill '$skill_name' in manifest but directory missing. Run: ./skill.sh build-manifest"
            exit 1
        fi
    done

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

# --- Stub commands (to be implemented in later tasks) ---
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

    local field value
    for field in description version allowed-tools argument-hint tags; do
        value=$(echo "$frontmatter" | sed -n "s/.*\"$field\": \(\"[^\"]*\"\|\[[^]]*\]\).*/\1/p")
        if [[ -n "$value" ]]; then
            printf "  %-16s %s\n" "$field:" "$value"
        fi
    done

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
cmd_install() {
    if [[ $# -lt 2 ]]; then
        error "Usage: skill.sh install <skill|group> <target>"
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
cmd_uninstall() { error "Not yet implemented"; exit 1; }
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

    cmd_build_manifest
}
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
