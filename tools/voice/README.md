# Offline narration (Kokoro-82M)

`render.py` turns a script (one paragraph = one beat) into `voice-<name>.m4a` plus a
`voice-<name>.json` with the voice, duration, beat start times and per-word times.

    brew install espeak-ng
    python3.11 -m venv ~/kokoro-venv && ~/kokoro-venv/bin/pip install kokoro soundfile
    ~/kokoro-venv/bin/python render.py shazam.txt ../../ios/Polymath/Resources [--voice af_heart] [--speed 1.0]

First run downloads the model (~330 MB) and a spaCy model into the venv/HF cache, not the repo.
