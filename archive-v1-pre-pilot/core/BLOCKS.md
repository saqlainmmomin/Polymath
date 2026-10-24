# Tell Me How: block catalogue

A topic is ONE data file, `topics/<name>.js`, that sets `window.EXPLAINER = {...}`. Build with `./build.sh <name>` (from `tell-me-how/`). Output: `dist/<name>.html` (hosting-contract fragment) and `dist/<name>.preview.html` (same, in a normal document, for local testing). Nothing else is needed to make a topic. Do not edit `core/` unless you are adding a block (last section).

Target screen: phone, 375x667 up to 390x844, one card per screen, swipe up. Content column is 343px wide at 375 (16px side padding, max 480px on wide screens). Cards scroll inside themselves if they overflow, but design so they do not.

## 1. Top-level shape

```js
window.EXPLAINER = {
  id: 'car-engine',                       // string, required, slug (not shown)
  title: 'How a Car Engine Works',        // string, required. Becomes the page <title>.
  ariaLabel: 'How a car engine works. Swipe up through the cards.', // optional. Default: title + ". Swipe up through the cards."
  ui: { /* optional overrides of generic UI strings, section 2 */ },
  cards: [ /* ordered card objects, each { type, ... }, section 3 */ ]
};
```

Rules:
- The first card should be `intro`. It is not counted: the HUD shows "Intro" on it, then `01 / NN` on the rest, with one progress segment per counted card.
- Unknown `type` throws at mount (`TMH: unknown card type`).
- Fonts are global (Big Shoulders Display for headings, Public Sans body, IBM Plex Mono for labels). Not configurable per topic.
- All text is plain strings set with `textContent`. No HTML. Use real typographic characters (curly apostrophe, middle dot) directly or as `\u` escapes. Do not use em dashes.
- The page works in light and dark automatically (CSS tokens, canvas reads them).

## 2. Generic UI strings (`EXPLAINER.ui`, all optional)

Defaults shown. Override only to translate or re-voice.

| key | default | where |
|---|---|---|
| modelLabel | `MENTAL MODEL` | small label above every model line |
| cue | `Swipe up` | scroll cue under predict/hook/recall-end (card-level `cue` overrides on hook/predict/recall) |
| right / answer / notQuite | `RIGHT` / `ANSWER` / `NOT QUITE` | tags on answered options |
| bonus | `BONUS` | label of the reveal bonus box |
| play / pause | `Play` / `Pause` | animation button text |
| playAria / pauseAria | `Play animation` / `Pause animation` | its aria-label |
| intro | `Intro` | HUD text on the cover |
| score | `YOUR SCORE` | recall result heading |
| tryAgain | `Try again` | recall restart button |
| seeScore / nextQuestion | `See score` / `Next question` | recall button |
| questionOf | `QUESTION {i} OF {n}` | recall step label (tokens `{i}`, `{n}`) |
| rightPrefix / notQuitePrefix | `RIGHT. ` / `NOT QUITE. ` | start of recall feedback line (keep trailing space) |
| recallClosing | "Pulling it from memory is what makes it stick. ..." | recall result paragraph (card-level `closing` overrides) |
| go | `Read this one` | line under a branches item that has an `href` (card-level `go` overrides) |

## 3. Card types

Common fields on most cards: `type` (required), `kicker` (string, small orange caps label above the title; keep under about 24 chars), `model` (string, one-line takeaway shown in the MENTAL MODEL box). Text length guidance below is for 375x667; keep to it and nothing overflows.

Option letters are A, B, C, D by position.

### 3.1 `intro` (cover)
Use: first card only. Headline, how-to-use hints, Start button.

| field | type | req | notes |
|---|---|---|---|
| kicker | string | yes | topic name, under 28 chars |
| headline | array of `{t: string, em?: true}` | yes | h1. `em` parts render accent colour. Total under 50 chars, 2 to 3 lines. |
| meta | string | yes | lead paragraph. Token `{n}` becomes the counted card total. Under 110 chars. |
| hows | array of `{k, t}` | no | up to 3 rows. `k` bold label under 14 chars, `t` under 40 chars. |
| start | string | yes | button label, e.g. "Start" |
| title | string | no | only used as aria-label (default kicker) |
| visual | `'crank'`, `'gears'` or `'none'` | no | default `'none'`. `'crank'` shows the quiet spinning engine crank (engine-themed). `'gears'` shows an ambient meshing gear pair, no labels or controls, static under reduced motion; `params: {driving?: 14, driven?: 50, speed?: 0.08 (driver turns/s)}` (tooth counts, 14 or more driving). Avoid `'none'`: it leaves a large empty gap. |
| params | `{speed?: 40, start?: 40, rodRatio?: 3.2}` | no | only for `visual:'crank'` (deg/s, start angle) |

