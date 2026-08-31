---
name: read-lesswrong-post
description: Use this skill when asked to read a LessWrong, Alignment Forum, or EA Forum post given its URL. Can also be invoked with /read-lesswrong-post.
argument-hint: <lesswrong-url>
---

You will be given a URL of a post on LessWrong, the Alignment Forum, or the EA Forum, for example:
https://www.lesswrong.com/posts/L23poLi8MRgS6mXYF/rl-creates-split-personas
https://www.alignmentforum.org/posts/L23poLi8MRgS6mXYF/rl-creates-split-personas
https://forum.effectivealtruism.org/posts/<id>/<slug>

All three sites run **ForumMagnum** and share one GraphQL schema, so the same procedure works for each.

### Part 1: Get the post ID and host

The post ID is the `/posts/<id>/` segment of the URL. It is **case-sensitive**. The host is whichever of the three sites the URL points at — query the same host the URL came from.

A crossposted item is usually retrievable from either LessWrong or the Alignment Forum with the same id.

### Part 2: Fetch the post via the GraphQL API

**Never scrape the rendered HTML page.** The API returns the author's own markdown, so headings, links, footnotes, blockquotes and emphasis survive exactly. Scraping reconstructs all of that from HTML and drags in navigation, footers and subscribe boxes.

```bash
curl -sS --max-time 60 -X POST "https://{host}/graphql" \
  -H "Content-Type: application/json" -H "User-Agent: Mozilla/5.0" \
  --data '{"query":"{post(input:{selector:{_id:\"<POST_ID>\"}}){result{_id title slug pageUrl postedAt baseScore commentCount user{displayName} coauthors{displayName} contents{markdown}}}}"}'
```

Useful fields: `title`, `user.displayName` and `coauthors[].displayName`, `postedAt`, `pageUrl`, `baseScore` (karma), `commentCount`, and `contents.markdown` (the body).

If the response contains an `errors` array with `app.missing_document`, the post id is wrong — re-read it from the URL rather than guessing.

### Part 3: Normalize the markdown

ForumMagnum emits **setext** headings:

```
Main claim
----------
```

Convert these to ATX (`## Main claim`) before using or saving the text. ATX is what `grep '^#'` finds, and it matches how everything else is written.

Leave footnote definitions (`[^abc123]: …`) in place — they carry real content and often hold the author's hedges and caveats.

Images are remote URLs (usually Cloudinary). Keep them as URLs unless asked to download them.

### Part 4: Read the post

Read the whole body, including footnotes. When summarizing or answering questions about it, pay attention to:

- **The main claim, stated in the author's own terms** rather than paraphrased into something more familiar.
- **Confidence markers.** LessWrong authors routinely hedge explicitly ("very speculative", "I'm at ~30% this explains it", "no new experimental results"). These are load-bearing — carry them through instead of reporting hedged claims as findings.
- **What the post concedes.** Good posts name what their own framing fails to explain; that is often the most useful part.
- Whether the post presents **new results** or is a framing/position piece. Say which.

Karma and comment count tell you how the post was received, not whether it is correct. Report them as reception, not evidence.

### Part 5: Report

Tell the user the title, author(s), date, venue, and karma, then answer whatever they asked. If they asked you to read it without a specific question, give a short summary of the main claim and its status (result vs framing), then say you're ready for questions.

### Ingesting into a knowledge vault

If the user wants the post saved rather than just read, and the project is a knowledge vault with a `raw/articles/` directory, follow that project's blogpost workflow — in `agent-wiki-vault` this is `scripts/ingest_forum_post.py <url> <out_path>`, which performs Parts 1–3 and writes frontmatter (`title`, `authors`, `source`, `date`, `venue`, `type: blogpost`, `karma`, `comments`, `retrieved`). Check the post is in scope for the vault before saving it.
