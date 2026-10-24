# Tell Me How: direction and plan (agreed 2026-10-24)

Done earlier: the topic-format experiment (recipe + blocks + Sonnet agent) finished. Gearbox was about 90% usable as delivered; see `fix-log.md`.

## Direction
- **Positioning:** entertainment first, between education and entertainment. Never edtech: no scores, no quizzes, no lessons, no streaks.
- **Format = shorts.** Swipe up anywhere = a new random topic. Swipe sideways (or tap the right edge) = the next card in this topic. The last card has "Go deeper" links to related topics.
- **Topic size (revised 2026-10-24 after the owner tried v2):** one idea per topic, 2–4 cards plus `more`. Big subjects become a series of small topics linked through `more`. The 9-card engine and gearbox were too long: the gears explanation didn't land at all, and the ice bite did. (Earlier plan: 8–9 card full topics plus bites.)
- **Guess taps stay** as light, unscored taps before a reveal. The recall/quiz card and the score are removed.
- **Look** (inspired by makingsoftware.com and the "Gazette" editorial mockup): one reading voice and no competing hierarchy.
  - Type: one serif (e.g. Newsreader / Source Serif 4) for headlines and text, loose line height. Tiny uppercase mono only for diagram labels and the card counter. Drop Big Shoulders, the orange kickers and the MENTAL MODEL box.
  - Card: the visual takes the top ~55%, then a headline and at most 2 sentences. The takeaway is the last sentence, in bold.
  - Palette: warm off-white paper, near-black ink, one rust accent used only for "tap this" or "this is moving". Dark mode = ink paper, same rules.
  - Chrome: page dots at the bottom (current card in accent, "Swipe →" on card 1), text-link buttons. (Was a hairline progress bar and `03 / 08`.)
- **Visuals:** technical line art by default (thin ink lines, cutaways and exploded views, mono labels with leader lines, no captions, colour only for the subject). Other styles are allowed per topic when they explain that topic better; try them as experiments, not by default.
- **Motion:** slow, eased and mechanical. Animations start on their own when a card appears, loop calmly, and only the explaining part moves.
- **Animation-type library** (reusable, data in and no topic text in code), so most topics fill templates and only flagships get custom sims: process steps, cycle loop, scrubbable cutaway, before/after, flow along a path, lever/force, rotating mechanism (gears), scale zoom, labelled reveal diagram, wave/signal, network/map, timeline.
- **App:** Capacitor shell around the existing web build. Topics stay data files. Ship to TestFlight and Play internal testing.
- **Production line per topic (Sonnet agents):** writer (recipe + animation types) → separate newcomer reviewer → fact checker → phone-screen check (375px, light and dark). Saqlain reviews only the finished topic and the fix log.

## Phase 1: Pilot (before any new topics)
Status 2026-10-24: steps 1–5 done (spec in `tasks/pilot-spec.md`, v1 backup in `archive-v1-pre-pilot/`). Engine and gearbox are 9 cards each, ice-floats is a 2-card bite; all passed newcomer review + fact check after fixes (see `fix-log.md`). Step 6: testers' library link republished with v2 on 2026-10-24 (version 5); collect their feedback next.
1. Rewrite `RECIPE.md` for the new format: 8–9 cards at most or a 1–2 card bite, no recall card, the card anatomy above, the bold-takeaway rule, and the screen budget kept.
2. New look in `core/`: serif + mono fonts, warm paper tokens (light/dark), card layout with the visual on top, hairline chrome, and the mental-model box and kicker removed.
3. Shorts navigation: vertical = random topic, horizontal = cards within a topic, Go deeper links, bites in the feed.
4. Animation-type library: restyle the existing canvases to line art, then add the generic types above, starting with process steps, cutaway and flow (turbo and most topics need them). Document each in `core/BLOCKS.md`.
5. Rebuild engine and gearbox in the new format (8–9 cards at most each, depth moved into linked topics/bites) and write one bite.
6. Show the 5 testers; fix what they flag. Smoke test: 375px screenshots in light and dark, no console errors, both swipe directions work.

