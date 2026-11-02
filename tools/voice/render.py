"""Offline narration: script.txt -> voice-<name>.m4a + voice-<name>.json (Kokoro-82M, or Sarvam Bulbul).

Setup (Python 3.11; torch/kokoro do not support 3.14), keep the venv outside the repo:
    brew install espeak-ng
    python3.11 -m venv ~/kokoro-venv && ~/kokoro-venv/bin/pip install kokoro soundfile
Run:
    ~/kokoro-venv/bin/python render.py shazam.txt ../../ios/Polymath/Resources [--voice af_heart] [--speed 1.0]

Paragraphs (blank-line separated) are beats, rendered one by one with 0.6 s of silence between.
The JSON holds the voice, total duration, beat start times and per-word times in the final audio.
Picture keyframe markers: `{1.6}word` = picture time 1.6 s at that word's start; a marker at the very end
of a paragraph (`when.{3.4}`) = at the last word's end. Markers are stripped before TTS; the JSON gets
`keys`: per beat, [[sec_relative_to_beat_start, t], ...].

Engines: `--engine kokoro` (default, offline, word times from the model) or `--engine bulbul` (Sarvam API, key in
$SARVAM_API_KEY or tools/voice/.env; the API returns no timings, so each beat's audio is force-aligned to its known
words with torchaudio's MMS_FA wav2vec2 CTC model). `--variant X` appends `-X` to the output names.
"""
import argparse, base64, io, json, os, re, subprocess, sys, tempfile, time, unicodedata
import urllib.error, urllib.request
from pathlib import Path

import numpy as np
import soundfile as sf

SR, GAP = 24000, 0.6
BULBUL_URL, BULBUL_MODEL, BULBUL_LANG, BULBUL_LIMIT = "https://api.sarvam.ai/text-to-speech", "bulbul:v3", "en-IN", 2500
BULBUL_SPEAKERS = ("shubh aditya ritu priya neha rahul pooja rohan simran kavya amit dev ishita shreya ratan varun manan "
                   "sumit roopa kabir aayan ashutosh advait anand tanya tarun sunny mani gokul vijay shruti suhani mohit "
                   "kavitha rehan soham rupali").split()
MARK = re.compile(r"\{(\d+(?:\.\d+)?)\}")


def parse_beat(para):
    """-> (clean text, [(word_index_in_beat, 'start'|'end', t)]). Markers attach by word index, not text."""
    words, marks, pending = [], [], []
    for tok in para.split():
        while (m := MARK.match(tok)):
            pending.append(float(m.group(1))); tok = tok[m.end():]
        trailing = []
        while (m := re.search(r"\{(\d+(?:\.\d+)?)\}$", tok)):
            trailing.insert(0, float(m.group(1))); tok = tok[:m.start()]
        if not tok:
            assert not trailing, "stray marker"
            continue
        assert "{" not in tok and "}" not in tok, f"marker not at word boundary: {tok}"
        marks += [(len(words), "start", t) for t in pending]; pending = []
        words.append(tok)
        marks += [(len(words) - 1, "end", t) for t in trailing]
    marks += [(len(words) - 1, "end", t) for t in pending]  # markers after the last word
    return " ".join(words), marks


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


# ---------------------------------------------------------------- Kokoro

def kokoro_engine(a):
    """-> synth(beat) yielding (audio float32 @SR, words [[text, start|None, end|None]] relative to the chunk)."""
    # espeakng-loader's bundled dylib looks for its data under the CI runner's path and exits on macOS;
    # point misaki at Homebrew's espeak-ng instead (`brew install espeak-ng`).
    import espeakng_loader
    ESPEAK = Path("/opt/homebrew/opt/espeak-ng")
    if ESPEAK.exists():
        espeakng_loader.get_library_path = lambda: str(ESPEAK / "lib/libespeak-ng.dylib")
        espeakng_loader.get_data_path = lambda: str(ESPEAK / "share/espeak-ng-data")
    from kokoro import KPipeline
    pipe = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")

    def synth(beat):
        for r in pipe(beat, voice=a.voice, speed=a.speed, split_pattern=None):
            yield r.audio.numpy().astype(np.float32), words_of(r.tokens)
    return synth


# ---------------------------------------------------------------- Forced alignment (any engine)

_FA = {}


def norm_word(w):
    """Aligner form of a word: lowercase letters and apostrophes only; digits spelled out."""
    w = w.replace("’", "'")
    w = re.sub(r"\d[\d,]*(?:\.\d+)?", lambda m: " " + _spell(m.group(0)) + " ", w)
    w = unicodedata.normalize("NFKD", w).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z']", "", w)


def _spell(num):
    from num2words import num2words
    num = num.replace(",", "")
    return num2words(float(num) if "." in num else int(num))