### 3.2 `hook`
Use: card 2. A surprising number or claim, a question, and an expandable "where does it come from" calculation.

| field | type | req | notes |
|---|---|---|---|
| kicker | string | yes | |
| headline | array of `{t, em?}` | yes | h1; one `em` run for the punchline. Under 90 chars. |
| question | string | yes | bold lead under the visual. Under 80 chars. |
| mathLabel | string | if `math` | summary text of the details toggle. Under 40 chars. |
| math | string[] | no | 2 to 4 short paragraphs revealed on tap. Under 90 chars each. Omit to hide the toggle. |
| fig | string | no | caption chip on the visual, caps, e.g. `FIG. 0 / RUNNING ENGINE`. Only drawn with a visual. |
| cue | string | no | default `ui.cue` |
| visual | `'engine-cycle'`, `'gears'` or `'none'` | no | default `'none'`. `'engine-cycle'` runs the four-stroke cylinder. `'gears'` shows the ambient meshing gear pair (params `{driving, driven, speed}` as for intro; `fig` caption is drawn on it). |
| params | `{intake:[a,b], exhaust:[a,b], ramp, speed, start, rodRatio}` | no | engine-cycle only; valve-open windows in crank degrees 0..720, defaults `[0,190]`, `[530,720]`, 25, 90, 420, 3.2 |
| labels | `{push, tdc, bdc, stroke, drag, intake, exhaust, spark}` | no | canvas text, defaults in section 4 |

### 3.3 `predict`
Use: ask the learner to guess before the explanation. After a pick, only the picked and correct options stay, each showing its `why`.

| field | type | req | notes |
|---|---|---|---|
| kicker | string | yes | usually "Predict first" |
| q | string | yes | question (h2). Under 60 chars. |
| lead | string | yes | prompt line, hidden after answering. Under 60 chars. |
| options | array of `{t, ok?: true, why?}` | yes | **2 to 4** (A to D). Exactly one has `ok: true`. `t` under 55 chars (2 lines max). `why` under 150 chars; shown after answering for the picked and correct options. Give every WRONG option a `why`; the correct one may omit it if `model` covers it. |
| model | string | yes | revealed with a swipe cue. Under 60 chars. |
| cue | string | no | default `ui.cue` |

Layout: options share the card height equally; 4 options with 2-line text fits at 375x667.

### 3.4 `reveal`
Use: a second guess whose answer is explained with prose plus an optional interactive visual. Same option rules as `predict`, plus explanation.

| field | type | req | notes |
|---|---|---|---|
| kicker, q, lead, options | as `predict` | yes | **2 to 4** options. Wrong options need `why`; the correct one usually omits it (the explanation covers it). |
| explain | string | yes | 2 to 4 sentences, under 280 chars |
| bonus | string | no | dashed box labelled `ui.bonus`. Under 130 chars. Omit to hide. |
| model | string | no | under 60 chars |
| fig | string | no | caption on the mini visual |
| viz | object | no | slider + canvas visual. Omit for text-only reveal. |

`viz` (kind `'compression'`: a gas column squeezed by a piston with a pressure gauge; reusable for any "ratio vs result" idea):

| field | type | default | notes |
|---|---|---|---|
| kind | `'compression'` | required | only kind that exists |
| label | string | required | visually hidden label of the slider (accessibility), e.g. "Squeeze ratio" |
| min, max, start | number | 1, 10, 1 | slider range. The gas column height is `min/value` of the box, so `min` should be the "uncompressed" value. |
| step | number | 0.1 | |
| decimals | number | 1 | decimals shown in the readout (trailing `.0` is trimmed) |
| durationMs | number | 1400 | auto-tween from `start` to `max` after answering |
| format | string | `'{v}'` | readout text, token `{v}`, e.g. `'{v} : 1'` |
| gauge | object | none (no gauge) | `{title: [line1, line2?], unit, prefix?, exponent, scale, full}`. Bar value = `value^exponent * scale`; bar fills `value/full` of the gauge height. Label reads `prefix + round(value) + ' ' + unit`. Each title line under 14 chars. |

