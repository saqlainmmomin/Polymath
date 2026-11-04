"""Scene files: check them, and grab frames of them from the simulator (tasks/scene-format.md).

    python3 scene.py check <id>                 # parts, params, ids, words said in order, and the picture's bounds
    python3 scene.py frames <id> [--card N] [--compare] [--out DIR]
                                                # frames at each move, from the booted simulator (the app must be installed:
                                                # ios/run.sh); --compare also grabs the hand-written Swift pictures (--no-scenes)

`check` exits non-zero on errors, so an agent writing scenes can loop on it. Words are matched against the topic's rendered voice
(`voice-<id>.json`); before the voice is rendered, against the script `tools/voice/<id>.txt`.
"""
import argparse, json, re, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
APP = ROOT / "ios" / "Polymath"
W, H = 343, 320
CORNER = (288, 235)          # the player's corner: keep labels out of x > 288, y > 235
PROPS = {"x", "y", "opacity", "scale", "rotate", "draw", "fill"}


def norm(w):
    return re.sub(r"[^a-z0-9]", "", w.lower())


def beat_words(tid):
    """Per beat: [(word, seconds into the beat)]. From the voice if rendered, else the script (times unknown: None)."""
    v = APP / "Resources" / f"voice-{tid}.json"
    if v.exists():
        d = json.loads(v.read_text())
        b = d["beats"] + [d["duration"] + 1]
        return [[(norm(w["text"]), w["start"] - b[i]) for w in d["words"] if b[i] - 0.01 <= w["start"] < b[i + 1] - 0.01] for i in range(len(d["beats"]))]
    s = ROOT / "tools" / "voice" / f"{tid}.txt"
    if s.exists():
        paras = [p for p in s.read_text().strip().split("\n\n") if p.strip()]
        return [[(norm(re.sub(r"\{[\d.]+\}", "", w)), None) for w in p.split() if norm(re.sub(r"\{[\d.]+\}", "", w))] for p in paras]
    return None


def part_names():
    src = (APP / "SceneParts.swift").read_text()
    return set(re.findall(r'"(\w+)"', re.search(r"static let names = \[(.*?)\]", src, re.S).group(1)))


# Rough extents of each part, relative to its `at`, before scale: (x0, y0, x1, y1). Standing parts have their feet at the origin.
PART_BOX = {"phone": (-46, -190, 55, 0), "battery": (-40, -166, 48, 0), "meter": (-20, -175, 27, 0), "snowflake": (-1, -1, 1, 1),
            "ground": (0, 0, 0, 0), "tank": (-70, -143, 80, 0), "playingCard": (-15, -21, 15, 21), "chips": (-14, -30, 14, 0),
            "terminal": (0, 0, 82, 118), "card": (-26, -17, 26, 17), "bank": (-45, -80, 45, 0), "shop": (-45, -80, 45, 0)}
DECOR = {"ground", "snowflake"}      # context: not counted when judging the hero's size and centring


def boxes(elements, ox=0.0, oy=0.0):
    """[(x0, y0, x1, y1)] of the things drawn (not labels, not text, not decoration), in design-space coordinates."""
    out = []
    for e in elements:
        if "label" in e or "text" in e or e.get("part") in DECOR:
            continue
        at = e.get("at") or [0, 0]
        k = e.get("scale", 1)
        if "group" in e:
            if e.get("clip") and "at" not in e:
                out += boxes(e["group"], ox, oy)
            else:
                out += boxes(e["group"], ox + at[0], oy + at[1])
        elif "part" in e:
            x0, y0, x1, y1 = PART_BOX.get(e["part"], (-30, -30, 30, 30))
            h = e.get("params", {}).get("h")
            if e["part"] == "tank" and h:
                y0 = -(h + 7)
            out.append((ox + at[0] + x0 * k, oy + at[1] + y0 * k, ox + at[0] + x1 * k, oy + at[1] + y1 * k))
        elif "circle" in e:
            cx, cy, r = e["circle"]
            out.append((ox + cx - r, oy + cy - r, ox + cx + r, oy + cy + r))
        elif "rect" in e:
            x, y, w, h = e["rect"][:4]
            out.append((ox + x, oy + y, ox + x + w, oy + y + h))
        elif "path" in e and not any(c in e["path"] for c in "mlhvcsqtz"):
            nums = [float(n) for n in re.findall(r"-?\d+\.?\d*", e["path"])]
            xs, ys = nums[0::2], nums[1::2]
            if xs and ys:
                out.append((ox + min(xs), oy + min(ys), ox + max(xs), oy + max(ys)))
    return out