def ctc_viterbi(logp, tokens, blank=0):
    """Best CTC path: logp (T, C) log-probs, tokens list[int] -> per token (first_frame, last_frame_exclusive)."""
    T, L = logp.shape[0], len(tokens)
    ext = np.full(2 * L + 1, blank); ext[1::2] = tokens
    S = len(ext)
    assert T >= S // 2 + 1, "audio too short for transcript"
    neg = -1e30
    dp = np.full((T, S), neg); bp = np.zeros((T, S), dtype=np.int8)
    dp[0, 0], dp[0, 1] = logp[0, blank], logp[0, ext[1]]
    can_skip = np.zeros(S, dtype=bool)
    can_skip[2:] = (ext[2:] != blank) & (ext[2:] != ext[:-2])
    for t in range(1, T):
        stay = dp[t - 1]
        prev = np.concatenate(([neg], dp[t - 1, :-1]))
        skip = np.concatenate(([neg, neg], dp[t - 1, :-2])); skip[~can_skip] = neg
        cand = np.stack([stay, prev, skip])
        bp[t] = cand.argmax(0)
        dp[t] = cand.max(0) + logp[t, ext]
    s = S - 1 if dp[T - 1, S - 1] >= dp[T - 1, S - 2] else S - 2
    path = np.zeros(T, dtype=int)
    for t in range(T - 1, -1, -1):
        path[t] = s
        s -= int(bp[t, s])
    spans = []
    for k in range(L):
        fr = np.nonzero(path == 2 * k + 1)[0]
        spans.append((int(fr[0]), int(fr[-1]) + 1))
    return spans


def align_words(audio, sr, words):
    """Force-align known `words` to `audio` -> [(start_s, end_s)] per word (None for words with no letters)."""
    import torch, torchaudio
    if "fa" not in _FA:
        bundle = torchaudio.pipelines.MMS_FA
        _FA.update(fa=bundle, model=bundle.get_model(with_star=False).eval(), dict=bundle.get_dict(star=None))
    bundle, model, vocab = _FA["fa"], _FA["model"], _FA["dict"]
    wav = torch.from_numpy(np.asarray(audio, dtype=np.float32))[None]
    wav = torchaudio.functional.resample(wav, sr, bundle.sample_rate)
    with torch.inference_mode():
        emission, _ = model(wav)
    logp = torch.log_softmax(emission[0], -1).numpy()
    dt = (wav.shape[1] / bundle.sample_rate) / logp.shape[0]
    toks, owner = [], []  # owner[i] = word index of token i
    for wi, w in enumerate(words):
        for ch in norm_word(w):
            toks.append(vocab[ch]); owner.append(wi)
    spans = ctc_viterbi(logp, toks) if toks else []
    out = [None] * len(words)
    for (f0, f1), wi in zip(spans, owner):
        s, e = f0 * dt, f1 * dt
        out[wi] = (s, e) if out[wi] is None else (out[wi][0], e)
    return out


def aligned_chunk(audio, sr, words):
    """-> (audio, [[text, start, end]]) with times from forced alignment (None where a word has no letters)."""
    times = align_words(audio, sr, words)
    return audio, [[w, *(t if t else (None, None))] for w, t in zip(words, times)]


# ---------------------------------------------------------------- Sarvam Bulbul

def sarvam_key():
    """Key from $SARVAM_API_KEY, else tools/voice/.env. Never printed."""
    if os.environ.get("SARVAM_API_KEY", "").strip():
        return os.environ["SARVAM_API_KEY"].strip()
    env = Path(__file__).with_name(".env")
    if env.exists():
        for line in env.read_text().splitlines():
            m = re.match(r"\s*(?:export\s+)?SARVAM_API_KEY\s*=\s*(.*?)\s*$", line)
            if m and m.group(1).strip("'\""):
                return m.group(1).strip("'\"")
    sys.exit("No Sarvam key: set SARVAM_API_KEY or put a line SARVAM_API_KEY=... in tools/voice/.env")


def split_text(text, limit=BULBUL_LIMIT - 100):
    """Pack sentences into pieces <= limit chars; a lone over-long sentence is split at spaces."""
    if len(text) <= limit:
        return [text]
    pieces, cur = [], ""
    for sent in re.split(r"(?<=[.!?])\s+", text):
        while len(sent) > limit:
            cut = sent.rfind(" ", 0, limit); cut = cut if cut > 0 else limit
            if cur: pieces.append(cur); cur = ""
            pieces.append(sent[:cut]); sent = sent[cut:].lstrip()
        if cur and len(cur) + 1 + len(sent) > limit:
            pieces.append(cur); cur = ""
        cur = f"{cur} {sent}".strip()
    return pieces + ([cur] if cur else [])


