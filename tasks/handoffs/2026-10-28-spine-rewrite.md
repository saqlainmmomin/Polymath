# Handoff: rewrite the six pre-spine topics, spine-first

## Goal
Rewrite the reader-facing copy of six topics with the `write-explainer` skill (spine-first, v2): **moon-tides, bike-gears, card-payment, gps, feel-wet, sky-blue**. Work one topic at a time, in that order (most work first). The owner approves each gate before you move on.

**Done for a topic:**
1. `tasks/spine-<id>/` holds `facts.md`, `paragraph.md` and `slides.md`.
2. The owner has approved the paragraph, then the spine and slides.
3. The fact recheck is clean.
4. `topics/<id>.js` is rewritten.
5. `./build.sh <id>` and `./build.sh library` pass lint.
6. The new copy is exported to the iOS app.

Stage 5 (human cold read) is the owner's job. List it as pending; don't fake it.

**Done overall:** all six topics through stage 4. A `## Results` table at the end of this file lists each topic's new title and card list (headline per card), so the design session can redraw its pictures.

## Current state (2026-10-28)
- **Already spine-first:** shazam, car-engine, superglue, birthday and seasons (see `tasks/spine-*` and `tasks/trial-glue`). Use them as models; `tasks/spine-car-engine/` and `tasks/spine-shazam/` are the most recent.
- **The six topics** predate the method. `tasks/rules-audit.md` has, per topic, a spine, findings that quote the lines and the rules they break, and a verdict. Read the topic's section before stage 1. The audit is input, not the answer: still write the facts sheet and paragraph from scratch.
  - **moon-tides:** full redo and a new title. The current title names the answer, the topic carries three questions, and there's a bridge card.
  - **bike-gears:** full redo, keeping slide 1. Cards 2–4 are too long, card 3 is arithmetic, and the title is textbook.
  - **card-payment:** card 3 is a link-counting detour; ask the owner whether to keep it.
  - **gps:** has two analogies, uses "GPS", and has a "usually" hedge.
  - **feel-wet:** "sensors" is defined three times, and slide 1 states the surprise three times.
  - **sky-blue:** slide 1 is the owner's own rewrite and is the voice bar (`.claude/skills/write-explainer/examples/sky-blue-opener.md`). Keep its meaning; the rest was never approved.
- **A separate design session** is redrawing iOS pictures in a navy "Blueprint" style (`tasks/handoffs/2026-10-28-blueprint-rollout.md`). It has been told to hold off on these six topics until your rewrite lands. Your card lists in Results are its input.
- `main` is pushed to GitHub (`a0bf675` and later). Other sessions may have uncommitted edits in this checkout.

## Key files
- `/Users/saqlainmomin/tell-me-how/.claude/skills/write-explainer/SKILL.md`: the method and the 10 meaning rules. Invoke the `write-explainer` skill; don't paraphrase it from memory.
- `/Users/saqlainmomin/tell-me-how/.claude/skills/write-explainer/examples/`: the voice bar (`sky-blue-opener.md`) and worked examples.
- `/Users/saqlainmomin/tell-me-how/PRODUCT.md`: the product goal (curiosity, effortless, broad appeal).
- `/Users/saqlainmomin/tell-me-how/RECIPE.md`: topic structure (one big question, 1–6 cards).
- `/Users/saqlainmomin/tell-me-how/core/BLOCKS.md`: card and visual types for the web diagrams.
- `/Users/saqlainmomin/tell-me-how/tasks/rules-audit.md`: the per-topic audit described above.
- `/Users/saqlainmomin/tell-me-how/topics/<id>.js`: the topic files you rewrite.
- `/Users/saqlainmomin/tell-me-how/tasks/spine-car-engine/`, `/Users/saqlainmomin/tell-me-how/tasks/spine-shazam/`: model facts, paragraph and slides files, including the recheck and fixes sections.
- `/Users/saqlainmomin/tell-me-how/build.mjs`: the `LIBRARY` list. All six topics are already in it; don't edit it.
- `/Users/saqlainmomin/tell-me-how/tools/export-topics.mjs`: exports `topics/*.js` to `ios/Polymath/Resources/topics.json`.