Layout: the card is dense. Keep `explain` + `bonus` + `model` within the lengths above.

Optional no-guess mode: omit `options` (and `lead` becomes the first, smaller line under the title `q`). The card is then a plain explainer: `explain`, the `viz` slider visual, `bonus` and `model` show at once, and the viz plays its auto-tween when the card comes into view. Pair it with a `predict` card before it for the guess (split "predict" from "see it", see RECIPE screen budget). `explain` and `model` are both optional.

### 3.5 `sim-crank` (engine block)
Use: draggable slider-crank: the learner drags the crank pin and watches the piston. Teaches turning linear motion into rotation.

| field | type | req | notes |
|---|---|---|---|
| kicker | string | yes | e.g. "Fig. 1" |
| title | string | yes | h2, under 22 chars |
| lead | string | yes | instruction. Under 130 chars. |
| model | string | yes | |
| fig | string | no | caption chip on the canvas |
| params | `{rodRatio?: 3.2, speed?: 50, start?: 40}` | no | rod length / crank radius; auto-spin deg/s; start angle |
| labels | object | no | all optional: `sliderLabel, crank, piston, travel, top, bottom, down, up, travelUnit, tdc, bdc, stroke, drag, push, partPiston, partRod, partCrank, partCylinder` (defaults in section 4) |

`model` is optional. `params.hide` (optional array, default none, so existing cards render identically): `'fig'` (caption chip), `'readout'` (all three readouts), `'stat0'`/`'stat1'`/`'stat2'` (CRANK angle / PISTON direction / TRAVEL %; the rest stay), `'guides'` (TDC/BDC lines and the stroke ruler), `'arc'` (angle arc), `'hint'` (pulsing DRAG ring and label), `'play'`, `'slider'` (with both hidden the control row disappears). `params.parts: true` draws plain-word part labels with leader lines (PISTON, ROD, CRANKSHAFT, CYLINDER; text from `labels.part*`, an empty string drops one): a "meet the parts" card is `{parts: true, hide: ['readout','guides','arc','hint','slider']}`.

### 3.6 `sequence` (engine block)
Use: the four-stroke cycle. Full cylinder cross-section with valves, spark plug, gas colour, play/pause, scrubber, per-stroke chips and text. Exactly 4 strokes (180 degrees each, 720 total); the gas physics is fixed to petrol-engine timing.

| field | type | req | notes |
|---|---|---|---|
| kicker, title | string | yes | the header renders `kicker · title`; title also an sr-only h2 |
| strokes | array of exactly 4 `{name, word, gas, text}` | yes | in cycle order. `name` stroke name (shown huge, under 12 chars). `word` chip label (under 9 chars). `gas` one of `mix`, `mixhi`, `burn`, `exh` (chip swatch colour token). `text` under 110 chars (3 lines). |
| model | string | yes | |
| fig | string | no | |
| lead | string | no | unused by the layout (kept for symmetry; may be `''`) |
| params | `{intake:[a,b], exhaust:[a,b], ramp, speed, start, rodRatio}` | no | defaults `[0,190]`, `[530,720]`, 25, 80, 440, 3.2 |
| labels | object | no | `sliderLabel, chipsLabel, strokeOf ('STROKE {i} OF {n}'), cycle ('CRANK {deg}° OF 720°'), intake, exhaust, spark, push, tdc, bdc, stroke, drag`. An empty string hides that canvas label (e.g. `spark: ''` until the spark plug has been explained). |

