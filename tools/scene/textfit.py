"""B: text boxes. Real widths for labels and text, so `scene.py check` can find words on words, words past the edge, words on a part.

Written from the renderer: SceneLook.label / SceneLook.text, DR.label (Drafting), AB.label and AB.say (Airbrush), WF label (Wireframe).
Widths come from the real fonts' advance tables (SF Rounded semibold for Drafting, DIN Condensed Bold for Airbrush, a monospace for
Wireframe), then a small per-style correction measured on rendered frames (see FIT below).

What `text_checks` checks, per card. Every `label` (its words, one box per line, plus the leader) and `text` gets a real box in stage units,
moved with the moves on it and its groups, and looked at only while it is on screen (not `hidden`, opacity above 0.05, after its `word`;
needs the rendered voice, else everything not hidden counts as on screen and collisions are only warned). ERROR: words past x 0..343, above
y 0 or below the stage (y 275, 3 units of slack, a warning from 2 over); words into the player's corner (more than 6 units in x and 3 in y);
two labels' / texts' words overlapping (by over 1 unit, for 0.2 s or more) while both are on screen. WARN: words over a part's box from
`boxes` (not DECOR parts, not the part the label's anchor sits on, not `onpicture` elements; the part boxes are rough, so a warning only);
a label's leader running 3 units or more through its own words; a label or text wider than 150 units. The topic id comes in with the helpers (`h["tid"]`).
"""
import json, re, sys
from pathlib import Path

APP = Path(__file__).resolve().parent.parent.parent / "ios" / "Polymath"
_CH = "".join(chr(c) for c in range(32, 127))


def _tab(s):
    return dict(zip(_CH, (int(v) / 1000 for v in s.split())))


# advance widths in em, characters 32..126. SF Pro Rounded semibold (Drafting words) and DIN Condensed Bold (Airbrush words).
SF = _tab("""200 300 434 627 633 849 691 222 362 362 433 633 270 438 270 362 639 468 591 617 633 612 628 563 635 629 270
270 633 633 633 519 880 670 628 704 692 566 542 720 719 251 537 646 537 853 709 746 604 745 626 619 595 704
663 952 668 647 626 362 362 362 433 414 492 532 583 530 582 541 338 579 569 228 228 521 229 843 560 559 579
579 345 499 337 560 513 765 508 524 493 362 362 362 633""")
DIN = _tab("""186 240 278 372 372 352 481 186 222 222 370 600 186 389 186 222 372 372 372 372 372 372 372 372 372 372 186
186 600 600 600 370 800 407 426 407 426 370 370 426 426 204 333 426 370 556 444 426 407 426 426 406 332 426
407 593 389 388 333 222 222 222 600 500 186 370 389 370 389 370 222 389 389 186 186 389 186 592 389 370 389
389 278 352 204 389 352 536 332 352 315 222 222 222 600""")
MONO = 0.6          # em per character (Wireframe): the monospace advance is 0.618 em, the ink a pixel or so less

# per-style corrections to the advance tables, measured on frames: extra points per character (the renderer's tracking and the small-size
# letter spacing the tables do not have) and a multiplier. See the module's last paragraph.
FIT = {"drafting": dict(track=1.0, mul=1.0), "wireframe": dict(track=0.0, mul=1.0), "airbrush": dict(track=0.0, mul=1.0)}

MAX_WORDS = 150          # a label or text wider than this (design units) is reported
PLAYER_X, PLAYER_Y = 288, 235
STAGE_BOTTOM = 275       # the visible stage ends here
SLACK = 3.0              # a label this far past it is still only a warning
EASES = {"linear": lambda x: x, "eout": lambda x: 1 - (1 - x) ** 3, "snap": lambda x: x * x * (3 - 2 * x), "fall": lambda x: x * x}


def norm(w):
    return re.sub(r"[^a-z0-9]", "", w.lower())


def _line_w(line, style, size):
    """Width in design units of one line, as the renderer draws it."""
    f = FIT[style]
    if style == "wireframe":
        return len(line) * MONO * size * f["mul"] + len(line) * f["track"]
    tab = DIN if style == "airbrush" else SF
    return sum(tab.get(c, 0.55) for c in line) * size * f["mul"] + len(line) * f["track"]