## Process per topic (the skill's gates; don't skip or merge them)
1. **Facts sheet:** a separate fact-checker subagent writes `tasks/spine-<id>/facts.md`.
2. **Paragraph:** about 100–150 words, with `[n]` slide marks.
   - A fresh subagent paraphrases it back; fix every phrase it had to guess at.
   - Show the owner only the title, the setup line and the paragraph, then **stop and wait for approval.**
3. **Slice and spine:** cut the approved paragraph into slides and write the spine. Show the owner the spine, then the slides, and **wait for approval.**
4. **Fact recheck and file:** run the fact recheck (subagent against `facts.md`). Fix each flag by going back to the sheet's own sentence, then write `topics/<id>.js`.
   - Web diagrams: keep or adapt the existing ones so their labels use the text's exact words. Don't build new blocks.
   - Run `./build.sh <id>` and look at `dist/<id>.preview.html` in the built-in browser for overlaps.
5. **Export:** run `node tools/export-topics.mjs`, then add the topic's row to Results.

The owner said "run one topic at a time": finish a topic's gates before starting the next topic's facts sheet. You may start the next topic's facts-sheet subagent while waiting on an owner gate, but show the owner only one topic at a time.

## Constraints (decided; do not relitigate)
- **Copy rules:** the 10 meaning rules in the skill, plus these owner tastes:
  - Explainer voice, not staccato: joined sentences, few colour names.
  - Hooks lead into the next headline's key word, and headlines decode cold.
  - One analogy, and it must stick.
  - Plain reader verbs ("goes hard", not "grabs").
  - Sentences about 8–18 words, none over 20. The lint's 15-word warning is stale.
  - Writers drift over about 30 words per card during fixes; trim.
- **Title:** a twist, personal or daily-use, literally true; never a textbook "how does X work".
- **Self-contained topics:** every topic defines its own words, because topics arrive in random order.
- **Never paste fact-check wording into copy.** Fix flags with the facts sheet's plain sentence.
- **Off limits:** no Swift files and no picture work (that's the design session's job). Don't edit `build.mjs`; all six ids are already in `LIBRARY`. Touch only `topics/<id>.js`, `tasks/spine-<id>/` and the generated `topics.json`.
- **Shared checkout:** several sessions edit this checkout. Never stash, reset or switch branches.
- **No commits** unless the owner asks. If asked, commit only your files.
- **Testers' link:** never republish https://claude.ai/artifact/47dT3dkGhANEzEWf64UFhP without the owner's OK.
- **No simulator:** don't run or boot the iOS simulator; it slows the owner's laptop. To show copy on the phone: `ios/run-device.sh <id> [card]` (it re-exports `topics.json`). The phone must be unlocked. Don't screenshot every card.

## Verification (before calling a topic done)
- `./build.sh <id>` and `./build.sh library` finish with no lint errors.
- A script counts each card's sentences and words and finds none over 20 words.
- Read the spine aloud as a check: every hook shares a key word with the next headline.
- `node tools/export-topics.mjs` succeeds, and `ios/Polymath/Resources/topics.json` holds the new title.
- The fact recheck section in `slides.md` shows every flag resolved.

## Report back
Append to this file:

```
## Results
| Topic | New title | Cards (headline per card) | Gates passed | Pending |
```

Note any card the owner cut or added, because the design session's picture mapping (`ios/Polymath/Pictures.swift`, by card index) depends on the card order.

## Results
Updated 2026-10-28 as each topic finishes. Stage 5 (human cold read) is the owner's job and is pending for every topic.