Optional, defaults unchanged: `lead` (if non-empty) is shown as a small line under the header. `model` is optional. `params.hide`: `'fig'`, `'bar'` (big stroke name and counter), `'count'` (just the "STROKE i OF n / CRANK deg" counter), `'chips'`, `'play'`, `'slider'`, `'desc'` (per-stroke text). `params.only: 0..3` makes a one-stroke card: the animation loops that stroke, the scrubber covers only it, the header is a normal title (`title`, `kicker`) plus `lead`, and `bar`, `chips` and `desc` are hidden. One card per stroke: `{type:'sequence', kicker:'Stroke 1/4', title:'Intake: breathe in', lead:'...', strokes, params:{only:0, speed:60}, labels:{intake:'INTAKE VALVE', exhaust:'', spark:''}}`. `strokes` is still required (4 entries) even though only one is used.

### 3.7 `sim-cylinders` (engine block)
Use: compare cylinder counts: cylinders animate by firing order over a torque graph that shows how smooth the push is.

| field | type | req | notes |
|---|---|---|---|
| kicker, title, lead, model | string | yes | lead under 130 chars |
| options | array of `{n, order, unit?}` | yes | **up to 3** (they sit in a 3-column button row). `n` cylinder count (1 to 8 fit). `order` is the firing order: array of `n` cylinder numbers 1..n, each once. `unit` overrides the small suffix (default `labels.unit`). |
| params | `{speed?: 120, selected?: 1, rodRatio?: 3.2}` | no | animation deg/s; index of initially selected option; rod ratio of the torque model |
| labels | object | no | `groupLabel, unit, order, peak, peakUnit, graphTitle, now, average` (defaults in section 4) |

The readout "peak push" = peak torque / average torque, computed live. The drawn rod ratio is fixed at 3.

`params.hide` (optional array, default none): `'graph'` (drop the push graph; the cylinders get the stage, centred and larger), `'segs'` (the count buttons; use one option for a "see it" card), `'play'`, `'order'` (ORDER readout), `'peak'` (PEAK PUSH readout). With `order` and `peak` both hidden the readout disappears; with everything hidden the control row disappears. `model` is optional.

### 3.7b `sim-gears` (generic block)
Use: two spur gears with real involute teeth meshing. The learner picks a gear (and optionally a vehicle), drags the driver or a slider, and watches the driven gear turn slower or faster, with live readouts. Teaches "gears trade speed for force". Topic-agnostic: all names, numbers and labels come from the card.

| field | type | req | notes |
|---|---|---|---|
| kicker, title, lead, model | string | yes | title under 22 chars, lead under 130 chars (one line, under 50 chars, buys a taller stage when `mode:'speed'`) |
| fig | string | no | caption chip on the canvas |
| sets | array of set objects | yes | 1 or more. 2 or more shows a toggle row (`label` is its button text, keep each under 12 chars). Max 3. |
| params | `{mode?: 'rpm', set?: 0, selected?: 0, bar?: bool}` | no | `mode` `'rpm'`: the slider sets engine rpm, readouts ENGINE / OUTPUT / TORQUE. `'speed'`: the slider sets road speed, engine rpm is derived from gear x final drive x wheel size, readouts ROAD SPEED / ENGINE / WHEEL TORQUE. `set` and `selected` are initial set and gear indices. `bar` shows the rpm-band bar on top of the canvas (default: true in `speed` mode, false in `rpm`; needs `band`). |

Set object:

| field | type | req | notes |
|---|---|---|---|
| label | string | if 2+ sets | toggle button text |
| gears | array of `{name, driving, driven}` | yes | **up to 6** (one button each). `name` button text (1 to 2 chars). `driving` and `driven` are tooth counts of the driver and the driven gear, integers about 12 to 60. Ratio = driven / driving, exactly, both on screen and in readouts. Keep `driving + driven` equal across gears so the two shafts stay in place; if not, the gear pair re-centres on every change. Use 14 or more teeth on the smaller gear (fewer looks undercut). |
| final | number | no | extra fixed reduction after the gearbox (final drive). Default 1. Only used in `speed` mode. |
| wheel | number | speed mode | wheel circumference in metres. |
| band | `[lo, hi]` rpm | no | good engine range, drawn on the bar. |
| redline | number | no | rpm where the bar turns red. |
| idle | number | no | in `speed` mode engine rpm never reads below this; the bar says "clutch slips". |
| scaleMax | number | no | rpm at the right end of the bar. Default `redline * 1.18`. |
| rpmMax, rpmStart, rpmStep | number | no | `rpm` mode slider. Defaults `redline or 6000`, 2000, 100. |
| speedMax, speedStart | number | no | `speed` mode slider, km/h. Defaults 180, 20. |
| spin | number | no | on-screen driver turns per second per 1,000 engine rpm (slow motion). Default 0.2. Keep the driver under about 1.5 turns per second at the top rpm or fast teeth look like they run backwards (use about 0.08 for 14,000 rpm). |

