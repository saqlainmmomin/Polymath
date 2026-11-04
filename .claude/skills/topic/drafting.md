# Drafting scenes: how to write them and what to check

Format: `tasks/scene-format.md`. Working examples: `ios/Polymath/Scenes/poker.json` (cards, chips, a table) and `superglue.json` (a bespoke finger, clipped magnifier, falling drop). Checker: `python3 tools/scene/scene.py check <id>`.

## Composition (every scene, the first time)
A scene is a small stage set, not a diagram. Build it in this order and a bare-looking picture does not happen:
1. **Ground.** `{"part":"ground","at":[171,240],"params":{"w":250}}` under everything that stands. Labels hang below it at y about 274, each pointing at its object's foot.
2. **Hero.** The thing the sentence is about, centred on x 171 (or two heroes balanced about it), tall enough to fill 45% or more of the stage's height. Never a bare rectangle: if the object is not a kit part, add a part with thickness (a hatched back slab), a window or panel, and one or two small details (see `DraftingParts.swift`: phone, battery, meter, tank are the model).
3. **Context.** One or two small cues that say where we are, in the lighter ink: snowflakes for cold (`snowflake`, drifting with a `wobble` on y), the table edge for a game, a shelf. They sit around the hero, never over a label.
4. **One accent.** Yellow on the one thing that changes or matters.
5. **Life.** Something moves on every sentence (a level rises, a screen goes dark, dots dart). A frame with nothing happening for more than 3 seconds needs a move or a new label.
The checker warns when the picture is off-centre, too high or low, small, or in the player corner (approximate: unknown parts count as 60 x 60).

Standing parts (bottom centre at the origin, so `at` is the feet): `phone` (dark, icon, level), `battery` (level, stuck), `meter` (level, grey), `tank` (thick, h), `snowflake` (size), `ground` (w). Keep adding parts like these rather than drawing a card's objects from bare shapes.

## Look
- Black line art on white. **One yellow accent** per picture, for the one thing the sentence is about (a `lit` card, a bead, a handshake). Never two yellow things competing.
- Design space 343 x 320. Keep everything in it, and keep objects and labels out of the bottom-right corner (x > 288 and y > 235): the player sits there. A wide scene puts its ground at y 232 so the right-hand object clears the corner.
- Fill the stage. No empty bands, no tiny objects (nothing under about 24 wide unless it is a detail).
- Labels are the text's own words, in caps, at most 4 words a line, each pointing (anchor dot) at the thing it names. A label appears on the word that names it (`"word": "film"`).

## Timing
- Every element and move that appears or changes names the spoken word it starts on. Never use `at` seconds. `"word#2"` for the second time a word is said.
- One thing happens per sentence. If two things happen on one word, stagger with `delay` 0.1 to 0.3.
- Moves are brisk: 0.4 to 0.9 s. A move that sits on a word 3 s before the next one reads as a stall: start it on a later word.
- The checker's list of parts and props is the whole vocabulary: `part`, `path`, `circle`, `rect`, `label`, `text`, `group`; props `x y opacity scale rotate draw fill` or a part's param. Eases: `eio`, `eout`, `snap`, `fall`, `linear`.
- Parts for Drafting: glueTube, bead, waterDrop, tear, skin, waterFilm, calendar, stopwatch, plank, playingCard, chips, terminal, card, heldCard, envelope, bank, network, shop, yes, slip. Look at `SceneParts.swift` for params. Anything else: draw with paths.

## Look at the contact sheet and ask
1. Can I tell what each frame shows with the sound off? One idea per card.
2. Does the thing the sentence is about move or light up on that word, and nothing else yet?
3. Any label that points at where an object *used to be*, or a moved object landing on another one? (Both happened in poker.)
4. Any text or object clipped at the edge, or in the player corner?
5. Is anything drawn that no sentence mentions? Cut it.
6. Does the last frame stand on its own as the answer?
7. Do the frames read left to right / top to bottom in the order the words say them?
8. Design: is the hero centred and big? Does every object look like a real thing (thickness, hatching, a detail) and not a box? Is there a ground and a context cue? Would you put it next to the card-payment pictures?

## Rules the owner has added (append here)
- 2026-11-04 (cold-phone, owner): the first pictures were flat boxes, empty and off-centre. Rule: ground + centred hero + context cue, parts with thickness (Composition above).
- 2026-11-04 (cold-phone, owner): copy had too many ideas on one card (voltage, sags, a wrong guess). One new word per card, say "push" not "voltage", no "guess" jargon.