| Topic | New title | Cards (headline per card) | Gates passed | Pending |
|---|---|---|---|---|
| moon-tides | Why does one Moon give most beaches two high tides a day? | 1. *There's only one Moon, and it's on one side of the sky at a time.* (setup) · 2. The Moon pulls the near sea harder than the ground, and the far sea less · 3. The sea piles up on both sides of Earth, in two bulges · 4. As Earth turns under the bulges, your beach gets two high tides · 5. The Moon moves on, so each day's high tide comes about 50 minutes later | Facts sheet · paragraph (owner approved, paraphrase check done) · spine and slides (owner approved) · fact recheck (2 flags, resolved) · `topics/moon-tides.js` · `./build.sh moon-tides` and `library` (0 errors; only the stale 15-word / 8-word-headline warnings) · no sentence over 20 words · exported to `topics.json` | Stage 5 cold read · web diagrams not looked at in a browser (Chrome extension not connected: OAuth token belongs to a different claude.ai account) · not pushed to the phone |
| bike-gears | Why does one gear click make the same hill feel easier? | 1. *Same hill, same legs.* (setup) · 2. A smaller back ring spins the wheel more for each pedal turn · 3. A smaller back ring carries you farther with each pedal turn · 4. A shorter way per turn means a lighter push, and more turns to the top · 5. To go the same speed on flat road, a smaller back ring means slower pedalling | Facts sheet · paragraph (owner approved, paraphrase check done) · spine and slides (owner approved) · fact recheck (6 flags, resolved; 5 changed approved wording slightly, listed in `slides.md`) · `topics/bike-gears.js` · `./build.sh bike-gears` and `library` (0 errors, stale warnings only) · no sentence over 20 words · exported to `topics.json` | Stage 5 cold read |
| card-payment | Why isn't the shop paid the moment you tap your card? | 1. *You tap, it beeps, and you walk away.* (setup) · 2. The message goes to the shop's bank, then a card network, then your bank · 3. Your bank's yes is a promise to pay, and the money hasn't reached the shop yet · 4. Banks move money in totals, so the shop is usually paid a few working days later | Facts sheet · paragraph (owner approved, paraphrase check done) · owner approved cutting the link-counting card · spine and slides (owner approved) · fact recheck (5 flags, resolved; 3 changed approved wording, listed in `slides.md`) · `topics/card-payment.js` · `./build.sh card-payment` and `library` (0 errors, stale warnings only) · no sentence over 20 words · exported to `topics.json` | Stage 5 cold read · web diagrams not looked at in a browser |

**Card changes for the design session (`Pictures.swift` maps by card index):** moon-tides went from 6 cards plus a bridge to **5 cards, no bridge**. All five pictures change. Old: tide on a beach, the Moon's pull, two bulges, Earth spins, Sun and spring tides, Bay of Fundy. New: the question (sea rises and falls twice), uneven pull on near sea / ground / far sea, three runners becoming two bulges, Earth turning your beach through both bulges, the Moon moving on so the beach needs about 50 extra minutes. Cut from the topic: the Sun and spring tides, Bay of Fundy, the rock-moves note and the 50-minute bridge as its own card (it is now card 5). Picture labels per card are in `tasks/spine-moon-tides/slides.md`.

**bike-gears card changes:** still 5 cards, but all five pictures change. Old: same hill; stack of rings on the back wheel; teeth arithmetic (a smaller back ring spins the wheel more); short steps easier uphill (stairs); pick the gear for the road. New: the same hill and a gear click; the chain, pedal ring and a bigger or smaller back ring (each link fits one tooth); one pedal turn carries you farther or a shorter way; walking a steep path in long strides or short quick steps (a pedal turn is like a stride); flat road, same speed, a smaller back ring means slower pedalling and a harder push. Picture labels per card are in `tasks/spine-bike-gears/slides.md`. Dropped: numbered gears, the 30/10 teeth sum, the stairs picture, and the "low number = easy" bold line. The bold line is now "A gear can't make the hill any lower. It only decides how many pushes it takes to climb it."

**card-payment card changes:** went from 5 cards to **4**. The link-counting card (old card 3, 45 links against 10) is cut by the owner's decision. Old: tap and beep; four places; one network saves links; checks then sets money aside; shop paid later. New: the tap sends a short message; the message goes shop's bank, card network, your bank, and the yes comes back; the yes takes the amount off what you can spend but the shop has no money yet; many payments added up into totals and the shop paid a few working days later. Pictures 3 and 4 are new, picture 2 can keep its four-places layout, and the link-counting picture goes away. Picture labels per card are in `tasks/spine-card-payment/slides.md`. Dropped: "sets money aside", "the money stays in your account", "1 to 3 working days", "about 2 seconds", "all at once", the 20-from-50 sum. The bold line is now "The yes comes back in seconds, and the shop is usually paid a few working days later."

**Note for the design session:** the web diagrams were left as stand-ins using the text's words; I did not look at them in a browser.