`params.hide` (optional array, default none, so existing topics render identically) removes chrome that is not the card's point: `'legend'` (the DRIVER/DRIVEN tooth-count captions and the slow-motion note), `'slowmo'` (just the note), `'fig'` (caption chip), `'readout'` (all three readouts), `'stat0'`/`'stat1'`/`'stat2'` (one readout each; the rest share the row), `'gears'` (gear buttons), `'slider'`, `'play'` (Play/Pause button). With both `'slider'` and `'play'` hidden the control row disappears. `model` is optional on `sim-gears`, `predict` (and `reveal`): omit it on cards where the idea does not land (see RECIPE screen budget). The driver gear can still be dragged.

`labels` (all optional, canvas text is 10px mono caps, keep each under 16 chars; readout captions under 14):

```
engine 'ENGINE', output 'OUTPUT', torque 'TORQUE', road 'ROAD SPEED', wheelTorque 'WHEEL TORQUE',
rpm 'RPM', kmh 'KM/H', times '×', driver 'DRIVER', driven 'DRIVEN', teeth '{n} TEETH', slowmo 'SLOW MOTION' (empty string hides it),
band 'GOOD RANGE', ok 'IN RANGE', low 'TOO LOW', over 'TOO FAST', slip 'CLUTCH SLIPS',
sliderRpm 'Engine speed in rpm', sliderSpeed 'Road speed in km/h' (sr-only slider label),
gearsGroup 'Gear', gear 'Gear {n}, ratio {r} to 1' (aria-label of each gear button), setsGroup 'Vehicle'
```

Behaviour: autoplays when the card is 50% in view (not with reduced motion); Play/Pause button. Dragging the small (driver) gear turns it by hand and the driven gear follows; only the driver captures touches, so swipes elsewhere on the canvas still scroll the feed. The slider drives speed, it does not pause the animation. Gears turn in opposite directions (arrows) and a marked orange tooth on each makes the speed difference visible. Layout needs about 237px of stage height in `speed` mode at 375x667 (150px minimum, flexible). The torque readout is the pure ratio (friction ignored).

```js
{ type: 'sim-gears', kicker: 'Fig. 1', title: 'Speed for force', lead: '...', model: '...',
  params: { mode: 'speed' },
  sets: [{ label: 'Car', gears: [{ name: '1', driving: 14, driven: 50 }, { name: '2', driving: 20, driven: 44 }],
           final: 3.9, wheel: 1.98, band: [1500, 6000], redline: 6500, idle: 800, speedMax: 180 }] }
```

### 3.8 `recall`
Use: closing quiz, one question at a time, then a score with retry.

| field | type | req | notes |
|---|---|---|---|
| kicker, title, lead | string | yes | lead under 100 chars |
| questions | array of `{q, options, a, why}` | yes | 3 to 5 questions recommended. `q` under 70 chars. `options` string[] **2 to 4**, each under 45 chars (2 lines). `a` zero-based index of the right option. `why` under 110 chars, shown after answering. |
| closing | string | no | text on the result screen; default `ui.recallClosing` |
| cue | string | no | default `ui.cue` |

### 3.9 `branches`
Use: last card. "Where next" list. Items without `href` are votes (toggle shows `soon`). Items with `href` are real links to another published topic, same tab.

| field | type | req | notes |
|---|---|---|---|
| kicker, title, lead | string | yes | |
| items | array of `string` or `{t, href?, topic?}` | yes | **up to 5** (more squeeze). `t` under 60 chars (2 lines). `href` URL string: renders `<a href>`, same tab, with a line `go` below. `topic` (optional, id of a sibling topic, e.g. `'gearbox'`): in the library build the item links in-page to `#gearbox` instead of `href`; standalone builds ignore it and use `href` (so keep both). |
| soon | string | yes if any item lacks `href` | shown under a tapped vote item. Under 50 chars. |
| go | string | no | line under linked items, default `ui.go` |
| restart | string | yes | button label that rebuilds the whole feed and scrolls to the top |

