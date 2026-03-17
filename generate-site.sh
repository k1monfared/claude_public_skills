#!/usr/bin/env bash
set -euo pipefail

# Generate a static GitHub Pages site from skills and README
# Output: docs/index.html (GitHub Pages serves from docs/)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
GROUPS_FILE="$SCRIPT_DIR/groups.json"
OUTPUT_DIR="$SCRIPT_DIR/docs"
OUTPUT_FILE="$OUTPUT_DIR/index.html"

mkdir -p "$OUTPUT_DIR"

# --- Collect skill data ---
skills_html=""
skill_nav=""
skill_count=0

for skill_dir in "$SKILLS_DIR"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    skill_file="$skill_dir/SKILL.md"
    [[ -f "$skill_file" ]] || continue

    skill_count=$((skill_count + 1))

    # Parse frontmatter
    description=""
    version=""
    tags=""
    allowed_tools=""
    in_fm=false

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if $in_fm; then break; else in_fm=true; continue; fi
        fi
        if $in_fm; then
            case "$line" in
                description:*) description="${line#description: }" ;;
                version:*) version="${line#version: }" ;;
                tags:*) tags="${line#tags: }" ;;
                allowed-tools:*) allowed_tools="${line#allowed-tools: }" ;;
            esac
        fi
    done < "$skill_file"

    # Extract body (everything after second ---)
    body=""
    found_start=false
    found_end=false
    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if ! $found_start; then
                found_start=true
                continue
            elif ! $found_end; then
                found_end=true
                continue
            fi
        fi
        if $found_end; then
            # Escape HTML special chars
            line="${line//&/&amp;}"
            line="${line//</&lt;}"
            line="${line//>/&gt;}"
            body+="$line
"
        fi
    done < "$skill_file"

    # Clean up tags display
    tags_display="${tags//[\[\]]/}"
    tags_display="${tags_display//,/ }"

    # Build tag badges
    tag_badges=""
    if [[ -n "$tags_display" ]]; then
        for tag in $tags_display; do
            tag="$(echo "$tag" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [[ -z "$tag" ]] && continue
            tag_badges+="<span class=\"tag\">${tag}</span>"
        done
    fi

    # Build nav item
    skill_nav+="<a href=\"#skill-${skill_name}\" class=\"nav-skill\">${skill_name}</a>"

    # Build skill card
    skills_html+="
    <section id=\"skill-${skill_name}\" class=\"skill-card\">
      <div class=\"skill-header\">
        <h3>${skill_name}</h3>
        <span class=\"version\">v${version}</span>
      </div>
      <p class=\"skill-desc\">${description}</p>
      <div class=\"skill-meta\">
        ${tag_badges}
        <span class=\"tools\" title=\"Allowed tools\">${allowed_tools}</span>
      </div>
      <details>
        <summary>View full skill instructions</summary>
        <pre class=\"skill-body\">${body}</pre>
      </details>
    </section>"
done

