"""E: flow. The same things stay on the same sides of the screen in every card of a topic (the owner's rule, 2026-11-05).

    Read the whole topic after its cards, and report:
      1. two kinds of part (bank and shop, moon and tideEarth ...) that swap left/right order between cards;
      2. parts with a built-in side (a bike's back gears, a walker's face, a gearPair's pedal ring) whose EFFECTIVE side
         (after `mirror` on the part and on every group above it) differs between cards;
      3. the same kind of part mirrored in one card and not in another, when nothing above explains it.

Mirror in the renderer (ios/Polymath/Scene.swift, draw): translate to `at`, rotate, scale, then `scaleBy(-1, 1)`, so a mirrored part keeps its
place on the screen and only turns round, but a mirrored GROUP also swaps the sides of its children. Both are handled below.
"""
import math

MIN_GAP = 25      # two parts closer than this (x units, 343 wide) are too close to call an order
BIG_GAP = 40      # a swap of at least this much in both cards is an error, otherwise a warning
SIDE_GAP = 45     # a lone part this far from the middle of the screen counts as being on that side
TRAVEL = 30       # a facing part that moves backwards by more than this is reported

# What a part has on its RIGHT when it is drawn unmirrored, read from the Swift drawing code (ios/Polymath/DraftingBike.swift, Drafting.swift,
# DraftingParts.swift, WireframeParts.swift). Each entry: prop -> (+1 if it is on the right, -1 if on the left). Props shared by several parts are
# compared across all of them (a bike and a gearPair must put the back gears on the same side). "error" props are the clear cases.
SIDES = {
    "bike":     {"facing": +1, "backRing": -1},   # rider and front wheel (x +50) to the right; back wheel and its ring (x -50) left of the pedal ring (x -2)
    "gearPair": {"backRing": +1},                 # pedal ring (x -58) on the left, back ring (x +62) on the right: the opposite of the bike
    "walker":   {"facing": +1},                   # "facing right"; walks and climbs to the right
    "magnet":   {"poles": +1},                    # "pointing right: bottom of the U at the left, poles at the right end"
    "heldCard": {"arm": +1},                      # the forearm runs off down to the right
    "terminal": {"depth": +1},                    # its thickness shows up and to the right
    "phone":    {"depth": +1},                    # same slab, side buttons on the left
    "wfPhone":  {"depth": +1},
}
ERROR_PROPS = {"facing", "backRing"}
PHRASE = {   # prop -> what to say about a part, given the side ("left" or "right")
    "facing":   lambda side: f"faces {side}",
    "backRing": lambda side: f"has the back (changing) gears on the {side} of the pedal ring",
    "poles":    lambda side: f"has its poles pointing {side}",
    "arm":      lambda side: f"has the hand's forearm running off to the {side}",
    "depth":    lambda side: f"shows its thickness on the {side}",
    "moonSide": lambda side: f"has the Moon on the {side}",
}
# a param that names a side by itself: part -> (param, prop). tideEarth `dir` is the Moon's angle (0 is right, 180 left).
PARAM_SIDES = {"tideEarth": ("dir", "moonSide")}
# a param that tells two uses of the same part apart (a cold nerve is not a warm one)
IDENT = {"nerve": "kind", "clock": "pink"}


def _rot_flips(e):
    r = (e.get("rotate") or 0) % 360
    return -1 if 90 < r < 270 else 1


def _centre(part, params, style, h):
    """(x0, x1) of the part in its own frame, before scale: what the checker's PART_BOX says, plus a few parts it does not know."""
    if part == "glueTube": return 22.0, 187.0
    if part == "calendar": return 0.0, 56.0
    if part == "plank": return 0.0, float(params.get("w", 300))
    if part in ("skin", "waterFilm"): return float(params.get("x0", 0)), float(params.get("x1", 200))
    if part in ("globe", "moon") and params.get("r"): return -float(params["r"]), float(params["r"])
    b = h["PART_BOX"].get(style, {}).get(part)
    return (b[0], b[2]) if b else (-30.0, 30.0)


