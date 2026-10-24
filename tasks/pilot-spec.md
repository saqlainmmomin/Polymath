# Phase 1 pilot spec (v2 format)

The contract every pilot agent builds from. Direction and reasons: `tasks/todo.md`. v1 is backed up in `archive-v1-pre-pilot/` (do not edit it).

## 1. Look
One reading voice. Nothing on a card competes with the headline and the visual.

- **Fonts:** Newsreader (Google Fonts, opsz axis, weights 400/500/600 + italic 400) for every piece of reading text. IBM Plex Mono 500 only for diagram labels, the card counter and tiny meta, always uppercase, 10–11px, letter-spacing 0.08em. No other fonts. Big Shoulders and Public Sans are removed.
- **Tokens** (light / dark):
  - `--paper` #F5F0E6 / #15130F (page and card background)
  - `--panel` #FBF8F2 / #1C1915 (visual panel)
  - `--ink` #1E1A15 / #ECE5D8 (text, line art)
  - `--ink2` #5C5449 / #A79E90 (secondary text, labels)
  - `--rule` #D9D0C0 / #3A342C (hairlines, panel border)
  - `--accent` #B4532A / #E2804F (rust; ONLY for "tap this" and "this is the moving/important part")
  - Subject colours, confident and meaningful: `--s-blue` #3F7DB2 / #6FAAE0 (air, water, cold, data, fuel/air), `--s-heat` #E06B22 / #FF9040 (fire, heat, burning mix), `--s-green` #4E9A4C / #7CCB74 (living, OK), `--s-spark` #EDB10F / #FFD24A (sparks, flashes, energy only; never text).
  - Dark mode = same rules, ink paper. Respect `prefers-color-scheme` and `[data-theme]` the way blocks.css already does.