def composition(scene, tag, warns):
    """Design checks on what the scene draws: centred, big enough, not in the player's corner."""
    bs = boxes(scene["elements"])
    if not bs:
        return
    x0, y0, x1, y1 = min(b[0] for b in bs), min(b[1] for b in bs), max(b[2] for b in bs), max(b[3] for b in bs)
    cx, cy, w, h = (x0 + x1) / 2, (y0 + y1) / 2, x1 - x0, y1 - y0
    if abs(cx - W / 2) > 24:
        warns.append(f"{tag}: the picture is off-centre sideways (its middle is x {cx:.0f}, the stage's is {W / 2:.0f}); move things so it balances")
    if cy < 105 or cy > 200:
        warns.append(f"{tag}: the picture sits too {'high' if cy < 105 else 'low'} (its middle is y {cy:.0f}, aim for about 150)")
    if h < 0.45 * H and w < 0.55 * W:
        warns.append(f"{tag}: the picture is small ({w:.0f} x {h:.0f} of {W} x {H}); draw bigger or add the objects around it")
    for b in bs:
        if b[2] > CORNER[0] + 1 and b[3] > CORNER[1] + 1 and (b[2] - b[0]) < 0.6 * W:
            warns.append(f"{tag}: something reaches into the player's corner (x to {b[2]:.0f}, y to {b[3]:.0f}); keep it left of x {CORNER[0]} or above y {CORNER[1]}")
            break


def walk(elements):
    for e in elements:
        yield e
        yield from walk(e.get("group", []))


def check(tid):
    f = APP / "Scenes" / f"{tid}.json"
    if not f.exists():
        sys.exit(f"No {f.relative_to(ROOT)}")
    try:
        data = json.loads(f.read_text())
    except json.JSONDecodeError as e:
        sys.exit(f"{f.name}: not valid JSON: {e}")
    parts, words = part_names(), beat_words(tid)
    errors, warns = [], []
    if words is None:
        warns.append("no voice or script yet: words not checked")
    for s in data["scenes"]:
        card = s["card"]
        tag = f"card {card + 1}"
        els = list(walk(s["elements"]))
        ids = {e["id"]: e for e in els if "id" in e}
        said = words[card] if words and card < len(words) else None
        if words and said is None:
            errors.append(f"{tag}: the script has no paragraph {card + 1}")

        def when(word, where):
            if word is None or said is None:
                return None
            w, _, n = word.partition("#")
            hits = [t for x, t in said if x == norm(w)]
            if len(hits) < int(n or 1):
                errors.append(f"{tag} {where}: {word!r} is not said" + (f" {n} times" if n else "") + " in this paragraph")
                return None
            return hits[int(n or 1) - 1]

        for e in els:
            kinds = [k for k in ("part", "path", "circle", "rect", "label", "text", "group") if k in e]
            what = e.get("id") or e.get("label") or e.get("part") or kinds[0] if kinds else "?"
            if len(kinds) != 1:
                errors.append(f"{tag} element {what!r}: needs exactly one of part, path, circle, rect, label, text, group (has {kinds or 'none'})")
            if "part" in e and e["part"] not in parts:
                errors.append(f"{tag}: unknown part {e['part']!r} (known: {', '.join(sorted(parts))})")
            when(e.get("word"), f"element {what!r}")
            if "label" in e:
                x, y = e.get("at", e.get("anchor", [0, 0]))
                if not (0 <= x <= W and 0 <= y <= H):
                    warns.append(f"{tag} label {e['label']!r}: text at {x:g}, {y:g} is outside {W} x {H}")
                if x > CORNER[0] and y > CORNER[1]:
                    warns.append(f"{tag} label {e['label']!r}: text at {x:g}, {y:g} sits in the player's corner (x > {CORNER[0]}, y > {CORNER[1]})")
                if any(len(line.split()) > 4 for line in e["label"].split("\n")):
                    warns.append(f"{tag} label {e['label']!r}: over 4 words on a line")
        times = []
        for m in s.get("moves", []):
            e = ids.get(m["move"])
            if e is None:
                errors.append(f"{tag}: move on unknown id {m['move']!r}")
                continue
            if m["prop"] not in PROPS and m["prop"] not in e.get("params", {}):
                errors.append(f"{tag}: move {m['move']}.{m['prop']}: not a prop ({', '.join(sorted(PROPS))}) or one of its params")
            if "word" not in m and "at" not in m:
                errors.append(f"{tag}: move {m['move']}.{m['prop']} needs a word or an at")
            t = when(m.get("word"), f"move {m['move']}.{m['prop']}")
            if t is not None:
                times.append(t + m.get("delay", 0) + m.get("dur", 0.5))
        if said and said[0][1] is not None and times and max(times) > said[-1][1] + 1.5:
            warns.append(f"{tag}: a move ends {max(times) - said[-1][1]:.1f} s after the last word starts")
        composition(s, tag, warns)
        print(f"{tag}: {len(els)} elements, {len(s.get('moves', []))} moves")
    for w in warns:
        print("  warn: " + w)
    for e in errors:
        print("  ERROR: " + e)
    print("OK" if not errors else f"{len(errors)} errors")
    return not errors


