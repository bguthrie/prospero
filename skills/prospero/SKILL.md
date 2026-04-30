---
name: prospero
description: Dialectical blog-post pipeline. Use when the user expresses intent to write, outline, review, draft, or revise a blog post. Routes to the appropriate phase skill based on input and project state.
---

# Prospero

Prospero is a dialectical pipeline for writing blog posts: interrogation into an outline, oppositional critique, voice-calibrated authoring, and line-level revision. This skill is the router — it reads the user's intent and the current project state, picks one phase skill to invoke, and hands off. It does not chain phases or duplicate their preflight logic.

## When to use

Invoke this skill when the user's message expresses intent to produce or work on a blog post, without naming a specific phase. Typical phrasings:

- "Help me write a post about X."
- "I want to outline a piece on Y."
- "Can you review this outline?"
- "Draft the post from the outline."
- "I've edited the draft — give me feedback."
- "Let's work on a blog post."

If the user invoked a specific phase directly via `/interrogate`, `/critique`, `/author`, or `/revise`, do not invoke this skill — that phase skill is already running.

## When NOT to use

- The user asks an edit-level question about a single sentence or paragraph in an existing draft → invoke `/revise` directly.
- The user asks how Prospero works, what a phase does, or wants to inspect configuration → answer the question; do not route.
- The user is working on non-blog content (documentation, email, README, code comments) → do not route. Prospero is scoped to blog posts.

## Routing logic

Pick exactly one phase skill based on what the user has and what they are asking for.

1. **Topic or raw idea, no outline yet → `/interrogate`.** The first phase extracts the argumentative spine through Socratic questioning and writes the outline artifact. This is the entry point for any post that does not yet have an outline on disk.

2. **Outline exists at `<drafts_dir>/<slug>/outline.md` and the user wants adversarial review → `/critique`.** Critique is an independent, oppositional reader; routing here before drafting is how the pipeline stress-tests the argument.

3. **Outline exists (usually reviewed) and the user says "draft it" or equivalent → `/author`.** The author reads the outline, voice, audience, and sample posts, then writes the post at the resolved `post_path_pattern`.

4. **Draft exists at the resolved post path and the user wants feedback on their edits → `/revise`.** Revise is collaborative line-level and structural feedback on a draft the user has already touched; it can also re-invoke `/critique` in draft mode.

5. **Draft exists and the user wants adversarial review → `/critique` in draft mode.** This is how the pipeline stress-tests execution, not just the argument. Expect this route to be taken more than once over a single draft's lifecycle: authors typically cycle `/critique` ↔ revisions ↔ `/critique` across several passes before publishing. A second or third critique pass on the same draft is the normal case, not an exception — do not second-guess it or default to `/revise` just because the draft has already been critiqued once.

If the user's intent is ambiguous between two phases, ask one clarifying question and route on the answer. Do not run a phase speculatively. The most common ambiguity after authoring is rule 4 vs. rule 5 — "review my draft" can mean either. When in doubt, ask whether the user wants an adversarial reading (`/critique`) or collaborative editing feedback (`/revise`).

## Init handoff

If `.prospero/config.toml` is missing, do not invoke `/init` yourself from here. Route to the phase skill the user's intent maps to; each phase skill's preflight auto-invokes `/init` when the project is unconfigured and resumes its own work afterwards. This skill's job ends at the routing decision.

## Artifacts

Each phase reads and writes files at known locations. Path variables (`drafts_dir`, `post_path_pattern`) resolve from `.prospero/config.toml` and the active preset.

- **Outline:** `<drafts_dir>/<slug>/outline.md` — written by `/interrogate`, read by `/critique` and `/author`.
- **Research:** `<drafts_dir>/<slug>/research.md` — written by `/critique`, read by `/author`.
- **Post:** resolved `post_path_pattern` with `{slug}` substituted (e.g., `content/post/<slug>/index.md`) — written by `/author`, read and edited by `/revise`.

The slug is the cross-reference spanning all three paths. No state file tracks the active post; filesystem mtime under `<drafts_dir>/` resolves ambiguity when several drafts are in flight.

## Configuration

Prospero reads three user files from `.prospero/` in the project root:

- **`.prospero/config.toml`** — names the active preset and any explicit overrides for its keys.
- **`.prospero/voice.md`** — the author's voice guide; read verbatim by `/author` and `/revise`.
- **`.prospero/audience.md`** — the audience description and research-source catalog; read verbatim by `/interrogate`, `/critique`, and `/author`.

These files are never rewritten by phase skills. `/init` creates them from templates; the user fills them in.
