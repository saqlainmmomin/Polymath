# Writer brief (v3 system): read this before writing or rewriting a topic

You write ONE topic file in `/Users/saqlainmomin/tell-me-how/topics/`. The product is a phone shorts feed that makes curious people want to read more. The owner's verdict on the first version: small, narrow topics did not spark curiosity; a big question with a satisfying answer did. The titles were too weak, cards had dead space, and the text read like a textbook.

## Read first, in this order
1. `PRODUCT.md` (the goal), then `RECIPE.md` (v3, binding: size, title, card anatomy, copy rules, cue).
2. `topics/_template.js` (the shape), `core/BLOCKS.md` sections 1-3 (visual types and their params; `diagram` is the default).
3. The old topic file(s) named in your assignment: reuse their working pictures, facts and ideas, but rewrite the words completely in the new voice. Their old text is the "before" in RECIPE.md section 4.
4. `tasks/fix-log.md` (the mistakes reviewers keep catching: every topic so far failed its first fact check; newcomers trip on words explained only elsewhere).

## Hard rules
- Only create or edit YOUR topic file(s). Do NOT touch `core/`, `build.mjs`, `RECIPE.md`, other topics, or `LIBRARY`. The orchestrator registers and archives topics.
- Build only your own topic: `cd /Users/saqlainmomin/tell-me-how && ./build.sh <id>`. Never run `./build.sh library`. The build must show NO warnings for your file (title is a question of at most 12 words ending in `?`, 1-6 content cards, about 30 words of text per card, headline about 8 words).
- `kind`: `'bite'` for 1-2 content cards, `'full'` for 3-6. `theme`: one of machines, nature, internet, money.
- Card 1 is the opener: the topic title is its headline; its own `title` is an optional one-line setup. The picture shows the mystery at once. Cards 2+: headline above the picture, one short paragraph below.
- Plain text only (no HTML), no em dashes. Last card `{ type: 'more', links: [...] }` with ids that exist in `topics/` (or `[]`).
- Define every word inside the topic. Use plain words first. Start from zero.
- Pictures must fill the panel (draw big, view box near square, no empty bands) and every card needs a visual. Visuals that can be touched get the cue automatically (see `RECIPE.md` section 5): if your picture is interactive, check the pill does not cover a label.
- Facts: be conservative. If a number or claim is rough, say "about". If unsure, simplify rather than assert.

## Verify (never claim done on faith)
Screenshot every card, light and dark, at 375x667 and LOOK at the PNGs:
`cd /private/tmp/claude-501/-Users-saqlainmomin/515c5568-c803-4e67-80b1-d3f4b8310c97/scratchpad/pw && SINGLE=1 node shoot.mjs out-<id> <id> both 2200` (add `TAP=1` to also tap the first option of guess cards). Check: no overflow or overlap, no dead space, headline readable, labels do not collide, zero console errors. Fix and re-shoot until clean.

## Report back (short)
- Title, card count, one-sentence idea.
- Each card: headline | the paragraph (exact text).
- Build warnings (must be none), console errors (must be zero), what you checked in the screenshots.
- Anything you are unsure is TRUE (numbers, mechanisms, geometry), for the fact checker.
- Anything in the pictures you could not make work.
