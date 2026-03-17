# Future Plans

## CLI Enhancements

### `upgrade` command
Compare installed skill versions against source and update stale copies.
```
./skill.sh upgrade <skill|group|--all> <target>
```
- Read `.skill-source` marker to find installed version
- Compare against current version in `skills/*/SKILL.md`
- Copy new version if outdated, preserve `.skill-source` with updated version
- Show diff summary of what changed

### `list` filtering
Filter skills by tag or group instead of showing everything.
```
./skill.sh list --tag meta
./skill.sh list --group dev-tools
./skill.sh list --tag quality --tag meta   # intersection
```

### Remote installation
Install skills from a GitHub URL without cloning the whole repo.
```
./skill.sh install-remote <github-url> <skill-name> <target>
```
- Fetch `manifest.json` from the remote repo
- Download individual skill directories
- Write `.skill-source` with remote URL for tracking

## Content

### Add more skills
- Port useful generic skills from other projects
- Look for common Claude Code workflows worth codifying (testing, deployment, migrations, etc.)

### Skill quality pass
- Run `/skill-audit` on all skills and fix structural gaps
- Run `/cross-skill-patterns` to find redundancy and asymmetries
- Add worked examples to skills that lack them

## Infrastructure

### GitHub Pages deployment
- Push to GitHub
- Enable Pages from `docs/` folder on `master` branch
- Add repo URL to `generate-site.sh` footer

### CI/CD
- GitHub Action to run `bash tests/test_skill.sh` on PRs
- Auto-regenerate site on push to `master`
- Validate manifest is up to date in CI

### Skill testing framework
- Way to test skills beyond structural audit
- Invoke skills in a sandbox and check output
- Track skill usage metrics across projects