def frames(tid, card, compare, out, sim, bundle):
    d = json.loads((APP / "Resources" / f"voice-{tid}.json").read_text())
    data = json.loads((APP / "Scenes" / f"{tid}.json").read_text())
    words = beat_words(tid)
    out = Path(out); out.mkdir(parents=True, exist_ok=True)
    shots = []
    for s in data["scenes"]:
        if card is not None and s["card"] != card - 1:
            continue
        b, said = s["card"], words[s["card"]]

        def at(m):
            if "at" in m:
                return m["at"] + m.get("delay", 0)
            w, _, n = m["word"].partition("#")
            hits = [t for x, t in said if x == norm(w)]
            return (hits[int(n or 1) - 1] if len(hits) >= int(n or 1) else 0) + m.get("delay", 0)

        ts = sorted({round(at(m) + m.get("dur", 0.5) * 0.6, 2) for m in s.get("moves", []) if "word" in m or "at" in m} | {1.0, said[-1][1] + 0.5})
        kept = []
        for t in ts:                     # one frame per moment: moves within 0.6 s share a frame
            if not kept or t - kept[-1] >= 0.6:
                kept.append(t)
        for t in kept:
            for mode in ["scene"] + (["swift"] if compare else []):
                subprocess.run(["xcrun", "simctl", "terminate", sim, bundle], capture_output=True)
                args = ["-profile.onboarded", "YES", "--topic", tid, "--seek", f"{d['beats'][b] + t:.2f}"] + (["--no-scenes"] if mode == "swift" else [])
                subprocess.run(["xcrun", "simctl", "launch", sim, bundle] + args, check=True, capture_output=True)
                time.sleep(2.5)
                png = out / f"card{b + 1}-{t:05.2f}-{mode}.png"
                subprocess.run(["xcrun", "simctl", "io", sim, "screenshot", str(png)], check=True, capture_output=True)
                subprocess.run(["sips", "-c", "1160", "1206", "--cropOffset", "560", "0", str(png)], capture_output=True)   # the picture area on a 6.3" phone
                subprocess.run(["sips", "-Z", "520", str(png)], capture_output=True)
                shots.append(png)
    for p in shots:
        print(p)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["check", "frames"]); ap.add_argument("id")
    ap.add_argument("--card", type=int, help="frames: only this card (1-based)")
    ap.add_argument("--compare", action="store_true", help="frames: also the Swift pictures")
    ap.add_argument("--out", default=str(ROOT / "ios" / "build" / "frames"))
    ap.add_argument("--sim", default="booted"); ap.add_argument("--bundle", default="com.saqlainmomin.polymath")
    a = ap.parse_args()
    if a.cmd == "check":
        sys.exit(0 if check(a.id) else 1)
    frames(a.id, a.card, a.compare, a.out, a.sim, a.bundle)


if __name__ == "__main__":
    main()
