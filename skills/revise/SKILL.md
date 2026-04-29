---
name: revise
description: Structural and line-level feedback on a draft the author has edited; enforces voice.md rules and can optionally re-run /critique in draft mode
---

# Revise

The author has made an editing pass on a draft and wants feedback before publishing. Revise reads the current draft and returns specific, actionable suggestions — structural where the argument needs it, line-level where the prose does. Revise is collaborative editorial feedback; it is not the adversarial review that `/critique` in draft mode provides.

## When to use

- The user has a draft at the resolved `post_path_pattern` (typically written by `/author`) and has made their own editing pass, and wants feedback on the current state.
- The user wants a line-level polish pass before publishing.

Do NOT use for:

- Producing a new outline from a topic → use `/interrogate`.
- Oppositional review before drafting → use `/critique` in outline mode.
- Independent adversarial evaluation of the draft against its outline → use `/critique` in draft mode (which revise can offer to invoke; see below).
- Writing the first draft → use `/author`.

## Preconditions

Run these as a silent preflight. Do not narrate them to the user unless a check fails; a passing preflight should be invisible.

### 1. `.prospero/config.toml` must exist

If `.prospero/config.toml` does NOT exist in the current working directory, invoke the `prospero:init` skill and follow it to completion. When init returns, resume at step 2 below. Do not proceed to revision with an unconfigured project.

### 2. `.prospero/voice.md` and `.prospero/audience.md` must be filled in

For each of `.prospero/voice.md` and `.prospero/audience.md`, compute byte-for-byte equality against the plugin's corresponding template at `<plugin-root>/templates/voice.md` and `<plugin-root>/templates/audience.md`. Use the plugin-root resolution procedure defined in the `init` skill's "Resolving the plugin's templates directory" section. Do not abbreviate its failure handling: zero matches → ask the user; multiple matches → ask the user; match found but `voice.md` or `audience.md` missing → halt with the resolved path.

- If either user file is **Missing** → halt with: "`.prospero/<file>` is missing. Run `/init` to restore it, then fill it in before `/revise`."
- If either user file is **byte-for-byte equal** to its template → halt with: "`.prospero/<file>` is the unmodified scaffold. Fill it in before running `/revise`; this is the one thing Prospero cannot write for you."
- Otherwise → the file is user content. Proceed.

Additionally, check that `.prospero/voice.md` is substantive, not a one-liner. If voice.md is shorter than ~500 characters or contains fewer than three concrete rules (prohibitions, structural conventions, tonal directives), halt with: "`.prospero/voice.md` is too sparse to flag voice violations reliably. The skill needs concrete rules to enforce — otherwise it will improvise. Expand voice.md with at least three rules (tone / structure / prohibitions), then re-run `/revise`."

### 3. Resolve the preset keys

Load `.prospero/config.toml` to get the preset name. Read the preset file at `<plugin-root>/presets/<preset>.toml` and extract both `drafts_dir` (where the outline and research live, for optional context) and `post_path_pattern` (where the draft itself lives). Overlay any explicit overrides for these keys set directly in `.prospero/config.toml`. If no preset is named, default to `plain`.

If `config.toml` is unparseable, the named preset file is missing, or either of the two keys above is absent from both the preset and the config, halt with a message naming the specific missing key and suggesting `/init` to reconfigure. Do not silently fall back.

### 4. Resolve the slug and confirm the draft exists

Revise consumes an existing draft, so the slug must come from the user or the filesystem:

- If the user named a file or slug directly, use it.
- Otherwise, list subdirectories of `<drafts_dir>/`. If exactly one exists, confirm with the author before proceeding. If multiple exist, ask which post to revise.
- If `<drafts_dir>/` is empty or does not exist, halt with: "No drafts found in `<drafts_dir>/`. Run `/interrogate` first."

Once the slug is determined, substitute it into `post_path_pattern` to resolve the draft path. If that file does not exist, halt with: "No draft at `<resolved post path>`. Run `/author` to write one before `/revise`."

## Process

Read the draft in full before commenting on any part of it. Then assess whether the draft's primary need is structural or line-level and weight your feedback accordingly.

1. **Structural assessment** — argument ordering, cuts, thesis clarity, whether sections earn their place, whether the antithesis is genuinely engaged, whether the opening earns attention, whether the close lands with force. If the outline still exists at `<drafts_dir>/<slug>/outline.md`, use it as a reference for what the draft promised to deliver — but do not re-critique the outline's soundness; that is `/critique`'s job.

2. **Line-level assessment** — tightening sentences, fixing awkward phrasing, improving transitions, catching voice violations, trimming throat-clearing.

3. **Weight feedback toward whichever the draft needs more.** If the structure is off, do not bury that under a pile of comma suggestions. If the structure is solid, concentrate on the prose.

4. **Be specific and actionable.** Provide line references and concrete edits. Do not rewrite the whole post. "Cut the first two sentences of section 3; they restate the thesis without advancing it" is useful. "Consider strengthening section 3" is not.

5. **Multiple rounds are fine.** The author may come back with another edit for another pass. Do not try to catch everything in one round.

## Voice enforcement

Refer to `.prospero/voice.md` for this project's voice rules. Flag violations of its rules; don't import rules from elsewhere. If a construction the author used is not prohibited by voice.md but strikes you as awkward, flag it as a line-level suggestion rather than a voice violation — that distinction matters. Voice.md is a hard contract; your aesthetic taste is advisory.

## Optional: Draft-mode critic

If the author asks for a formal review, or if you believe the draft has significant structural issues that warrant independent adversarial evaluation, offer to invoke `/critique` in draft mode. That skill spawns a separate agent that evaluates the draft against its outline without the context of your feedback — useful precisely because it is blind to your suggestions. Do not invoke `/critique` silently; offer, and let the author decide.

## Handoff

Return feedback to the author and stop. Do not auto-invoke any other skill. The author decides what to do with the feedback — apply it, dismiss it, come back for another round, or escalate to `/critique` in draft mode.
