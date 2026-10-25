# Publishing a post

**Medium is home.** Every post is published there first and in full. dev.to gets
a complete cross-post with its canonical link pointed back at Medium. LinkedIn
drives traffic. Reddit gets the discussion.

Order matters: the Medium URL has to exist before anything else can point at it.

---

## 0. Before anything goes public

Run this checklist on every post. The technical substance survives
genericisation completely; none of these posts need a real identifier to land.

- [ ] No real schema or database names
- [ ] No real table names that carry the business domain
- [ ] No storage account, container, or bucket names
- [ ] No hostnames (metastore, edge nodes, Thrift URIs)
- [ ] No HDFS nameservice names
- [ ] No filesystem paths that include an org or project name
- [ ] No service account or username
- [ ] No DAG, task, or job IDs
- [ ] No internal distribution lists, Slack channels, or on-call tooling
- [ ] Query IDs and application IDs redacted or replaced
- [ ] Row counts and timings kept — these are the point and are not sensitive

Grep for the obvious ones before committing. The terms to search for are
employer- and project-specific, so they live in `scrub-terms.txt`, which is
gitignored and never published — keep one term per line:

```powershell
$terms = (Get-Content .\scrub-terms.txt | Where-Object { $_ -and $_ -notmatch '^#' }) -join '|'
Get-ChildItem .\posts -Recurse -Include *.md,*.mmd,*.svg |
  Select-String -Pattern "(?i)($terms)"
```

An empty result is what you want.

---

## 1. Export every diagram to PNG

Two hard constraints from Medium, both worth knowing because they are not
negotiable:

- The editor accepts **only JPG, JPEG, GIF and PNG**, up to 25 MB. SVG cannot be
  uploaded at all, and Mermaid obviously cannot be rendered.
- An image must be **at least 1192px wide** or Medium hides some of the
  placement options, so you cannot make it full-width.

