"""Scene files: check them, and grab frames of them from the simulator (tasks/scene-format.md).

    python3 scene.py check <id>                 # parts, params, ids, words said in order, and the picture's bounds
    python3 scene.py frames <id> [--card N] [--compare] [--out DIR]
                                                # frames at each move, from the booted simulator (the app must be installed:
                                                # ios/run.sh); --compare also grabs the hand-written Swift pictures (--no-scenes)
    python3 scene.py lint <id> [--card N] [--out DIR]
                                                # after `frames`: re-grabs each frame without its words (--hide labels) and with nothing
                                                # (--hide all), and reports words printed on the picture, and cards that go blank

`check` exits non-zero on errors, so an agent writing scenes can loop on it. Words are matched against the topic's rendered voice
(`voice-<id>.json`); before the voice is rendered, against the script `tools/voice/<id>.txt`.
"""
import argparse, json, re, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
import flow, textfit      # B (text boxes) and E (same sides in every card): their own files
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


def names_in(file):
    src = (APP / file).read_text()
    return set(re.findall(r'"(\w+)"', re.search(r"static let names = \[(.*?)\]", src, re.S).group(1)))


def topic_style(tid):
    """The topic's style from its JSON: drafting (also for blueprint, which has no scene kit), wireframe or airbrush."""
    try:
        s = json.loads((APP / "Topics" / f"{tid}.json").read_text()).get("style", "drafting")
    except (OSError, json.JSONDecodeError):
        s = "drafting"
    return s if s in ("wireframe", "airbrush") else "drafting"


def part_names(style="drafting"):
    """Every part a scene in this style can name: the generic ones, plus the style's own kit."""
    kit = {"drafting": "SceneParts.swift", "wireframe": "WireframeParts.swift", "airbrush": "AirbrushParts.swift"}[style]
    return names_in("SceneGeneric.swift") | names_in(kit)


# Rough extents of each part, relative to its `at`, before scale: (x0, y0, x1, y1). Standing parts have their feet at the origin.
PART_BOX = {"drafting": {"phone": (-46, -190, 55, 0), "battery": (-40, -166, 48, 0), "meter": (-20, -175, 27, 0), "snowflake": (-1, -1, 1, 1),
                         "ground": (0, 0, 0, 0), "tank": (-70, -143, 80, 0), "playingCard": (-15, -21, 15, 21), "chips": (-14, -30, 14, 0),
                         "terminal": (0, 0, 82, 118), "card": (-26, -17, 26, 17), "bank": (-45, -80, 45, 0), "shop": (-45, -80, 45, 0),
                         "bike": (-105, -118, 105, 0), "gearPair": (-90, -62, 90, 62), "walker": (-14, -66, 18, 0)},
            "wireframe": {"wfPhone": (-35, -143, 44, 0), "satellite": (-44, -30, 44, 30), "tower": (-16, -126, 16, 0), "pin": (-9, -27, 9, 0),
                          "magnet": (-25, -18, 40, 18), "clock": (-16, -16, 16, 16), "moon": (-22, -22, 22, 22), "tideEarth": (-84, -67, 84, 67),
                          "dial": (-147, -60, 154, 52), "router": (-31, -70, 39, 0), "earbud": (-9, -38, 11, 0)},
            "airbrush": {"skinCut": (-130, 0, 130, 100), "nerve": (-10, -10, 10, 44), "brain": (-50, -36, 50, 44), "finger": (-13, 0, 13, 96),
                         "tub": (-65, -96, 65, 0), "molecule": (-14, -8, 14, 8), "eye": (-28, -15, 28, 13), "drop": (-8, -13, 8, 8),
                         "sun": (-26, -26, 26, 26), "person": (-32, -170, 32, 0), "earthLimb": (-160, -330, 160, -280)}}
# parts that set the scene rather than being the hero: not counted when judging the hero's size and centring
DECOR = {"ground", "snowflake", "arrow", "dim", "wave", "arc", "rings", "spray", "glow", "scatter"}


