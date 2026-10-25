# Tell Me How: card and visual catalogue (v2)

A topic is ONE data file, `topics/<id>.js`, that sets `window.EXPLAINER`. Build with `./build.sh <id>` (one-topic page) or `./build.sh library` (the shorts feed of every id in `LIBRARY` at the top of `build.mjs`). Output goes to `dist/<name>.html` (hosting-contract fragment) and `dist/<name>.preview.html` (same, in a normal document, for local testing). Binding spec: `tasks/pilot-spec.md`. Do not edit `core/` to write a topic; add a visual type only through section 6.

Target screen: phone, 375x667 up to 390x844. One card = one screen, no scrolling inside a card.

## 1. Topic shape

```js
window.EXPLAINER = {
  id: 'gearbox',                      // slug, equals the file name
  title: 'How does a gearbox work?',  // the topic's QUESTION (at most 12 words): the huge headline of card 1, a small line in the top bar on later cards; also <title> on a one-topic page
  kind: 'full',                       // 'bite' (1-2 content cards) or 'full' (3-6), then `more`; build lints the count
  theme: 'machines',                  // 'machines' | 'nature' | 'internet' | 'money' (build warns on anything else)
  cards: [ ... ]
};
```
A topic file may only run code that works in the browser and in Node's `vm` (the build evaluates it once to read title, kind, theme and card count). All text is plain strings (`textContent`, no HTML). No em dashes.

Look and tokens (Newsreader for reading, IBM Plex Mono only for labels/counter/hints, paper/panel/ink/ink2/rule/accent plus subject colours `--s-blue`, `--s-heat`, `--s-green` and the energy colour `--s-spark`) are fixed in `core/blocks.css` and not per topic. Light and dark follow `prefers-color-scheme` and `[data-theme]`.

## 2. Card types

Every card except `more` should read in about 30 words of text. Keep to it: the 375x667 card has no scroll. Anatomy of `card` and `guess`: a headline (`.lead`) above, the picture in the middle taking every spare pixel, the paragraph below. No dead space.

### `cover` (full topics only, first card)
`{ type:'cover', title, lead, visual }`. `title` 34px, about 60 chars max (3 lines). `lead` one line under 90 chars. Mono hint "Swipe ←" is added. Use an ambient visual (`crank` with `interactive:false`, or `gears`).

### `card`
`{ type:'card', title, text, takeaway?, visual }`. `title` is the headline above the picture (about 8 words, 26px). `text` is 1-2 short sentences under it. `takeaway` is an optional sentence set in semibold right after `text`; text + takeaway together are about 30 words. `visual` is required (see section 3).

**Opener (card 1 of every topic).** Its headline is the topic's `EXPLAINER.title` (the question, 33px). The card's own `title` becomes an optional smaller setup line under the question (one line of stakes); leave it out if the question says enough.

### `guess`
`{ type:'guess', title, options:[2-3 strings], answer, why, visual? }`. `title` is the question, set above the picture like any headline. `answer` is the index of the right option. `why` is 1-2 sentences. Unscored and nothing is stored: tapping any option underlines the right one in accent with a mono "THIS ONE", dims the others and fades in `why`. With `visual`, the panel (smaller, 36%) shows "Pick an answer to see it" first and the visual fades in after the tap; its animation only starts then.

### `more` (last card of every topic)
`{ type:'bridge', text }`. A text-only pause between two content cards: no headline, no picture, the text set big (24px) in the middle of the card. Not counted toward the 6 content cards.

`{ type:'more', links:[topic ids], note? }`. Shows "Go deeper" and one row per linked topic (title and card count come from the topic files; ids not in the build are skipped). Tapping a row slides that topic in as the next vertical slot and scrolls to it. A mono hint "Swipe up for something new" sits at the bottom (library build only).

Fallback: when `links` is empty, or none of its ids exists in the build (and the topic itself is never offered), `more` offers up to 3 OTHER topics of the library instead, topics with the same `theme` first, then any, in library order, under the same "Go deeper" heading. If there is nothing to offer at all (a one-topic build), the card shows just the `note` (if any) and the "Swipe up for something new" hint, centred on the card instead of a near-empty screen. So `links: []` is fine, and a topic does not need to list every neighbour.

## 3. Visual types

