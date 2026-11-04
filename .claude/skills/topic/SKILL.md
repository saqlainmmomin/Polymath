---
name: topic
description: Make a finished Narrated Tell Me How topic from a question: facts, spoken script, Drafting scene pictures, voice, simulator check and phone install, with the owner approving only the script and the final phone look. Use when the owner gives a question (or a list) to turn into a topic, e.g. "/topic Why does ice float?".
---

# /topic: question in, Narrated topic on the phone out (v1, 2026-11-04)

The owner gives a question (or several). Everything between "script approved" and "look at it on the phone" is yours. Two owner gates only.

Drafting style only for now (`drafting.md` beside this file has the picture rules). The other three styles have no scene parts yet: say so, don't fake them.

## Steps

1. **Facts and script (AI).** Pick `<id>` (kebab-case). A fact-checker subagent writes `tasks/spine-<id>/facts.md` (see `tasks/spine-poker/` for layout). You write `tasks/spine-<id>/paragraph.md` by the `write-explainer` skill stage 2: title, setup, one spoken paragraph of 100 to 150 words with `[n]` slide marks (at most 5 slides). A fresh subagent reads it cold and says the answer back; fix what it guessed.
   **GATE 1:** show the owner the title and paragraph only. For a list of questions, show all of them at once. Stop until they say go. Only structure changes happen here.
2. **Words (AI).** Cut the approved paragraph into `ios/Polymath/Topics/<id>.json` (copy `poker.json`'s shape: `style: "drafting"`, cards with `title`, `text`, `hook` / `takeaway`, `visual.notes` and `labels`, then a `more` card with empty `links`). Headlines reuse words from their own slice; each hook asks what the next headline answers. A fact-recheck subagent compares the cards with `facts.md` and flags meaning changes only. The owner does not gate slides; the spine goes in the final report.
3. **Pictures (AI).** Write `ios/Polymath/Scenes/<id>.json`, one scene per card, by `drafting.md`: ground, centred hero, context cue, one accent. Look at the card-payment pictures for the bar. Every move names the word it starts on. Do not add Swift pictures or `{t}` markers. If an object has no part, draw it with `path`, `circle`, `rect`; add a part (a new function in a `DraftingParts`-style file, registered in `SceneParts.swift`) when the object is the hero of a card, so it has real thickness and detail; a bare rectangle is never the hero.
4. **Make (code).** `python3 tools/topic/topic.py make <id>`. It drafts and renders the voice (script = the cards read aloud, via `narrate.py new`), runs the scene checker, builds the simulator app and takes frames, then writes `ios/build/frames/<id>/card<N>.png`, one contact sheet per card with the second on top of each frame.
5. **Look and fix (AI, up to 3 rounds).** Fix every checker error. Then open each contact sheet with Read and go through the list in `drafting.md`. Edit the scene, run `make <id> --skip-voice` again. Stop after 3 rounds and list what is still doubtful.
6. **Phone (code).** `python3 tools/topic/topic.py make <id> --skip-voice --skip-frames --phone`. If the phone is unavailable, say so and give the simulator command.
   **GATE 2:** tell the owner what to check on the phone, what you are least sure of, and the timings the tool printed. Their notes come back as edits to this topic.
7. **Learn.** A note that applies to every topic ("labels too small", "yellow only on the answer") becomes a rule line in `drafting.md`. A note about this topic's picture is just an edit. Never leave the same note to be given twice.

## Rules
- Never claim a picture is right without having looked at its contact sheet this round.
- A topic is done when the owner says so after the phone look, and a person new to the topic has read it once (`write-explainer` stage 5). Say that last part is still open.
- Commit and push only when the owner asks.
- Several sessions may edit at once: touch only this topic's files (`Topics/<id>.json`, `Scenes/<id>.json`, `tools/voice/<id>.txt`, `Resources/voice-<id>.*`, `tasks/spine-<id>/`).