def boxes(elements, style, ox=0.0, oy=0.0, moves=(), sc=1.0):
    """[(x0, y0, x1, y1)] of the things drawn (not labels, not text, not decoration), in design-space coordinates.
    (ox, oy, sc) is the frame the elements sit in: a group's `at` and `scale`. Elements that move count where they start and end."""
    out = []
    for e in elements:
        if "label" in e or "text" in e or e.get("part") in DECOR or (e.get("part") == "globe" and e.get("params", {}).get("r", 0) > 100):
            continue      # (a globe bigger than 100 is a planet seen from space: scenery)
        at = e.get("at") or [0, 0]
        k = e.get("scale", 1)
        fin = {p: [m["to"] for m in moves if m["move"] == e.get("id") and m["prop"] == p] for p in ("x", "y")}
        if (fin["x"] or fin["y"]) and "_final" not in e:
            end = dict(e, _final=True, at=[fin["x"][-1] if fin["x"] else at[0], fin["y"][-1] if fin["y"] else at[1]])
            out += boxes([end], style, ox, oy, moves, sc)
        px, py = ox + sc * at[0], oy + sc * at[1]
        if "group" in e:
            if e.get("clip") and "at" not in e:
                out += boxes(e["group"], style, ox, oy, moves, sc)
            else:
                out += boxes(e["group"], style, px, py, moves, sc * k)
        elif "part" in e:
            x0, y0, x1, y1 = PART_BOX.get(style, {}).get(e["part"], (-30, -30, 30, 30))
            h = e.get("params", {}).get("h")
            if e["part"] == "tank" and h:
                y0 = -(h + 7)
            if e["part"] in ("globe", "moon") and e.get("params", {}).get("r"):
                r = e["params"]["r"]; x0, y0, x1, y1 = -r, -r, r, r
            out.append((px + x0 * k * sc, py + y0 * k * sc, px + x1 * k * sc, py + y1 * k * sc))
        elif "circle" in e:
            cx, cy, r = e["circle"]
            out.append((ox + sc * (cx - r), oy + sc * (cy - r), ox + sc * (cx + r), oy + sc * (cy + r)))
        elif "rect" in e:
            x, y, w, h = e["rect"][:4]
            out.append((ox + sc * x, oy + sc * y, ox + sc * (x + w), oy + sc * (y + h)))
        elif "path" in e and not any(c in e["path"] for c in "mlhvcsqtz"):
            nums = [float(n) for n in re.findall(r"-?\d+\.?\d*", e["path"])]
            xs, ys = nums[0::2], nums[1::2]
            if xs and ys:
                out.append((ox + sc * min(xs), oy + sc * min(ys), ox + sc * max(xs), oy + sc * max(ys)))
    return out


def composition(scene, tag, warns, style):
    """Design checks on what the scene draws: centred, big enough, not in the player's corner."""
    bs = boxes(scene["elements"], style, 0.0, 0.0, scene.get("moves", []))
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


# ---- timeline checks (C: end state and stalls, D: a label must not show before the thing it points at) -----------------------------
EASES = {"linear": lambda x: x, "eout": lambda x: 1 - (1 - x) ** 3, "snap": lambda x: x * x * (3 - 2 * x), "fall": lambda x: x * x}
STALL = 5.0     # seconds with no element starting and no move running before it is reported
EMPTY_END = 0.4    # the card ends with fewer than this share of the most things it ever showed: reported


def card_lengths(tid):
    v = APP / "Resources" / f"voice-{tid}.json"
    if not v.exists():
        return None
    d = json.loads(v.read_text())
    ends = d["beats"][1:] + [d["duration"]]
    return [e - b for b, e in zip(d["beats"], ends)]