`visual = { type, ...params }`. Visuals are line art on a canvas in the card's panel: ink strokes (1.25px, 2px main part), panel fills, 45 degree hatching in `--rule` for cut surfaces, mono labels with leader lines, colour carries meaning, with confident tinted fills (about 40% of the colour over the panel) plus a coloured stroke: `--s-blue` water/air/fuel-air, `--s-heat` fire/heat/burning mix, `--s-green` living/OK, `--s-spark` (warm yellow, light #EDB10F / dark #FFD24A) only for sparks, flashes and energy, and `--accent` (stroke plus a light 25% tint) for the one moving or important part. In the engine visuals the fuel/air charge is blue, the burning mix is heat-orange, ignition is a short solid spark-yellow flash with rays at the plug, and the push is a bold heat arrow. In `gears` the driver has a light accent tint and the driven gear a light blue tint (the marked tooth stays solid). Helpers: `TMH.tint(colour, a)` (flat tint over the panel), `TMH.sparkFlash(ctx, x, y, r, k)`. They start when their card is on screen and stop when it leaves, and under `prefers-reduced-motion` they do not autoplay (the play link becomes "Step"). Animated ones get a small mono Play/Pause link in the panel's top-right corner.

### `crank`
Piston, rod and crank in a cylinder (no head).
| param | default | notes |
|---|---|---|
| interactive | true | true: drag the crank pin (accent, with a hint ring), Play/Pause link. false: quiet ambient spin, piston in accent |
| speed, start | 50, 40 | degrees per second, start angle (0 = top) |
| rodRatio | 3.2 | rod length / crank radius |
| parts | false | label piston, rod, crankshaft, cylinder with leader lines |
| guides | false | dashed TDC / BDC lines |
| hint | true | pulsing ring on the pin while untouched. The words come from the interaction cue (`tip`, see 3.1) |
| labels | | `{tdc, bdc, partPiston, partRod, partCrank, partCylinder}` overrides (uppercased) |

### `strokes`
Four-stroke cycle in a cylinder with head, valves and spark plug; the piston is accent; the mix is blue, burning is heat. Mono "3/4  POWER" in the corner. Drag the crank pin to scrub.
| param | default | notes |
|---|---|---|
| speed, start | 80, 440 | cycle degrees per second (cycle = 0..720), start position |
| only | | 0..3: loop a single stroke |
| strokes | Intake, Compression, Power, Exhaust | names, strings or `{name}` |
| intake, exhaust, ramp | `[0,190]`, `[530,720]`, 25 | valve-open windows |
| interactive | true | drag to scrub |
| labels | | `{intake, exhaust, spark, push}` text on the figure; pass `''` to hide one; `labels:false` hides all port labels |