def bulbul_request(key, text, speaker, pace, lang_field="language_code"):
    body = {"text": text, lang_field: BULBUL_LANG, "model": BULBUL_MODEL, "speaker": speaker, "pace": pace,
            "speech_sample_rate": SR, "output_audio_codec": "wav"}
    req = urllib.request.Request(BULBUL_URL, json.dumps(body).encode(), {
        "api-subscription-key": key, "Content-Type": "application/json"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            detail = e.read().decode(errors="replace")[:300]
            if e.code == 422 and lang_field == "language_code" and "language" in detail.lower():
                return bulbul_request(key, text, speaker, pace, "target_language_code")  # older API spelling
            if e.code in (429, 500, 502, 503, 504) and attempt < 3:
                time.sleep(2 * 2 ** attempt); continue
            sys.exit(f"Sarvam API error {e.code}: {detail}")
        except urllib.error.URLError as e:
            if attempt < 3:
                time.sleep(2 * 2 ** attempt); continue
            sys.exit(f"Sarvam API unreachable: {e.reason}")


def bulbul_synth_text(key, text, speaker, pace):
    """One request -> mono float32 audio at SR."""
    res = bulbul_request(key, text, speaker, pace)
    audio, sr = sf.read(io.BytesIO(base64.b64decode(res["audios"][0])), dtype="float32")
    if audio.ndim > 1:
        audio = audio.mean(1)
    assert sr == SR, f"expected {SR} Hz from Bulbul, got {sr}"
    return audio


def bulbul_engine(a):
    key = sarvam_key()
    if a.speaker not in BULBUL_SPEAKERS:
        sys.exit(f"Unknown {BULBUL_MODEL} speaker {a.speaker!r}; choose from: {' '.join(BULBUL_SPEAKERS)}")
    a.billed = 0

    def synth(beat):
        parts = []
        for piece in split_text(beat):
            a.billed += len(piece)
            parts.append(bulbul_synth_text(key, piece, a.speaker, a.speed))
        yield aligned_chunk(np.concatenate(parts), SR, beat.split())
    return synth


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("script"); ap.add_argument("out_dir")
    ap.add_argument("--engine", choices=["kokoro", "bulbul"], default="kokoro")
    ap.add_argument("--voice", default="af_heart", help="Kokoro voice")
    ap.add_argument("--speaker", default="shubh", help=f"Bulbul {BULBUL_MODEL} speaker")
    ap.add_argument("--speed", type=float, default=1.0, help="Kokoro speed / Bulbul pace")
    ap.add_argument("--variant", default="", help="suffix for output names: voice-<name>-<variant>.*")
    a = ap.parse_args()

    script = Path(a.script)
    text = script.read_text().strip()
    parsed = [parse_beat(p) for p in text.split("\n\n") if p.strip()]
    beats_text = [t for t, _ in parsed]
    clean_script = " ".join(beats_text)
    synth = {"kokoro": kokoro_engine, "bulbul": bulbul_engine}[a.engine](a)
    silence = np.zeros(int(GAP * SR), dtype=np.float32)

    chunks, words, beats, pos = [], [], [], 0  # pos = samples written so far
    for bi, beat in enumerate(beats_text):
        if bi:
            chunks.append(silence); pos += len(silence)
        beats.append(pos / SR)
        for audio, chunk_words in synth(beat):
            base = pos / SR
            for txt, s, e in chunk_words:
                words.append({"text": txt, "start": None if s is None else base + s,
                              "end": None if e is None else base + e})
            chunks.append(audio); pos += len(audio)

    fill_gaps(words)
    duration = pos / SR
    assert " ".join(w["text"] for w in words) == clean_script, "word text != script"
    for w in words:
        w["end"] = min(w["end"], duration)
    keys, wi = [], 0  # wi = index of the beat's first word in `words`
    for bi, (btxt, marks) in enumerate(parsed):
        length = (beats[bi + 1] if bi + 1 < len(beats) else duration) - beats[bi]
        ks = [[round(words[wi + i][edge] - beats[bi], 2), t] for i, edge, t in marks]
        assert all(a[0] <= b[0] for a, b in zip(ks, ks[1:])), f"beat {bi}: keys out of order {ks}"
        assert all(0 <= k[0] <= round(length, 2) for k in ks), f"beat {bi}: key outside beat (len {length:.2f}) {ks}"
        keys.append(ks); wi += len(btxt.split())
    for w in words:
        w["start"], w["end"] = round(w["start"], 2), round(w["end"], 2)

    name = f"voice-{script.stem}" + (f"-{a.variant}" if a.variant else "")
    voice = a.voice if a.engine == "kokoro" else f"{BULBUL_MODEL}:{a.speaker}"
    out = Path(a.out_dir); out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "v.wav"
        sf.write(wav, np.concatenate(chunks), SR)
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac@44100", "-b", "96000", str(wav),
                        str(out / f"{name}.m4a")], check=True)
    (out / f"{name}.json").write_text(json.dumps(
        {"voice": voice, "duration": round(duration, 2), "beats": [round(b, 2) for b in beats],
         "words": words, "keys": keys}, indent=1))
    print(f"{name}: {duration:.2f}s, {len(beats)} beats, {len(words)} words"
          + (f", {a.billed} characters sent to Sarvam" if a.engine == "bulbul" else ""))


if __name__ == "__main__":
    main()