def timeline_checks(sc, tag, said, length, style, errors, warns):
    """Simulates what the renderer draws (SceneRenderer.draw: hidden, `word` start, opacity moves, parent groups) every 0.1 s."""
    def hit(word):
        if word is None:
            return 0.0
        w, _, n = word.partition("#")
        hs = [t for x, t in said if x == norm(w)]
        return hs[int(n or 1) - 1] if len(hs) >= int(n or 1) else 0.0
    moves = sc.get("moves", [])
    leaves = []          # (element, chain of ancestors including itself, (ox, oy, scale) it sits in)

    def collect(els, chain, ox, oy, k):
        for e in els:
            c = chain + [e]
            if "group" in e:
                at = e.get("at") or [0, 0]
                collect(e["group"], c, ox + k * at[0], oy + k * at[1], k * e.get("scale", 1))
            else:
                leaves.append((e, c, (ox, oy, k)))
    collect(sc["elements"], [], 0.0, 0.0, 1.0)

    def opacity(e, t):
        v = 0.0 if e.get("hidden") else 1.0
        mine = sorted(((m.get("at", hit(m.get("word"))) + m.get("delay", 0), m) for m in moves if m["move"] == e.get("id") and m["prop"] == "opacity"), key=lambda x: x[0])
        for start, m in mine:
            d = max(m.get("dur", 0.5), 0.001)
            x = min(1.0, max(0.0, (t - start) / d))
            v += (m["to"] - v) * EASES.get(m.get("ease"), lambda y: y * y * (3 - 2 * y))(x)
        return v

    def shown(chain, t):
        return all(opacity(e, t) > 0.05 and t > hit(e.get("word")) + e.get("delay", 0) for e in chain)

    ts = [i * 0.1 for i in range(int(length * 10))]
    first = {id(e): next((t for t in ts if shown(c, t)), None) for e, c, _ in leaves}
    counts = [sum(1 for e, c, _ in leaves if shown(c, t)) for t in ts]
    # C1: the end state
    if counts and max(counts) > 0:
        tail = counts[-min(len(counts), 30):]
        if max(tail) == 0:
            errors.append(f"{tag}: nothing is drawn in the last 3 s (all {max(counts)} things have faded out or never show)")
        elif counts[-1] < EMPTY_END * max(counts):
            warns.append(f"{tag}: the card ends with {counts[-1]} things showing, from a peak of {max(counts)}: is something fading out that should stay?")
    # C2: starts visible although an opacity move says it fades in
    for e in walk(sc["elements"]):
        ups = sorted((m for m in moves if m["move"] == e.get("id") and m["prop"] == "opacity"), key=lambda m: m.get("at", hit(m.get("word"))) + m.get("delay", 0))
        if ups and not e.get("hidden") and not e.get("word") and ups[0]["to"] >= 0.99:
            errors.append(f"{tag}: {e['id']!r} has no `hidden` and no `word`, so it is on screen from the start; its opacity move to 1 does nothing (add \"hidden\": true)")
    # C3: a stall
    events = {0.0}
    for e in walk(sc["elements"]):
        if e.get("word"):
            events.add(hit(e["word"]) + e.get("delay", 0))
    for m in moves:
        a = m.get("at", hit(m.get("word"))) + m.get("delay", 0)
        events |= {a, a + m.get("dur", 0.5)}
    last = max((t for _, t in said if t is not None), default=length) + 1.0
    ev = sorted(t for t in events if t <= last) + [min(last, length)]
    for a, b in zip(ev, ev[1:]):
        if b - a > STALL:
            warns.append(f"{tag}: nothing starts or moves from {a:.1f} s to {b:.1f} s ({b - a:.1f} s): start something on a word in between")
    # D: a label shows only once the thing it points at is there
    def box_of(e, frame):
        ox, oy, k = frame
        bs = boxes([dict(e, at=e.get("at") or [0, 0])], style, ox, oy, [], k)
        return bs[0] if bs else None
    for e, c, frame in leaves:
        if "label" not in e or "anchor" not in e or first[id(e)] is None:
            continue
        ax, ay = e["anchor"]
        best = None
        for o, oc, of in leaves:
            if "label" in o or "text" in o or o is e:
                continue
            b = box_of(o, of)
            if b and b[2] - b[0] >= 8 and b[3] - b[1] >= 8 and b[0] - 6 <= ax <= b[2] + 6 and b[1] - 6 <= ay <= b[3] + 6:
                area = (b[2] - b[0]) * (b[3] - b[1])
                key = (oc[:-1] != c[:-1], area)       # things in the label's own group first, then the smallest
                if best is None or key < best[0]:
                    best = (key, o, oc)
            m = re.fullmatch(r"M\s*(-?[\d.]+)[ ,](-?[\d.]+)\s*L\s*(-?[\d.]+)[ ,](-?[\d.]+)", o.get("path", "").strip())
            if m and not of[0] and not of[1] and of[2] == 1:      # a straight line the anchor sits on (3 units)
                x1, y1, x2, y2 = map(float, m.groups())
                dx, dy = x2 - x1, y2 - y1
                u = min(1, max(0, ((ax - x1) * dx + (ay - y1) * dy) / max(dx * dx + dy * dy, 1e-6)))
                if (ax - (x1 + u * dx)) ** 2 + (ay - (y1 + u * dy)) ** 2 <= 9:
                    key = (oc[:-1] != c[:-1], 0)
                    if best is None or key < best[0]:
                        best = (key, o, oc)
        if best:
            best = (best[0], best[1])
        if best and first[id(best[1])] is not None:
            gap = best[1] and first[id(best[1])] - first[id(e)]
            name = best[1].get("id") or best[1].get("part") or best[1].get("path", "")[:18] or "its target"
            if gap > 2.0:
                errors.append(f"{tag}: label {e['label']!r} shows at {first[id(e)]:.1f} s but {name} only at {first[id(best[1])]:.1f} s: it points at nothing for {gap:.1f} s")
            elif gap > 0.4:
                warns.append(f"{tag}: label {e['label']!r} shows {gap:.1f} s before {name} (at {first[id(best[1])]:.1f} s)")


