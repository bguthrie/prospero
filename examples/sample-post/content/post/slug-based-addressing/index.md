---
title: "Slugs, Not Dates"
description: "Blog URLs should be stable names, not scheduling decisions."
date: 2026-04-12T10:00:00-04:00
draft: false
categories:
  - platform
---

A month ago I rescheduled a post and every inbound link 404'd. The
post was the same post. The URL had moved because the URL encoded
the publication date, and the publication date had changed. I spent
an afternoon writing redirects for a decision I never meant to make.

Blog posts should be addressed by a stable slug, not by publication
date. The slug names what the post is. The date names only when it
appeared, which is metadata, not identity.

## URLs are promises

A URL is a public commitment. Every inbound link, every bookmark,
every RSS reader's cache assumes the path will keep pointing at the
same thing. Berners-Lee said this in 1998 and it is still the single
rule that matters. Slugs keep the promise because they describe the
resource. Dates encode a scheduling decision you may or may not
honor a year from now.

The usual rebuttal is that dates are stable once published. That is
true only if you never reschedule and never backdate. Most writers
do both. I have done both this month.

## Dates belong in frontmatter

Hugo, Eleventy, and Astro all let you put the date in the post's
frontmatter and put whatever you want in the URL. This is the right
factoring. The path is the identifier; the date is an attribute.
The page itself can show the date as prominently as you like, and
readers who want to judge recency have it one line into the post.
Doubling it in the URL serves no reader.

## The journal argument

Tom Preston-Werner picked `/YYYY/MM/DD/slug/` for Jekyll in 2008
because blogs in 2008 were journals, and a journal's entries are
naturally dated. Fair enough in context. But the context has shifted.
Most modern static site generators default to slug-only paths or
make the switch trivial. Treating the 2008 convention as a universal
truth mistakes one design choice for a deduction.

## Migration

If you already have a date-based blog and it hurts, the migration
is a one-time chore. Write the new permalinks, emit 301s for every
old path, keep the redirect map in version control. A few dozen
entries, one afternoon, done. The asymmetry matters: going from
date-based to slug-based is a one-way street, and you should never
go the other direction.

If you are starting a blog today, skip the detour. Use slugs from
the first post. Every inbound link from now on is worth the ten
seconds it takes to configure.
