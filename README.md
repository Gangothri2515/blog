# Blog

Data engineering writing, mostly on Hive, Tez and the things that go wrong at
scale. Drafts live here in markdown; published versions go to Medium first, with
a cross-post on dev.to pointing back.

See [PUBLISHING.md](./PUBLISHING.md) for the full publishing workflow and the
pre-publish sanitisation checklist.

## Structure

```
posts/
  NNN-slug/
    index.md            the post, with dev.to-compatible YAML front matter
    diagrams/           diagram sources — .mmd (Mermaid) and hand-authored .svg
    assets/             exported PNGs for Medium and LinkedIn
```

## Posts

| # | Title | Status | Medium | dev.to |
|---|---|---|---|---|
| 001 | [Hive spent 98% of my query on bookkeeping nothing reads](./posts/001-work-that-cannot-be-parallelised/index.md) | Draft | — | — |

## Backlog

Ordered by how much first-hand evidence sits behind each. The first group is
backed by production logs and measured results; the second needs one `EXPLAIN` to
stop being a textbook post; the third is mechanism explanation with no incident
behind it, and should be framed as such.

**Measured**

1. The work that can't be parallelised — *drafted*
2. Managed vs external tables in Hive 3
3. Why `INSERT OVERWRITE` with `UNION ALL` fails on a transactional table
4. Heap, containers, and the three ways Hive runs out of memory
5. How to tell what a slow query is actually waiting on
6. Why 510 million rows only cost 1.34 GB to read
7. Why your Hive row count is lying to you
8. Spark says my table doesn't support DELETE
9. Orchestrating work on a cluster your scheduler can't reach

**One command away**

10. Vectorisation is not parallelism — needs `EXPLAIN VECTORIZATION DETAIL` output
11. Static vs dynamic partition pruning — needs `EXPLAIN` before and after

**Concept**

12. Inside a vectorised hash join
13. Five categories of query optimisation — the capstone, publish last
14. Debugging production with an AI assistant: three times I had to catch it

## House rules

Two that matter more than style:

**Mark where every claim comes from.** "I measured this in my logs", "this is how
the system is documented to behave", and "I'm inferring this" are three different
confidence levels. Readers trust writing that distinguishes them far more than
writing that flattens everything into one confident tone. Every post should end
with a short section separating the measured from the inferred.

**Cite primary sources.** Apache JIRAs, design docs and vendor documentation over
blog posts and Stack Overflow answers. Link them inline and list them at the end
so a reader can check the general claims independently — the numbers are yours,
but the mechanism should be verifiable without taking your word for it.

## Adding a post

```powershell
$slug = "002-managed-vs-external"
mkdir "posts\$slug\diagrams", "posts\$slug\assets" -Force
```

Copy the front matter block from the bottom of `PUBLISHING.md` into
`posts\$slug\index.md` and start writing.
