# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

Prospero is a Claude Code **plugin** (not an application). There is no build step, runtime, or package manager. The "code" is markdown and TOML: command shims, skill prompts, CMS presets, and rubric templates. Claude Code loads everything at runtime from the plugin root.

Plugin manifest: `.claude-plugin/plugin.json`. Marketplace entry: `.claude-plugin/marketplace.json`.

## Commands

The only automated check is a static lint:

```bash
./tests/validate.sh
```

It verifies the manifest parses, the required skills/commands/presets/templates exist, each preset has its required keys (`posts_dir`, `post_path_pattern`, `drafts_dir`, `frontmatter_template`), and every `SKILL.md` has `name:` and `description:` frontmatter. Run it after any structural change.

There is no test runner for skill behavior — skills are LLM prompts, not code. `tests/fixtures/hugo/{before,after}/` shows the expected filesystem state around `/init`; `examples/sample-post/` shows per-phase artifacts for a single post.

## Architecture

### The four-phase pipeline

`interrogate → critique → author → revise`. Each phase is one skill that does one job and produces one artifact; phases communicate via files on disk, not conversation state. The `prospero` skill is a **router** that picks a phase from user intent; it does not chain phases or duplicate their preflight checks. Each phase decides its own handoff (e.g., `/interrogate` auto-invokes `/critique`; `/critique` does NOT auto-invoke `/author` — the author must accept the critique first).

Cross-phase state is files, keyed by slug:
- Outline: `<drafts_dir>/<slug>/outline.md` — written by interrogate, read by critique/author.
- Research: `<drafts_dir>/<slug>/research.md` — the accumulating research record for the post. Interrogate initializes it, critique extends it (and consumes it before doing new web calls — research is not re-derived), author expands it while grounding the draft. Every writer appends under a `YYYY-MM-DDTHH:MM` section header (local time, to the minute) so multiple same-day passes do not collide. Never overwritten.
- Post: resolved `post_path_pattern` — written by author, edited by revise.

The research file is the pipeline's only durable memory of what has been looked up. When modifying a phase skill, preserve the "read first, extend only the gaps" contract — the critic in particular is cheap to tempt into re-running web searches, and that's exactly what the research file exists to prevent.

### Commands are thin shims for skills

Every file in `commands/` is a few lines that invoke the matching skill. All carry `disable-model-invocation: true` so the user must type `/<command>` explicitly — skills are *not* auto-routed by name matching. When adding a new phase, create both `commands/<name>.md` and `skills/<name>/SKILL.md`; `validate.sh` enforces the pairing for the known phases.

### Project-local config vs. plugin-shipped content

The line between **user-owned** and **plugin-owned** files is load-bearing and the source of most of the skill logic's complexity.

- **User-owned** (in the user's blog project, at `.prospero/`): `config.toml`, `voice.md`, `audience.md`, and anything under `.prospero/types/`. Skills **must never** overwrite these silently.
- **Plugin-owned** (here): everything in `presets/`, `templates/`, and `templates/types/`. These are read-only at runtime.

Phase skills distinguish an unfilled scaffold from user content using **byte-for-byte equality** against the plugin template (`templates/voice.md`, `templates/audience.md`). Any difference — even a trailing newline — means user content. This rule is stated in `skills/init/SKILL.md` and referenced by every other phase's preflight; do not loosen it to fuzzy matching.

### Resolving the plugin root at runtime

Skills that need to read plugin-shipped files (templates, presets) resolve the plugin root with this procedure, defined canonically in `skills/init/SKILL.md` under "Resolving the plugin's templates directory":

1. Use `$CLAUDE_PLUGIN_ROOT` if set.
2. Otherwise, `Glob` for `**/prospero/templates/voice.md` under `~/.claude/plugins/`. Exactly one match → plugin root is the parent of that `templates/`. Zero or multiple matches → ask the user.

Every phase skill must use this procedure verbatim (including the "ask the user" failure modes). Do not inline a shortened variant.

### Presets

Presets in `presets/<name>.toml` define CMS-specific paths and frontmatter. Required keys: `posts_dir`, `post_path_pattern`, `drafts_dir`, `frontmatter_template`. Optional: `sample_posts_dir`. A user can override any single key in their `.prospero/config.toml`; the config names one preset and then overlays specific keys. `hugo` is the reference implementation; `plain` is the default fallback when no preset is named or resolution fails.

When adding a preset, also update `validate.sh`'s required-presets list if the new preset is a required check.

### Piece types

`templates/types/{argued-essay,opinion-polemic,explainer}.md` are rubrics the critic loads in outline mode. Users can override a bundled type with a project-local `.prospero/types/<type>.md`. When adding a new type, its filename (minus `.md`) is the type key used in `/critique`'s first question; `templates/types/.gitkeep` exists so the directory ships even if empty.

### Skill-writing conventions

- Every phase skill runs its **preconditions as a silent preflight** — only surface them if a check fails.
- When a precondition fails because the project is unconfigured, the skill **auto-invokes `prospero:init`** and resumes after it returns. The router skill (`prospero`) does not do this itself.
- The critic in `/critique` is **independent by construction**: it spawns a separate agent via the Agent tool with only file paths in its prompt, never the conversation history. Preserve this isolation when modifying the skill.
- Skills never rewrite `.prospero/voice.md` or `.prospero/audience.md`. Those files are the one thing Prospero cannot write for the user.

## Repository layout

```
.claude-plugin/         # plugin + marketplace manifests
commands/               # slash-command shims, one per skill
skills/<name>/SKILL.md  # phase skills + prospero router + init
presets/*.toml          # CMS presets (hugo, plain, jekyll, ghost)
templates/
  voice.md              # voice scaffold copied into user projects
  audience.md           # audience scaffold copied into user projects
  types/*.md            # piece-type rubrics for the critic
examples/sample-post/   # artifacts produced at each phase for a single post
tests/
  validate.sh           # static lint
  fixtures/hugo/        # before/after snapshots for /init on a bare Hugo project
```
