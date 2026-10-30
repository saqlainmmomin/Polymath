"""Offline narration with Kokoro-82M: script.txt -> voice-<name>.m4a + voice-<name>.json.

Setup (Python 3.11; torch/kokoro do not support 3.14), keep the venv outside the repo:
    brew install espeak-ng
    python3.11 -m venv ~/kokoro-venv && ~/kokoro-venv/bin/pip install kokoro soundfile
Run:
    ~/kokoro-venv/bin/python render.py shazam.txt ../../ios/Polymath/Resources [--voice af_heart] [--speed 1.0]

Paragraphs (blank-line separated) are beats, rendered one by one with 0.6 s of silence between.
The JSON holds the voice, total duration, beat start times and per-word times in the final audio.
"""
import argparse, json, subprocess, tempfile
from pathlib import Path

import numpy as np
import soundfile as sf

# espeakng-loader's bundled dylib looks for its data under the CI runner's path and exits on macOS;
# point misaki at Homebrew's espeak-ng instead (`brew install espeak-ng`).
import espeakng_loader
ESPEAK = Path("/opt/homebrew/opt/espeak-ng")
if ESPEAK.exists():
    espeakng_loader.get_library_path = lambda: str(ESPEAK / "lib/libespeak-ng.dylib")
    espeakng_loader.get_data_path = lambda: str(ESPEAK / "share/espeak-ng-data")
from kokoro import KPipeline

SR, GAP = 24000, 0.6


def words_of(tokens):
    """Merge misaki tokens into whitespace-separated words: [text, start, end] (times may be None)."""
    out, cur = [], None
    for t in tokens:
        if cur is None:
            cur = [t.text, t.start_ts, t.end_ts]
        else:
            cur[0] += t.text
            cur[1] = t.start_ts if cur[1] is None else cur[1]
            cur[2] = t.end_ts if t.end_ts is not None else cur[2]
        if t.whitespace:
            out.append(cur)
            cur = None
    if cur:
        out.append(cur)
    return out


def fill_gaps(words):
    """Interpolate missing times from neighbours (in place, absolute seconds)."""
    for i, w in enumerate(words):
        if w["start"] is None:
            w["start"] = words[i - 1]["end"] if i and words[i - 1]["end"] is not None else None
        if w["end"] is None:
            nxt = next((x["start"] for x in words[i + 1:] if x["start"] is not None), None)
            w["end"] = nxt if nxt is not None else w["start"]
        if w["start"] is None:
            w["start"] = w["end"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("script"); ap.add_argument("out_dir")
    ap.add_argument("--voice", default="af_heart"); ap.add_argument("--speed", type=float, default=1.0)
    a = ap.parse_args()

    script = Path(a.script)
    text = script.read_text().strip()
    beats_text = [" ".join(p.split()) for p in text.split("\n\n") if p.strip()]
    pipe = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
    silence = np.zeros(int(GAP * SR), dtype=np.float32)

    chunks, words, beats, pos = [], [], [], 0  # pos = samples written so far
    for bi, beat in enumerate(beats_text):
        if bi:
            chunks.append(silence); pos += len(silence)
        beats.append(pos / SR)
        for r in pipe(beat, voice=a.voice, speed=a.speed, split_pattern=None):
            audio = r.audio.numpy().astype(np.float32)
            base = pos / SR
            for txt, s, e in words_of(r.tokens):
                words.append({"text": txt, "start": None if s is None else base + s,
                              "end": None if e is None else base + e})
            chunks.append(audio); pos += len(audio)

    fill_gaps(words)
    duration = pos / SR
    assert " ".join(w["text"] for w in words) == " ".join(text.split()), "word text != script"
    for w in words:
        w["start"], w["end"] = round(w["start"], 2), round(min(w["end"], duration), 2)

    out = Path(a.out_dir); out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "v.wav"
        sf.write(wav, np.concatenate(chunks), SR)
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac@44100", "-b", "96000", str(wav),
                        str(out / f"voice-{script.stem}.m4a")], check=True)
    (out / f"voice-{script.stem}.json").write_text(json.dumps(
        {"voice": a.voice, "duration": round(duration, 2), "beats": [round(b, 2) for b in beats],
         "words": words}, indent=1))
    print(f"{script.stem}: {duration:.2f}s, {len(beats)} beats, {len(words)} words")


if __name__ == "__main__":
    main()