HELPERS = dict(boxes=boxes, walk=walk, PART_BOX=PART_BOX, DECOR=DECOR, W=W, H=H, CORNER=CORNER)


def check(tid):
    HELPERS["tid"] = tid
    f = APP / "Scenes" / f"{tid}.json"
    if not f.exists():
        sys.exit(f"No {f.relative_to(ROOT)}")
    try:
        data = json.loads(f.read_text())
    except json.JSONDecodeError as e:
        sys.exit(f"{f.name}: not valid JSON: {e}")
    style = topic_style(tid)
    parts, words = part_names(style), beat_words(tid)
    errors, warns = [], []
    if words is None:
        warns.append("no voice or script yet: words not checked")
    lengths = card_lengths(tid)
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
        composition(s, tag, warns, style)
        textfit.text_checks(s, tag, style, errors, warns, HELPERS)
        if said and lengths and card < len(lengths) and all(t is not None for _, t in said):
            timeline_checks(s, tag, said, lengths[card], style, errors, warns)
        print(f"{tag}: {len(els)} elements, {len(s.get('moves', []))} moves ({style})")
    flow.flow_checks(data["scenes"], style, errors, warns, HELPERS, tid)
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
        # elements that draw on a word (no move) get a frame too, 1 s after they start, if nothing is kept within 2 s of it
        starts = sorted({round(at({"word": e["word"], "delay": e.get("delay", 0)}) + 1.0, 2) for e in walk(s["elements"]) if e.get("word") and e["word"].partition("#")[0] and norm(e["word"].partition("#")[0]) in [x for x, _ in said]})
        for t in starts:
            if all(abs(t - k) >= 2.0 for k in kept):
                kept.append(t)
        kept.sort()
        while len(kept) > 12:            # cap: drop the frame closest to its neighbour
            i = min(range(1, len(kept) - 1), key=lambda j: kept[j + 1] - kept[j - 1])
            kept.pop(i)
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