# ---------------------------------------------------------------- where the words sit (in the element's own frame)
def layout(e, style):
    """For a label or text element: dict(lines=[(x0, y0, x1, y1)], leader=((ax, ay), (bx, by)) or None, text=shown text), all in the
    coordinates of the group the element sits in, before any moves. A text element's origin is its `at` (the frame translates there)."""
    is_label = "label" in e
    raw = e["label"] if is_label else e["text"]
    if style == "wireframe":
        raw = raw.lower()
    elif style == "airbrush":
        raw = raw.upper()
    lines = raw.split("\n")
    align = e.get("align") or ("leading" if is_label else "center")
    n = len(lines)
    boxes = []
    leader = None
    if is_label:
        ax, ay = e.get("anchor", [0, 0])
        bx, by = e.get("at") or [ax, ay]
        size = e.get("size")
        if style == "wireframe":
            s = size or 9.5
            lh = s * 1.25
            for i, ln in enumerate(lines):
                w = _line_w(ln, style, s)
                px = bx + (6 if align == "leading" else -6 if align == "trailing" else 0)
                cy = by + (i - (n - 1) / 2) * lh + (9 if align == "center" else 0)
                x0 = px if align == "leading" else px - w if align == "trailing" else px - w / 2
                boxes.append(_ink(x0, cy, w, s, ln, style))
            leader = ((ax, ay), (bx, by))
        elif style == "airbrush":
            s = size or 19
            lh = s * 0.95
            side = 0 if align == "center" else -1 if align == "trailing" else 1
            below = by >= ay
            for i, ln in enumerate(lines):
                w = _line_w(ln, style, s)
                if side == 0:
                    # DIN: ascent .712 / descent .288 per point; anchor .top / .bottom sit on the line box
                    if below:
                        top = by + 3 + i * lh
                    else:
                        top = by - 2 - (n - 1 - i) * lh - s
                    boxes.append((bx - w / 2, top, bx + w / 2, top + 0.712 * s))
                else:
                    cy = by + (i - (n - 1) / 2) * lh
                    x0 = bx + 5 if side > 0 else bx - 5 - w
                    boxes.append((x0, cy - 0.5 * s, x0 + w, cy - 0.5 * s + 0.712 * s))
            leader = ((ax, ay), (bx, by))
        else:
            s = 8.5
            lh = s * 1.2
            ws = [_line_w(ln, style, s) for ln in lines]
            px = bx + (4 if align == "leading" else -4 if align == "trailing" else 0)
            wm = max(ws)          # a multi-line Text is one block, anchored as a whole, its lines flush left inside it (seen on cold-phone card 3)
            x0 = px if align == "leading" else px - wm if align == "trailing" else px - wm / 2
            for i, ln in enumerate(lines):
                cy = by + (i - (n - 1) / 2) * lh
                boxes.append(_ink(x0, cy, ws[i], s, ln, style))
            leader = ((ax, ay), (bx, by - 14) if align == "center" else (bx, by))
    else:
        if style == "wireframe":
            s = e.get("size") or 9.5
            lh = s * 1.2
        elif style == "airbrush":
            s = e.get("size") or 22
            lh = s * 1.0
        else:
            s = e.get("size") or 8.5
            lh = s * 1.2
        wm = max(_line_w(ln, style, s) for ln in lines)
        for i, ln in enumerate(lines):
            w = _line_w(ln, style, s)
            cy = (i - (n - 1) / 2) * lh
            bx0 = 0 if align == "leading" else -wm if align == "trailing" else -wm / 2
            x0 = bx0          # (one Text with line breaks is one block)
            if style == "airbrush":
                boxes.append((x0, cy - 0.5 * s, x0 + w, cy - 0.5 * s + 0.712 * s))
            else:
                boxes.append(_ink(x0, cy, w, s, ln, style))
    return dict(lines=boxes, leader=leader, text=raw)


def _ink(x0, cy, w, s, line, style):
    """The ink box of one line of SF / mono words whose line box is centred on cy, measured on frames: Drafting caps run 0.33 em either side
    of cy; Wireframe's small letters from 0.42 em above to 0.36 below; a descender (g j p q y , ;) adds 0.2 em."""
    desc = 0.2 if re.search(r"[gjpqy,;]", line) else 0.0
    if style == "wireframe":
        return (x0, cy - 0.42 * s, x0 + w, cy + (0.36 + desc) * s)
    return (x0, cy - 0.33 * s, x0 + w, cy + (0.33 + desc) * s)


