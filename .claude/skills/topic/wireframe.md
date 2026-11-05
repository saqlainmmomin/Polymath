# Wireframe scenes: how to write them and what to check

Format: `tasks/scene-format.md`. Working examples: `ios/Polymath/Scenes/gps.json` (satellites, a phone, a huge wire Earth, rings, clocks) and `moon-tides.json` (a beach, a Moon, Earth from above with a pink sea). Checker: `python3 tools/scene/scene.py check <id>`. The topic JSON needs `"style": "wireframe"`.

The look: a 3D wire illustrator on black. Fine white lines, solid black fills so nothing shows through that should not, **one pastel pink** for the one thing the sentence is about (a signal, a sea, a distance, the spot you are on). Labels are lowercase mono on a short leader. The kit is `WireframeParts.swift` (`wfPhone`, `satellite`, `globe`, `moon`, `tideEarth`, `tower`, `pin`, `clock`, `magnet`, `ground`) plus the generic parts every style has (`arrow`, `dim`, `wave`, `arc`, `rings`).

## Composition (every scene, the first time)
1. **Ground or space.** Something stands on `{"part":"ground"}` (a line, a dim line under it, dotted ticks), or hangs in space above a huge `globe` (`r` 160 to 210, centre below the stage so only its curve shows: it reads as a planet and is not counted as the hero).
2. **Hero.** The object the sentence is about, wired and big: a `wfPhone` at scale 1.2, a `satellite`, `tideEarth` at r 58 to 62. A phone is not a rectangle: it has a back slab, buttons, a map grid, signal bars. A satellite has panels and a dish.
3. **Context.** One or two cues in the dim greys: a mast (`tower`), a dashed orbit (`arc` with `dash` 1), guide lines. Never over a label.
4. **One pink.** `accent` on the signal, the sea, the distance or the pin. A scene with two pink things at the same time is wrong. Pink text: `"stroke":"accent"`.
5. **Life.** `rings` travel by themselves (set `speed`); `globe` and `moon` can turn (`turn`); `tideEarth` has `spin`, `bulge`, `dir`. Something changes every sentence.

## Look
- **Visible stage: stay above y 275.** The contact sheet and the phone cut the picture a little below that. Labels at y 282 or 292 are lost. The player corner (x > 288, y > 235) is kept clear as always.
- Design space 343 x 320, centred on x 171. The hero's middle near y 150.
- Labels: lowercase, at most 4 words a line, a short leader to a dot on the part. `"align":"leading"` puts the text right of `at`, `"trailing"` left of it (the leader runs from the dot to `at`), `"center"` hangs the text just below `at`. Never put `at` above the dot with `center` (the leader would run through the words).
- A label has a black knockout behind it, so it hides lines: keep it clear of rings and of the sea.
- Text on a line of its own: `{"text": ...}`, size 9 to 11, mono, white or `"stroke":"accent"`.
- Pink fill on `circle`/`rect`/`path`: `"fill":"accent"`; black fill to hide what is behind: `"fill":"face"`; pale: `"fill":"side"`; hatch: `"hatch":{"spacing":3.6,"alpha":0.4}`.
- Dashes: `"dash":[3,3]`. Dim lines: `"stroke":"ink@0.4"`, `"width":0.7`.

## Timing
Same as Drafting (`drafting.md`): every element and move names the spoken word it starts on (`"word#2"` for the second time). A part's animated number must be in its own `params` (so `bulge`, `spin`, `dir`, `lit`, `bars`, `pin` are listed even when 0). Parts and props: the checker prints them. A move on `x`/`y` counts where the thing ends up for the composition check.

## Look at the contact sheet and ask
1. Can I tell what each frame shows with the sound off?
2. Is anything pink that is not the point of this sentence, or two things pink at once?
3. Does any label sit on a ring, a sea or another label? Does a leader run through its own words?
4. Is anything cut off at the edge, below y 275 or in the player corner?
5. Is every object a real wire object (back slab, mesh, panels, ticks) and not a bare box or circle?
6. Does the last frame stand on its own as the answer?
7. Is there a moment longer than 3 s where nothing moves?

## Rules the owner has added (append here)
- 2026-11-04 (gps and moon-tides, first scenes): keep everything above y 275; centred labels hang *below* their leader, so put text beside or below the dot, not above it.
- 2026-11-05 (owner; extended after bike-gears card 2 and a card-payment topic, where a close-up put things on the other side): **flow: the same thing stays on the same side in every card.**
  - In card 1, choose the side of each thing and keep it in every later card. Cause, sender or before on the LEFT; effect, receiver or after on the RIGHT (a satellite left, the phone right; the Moon left, the sea right; shop left, bank right, the message going left to right).
  - Before drawing a card, list the parts it shares with earlier cards and put each one where it was. Never swap two of them, and a card that is "another look" at the story is still the same left and right.
  - A close-up of a part keeps that part's orientation: mirror the diagram, not the story. `bike` and `walker` face and move RIGHT and are never mirrored (a left-facing rider "doesn't look right"). `gearPair` draws its pedal ring on the LEFT, so next to a bike it takes `"mirror": true` (back rings left, pedal ring right, as on the bike).
  - `scene.py check` runs `tools/scene/flow.py` and says which cards flip: an error for a side-bound part (`bike`, `gearPair`, `walker`) that turns round or two parts that swap by 40 or more units, a warning for smaller swaps, a lone part that changes halves of the screen, or a part mirrored in one card only. Fix it, or tell the owner why it must flip.
- 2026-11-05 (owner): **no text on the picture.** A label or caption may not sit on a part, a ray, a ring, a wave or a grid line, nor on another label or leader. Keep words in a clear band (above, below or in a column beside the picture), a label shows only after the thing it points at has started, and a claim sentence is a `text` placed in a band, not a `label` with a leader into the picture. Two headlines never fade over each other: the second waits for the first.
- 2026-11-05 (lint): `python3 tools/scene/scene.py lint <id>` finds words printed on the picture and blank cards; fix what it reports, or put `"onpicture": true` on words that belong there (see `tasks/scene-format.md`).
