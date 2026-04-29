---
name: init
description: Scaffold .prospero/ in the current project. Detect the host CMS, propose a preset, and copy the voice and audience templates. Auto-invoked by /interrogate on first use; also callable directly for reconfiguration.
---

# Init

Set up Prospero in the current project. Idempotent: safe to re-run for reconfiguration. Never overwrites a populated `.prospero/voice.md` or `.prospero/audience.md`.

## When to use

- **Auto-invoked** by `/interrogate` (and any other phase skill) when `.prospero/config.toml` is absent.
- **Invoked directly** via `/init` when the user wants to change the preset or recopy a missing template file.

Do not invoke any other phase skill from here. Scaffold, confirm, report. Then return control.

## Process

You MUST complete each step in order. Do not write any files before the user has confirmed at step 3.

### 1. Scan for CMS markers

Look in the current working directory (the project root) for the files below. Read each candidate file — do not decide by filename alone.

- `hugo.toml`, `hugo.yaml`, `hugo.json` → Hugo. Also check for a top-level `config.toml`/`config.yaml` that contains Hugo-specific keys (`baseURL`, `theme`, `[params]`, `[markup]`).
- `_config.yml` with Jekyll markers (`collections:`, `permalink:`, `plugins:` referencing `jekyll-*`, or a `_posts/` directory nearby) → Jekyll.
- `package.json` whose `dependencies` or `devDependencies` include `ghost`, `@tryghost/*`, or a Ghost-specific build tool → Ghost.
- None of the above, or ambiguous markers → plain.

Also note whether the implied content directory exists (`content/post/` for Hugo, `_posts/` for Jekyll, etc.). A matching config **plus** a matching content directory is strong evidence. A config alone with no content directory is still enough to propose the preset, but mention the missing directory in the proposal so the user can correct course.

If two CMS markers appear to be present (e.g., a Hugo `hugo.toml` and a Jekyll `_config.yml`), do not guess. Ask the user which is canonical.

### 2. Propose a preset

Read the preset file at `<plugin-root>/presets/<cms>.toml` so the proposal is concrete. Show the user:

- The preset name you chose and the signal that led to it (e.g., "I see `hugo.toml` with a `baseURL` key").
- The resolved **post path pattern** from the preset's `post_path_pattern`, with `{slug}` left literal so they can see the shape (e.g., `content/post/{slug}/index.md`).
- The resolved **drafts directory** (`drafts_dir`).
- The **sample posts directory** (`sample_posts_dir`) that the author skill will read for voice calibration, and whether it currently exists.

Then ask one question: "Accept this preset, pick a different one (plain/hugo/jekyll/ghost), or override specific fields?"

### 3. Confirmation gate

Before writing anything, show the user the full list of files you intend to create and wait for explicit consent.

Template:

> I will create:
> - `.prospero/config.toml` with `preset = "<name>"` [and any overrides the user asked for]
> - `.prospero/voice.md` (copied from the plugin template)
> - `.prospero/audience.md` (copied from the plugin template)
>
> Proceed? (yes/no)

Only proceed after an affirmative answer. If the user says no or asks for changes, revise and re-show the plan.

### 4. Check for existing files (idempotency)

Before writing, inspect `.prospero/` if it exists. For each target path, classify it:

- **Missing** → write it.
- **Exists but empty or contains only the unchanged template content** → overwrite (it's a scaffold the user never filled in).
- **Exists with user content** → do NOT overwrite. Add it to a skip list reported at the end.

The files that MUST be treated as user-authored once they exist:

- `.prospero/voice.md`
- `.prospero/audience.md`

`.prospero/config.toml` may be regenerated when the user is running `/init` explicitly for reconfiguration, but only after showing the diff and asking for confirmation.

### 5. Write the scaffold

Create `.prospero/` if it does not exist, then write the files that survived the idempotency check.

**`.prospero/config.toml`** — minimal, one line:

```toml
preset = "<chosen preset name>"
```

Add explicit override keys only if the user asked for them at step 2. Do not copy the preset's contents into the config; the preset is read from the plugin at runtime.

**`.prospero/voice.md`** — copy byte-for-byte from the plugin's `templates/voice.md`.

**`.prospero/audience.md`** — copy byte-for-byte from the plugin's `templates/audience.md`.

### 6. Report and hand off

Tell the user what was written and what was skipped. Exact closing message:

> Setup complete.
>
> Written:
> - `.prospero/config.toml` (preset = <name>)
> - `.prospero/voice.md`
> - `.prospero/audience.md`
>
> [If files were skipped, list them under "Skipped (already populated)".]
>
> Before running `/interrogate`, fill in `.prospero/voice.md` and `.prospero/audience.md`. These are the one thing Prospero cannot write for you.

After the report, control returns to the invoking context — the user if `/init` was invoked directly, or the `/interrogate` skill if init was auto-invoked. Do not continue into another skill yourself.

## Resolving the plugin's templates directory

The plugin ships `templates/` inside its installed directory. Resolve it like this, in order:

1. If the `CLAUDE_PLUGIN_ROOT` environment variable is set, use `$CLAUDE_PLUGIN_ROOT/templates/`.
2. Otherwise, resolve relative to this SKILL.md's own path: the plugin root is two levels up (`skills/init/SKILL.md` → plugin root). Use `<plugin-root>/templates/`.

Verify the resolved path contains `voice.md` and `audience.md` before trying to copy. If it does not, halt with a message reporting the path you tried; do not guess at another location.

## Files that must never be overwritten silently

Once they exist in `.prospero/`, the following are user-authored and belong to the project, not the plugin:

- `voice.md`
- `audience.md`
- Anything under `.prospero/types/` (user-provided piece-type overrides).

If the user asked for a fresh copy of a template, rename the existing file (`voice.md.bak`) rather than deleting it, and tell them you did.

## Anti-patterns

- Writing files before the confirmation gate.
- Using regex or filename-only heuristics to detect the CMS. Read the files.
- Overwriting a populated `voice.md` or `audience.md` without explicit permission.
- Invoking `/interrogate` or any other phase skill from here. Init scaffolds and stops.
- Copying the preset's contents into `.prospero/config.toml`. The config references the preset by name.
