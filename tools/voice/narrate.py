"""Make a topic Narrated: draft its script, place picture cues automatically, render the voice, bundle it.

    python3 narrate.py new <id>       # writes <id>.txt from the topic's cards (one paragraph per card) and prints picture timings
    python3 narrate.py moments <id>   # prints each card's picture: length and when each label appears
    python3 narrate.py cues <id> [--fresh] [--write] [--compare]
                                      # renders the script once (no markers, temp dir) for word times, reads every picture label's
                                      # start time from the Swift source, and proposes the {t} markers that tie each label to the
                                      # word the narrator says for it. Prints the proposal and what it could not place.
                                      #   --fresh    ignore markers already in the script (default: they are kept and win)
                                      #   --write    write the proposed markers into <id>.txt
                                      #   --compare  also compare with the keys in the bundled voice-<id>.json (hand-placed)
    python3 narrate.py render <id> [--voice af_heart] [--speed 1.0] [--fresh] [--out DIR]
                                      # cues + write markers into <id>.txt, then renders voice-<id>.m4a/.json into ios/Polymath/Resources
                                      # and regenerates the Xcode project (--out DIR: dry run into DIR)

Kokoro Python: env KOKORO_PY, else ~/kokoro-venv/bin/python, else ~/yozora-launch-film/.venv/bin/python.

The script is a draft until the owner approves it (spine-first, see RECIPE.md). Markers: `{1.6}word` = picture time 1.6 s as that
word starts, `word{1.6}` = as it ends (render.py). Between markers the picture moves in straight lines; with none, it plays at its own pace.
Only cards of type "card" are beats; the "more" card is not narrated. Once voice-<id>.* is bundled the app opens the topic Narrated.

How cues are placed. Labels are read from the picture struct of each card (AB.label, DR.label, WF.label, bpLeader, bpText with a
constant `BP.pr(t, a, b)` timing). Per beat, in order of start time a, each label is matched to the next unused word the narrator
says that is a distinctive word of the label (stop words skipped, plurals and -ing/-ed folded). The marker is (picture time a, that
word's start). Markers already in the script are kept; a label that conflicts with them, comes out of speech order, or has no spoken
match is flagged, never guessed. A final marker at the last word's end holds the picture at its full length. Things that are not labels
(a spot growing, an eye turning) cannot be inferred: they are listed as "unanchored" with their time ranges and ride on interpolation.
Run `render` again after editing: markers now in the script count as hand-placed; use --fresh to place everything again.
"""
import argparse, json, os, re, shutil, subprocess, sys, tempfile
from pathlib import Path

VOICE = Path(__file__).resolve().parent
ROOT = VOICE.parent.parent
APP = ROOT / "ios" / "Polymath"
STYLE_PREFIX = {"blueprint": "BP", "drafting": "DR", "wireframe": "WF", "airbrush": "AB"}


def kokoro_py():
    for p in (os.environ.get("KOKORO_PY"), Path.home() / "kokoro-venv/bin/python", Path.home() / "yozora-launch-film/.venv/bin/python"):
        if p and Path(p).exists():
            return str(p)
    sys.exit("No Kokoro Python: set KOKORO_PY, or see README.md")


def topic(tid):
    f = APP / "Topics" / f"{tid}.json"
    if not f.exists():
        sys.exit(f"No topic {f.relative_to(ROOT)}")
    return json.loads(f.read_text())


def beats_of(t):
    return [c for c in t["cards"] if c["type"] == "card"]


def draft(t):
    """One paragraph per card: the topic's question opens, then each card's title, text and hook (takeaway on the last)."""
    paras = []
    for i, c in enumerate(beats_of(t)):
        parts = ([t["title"]] if i == 0 else []) + [c.get("title", ""), c.get("text", ""), c.get("hook") or c.get("takeaway") or ""]
        parts = [p.strip() for p in parts if p.strip()]
        paras.append(" ".join(p if p[-1] in ".?!" else p + "." for p in parts))
    return "\n\n".join(paras) + "\n"


