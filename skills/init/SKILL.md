---
name: init
description: Scaffold .prospero/ in the current project. Detect the host CMS, propose a preset, and copy the voice and audience templates. Auto-invoked by /interrogate on first use; also callable directly for reconfiguration.
---

# Init

Set up Prospero in the current project. Idempotent: safe to re-run for reconfiguration. Never overwrites user-modified content in `.prospero/voice.md` or `.prospero/audience.md`. A file whose contents are byte-identical to the plugin's template is treated as an unfilled scaffold and is safe to recopy.

## When to use

- **Auto-invoked** by `/interrogate` (and any other phase skill) when `.prospero/config.toml` is absent.
- **Invoked directly** via `/init` when the user wants to change the preset or recopy a missing template file.

Do not invoke any other phase skill from here. Scaffold, confirm, report. Then return control.

## Process

You MUST complete each step in order. Do not write any files before the user has confirmed at step 4.

### 1. Scan for CMS markers

Look in the current working directory (the project root) for the files below. Read each candidate file — do not decide by filename alone.

- `hugo.toml`, `hugo.yaml`, `hugo.json` → Hugo. Also check for a top-level `config.toml`/`config.yaml` that contains Hugo-specific keys (`baseURL`, `theme`, `[params]`, `[markup]`).
- `_config.yml` with Jekyll markers (`collections:`, `permalink:`, `plugins:` referencing `jekyll-*`, or a `_posts/` directory nearby) → Jekyll.
- `package.json` whose `dependencies` or `devDependencies` include `ghost`, `@tryghost/*`, or a Ghost-specific build tool → Ghost.
- None of the above, or ambiguous markers → plain.

Also note whether the implied content directory exists (`content/post/` for Hugo, `_posts/` for Jekyll, etc.). A matching config **plus** a matching content directory is strong evidence. A config alone with no content directory is still enough to propose the preset, but mention the missing directory in the proposal so the user can correct course.

If two CMS markers appear to be present (e.g., a Hugo `hugo.toml` and a Jekyll `_config.yml`), do not guess. Ask the user which is canonical.

### 2. Inspect existing `.prospero/` files

Before proposing anything, classify the state of each target path so the proposal at step 3 can be accurate. For each of `.prospero/config.toml`, `.prospero/voice.md`, `.prospero/audience.md`, classify as one of:

- **Missing** — the file does not exist.
- **Unchanged scaffold** — the file exists and its contents are **byte-for-byte equal** to the plugin's corresponding template.
- **User content** — the file exists and its contents differ from the template (even by a single added newline or trailing space).

**Fingerprint algorithm (MUST be byte-for-byte):**

Compute byte-for-byte equality between the existing file and the plugin's template at `<plugin-root>/templates/voice.md` (for `.prospero/voice.md`) and `<plugin-root>/templates/audience.md` (for `.prospero/audience.md`). Equal → unchanged scaffold, safe to recopy. Not equal, even a single added newline or differing byte → user content, must not be overwritten without explicit permission.

`.prospero/config.toml` has no template to compare against; classify it as **Missing** or **Exists** only. For the **Exists** case, compute a unified diff between the current file and the config you intend to write so you can show it at step 3.

Record the classification for each file. Step 3's proposal depends on it.

### 3. Propose

Read the preset file at `<plugin-root>/presets/<cms>.toml` so the proposal is concrete. Show the user, in order:

- The preset name you chose and the signal that led to it (e.g., "I see `hugo.toml` with a `baseURL` key").
- The resolved **post path pattern** from the preset's `post_path_pattern`, with `{slug}` left literal (e.g., `content/post/{slug}/index.md`).
- The resolved **drafts directory** (`drafts_dir`).
- The **sample posts directory** (`sample_posts_dir`) that the author skill will read for voice calibration, and whether it currently exists.

Then enumerate the **actions** you will take, one per target file, based on step 2's classifications:

- For each file classified **Missing** → "Create `.prospero/<file>`."
- For each file classified **Unchanged scaffold** → "Recopy `.prospero/<file>` from the plugin template (current file is the unmodified scaffold)."
- For each file classified **User content** → "Skip `.prospero/<file>` (contains your edits; will not be overwritten)."
- For `.prospero/config.toml` classified **Exists** → "Replace `.prospero/config.toml`. Diff:" followed by the unified diff computed in step 2.
- For `.prospero/config.toml` classified **Missing** → "Create `.prospero/config.toml` with:" followed by the exact content.

