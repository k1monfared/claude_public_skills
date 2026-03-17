# Claude Public Skills

**Status**: 🟡 MVP | **Mode**: 🤖 Claude Code | **Updated**: 2026-03-16

A collection of reusable [Claude Code](https://claude.ai/claude-code) skills with a management CLI. Skills are developed here and can be installed or linked into any project.

## What Are Skills?

Claude Code skills are markdown files that teach Claude how to perform specific tasks. They live in `.claude/skills/` in your project (project-specific) or `~/.claude/skills/` (global, available everywhere). When Claude sees a task that matches a skill, it follows the skill's instructions.

## Available Skills

### Development Tools
| Skill | Description |
|-------|-------------|
| **changelog** | Generate changelog entries from git commits |
| **review** | Review code changes for quality, security, performance, and style |

### Documentation
| Skill | Description |
|-------|-------------|
| **explain** | Explain code with analogies, diagrams, and step-by-step walkthroughs |
| **loglog** | Create documentation using the loglog hierarchical plain-text format |

### Skill Meta (creating and managing skills)
| Skill | Description |
|-------|-------------|
| **create-skill** | Draft a new skill from a task description |
| **improve-skill** | Review and improve an existing skill file |
| **skill-audit** | Score skills against a structural completeness rubric |
| **cross-skill-patterns** | Find patterns, asymmetries, and redundancy across skills |
| **synthesize-learnings** | Extract cross-cutting themes from usage history |
| **skill-management** | Full skill system health analysis and prioritised improvement |

## Quick Start

### Using skills from this repo

**Option A: Install (copy) specific skills**
```bash
git clone <repo-url>
cd claude_public_skills

# Install one skill globally (available in all projects)
./skill.sh install changelog --global

# Install a group of skills into a specific project
./skill.sh install dev-tools /path/to/my-project

# Install all skills globally
./skill.sh install --all --global
```

**Option B: Link (symlink) for live updates**
```bash
# Link all skills globally — changes in this repo are reflected instantly
./skill.sh link --all --global

# Link a group into a project
./skill.sh link documentation /path/to/my-project
```

The difference: `install` copies files (snapshot), `link` creates symlinks (always up to date with `git pull`).

### Browsing skills

```bash
# List all available skills and groups
./skill.sh list

# Show details about a specific skill
./skill.sh info changelog

# Validate everything is in sync
./skill.sh validate
```

### Uninstalling

```bash
# Remove a skill from a project
./skill.sh uninstall changelog /path/to/my-project

# Remove a skill globally
./skill.sh uninstall changelog --global

# Remove a group
./skill.sh uninstall dev-tools --global
```

## Developing Skills

### Creating a new skill

```bash
# Scaffold from template
./skill.sh new my-skill-name

# This creates skills/my-skill-name/SKILL.md with a template
# Edit the file to add your skill's instructions
```

### Skill file structure

Each skill is a directory under `skills/` containing a `SKILL.md` with YAML frontmatter:

```yaml
---
name: my-skill
description: One-line description of what this skill does
allowed-tools: Read, Write, Edit, Bash
argument-hint: [expected arguments]
tags: [relevant, tags]
version: 1.0.0
---

# My Skill

Instructions for Claude to follow when this skill is invoked...
```

### Skill groups

Groups are defined in `groups.json`. A skill can belong to multiple groups:

```json
{
  "my-group": {
    "description": "What this group is for",
    "skills": ["skill-a", "skill-b"]
  }
}
```

### Development workflow

1. Create or edit skills in `skills/`
2. Run `./skill.sh build-manifest` to update `manifest.json`
3. Run `./skill.sh validate` to check everything is consistent
4. Run `bash tests/test_skill.sh` to run the test suite
5. Commit — the pre-commit hook auto-regenerates the manifest

Set up the pre-commit hook (once after cloning):
```bash
./skill.sh init
```

### Testing your skills

Link skills into your project and use them:
```bash
./skill.sh link my-skill /path/to/project
# Now use the skill in that project's Claude Code session
```

Use the meta-skills to improve quality:
```bash
# In a Claude Code session:
/skill-audit           # Score all skills against quality rubric
/improve-skill review  # Analyse and improve a specific skill
/skill-management      # Full system health check
```

## CLI Reference

| Command | Description |
|---------|-------------|
| `./skill.sh list` | List all skills and groups |
| `./skill.sh info <skill>` | Show skill details |
| `./skill.sh install <skill\|group> <target>` | Copy skill(s) to target |
| `./skill.sh link <skill\|group> <target>` | Symlink skill(s) to target |
| `./skill.sh uninstall <skill\|group> <target>` | Remove skill(s) from target |
| `./skill.sh new <name>` | Scaffold a new skill from template |
| `./skill.sh build-manifest` | Regenerate manifest.json |
| `./skill.sh validate` | Check manifest and groups are in sync |
| `./skill.sh init` | Install git pre-commit hook |

**Targets:** `--global` / `-g` (installs to `~/.claude/skills/`) or a path (installs to `<path>/.claude/skills/`)

**Flags:** `--force` / `-f` (skip prompts), `--all` (apply to all skills)

## Contributing

1. Fork and clone
2. Run `./skill.sh init` to set up the pre-commit hook
3. Create your skill: `./skill.sh new my-skill`
4. Edit `skills/my-skill/SKILL.md`
5. Add it to a group in `groups.json` (or create a new group)
6. Run tests: `bash tests/test_skill.sh`
7. Submit a PR

## License

MIT