- **Type scale (375px wide):** card headline 25px/1.2 Newsreader 500, letter-spacing -0.01em; body 17px/1.6 Newsreader 400, `--ink`; takeaway = last sentence of the body in Newsreader 600 (same size, no box, no label); cover title 34px/1.1 Newsreader 500.
- **Card anatomy** (one card = one screen, 375x667 must fit with no scroll):
  - Top bar, 36px: left = topic title in mono (truncate), right = `03 / 08` in mono. Under it a 1px hairline progress line (filled part = `--ink`, rest = `--rule`).
  - Visual panel: about 55% of the remaining height, `--panel` background, 1px `--rule` border, radius 2px, 16px side margin. Line art inside.
  - Text block below, 20px side padding: headline, then at most 2 sentences (about 30 words total).
  - Nothing else. No kickers, no MENTAL MODEL box, no badges, no captions under the visual, no buttons except where a card needs a control (play/pause is a small mono text link in the panel's corner, not a button).
- **Motion:** visuals start by themselves when their card is on screen and stop when it leaves. Quick bursts, eased (ease-in-out ~500ms per transition, ~1.1s hold per step, ~1.8s rest before the loop). Change pops: a part that appears, gains focus or moves gets a brief (~480ms) stroke-weight and glow pulse, appearing parts scale in from 0.9, arrows draw in tail to head. Only the explaining part moves. No bounces, no particles for decoration, honour `prefers-reduced-motion` (no pulses, instant states, allow stepping by tap).
- **Line art rules:** strokes `--ink` 1.25px (2px for the main part), fills `--panel` or `--paper`, cut surfaces as 45° hatching in `--rule`, labels in mono `--ink2` with a thin leader line to the part, no figure captions. Colour carries meaning and there is more of it: subject parts get a flat tinted fill (about 40% of the colour over the panel, no gradients) plus a coloured stroke (water/air/fuel-air = `--s-blue`, fire/burning/heat = `--s-heat`, OK = `--s-green`, ignition and energy flashes = `--s-spark`), and the one moving or important part is `--accent` (stroke plus a light tint). Ink parts stay panel-filled. Gears: driver light accent tint, driven light blue tint. Grey/ink for everything that is not the subject.

## 2. Navigation (shorts model)
- The page is a vertical feed of **topics**. Swipe up = next topic, swipe down = previous. Order is shuffled once per load (Fisher-Yates), except a `#<id>` hash puts that topic first.
- Each topic is a horizontal row of **cards**. Swipe left = next card, right = previous. Tapping the right 25% of the card (outside controls) = next card; left 25% = previous.
- Use native CSS scroll-snap (vertical container of topic slots, each slot a horizontal scroll-snap row). Mount only the current topic and its neighbours (±1); unmount others so canvases stop.
- Keyboard: ←/→ cards, ↑/↓ topics. Focus and aria-live announce "Topic name, card 3 of 8".
- **End card (`more`)** is the last card of every topic: "Go deeper" list of linked topic ids (tap = that topic slides in as the next vertical slot and the feed scrolls to it) + a mono hint "Swipe up for something new".
- A small mono "Index" link in the top bar opens a plain list of all topics (title + card count); tapping one jumps to it. This replaces the old home screen.
- Gestures must not fight: a drag that starts on an interactive visual (slider, draggable part) belongs to that visual, not the feed.

## 3. Topic data (v2)
```
window.EXPLAINER = {
  id: 'gearbox', title: 'How a gearbox works', kind: 'full' | 'bite',
  theme: 'machines' | 'nature' | 'internet' | 'money',
  cards: [ ... ]   // one idea: 2–4 cards, then more (kind 'bite'). 'full' + cover only for rare series openers. See RECIPE.md.
}
```
Card types (all others are removed, including intro, hook, predict, reveal, recall, branches):
- `cover`: `{ type:'cover', title, lead, visual }`. Big title over/under an ambient visual, one-line lead (under 90 chars), mono hint "Swipe ←". Full topics only; a bite starts with a `card`.
- `card`: `{ type:'card', title, text, takeaway?, visual }`. `text` = 1–2 sentences. `takeaway` = optional one sentence rendered bold right after `text` (counts toward the 30 words).
- `guess`: `{ type:'guess', title (the question), options:[2–3 strings], answer: index, why (1–2 sentences shown after tapping), visual? }`. Unscored: tapping any option marks the right one with an accent underline and a small mono "THIS ONE", dims the others, and fades in `why`. No RIGHT / NOT QUITE, no score, nothing stored. If `visual` is set it is shown after the tap (the reveal).
- `more`: `{ type:'more', links:[topic ids], note? }`. Last card. Titles come from the linked topics; unknown ids are skipped.

`visual` = `{ type: '<visual type>', ...params }`. Every visual type is a reusable renderer in `core/` that takes data in and hard-codes no topic text.

## 4. Visual types for the pilot
- Existing, restyled to line art: `crank` (engine cross-section, scrubbable), `strokes` (four-stroke sequence), `cylinders`, `gears` (ambient + interactive modes). Keep their parameters.
- New, generic: `diagram` — a small scene described in data, which covers process steps, cycle, before/after, flow and labelled reveal in one renderer:
  - `view: [w, h]` coordinate box (e.g. `[100, 62]`), scaled to fit the panel.
  - `parts: [{ id, shape: 'rect'|'circle'|'line'|'path'|'arrow'|'dot', ...geometry, style?: 'ink'|'thin'|'hatch'|'blue'|'heat'|'green'|'accent', label?, labelAt? }]`. Labels are mono with a leader line.
  - `steps: [{ show?:[ids], hide?:[ids], focus?:[ids], move?:{ id:[dx,dy] }, note? }]` — each step is a state; the renderer eases between states, auto-plays through them on a loop, and draws small mono step dots (tap a dot to jump). `note` is a short mono line in the panel corner (under 30 chars).
  - `flows: [{ along: [[x,y],...], style, count, speed, during?:[step indexes] }]` — dots moving along a path (air in, water out, data through a wire).
  - Optional `scrub: true` adds a thin slider under the panel that drives the steps by hand instead of auto-play.

## 5. Checks every agent runs before reporting
- `./build.sh library` (and `./build.sh <topic>` for a single topic) succeeds.
- Screenshot at 375x667 in light AND dark with the helper:
  `node /private/tmp/claude-501/-Users-saqlainmomin-tell-me-how/5aeba212-51a6-4448-bd31-27c848c2b041/scratchpad/pw/shot.mjs <abs path to dist/*.preview.html> <out.png> [light|dark]`
  (it prints console errors; there must be none). Look at the PNGs yourself. Nothing overflows, nothing overlaps, no horizontal scroll inside a card.
- Report what you could not finish or verify, plainly.