def _collect(scene, style, h):
    """Every part the card draws, as dicts: key, part, id, lo/hi (the x range its centre covers, start to end of its moves), flip (drawn
    turned round), own (the part itself has `mirror`), by (the nearest mirrored group above it, or None), travel (x moved, on screen)."""
    moves, out = scene.get("moves", []), []

    def rec(els, a, blo, bhi, drift, group_mirror):
        for e in els:
            if "label" in e or "text" in e or e.get("part") in h["DECOR"]:
                continue
            if e.get("part") == "globe" and e.get("params", {}).get("r", 0) > 100:
                continue                      # a planet seen from space: scenery
            at = e.get("at") or [0, 0]
            xs = [at[0]] + [m["to"] for m in moves if e.get("id") and m["move"] == e["id"] and m["prop"] == "x"]
            k = e.get("scale", 1) * (-1 if e.get("mirror") else 1) * _rot_flips(e)
            cand = [b + a * x for x in xs for b in (blo, bhi)]
            if "group" in e:
                rec(e["group"], a * k, min(cand), max(cand), drift + a * (xs[-1] - xs[0]), e.get("mirror") and "mirror" or group_mirror)
            elif "part" in e:
                p = e.get("params", {})
                x0, x1 = _centre(e["part"], p, style, h)
                c = (x0 + x1) / 2 * k
                world = [b + a * (x + c) for x in xs for b in (blo, bhi)]
                key = e["part"] + (":" + str(p.get(IDENT[e["part"]], 0)) if e["part"] in IDENT else "")
                out.append(dict(key=key, part=e["part"], id=e.get("id"), params=p, lo=min(world), hi=max(world), flip=a * k < 0,
                                own=bool(e.get("mirror")), by=group_mirror, travel=drift + a * (xs[-1] - xs[0]), mid=sum(world) / len(world)))
    rec(scene["elements"], 1.0, 0.0, 0.0, 0.0, None)
    return out


def _name(i):
    return i["part"] + (f" {i['id']!r}" if i["id"] else "")


def _how_to_flip(i):
    if i["own"]:
        return f'take "mirror" off {_name(i)}' if i["flip"] else f'add "mirror": true to {_name(i)}'
    if i["by"]:
        return f'toggle "mirror" on the group that holds {_name(i)}'
    return f'add "mirror": true to {_name(i)}'


def _say(prop, v):
    return "right" if v > 0 else "left"


def _names(items):
    return " and ".join(sorted({_name(i) for i in items}))


