# Scene format: pictures as data (plan, 2026-11-03)

**Status (2026-11-03): steps 1 to 4 built.** Renderer `ios/Polymath/Scene.swift`, parts `ios/Polymath/SceneParts.swift`, superglue's
four cards in `ios/Polymath/Scenes/superglue.json` (196 lines, replacing ~330 lines of Swift; the Swift pictures stay as the fallback),
`tools/scene/scene.py check|frames`. Frame by frame on the simulator the scenes match the Swift pictures; differences are timing only,
now on the words (the GLUE label comes in on "glue"; card 2's drops no longer straggle). Launch args: `--seek <s>` opens paused at that
second of the narration, `--no-scenes` draws the Swift pictures. Next: step 5, a new topic from scenes only.

**Step 5 (2026-11-03): poker**, the first topic made from scenes only (`Scenes/poker.json`, 193 lines, no Swift picture). It needed two
new parts, `playingCard` (rank, suit, turn over, light up) and `chips` (a stack that grows); everything else is paths, labels and
moves. Writing the five scenes and fixing them from the frames took one pass plus one round of position fixes (labels left pointing
at where a card used to be, the pot landing on a player's cards). Its script has no `{t}` markers.

**Goal:** make topics in bulk. Today every picture is hand-written Swift (`GlueDRFilm` is ~85 lines of paths and timings) and its
`{t}` markers are placed by hand. A scene file describes a picture as data instead: which kit parts, where, what moves, and on which
spoken word. An agent can write one in minutes, a tool can check it, and the owner reviews the result on the phone. Start with
Drafting only; prove it by rebuilding superglue; then make one new topic from scratch.

## What a scene file is

`ios/Polymath/Scenes/<id>.json`: one scene per narrated card, beside the topic's words (`Topics/<id>.json` stays words only).
Drawn in the same 343 x 320 design space, clear of the bottom-right corner (x > 288, y > 235), as today.

Elements, in draw order:

| Kind | What | Example |
|---|---|---|
| `part` | A kit object by name, with its own params | `{"part": "glueTube", "at": [22, 89], "params": {"fill": 1}}` |
| `path` | Any bespoke outline as SVG path data: stroke, fill, hatch, dash, accent | the fingertip, the counter line |
| `label` | `DR.label`: text, anchor dot, text position, align | `{"label": "WATER FILM", "anchor": [128, 170], "at": [66, 268]}` |
| `group` | Children with a transform (move, scale, rotate, mirror) and an optional clip | the magnifier: a circle clip around the skin |

Every element draws itself on by default (lines trim in, fills fade up), as the Swift pictures do now.

**Moves**: any number on an element can change over time: position, opacity, scale, rotation, a draw-on amount, or a part's own
param (`bead.hard` 0 → 1). A move names the **word** it starts on, not a picture second:

    {"move": "drop", "prop": "y", "to": 174, "word": "lands", "dur": 0.5, "ease": "fall"}

Eases: `eio` (in-out), `eout` (out), `snap` (DR overshoot), `fall` (gravity), `linear`. `"word": "hard#2"` is the second "hard"
in that paragraph; `"delay": 0.2` waits after the word starts.

**Why words, not seconds**: the automatic cue tool failed because it had to guess which word a label belonged to. Here the author
says so when writing the scene, so nothing is guessed. The renderer reads the word times from `voice-<id>.json`, so a scene
topic's script needs **no `{t}` markers** at all. A rewritten script just needs a re-render, and the words that the scene names must
still be said (the checker below catches it).

### Example: superglue card 3, abridged

```json
{ "card": 2, "label": "A fingertip, and a magnifier showing a thin film of water on the skin; a yellow drop lands on it and goes hard.",
  "elements": [
    {"id": "finger", "path": "M110 30 L64 32 C48 32 35 37 30 46 C25 55 28 66 38 68 C50 72 64 71 76 71 L110 72", "fill": "face"},
    {"id": "lens", "group": [
        {"part": "skinSection", "params": {"surface": 178, "ridge": 5}},
        {"part": "waterFilm", "params": {"shimmer": true}},
        {"id": "drop", "part": "bead", "at": [200, 60], "params": {"hard": 0, "fromBottom": true}, "hidden": true}
      ], "clip": {"circle": [196, 148, 96]}},
    {"label": "SKIN", "anchor": [262, 222], "at": [290, 268], "word": "skin"},
    {"label": "WATER FILM", "anchor": [128, 170], "at": [66, 268], "word": "film"}
  ],
  "moves": [
    {"move": "drop", "prop": "visible", "to": 1, "word": "superglue"},
    {"move": "drop", "prop": "y", "to": 174, "word": "lands", "dur": 0.5, "ease": "fall"},
    {"move": "drop", "prop": "hard", "to": 1, "word": "hard", "dur": 1.0, "ease": "eio"}
  ] }
```

## What stays Swift

- **The parts kit** (`DR` in `Drafting.swift`): `glueTube`, `bead`, `waterDrop`, `terminal`, `heldCard`, `bank`, `network`, `shop`,
  `envelope`, `yes`, `slip`, plus new ones. A part is drawing code written once and reused by every scene. Procedural things (skin
  ridges from a sine wave, a shimmering water film) become parts. Each part is registered by name with its params.
- **The escape hatch**: a card can still point at a hand-written Swift picture in `Pictures.swift`. Scenes are opt-in per card, so
  nothing existing breaks and an unusual picture never blocks a topic.

## Build steps

1. **Renderer** (Swift): `Scene` model (Decodable), `SceneStage` drawing one scene from the beat's word times, the part registry
   for the existing `DR` parts, SVG path parsing, labels, groups with clip, moves with eases. `Pictures.swift` picks a scene when
   `Scenes/<id>.json` has the card.
2. **Checker** (`tools/scene/scene.py check <id>`): every part and param exists, every `word` is said in that beat's script in
   order, nothing falls outside the design space or in the bottom-right corner, labels are short.
3. **Frames** (`scene.py frames <id> [--compare]`): launches the simulator at set narration times (a new `--seek` launch arg) and saves
   one frame per move into a grid PNG. The agent uses it to check its own work; the owner can skim it before the phone.
4. **Pilot: rebuild superglue** in scenes, card 3 first (the hardest: bespoke finger, clipped magnifier, falling drop). Pass if
   the owner can't tell it from the Swift version, or prefers it, on the phone. Note what parts had to be added.
5. **New topic from scratch**: an agent makes one approved-spine topic with scene files only, no Swift. Time it. This is the real
   test of bulk.
6. Then Wireframe (`Cam`, `globe` and the rest become parts), Blueprint and Airbrush, each the same way.

## Decisions for the owner

- **Words instead of `{t}` markers** for scene topics (recommended): the scene says which word starts each move.
- **Cards version**: scene pictures only play Narrated, and show their end state in Cards (the feed is Narrated only now).
- **Pilot**: rebuild superglue first to prove it matches (recommended), or go straight to a new topic.

## Later (not in this plan)

Topics downloaded instead of bundled: once pictures are data, a topic is JSON plus an m4a, so new topics could ship without an
App Store build. Worth doing after step 5 works.
