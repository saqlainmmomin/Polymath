# Offline narration (Kokoro-82M)

## Making a topic Narrated

    python3 narrate.py new <id>       # drafts <id>.txt from the cards, prints each picture's timings
    python3 narrate.py moments <id>   # timings again: picture length and when each label appears
    python3 narrate.py render <id>    # checks one paragraph per card, renders with Kokoro, regenerates the Xcode project

Rewrite the draft as speech, place `{t}` markers against the timings, get the owner's OK, then render. Once `voice-<id>.*` is bundled the topic opens Narrated.

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
