---
name: write-explainer
description: Write or rewrite the reader-facing copy of a Tell Me How / Polymath topic (headlines, card text, bridges, hooks, picture labels) so a 10-year-old can follow it. Uses Simplified Technical English (ASD-STE100) at about 80% strength, standalone slides and hook endings. Use when drafting a new topic, rewriting an existing one, or doing a copy pass on picture labels.
---

# Write an explainer

Owner-approved 2026-10-25 after three test topics (Shazam, Moon/tides, GPS). Worked example: `examples/gps.md`.

## Who reads it
A 10-year-old, or a curious adult with no background, swiping a phone feed. Topics arrive in random order, so nothing may depend on another topic.

## Steps
1. **Check the title is literally true.** Fix the question if its premise is wrong (the Moon causes tides, not waves) and tell the owner why. The title is a plain question a friend would ask, 12 words or fewer.
2. **Build the spine.** List every idea the reader must hold to get the answer, from zero. One idea per slide. At most 6 content slides. Where one idea needs closing in words before the next builds on it, add a bridge.
3. **Write each slide** with the parts in the output format below.
4. **Write the picture labels** in the same words as the text.
5. **Run the checklist.** Then show the copy in chat. Change no code or topic files until the owner approves the copy.

## Sentence rules (STE at about 80%)
- One idea per sentence. 15 words at most.
- Active voice, simple present tense ("Shazam keeps", not "is kept" or "will be keeping").
- **One word, one meaning,** for the whole topic. Pick the word once and never swap it (for example, "clip" is only ever your recording, "song" is only ever a song in the library, and "peak" is only ever a loud point). Never use synonyms for variety ("landmark", "star" and "dot" all for "peak" is a fail).
- Common words. No idioms, no phrasal verbs where a plain verb exists, no "-ing" words used as nouns.
- At most 7 sentences per slide.
- **The relaxed 20%:** a few technical words are allowed (frequency, peak, Hz, index) when the reader needs them again, each explained in plain words on the same slide. A warm, friendly tone is allowed; it must not read like a manual.

## Slide rules
- **Every slide stands alone.** If a slide uses a word, it explains it on that slide, even if an earlier slide already did. No slide may need a later slide to make sense.
- **Every slide ends with a hook** that the very next slide answers (not two slides later). It is a question, a gap ("But one peak alone does not tell Shazam much.") or a promise ("A storm shows you.").
- **Explain the idea, not the interaction.** Never write "drag the slider" or "tap below"; the cue pill already says it. Say what the picture proves.
- **Say what the picture shows before the reader acts on it.** Axes, colours and what bright or dim means go in the text.
- **Don't repeat the headline** in the text.
- **One number per slide,** rounded, with something to hold it against ("16 metres, taller than a four-storey building").
- **Open from something seen or felt** (a noisy café, a storm, a beach), never from a definition.
- **The last content slide lands the whole idea** in one bold line a friend would repeat.

## Bridges
A bridge (`type: 'bridge'`) is a text-only slide: no headline, no picture, text set large. Use one to close an idea in words before the next slide builds on it (for example, "one peak is common, but a pair is rare" before the slide that pairs peaks). Same sentence rules, about 35 words, ends with a hook. A bridge does not count toward the 6 content slides.

## Picture labels
- Same words as the text: if the text says "peaks", the slider says "PEAKS ONLY", never "BRIGHTEST".
- Short noun phrases or tiny sentences, in capitals on screen.
- No idioms ("SLOWED WAY DOWN" → "SHOWN MUCH SLOWER"), no unexplained terms ("OFFSET").
- Axis labels on every chart ("FREQUENCY ↑", "TIME →").

## Output format (one block per slide)
```
### Slide N
**Headline:** (slide 1: the topic question)
**Setup:** (slide 1 only: one line of stakes)
**Text:** sentences
**Hook:** last sentence, answered by the next slide
**Picture:** one line on what it shows (new topics)
**Picture labels:** LABEL · LABEL
```
Bridges have only **Text** and **Hook**. End with a short note listing: numbers to fact check, the slide most likely to lose a cold reader, and any rule you bent and why.

## Checklist before showing the owner
- [ ] Every sentence is 15 words or fewer, active voice, and holds one idea.
- [ ] Each key word means one thing for the whole topic; no synonyms for variety.
- [ ] Every technical word is explained on each slide that uses it.
- [ ] Each slide makes sense if read alone.
- [ ] Each hook is answered by the very next slide.
- [ ] No sentence describes the interaction.
- [ ] The picture labels use the text's words.
- [ ] The title and every claim are literally true; the numbers are listed for the fact checker.
- [ ] 6 content slides or fewer; bridges only where an idea needs closing.

After approval, the production line in `RECIPE.md` §8 still applies: a cold newcomer reviewer, then a fact checker, then a phone check. Judge clarity with someone who has never read about the topic; the writer and the owner cannot.
