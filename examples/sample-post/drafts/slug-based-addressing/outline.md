# Why Slug-Based Addressing Beats Date-Based for Blog Posts

## Thesis
Blog posts should be addressed by a stable slug, not by publication
date. The slug captures what the post is; the date captures only
when it appeared. Tying URLs to dates mistakes the accident for the
essence and produces brittle links that decay as soon as you reschedule.

## Antithesis
The strongest counterargument is chronological: a blog is a journal,
and a journal's entries are naturally dated. Date-based URLs communicate
recency at a glance, preserve the author's timeline, and match the
conventions of the tools most writers reach for first. Tom Preston-Werner
picked `/YYYY/MM/DD/slug/` for Jekyll in 2008 for exactly these reasons.

## Synthesis
The journal framing is real but incidental. Readers care what a post
is about; the publication date is one attribute among many, and it
belongs in the post's metadata, not in the address. A URL is a
commitment to stability, and nothing about a URL's path components
should require a commitment you cannot keep. Slugs keep that promise;
dates do not.

## Entry Point
A short anecdote about republishing a post a month after originally
drafting it and watching every inbound link 404 because the date path
moved. Personal, concrete, and names the failure mode without
philosophizing first.

## Sections

### URLs are promises; slugs keep them
- **Claim:** A URL is a public commitment to a resource. Slugs name
  the resource; dates name the scheduling decision around it.
- **Evidence:** Cool URIs Don't Change (Berners-Lee, 1998). Every
  CMS that defaults to date-based paths has a documented migration
  pain when authors reschedule.
- **Objection:** Dates are also stable once published.
- **Resolution:** They're stable only if you never reschedule or
  backdate. Slugs remove that constraint entirely.

### Dates belong in frontmatter, not the path
- **Claim:** Metadata goes in metadata. The path is the identifier.
- **Evidence:** Hugo, Eleventy, and Astro all treat date as a
  frontmatter field and let the path be whatever the author wants.
- **Objection:** Some readers scan URLs to judge recency.
- **Resolution:** The page itself shows the date prominently.
  Readers who care have it; the URL doesn't need to double-encode.

### The journal argument is a historical artifact
- **Claim:** Jekyll's date paths reflected 2008's blogging culture,
  not a universal truth about what blog URLs should be.
- **Evidence:** Tom Preston-Werner's 2008 Jekyll announcement frames
  the permalink format as a specific design choice, not a deduction.
- **Objection:** Conventions have value; departing from them costs
  reader expectation.
- **Resolution:** The convention has already shifted. Most modern
  blog platforms default to slug-only or make it trivial to switch.

### Migration is one-way and cheap if you do it early
- **Claim:** Moving from date-based to slug-based is a small chore
  early and a big one late, but the asymmetry is permanent — you
  should never migrate the other direction.
- **Evidence:** Hugo's `permalinks` config, Jekyll's `permalink`
  frontmatter override, and Eleventy's `permalink` all allow a
  gradual migration with redirects.
- **Objection:** Redirect files are their own maintenance.
- **Resolution:** A redirect map of a few dozen entries is vastly
  cheaper than re-authoring URLs every time you rearrange a schedule.

## So What?
If you're starting a blog today, use slugs. If you already have a
date-based blog and you reschedule posts often enough to feel the
pain, plan a one-time migration and a redirect map. The cost is
small; the payoff is every inbound link from now on.

## Open Questions
- How much does SEO penalize a mid-life URL migration in 2026?
  Informal reading suggests "not much with proper 301s," but I
  haven't verified rigorously.
- Is there a principled case for date-based URLs in aggregator-
  style sites (newsletters, digests) where the date IS the
  identifier? The argument above is narrower than it sounds.