# --- Collect group data ---
groups_html=""
if [[ -f "$GROUPS_FILE" ]]; then
    current_group=""
    current_desc=""
    while IFS= read -r line; do
        if [[ "$line" =~ \"([a-zA-Z0-9_-]+)\":[[:space:]]*\{ ]]; then
            current_group="${BASH_REMATCH[1]}"
        fi
        if [[ -n "$current_group" && "$line" =~ \"description\":[[:space:]]*\"([^\"]+)\" ]]; then
            current_desc="${BASH_REMATCH[1]}"
        fi
        if [[ -n "$current_group" && "$line" =~ \"skills\":[[:space:]]*\[([^\]]+)\] ]]; then
            skills_str="${BASH_REMATCH[1]}"
            skills_clean=$(echo "$skills_str" | sed 's/"//g; s/,/\n/g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$')

            skill_links=""
            for s in $skills_clean; do
                skill_links+="<a href=\"#skill-${s}\" class=\"group-skill-link\">${s}</a>"
            done

            groups_html+="
            <div class=\"group-card\">
              <h4>${current_group}</h4>
              <p>${current_desc}</p>
              <div class=\"group-skills\">${skill_links}</div>
            </div>"
            current_group=""
        fi
    done < "$GROUPS_FILE"
fi

# --- Generate HTML ---
cat > "$OUTPUT_FILE" << 'HTML_HEAD'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Claude Public Skills</title>
<style>
  :root {
    --bg: #0d1117;
    --surface: #161b22;
    --surface-hover: #1c2129;
    --border: #30363d;
    --text: #e6edf3;
    --text-muted: #8b949e;
    --accent: #58a6ff;
    --accent-subtle: #1f6feb33;
    --green: #3fb950;
    --orange: #d29922;
    --purple: #bc8cff;
    --pink: #f778ba;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Noto, Helvetica, Arial, sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.6;
  }

  .layout {
    display: grid;
    grid-template-columns: 260px 1fr;
    min-height: 100vh;
  }

  /* --- Sidebar --- */
  .sidebar {
    background: var(--surface);
    border-right: 1px solid var(--border);
    padding: 24px 16px;
    position: sticky;
    top: 0;
    height: 100vh;
    overflow-y: auto;
  }

  .sidebar h1 {
    font-size: 18px;
    margin-bottom: 4px;
    color: var(--text);
  }

  .sidebar .subtitle {
    font-size: 12px;
    color: var(--text-muted);
    margin-bottom: 24px;
  }

  .sidebar h2 {
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    color: var(--text-muted);
    margin: 20px 0 8px;
  }

  .nav-skill {
    display: block;
    padding: 6px 12px;
    color: var(--text-muted);
    text-decoration: none;
    font-size: 14px;
    border-radius: 6px;
    transition: all 0.15s;
  }

  .nav-skill:hover {
    background: var(--surface-hover);
    color: var(--text);
  }

  .nav-link {
    display: block;
    padding: 6px 12px;
    color: var(--accent);
    text-decoration: none;
    font-size: 14px;
    border-radius: 6px;
    transition: all 0.15s;
  }

  .nav-link:hover {
    background: var(--accent-subtle);
  }

  /* --- Main content --- */
  .main {
    padding: 48px;
    max-width: 960px;
  }

  .hero {
    margin-bottom: 48px;
  }

  .hero h1 {
    font-size: 36px;
    margin-bottom: 8px;
    background: linear-gradient(135deg, var(--accent), var(--purple));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }

  .hero p {
    font-size: 18px;
    color: var(--text-muted);
    max-width: 600px;
  }

  .stat-row {
    display: flex;
    gap: 24px;
    margin: 24px 0 0;
  }

  .stat {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 16px 24px;
    text-align: center;
  }

  .stat .num {
    font-size: 28px;
    font-weight: 700;
    color: var(--accent);
  }

  .stat .label {
    font-size: 12px;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  /* --- Sections --- */
  .section-title {
    font-size: 24px;
    margin: 48px 0 16px;
    padding-bottom: 8px;
    border-bottom: 1px solid var(--border);
  }

  /* --- Quick Start --- */
  .quickstart {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 24px;
    margin: 24px 0;
  }

  .quickstart h3 {
    font-size: 16px;
    margin-bottom: 12px;
    color: var(--green);
  }

  .quickstart code {
    display: block;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 12px 16px;
    margin: 8px 0;
    font-family: 'SF Mono', Monaco, Consolas, monospace;
    font-size: 13px;
    color: var(--text);
    overflow-x: auto;
  }

  .quickstart p {
    color: var(--text-muted);
    font-size: 14px;
    margin: 8px 0;
  }

  /* --- Groups --- */
  .groups-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 16px;
    margin: 16px 0;
  }

  .group-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 20px;
  }

  .group-card h4 {
    font-size: 16px;
    margin-bottom: 4px;
    color: var(--purple);
  }

  .group-card p {
    font-size: 13px;
    color: var(--text-muted);
    margin-bottom: 12px;
  }

  .group-skills {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
  }

  .group-skill-link {
    background: var(--accent-subtle);
    color: var(--accent);
    padding: 2px 10px;
    border-radius: 12px;
    text-decoration: none;
    font-size: 12px;
    transition: background 0.15s;
  }

  .group-skill-link:hover {
    background: var(--accent);
    color: var(--bg);
  }

  /* --- Skill Cards --- */
  .skill-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 24px;
    margin: 16px 0;
    transition: border-color 0.15s;
  }

  .skill-card:target {
    border-color: var(--accent);
    box-shadow: 0 0 0 1px var(--accent);
  }

  .skill-header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 8px;
  }

  .skill-header h3 {
    font-size: 20px;
    color: var(--text);
  }

  .version {
    background: var(--accent-subtle);
    color: var(--accent);
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 12px;
    font-family: monospace;
  }

  .skill-desc {
    color: var(--text-muted);
    font-size: 14px;
    margin-bottom: 12px;
  }

  .skill-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    align-items: center;
    margin-bottom: 12px;
  }

  .tag {
    background: #2ea04333;
    color: var(--green);
    padding: 2px 8px;
    border-radius: 12px;
    font-size: 11px;
  }

  .tools {
    color: var(--text-muted);
    font-size: 11px;
    font-style: italic;
    margin-left: auto;
  }

  details {
    margin-top: 8px;
  }

  summary {
    cursor: pointer;
    color: var(--accent);
    font-size: 13px;
    padding: 4px 0;
    user-select: none;
  }

  summary:hover {
    text-decoration: underline;
  }

  .skill-body {
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 16px;
    margin-top: 12px;
    font-family: 'SF Mono', Monaco, Consolas, monospace;
    font-size: 12px;
    line-height: 1.5;
    overflow-x: auto;
    white-space: pre-wrap;
    word-wrap: break-word;
    color: var(--text-muted);
    max-height: 500px;
    overflow-y: auto;
  }

  /* --- CLI Reference --- */
  .cli-table {
    width: 100%;
    border-collapse: collapse;
    margin: 16px 0;
  }

  .cli-table th, .cli-table td {
    text-align: left;
    padding: 10px 16px;
    border-bottom: 1px solid var(--border);
    font-size: 14px;
  }

  .cli-table th {
    color: var(--text-muted);
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .cli-table td:first-child {
    font-family: monospace;
    color: var(--accent);
    white-space: nowrap;
  }

  /* --- Footer --- */
  .footer {
    margin-top: 64px;
    padding: 24px 0;
    border-top: 1px solid var(--border);
    text-align: center;
    color: var(--text-muted);
    font-size: 13px;
  }

  .footer a {
    color: var(--accent);
    text-decoration: none;
  }

  /* --- Responsive --- */
  @media (max-width: 768px) {
    .layout {
      grid-template-columns: 1fr;
    }
    .sidebar {
      position: static;
      height: auto;
      border-right: none;
      border-bottom: 1px solid var(--border);
    }
    .main {
      padding: 24px;
    }
    .stat-row {
      flex-wrap: wrap;
    }
  }
</style>
</head>
<body>
<div class="layout">
HTML_HEAD

# Write sidebar
cat >> "$OUTPUT_FILE" << HTML_SIDEBAR_START
<nav class="sidebar">
  <h1>Claude Public Skills</h1>
  <p class="subtitle">${skill_count} skills available</p>

  <h2>Navigation</h2>
  <a href="#quickstart" class="nav-link">Quick Start</a>
  <a href="#groups" class="nav-link">Groups</a>
  <a href="#cli" class="nav-link">CLI Reference</a>

  <h2>Skills</h2>
  ${skill_nav}
</nav>
HTML_SIDEBAR_START

# Write main content
cat >> "$OUTPUT_FILE" << HTML_MAIN_START
<main class="main">

<div class="hero">
  <h1>Claude Public Skills</h1>
  <p>A collection of reusable Claude Code skills you can install into any project. Browse, pick what you need, and get started in seconds.</p>
  <div class="stat-row">
    <div class="stat"><div class="num">${skill_count}</div><div class="label">Skills</div></div>
    <div class="stat"><div class="num">3</div><div class="label">Groups</div></div>
    <div class="stat"><div class="num">0</div><div class="label">Dependencies</div></div>
  </div>
</div>

<h2 id="quickstart" class="section-title">Quick Start</h2>

<div class="quickstart">
  <h3>Install skills into your project</h3>
  <code>git clone &lt;repo-url&gt; &amp;&amp; cd claude_public_skills</code>
  <p>Install a single skill globally:</p>
  <code>./skill.sh install changelog --global</code>
  <p>Or link all skills (live updates with git pull):</p>
  <code>./skill.sh link --all --global</code>
</div>

<div class="quickstart">
  <h3>Create a new skill</h3>
  <code>./skill.sh new my-skill-name</code>
  <p>Edit <code>skills/my-skill-name/SKILL.md</code>, then rebuild:</p>
  <code>./skill.sh build-manifest</code>
</div>

<h2 id="groups" class="section-title">Skill Groups</h2>
<div class="groups-grid">
  ${groups_html}
</div>

<h2 class="section-title">All Skills</h2>
${skills_html}

<h2 id="cli" class="section-title">CLI Reference</h2>
<table class="cli-table">
  <tr><th>Command</th><th>Description</th></tr>
  <tr><td>./skill.sh list</td><td>List all skills and groups</td></tr>
  <tr><td>./skill.sh info &lt;skill&gt;</td><td>Show skill details</td></tr>
  <tr><td>./skill.sh install &lt;skill|group&gt; &lt;target&gt;</td><td>Copy skill(s) to target</td></tr>
  <tr><td>./skill.sh link &lt;skill|group&gt; &lt;target&gt;</td><td>Symlink skill(s) to target</td></tr>
  <tr><td>./skill.sh uninstall &lt;skill|group&gt; &lt;target&gt;</td><td>Remove skill(s) from target</td></tr>
  <tr><td>./skill.sh new &lt;name&gt;</td><td>Scaffold a new skill from template</td></tr>
  <tr><td>./skill.sh build-manifest</td><td>Regenerate manifest.json</td></tr>
  <tr><td>./skill.sh validate</td><td>Check manifest and groups are in sync</td></tr>
  <tr><td>./skill.sh init</td><td>Install git pre-commit hook</td></tr>
</table>
<p style="color: var(--text-muted); font-size: 13px; margin-top: 8px;">
  <strong>Targets:</strong> <code>--global</code> / <code>-g</code> (installs to ~/.claude/skills/) or a path<br>
  <strong>Flags:</strong> <code>--force</code> / <code>-f</code> (skip prompts), <code>--all</code> (apply to all skills)
</p>

HTML_MAIN_START

# Write generated timestamp and footer
cat >> "$OUTPUT_FILE" << HTML_FOOTER
<div class="footer">
  Generated on $(date +%Y-%m-%d) &middot;
  <a href="https://github.com">View on GitHub</a> &middot;
  Built with <a href="https://claude.ai/claude-code">Claude Code</a>
</div>

</main>
</div>
</body>
</html>
HTML_FOOTER

echo "Site generated: $OUTPUT_FILE"
echo "Skills documented: $skill_count"
echo ""
echo "To deploy on GitHub Pages:"
echo "  1. Push to GitHub"
echo "  2. Go to Settings > Pages"
echo "  3. Set source to 'Deploy from a branch'"
echo "  4. Set branch to 'master' and folder to '/docs'"
