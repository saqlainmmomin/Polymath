---
name: write-explainer
description: Write or rewrite the reader-facing copy of a Tell Me How / Polymath topic (headlines, card text, hooks, picture labels) so a newcomer gets it on one read. Spine-first: facts sheet, then one spoken paragraph the owner approves, then slides cut from it, then a human cold read. Use when drafting a new topic, rewriting an existing one, or doing a copy pass on picture labels.
---

# Write an explainer (spine-first, v2 2026-10-27)

Why this order: in rounds one to five, slides were written first and then patched line by line. Fact-check hedges were pasted in as copy ("higher sunlight"), hooks stopped matching the next headline, and the structure kept moving after the sentences were polished. The fix is to settle the facts, then the whole explanation, then cut it into slides. Each stage has a gate; never go back to an earlier stage by patching a later one.

## Who reads it
A curious adult or a 10-year-old with no background, swiping a phone feed, reading once. Topics arrive in random order, so a topic defines its own words.

## Stage 1: facts sheet (separate fact-checker agent, before any writing)
The checker writes `tasks/<topic>/facts.md`: is the title literally true; the answer in one sentence; 8 to 12 safe claims, each one plain true sentence with a source; myths to avoid; at most one good number with an everyday comparison; 2 or 3 analogies judged for whether they mislead. The writer uses only these claims. A claim that needs a caveat is rewritten until it is simply true, never hedged.

## Stage 2: the paragraph (owner gate)
Write the whole answer as **one spoken paragraph, about 100 to 150 words**, as you would tell a friend across a table. It opens with the surprise, walks the reasoning in order, uses at most one analogy, and ends on the line a friend would repeat. Mark where each slide will start with `[1]`, `[2]`… (at most 6). Then hand the paragraph alone to a fresh subagent and ask it to say the answer back in one sentence and quote any phrase it had to guess at; fix those.

Show the owner the title, the setup line and the paragraph, nothing else. **All structural change happens here:** order, which ideas, which analogy, what to cut. Do not write slides until the owner approves the paragraph.

## Stage 3: slice (owner gate)
Cut the approved paragraph at its marks. Each slice becomes one slide.
- **Text** is that slice, lightly expanded only to say what the picture shows. Do not add new ideas.
- **Headline** reuses words from its own slice. Never coin a new phrase for a headline.
- **Hook** asks the question the next slide's headline answers, using that headline's key word.

Then write the **spine**: title → hook 1 → headline 2 → hook 2 → headline 3 … → bold line, one per line. Read it aloud as a story. If any hook and the next headline don't share a key word, or a headline means nothing on its own, fix the slice, not just the line. Show the owner the spine first, then the slides.

## Stage 4: fact recheck
The fact checker compares the slides with `facts.md` and flags only meaning changes. Fix a flag by going back to the sheet's own plain sentence, not by inserting new wording.

## Stage 5: human cold read (decides "done")
Two people who have never seen the topic read it once on a phone, then say the answer in one sentence and point at the line where they slowed down. If both can say it, the topic is done. A model's read never counts as cold, and the owner's reads after the first one don't count either.

## Editing after any gate
Every edit, however small, regenerates the spine and rereads the slide before and after the edited one. Never change a line without reading the hook that leads into it and the headline it leads to.

## The rules that matter (meaning, not counting)
1. **Say it like a friend.** Mixed sentence lengths, linked with "but" and "so", contractions allowed. Voice bar: `examples/sky-blue-opener.md`.
2. **Headlines decode cold.** Read alone, a stranger can picture it. "More pairs means a higher chance of a match", not "253 small chances make a coin flip".
3. **Never state the obvious or pad** ("tiny machines, too small to see"). Every sentence moves the idea.
4. **One word, one meaning** for the whole topic. No synonyms for variety.
5. **One analogy at most,** picturable in one image, and still right when the reader takes the obvious next thought.
6. **Plain words.** Use a technical term only if the topic needs it again, and define it once in plain words. Never define everyday words. No acronyms, no brackets.
7. **One number per slide,** rounded, against something familiar. Never make the reader do sums.
8. **Slide 1 is the surprise and one question,** no spoilers. If the thing has a name (the birthday paradox), ask directly and name it.
9. **The title is a plain, literally true question,** with no premise the reader doesn't hold.
10. **Explain the idea, not the interaction,** and picture labels use the text's exact words. On screen the card shows the headline, then the text, then the picture below it, so the text tells the reader what to watch and the picture proves it.

Counts (title 12 words, sentences about 8 to 18 words and none over 20, at most 7 sentences a slide, at most 6 slides) are checked by `./build.sh` lint. Stay inside them, but don't write to them.

## Output formats
Stage 2: **Title**, **Setup**, **Paragraph** with `[n]` marks, then one line: the slide most likely to lose a reader.
Stage 3: the **Spine** list, then one block per slide:
```
### Slide N
**Headline:**
**Text:**
**Hook:**   (last slide: **Bold:** instead)
**Picture:** one line on what it shows
**Picture labels:** LABEL · LABEL
```
Then a **Go deeper** line taken from the facts sheet.