def pictures(t):
    """Struct name per card, read from Pictures.swift (the style's version where a card has more than one)."""
    src = (APP / "Pictures.swift").read_text()
    m = re.search(r'if topic\.id == "%s" \{(.*?)\n        \}' % re.escape(t["id"]), src, re.S)
    if not m:
        return {}
    prefix = STYLE_PREFIX.get(t.get("style", "blueprint"), "BP")
    out = {}
    for case, line in re.findall(r"case (\d+): (.*)", m.group(1)):
        names = re.findall(r"AnyView\((\w+)\(", line)
        out[int(case)] = next((n for n in names if prefix in n), names[0] if names else None)
    return out


def struct_body(name):
    for f in APP.glob("*.swift"):
        s = f.read_text()
        m = re.search(r"\nstruct %s\b.*?(?=\nstruct |\Z)" % name, s, re.S)
        if m:
            return m.group(0)
    return ""


STR = r'"((?:[^"\\]|\\.)*)"'
LABEL_FORMS = [  # (regex over one source line, group 1 = the label text)
    re.compile(r"\b(?:AB|DR|WF)\.label\(&\w+, " + STR),
    re.compile(r"\bbpLeader\(.*?\btext: " + STR),
    re.compile(r"\bbpText\(&\w+, " + STR),
]
PR = re.compile(r"BP\.pr\((\w+), ([\d.]+), ([\d.]+)\)")
STOP = set("a an and are as at be by can do does for from get got has have how i if in into is it its just like of on one or so than that the their them then there they this to up us was we were what when where which who why will with you your yours not no but out all any each".split())


def picture_length(body):
    m = re.search(r"length: ([\d.]+)", body) or re.search(r"\bstory\s*=\s*([\d.]+)", body)
    return float(m.group(1)) if m else None


def read_labels(body):
    """-> (labels [(a, b, text)], unreadable [text], other [(a, b)]): label calls with a constant BP.pr timing, label calls whose
    timing is computed, and every other constant BP.pr range in the picture (the things that happen but have no words)."""
    lines = body.split("\n")
    labels, unreadable, used = [], [], set()
    for n, line in enumerate(lines):
        for form in LABEL_FORMS:
            m = form.search(line)
            if not m:
                continue
            text = m.group(1).replace("\\n", " ")
            span = "\n".join(lines[n:n + 3]) if "BP.pr" not in line[m.end():] else line[m.end():]
            p = PR.search(span)
            if p:
                labels.append((float(p.group(2)), float(p.group(3)), text)); used.add((n, p.group(0)))
            else:
                unreadable.append(text)
            break
    other = set()
    for n, line in enumerate(lines):
        for p in PR.finditer(line):
            if (n, p.group(0)) not in used and not any(abs(n - u) <= 2 and p.group(0) == g for u, g in used):
                other.add((float(p.group(2)), float(p.group(3))))
    return sorted(labels), unreadable, sorted(other)


def moments(t):
    pics = pictures(t)
    for i, c in enumerate(beats_of(t)):
        name = pics.get(i)
        body = struct_body(name) if name else ""
        length = picture_length(body)
        print(f"\nBeat {i + 1}: {name or 'no picture'}" + (f", {length:g} s" if length else ""))
        labels, unreadable, other = read_labels(body)
        for a, b, text in labels:
            print(f"  {a:g}-{b:g}  {text}")
        for text in unreadable:
            print(f"  ?  {text}  (timing is computed in the code)")
        for note in (c.get("visual") or {}).get("notes", []):
            print(f"  note: {note}")


# ---- cues -------------------------------------------------------------------------------------------------------------

MARK = re.compile(r"\{(\d+(?:\.\d+)?)\}")