## 4. Canvas label defaults (engine blocks)

```
engine cross-section (hook, sim-crank, sequence): tdc 'TDC', bdc 'BDC', stroke 'STROKE', push 'PUSH', drag 'DRAG', intake 'INTAKE', exhaust 'EXHAUST', spark 'SPARK PLUG'
sim-crank readout: sliderLabel 'Crank angle in degrees', crank 'CRANK', piston 'PISTON', travel 'TRAVEL', top 'TOP (TDC)', bottom 'BOTTOM (BDC)', down 'MOVING DOWN', up 'MOVING UP', travelUnit '% DOWN', partPiston 'PISTON', partRod 'ROD', partCrank 'CRANKSHAFT', partCylinder 'CYLINDER' (only drawn with params.parts)
sequence: sliderLabel 'Engine cycle position, 0 to 720 degrees of crank turn', chipsLabel 'Jump to a stroke', strokeOf 'STROKE {i} OF {n}', cycle 'CRANK {deg}° OF 720°'
sim-cylinders: groupLabel 'Number of cylinders', unit 'CYL', order 'ORDER', peak 'PEAK PUSH', peakUnit 'x AVERAGE', graphTitle 'PUSH ON THE CRANKSHAFT', now 'NOW', average 'AVERAGE'
```
Canvas text is 10px mono caps: keep each label under 14 chars. The engine blocks are engine-specific; a non-engine topic should not use `sim-crank`, `sequence`, `sim-cylinders`, `hook.visual='engine-cycle'` or `intro.visual='crank'`. It still gets `intro`, `hook` (visual `none`), `predict`, `reveal` (without `viz`, or with the generic compression viz), `recall`, `branches`, and any new block you add.

sim-gears canvas labels: see section 3.7b.

## 5. Card recipe (convention, not enforced)
intro, hook, predict, one or two sim blocks each followed by a guess (`reveal`), recall, branches. About 8 counted cards, 3 minutes. One idea per card. Guess before answer.

## 6. Adding a new block

A block is a function in `TMH.blocks` (`R`) that takes the card data `c` and returns the card's root element (a `<section class="card">`). The feed, HUD, progress and visibility handling are automatic. Two ways to add one:

1. Permanent: add `R['my-block'] = function (c) {...}` inside `core/blocks.js` next to the others (before the "build / feed / progress" section), and its CSS to `core/blocks.css`. Document its schema in this file.
2. Topic-local: at the top of `topics/<name>.js`, before `window.EXPLAINER`, write `TMH.blocks['my-block'] = function (c) {...}`. `core/blocks.js` runs first so `TMH` exists. Promote to core when a second topic needs it.

### 6.1 Signature and layout
```js
R['my-block'] = function (c, index) {
  const stage = TMH.stageBox(c.fig);          // .stage panel (flexible height), optional fig chip bottom-right
  const { el } = TMH.baseCard(c, {
    head: [ ...TMH.head2(c, c.title), TMH.h('p', { class: 'lead sm', text: c.lead }) ],  // top cluster
    mid:  [ stage ],                           // ONE flexible middle (visual or options); centred if short
    foot: [ controlsEl, TMH.modelBlock(c.model) ]  // bottom cluster; hidden if empty
  });
  return el;
};
```
- `baseCard(c, {head, mid, foot})` builds `.inner > .hd + mid... + .ft` as a column. `head` and `foot` are arrays of elements (each wrapped in a flex column with gaps); `mid` is an array whose elements become direct children of the card (give a visual `flex: 1 1 0`, which `.stage` already has). Aria label = `c.title || c.q || c.kicker`.
- Helpers on `TMH`: `h(tag, props, ...kids)` (props: `class`, `text`, `onclick`/`on*`, boolean attrs; `style` and others as attributes; kids may be nodes, strings, arrays), `baseCard`, `modelBlock(text)`, `stageBox(fig)`, `head2(c, title)` (h2 + kicker row), `cueEl(c)`, `kickerEl(c)`, `uid(prefix)` (unique ids for label/slider pairs), `fmt(str, {k: v})` (replaces `{k}`), `ui(key)` (generic strings), `makeCanvas`, `addSim`, `playButton`, `drawGrid`, `theme`, `rgba`, `mixc`, `clamp`, `reducedMotion()`.
- Existing CSS classes you can reuse: `.stage`, `.fig`, `.lead`, `.lead.sm`, `.readout`, `.controls` (row of button + sr-only label + range input), `.btn`, `.btn.sm`, `.btn.solid`, `.opts`/`.opt` (option buttons), `.chips`/`.chip`, `.segrow`/`.seg`, `.model`, `.cue`, `.bonus`, `.mini`, `details/summary`, `.desc`, `.hows`. Tokens (CSS custom properties) are in `:root` at the top of `blocks.css`; always use them, never hex, so dark mode works.
- Every control needs 44 to 48px touch height, a visible `:focus-visible` (already global for the classes above), and an accessible name (sr-only `<label for>` for sliders: use `TMH.uid` for ids).

