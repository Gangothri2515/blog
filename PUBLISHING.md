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

Medium cannot render Mermaid, so this step is mandatory and comes first. You need
a PNG for every diagram before you start writing the Medium draft.

### Option A — no install (quickest)

1. Go to <https://mermaid.live>
2. Paste the contents of a `.mmd` file from `posts/<post>/diagrams/`
3. **Actions → PNG**, save into `posts/<post>/assets/`

### Option B — scriptable (better once you have more than one post)

```powershell
npm install -g @mermaid-js/mermaid-cli

cd .\posts\001-work-that-cannot-be-parallelised
mkdir assets -Force
mmdc -i diagrams\dag-before-after.mmd -o assets\dag-before-after.png -b white -s 3
mmdc -i diagrams\diagnostic-flow.mmd  -o assets\diagnostic-flow.png  -b white -s 3
```

`-s 3` renders at 3x so it stays sharp on high-DPI screens. `-b white` matters
because a transparent background makes the dark text invisible to anyone reading
Medium in dark mode.

### The hand-authored SVGs

`where-the-time-went.svg` is drawn to scale by hand rather than generated.
Convert it the same way:

```powershell
npm install -g sharp-cli
sharp -i diagrams\where-the-time-went.svg -o assets\where-the-time-went.png --width 2000
```

Or open the `.svg` in a browser, zoom to 200%, and screenshot it. Crude, works.

Commit the PNGs. They are the published artifact and you will want them again for
LinkedIn.

---

## 2. Medium — the canonical home

1. Go to <https://medium.com/new>
2. Paste the body of `index.md` — **not** the YAML front matter. The first line
   becomes the title, the second becomes the subtitle
3. **Code blocks.** This is the one real weakness of Medium as a home for
   technical writing, so handle it deliberately:
   - Short snippets (1–3 lines): Medium's inline code block is fine. Type three
     backticks and Enter.
   - Anything longer — the SQL, the Task Execution Summary, the progress table,
     the config diff — put in a [GitHub Gist](https://gist.github.com) and paste
     the Gist URL on its own empty line. Medium embeds it with real syntax
     highlighting and horizontal scrolling. Name each Gist file with the right
     extension (`.sql`, `.diff`, `.txt`) so highlighting picks the right
     language.
4. Upload the PNGs from step 1. Click an image after inserting it to add a
   caption — captions are worth writing, they are read more than body text
5. Add up to five tags. Medium allows five, dev.to only four, so the two lists
   differ slightly. For this post on Medium: `data engineering`, `hive`,
   `optimization`, `performance`, `big data`
6. Publish

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

> A nightly Hive job was taking 2 hours 33 minutes. The actual query — a scan of
> 510 million rows, five joins and a GROUP BY — accounted for 194 seconds of
> that. The other 97.9% was a single task computing statistics that nothing in
> the pipeline would ever read.

### A document carousel (higher engagement, more effort)

Export 6–10 slides to a single PDF and upload it as a document post. These
perform unusually well for technical content and work around LinkedIn's inability
to format code. Good slide order: the symptom, the summary table, the three
tells, the mechanism, the one-line fix, the result, when not to do it.

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
tags: [hive, bigdata, performance, dataengineering]
canonical_url:  # the Medium URL, filled in after step 2
---
```

`tags` must be four or fewer, lowercase, no spaces or punctuation. This front
matter is read by dev.to; Medium ignores it, which is why you paste the body
only.