def parse_script(text):
    """-> per paragraph: (tokens, marks [(word_index, 'start'|'end', t)]). Same reading of markers as render.py."""
    out = []
    for para in [p for p in text.strip().split("\n\n") if p.strip()]:
        words, marks, pending = [], [], []
        for tok in para.split():
            while (m := re.match(r"\{(\d+(?:\.\d+)?)\}", tok)):
                pending.append(float(m.group(1))); tok = tok[m.end():]
            trailing = []
            while (m := re.search(r"\{(\d+(?:\.\d+)?)\}$", tok)):
                trailing.insert(0, float(m.group(1))); tok = tok[:m.start()]
            if not tok:
                continue
            marks += [(len(words), "start", t) for t in pending]; pending = []
            words.append(tok)
            marks += [(len(words) - 1, "end", t) for t in trailing]
        marks += [(len(words) - 1, "end", t) for t in pending]
        out.append((words, marks))
    return out


def write_script(beats):
    paras = []
    for words, marks in beats:
        toks = list(words)
        for i, edge, t in sorted(marks, key=lambda m: (m[0], m[1] == "end")):
            s = ("%.2f" % t).rstrip("0"); s += "0" if s.endswith(".") else ""
            toks[i] = ("{%s}%s" % (s, toks[i])) if edge == "start" else ("%s{%s}" % (toks[i], s))
        paras.append(" ".join(toks))
    return "\n\n".join(paras) + "\n"


def render_words(tid, beats, voice, speed):
    """Render the script without markers into a temp dir -> the render's json (words with start/end, beats)."""
    with tempfile.TemporaryDirectory() as tmp:
        (Path(tmp) / f"{tid}.txt").write_text("\n\n".join(" ".join(w) for w, _ in beats) + "\n")
        subprocess.run([kokoro_py(), str(VOICE / "render.py"), str(Path(tmp) / f"{tid}.txt"), tmp, "--voice", voice, "--speed", str(speed)],
                       check=True, stdout=subprocess.DEVNULL)
        return json.loads((Path(tmp) / f"voice-{tid}.json").read_text())


def stem(w):
    w = re.sub(r"'s$", "", w.lower())
    w = re.sub(r"[^a-z]", "", w)
    for suf in ("ing", "ed", "er", "es", "s", "ly"):
        if len(w) > len(suf) + 2 and w.endswith(suf):
            return w[:-len(suf)]
    return w


def keywords(label):
    return [w for w in re.findall(r"[a-z']+", label.lower()) if w not in STOP and len(w) > 1]


def compatible(keys, new):
    """keys sorted by word index; `new` = (word_index, t) fits if picture times stay non-decreasing and words strictly increase."""
    allk = sorted(keys + [new])
    if len({k[0] for k in allk}) != len(allk):
        return False
    return all(a[1] <= b[1] for a, b in zip(allk, allk[1:]))


LEAD = 0.5       # the marker puts the label this far (of its a-b window) into its appearance as the word starts
DRIFT = 0.4      # a match is refused when the word sits this much further along the beat than the label does along the picture


