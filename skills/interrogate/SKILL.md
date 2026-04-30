---
name: interrogate
description: Socratic questioning to extract a dialectical outline for a new blog post
---

# Interrogate

Through Socratic questioning, transform a raw topic into a dialectical outline that names its own best counterargument. Produces `drafts/<slug>/outline.md`.

## When to use

- The user has a topic, idea, or argument and wants to start a new post.
- The user wants to test whether an idea is worth writing about before committing to a draft.

Do NOT use for:

- Editing or restructuring an existing draft → use `/revise`.
- Reviewing an outline that already exists → use `/critique`.

## Preconditions

You MUST complete these checks before asking any questions. Do not skip ahead.

Run these as a silent preflight. Do not narrate them to the user unless a check fails; a passing preflight should be invisible.

### 1. `.prospero/config.toml` must exist

If `.prospero/config.toml` does NOT exist in the current working directory, invoke the `prospero:init` skill and follow it to completion. When init returns, resume at step 2 below. Do not proceed to questioning with an unconfigured project.

### 2. `.prospero/voice.md` and `.prospero/audience.md` must be filled in

For each of `.prospero/voice.md` and `.prospero/audience.md`, compute byte-for-byte equality against the plugin's corresponding template at `<plugin-root>/templates/voice.md` and `<plugin-root>/templates/audience.md`. Use the plugin-root resolution procedure defined in the `init` skill's "Resolving the plugin's templates directory" section. Do not abbreviate its failure handling: zero matches → ask the user; multiple matches → ask the user; match found but `voice.md` or `audience.md` missing → halt with the resolved path.

- If either user file is **Missing** → halt with: "`.prospero/<file>` is missing. Run `/init` to restore it, then fill it in before `/interrogate`."
- If either user file is **byte-for-byte equal** to its template → halt with: "`.prospero/<file>` is the unmodified scaffold. Fill it in before running `/interrogate`; this is the one thing Prospero cannot write for you."
- Otherwise → the file is user content. Proceed.

### 3. Resolve the drafts directory

Load `.prospero/config.toml` to get the preset name. Read the preset file at `<plugin-root>/presets/<preset>.toml` and extract `drafts_dir`. Overlay any explicit `drafts_dir` key set directly in `.prospero/config.toml`. If no preset is named, default to `plain`. The resolved value (typically `drafts` or `_drafts`) is where the outline will be written in the Artifact step.

If `config.toml` is unparseable, the named preset file is missing, or the resolved preset lacks `drafts_dir`, halt with a message naming the specific failure and suggesting `/init` to reconfigure. Do not silently fall back.

### 4. Read `.prospero/audience.md` in full

The audience description informs how you frame every subsequent question — what to assume the reader already knows, which counterarguments will land, what tone calibrates the piece. The Research Sources section lists where to verify claims and check for prior art during the questioning. Hold this context throughout the session.

## Process

### First question: what kind of piece?

Ask the user which of the three piece types they are writing. This calibrates the whole pipeline.

1. **Argued essay** — a thesis that needs to survive challenge. The critic will run a full rubric.
2. **Opinion / polemic** — the user has something to say and the value is in saying it well. Critic review is lighter, focused on "is this interesting?" rather than "is this airtight?"
3. **Explainer** — teaching the reader something they don't know. Critic focuses on clarity, accuracy, and whether the reader actually learns what was promised.

### Second question: working title

Ask the author for a working title. A rough version is fine — it does not need to be the final title, and a better one often emerges during questioning. You need something now to resolve the slug (by kebab-casing the title) so research notes can land on disk as the session progresses. If the title changes substantively later, the author can rename the `<drafts_dir>/<slug>/` directory; it is not a cost worth avoiding by deferring this question.

Once the title is resolved, check whether `<drafts_dir>/<slug>/` already exists. If it contains an `outline.md`, show the author the path and ask whether to pick a different working title, overwrite the outline, or stop and resume the existing draft. If the directory exists but contains only `research.md` or is otherwise empty of an outline, proceed without prompting — research accumulates, nothing is overwritten.

### Socratic questioning

Ask one question at a time. Do not batch. Focus on:

- **Thesis:** What exactly are you arguing? Can you state it in one sentence?
- **Antithesis:** What is the strongest version of the opposing view? Who holds it and why? (Frame "who holds it" in terms of the audience defined in `.prospero/audience.md` — the reader types and communities most likely to push back.)
- **Evidence:** Where is the evidence thin or anecdotal? What would make a skeptic change their mind?
- **Unity:** Is this actually one thesis or two competing ones?
- **Stakes:** What is the "so what?" Why should a reader who disagrees still care?
- **Entry point:** Is there a better opening (story, analogy, historical example) than the one on the table?

Use web search proactively to find counterarguments, verify claims, and surface related work the author may want to engage with. The sources to consult are listed in `.prospero/audience.md`'s Research Sources section — use those first, then broader web as needed. Do not hardcode a source list of your own.

**Persist what you find.** Write sources, key quotes, and URLs to `<drafts_dir>/<slug>/research.md` as you go — the slug is already resolved from the Second question step. This is the first entry in the post's research record; downstream phases (`/critique`, `/author`) read it and build on it rather than re-running the same searches. Create the file if missing and append under a section header like `## Interrogation session YYYY-MM-DDTHH:MM` (local time, to the minute).

A few signals that you are not ready yet: the thesis is still two sentences, the antithesis is a strawman, the "so what?" is hand-wavy, or the author is still discovering what they think.

Stop when either (a) the author explicitly says they're ready AND the thesis, antithesis, and "so what?" all pass the checks above, or (b) the author explicitly overrides your concerns (e.g. "I know, let's outline anyway"). In case (b), capture the unresolved concerns in the outline's Open Questions section — do not suppress them.

## Artifact

When interrogation is complete, write the outline to `<drafts_dir>/<slug>/outline.md` using the slug resolved in the Second question step and `drafts_dir` from step 3 of Preconditions. Use this structure:

~~~markdown
# <Working Title>

## Thesis
<One to three sentences stating the core claim.>

## Antithesis
<The strongest version of the counterargument. Not a strawman; the version
a smart, good-faith disagreer would actually make.>

## Synthesis
<Where you land and why. What the thesis looks like after it has absorbed
the counterargument.>

## Entry Point
<The story, observation, or historical example that opens the piece.
Why this is the right door in.>

## Sections

### <Section header, argumentative not topical>
- **Claim:** What this section asserts
- **Evidence:** What supports it (experience, data, reference)
- **Objection:** What a skeptic would say about this specific claim
- **Resolution:** How the section answers the objection

### <Next section>
...

## So What?
<Why should a reader care? What does this change about how they think or act?>

## Open Questions
<Anything unresolved. Thin evidence, uncertain framing, areas where
the author isn't sure yet. Honest inventory.>
~~~

## Handoff

Present the outline to the author for review. They may edit it directly. Once the outline is written, invoke `/critique` for oppositional review. Do not wait for explicit permission; the pipeline assumes the author has read the outline. (They can always dismiss the critic's findings or revise.)