Ask one question at the end of the proposal: "Accept this plan, change the preset, override specific fields, or abort?"

### 4. Confirmation gate

Before writing anything, the user must explicitly consent to the proposal from step 3. If the user says anything other than a clear affirmative, treat it as a request for changes: revise the proposal and re-show step 3's output. Do not proceed to step 5 without explicit consent.

### 5. Write the scaffold per the confirmed plan

Create `.prospero/` if it does not exist, then execute exactly the actions the user approved at step 4. No deviation.

**`.prospero/config.toml`** — minimal, one line:

```toml
preset = "<chosen preset name>"
```

Add explicit override keys only if the user asked for them at step 3. Do not copy the preset's contents into the config; the preset is read from the plugin at runtime.

**`.prospero/voice.md`** — copy byte-for-byte from the plugin's `templates/voice.md`.

**`.prospero/audience.md`** — copy byte-for-byte from the plugin's `templates/audience.md`.

**Fresh-copy requests on user content.** If the user explicitly asked at step 3 for a fresh copy of a template file that step 2 classified as **User content**, do NOT delete the existing file. Rename it to a `.bak` sibling first, then write the fresh template. Collision handling for `.bak`:

1. Try `<name>.bak` (e.g., `voice.md.bak`).
2. If that path already exists, try `<name>.bak.2`.
3. If that exists too, increment: `<name>.bak.3`, `<name>.bak.4`, and so on, until you find an unused name.

Do not overwrite an existing `.bak` file, and do not append a timestamp. Tell the user the exact backup filename you used.

### 6. Report and hand off

Tell the user what was written, what was skipped, and any backups created. Exact closing message template (omit sections that do not apply):

> Setup complete.
>
> Written:
> - `.prospero/config.toml` (preset = <name>)
> - `.prospero/voice.md`
> - `.prospero/audience.md`
>
> Skipped (already populated):
> - `.prospero/<file>` — contains your edits
>
> Backed up:
> - `.prospero/<file>` → `.prospero/<file>.bak[.N]`
>
> Before running `/interrogate`, fill in `.prospero/voice.md` and `.prospero/audience.md`. These are the one thing Prospero cannot write for you.

After the report, control returns to the invoking context — the user if `/init` was invoked directly, or the `/interrogate` skill if init was auto-invoked. Do not continue into another skill yourself.

## Resolving the plugin's templates directory

The plugin ships `templates/` inside its installed directory. Resolve it like this, in order:

1. If the `CLAUDE_PLUGIN_ROOT` environment variable is set, use `$CLAUDE_PLUGIN_ROOT` as the plugin root. Templates live at `$CLAUDE_PLUGIN_ROOT/templates/`.
2. Otherwise, use `Glob` with the pattern `**/prospero/templates/voice.md` rooted at `~/.claude/plugins/`. If there is exactly one match, the plugin root is the parent of the matched `templates/` directory. If there are zero or multiple matches, ask the user for the plugin root path; do not guess.

Verify the resolved path contains both `voice.md` and `audience.md` by `Read`-ing each. If either is missing, halt with a clear message reporting the path you tried and asking the user to supply the correct plugin root.

## Files that must never be overwritten silently

Once they exist in `.prospero/` with user content (see step 2's fingerprint algorithm), the following are user-authored and belong to the project, not the plugin:

- `voice.md`
- `audience.md`
- Anything under `.prospero/types/` (user-provided piece-type overrides).

Handling for these is specified in steps 2, 3, and 5. Do not act on them outside that process.

## Anti-patterns

- Writing files before the user confirms at step 4.
- Using regex or filename-only heuristics to detect the CMS. Read the files.
- Overwriting user-modified content in `voice.md` or `audience.md` without explicit permission. (Byte-identical-to-template files are unfilled scaffolds, not user-modified content, and may be recopied.)
- Fuzzy-matching the fingerprint check. The comparison is byte-for-byte; whitespace differences count.
- Invoking `/interrogate` or any other phase skill from here. Init scaffolds and stops.
- Copying the preset's contents into `.prospero/config.toml`. The config references the preset by name.
- Deleting a user-content file during a fresh-copy request. Rename to `.bak[.N]` first.
