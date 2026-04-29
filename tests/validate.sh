#!/usr/bin/env bash
# Static lint for the Prospero plugin. Returns 0 on success, non-zero on failure.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $1" >&2; exit 1; }

# Plugin manifest present and parseable
[[ -f .claude-plugin/plugin.json ]] || fail "missing .claude-plugin/plugin.json"
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))" || fail "plugin.json not valid JSON"

# Required skills exist
for skill in prospero init interrogate critique author revise; do
  [[ -f "skills/$skill/SKILL.md" ]] || fail "missing skills/$skill/SKILL.md"
done

# Required commands exist
for cmd in init interrogate critique author revise; do
  [[ -f "commands/$cmd.md" ]] || fail "missing commands/$cmd.md"
done

# Required presets exist with required keys
for preset in plain hugo; do
  path="presets/$preset.toml"
  [[ -f "$path" ]] || fail "missing $path"
  for key in posts_dir post_path_pattern drafts_dir frontmatter_template; do
    grep -q "^$key" "$path" || fail "$path missing key: $key"
  done
done

# Required templates
[[ -f templates/voice.md ]] || fail "missing templates/voice.md"
[[ -f templates/audience.md ]] || fail "missing templates/audience.md"
for type in argued-essay opinion-polemic explainer; do
  [[ -f "templates/types/$type.md" ]] || fail "missing templates/types/$type.md"
done

# Every SKILL.md has required frontmatter
for skill_file in skills/*/SKILL.md; do
  head -5 "$skill_file" | grep -q "^name:" || fail "$skill_file missing 'name:' frontmatter"
  head -5 "$skill_file" | grep -q "^description:" || fail "$skill_file missing 'description:' frontmatter"
done

echo "OK"
