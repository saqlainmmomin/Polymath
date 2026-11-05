# Airbrush scenes: how to write them and what to check

Format: `tasks/scene-format.md`. Working examples: `ios/Polymath/Scenes/feel-wet.json` (skin, nerve endings, a brain, a finger in a tub) and `sky-blue.json` (a sun, waves, a molecule, scattering, the top of the Earth). Checker: `python3 tools/scene/scene.py check <id>`. The topic JSON needs `"style": "airbrush"`.

The look (owner, 2026-11-03): paper photo behind, a **thin near-black hand line that wobbles and sits a little off its colour**, sprayed colour clouds with grainy edges, soft airbrushed glows, round simple figures, and **green condensed capitals** for words. The renderer does the wobble and the offset for you: any `circle`/`rect`/`path` with a `fill` is painted, then inked a few points off. The kit is `AirbrushParts.swift` (`sun`, `skinCut`, `nerve`, `brain`, `finger`, `tub`, `molecule`, `scatter`, `eye`, `earthLimb`, `drop`, `spray`, `glow`, `person`, `ground`) plus the generic parts (`arrow`, `dim`, `wave`, `arc`, `rings`). Colours by name: `blue orange salmon skin yellow lime green`, `ink`, `white`, `paper`, with `@alpha` ("blue@0.3"), and `"vg:orange:salmon"` for a top to bottom gradient. In `part` params a colour is a number (`col`): 0 ink, 1 yellow (the accent), 2 blue, 3 orange, 4 salmon, 5 skin, 6 yellow, 7 lime, 8 green, 9 red.

## Composition (every scene, the first time)
1. **Ground or a backdrop cloud.** A `ground` part (a sprayed salmon wash under a wobbly line), or a big `spray` cloud behind the hero, so the paper is not empty.
2. **Hero.** A real object with colour and a line: a `skinCut` with a nerve ending in it, a `brain`, a `finger` in a `tub`, a `sun` with a glow. Never a bare outlined shape: give it a fill, and a second colour or a detail.
3. **Context.** A few strokes or a faint spray round it: air molecules, a puddle, a dashed box.
4. **One yellow.** Yellow (the glow, the bead, the lit thing) is for what the sentence is about. Blue, orange, lime, salmon and skin are the base colours of things; they do not count as accents.
5. **Life.** `sun` pulses with a `wobble` on `r`; `wave` scrolls with `speed`; `scatter` grows with `len`; `nerve` takes `lit` and `sig` (a bead down the stalk). The boil of the hand line is always alive, but something must also change every sentence.

## Look
- **Visible stage: stay above y 275** (see `wireframe.md`); the player corner (x > 288, y > 235) stays clear.
- Words are green capitals, big: label size 19 and text size 22 by default, so keep to 3 words a line and use `\n`. Green on blue or on green is hard to read: use `"stroke":"white"` for a word that sits on a colour.
- Labels: `"align":"center"` with `at` *above* the dot puts the words above the end of the leader (the Airbrush way); `"leading"` right of it, `"trailing"` left of it. Keep every label clear of the others: they are wide.
- A coloured shape smaller than 24 across gets no offset (it would look broken). Wobble is gentler on short lines.
- `spray` (`rx`, `ry`, `col`, `alpha`, `grow`) sprays in on its word. Use it for water, air and light, not for outlines.

## Timing
Same as Drafting (`drafting.md`): every element and move names the spoken word it starts on. A part's animated number must be in its own `params` (so `lit`, `sig`, `sheath`, `alpha`, `len` are listed even when 0). A group fades with `opacity`; text and labels too.

## Look at the contact sheet and ask
1. Can I tell what each frame shows with the sound off?
2. Does the colour sit a little off its line, and is the line thin and alive, not heavy?
3. Is yellow only on the one thing that matters? Are the greens readable on what is behind them?
4. Any label on top of another, or a leader through its own words? Anything cut off, below y 275, or in the corner?
5. Is every object a real thing with colour and a detail, and does the picture have a hero, not a scatter?
6. Does the last frame stand on its own as the answer? Any stall longer than 3 s?

## Rules the owner has added (append here)
- 2026-11-04 (feel-wet and sky-blue, first scenes): keep everything above y 275; centred labels put their words above the leader's end.
- 2026-11-05 (owner; extended after bike-gears card 2 and a card-payment topic, where a close-up put things on the other side): **flow: the same thing stays on the same side in every card.**
  - In card 1, choose the side of each thing and keep it in every later card. Cause, sender or before on the LEFT; effect, receiver or after on the RIGHT (a satellite left, the phone right; the Moon left, the sea right; shop left, bank right, the message going left to right).
  - Before drawing a card, list the parts it shares with earlier cards and put each one where it was. Never swap two of them, and a card that is "another look" at the story is still the same left and right.
  - A close-up of a part keeps that part's orientation: mirror the diagram, not the story. `bike` and `walker` face and move RIGHT and are never mirrored (a left-facing rider "doesn't look right"). `gearPair` draws its pedal ring on the LEFT, so next to a bike it takes `"mirror": true` (back rings left, pedal ring right, as on the bike).
  - `scene.py check` runs `tools/scene/flow.py` and says which cards flip: an error for a side-bound part (`bike`, `gearPair`, `walker`) that turns round or two parts that swap by 40 or more units, a warning for smaller swaps, a lone part that changes halves of the screen, or a part mirrored in one card only. Fix it, or tell the owner why it must flip.
- 2026-11-05 (owner): **no text on the picture.** A label or caption may not sit on a part, a ray, a ring, a wave or a grid line, nor on another label or leader. Keep words in a clear band (above, below or in a column beside the picture), a label shows only after the thing it points at has started, and a claim sentence is a `text` placed in a band, not a `label` with a leader into the picture. Two headlines never fade over each other: the second waits for the first.
- 2026-11-05 (lint): `python3 tools/scene/scene.py lint <id>` finds words printed on the picture and blank cards; fix what it reports, or put `"onpicture": true` on words that belong there (see `tasks/scene-format.md`).