# ---- lint: pixel check of the frames `frames` took ------------------------------------------------------------------------------
LINT_DIFF = 40        # a pixel differs between two frames when some channel differs by more than this
LINT_HIT = 60         # letter pixels (leaders are ignored) overlapping the picture, at 520 px wide, before it is reported
LINT_BLANK = 120      # a frame with fewer picture pixels than this, after BLANK_AFTER seconds into the card, is blank
BLANK_AFTER = 3.0
LINT_UNSTABLE = 40000   # more word pixels than this means the two shots are not the same moment (a transition): skip the frame
PX_K, PX_X0, PX_Y0 = 1.455, 10.3, 80.0    # design units -> pixels of a 520 px wide frame (measured on sky-blue card 3: x_px = 10.3 + 1.455 x, y_px = 80 + 1.455 y)


def shoot(sim, bundle, tid, seek, hide, png):
    subprocess.run(["xcrun", "simctl", "terminate", sim, bundle], capture_output=True)
    args = ["-profile.onboarded", "YES", "--topic", tid, "--seek", f"{seek:.2f}"] + (["--hide", hide] if hide else [])
    subprocess.run(["xcrun", "simctl", "launch", sim, bundle] + args, check=True, capture_output=True)
    time.sleep(2.5)
    subprocess.run(["xcrun", "simctl", "io", sim, "screenshot", str(png)], check=True, capture_output=True)
    subprocess.run(["sips", "-c", "1160", "1206", "--cropOffset", "560", "0", str(png)], capture_output=True)
    subprocess.run(["sips", "-Z", "520", str(png)], capture_output=True)


