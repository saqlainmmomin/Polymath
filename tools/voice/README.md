# Offline narration (Kokoro-82M)

## Making a topic Narrated

    python3 narrate.py new <id>       # drafts <id>.txt from the cards, prints each picture's timings
    python3 narrate.py moments <id>   # timings again: picture length and when each label appears
    python3 narrate.py render <id>    # checks one paragraph per card, renders with Kokoro, regenerates the Xcode project

Rewrite the draft as speech, place `{t}` markers against the timings, get the owner's OK, then render. Once `voice-<id>.*` is bundled the topic opens Narrated.

## Automatic cue placing (`narrate.py cues` / `render`)

You no longer place `{t}` markers by hand. Write the script (one paragraph per card), get it approved, then:

    python3 narrate.py cues <id>              # prints the proposed markers and what it could not place; changes nothing
    python3 narrate.py render <id>            # does it all: render once without markers (temp dir) for word times, place markers, write them into <id>.txt, render into ios/Polymath/Resources, xcodegen
    python3 narrate.py render <id> --out DIR  # dry run into DIR (markers go to DIR/<id>.txt, bundled files untouched)

Python for Kokoro: env `KOKORO_PY`, else `~/kokoro-venv/bin/python`, else `~/yozora-launch-film/.venv/bin/python`.

What it does: reads each card's picture struct (style from the topic's `"style"`: `BP`, `DR`, `WF`, `AB`) and its label calls (`AB.label`, `DR.label`, `WF.label`, `bpLeader`, `bpText`, each with a constant `BP.pr(t, a, b)`), then ties each label, in order of `a`, to the next word the narrator says that is a distinctive word of the label (the label's rarest word in the paragraph, plurals folded). The marker is picture time = middle of the label's appearance, at that word's start; a last marker at the final word's end holds the picture at its full length.

What to check in its output:
- `FLAG ... not placed`: no spoken match, out of speech order, a computed timing it cannot read, or the word sits far from where the label sits in the picture (over 40% of the beat apart). It never guesses: fix by rewording the script so the word is said, or hand-mark that word.
- `unanchored`: things that happen in the picture with no label (a spot growing, an eye turning). They ride on interpolation between markers; hand-mark them if they look off.
- Markers already in the script are kept and win, and a re-run keeps what is there. `--fresh` ignores them and places everything again. After the owner moves a cue, edit that marker in `<id>.txt` and run `render` again.

How well it matches hand placing (afterimage, shazam, car-engine; scripts stripped of markers, compared with the committed `voice-*.json`): see `tasks/fix-log.md`, 2026-11-03.

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