def place(words, hand, labels, unreadable, other, length, dur):
    """words: spoken words of the beat as [text, start, end]. hand: [(index, 'start'|'end', t)] already in the script.
    -> (new_marks, notes, who): who maps a new marker's word index to the label (a, b, text) behind it."""
    stems = [stem(w[0]) for w in words]
    keys = [(i, t) for i, e, t in hand]                      # (word index, picture time) for the order check
    new, notes, cursor, who = [], [], -1, {}
    hand_idx = {i for i, e, t in hand if e == "start"}
    for a, b, text in labels:
        # the label's rarest distinctive word in this paragraph (ties: label order), first time it is spoken after the last match
        cands = []
        for n, kw in enumerate(keywords(text)):
            k = stem(kw)
            idx = next((j for j in range(cursor + 1, len(words)) if stems[j] == k), None)
            if idx is not None:
                cands.append((stems.count(k), n, idx, kw))
        found = min(cands)[2:] if cands else None
        if found is None:
            seen = any(stem(kw) in stems[:cursor + 1] for kw in keywords(text))
            notes.append(f"FLAG {text!r} ({a:g}-{b:g}): " + ("only spoken before an earlier label's word, out of speech order" if seen else "no spoken match") + "; not placed")
            continue
        idx, kw = found
        tt = a + LEAD * (b - a)
        if length and abs(words[idx][1] / dur - a / length) > DRIFT:
            notes.append(f"FLAG {text!r} ({a:g}-{b:g}): the only match, {words[idx][0]!r}, is at {words[idx][1] / dur:.0%} of the beat but the label is at {a / length:.0%} of the picture; not placed")
            continue
        if idx in hand_idx or not compatible(keys, (idx, tt)):
            notes.append(f"FLAG {text!r} ({a:g}-{b:g}): word {words[idx][0]!r} conflicts with markers already in the script; not placed")
            continue
        keys.append((idx, tt)); new.append((idx, "start", tt)); who[idx] = (a, b, text); cursor = idx
        notes.append(f"  {text!r} {a:g}-{b:g} -> {words[idx][0]!r} at {words[idx][1]:.2f}s")
    last = len(words) - 1
    if length and not any(e == "end" and i == last for i, e, t in hand) and (not keys or max(t for _, t in keys) < length):
        if compatible(keys, (last, length)) or all(i != last for i, _ in keys):
            new.append((last, "end", length)); notes.append(f"  hold: picture length {length:g} at the end of {words[last][0]!r} ({words[last][2]:.2f}s)")
    return new, notes, who


def hand_time(keys, t):
    """The seconds (from the beat start) at which hand-placed keys [[sec, t], ...] have the picture at time t, or None."""
    pts = [(0.0, 0.0)] + [(s, v) for s, v in keys]
    for (s0, v0), (s1, v1) in zip(pts, pts[1:]):
        if v0 <= t <= v1 and v1 > v0:
            return s0 + (s1 - s0) * (t - v0) / (v1 - v0)
    return None


def cues(t, script, voice, speed, fresh, write, compare):
    tid = t["id"]
    beats = parse_script(script.read_text())
    if len(beats) != len(beats_of(t)):
        sys.exit(f"{script.name} has {len(beats)} paragraphs; {tid} has {len(beats_of(t))} cards")
    if fresh:
        beats = [(w, []) for w, _ in beats]
    r = render_words(tid, beats, voice, speed)
    pics = pictures(t)
    out, wi, diffs, skipped = [], 0, [], []
    ref = None
    if compare:
        f = APP / "Resources" / f"voice-{tid}.json"
        ref = json.loads(f.read_text())["keys"] if f.exists() else None
    for bi, (words, hand) in enumerate(beats):
        name = pics.get(bi)
        body = struct_body(name) if name else ""
        length = picture_length(body)
        labels, unreadable, other = read_labels(body)
        w = r["words"][wi:wi + len(words)]; wi += len(words)
        base = r["beats"][bi]
        wr = [[x["text"], x["start"] - base, x["end"] - base] for x in w]
        dur = (r["beats"][bi + 1] if bi + 1 < len(r["beats"]) else r["duration"]) - base
        new, notes, who = place(wr, hand, labels, unreadable, other, length, dur)
        print(f"\nBeat {bi + 1}: {name or 'no picture'}" + (f", {length:g} s" if length else "") + f", {len(words)} words, {len(hand)} markers kept")
        for n in notes:
            print(n)
        for text in unreadable:
            print(f"FLAG {text!r}: timing is computed in the code; not placed")
        placed = [m[2] for m in new if m[1] == "start"] + [m[2] for m in hand]
        un = [(a, b) for a, b in other if not any(abs(a - p) < 0.35 for p in placed)]
        if un:
            print("  unanchored (no words tie these; they follow interpolation): " + ", ".join(f"{a:g}-{b:g}" for a, b in un))
        if ref:
            for i, e, tt in new:
                if e != "start":
                    continue
                lab = who[i]
                near = [k for k in ref[bi] if lab[0] - 0.25 <= k[1] <= lab[1] + 0.25]    # the hand marker(s) tied to this label's window
                if not near:
                    print(f"    vs hand: {lab[2]!r}: tool {wr[i][1]:.2f}s; the hand-placed keys have nothing in its window"); skipped.append(lab[2]); continue
                h = min(near, key=lambda k: abs(k[1] - tt))
                best = min(near, key=lambda k: abs(wr[i][1] - k[0]))        # the closest of the hand keys in that window
                diffs.append((bi + 1, tt, wr[i][1] - h[0], wr[i][1] - best[0])); print(f"    vs hand: {lab[2]!r}: tool {wr[i][1]:.2f}s, hand {h[0]:.2f}s (t={h[1]:g}), diff {wr[i][1] - h[0]:+.2f}")
        beats[bi] = (words, hand + new)
    if diffs:
        d, e = [abs(x[2]) for x in diffs], [abs(x[3]) for x in diffs]
        print(f"\nCompared {len(d)} label cues with the hand-placed keys: average {sum(d) / len(d):.2f}s, largest {max(d):.2f}s against the hand key nearest in picture time;"
              f" average {sum(e) / len(e):.2f}s, largest {max(e):.2f}s against the closest hand key in the label's window"
              + (f" ({len(skipped)} more had no hand key in their window)" if skipped else ""))
    if write:
        script.write_text(write_script(beats))
        print(f"\nWrote markers into {script}")
    return beats


