"""Writes ios/Polymath/Scenes/memory-consolidation.json. Edit here, then run: python3 tasks/spine-memory-consolidation/gen_scenes.py"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "ios" / "Polymath" / "Scenes" / "memory-consolidation.json"


def mv(i, prop, to, word, dur=0.5, delay=None, ease=None):
    m = {"move": i, "prop": prop, "to": to, "word": word, "dur": dur}
    if delay: m["delay"] = delay
    if ease: m["ease"] = ease
    return m


def cell(i, at, scale, word, delay=None):
    """A brain cell: skin-to-salmon body, an orange core, three short branches."""
    e = {"id": i, "group": [
        {"path": "M-30 -16 L-50 -30 L-58 -26 M-50 -30 L-52 -42 M-22 26 L-36 46 M28 -20 L42 -38 M32 18 L50 30", "stroke": "ink", "width": 1.6},
        {"circle": [0, 0, 34], "fill": "vg:skin:salmon"},
        {"circle": [0, 0, 11], "fill": "orange@0.8"}],
        "at": at, "scale": scale, "word": word}
    if delay: e["delay"] = delay
    return e


def text(i, s, at, word, size=22, delay=None):
    e = {"id": i, "text": s, "at": at, "size": size, "word": word, "hidden": True, "scale": 0.4}
    if delay: e["delay"] = delay
    return e


def pop(i, word, delay=None):
    return [mv(i, "opacity", 1, word, 0.3, delay), mv(i, "scale", 1.0, word, 0.5, delay, "snap")]


BRAIN = (172, 160)
HIPPO = (172, 168)
SEAHORSE = "M2 -26 C9 -28 14 -23 13 -16 C12 -11 9 -9 10 -4 C14 4 14 12 7 18 C2 23 -6 23 -8 17 C-10 11 -4 8 0 11 C3 13 4 9 1 6 C-4 1 -6 -4 -4 -9 L-7 -11 L-19 -12 L-19 -17 L-7 -17 C-5 -22 -2 -25 2 -26 Z"


def hippo(word, hidden=True):
    e = {"id": "hip", "group": [
        {"part": "glow", "params": {"r": 30, "col": 1, "alpha": 0.8}},
        {"path": SEAHORSE, "fill": "yellow", "width": 1.6},
        {"path": "M12 -6 L18 -8 L17 -2 L12 0", "fill": "orange", "width": 1.2},
        {"circle": [3, -19, 1.8], "fill": "ink"}],
        "at": list(HIPPO), "word": word}
    if hidden:
        e["hidden"] = True
        e["scale"] = 0.4
    return e


scenes = []

# ---- card 1: cells that fired together, linked; a new memory is wet cement
C = [(110, 110), (162, 78), (222, 100), (140, 158), (208, 156)]
links = "M110 110 L162 78 M162 78 L222 100 M110 110 L140 158 M140 158 L208 156 M208 156 L222 100 M162 78 L208 156"
el = [{"id": "bg", "part": "spray", "at": [172, 120], "params": {"rx": 140, "ry": 86, "col": 7, "alpha": 0.22, "grow": 1}, "word": "memory#2"}]
el += [{"id": f"g{k}", "part": "glow", "at": list(p), "params": {"r": 30, "col": 1, "alpha": 0.95}, "hidden": True, "word": "fired"} for k, p in enumerate(C)]
el += [{"id": "net", "group": [{"path": links, "stroke": "ink", "width": 2.4}], "word": "linked", "draw": 1.0}]
el += [cell(f"c{k}", list(p), 0.42, "cells", 0.1 * k) for k, p in enumerate(C)]
el += [{"id": "lc", "label": "BRAIN CELLS", "anchor": [162, 64], "at": [162, 36], "align": "center", "word": "cells", "delay": 0.5}]
el += [{"id": "cem", "rect": [52, 196, 240, 44, 10], "fill": "ink@0.22", "word": "cement"},
       {"id": "b1", "circle": [92, 214, 3], "fill": "white", "word": "cement", "delay": 0.4},
       {"id": "b2", "circle": [178, 224, 2.5], "fill": "white", "word": "cement", "delay": 0.5},
       {"id": "b3", "circle": [246, 210, 3], "fill": "white", "word": "cement", "delay": 0.6},
       text("wc", "WET CEMENT", [172, 262], "cement"),
       {"id": "clock", "group": [{"circle": [0, 0, 20], "fill": "white"},
                                 {"id": "hand", "group": [{"path": "M0 2 L0 -13", "stroke": "ink", "width": 2.2}]}],
        "at": [300, 46], "word": "time", "hidden": True}]
mv0 = [mv(f"g{k}", "opacity", 1, "fired", 0.3, 0.06 * k) for k in range(5)]
mv0 += [mv(f"g{k}", "opacity", 0, "experience", 0.5) for k in range(5)]
mv0 += [mv(f"g{k}", "opacity", 1, "again", 0.3, 0.06 * k) for k in range(5)]
mv0 += [mv(f"g{k}", "opacity", 0, "but", 0.5) for k in range(5)]
mv0 += [mv("lc", "opacity", 0, "cement", 0.3)]
mv0 += pop("wc", "cement", 0.3)
# soft: the whole network sags into the cement, then rises back
for k, (x, y) in enumerate(C):
    mv0 += [mv(f"c{k}", "y", y + 8, "soft", 0.4), mv(f"c{k}", "y", y, "soft", 0.6, 0.4)]
mv0 += [mv("net", "y", 8, "soft", 0.4), mv("net", "y", 0, "soft", 0.6, 0.4)]
mv0 += [mv("clock", "opacity", 1, "time", 0.3), mv("hand", "rotate", 360, "time", 2.4, 0.2, "linear")]
scenes.append({"card": 0, "label": "A few round brain cells light up yellow together and stay joined by links; below them a slab of wet cement, and a clock ticking.",
               "elements": el, "moves": mv0})

# ---- card 2: consolidation; within hours, new proteins make the link sturdier
L, R, Y = (90, 140), (254, 140), 140
el = [{"id": "bg", "part": "spray", "at": [172, 140], "params": {"rx": 150, "ry": 46, "col": 2, "alpha": 0.16, "grow": 1}, "word": "turning"},
      {"id": "thin", "path": f"M122 {Y} L222 {Y}", "stroke": "ink", "width": 1.6, "word": "turning"},
      {"id": "thick", "rect": [120, Y - 9, 104, 18, 9], "fill": "yellow", "hidden": True, "word": "sturdier"},
      cell("cl", list(L), 1.0, "turning"),
      cell("cr", list(R), 1.0, "turning", 0.2),
      text("con", "CONSOLIDATION", [172, 40], "consolidation", 26),
      text("hrs", "WITHIN HOURS", [172, 254], "hours"),
      text("stu", "STURDIER LINK", [172, 254], "sturdier")]
P = [(L[0] - 4, Y - 4), (L[0] + 6, Y + 6), (L[0] + 2, Y - 10), (R[0] + 4, Y - 4), (R[0] - 6, Y + 6), (R[0] - 2, Y - 10)]
DEST = [134, 152, 170, 210, 192, 176]
for k, p in enumerate(P):
    el.append({"id": f"p{k}", "group": [{"circle": [0, 0, 5.5], "fill": "orange"}], "at": list(p), "hidden": True, "word": "proteins"})
el.append({"id": "lp", "label": "NEW PROTEINS", "anchor": [172, Y - 12], "at": [172, Y - 50], "align": "center", "word": "material", "delay": 0.5})
mv1 = pop("con", "consolidation") + pop("hrs", "hours")
for k in range(6):
    mv1 += [mv(f"p{k}", "opacity", 1, "build", 0.3, 0.08 * k),
            mv(f"p{k}", "x", DEST[k], "proteins", 0.9, 0.1 * k),
            mv(f"p{k}", "y", Y, "proteins", 0.9, 0.1 * k)]
mv1 += [mv("hrs", "opacity", 0, "material", 0.3)]
mv1 += [mv("thick", "opacity", 1, "sturdier", 0.5)] + pop("stu", "sturdier", 0.4)
mv1 += [mv("lp", "opacity", 0, "sturdier", 0.3)]
scenes.append({"card": 1, "label": "Two brain cells close up, joined by a thin link; small orange proteins gather on it and the link turns thick and yellow.",
               "elements": el, "moves": mv1})

# ---- card 3: pieces in different parts; the hippocampus ties them into one
REG = [(116, 142, 2, "saw"), (178, 112, 7, "heard"), (234, 150, 3, "felt")]
ICON = [(80, 50), (172, 50), (264, 50)]
el = [{"id": "brain", "part": "brain", "at": list(BRAIN), "scale": 1.9, "params": {"lit": 0}, "word": "brain"}]
el += [{"id": f"halo{k}", "part": "spray", "at": [ICON[k][0], 50], "params": {"rx": 24, "ry": 20, "col": REG[k][2], "alpha": 0.4, "grow": 1}, "word": REG[k][3]} for k in range(3)]
el += [{"id": "eye", "part": "eye", "at": [80, 50], "params": {"s": 0.55}, "word": "saw"},
      {"id": "ear", "path": "M168 32 C184 28 192 44 186 56 C182 62 178 64 178 70 C178 76 168 78 164 72 C160 66 158 36 168 32 Z", "fill": "skin", "word": "heard"},
      {"id": "heart", "path": "M264 66 C246 54 248 36 258 36 C262 36 264 40 264 42 C264 40 266 36 270 36 C280 36 282 54 264 66 Z", "fill": "orange", "word": "felt"},
      text("tsaw", "SAW", [80, 14], "saw", 19), text("thrd", "HEARD", [172, 14], "heard", 19), text("tflt", "FELT", [264, 14], "felt", 19)]
for k, (x, y, col, w) in enumerate(REG):
    el.append({"id": f"s{k}", "part": "spray", "at": [x, y], "params": {"rx": 26, "ry": 18, "col": col, "alpha": 0.75, "grow": 1}, "word": "different", "delay": 0.6 + 0.15 * k, "hidden": True})
for k, (x, y, col, w) in enumerate(REG):
    el.append({"id": f"tie{k}", "path": f"M{HIPPO[0]} {HIPPO[1]} L{x} {y}", "stroke": "orange", "width": 2.4, "dash": [5, 4], "word": "ties", "delay": 0.15 * k, "draw": 0.6})
for k, (x, y, col, w) in enumerate(REG):
    el.append({"id": f"d{k}", "group": [{"circle": [0, 0, 6], "fill": ["blue", "lime", "orange"][k]}], "at": list(ICON[k]), "hidden": True, "word": w})
el += [hippo("hippocampus"), text("thip", "HIPPOCAMPUS", [172, 264], "hippocampus", 22, 0.3)]
mv2 = pop("tsaw", "saw") + pop("thrd", "heard") + pop("tflt", "felt")
for k, (x, y, col, w) in enumerate(REG):
    mv2 += [mv(f"d{k}", "opacity", 1, w, 0.3, 0.2),
            mv(f"d{k}", "x", x, "different", 0.8, 0.15 * k), mv(f"d{k}", "y", y, "different", 0.8, 0.15 * k, "fall"),
            mv(f"s{k}", "opacity", 1, "different", 0.4, 0.6 + 0.15 * k)]
mv2 += pop("hip", "hippocampus") + pop("thip", "hippocampus", 0.3)
mv2 += [mv("hip", "scale", 1.25, "one", 0.3), mv("hip", "scale", 1.0, "one", 0.4, 0.3)]
scenes.append({"card": 2, "label": "An eye, an ear and a heart drop their pieces into three parts of a brain; a yellow seahorse-shaped hippocampus deep inside ties them together.",
               "elements": el, "moves": mv2})

# ---- card 4: deep sleep; the hippocampus replays your day to the cortex
OUTS = [(108, 122), (172, 107), (236, 122), (93, 162), (251, 162)]
CORTEX = "M80 157 C80 122.2 121.2 94 172 94 C222.8 94 264 122.2 264 157 C264 191.8 222.8 220 172 220 C121.2 220 80 191.8 80 157 Z"
el = [{"id": "night", "part": "spray", "at": [172, 162], "params": {"rx": 128, "ry": 92, "col": 2, "alpha": 0.22, "grow": 1}, "word": "deep"},
      {"id": "moon", "path": "M60 22 C42 22 34 42 44 54 C52 62 66 60 70 52 C56 54 48 42 54 30 C56 26 58 24 60 22 Z", "fill": "white", "word": "sleep"},
      text("tds", "DEEP SLEEP", [172, 22], "sleep"),
      {"id": "brain", "part": "brain", "at": list(BRAIN), "scale": 1.9, "params": {"lit": 0}, "word": "in"},
      {"id": "ctx", "group": [{"path": CORTEX, "stroke": "lime@0.6", "width": 30}], "clip": {"path": CORTEX}, "word": "cortex", "draw": 1.0}]
for k, (x, y) in enumerate(OUTS):
    el.append({"id": f"m{k}", "part": "spray", "at": [x, y], "params": {"rx": 16, "ry": 12, "col": [2, 3, 4, 3, 2][k], "alpha": 0.85, "grow": 1}, "word": "storage", "delay": 0.1 * k, "hidden": True})
el.append(hippo("in", hidden=False))
for r, word in enumerate(["replays", "day"]):
    for k, (x, y) in enumerate(OUTS):
        el.append({"id": f"r{r}{k}", "group": [{"circle": [0, 0, 5], "fill": "yellow"}], "at": list(HIPPO), "hidden": True, "word": word})
el += [{"id": "lctx", "label": "CORTEX", "anchor": [172, 96], "at": [172, 72], "align": "center", "word": "outer", "delay": 0.2},
       text("tlt", "LONG-TERM STORAGE", [172, 262], "storage")]
mv3 = pop("tds", "sleep")
for r, word in enumerate(["replays", "day"]):
    for k, (x, y) in enumerate(OUTS):
        d = 0.08 * k
        mv3 += [mv(f"r{r}{k}", "opacity", 1, word, 0.2, d), mv(f"r{r}{k}", "x", x, word, 0.9, d), mv(f"r{r}{k}", "y", y, word, 0.9, d),
                mv(f"r{r}{k}", "opacity", 0, word, 0.3, d + 0.9)]
for k, (x, y) in enumerate(OUTS):
    d = 0.08 * k
    mv3 += [mv(f"r2{k}", "opacity", 1, "gradually", 0.2, d), mv(f"r2{k}", "x", x, "gradually", 1.0, d), mv(f"r2{k}", "y", y, "gradually", 1.0, d),
            mv(f"r2{k}", "opacity", 0, "gradually", 0.3, d + 1.0)]
    el.append({"id": f"r2{k}", "group": [{"circle": [0, 0, 5], "fill": "yellow"}], "at": list(HIPPO), "hidden": True, "word": "gradually"})
    mv3.append(mv(f"m{k}", "opacity", 1, "storage", 0.5, 0.1 * k))
mv3 += pop("tlt", "storage", 0.2)
mv3 += [mv("hip", "opacity", 0.55, "storage", 0.8, 0.4)]
scenes.append({"card": 3, "label": "A brain at night under a moon; yellow beads flow from the hippocampus out to the brain's green outer layer, where coloured patches of memory settle in.",
               "elements": el, "moves": mv3})

# ---- card 5: the student who sleeps (left) remembers more than the one who pulls an all-nighter (right); then a recap of cards 1-4
MOON = "M60 22 C42 22 34 42 44 54 C52 62 66 60 70 52 C56 54 48 42 54 30 C56 26 58 24 60 22 Z"
STUDENTS = ["moon", "bed", "zz", "lamp", "who", "bl", "br", "tsl", "tst", "tmore"]
el = [{"id": "moon", "path": MOON, "fill": "white", "word": "sleep"},
      {"id": "bed", "group": [
          {"path": "M24 196 L156 196 M28 196 L28 214 M152 196 L152 214", "stroke": "ink", "width": 2.2},
          {"rect": [26, 168, 30, 14, 6], "fill": "white"},
          {"circle": [44, 166, 13], "fill": "skin"},
          {"rect": [52, 164, 100, 32, 10], "fill": "blue@0.85"}], "word": "sleep"},
      text("zz", "Z z", [72, 146], "sleep", 19, 0.4),
      {"id": "lamp", "part": "glow", "at": [250, 150], "params": {"r": 60, "col": 3, "alpha": 0.45}, "word": "pull"},
      {"id": "who", "part": "person", "at": [250, 214], "scale": 0.62, "params": {"blink": 0}, "word": "pull"},
      {"id": "bl", "part": "brain", "at": [90, 82], "scale": 0.62, "params": {"lit": 0}, "word": "remember"},
      {"id": "br", "part": "brain", "at": [250, 58], "scale": 0.5, "params": {"lit": 0}, "word": "remember", "delay": 0.2},
      text("tsl", "SLEPT", [90, 246], "sleep"),
      text("tst", "ALL-NIGHTER", [232, 246], "pull"),
      text("tmore", "REMEMBERS MORE", [130, 24], "more", 22)]
mv4 = pop("zz", "sleep", 0.4) + pop("tsl", "sleep") + pop("tst", "pull")
mv4 += [mv("bl", "lit", 1, "more", 0.6), mv("br", "lit", 0.15, "more", 0.6)] + pop("tmore", "more", 0.2)
mv4 += [mv("br", "opacity", 0.45, "learning", 0.8), mv("who", "blink", 1, "learning", 0.2),
        mv("bl", "scale", 0.72, "close", 0.4), mv("bl", "scale", 0.62, "close", 0.5, 0.4)]
mv4 += [mv(k, "opacity", 0, "new", 0.4) for k in STUDENTS]

# the recap: four small panels, one per card, each on its words. Content in card coordinates, scaled 0.45.
S = 0.45
PAN = {"q1": [4, 2], "q2": [168, 2], "q3": [4, 126], "q4": [160, 124]}
# 1: soft cement (cells sag into it)
q1 = [{"part": "spray", "at": [172, 130], "params": {"rx": 140, "ry": 100, "col": 7, "alpha": 0.22, "grow": 1}},
      {"rect": [52, 196, 240, 44, 10], "fill": "ink@0.22"},
      {"id": "q1net", "group": [{"path": links, "stroke": "ink", "width": 2.4}] + [cell(f"q1c{k}", list(p), 0.42, None) for k, p in enumerate(C)]}]
# 2: links thicken with proteins
q2 = [{"part": "spray", "at": [172, 140], "params": {"rx": 150, "ry": 100, "col": 2, "alpha": 0.16, "grow": 1}},
      {"path": f"M122 {Y} L222 {Y}", "stroke": "ink", "width": 1.6},
      {"id": "q2thick", "rect": [120, Y - 9, 104, 18, 9], "fill": "yellow", "hidden": True},
      cell("q2l", list(L), 1.0, None), cell("q2r", list(R), 1.0, None)]
q2 += [{"id": f"q2p{k}", "group": [{"circle": [0, 0, 6], "fill": "orange"}], "at": [DEST[k], Y], "hidden": True} for k in range(6)]
# 3: the hippocampus ties the pieces
q3 = [{"part": "brain", "at": list(BRAIN), "scale": 1.9, "params": {"lit": 0}}]
q3 += [{"id": f"q3s{k}", "part": "spray", "at": [x, y], "params": {"rx": 26, "ry": 18, "col": col, "alpha": 0.8, "grow": 1}, "hidden": True} for k, (x, y, col, w) in enumerate(REG)]
q3 += [{"id": f"q3t{k}", "path": f"M{HIPPO[0]} {HIPPO[1]} L{x} {y}", "stroke": "orange", "width": 3, "hidden": True} for k, (x, y, col, w) in enumerate(REG)]
h = hippo(None, hidden=False); h["id"] = "q3hip"; del h["word"]; h["hidden"] = True
q3.append(h)
# 4: sleep replays it to the cortex
q4 = [{"path": MOON, "fill": "white"},
      {"part": "brain", "at": list(BRAIN), "scale": 1.9, "params": {"lit": 0}},
      {"group": [{"path": CORTEX, "stroke": "lime@0.6", "width": 30}], "clip": {"path": CORTEX}}]
q4 += [{"id": f"q4m{k}", "part": "spray", "at": [x, y], "params": {"rx": 16, "ry": 12, "col": [2, 7, 3, 7, 2][k], "alpha": 0.85, "grow": 1}, "hidden": True} for k, (x, y) in enumerate(OUTS)]
q4 += [{"id": f"q4r{k}", "group": [{"circle": [0, 0, 6], "fill": "yellow"}], "at": list(HIPPO), "hidden": True} for k in range(len(OUTS))]
for name, kids, word in [("q1", q1, "starts"), ("q2", q2, "cells"), ("q3", q3, "hippocampus"), ("q4", q4, "sleep#2")]:
    for k in kids:
        if "word" in k and k["word"] is None:
            del k["word"]
        for g in k.get("group", []):
            if g.get("word", 1) is None:
                del g["word"]
    el.append({"id": name, "group": kids, "at": PAN[name], "scale": S, "word": word, "hidden": True, "draw": 0.4})
mv4 += [mv("q1", "opacity", 1, "starts", 0.3), mv("q1net", "y", 14, "soft", 0.4), mv("q1net", "y", 0, "soft", 0.5, 0.45)]
mv4 += [mv("q2", "opacity", 1, "cells", 0.3)] + [mv(f"q2p{k}", "opacity", 1, "build", 0.2, 0.05 * k) for k in range(6)]
mv4 += [mv("q2thick", "opacity", 1, "proteins", 0.4, 0.3)]
mv4 += [mv("q3", "opacity", 1, "hippocampus", 0.3), mv("q3hip", "opacity", 1, "hippocampus", 0.3, 0.1)]
mv4 += [mv(f"q3s{k}", "opacity", 1, "pieces", 0.3, 0.1 * k) for k in range(3)]
mv4 += [mv(f"q3t{k}", "opacity", 1, "ties", 0.3, 0.1 * k) for k in range(3)]
mv4 += [mv("q4", "opacity", 1, "sleep#2", 0.3)]
for k, (x, y) in enumerate(OUTS):
    mv4 += [mv(f"q4r{k}", "opacity", 1, "moves", 0.2, 0.06 * k), mv(f"q4r{k}", "x", x, "moves", 0.7, 0.06 * k), mv(f"q4r{k}", "y", y, "moves", 0.7, 0.06 * k),
            mv(f"q4r{k}", "opacity", 0, "storage", 0.3), mv(f"q4m{k}", "opacity", 1, "storage", 0.4, 0.08 * k)]
scenes.append({"card": 4, "label": "A student asleep in bed under a moon remembers more than a student pulling an all-nighter by a lamp; then four small pictures recap the topic: cells in wet cement, a link made sturdy by proteins, the hippocampus tying pieces together, and sleep replaying it to the cortex.",
               "elements": el, "moves": mv4})

for s in scenes:
    for e in s["elements"]:
        if e.get("onpicture") is False:
            del e["onpicture"]
OUT.write_text(json.dumps({"scenes": scenes}, indent=1) + "\n")
print(OUT)
