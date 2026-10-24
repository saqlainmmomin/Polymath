# Session log: 2026-10-24 (direction, pilot, small-topic rework)

Owner: Saqlain. All building was done by Sonnet subagents. Plan: `tasks/todo.md`. Fixes and lessons: `tasks/fix-log.md`.

## Decisions, in order
1. **Positioning:** entertainment first, sitting between education and entertainment, and never edtech. No scores, quizzes, lessons or streaks. *Why:* advice from a product friend, and testers responded to fun, not to tests.
2. **Shorts navigation:** swipe up for a new random topic, sideways for the next card in the same topic, and "Go deeper" links on the last card. *Why:* this is the shorts format the owner chose. The Index list replaces the home screen.
3. **Unscored guess taps:** one light tap before a reveal. No RIGHT/WRONG and no score. *Why:* guessing makes facts stick and reads as a game.
4. **Look**, inspired by makingsoftware.com and a "Gazette" editorial mockup. One serif (Newsreader) for all text, tiny uppercase IBM Plex Mono only for labels, warm paper, one rust accent, technical line art. No kickers and no mental-model boxes. *Why:* the owner wanted no competing hierarchy and very readable text.
5. **Topic size, 8–9 cards → one idea in 2–4 cards.** Big subjects become a series of small topics linked via `more`. *Why:* the owner tried the 9-card gearbox and "did not get anything out of it"; the 2-card ice bite worked. In a random feed, one fuzzy card breaks a long chain of dependent ideas.
6. **Picture/text layout:** first the text stuck under the picture with dead space below, so the picture was made to fill the card. Then the owner said text pinned at the very bottom looks odd: the picture should be a bit smaller and the text higher. That rebalance is handled by the side session.
7. **Bigger titles:** the topic name in the top bar went from tiny mono to a 20px serif heading, and card headlines went up to 28px with balanced wrapping. *Why:* the owner "really had to look for the title".
8. **Colour and motion pass:** colour now carries meaning. Blue is water and air, orange (`--s-heat`) is heat and fire, yellow (`--s-spark`) is sparks, green is OK, rust is the moving part. Shapes get real fills. Steps run about 1.1s with a quick pop, and arrows draw in. *Why:* the owner said the animations were "not catching attention, not conveying information in quick bursts".
9. **Page dots:** dots at the bottom of each card show the position and that sideways swipes continue the topic. Done in the side session.

## What was built
- **v2 core** (`core/blocks.js`, `blocks.css`, `library.js`, documented in `core/BLOCKS.md`):
  - Card types: `cover`, `card`, `guess`, `more`.
  - The shorts feed, with only the current topic ±1 mounted.
  - Line-art visuals: `crank`, `strokes`, `cylinders`, `gears`.
- **`diagram` visual:** a data-described scene of parts, steps (show/hide/focus/move/restyle), flows and an optional scrub slider. It covers process steps, cycles, before/after, flows and labelled reveals.
- **Lap counter:** `gears` with `count: true` shows live "Turns n" under each gear and highlights the 3:1 moment.
- **8 topics:**
  - engine-push, crank, four-strokes, cylinders (engine series)
  - spanner, two-gears, why-gears (gears series)
  - ice-floats
- **3 newer topics:** sky-blue, gps, card-payment, from the side session "Refine topics, page dots, layout, add 3 new topics". That session also retitled topics (e.g. "How two gears swap speed for strength"), rebalanced the layout and added page dots. It may still be finishing; check `tasks/fix-log.md` and `tasks/todo.md` for its final state.
- **Archives:** v1 in `archive-v1-pre-pilot/`, the 9-card v2 topics in `archive-v2-long/`.

## Owner feedback (gist)
- Topics too long, and the gears explanation "not clear at all, did not get anything out of it". Prefer smaller, simpler topics.
- Text stuck right under the picture with empty space below. Later: text at the very bottom looks weird, so make the picture smaller and bring the text up.
- "The title is really small, I have to look for it."
- Animations look nice but don't catch attention. Add colour and quick bursts.
- Ice: the ideas did not connect (gaps → 9% more room → floats). Now: gaps → same water, more room → a cupful is lighter → the heavier water pushes it up.
- "Why a long spanner is easier" is an awkward, abrupt title.
- Multi-card topics: it's hard to know where you are and that you should swipe. Wanted page dots.
- Broaden beyond cars. The end goal is curiosity (see `PRODUCT.md`).

## Lessons from reviews
- Every topic failed its first fact check on a real error. Examples:
  - "lighter than the same amount of water"
  - "reload takes four trips"
  - "the gearbox slows it" (the final drive does most of it)
  - a gear labelled "Wheel side"
  - "the battery" as a half-true wrong answer

  Keep the fact checker and the newcomer reviewer as separate agents; they find different things.
- The most common newcomer finding in small topics is a word explained in a sibling topic but not in this one. Every topic must define its own words.
- Writers drift over the ~30-words-per-card budget while applying fixes. Trim after every fix round.
- Asserted mechanisms don't land. Show them: a lap counter for 3:1, gears touching with the same push at the contact point rather than concentric circles.
- Guess cards: the right answer must not echo the previous card's wording and must not be the longest option.

## Artifacts
- **Private preview** (owner checks here): https://claude.ai/artifact/EmopmpGtn9AR1BFywrdn2t. Republish `dist/library.html` with this url.
- **Testers' link**, shared anyone-with-link with 5 testers: https://claude.ai/artifact/47dT3dkGhANEzEWf64UFhP. It last carried the 9-card v2 pilot. **Do not republish without the owner's explicit OK.**
- **Old standalone gearbox:** https://claude.ai/artifact/5vy4i2LsnqvxJd1BUf8dRK. Still v1; never updated by library builds.

## Screenshot helper (Playwright)
It lived in a temp scratchpad (`/private/tmp/claude-501/.../scratchpad/pw/`) that may be gone. To recreate it:
1. In any scratch folder, run `npm init -y && npm i playwright@1.56.1`.
2. Launch with the cached Chromium instead of downloading:
   `chromium.launch({ executablePath: '/Users/saqlainmomin/Library/Caches/ms-playwright/chromium_headless_shell-1228/chrome-headless-shell-mac-arm64/chrome-headless-shell' })`
3. Open `file:///Users/saqlainmomin/tell-me-how/dist/library.preview.html#<topic-id>` at viewport 375x667, `colorScheme` light and dark, `deviceScaleFactor` 2. Collect `console` errors and `pageerror`. ArrowRight moves to the next card and ArrowDown to the next topic. Wait about 2.6s per card so animations settle.