# ---------------------------------------------------------------- the card over time
def _voice(tid):
    """(per-beat [(word, seconds into beat)], per-beat length) from the rendered voice, or (None, None)."""
    v = APP / "Resources" / f"voice-{tid}.json"
    if not tid or not v.exists():
        return None, None
    d = json.loads(v.read_text())
    b = d["beats"] + [d["duration"] + 1]
    words = [[(norm(w["text"]), w["start"] - b[i]) for w in d["words"] if b[i] - 0.01 <= w["start"] < b[i + 1] - 0.01] for i in range(len(d["beats"]))]
    ends = d["beats"][1:] + [d["duration"]]
    return words, [e - s for s, e in zip(d["beats"], ends)]


def _frames(scene):
    """All leaves (anything not a group) with the list of ancestors they sit in: [(element, chain)]."""
    out = []

    def go(els, chain):
        for e in els:
            c = chain + [e]
            if "group" in e:
                go(e["group"], c)
            else:
                out.append((e, c))
    go(scene["elements"], [])
    return out


def text_checks(scene, tag, style, errors, warns, h):
    """scene: one card's dict (elements, moves). tag: 'card 3'. h: helpers from scene.py (boxes, walk, PART_BOX, DECOR, W, H, CORNER). Append to errors / warns."""
    W, H = h["W"], h["H"]
    moves = scene.get("moves", [])
    tid = h.get("tid")
    words, lengths = _voice(tid)
    card = scene.get("card", 0)
    said = words[card] if words and card < len(words) else None
    length = lengths[card] if lengths and card < len(lengths) else None
    timed = said is not None and length is not None and all(t is not None for _, t in said)

    def hit(word):
        if word is None:
            return 0.0
        w, _, n = word.partition("#")
        hs = [t for x, t in (said or []) if x == norm(w)]
        return hs[int(n or 1) - 1] if len(hs) >= int(n or 1) else 0.0

    def mstart(m):
        return m.get("at", hit(m.get("word"))) + m.get("delay", 0)

    def value(e, prop, base, t):
        v = base
        for m in sorted((m for m in moves if m["move"] == e.get("id") and m["prop"] == prop), key=mstart):
            st = mstart(m)
            x = min(1.0, max(0.0, (t - st) / max(m.get("dur", 0.5), 0.001)))
            v += (m["to"] - v) * EASES.get(m.get("ease"), lambda y: y * y * (3 - 2 * y))(x)
        return v

    def started(e, t):
        return t > hit(e.get("word")) + e.get("delay", 0) if timed or not e.get("word") else True

    def shown(chain, t):
        return all(value(e, "opacity", 0.0 if e.get("hidden") else 1.0, t) > 0.05 and started(e, t) for e in chain)

    def frame_at(chain, t):
        """The map from a leaf's parents' space to the stage at time t: list of (tx, ty, k, mirror) outermost first."""
        fr = []
        for e in chain:
            at = e.get("at") or [0, 0]
            tx = value(e, "x", at[0] if "label" not in e else 0.0, t)
            ty = value(e, "y", at[1] if "label" not in e else 0.0, t)
            k = value(e, "scale", e.get("scale", 1), t)
            fr.append((tx, ty, k, -1 if e.get("mirror") else 1))
        return fr

    def to_stage(pt, fr):
        x, y = pt
        for tx, ty, k, mr in reversed(fr):
            x, y = tx + k * mr * x, ty + k * y
        return x, y

    leaves = _frames(scene)
    texts = [(e, c) for e, c in leaves if "label" in e or "text" in e]
    if not texts:
        return
    lay = {id(e): layout(e, style) for e, _ in texts}
    ts = [i * 0.1 for i in range(int((length if timed else 12) * 10))] if timed else [0.0, 0.5, 1.0, 2.0, 4.0, 8.0, 12.0, 20.0, 40.0]

    def name(e):
        return e.get("label") or e.get("text")

    def box_at(e, c, t):
        """Word boxes of a label/text at time t, on the stage, as one (x0, y0, x1, y1), and the leader's two ends."""
        fr = frame_at(c, t)
        L = lay[id(e)]
        if "text" in e:
            fr_words = fr       # a text's own translate and scale apply to its words
            pts = [[to_stage((b[0], b[1]), fr_words), to_stage((b[2], b[3]), fr_words)] for b in L["lines"]]
            ld = None
        else:
            fr_words = fr[:-1] + [(fr[-1][0], fr[-1][1], 1.0, 1)]   # a label's own x/y move translates it; its scale is ignored
            pts = [[to_stage((b[0], b[1]), fr_words), to_stage((b[2], b[3]), fr_words)] for b in L["lines"]]
            ld = [to_stage(p, fr_words) for p in L["leader"]] if L["leader"] else None
        xs = [p for pr in pts for p in (pr[0][0], pr[1][0])]
        ys = [p for pr in pts for p in (pr[0][1], pr[1][1])]
        return (min(xs), min(ys), max(xs), max(ys)), ld

    vis = {}          # id(e) -> [(t, box, leader)]
    for e, c in texts:
        vis[id(e)] = [(t, *box_at(e, c, t)) for t in ts if shown(c, t)]
    live = [(e, c) for e, c in texts if vis[id(e)]]       # `hidden` and never made visible: not looked at
    tword = (lambda t: f"at {t:.1f} s") if timed else (lambda t: "")
    where = lambda b: f"x {b[0]:.0f} to {b[2]:.0f}, y {b[1]:.0f} to {b[3]:.0f}"
    kind = lambda e: "label" if "label" in e else "text"

    # 1. each one on its own: off the screen, in the player's corner, too wide
    for e, c in live:
        bs = [b for _, b, _ in vis[id(e)]]
        bx = (min(b[0] for b in bs), min(b[1] for b in bs), max(b[2] for b in bs), max(b[3] for b in bs))
        nm = f"{kind(e)} {name(e).replace(chr(10), ' / ')!r}"
        why = []
        if bx[0] < -0.5:
            why.append(f"runs off the left edge (words start at x {bx[0]:.0f})")
        if bx[2] > W + 0.5:
            why.append(f"runs off the right edge (words reach x {bx[2]:.0f}, the stage ends at {W})")
        if bx[1] < -0.5:
            why.append(f"runs off the top (words start at y {bx[1]:.0f})")
        if bx[3] > STAGE_BOTTOM + SLACK:
            why.append(f"sits below the visible stage (words reach y {bx[3]:.0f}, it ends at {STAGE_BOTTOM})")
        elif bx[3] > STAGE_BOTTOM + 2.0:
            warns.append(f"{tag}: {nm} ends {bx[3] - STAGE_BOTTOM:.0f} units below where the visible stage ends (words reach y {bx[3]:.1f}, the stage ends at {STAGE_BOTTOM}), words at {where(bx)}")
        if bx[2] > PLAYER_X + 6 and bx[3] > PLAYER_Y + 3:
            why.append(f"runs into the player's corner (words reach x {bx[2]:.0f}, y {bx[3]:.0f}; keep clear of x > {PLAYER_X} and y > {PLAYER_Y})")
        for w in why:
            errors.append(f"{tag}: {nm} {w}, words at {where(bx)}")
        if bx[2] - bx[0] > MAX_WORDS:
            warns.append(f"{tag}: {nm} is {bx[2] - bx[0]:.0f} units wide (over {MAX_WORDS}), words at {where(bx)}: split it onto two lines")

    # 2. two labels' / texts' words at once
    for i, (e1, c1) in enumerate(live):
        for e2, c2 in live[i + 1:]:
            s1 = {t: b for t, b, _ in vis[id(e1)]}
            s2 = {t: b for t, b, _ in vis[id(e2)]}
            hits = []
            for t in s1.keys() & s2.keys():
                a, b = s1[t], s2[t]
                ox, oy = min(a[2], b[2]) - max(a[0], b[0]), min(a[3], b[3]) - max(a[1], b[1])
                if ox > 1.0 and oy > 1.0:
                    hits.append((t, a, b, ox, oy))
            if len(hits) >= (2 if timed else 1):
                t, a, b, ox, oy = min(hits, key=lambda x: x[0])
                msg = (f"{tag}: {kind(e1)} {name(e1).replace(chr(10), ' / ')!r} (words at {where(a)}) and {kind(e2)} {name(e2).replace(chr(10), ' / ')!r} "
                       f"(words at {where(b)}) are on top of each other by {ox:.0f} x {oy:.0f} units" + (f" {tword(t)}" if timed else ""))
                (errors if timed else warns).append(msg)

    # 3. words on a part (warning: the part boxes are rough), a leader through its own words
    parts = [(e, c) for e, c in leaves if "part" in e and e["part"] not in h["DECOR"]]
    for e, c in live:
        if e.get("onpicture"):
            continue
        nm = f"{kind(e)} {name(e).replace(chr(10), ' / ')!r}"
        anchor = None
        if "label" in e:
            anchor = to_stage(tuple(e.get("anchor", [0, 0])), frame_at(c, ts[0])[:-1]) if len(c) > 1 else tuple(e.get("anchor", [0, 0]))
        done = set()
        for p, pc in parts:
            if id(p) in done:
                continue
            for t, b, _ in vis[id(e)][::2]:
                if not shown(pc, t):
                    continue
                fr = frame_at(pc, t)
                at = [fr[-1][0], fr[-1][1]]
                pb = h["boxes"]([dict(p, at=at)], style, 0.0, 0.0, [], 1.0)
                if not pb:
                    continue
                # the part's own frame: its parents' transform applied to its box corners
                outer = fr[:-1]
                x0, y0 = to_stage(pb[0][:2], outer)
                x1, y1 = to_stage(pb[0][2:], outer)
                pb = (min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1))
                if anchor and pb[0] - 6 <= anchor[0] <= pb[2] + 6 and pb[1] - 6 <= anchor[1] <= pb[3] + 6:
                    done.add(id(p))
                    break
                ox, oy = min(b[2], pb[2]) - max(b[0], pb[0]), min(b[3], pb[3]) - max(b[1], pb[1])
                if ox > 3 and oy > 3:
                    done.add(id(p))
                    pn = p.get("id") or p["part"]
                    warns.append(f"{tag}: {nm} (words at {where(b)}) overlaps {pn!r} (box {where(pb)}) by {ox:.0f} x {oy:.0f} units" + (f" {tword(t)}" if timed else "")
                                 + "; if it should sit on the picture add \"onpicture\": true")
                    break
        if "label" in e and lay[id(e)]["leader"]:
            t, b, ld = vis[id(e)][len(vis[id(e)]) // 2]
            if ld and any(_seg_inside(ld[0], ld[1], bb) > 3.0 for bb in _stage_lines(e, c, t, lay, frame_at, to_stage)):
                warns.append(f"{tag}: {nm}: its leader line from ({ld[0][0]:.0f}, {ld[0][1]:.0f}) to ({ld[1][0]:.0f}, {ld[1][1]:.0f}) runs through its own words ({where(b)})")


def _stage_lines(e, c, t, lay, frame_at, to_stage):
    fr = frame_at(c, t)
    fr = fr[:-1] + [(fr[-1][0], fr[-1][1], 1.0, 1)]
    out = []
    for b in lay[id(e)]["lines"]:
        (x0, y0), (x1, y1) = to_stage((b[0], b[1]), fr), to_stage((b[2], b[3]), fr)
        out.append((min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1)))
    return out


def _seg_inside(p, q, b):
    """How much of the segment p-q (design units) lies inside box b (x0, y0, x1, y1)? (Liang-Barsky)"""
    x0, y0, x1, y1 = b
    if x1 <= x0 or y1 <= y0:
        return 0.0
    dx, dy = q[0] - p[0], q[1] - p[1]
    t0, t1 = 0.0, 1.0
    for pp, qq in ((-dx, p[0] - x0), (dx, x1 - p[0]), (-dy, p[1] - y0), (dy, y1 - p[1])):
        if pp == 0:
            if qq < 0:
                return 0.0
        else:
            r = qq / pp
            if pp < 0:
                t0 = max(t0, r)
            else:
                t1 = min(t1, r)
            if t0 > t1:
                return 0.0
    return (t1 - t0) * (dx * dx + dy * dy) ** 0.5