Both are stated in [Medium's own help page on images][mediumimages].

So PNG export is mandatory and comes first. One command does all of it:

```powershell
powershell -ExecutionPolicy Bypass -File tools\render-diagrams.ps1 -Post 001-work-that-cannot-be-parallelised
```

That script drives headless Chrome, so there is **no Node, npm or Puppeteer
install needed**. For every `.mmd` in the post's `diagrams/` folder it writes a
matching `.svg` next to the source and a wide `.png` into `assets/`, and it
rasterises hand-authored SVGs like `where-the-time-went.svg` the same way. Add
`-Only <name>` to redo a single diagram.

Three details in there exist because of bugs worth not re-discovering:

- **White background is forced.** A transparent PNG makes dark diagram text
  invisible to anyone reading Medium in dark mode.
- **Mermaid runs with `htmlLabels: false`.** HTML labels render into
  `<foreignObject>`, which browsers ignore when an SVG is loaded through an
  `<img>` tag — the export would come out blank. The cost is that `<b>` tags in
  node labels do nothing, so do not use them.
- **Chrome's stdout is decoded as UTF-8 explicitly.** Without that, PowerShell
  uses the console codepage and every em dash and middot in a diagram turns to
  mojibake.

Commit the PNGs. They are the published artifact and you will want them again for
LinkedIn.

[mediumimages]: https://help.medium.com/hc/en-us/articles/215679797-Using-images

---

## 2. Medium — the canonical home

1. Go to <https://medium.com/new>
2. Paste the body of `index.md` — **not** the YAML front matter.
3. **Set the three title elements.** Medium infers these from position plus
   formatting, which is unintuitive enough that most people never set them. In
   the editor, select a line and use the two `T` buttons — large `T` is a
   header, small `T` is a subheader:
   - **Title** — the first line of the story, formatted with the large `T`.
   - **Subtitle** — the line directly *below* the title, formatted with the
     small `T`. Always set one. It shows up in search results and link previews,
     and a story without it looks unfinished.
   - **Kicker** — optional single word *above* the title, small `T`. Use it as a
     category signpost. `HIVE` or `PERFORMANCE` works for this material.
4. **Add a featured image.** The first image in the story becomes the one Medium
   uses in the feed and in every social share card, including the LinkedIn and
   X previews later. Use `where-the-time-went.png` — it carries the whole
   argument by itself. Then click it and:
   - set **alt text** (accessibility, and it is indexed),
   - write a **caption** — captions get read more than body text,
   - set the **focal point** with alt-click so Medium crops the preview
     sensibly rather than through the middle of a bar.
5. **Code blocks.** This is the one real weakness of Medium as a home for
   technical writing, so handle it deliberately:
   - Short snippets (1–3 lines): Medium's inline code block is fine. Type three
     backticks and Enter.
   - Anything longer — the SQL, the Task Execution Summary, the progress table,
     the config diff — put in a [GitHub Gist](https://gist.github.com) and paste
     the Gist URL on its own empty line. Medium embeds it with real syntax
     highlighting and horizontal scrolling. Name each Gist file with the right
     extension (`.sql`, `.diff`, `.txt`) so highlighting picks the right
     language.
6. Upload the remaining PNGs where the ` ```mermaid ` blocks sit in the markdown,
   and delete those blocks — they are for GitHub and dev.to, not here. Give each
   image alt text and a caption too.
7. Add up to five tags. Medium allows five, dev.to only four, so the two lists
   differ slightly. For this post on Medium: `data engineering`, `hive`,
   `optimization`, `performance`, `big data`
8. Publish

**Alternative to pasting: the import tool.** <https://medium.com/p/import> takes
a public URL and converts the page into a Medium draft, and it sets the canonical
link back to the source automatically. That is useful once posts live somewhere
public, but it is the wrong way round while Medium is the canonical home — the
import would credit GitHub instead. Paste manually for now.

**Reach.** A story on your own profile reaches almost nobody. Submitting to a
publication is the whole game. Relevant ones for this material: *Data Engineer
Things*, *Towards Data Science*, *Dev Genius*, *Towards Dev*. Most require you to
request writer access first, which can take days — start that request now so it
is in place for post 2. Check each publication's guidelines on previously
published work; some want originals only, which is another reason Medium goes
first.

**Copy the published URL.** Everything below needs it.

---

## 3. dev.to — the cross-post

dev.to is the better technical renderer, so this copy is worth having even though
it is not the canonical one. It renders ` ```mermaid ` blocks natively, so you can
publish the markdown as-is without the PNG substitution.

1. Open `index.md` and fill in the front matter:

   ```yaml
   canonical_url: https://medium.com/@you/your-post-slug
   ```

2. Sign in at <https://dev.to> → **Create Post**
3. Switch the editor to **Markdown** via the settings gear if it is not already
4. Paste the whole file, front matter included. dev.to reads `title`, `tags`,
   `description`, `canonical_url` and `published` directly from it
5. Upload `where-the-time-went.svg` with the toolbar image button and replace the
   `./diagrams/...` path with the URL dev.to returns. Leave the ` ```mermaid `
   blocks exactly as they are
6. Save with `published: false`, check the preview — especially that both Mermaid
   diagrams rendered — then set `published: true` and save again

Four tags maximum, lowercase, no spaces — this is why `bigdata` is dropped here
but kept on Medium: `hive`, `dataengineering`, `performance`, `optimization`.

With `canonical_url` set, dev.to displays an "Originally published at medium.com"
line and tells search engines to credit the Medium URL. That consolidates your
search ranking onto one page instead of splitting it between two identical
articles.

---

## 4. LinkedIn — traffic, not hosting

Do **not** paste the whole post here. Two formats work:

### A native post (default choice)

- 150–250 words. State the finding and the number, not the methodology.
- Put the Medium link **in the first comment**, not the post body. LinkedIn
  reduces the reach of posts containing external links.
- One image — use `where-the-time-went.png`. It carries the whole argument on its
  own.
- Three to five hashtags: `#dataengineering #hive #bigdata #performance`

Opening line draft for this post:

> A nightly Hive job hit 99% in three and a half minutes, then sat at 99% for the
> next two and a half hours.
>
> The real work — a scan of 510 million rows, five joins and a GROUP BY — took
> 185 seconds. The other 98% was one task computing column statistics that
> nothing in the pipeline would ever read. One `SET` removed it and the job
> finished in 16 minutes.
>
> More containers would not have helped. Some work cannot be parallelised, and
> that work sets the floor on your runtime.

### A document carousel (higher engagement, more effort)

Export 6–10 slides to a single PDF and upload it as a document post. These
perform unusually well for technical content and work around LinkedIn's inability
to format code. Good slide order: the symptom, the summary table, the three
tells, the mechanism, the one-line fix, the result, when not to do it.

---

## 4b. X / Twitter — worth doing, not worth optimising

Be clear-eyed about this one. For a data engineer building a professional
footprint, **LinkedIn is where the career value is** — that is where recruiters,
hiring managers and your peers actually are, and it is where the data
engineering conversation has largely moved. X has a thinner data-engineering
community than it used to, and building an audience there from zero is slow.

But the marginal cost once the post exists is about five minutes, and unlike
LinkedIn, posts on X stay findable and linkable, so it is worth doing as an
afterthought rather than a strategy.

- Post a **thread**, not a single tweet with a link. A bare link gets suppressed
  the same way it does on LinkedIn.
- Three or four tweets: the hook, the counterintuitive number, the fix, then the
  link in the last one.
- Attach `where-the-time-went.png` to the first tweet. Images carry threads.
- Two hashtags at most. `#dataengineering` and `#hive`.

Tweet one should be the hook alone, with the image:

> A Hive query hit 99% in 3.5 minutes.
>
> Then sat at 99% for 2.5 hours.
>
> 98% of the runtime was one task doing work nobody asked for. 🧵

**Do not** cross-post the same text to LinkedIn and X on the same day. The
audiences overlap enough to notice, and the formats reward different things.

---

## 5. r/dataengineering — the practitioners

- Post the **substance in the body as a text post**. A bare link reads as
  self-promotion and gets downvoted or removed.
- Paste the Task Execution Summary and the fix inline. Link the full post at the
  bottom as "longer write-up here" if you want.
- Read the subreddit's self-promotion rules first; they change.
- Expect to be challenged on specifics. That is the value — it is the best
  technical review you will get for free.

---

## 6. Stack Overflow — for the narrow ones

Not every post, but for sharply specific errors it is the highest-leverage place
and the content is permanent. Find the existing question about the error and write
an answer explaining the mechanism rather than just the workaround. People will
land on it for years.

Applies to planned post 3 (the `OVERWRITE` + `UNION ALL` lock failure) and post 8
(Spark's `DELETE` on a non-Delta table).

---

## 7. After publishing

- [ ] `canonical_url` in the front matter points at the Medium URL, and committed
- [ ] `published: true` in the front matter, and committed
- [ ] Live URLs recorded in `README.md`
- [ ] PNGs committed under `assets/`
- [ ] Status updated in the backlog canvas

---

## Front matter reference

```yaml
---
title: "My Hive query sat at 99% for two and a half hours"
published: false
description: "One sentence. Shows up in search results and link previews."
tags: [hive, dataengineering, performance, optimization]
canonical_url:  # the Medium URL, filled in after step 2
---
```

`tags` must be four or fewer, lowercase, no spaces or punctuation. This front
matter is read by dev.to; Medium ignores it, which is why you paste the body
only.