def flow_checks(scenes, style, errors, warns, h, tid):
    """scenes: every card's dict of the topic, in order. h: helpers from scene.py (boxes, walk, PART_BOX, DECOR, W, H, CORNER). Append to errors / warns."""
    cards = [(f"card {s['card'] + 1}", _collect(s, style, h)) for s in scenes]
    if len(cards) < 2:
        return

    # (a) two kinds of part swap their left/right order between cards
    keys = sorted({i["key"] for _, items in cards for i in items})
    swapped = set()      # kinds already reported as swapping places: not said again in (d)
    for ai, ka in enumerate(keys):
        for kb in keys[ai + 1:]:
            seen = []       # (tag, +1 if ka is left of kb / -1 if right, gap, ka mid, kb mid)
            for tag, items in cards:
                A, B = [i for i in items if i["key"] == ka], [i for i in items if i["key"] == kb]
                if not A or not B:
                    continue
                left = min(b["lo"] - a["hi"] for a in A for b in B)      # every A left of every B, by at least this
                right = min(a["lo"] - b["hi"] for a in A for b in B)     # every A right of every B
                if left >= MIN_GAP:
                    seen.append((tag, +1, left, sum(a["mid"] for a in A) / len(A), sum(b["mid"] for b in B) / len(B)))
                elif right >= MIN_GAP:
                    seen.append((tag, -1, right, sum(a["mid"] for a in A) / len(A), sum(b["mid"] for b in B) / len(B)))
            if len({s[1] for s in seen}) < 2:
                continue
            first = seen[0]
            odd = [x for x in seen if x[1] != first[1]]
            l, r = (ka, kb) if first[1] > 0 else (kb, ka)
            xl = lambda x: x[3] if l == ka else x[4]          # where the first card's left-hand kind sits in card x
            xr = lambda x: x[4] if l == ka else x[3]
            ln, rn = l.split(":")[0], r.split(":")[0]
            both_big = first[2] >= BIG_GAP and max(x[2] for x in odd) >= BIG_GAP
            msg = (f"{first[0]} puts the {ln} on the left (x {xl(first):.0f}) and the {rn} on the right (x {xr(first):.0f}), but "
                   + "; ".join(f"{x[0]} has the {ln} at x {xl(x):.0f} and the {rn} at x {xr(x):.0f}" for x in odd)
                   + f". A thing stays on the side it started on: put the {ln} on the left and the {rn} on the right in "
                   + ", ".join(x[0] for x in odd) + " (move them, or mirror the group that holds both).")
            (errors if both_big else warns).append(msg)
            swapped |= {ka, kb}

    # (b) parts with a built-in side: the effective side must be the same in every card
    values = {}      # prop -> [(tag, value, [items])]
    for tag, items in cards:
        per = {}
        for i in items:
            for prop, v in SIDES.get(i["part"], {}).items():
                per.setdefault(prop, []).append((v * (-1 if i["flip"] else 1), i))
            if i["part"] in PARAM_SIDES and PARAM_SIDES[i["part"]][0] in i["params"]:
                par, prop = PARAM_SIDES[i["part"]]
                c = math.cos(math.radians(i["params"][par]))
                if abs(c) > 0.3:
                    per.setdefault(prop, []).append((int(math.copysign(1, c)) * (-1 if i["flip"] else 1), i))
        for prop, vs in per.items():
            if len({v for v, _ in vs}) == 1:         # a card that shows both ways on purpose is left alone
                values.setdefault(prop, []).append((tag, vs[0][0], [i for _, i in vs]))
    for prop, seen in values.items():
        if len({v for _, v, _ in seen}) < 2:
            continue
        ref_tag, ref_v, ref_items = seen[0]
        for tag, v, items in seen[1:]:
            if v == ref_v:
                continue
            msg = (f"{tag}: {_names(items)} {PHRASE[prop](_say(prop, v))}, but {ref_tag} ({_names(ref_items)}) {PHRASE[prop](_say(prop, ref_v))}. "
                   f"Keep it as in {ref_tag}: {_how_to_flip(items[0])}"
                   + ("; mirror the diagram, not the story." if any(i["part"] == "gearPair" for i in items + ref_items) else "."))
            (errors if prop in ERROR_PROPS else warns).append(msg)

    # a facing part that travels backwards: the picture says one thing, the move another
    for tag, items in cards:
        for i in items:
            if "facing" in SIDES.get(i["part"], {}):
                f = SIDES[i["part"]]["facing"] * (-1 if i["flip"] else 1)
                if i["travel"] * f < -TRAVEL:
                    warns.append(f"{tag}: {_name(i)} faces {_say('facing', f)} but its moves carry it {'left' if f > 0 else 'right'} "
                                 f"by {abs(i['travel']):.0f}; face the way it goes (or move it the way it faces)")

    # (c) the same part mirrored in one card and not in another, where the table above does not explain it
    for key in keys:
        part = key.split(":")[0]
        if part in SIDES or part in PARAM_SIDES:
            continue
        seen = [(tag, [i for i in items if i["key"] == key]) for tag, items in cards]
        seen = [(t, v) for t, v in seen if v]
        flips = [(t, {i["flip"] for i in v}) for t, v in seen]
        mono = [(t, next(iter(f))) for t, f in flips if len(f) == 1]
        if len({f for _, f in mono}) > 1:
            on = [t for t, f in mono if f]
            off = [t for t, f in mono if not f]
            warns.append(f"{part} is drawn mirrored in {', '.join(on)} but not in {', '.join(off)}, and it has no side of its own that would need "
                         f"it; keep it the same in every card (or leave a note why a mirrored one is needed)")

    # (d) one thing on a different half of the screen than it was: only said when the card has just one of it and it is well clear of the middle
    mid = h["W"] / 2
    for key in keys:
        if key in swapped:
            continue
        one = [(tag, [i for i in items if i["key"] == key]) for tag, items in cards]
        one = [(t, v[0]) for t, v in one if len(v) == 1]
        right = [(t, i) for t, i in one if i["mid"] - mid >= SIDE_GAP]
        left = [(t, i) for t, i in one if mid - i["mid"] >= SIDE_GAP]
        if right and left:
            first_t, first_i = min(right + left, key=lambda x: int(x[0].split()[1]))
            on_right = first_t in [t for t, _ in right]
            other = left if on_right else right
            side, back = ("right", "left") if on_right else ("left", "right")
            warns.append(f"{key.split(':')[0]} starts on the {side} of the screen ({first_t}, x {first_i['mid']:.0f}) but sits on the {back} in "
                         + ", ".join(f"{t} (x {i['mid']:.0f})" for t, i in other)
                         + f". A thing keeps its side from card to card: move it back to the {side}, or if the picture truly needs it there, check the story still reads the same way.")
