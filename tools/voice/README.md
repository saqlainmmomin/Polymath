# Offline narration (Kokoro-82M)

## Making a topic Narrated

    python3 narrate.py new <id>       # drafts <id>.txt from the cards, prints each picture's timings
    python3 narrate.py moments <id>   # timings again: picture length and when each label appears
    python3 narrate.py render <id>    # checks one paragraph per card, renders with Kokoro, regenerates the Xcode project

**Each claim is spoken once.** The draft speaks the topic's question, then each card's *text* and hook, never the card's headline (the headline is on screen and the text already carries it; reading both said the claim twice). Add a headline back by hand only where the text never says it. `new` never overwrites an existing `<id>.txt`, and `render` prints `SAID TWICE?` for near-identical sentences in one paragraph.

Rewrite the draft as speech, place `{t}` markers against the timings, get the owner's OK, then render. Once `voice-<id>.*` is bundled the topic opens Narrated.

Markers are placed by hand (owner, 2026-11-03): an automatic cue tool was tried and removed, because it tied labels to the wrong word, missed every move with no label, and landed 1.7 to 3.7 s off the hand-placed cues on superglue and seasons. `moments` lists each label's timing and the moves with no label, so both can be marked.

`render <id> --out DIR` is a dry run into DIR (bundled files untouched). Python for Kokoro: env `KOKORO_PY`, else `~/kokoro-venv/bin/python`, else `~/yozora-launch-film/.venv/bin/python`.

## Pacing: keep moves brisk (owner, 2026-11-03)

Markers stretch the picture's clock between them, so a move that takes 0.5 s of picture time crawls if its two nearest markers sit on words several seconds apart (a hop took 3.5 s, a tick 9 s in card payment). Put the marker at the start of a move on the word where it should begin and the next marker a few words later (0.4 to 1 s of speech); two markers with the same picture time hold the picture still in between. Check each move's real duration in `voice-<id>.json` `keys` before the owner sees it.

## render.py

`render.py` turns a script (one paragraph = one beat) into `voice-<name>.m4a` plus a
`voice-<name>.json` with the voice, duration, beat start times and per-word times.

Picture keyframes: `{1.6}word` marks picture time 1.6 s at that word's start; a marker ending a paragraph (`when.{3.4}`) marks the last word's end. Markers are stripped before TTS; the JSON gets `keys` (per beat, `[sec_from_beat_start, t]` pairs).

    brew install espeak-ng
    python3.11 -m venv ~/kokoro-venv && ~/kokoro-venv/bin/pip install kokoro soundfile
    ~/kokoro-venv/bin/python render.py shazam.txt ../../ios/Polymath/Resources [--voice af_heart] [--speed 1.0]

First run downloads the model (~330 MB) and a spaCy model into the venv/HF cache, not the repo.

## Sarvam Bulbul engine

`--engine bulbul [--speaker shubh] [--variant bulbul]` renders each beat with Sarvam's `bulbul:v3` (en-IN, 24 kHz WAV) and writes `voice-<name>-bulbul.*` with the same JSON. The API returns no timings, so every beat is force-aligned to its known words with torchaudio's MMS_FA model (`pip install --no-deps torchaudio`, plus `num2words`; ~1.2 GB model cached in `~/.cache/torch` on first use).
Key: `SARVAM_API_KEY` in the environment, or a line `SARVAM_API_KEY=...` in `tools/voice/.env` (git-ignored; never printed).