## Phase 1b: Small-topic rework (2026-10-24)
- Picture now grows to fill the space the text doesn't need (owner: text stuck under the picture with empty space below).
- Engine → engine-push, crank, four-strokes, cylinders. Gearbox → spanner, two-gears, why-gears. Old 9-card versions in `archive-v2-long/`.
- Then review, phone check, and owner OK before republishing the testers' link.

## Phase 1c: Titles, layout, dots, first non-machine topics (2026-10-24)
- Done: titles as hooks, picture ~50% with text right under it, page dots replace the counter and progress line, `spark` diagram style, 3 new topics (sky-blue, gps, card-payment), flow check in `tasks/flow-check.md`. Private preview republished.
- Next (owner to decide): space out series in the shuffle; watch for diagram step dots read as page dots; redo the card-payment timeline visual; keep new topics mostly non-machine. Testers' link not republished yet (needs owner OK).

## Phase 2: First 20 topics + test app
7. Capacitor wrapper; TestFlight + Play internal testing builds.
8. Run the production line until the feed holds about 20 topics (now all small, one idea each; series count as several), logging fixes in `fix-log.md`.
9. Ship the test build to testers. Signal to scale to 100: people keep swiping up for more topics.

### Draft topic list (4 themes)
- **Machines:** car engine*, gearbox*, how brakes stop a car, lock and key, how a fridge makes cold; bite: how a zip locks.
- **Nature & weather:** why the sky is blue, how lightning forms, how a rainbow forms; bites: why ice floats, why the sea is salty.
- **Internet & phones:** how Wi-Fi carries data, how GPS knows where you are, how a touchscreen feels your finger; bite: what a pixel is.
- **Money & everyday systems:** how a card payment goes through, how a barcode works, how airlines price seats; bites: why prices end in .99, how a cash machine knows your balance.
(* = rebuilt in Phase 1)

## Phase 3: Big questions, one card system, interaction cue (2026-10-24, owner direction)
Owner feedback: the small topics' questions do not spark curiosity; the big ones ("How does an engine work?") did. Wants bigger, eye-catching question titles, no dead space on cards, softer content, and a hint that animations can be touched.

**Decisions**
- Topic size: a topic is one BIG question, 4-6 cards at most (1-2 for a quick one). Engine series -> one topic, gears series -> one topic. Old small topics go to `archive-v3-small/`.
- Title = a full, natural question with a tension or stake ("Why does ice float on the very water it came from?"; titles must be literally true). Big serif, first thing on card 1.
- Card anatomy (3 zones, no dead space): headline ABOVE the picture, picture takes all spare height, 1 short paragraph below. Card 1 shows the topic question as its headline (bar title hidden there), later cards show a small version in the bar.
- Interaction cue: a small pill on the picture's bottom edge ("Drag the crank"), appears ~0.7s after the card shows, fades after ~5s or on first touch, and stops for the session once the reader has interacted anywhere.
- System, not one-offs: `RECIPE.md` v3 (sizing, title formula, copy rules with before/after), `topics/_template.js`, and lint warnings in `build.mjs` so every topic is checked the same way.

**Steps** (core first, then content in parallel)
1. [ ] Core: card anatomy v3 (CSS + `R.card`/`R.guess`), bar title rule, cue helper wired into crank/strokes/gears/cylinders/diagram.
2. [ ] `build.mjs` lint (title is a question, 1-6 cards, words per card, cue not disabled on interactive visuals) and `topics/_template.js`.
3. [ ] `RECIPE.md` v3 and `core/BLOCKS.md` updates.
4. [ ] Content, parallel writers + separate newcomer reviewer + fact checker: engine (merge 4 topics), gears (merge 3 topics), retitle/rewrite ice-floats, sky-blue, gps, card-payment.
5. [ ] Phone check light + dark, then owner review on the private preview. Testers' link stays untouched.
Later (owner): 10-15 new big-question topics, then the app shell.