### 6.2 Animated canvas blocks
```js
const stage = TMH.stageBox(c.fig);
const cv = TMH.makeCanvas(stage, () => sim.draw());   // returns {cv, ctx, w, h, dpr}
const sim = TMH.addSim(el, {                            // register AFTER baseCard returns el
  update(dt) { /* advance state; dt in seconds, capped at 0.05 */ },
  draw() { if (!cv.w) return; /* draw with cv.ctx in CSS pixels, size cv.w x cv.h */ },
  onShow() { if (!TMH.reducedMotion() && !sim.touched) { sim.playing = true; sim.syncUI && sim.syncUI(); } }
});
foot.push(TMH.playButton(sim));                         // optional Play/Pause button, wires sim.syncUI
```
- Lifecycle: `sim.visible` is set by an IntersectionObserver (card at least 50% in view). The shared rAF loop calls `update` only when `visible && playing`, and `draw` when `playing`, or after a change, or every frame if `sim.alwaysDraw = true` (use for pulsing hints). When you change state from a handler (slider input, click), set `sim.playing = false; sim.touched = true; sim.syncUI(); sim.draw();`. `touched` stops autoplay from re-starting after the learner took over.
- DPR: `makeCanvas` handles it. It sizes the backing store to `css size * min(devicePixelRatio, 3)`, applies `setTransform(dpr,0,0,dpr,0,0)` and re-fits on resize via ResizeObserver, then calls your callback. Draw in CSS pixels only.
- Theme: never hard-code colours. Read `TMH.theme` (a live object refreshed on theme change, followed by an automatic `draw()` of every sim): keys `bg panel ink ink2 line soft block hatch metal metalhi mech accent mix mixhi burn burnhot exh good bad` as `#hex` or `rgb()` strings. Use `TMH.rgba(color, alpha)` for transparency and `TMH.mixc(a, b, t)` to blend. Start frames with `TMH.drawGrid(ctx, w, h)` for the standard grid. Mono label font for canvas text: `"600 10px 'IBM Plex Mono', ui-monospace, Menlo, monospace"`. Do not capture colours at build time; read `TMH.theme.x` inside `draw()`.
- Reduced motion: do not autoplay when `TMH.reducedMotion()` is true (the `onShow` pattern above), and give a meaningful static first frame (the build draws one frame of every sim at mount). CSS already disables transitions and smooth scroll.
- Static draw: provide `draw()` that works at any state, so first frames, resizes and theme changes just call it.

### 6.3 Pointer/touch drag pattern (from sim-crank)
The canvas has `touch-action: pan-y`, so vertical swipes still scroll the feed. To drag something without scrolling the feed:
```js
cv.cv.addEventListener('touchstart', e => { if (hit(e.touches[0])) e.preventDefault(); }, { passive: false });
cv.cv.addEventListener('touchmove',  e => { if (dragging) e.preventDefault(); }, { passive: false });
cv.cv.addEventListener('pointerdown', e => {
  if (!hit(e)) return;                          // only start when the press lands on the draggable
  dragging = true; sim.playing = false; sim.touched = true; sim.syncUI && sim.syncUI();
  cv.cv.setPointerCapture(e.pointerId); cv.cv.classList.add('grabbing');
});
cv.cv.addEventListener('pointermove', e => {
  if (!dragging) { cv.cv.classList.toggle('grab', hit(e)); return; }   // hover cursor
  /* convert e.clientX/Y via cv.cv.getBoundingClientRect() into model coordinates, update state */ sim.draw();
});
const end = () => { dragging = false; cv.cv.classList.remove('grabbing'); };
cv.cv.addEventListener('pointerup', end); cv.cv.addEventListener('pointercancel', end);
```
Key points: `preventDefault` on `touchstart` only when the touch hits the draggable (otherwise the feed cannot scroll over the canvas), `passive: false` is required, capture the pointer, treat angles with wrap-around (`d > 180 ? d -= 360`), and always offer a keyboard/slider alternative (the crank block has a range input synced both ways).

