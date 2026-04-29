---
name: author
description: Write a blog post draft from a validated outline; voice and audience come from project config, frontmatter from the active preset
---

# Author

Write the best version of the essay from the validated outline. Voice, audience, research sources, and output format all come from the project's Prospero configuration; this skill is a process, not a style sheet.

## When to use

- The user has a validated outline at `<drafts_dir>/<slug>/outline.md` (typically after `/interrogate` and, usually, `/critique`) and is ready to draft.

Do NOT use for:

- Producing a new outline from a topic → use `/interrogate`.
- Oppositional review of an outline or draft → use `/critique`.
- Line-level edits on a draft the author has already revised → use `/revise`.

## Preconditions

Run these as a silent preflight. Do not narrate them to the user unless a check fails; a passing preflight should be invisible.

### 1. `.prospero/config.toml` must exist

If `.prospero/config.toml` does NOT exist in the current working directory, invoke the `prospero:init` skill and follow it to completion. When init returns, resume at step 2 below. Do not proceed to drafting with an unconfigured project.

### 2. `.prospero/voice.md` and `.prospero/audience.md` must be filled in

For each of `.prospero/voice.md` and `.prospero/audience.md`, compute byte-for-byte equality against the plugin's corresponding template at `<plugin-root>/templates/voice.md` and `<plugin-root>/templates/audience.md`. Use the plugin-root resolution procedure defined in the `init` skill's "Resolving the plugin's templates directory" section. Do not abbreviate its failure handling: zero matches → ask the user; multiple matches → ask the user; match found but `voice.md` or `audience.md` missing → halt with the resolved path.

- If either user file is **Missing** → halt with: "`.prospero/<file>` is missing. Run `/init` to restore it, then fill it in before `/author`."
- If either user file is **byte-for-byte equal** to its template → halt with: "`.prospero/<file>` is the unmodified scaffold. Fill it in before running `/author`; this is the one thing Prospero cannot write for you."
- Otherwise → the file is user content. Proceed.

### 3. Resolve the preset keys

Load `.prospero/config.toml` to get the preset name. Read the preset file at `<plugin-root>/presets/<preset>.toml` and extract all four of: `drafts_dir`, `post_path_pattern`, `sample_posts_dir`, `frontmatter_template`. Overlay any explicit overrides for these keys set directly in `.prospero/config.toml`. If no preset is named, default to `plain`.

If `config.toml` is unparseable, the named preset file is missing, or any of the four keys above is absent from both the preset and the config, halt with a message naming the specific missing key and suggesting `/init` to reconfigure. Do not silently fall back. The author cannot write a post without knowing where to write it, what frontmatter to use, where to read the outline from, or how to calibrate voice.

### 4. Resolve the slug

The author consumes an existing outline, so the slug must come from the user or the filesystem:

- If the user named a file or slug directly, use it.
- Otherwise, list subdirectories of `<drafts_dir>/`. If exactly one exists, confirm with the author before proceeding. If multiple exist, ask which post to draft.
- If `<drafts_dir>/` is empty or does not exist, halt with: "No drafts found in `<drafts_dir>/`. Run `/interrogate` first."

## Before Writing

1. **Check the date.** Verify today's date so you know what's current. Your training data may be stale; verify before assuming.

2. **Re-read the outline.** Read `<drafts_dir>/<slug>/outline.md` in full. The outline is a spine, not a transcript; you can reorder, merge, split, or restructure sections if the argument flows better. But do not silently drop claims or change the thesis. The thesis, antithesis, and synthesis must survive into the draft.

3. **Read existing research.** If `<drafts_dir>/<slug>/research.md` exists, read it. The critic has already found sources, prior art, and counterarguments. Use them; don't re-fetch what's already there.

4. **Read the audience definition.** Read `.prospero/audience.md` for the target reader description and research sources. The audience definition informs tone calibration, how much background to supply, and what prior art to engage. Hold this context while drafting.

5. **Read the voice guide.** Read `.prospero/voice.md` in full. Follow every rule in it. That file is the canonical voice guide for this project; treat it as a hard contract, not a style suggestion.

6. **Calibrate voice from samples.** Read at least 3 recent posts in the resolved `sample_posts_dir` to internalize rhythm, sentence structure, footnote usage, and section-header style. The voice.md rules and the sample posts together calibrate your output: the rules say what the voice is, the samples show what it sounds like.

7. **Research.** Use the research sources listed in `.prospero/audience.md`'s Research Sources section. Do not invent sources outside that list; if you need broader web search, say so in the post's citations. Verify facts and locate links worth citing. Append any new findings to `<drafts_dir>/<slug>/research.md`. Do not fabricate URLs. If a claim cannot be substantiated, flag it for the author rather than inventing a source.

## Output

Resolve the destination path by substituting `{slug}` (and any other variables) into the preset's `post_path_pattern`. Write the post to that path.

Apply the preset's `frontmatter_template` to the top of the file, substituting `{title}`, `{description}`, `{date}`, `{category}`, and any other variables the template names. Leave `draft: true` in the frontmatter (or the preset's equivalent flag) — the author does not unpublish.

- **Slug:** kebab-cased from the title, matching the `<drafts_dir>/<slug>/` directory the outline came from.
- **Date:** use today's date (verified at step 1 of Before Writing) formatted to match what existing posts in `sample_posts_dir` use — read a sample to confirm the format before writing.
- **Category:** if `category` is a variable in the frontmatter template, look at existing posts in `sample_posts_dir` to infer the project's category vocabulary. Use an existing category if one fits; propose a new one only if none do.
- **Image and other optional fields:** leave blank unless the author has provided values.

## Formatting

- `##` for major sections, `###` for subsections.
- Section headers signal the argument's movement, not just topic.
- Footnotes via `[^n]` for asides that would break the flow.
- Images as `![alt](filename)`, co-located in the post directory alongside `index.md` (or the equivalent file name the preset writes to).
- Block quotes for extended quotations.
- Code blocks with language tags.

## Writing Discipline

- Every section should earn its place. If a section does not advance the thesis, cut it.
- Transitions between sections should be logical, not merely sequential ("Next, let's look at...").
- The opening must hook within two sentences. Start with the concrete, not the abstract.
- The closing should land the argument with force; do not trail off into vague gestures at the future.

## Voice

Read `.prospero/voice.md` in full. Follow every rule in it. That file is the canonical voice guide for this project; treat it as a hard contract, not a style suggestion. Do not substitute your own aesthetic judgment for the rules it lays out, and do not soften its prohibitions because a given sentence reads more naturally the prohibited way.

## Handoff

After the draft is written, tell the author it's ready for their editing pass. When they come back with feedback, invoke `/revise`.