def lint(tid, card, out, sim, bundle):
    import numpy as np
    from PIL import Image
    out = Path(out)
    d = json.loads((APP / "Resources" / f"voice-{tid}.json").read_text())
    shots = sorted(out.glob("card*-*-scene.png"))
    if not shots:
        sys.exit(f"No frames in {out}: run `scene.py frames {tid}` first")
    scene_file = APP / "Scenes" / f"{tid}.json"
    shots = [x for x in shots if card is None or x.name.startswith(f"card{card}-")]
    stale = [x.name for x in shots if x.stat().st_mtime < scene_file.stat().st_mtime]
    if stale:
        sys.exit(f"{len(stale)} frames are older than {scene_file.name} (e.g. {stale[0]}): run `scene.py frames {tid}` again")
    ld = out / "lint"; ld.mkdir(exist_ok=True)
    img = lambda p: np.asarray(Image.open(p).convert("RGB"), dtype=np.int16)
    differs = lambda a, b: (np.abs(a - b).max(axis=2) > LINT_DIFF)

    def grow(m, n=1):      # dilate a mask by n pixels
        g = m.copy()
        for _ in range(n):
            g[1:, :] |= g[:-1, :]; g[:-1, :] |= g[1:, :]; g[:, 1:] |= g[:, :-1]; g[:, :-1] |= g[:, 1:]
        return g

    def erode(m):          # drop 1-2 px lines (leaders), keep letter strokes
        e = m.copy()
        e[1:, :] &= m[:-1, :]; e[:-1, :] &= m[1:, :]; e[:, 1:] &= m[:, :-1]; e[:, :-1] &= m[:, 1:]
        return e

    scenes = json.loads((APP / "Scenes" / f"{tid}.json").read_text())["scenes"]
    cards = {sc["card"]: [e for e in walk(sc["elements"]) if "label" in e] for sc in scenes}

    def leaders(b, shape):     # a mask over each label's leader (not its words), so a leader ending on its part is not a hit
        m = np.zeros(shape, bool)
        yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
        for e in cards.get(b, []):
            a = e.get("anchor", [0, 0]); to = e.get("at", a)
            ax, ay = PX_X0 + PX_K * a[0], PX_Y0 + PX_K * a[1]
            bx, by = PX_X0 + PX_K * (a[0] + 0.85 * (to[0] - a[0])), PX_Y0 + PX_K * (a[1] + 0.85 * (to[1] - a[1]))
            dx, dy = bx - ax, by - ay
            u = np.clip(((xx - ax) * dx + (yy - ay) * dy) / max(dx * dx + dy * dy, 1e-6), 0, 1)
            m |= (xx - (ax + u * dx)) ** 2 + (yy - (ay + u * dy)) ** 2 < 6 ** 2
            m |= (xx - ax) ** 2 + (yy - ay) ** 2 < 20 ** 2
        return m

    def allowed(b, shape):     # words that sit on the picture on purpose: "onpicture": true on the element
        m = np.zeros(shape, bool)
        yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
        for sc in scenes:
            if sc["card"] != b:
                continue
            for e in walk(sc["elements"]):
                if e.get("onpicture") and ("label" in e or "text" in e):
                    x, y = e.get("at", [0, 0])
                    m |= (xx - (PX_X0 + PX_K * x)) ** 2 + (yy - (PX_Y0 + PX_K * y)) ** 2 < 75 ** 2
        return m

    found, empties = [], {}
    for png in shots:
        m = re.match(r"card(\d+)-([\d.]+)-scene\.png", png.name)
        b, t = int(m[1]) - 1, float(m[2])
        if card is not None and b != card - 1:
            continue
        if b not in empties:
            ep = ld / f"card{b + 1}-empty.png"
            shoot(sim, bundle, tid, d["beats"][b] + 1.0, "all", ep)
            empties[b] = img(ep)
        bp = ld / png.name.replace("-scene", "-bare")
        shoot(sim, bundle, tid, d["beats"][b] + t, "labels", bp)
        bp2 = ld / png.name.replace("-scene", "-bare2")
        shoot(sim, bundle, tid, d["beats"][b] + t, "labels", bp2)
        full, bare, empty = img(png), img(bp), empties[b]
        noise = grow(differs(bare, img(bp2)), 2)           # parts of the picture that move between two shots of the same moment
        words, pic, anything = differs(full, bare), differs(bare, empty), differs(full, empty)
        if words.sum() > LINT_UNSTABLE:
            found.append(f"card {b + 1} t={t:g} s: frame is unstable (the two shots differ in {words.sum()} px), not checked")
            continue
        if t >= BLANK_AFTER and anything.sum() < LINT_BLANK:
            found.append(f"card {b + 1} t={t:g} s: BLANK, nothing drawn on the picture")
        if words.sum() < 25:
            continue
        hit = words & grow(pic, 1) & ~leaders(b, words.shape) & ~noise & ~allowed(b, words.shape)
        if hit.sum() >= LINT_HIT:
            ys, xs = np.nonzero(hit)
            found.append(f"card {b + 1} t={t:g} s: words overlap the picture ({hit.sum()} px, around x {xs.min()}-{xs.max()}, y {ys.min()}-{ys.max()} of 520 wide)  {bp.name}")
            mark = np.asarray(Image.open(png).convert("RGB")).copy()
            mark[hit] = (255, 0, 0)
            Image.fromarray(mark).save(ld / png.name.replace("-scene", "-hit"))
    for f in found:
        print("  lint: " + f)
    print("lint OK" if not found else f"lint: {len(found)} problem(s); red = words on the picture, in {ld}")
    return not found


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["check", "frames", "lint"]); ap.add_argument("id")
    ap.add_argument("--card", type=int, help="frames: only this card (1-based)")
    ap.add_argument("--compare", action="store_true", help="frames: also the Swift pictures")
    default_out = str(ROOT / "ios" / "build" / "frames")
    ap.add_argument("--out", default=default_out)
    ap.add_argument("--sim", default="booted"); ap.add_argument("--bundle", default="com.saqlainmomin.polymath")
    a = ap.parse_args()
    if a.cmd == "check":
        sys.exit(0 if check(a.id) else 1)
    if a.cmd == "lint":
        sys.exit(0 if lint(a.id, a.card, str(Path(a.out) / a.id if a.out == default_out else Path(a.out)), a.sim, a.bundle) else 1)
    frames(a.id, a.card, a.compare, a.out, a.sim, a.bundle)


if __name__ == "__main__":
    main()
