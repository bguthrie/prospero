---
name: critique
description: Oppositional review of an outline or draft by an independent agent; loads piece-type rubric and audience context from project config
---

# Critique

Stress-test an outline or draft before it moves forward. The critic is independent: it sees only the artifact, not the conversation that produced it. That independence is deliberate; the critic should not know why the author made the choices they did, only what they chose.

## When to use

- The user has an outline at `<drafts_dir>/<slug>/outline.md` and wants oppositional review before drafting.
- The user has a draft at `<posts_dir>/<slug>/index.md` and wants it reviewed against its outline before revising.

Do NOT use for:

- Producing a new outline from a topic → use `/interrogate`.
- Writing the draft itself → use `/author`.
- Line-level edits on a draft without adversarial review → use `/revise`.

## Preconditions

Run these as a silent preflight. Do not narrate them to the user unless a check fails; a passing preflight should be invisible.

### 1. `.prospero/config.toml` must exist

If `.prospero/config.toml` does NOT exist in the current working directory, invoke the `prospero:init` skill and follow it to completion. When init returns, resume at step 2 below. Do not proceed to critique with an unconfigured project.

### 2. `.prospero/voice.md` and `.prospero/audience.md` must be filled in

For each of `.prospero/voice.md` and `.prospero/audience.md`, compute byte-for-byte equality against the plugin's corresponding template at `<plugin-root>/templates/voice.md` and `<plugin-root>/templates/audience.md`. Use the plugin-root resolution procedure defined in the `init` skill's "Resolving the plugin's templates directory" section. Do not abbreviate its failure handling: zero matches → ask the user; multiple matches → ask the user; match found but `voice.md` or `audience.md` missing → halt with the resolved path.

- If either user file is **Missing** → halt with: "`.prospero/<file>` is missing. Run `/init` to restore it, then fill it in before `/critique`."
- If either user file is **byte-for-byte equal** to its template → halt with: "`.prospero/<file>` is the unmodified scaffold. Fill it in before running `/critique`; this is the one thing Prospero cannot write for you."
- Otherwise → the file is user content. Proceed.

### 3. Resolve the drafts directory and post path pattern

Load `.prospero/config.toml` to get the preset name. Read the preset file at `<plugin-root>/presets/<preset>.toml` and extract both `drafts_dir` and `post_path_pattern`. Overlay any explicit `drafts_dir` or `post_path_pattern` keys set directly in `.prospero/config.toml`. If no preset is named, default to `plain`. The resolved `drafts_dir` (typically `drafts` or `_drafts`) is where the outline and research file live; `post_path_pattern` (e.g., `content/post/{slug}/index.md`) is where the draft lives once `/author` has written it.

If `config.toml` is unparseable, the named preset file is missing, or the resolved preset lacks either field, halt with a message naming the specific failure and suggesting `/init` to reconfigure. Do not silently fall back.

## Resolve the slug

Critique consumes an existing artifact, so the slug must come from the user or the filesystem:

- If the user named a file or slug directly, use it.
- Otherwise, list subdirectories of `<drafts_dir>/`. If exactly one exists, confirm with the author before proceeding. If multiple exist, ask which post to critique.
- If `<drafts_dir>/` is empty or does not exist, halt with: "No drafts found in `<drafts_dir>/`. Run `/interrogate` first."

## Mode determination

Decide which mode to run based on the artifact the author has on hand:

- **Outline mode** — the outline exists at `<drafts_dir>/<slug>/outline.md` and no draft has been written yet. This is the common post-interrogation path.
- **Draft mode** — the draft exists at the resolved `post_path_pattern` (with `{slug}` filled in). This is the post-author review path.

If the user named a specific file, use that file to disambiguate. If both artifacts exist and the user did not specify, ask which one to review. Do not review both in a single invocation.

If neither artifact exists for the resolved slug, halt with: "No outline or draft found at `<drafts_dir>/<slug>/outline.md` or the resolved post path. Run `/interrogate` to produce an outline first."

## Process — outline mode

First, determine the piece type. If the outline explicitly names one, use that; otherwise ask the user whether the piece is an **argued essay**, **opinion / polemic**, or **explainer** — the three rubrics bundled with the plugin. (The bundled outline template does not record the piece type, so asking will be the common path.)

Load the matching rubric from `<plugin-root>/templates/types/<type>.md`, where `<type>` is one of `argued-essay`, `opinion-polemic`, `explainer`. User overrides may live at `.prospero/types/<type>.md`; if such a file exists, prefer it over the bundled plugin template.

Then spawn a separate agent using the Agent tool. Pass it ONLY:

- The outline path: `<drafts_dir>/<slug>/outline.md`.
- The rubric path you resolved above.
- The audience file path: `.prospero/audience.md`.
- The research file path if it exists: `<drafts_dir>/<slug>/research.md`.

Do NOT pass the conversation history. Give the agent this prompt body (substitute the paths):

> You are an oppositional critic reviewing an outline. Your job is to find weaknesses, not to be helpful. Be direct and specific, like a code review.
>
> **First:** Check today's date so you know what's current. Your training data may be stale; verify before assuming.
>
> Read the following files in order:
>
> 1. The outline at `{outline_path}`.
> 2. The rubric at `{rubric_path}` — evaluate against the criteria it defines.
> 3. The audience context at `.prospero/audience.md`. The target reader is defined there; do not flag missing explanations for concepts that audience already knows. The Research Sources section lists where to verify claims and survey prior art.
> 4. If a research file exists at `{research_path}`, read it first so you don't duplicate work.
>
> Use the research sources listed in `.prospero/audience.md`'s Research Sources section, then broader web as needed. Search for prior art, contradicting evidence, and strong opposing voices. Do not invent sources not listed there. If the audience file has no Research Sources section, fall back to broader web search and note the absence at the top of your critique.
>
> Output a structured critique following the rubric's criteria. Be specific: "Section 3 claims X but provides no evidence" not "consider strengthening Section 3." End with a summary judgment: ready to draft, needs revision, or needs rethinking.
>
> Write your research findings (sources found, key quotes, URLs) to `{research_path}`. If the file exists, append under a dated section header like `## Critique session YYYY-MM-DD`; do not overwrite existing content. Create the file if missing.

## Process — draft mode

No rubric file is loaded in draft mode; the criteria below are the rubric. Spawn a separate agent using the Agent tool. Pass it ONLY:

- The draft path, resolved from `post_path_pattern` with `{slug}` filled in.
- The outline path: `<drafts_dir>/<slug>/outline.md`.
- The audience file path: `.prospero/audience.md`.
- The research file path if it exists: `<drafts_dir>/<slug>/research.md`.

Do NOT pass the conversation history. Give the agent this prompt body:

> You are an oppositional critic reviewing a draft against its outline. Your job is to find where the execution failed the argument.
>
> **First:** Check today's date so you know what's current. Your training data may be stale; verify before assuming.
>
> Read the following files in order:
>
> 1. The outline at `{outline_path}`.
> 2. The draft at `{draft_path}`.
> 3. The audience context at `.prospero/audience.md`. The target reader is defined there; do not flag missing explanations for concepts that audience already knows. The Research Sources section lists where to verify claims.
> 4. If a research file exists at `{research_path}`, read it to see what sources have already been found and check whether the draft actually uses them.
>
> Use the research sources listed in `.prospero/audience.md`'s Research Sources section, then broader web as needed. Verify any factual claims in the draft and check whether cited sources are real. If the audience file has no Research Sources section, fall back to broader web search and note the absence at the top of your critique.
>
> Evaluate on these five criteria:
>
> 1. **Promise delivery:** Does the post deliver on what the opening promises? Does the reader get what they were told they would get?
> 2. **Evidence gaps:** Where does the post assert without substantiating? Flag every claim that lacks immediate support.
> 3. **Entry point:** Does the opening earn the reader's attention in the first two sentences? Would a busy, skeptical reader keep going?
> 4. **Section discipline:** Does every section advance the thesis? Flag any section that is tangential, redundant, or could be cut without loss.
> 5. **Coherence:** Does the argument build, or does it meander? Is the logical thread clear from section to section?
>
> For each criterion, give a rating (strong / adequate / weak) and a specific note. End with a summary judgment and a prioritized list of revisions.
>
> Write your research findings to `{research_path}`. If the file exists, append under a dated section header like `## Critique session YYYY-MM-DD`; do not overwrite existing content. Create the file if missing.

## Presenting findings

Relay the agent's critique to the author verbatim. The author then chooses one of:

- **Revise the artifact** and re-run `/critique` (common when the critic flags real gaps).
- **Dismiss specific criticisms** and proceed (the author has context the critic lacks; that is legitimate).
- **Go back to `/interrogate`** for further development (when the outline's foundations are the problem, not its execution).

Do not argue with the author's decision. The critic is advisory.

## Handoff

- After outline-mode review, when the author is satisfied, invoke `/author` to draft the post.
- After draft-mode review, return findings to the author for revision. Do NOT auto-invoke `/revise`; the author decides whether to revise, dismiss, or re-critique after their own edits.