### `cylinders`
Cylinders firing in order, plus a graph of the push on the crankshaft (heat) against its average.
| param | default | notes |
|---|---|---|
| options | required | `[{n, order:[1,3,4,2]}, ...]`; several = a count selector in the top-left, prefixed with the mono label `labels.unit` ("CYLINDERS") so the numbers are explained |
| selected | 0 | index into options |
| speed, rodRatio | 120, 3.2 | |
| graph | true | false: cylinders only, larger |
| hide | | `['segs','play']` |
| labels | | `{unit, graphTitle, average}` (`unit` is also the picker's label) |

### `gears`
Meshing involute spur gears. Driver gear is accent, marked teeth show the turning.
| param | default | notes |
|---|---|---|
| driving, driven | 14, 50 | tooth counts |
| speed, phase | 0.08, 0.6 | driver turns per second, start angle (rad) |
| interactive | false | true: drag the driver gear by hand (resumes after release), Play/Pause link |
| labels | | presence turns on the labelled version: `{driver, driven, teeth:'{n} teeth', gear}`. Labels sit under the gears, the name over the teeth line (no second line when `teeth` is `''`). They are measured and never overlap: pushed apart when the gear centres are close, and on very narrow panels the right one drops to its own row |
| count | false | needs `labels`. Adds a mono `LAPS n` counter under each gear (label `labels.laps`, default 'Laps'), counting whole turns from the actual rotation angle since the card was shown. The moment the slower gear completes a lap (the driven one for a speed-reducing pair) both counters turn `--accent` and fade back over 800 ms, hold that reading for 1.2 s, then both **reset to 0**, so a 12 to 36 pair reads 3 : 1 forever (a non-integer pair like 14 to 50 reads 3 : 1 too, just not exactly in step). Dragging the driver backwards clamps at 0. Under reduced motion the Step link turns the driver a quarter turn, and the counters follow. With `count: true` the default `speed` becomes 0.36 (one driver lap ~2.8 s); an explicit `speed` still wins, and `sets` keep their own `spin` speed. Costs one extra mono row under each label |
| sets, set, selected | | `sets:[{label, gears:[{name, driving, driven}], spin, rpmStart}]`; driving/driven then come from the selected gear; a mono picker (set labels, gear names) appears top-left when there is a choice AND `interactive: true`; with `interactive: false` there is no picker and the figure just shows the given `set` / `selected`. `spin * rpmStart/1000` = driver turns per second (clamped 0.03..0.3) |

The old slider, readouts, rpm band bar and ratio chips are gone.

### `diagram`
A small scene described in data: process steps, cycles, before/after, flows, labelled reveals. One renderer, no topic text in core. Line art like the others: strokes in screen px (2px main, 1.25px thin), mono uppercase labels with a thin leader line, subject colours for the subject only; fills are flat tints, never gradients.

Fields:
| param | default | notes |
|---|---|---|
| view | `[100, 100]` | `[w, h]` coordinate box for all geometry. Scaled to fit the drawing area (aspect kept, centred). The panel is nearly square (about 343x335 on a phone, minus a top strip for the dots and Play link and a bottom strip for the note and slider), so `[100, 96]` or `[100, 90]` fill it; a wide box like `[100, 62]` leaves empty bands |
| parts | `[]` | the shapes, drawn in list order (later on top), see below |
| steps | `[]` | states to move through. None = a static drawing (plus flows) |
| flows | `[]` | dots moving along a line, see below |
| scrub | false | a slider under the drawing drives the steps by hand; no auto-advance |

**Part** `{ id, shape, ...geometry, style?, label?, labelAt?, text?, hidden?, dash?, fill? }`, all geometry in view units:
| shape | geometry | notes |
|---|---|---|
| `rect` | `x, y, w, h` | top-left corner |
| `circle` | `x, y, r` | centre |
| `line` | `from:[x,y], to:[x,y]` (or `points`) | |
| `path` | `points:[[x,y],...]`, `closed?`, `smooth?` | `smooth` runs a curve through the points; `closed` joins the last to the first and makes it fillable. An open path is never filled |
| `arrow` | `from, to` (or `points`, head on the last segment) | head size is fixed in px |
| `dot` | `x, y, r?` | filled, `r` default 1.2 |
| `text` | `x, y, text` | no outline, only a mono label (see below) |

`id` is needed only for parts that steps refer to. `hidden: true` = starts invisible (a step must `show` it). `dash: true` = dashed stroke (chains, steam, guides). `fill: false` = outline only for a closed shape (closed shapes are filled with `--panel` so later parts hide what is behind them).

`style` (default `ink`):
| style | look |
|---|---|
| `ink` | 2px `--ink` stroke, panel fill: the main part |
| `thin` | 1.25px `--ink` stroke, panel fill |
| `hatch` | 45 degree hatching in `--rule`, 1.25px ink outline: a cut surface or ground |
| `blue`, `heat`, `green`, `spark` | the subject: strong tinted fill (42% of the colour over the panel), 1.75px stroke in `--s-blue` / `--s-heat` / `--s-green` / `--s-spark` (water, air, cold, data / fire, heat / living, OK / sparks, flashes, light, energy) |
| `accent` | 2px `--accent` stroke, light accent fill (26%): the one moving or important part. Use it once per card |

`spark` (warm yellow) is for sparks, flashes, light and energy only, never as a second accent.

Labels: `label: 'Water'` plus `labelAt: [x, y]` draws a mono uppercase label with a thin leader to the nearest edge of the part (the centre for a dot). `labelAt` is the OUTER end of the text: the text runs from `labelAt` toward the part, so a label to the right of a part is right-aligned at `labelAt`, one to the left is left-aligned. It is clamped to stay inside the panel. `text: '0 C'` (on any part, or on a `text` shape) draws a plain mono label with no leader, centred on `labelAt` if given, else on the part. Labels follow their part's visibility (a label shows once its part is more than half in and goes before it is half out) and focus dimming.

**Step** `{ show?:[ids], hide?:[ids], focus?:[ids], move?:{ id:[dx,dy] }, restyle?:{ id: style }, note? }`. Step 0 is the starting state; each step builds on the one before: `show` / `hide` / `move` persist into later steps. `move` is an offset in view units from the part's drawn position (absolute, so `[0,0]` puts it back; it does not add up from step to step). `restyle` changes a part's `style` from this step on (cumulative like `show` / `hide`: it persists into later steps, a later `restyle` of the same id replaces it, and the starting style is the part's own `style`). The change cross-fades stroke, fill colour and hatching over the same 500ms, e.g. `{ restyle: { w1: 'thin', w2: 'thin' } }` turns water molecules from `blue` to `thin` as they freeze. Unknown ids or styles throw at build. `focus` is NOT carried over: it applies to its own step only, and every part not listed dims to 25%. A step with no `focus` dims nothing. **`focus` dims every part not listed, `text` parts included** (and a part's label follows its part). A number or label you want to stay readable during a focused step must be listed in that step's `focus`, so give `text` parts an `id`. `note` is a short mono line (under 30 characters, 40 at most) at the bottom of the panel; it changes with its step: the old one fades out, then the new one fades in as the step lands. Unknown ids throw at build.
- Playing (quick bursts): opacity, focus and movement ease (ease-in-out, 500ms) between states. Auto-plays from step 0 when the card is shown: 1.1s hold per step, 1.8s at the last, then eases back to step 0 and loops. Timings live in `DG` at the top of the diagram code.
- Emphasis: a part that appears, newly gains `focus` or `move`s gets a 480ms pulse (stroke weight up to 1.7x with a glow in its own colour, fading out); a part that appears also scales in from 0.9. An `arrow` that appears is drawn in from tail to head over the same 500ms (and retracts when hidden). Nothing else pulses. Under `prefers-reduced-motion` there are no pulses, no draw-in and states change instantly. Not applied while scrubbing. Small step dots sit top-left (current one in accent); tapping a dot jumps there and pauses (the Play link resumes). With one step or none there are no dots.
- `scrub: true`: a hairline track with a tick per step and a small accent thumb sits under the drawing; dragging it blends between neighbouring steps by hand and does not move the feed or the card row (the press only counts as the visual's when it lands on the slider or a dot, like the other drags). Auto-advance is off; flows still run and the Play/Pause link only pauses them. Dots work as jumps.

**Flow** `{ along:[[x,y],...], style?, count?, speed?, size?, during? }`: `count` (default 4) dots evenly spaced along the polyline, in `style`'s colour (default `accent`; `ink` / `thin` draw in ink), moving at a steady `speed` (view units per second, default 16, looping) and fading in and out over the ends. `size` is the dot radius in px (4.2), drawn solid in the colour with a thin panel-colour ring so it reads over fills. `during:[step indexes]` = only run (faded in and out with the step change) in those steps; omit for always. Flows are not affected by `focus`.

Controls: small mono Play/Pause link top-right when there is more than one step or any flow. Reduced motion: nothing autoplays, step 0 is shown, the link reads "Step" and each tap moves to the next step (no easing), flows are static dots at their start positions. The scrub slider and the dots still work by hand.

Example (a process with focus and a flow):
```js
visual: { type: 'diagram', view: [100, 96],
  parts: [
    { id: 'water', shape: 'rect', x: 29, y: 46, w: 42, h: 32, style: 'blue', hidden: true, label: 'Water', labelAt: [98, 62] },
    { id: 'pot', shape: 'path', points: [[28, 26], [28, 78], [72, 78], [72, 26]], fill: false },
    { id: 'base', shape: 'rect', x: 24, y: 78, w: 52, h: 6, style: 'hatch' },
    { id: 'heat', shape: 'arrow', from: [50, 95], to: [50, 87], style: 'heat', hidden: true, label: 'Heat', labelAt: [2, 91] }
  ],
  steps: [
    { show: ['water'], note: 'Cold water goes in' },
    { show: ['heat'], focus: ['heat', 'base'], note: 'Heat warms the bottom' }
  ],
  flows: [ { along: [[50, 4], [50, 52]], style: 'blue', count: 3, speed: 20, during: [0] } ] }
```
More in `topics/_demo3.js` (a four step kettle with flows; a scrubbed bike chain before/after).

Authoring tips:
- Pick a `view` box near the panel's shape (about square). Draw big: the idea should read at arm's length.
- Labels: 1 to 3 words (`Water`, not `Cold water in the kettle`). Put `labelAt` in empty space outside the drawing, at the outer end; keep long labels away from other parts. Check no two labels cross in any step (a part that fades out takes its label with it).
- At most about 5 steps, one moving idea per card. Step 0 should already be a meaningful picture (it is what reduced motion shows).
- Draw the whole scene once and use `hidden` / `show` / `focus` to direct attention, rather than redrawing it per step. For before/after, hide one version and show the other (it cross-fades) or `move` the one changing part.
- Use `accent` once, for the part the card is about; use subject colours only for the subject.
- Moving things (water, air, data, bubbles) are `flows`, not steps. Each flow is a straight or bent line; use one flow per lane.
- For `scrub: true` prefer 2 to 4 states that are each a clear picture; the slider blends between them.

### 3.1 Interaction cue (`tip`)
Every visual a reader can touch shows a small dark pill on the picture's bottom edge (half outside the panel, so it never covers labels) saying what to do. It fades in 0.7s after the card is shown, fades out after about 6s or on the first touch (drag, Play/Pause or dot), and is never shown again in the session once the reader has dragged any visual (`learned`). A visual they already touched shows no cue on revisit. Under reduced motion it still appears, without the pulsing dot. Built-in defaults, from `UI.tips` in `core/blocks.js`:
| visual | when | default text |
|---|---|---|
| `crank` | `interactive` (default) | Drag the crank |
| `strokes` | `interactive` (default) | Drag to turn the engine |
| `gears` | `interactive: true` | Drag the gear to turn it |
| `cylinders` | more than one `options` and the picker visible | Tap a number to compare |
| `diagram` | `scrub: true` / 3 or more steps | Drag the slider / Tap a dot to jump |
Override with `tip: 'Verb first, 4 words or fewer'` in the visual's params; `tip: false` removes it. Add one to a new visual with `cue(panel, sim, tipOf(c, UI.tips.x))` after its controls (section 6).

## 4. Navigation (core/library.js)

- Vertical scroll-snap feed of topic slots. Order is shuffled once per load; `#<id>` in the URL puts that topic first. The hash follows the current topic (`replaceState`).
- Each slot is: top bar (the topic question as one small grey line, hidden on card 1 where the card shows it huge, plus the "Index" link), a 1px rule, a horizontal scroll-snap row of cards, then page dots (one per card, the current one a longer `--accent` pill; on card 1 a mono "Swipe →" hint nudges at the right). The dots are the only progress indicator.
- Card layout: headline above, then the panel, then the text. The panel takes all spare height (never under 30% of the card), so there is no dead space; text sits directly under it with room for the cue pill.
- Swipe up/down = topic, swipe left/right = card. Tap the right 25% of a card = next card, left 25% = previous (taps on buttons, links and the tap that ends a drag are ignored). Keyboard: left/right cards, up/down topics, Escape closes the index.
- Only the current topic and its neighbours (+-1) are mounted; the others are torn down so their canvases stop. A visual runs only while its card is the shown card of the current topic.
- An announcer (`aria-live`) says "Topic name, card 3 of 8".
- Index: plain list of all topics (title, card count) over the feed; tapping one jumps there.
- A `more` link moves the linked topic to be the slot right after the current one and scrolls to it.
- One-topic build (`./build.sh <id>`): same code with a single slot, no vertical feed, no Index link, `more` shows only its note and the "Swipe up for something new" hint (nothing to link to).
- Focus: the feed, the card row and the index can take focus (tap, or after keyboard use) but never show a browser ring around a whole card; `:focus-visible` shows only a quiet 1px `--rule` inset line. Real controls (buttons, links, options) keep a 2px `--ink` ring on `:focus-visible`.
- Interactive drags: the visual's canvas calls `preventDefault` on `touchstart` only when the press lands on its draggable, so everywhere else sideways swipes still move cards and vertical swipes still move the feed.

Library build data: `LIBRARY` in `build.mjs` is just a list of topic ids. Title, kind, theme and card count are read from each topic file. The build warns about topic files not listed.

## 5. Lifecycle API (window.TMH)

- `TMH.build(EXPLAINER)` returns `{cards, show(active, index), refresh(), destroy()}`: it renders every card; `show` marks which card is on screen (its visuals run, others stop); `destroy` disconnects ResizeObservers and sims and releases the shared rAF loop and theme listeners (reference counted per built topic).
- Host hooks `TMH.ctx = {has(id), info(id) -> {title, cards, theme}, others(id) -> [{id, title, cards, theme}], open(id), single}` are set by `core/library.js` and used by `more` (`others` is the fallback pool, empty on a one-topic page).
- `TMH.debug()`: `{loop (0|1), holds, sims}` for leak checks.
- Helpers for visual authors: `h`, `makeCanvas`, `addSim`, `playLink`, `autoplay`, `attachDrag`, `relPos`, `clearPanel`, `mono`, `monoW`, `leader`, `hatchRect`, `bar`, `disc`, `drawEngine`, `theme`, `rgba`, `mixc`, `clamp`, `reducedMotion`, `fmt`, `ui`.

## 6. Adding a visual type

A visual is a function in `TMH.visuals` that receives the panel element, its params and the card element. It creates its canvas, registers a sim and (optionally) controls. Cards, feed, visibility and teardown are automatic.

1. In `core/blocks.js`, next to the others, write `V.mything = function (panel, c, card) {...}` and document it in section 3 here. Visuals live in core (reusable, no topic text); there is no topic-local registration.
2. Use it from data: `visual: { type: 'mything', ...params }`. An unknown type throws at build.

### 6.1 Signature and canvas lifecycle
```js
V.mything = function (panel, c, card) {
  const P = Object.assign({ speed: 1 /* defaults for every optional param */ }, c);
  let t = 0, sim;                                  // declare sim first: a sized host fits (and calls back) inside makeCanvas
  const cv = TMH.makeCanvas(panel, () => sim && sim.draw());   // {cv, ctx, w, h, dpr}; fills the panel, handles DPR and resize
  sim = TMH.addSim(card, {
    update(dt) { t += dt * P.speed; },             // dt in seconds, capped at 0.05; called only while visible && playing
    draw() {                                       // CSS pixels, size cv.w x cv.h; must work at any state
      if (!cv.w) return;
      const T = TMH.theme;                         // live tokens: paper panel ink ink2 rule accent blue heat green
      TMH.clearPanel(cv.ctx, cv.w, cv.h);
      /* ink 1.25px, hatch with TMH.hatchRect, labels with TMH.mono / TMH.leader */
    },
    onShow() { TMH.autoplay(sim); }                // card came on screen: start by itself (skipped under reduced motion or after a touch)
  });
  TMH.playLink(panel, sim, () => { t += 1; });     // optional Play/Pause link (Step under reduced motion); the callback is the step
};
```
- `sim.visible` is set by the feed when the card is the shown card of the current topic. The shared loop calls `update` when `visible && playing`, and `draw` after that, or every frame if `sim.alwaysDraw` is set. When you change state from a handler set `sim.playing = false; sim.touched = true; sim.syncUI && sim.syncUI(); sim.draw()`.
- Never hard-code colours; read `TMH.theme` inside `draw()` (it refreshes on theme change and every sim is redrawn). Use `rgba(color, a)` and `mixc(a, b, t)`.
- Reduced motion: do not autoplay; give a meaningful static first frame (one frame of every sim is drawn at build) and make the step callback advance the state.

### 6.2 Pointer/touch drag pattern
`TMH.attachDrag(cv.cv, sim, { hit(e), start(e), move(e), resume? })` implements it: `touchstart` is cancelled only when `hit` is true (so feed and row still pan elsewhere), the pointer is captured, the sim pauses, `move` updates state, the tap that ends a drag does not trigger card navigation. Convert coordinates with `TMH.relPos(cv.cv, e)`, and treat angles with wrap-around (`d > 180 ? d -= 360`). Always give the part a visible affordance (the accent colour, a hint ring).

### 6.3 Checklist
1. All text and numbers from params, defaults for every optional one.
2. Theme tokens only; check light and dark.
3. 375x667: nothing overflows or overlaps inside the panel, no horizontal scroll in the card.
4. Controls (if any) are small mono text links in the panel corners, not buttons; they are real `<button>`s with accessible names.
5. Reduced motion, DPR 1 to 3, resize.
6. Document the params in section 3.
7. `./build.sh library`, screenshot at 375x667 light and dark, zero console errors.

## 7. Build and test
```
./build.sh library        # the feed of every topic in LIBRARY
./build.sh <id>           # one-topic page
```
Open `dist/<name>.preview.html` (add `#<id>` in the library to start on a topic). `dist/<name>.html` follows the hosting contract: no doctype/html/head/body, starts with `<title>`, the viewport meta, the fonts `<link>`, one `<style>`, the markup and one `<script>` (core, topic data, `core/library.js`). Fixtures: `topics/_demo.js` (full, every card and visual type) and `topics/_demo2.js` (bite), `topics/_demo3.js` (bite, `diagram`).