def check(t, script):
    paras = [p for p in script.read_text().strip().split("\n\n") if p.strip()]
    n = len(beats_of(t))
    if len(paras) != n:
        sys.exit(f"{script.name} has {len(paras)} paragraphs; {t['id']} has {n} cards")
    for i, p in enumerate(paras):
        words = len(re.sub(r"\{[\d.]+\}", "", p).split())
        marks = len(re.findall(r"\{[\d.]+\}", p))
        print(f"  beat {i + 1}: {words} words, {marks} markers")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["new", "moments", "cues", "render"]); ap.add_argument("id")
    ap.add_argument("--voice", default="af_heart"); ap.add_argument("--speed", type=float, default=1.0)
    ap.add_argument("--fresh", action="store_true"); ap.add_argument("--write", action="store_true"); ap.add_argument("--compare", action="store_true")
    ap.add_argument("--out", help="render: bundle into this folder instead (a dry run: the markers go to <out>/<id>.txt, no Xcode project change)")
    a = ap.parse_args()
    t = topic(a.id)
    script = VOICE / f"{a.id}.txt"
    if a.cmd == "new":
        if script.exists():
            sys.exit(f"{script.name} exists; edit it, or delete it to draft again")
        script.write_text(draft(t))
        print(f"Drafted {script.relative_to(ROOT)} from the cards. Rewrite it as speech, get it approved, then: narrate.py render {a.id}")
        moments(t)
    elif a.cmd == "moments":
        moments(t)
    else:
        if not script.exists():
            sys.exit(f"No {script.name}; run: python3 narrate.py new {a.id}")
        check(t, script)
        dry = a.cmd == "render" and a.out
        if dry:
            Path(a.out).mkdir(parents=True, exist_ok=True)
            script = Path(shutil.copy(script, Path(a.out) / script.name))
        cues(t, script, a.voice, a.speed, a.fresh, a.write or a.cmd == "render", a.compare)
        if a.cmd == "render":
            subprocess.run([kokoro_py(), str(VOICE / "render.py"), str(script), a.out or str(APP / "Resources"),
                            "--voice", a.voice, "--speed", str(a.speed)], check=True)
            if dry:
                print(f"Dry run: voice and marked script are in {a.out}")
            else:
                subprocess.run(["xcodegen", "generate", "--quiet"], cwd=ROOT / "ios", check=True)
                print(f"Bundled. {a.id} now opens Narrated.")


if __name__ == "__main__":
    main()
