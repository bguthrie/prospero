# Prospero

A dialectical pipeline for blog-post writing: interrogate, critique, author, revise.

## What is Prospero?

Prospero is a Claude Code plugin that turns a rough topic into a published blog post through four explicit phases. Each phase has one job, produces one artifact, and hands off. The point is to externalize the parts of writing a blog post that are boring to do in your head: naming the counterargument, checking prior art, calibrating voice, and critiquing your own draft.

Prospero is deliberately agnostic about where your blog lives. Voice, audience, and project layout are project-local files you own. A small preset system handles the layout differences between Hugo, Jekyll, Ghost, and plain markdown. Nothing Prospero knows about your writing is hardcoded into the plugin.

## Pipeline overview

1. **Interrogate** — Socratic questioning extracts the argumentative spine of the post: thesis, antithesis, synthesis, entry point, section-level claims and objections. Produces `drafts/<slug>/outline.md` and initializes `drafts/<slug>/research.md` with sources the questioning turned up.
2. **Critique** — An independent oppositional reader challenges the outline. Reads the existing `research.md` first and only runs new web searches for gaps it identifies; flags weak evidence and missing counterarguments. Can also run on a draft. Appends its findings to `research.md`.
3. **Author** — The primary research phase. Reads the outline, existing research, voice guide, audience, and sample posts; grounds the draft's claims against what is already on file and fills specific gaps. Writes the post at the resolved path (e.g. `content/post/<slug>/index.md`).
4. **Revise** — Collaborative line-level and structural feedback on a draft you have already edited. Can re-invoke the critic in draft mode; running `/critique` on the same draft multiple times across revise rounds is the expected path, not an exception.

Each phase is its own slash command; a router skill (`prospero`) picks the right phase when you describe intent without naming one.

## Installation

Install as a Claude Code plugin from the marketplace:

```
/plugin install prospero
```

Or install from this repository directly if you are developing against it.

## Quickstart

1. Install the plugin (above).
2. In your blog's project directory, start a post:
   ```
   /interrogate "why slugs beat dates for blog URLs"
   ```
3. On first run in an unconfigured project, Prospero will invoke `/init` to scaffold `.prospero/config.toml`, `.prospero/voice.md`, and `.prospero/audience.md`. Fill in the voice and audience files with your own rules and reader description, then answer the interrogator's Socratic questions.

The outline lands at `drafts/<slug>/outline.md`. From there you can `/critique` it, `/author` the draft, and `/revise` once you have edited the result.

A worked example lives at [`examples/sample-post/`](examples/sample-post/). It shows the artifacts a single post produces at each stage. A bare Hugo project before and after running `/init` is at [`tests/fixtures/hugo/`](tests/fixtures/hugo/).

## Configuration

Prospero reads three project-local files from `.prospero/`:

- **`config.toml`** — names the active preset and any explicit key overrides.
- **`voice.md`** — your voice guide. Read verbatim by `/author` and `/revise`. You fill this in; Prospero never rewrites it.
- **`audience.md`** — reader description plus a Research Sources catalog. Read by `/interrogate`, `/critique`, and `/author` to calibrate framing and ground research.

Presets live in the plugin at `presets/<name>.toml`. They define `posts_dir`, `post_path_pattern`, `drafts_dir`, `sample_posts_dir`, and `frontmatter_template`:

- **`hugo`** — reference implementation; actively maintained.
- **`plain`** — default for non-CMS projects. Plain markdown with minimal frontmatter.
- **`jekyll`** — skeleton; needs refinement from a Jekyll user.
- **`ghost`** — skeleton; needs refinement from a Ghost user.

To override a single preset value, set it directly in `.prospero/config.toml`:

```toml
preset = "hugo"
drafts_dir = "_drafts"
```

## Piece types

Prospero ships three piece-type rubrics in `templates/types/`:

- **`argued-essay`** — a thesis that must survive challenge. The critic runs the full rubric.
- **`opinion-polemic`** — the value is in saying it well. Critic review is lighter, focused on "is this interesting?"
- **`explainer`** — teaching something. Critic focuses on clarity, accuracy, and whether the reader actually learns what was promised.

The interrogator asks which type you are writing as its first question; the choice propagates through the pipeline. New piece types are a good contribution target — they are small, local, and composable.

## Status

v0.1, extracted from the tooling behind [brianguthrie.com](https://brianguthrie.com). The Hugo preset is what the author uses daily and is the best-tested path. The `plain` preset is adequate for most non-CMS projects. The `jekyll` and `ghost` presets are scaffolds that need someone who uses those platforms to shake them out.

Planned for v0.2: refinement of the Jekyll and Ghost presets, additional piece types, and better handling of multi-post series.

## License

MIT. See [LICENSE](LICENSE).

## Contributing

Pull requests welcome, particularly for:

- Refining the Jekyll and Ghost presets against real projects.
- New piece-type rubrics under `templates/types/`.
- Fixes and clarifications to the skill prompts.

The core phase skills are the primary thing Prospero owns; changes there need a clear rationale tied to an actual workflow problem. Preset and piece-type contributions are lower-risk and can move faster.