### 6.4 Interactive (non-canvas) blocks
Plain DOM blocks need no sims. For quiz-like blocks reuse `.opts`/`.opt`; set `--n` on `.opts` (inline style) to the option count so rows size correctly. Announce results in an `aria-live="polite"` container. Anything content (labels, numbers, answers, captions) must come from `c`; keep only generic UI chrome in `TMH.ui(...)`, and add new generic strings to `UI_DEFAULT` in `core/blocks.js`.

### 6.5 Checklist for a new block
1. All text, numbers, answers read from `c`; sensible defaults for every optional param.
2. Theme tokens only; check light and dark.
3. 375x667 and 390x844: no horizontal scroll, controls at least 44px, text not clipped.
4. Reduced motion, DPR 1 to 3, resize, keyboard operable, accessible names.
5. Document the schema (fields, types, required, limits, example) in this file.
6. Build (`./build.sh <topic>`), serve `dist/`, open `<topic>.preview.html` at 390x844, scroll every card, no console errors.

## 7. Build and test
```
./build.sh <topic>                      # reads topics/<topic>.js
cd dist && python3 -m http.server 8766 & echo $!    # record the PID, kill exactly that PID later
open http://localhost:8766/<topic>.preview.html
```
`dist/<topic>.html` follows the hosting contract: no doctype/html/head/body, starts with `<title>`, then `<meta name="claude:viewport-fit-sides" content="cover">`, the fonts `<link>`, one `<style>`, the markup, one `<script>` (core, then topic, then `TMH.mount(window.EXPLAINER)`). A topic file must set `window.EXPLAINER` and may only run code that works in both the browser and Node's `vm` (the build evaluates it once to read the title).

## 7. Library build (several topics in one page)

`./build.sh library` writes `dist/library.html` and `dist/library.preview.html`: a home screen plus every topic in `LIBRARY` (top of `build.mjs`: `{id, title, teaser, visual?, params?}`; `id` = `topics/<id>.js`; card count is derived from the topic; `visual` `'crank'` or `'gears'` draws the small ambient canvas on the tile). Adding a topic = write `topics/<id>.js` and add one line to `LIBRARY`. The build warns about topic files not listed.

- Routing is bare hash tokens only: `#engine`, `#gearbox`. Empty or unknown hash = home. Tiles and branch items are plain `<a href="#id">`; `hashchange` swaps views (`core/library.js`), so browser back works. The HUD has an "All topics" link (`href="#"`) left of the counter (library only).
- Each topic file is wrapped in a function with its own throwaway `window`, so `window.EXPLAINER` never collides. `TMH.blocks` is shared by all topics: if a topic registers a custom block, prefix its name with the topic id (`gearbox-foo`), since registrations persist after unmount.
- Library-only `TMH.topicHref(id)` is set by `core/library.js`; `branches` uses it for items with a `topic` field.

### Lifecycle API
- `TMH.mount(EXPLAINER)`: mounts a topic; if one is already mounted it is unmounted first (replace).
- `TMH.unmount()`: stops the rAF loop, disconnects the IntersectionObserver and every ResizeObserver, removes the keydown, `prefers-color-scheme` and theme-attribute listeners, empties feed, segments and counter, resets scroll to top.
- `TMH.ambient(host, {visual: 'crank'|'gears', params?})` / `TMH.clearAmbient()`: small always-running decorative canvases for a host page (library tiles). They share the single rAF loop.
- `TMH.debug()`: `{loop (0|1), holds, sims, ambientSims, resizeObservers, keydown}` for leak checks; `loop` must never exceed 1.
