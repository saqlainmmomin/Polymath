"""Writes ios/Polymath/Scenes/memory-recall.json (airbrush)."""
import json, sys

OUT = "/Users/saqlainmomin/tell-me-how/ios/Polymath/Scenes/memory-recall.json"
TIP = "tipofthetongue"

SAW, HEARD, FELT = (250, 118), (192, 150), (255, 178)


def piece(kind, at, **kw):
    if kind == "saw":
        kids = [{"circle": [0, 0, 16], "fill": "blue"},
                {"path": "M-10 0 Q0 -9 10 0 Q0 9 -10 0 Z", "fill": "white"},
                {"circle": [0, 0, 3.2], "fill": "ink", "stroke": "none"}]
    elif kind == "heard":
        kids = [{"rect": [-16, -16, 32, 32, 7], "fill": "orange"},
                {"path": "M-3 7 L-3 -8 L7 -10 L7 4", "stroke": "ink", "width": 1.8},
                {"circle": [-5.5, 7, 3], "fill": "ink", "stroke": "none"},
                {"circle": [4.5, 4.5, 3], "fill": "ink", "stroke": "none"}]
    elif kind == "felt":
        kids = [{"path": "M0 17 C-24 2 -20 -20 0 -9 C20 -20 24 2 0 17 Z", "fill": "vg:lime:green"},
                {"circle": [-5, -3, 2.2], "fill": "ink", "stroke": "none"}, {"circle": [5, -3, 2.2], "fill": "ink", "stroke": "none"},
                {"path": "M-5 4 Q0 8 5 4", "stroke": "ink", "width": 1.5}]
    elif kind == "new":
        kids = [{"part": "glow", "params": {"r": 28, "col": 1, "alpha": 0.9}},
                {"path": "M0 17 C-24 2 -20 -20 0 -9 C20 -20 24 2 0 17 Z", "fill": "vg:lime:green"},
                {"circle": [-5, -3, 2.2], "fill": "ink", "stroke": "none"}, {"circle": [5, -3, 2.2], "fill": "ink", "stroke": "none"},
                {"path": "M-5 6 Q0 2 5 6", "stroke": "ink", "width": 1.5}]
    e = {"id": kw.pop("id", kind), "group": kids, "at": list(at)}
    e.update(kw)
    return e


def backdrop(word=None):
    a = {"id": "bg", "part": "spray", "at": [228, 150], "params": {"rx": 96, "ry": 82, "col": 2, "alpha": 0.22, "grow": 1}}
    b = {"id": "brain", "part": "brain", "at": [225, 145], "scale": 1.5, "params": {"lit": 0}}
    if word:
        a["word"] = b["word"] = word
    return [a, b]


def links(word=None, delay=None):
    out = []
    for i, (p, q) in enumerate([(HEARD, SAW), (HEARD, FELT), (SAW, FELT)]):
        e = {"id": f"l{i}", "path": f"M{p[0]} {p[1]} L{q[0]} {q[1]}", "stroke": "ink@0.75", "width": 1.8}
        if word:
            e["word"] = word
        if delay:
            e["delay"] = delay + 0.15 * i
        out.append(e)
    return out


def text(id_, s, at, word, size=22, delay=None, onpic=True, hidden=True):
    e = {"id": id_, "text": s, "at": list(at), "size": size, "word": word, "hidden": hidden, "scale": 0.4}
    if onpic:
        e["onpicture"] = True
    if delay:
        e["delay"] = delay
    return e


def pop(id_, word, delay=0, dur=0.3):
    m = [{"move": id_, "prop": "opacity", "to": 1, "word": word, "dur": dur},
         {"move": id_, "prop": "scale", "to": 1.0, "word": word, "dur": 0.5, "ease": "snap"}]
    if delay:
        for x in m:
            x["delay"] = delay
    return m


def pulse(id_, word, delay=0, to=1.18):
    return [{"move": id_, "prop": "scale", "to": to, "word": word, "dur": 0.25, "delay": delay},
            {"move": id_, "prop": "scale", "to": 1.0, "word": word, "dur": 0.4, "delay": delay + 0.3}]


def fade(id_, word, to=0, delay=0, dur=0.4):
    m = {"move": id_, "prop": "opacity", "to": to, "word": word, "dur": dur}
    if delay:
        m["delay"] = delay
    return m


scenes = []

# ---- card 1: not a video; linked pieces in the brain
c1 = backdrop("brain") + [
    {"id": "vid", "group": [
        {"rect": [-46, -32, 92, 64, 8], "fill": "blue@0.55"},
        {"path": "M-9 -14 L15 0 L-9 14 Z", "fill": "white"}], "at": [70, 140], "word": "remembering"},
    {"id": "x", "group": [
        {"path": "M-52 -38 L52 38", "stroke": "ink", "width": 3},
        {"path": "M52 -38 L-52 38", "stroke": "ink", "width": 3}], "at": [70, 140], "word": "video"},
    text("nv", "NOT A VIDEO", (70, 206), "video", delay=0.2),
] + links("stored") + [
    piece("saw", SAW, word="saw"),
    piece("heard", HEARD, word="heard"),
    piece("felt", FELT, word="felt"),
    {"label": "SAW", "anchor": [250, 101], "at": [262, 66], "align": "center", "word": "saw", "delay": 0.2},
    {"label": "HEARD", "anchor": [180, 138], "at": [150, 74], "align": "center", "word": "heard", "delay": 0.2},
    {"label": "FELT", "anchor": [255, 195], "at": [255, 242], "align": "center", "word": "felt", "delay": 0.2},
]
m1 = pop("nv", "video", 0.2) + pulse("saw", "back") + pulse("heard", "back", 0.15) + pulse("felt", "back", 0.3)
scenes.append({"card": 0, "label": "A video with a play button is crossed out: not a video. A brain holds three linked pieces: what you saw, heard and felt.",
               "elements": c1, "moves": m1})

# ---- card 2: cues on the left; the song matches one piece
c2 = backdrop() + links() + [
    {"id": "glowH", "part": "glow", "at": list(HEARD), "params": {"r": 32, "col": 1, "alpha": 0.95}, "hidden": True},
    piece("saw", SAW), piece("heard", HEARD), piece("felt", FELT),
    text("cue", "CUE", (50, 36), "cue", size=24),
    text("q", "?", (50, 82), "question", size=36),
    {"id": "cup", "group": [
        {"path": "M0 16 L0 0", "stroke": "green", "width": 2.2},
        {"path": "M0 10 C5 6 9 7 11 9 C8 12 4 12 0 10 Z", "fill": "lime"},
        {"circle": [0, -10, 5.5], "fill": "salmon"}, {"circle": [-8, -4, 5.5], "fill": "salmon"}, {"circle": [8, -4, 5.5], "fill": "salmon"},
        {"circle": [-5, 4, 5.5], "fill": "salmon"}, {"circle": [5, 4, 5.5], "fill": "salmon"}, {"circle": [0, -2, 4.5], "fill": "yellow"},
        {"path": "M16 -12 C20 -15 22 -9 26 -12 M17 -2 C21 -5 23 1 27 -2", "stroke": "ink@0.6", "width": 1.4}], "at": [46, 132], "scale": 1.35, "word": "smell"},
    {"id": "note", "group": [
        {"path": "M-3 10 L-3 -14 L11 -18 L11 6", "stroke": "ink", "width": 2.2},
        {"circle": [-7, 10, 5], "fill": "orange"},
        {"circle": [7, 6, 5], "fill": "orange"}], "at": [50, 180], "word": "song"},
    {"id": "house", "group": [
        {"path": "M-14 16 L-14 -2 L14 -2 L14 16 Z", "fill": "skin"},
        {"path": "M-19 -1 L0 -18 L19 -1 Z", "fill": "blue"},
        {"rect": [-4, 4, 8, 12], "fill": "ink@0.7", "stroke": "none"}], "at": [50, 226], "word": "place"},
    {"id": "arr", "part": "arrow", "at": [72, 174], "rotate": -12, "params": {"len": 96, "col": 0, "w": 2.4, "head": 9}, "word": "matches"},
    text("mt", "MATCHES ONE PIECE", (180, 262), "matches", delay=0.3),
]
m2 = pop("cue", "cue") + pop("q", "question") + [fade("glowH", "matches", 1, 0.2, 0.5)] + pop("mt", "matches", 0.3) \
    + pulse("note", "matches") + pulse("heard", "wakes")
scenes.append({"card": 1, "label": "Cues on the left: a question mark, a cup with a smell, a song, a place. An arrow runs from the song to the matching piece in the brain, which glows.",
               "elements": c2, "moves": m2})

# ---- card 3: wakes up, spreads, whole memory; then dim but still there, a wrong cue bounces off, the right cue clicks
NOTE = [{"path": "M-3 10 L-3 -14 L11 -18 L11 6", "stroke": "ink", "width": 2.2},
        {"circle": [-7, 10, 5], "fill": "orange"}, {"circle": [7, 6, 5], "fill": "orange"}]
HOUSE = [{"path": "M-14 16 L-14 -2 L14 -2 L14 16 Z", "fill": "skin"}, {"path": "M-19 -1 L0 -18 L19 -1 Z", "fill": "blue"},
         {"rect": [-4, 4, 8, 12], "fill": "ink@0.7", "stroke": "none"}]
c3 = backdrop() + links() + [
    {"id": "glowH", "part": "glow", "at": list(HEARD), "params": {"r": 32, "col": 1, "alpha": 0.95}, "hidden": True},
    piece("saw", SAW), piece("heard", HEARD), piece("felt", FELT),
    {"id": "note", "group": NOTE, "at": [50, 180]},
    {"id": "arr", "part": "arrow", "at": [72, 174], "rotate": -12, "params": {"len": 96, "col": 0, "w": 2.4, "head": 9}},
    {"id": "b1", "group": [{"circle": [0, 0, 5], "fill": "yellow"}], "at": list(HEARD), "hidden": True},
    {"id": "b2", "group": [{"circle": [0, 0, 5], "fill": "yellow"}], "at": list(HEARD), "hidden": True},
    text("wm", "WHOLE MEMORY", (225, 40), "whole", delay=0.3),
    {"id": "wrong", "group": HOUSE, "at": [44, 150], "hidden": True},
    {"id": "right", "group": NOTE, "at": [44, 160], "hidden": True},
    text("st", "STILL THERE", (225, 250), "still"),
    text("tip", "TIP OF THE TONGUE", (225, 40), TIP, delay=0.1),
]
PIECES = ["saw", "heard", "felt", "l0", "l1", "l2"]
m3 = [fade("glowH", "wakes", 1, 0, 0.4)] + pulse("heard", "wakes") + [
    fade("b1", "spreads", 1, 0, 0.15), fade("b2", "spreads", 1, 0, 0.15),
    {"move": "b1", "prop": "x", "to": SAW[0], "word": "spreads", "dur": 0.8, "ease": "eio"},
    {"move": "b1", "prop": "y", "to": SAW[1], "word": "spreads", "dur": 0.8, "ease": "eio"},
    {"move": "b2", "prop": "x", "to": FELT[0], "word": "spreads", "dur": 0.8, "ease": "eio"},
    {"move": "b2", "prop": "y", "to": FELT[1], "word": "spreads", "dur": 0.8, "ease": "eio"},
    fade("b1", "whole", 0, 0.3), fade("b2", "whole", 0, 0.3),
    {"move": "brain", "prop": "lit", "to": 1, "word": "whole", "dur": 0.6},
] + pop("wm", "whole", 0.3) + [
    {"move": "brain", "prop": "lit", "to": 0, "word": "cant", "dur": 0.5},
    fade("glowH", "cant"), fade("wm", "cant"), fade("note", "cant"), fade("arr", "cant"),
] + [fade(x, "cant", 0.3, 0.2, 0.6) for x in PIECES] + pop("st", "still") + [
    # a wrong cue flies in and bounces off
    fade("wrong", "missing", 1, 0, 0.2),
    {"move": "wrong", "prop": "x", "to": 150, "word": "missing", "dur": 0.45, "ease": "eio"},
    {"move": "wrong", "prop": "x", "to": 70, "word": "missing", "dur": 0.5, "delay": 0.5, "ease": "snap"},
    {"move": "wrong", "prop": "rotate", "to": -25, "word": "missing", "dur": 0.4, "delay": 0.5},
    fade("wrong", "right", 0, 0.1, 0.3),
    # the right cue clicks
    fade("right", "cue", 1, 0, 0.2),
    {"move": "right", "prop": "x", "to": 152, "word": "cue", "dur": 0.5, "ease": "eio"},
    {"move": "right", "prop": "y", "to": 156, "word": "cue", "dur": 0.5, "ease": "eio"},
    fade("right", "thats", 0, 0.2, 0.3),
    fade("glowH", "thats", 1, 0, 0.3),
] + [fade(x, "thats", 1, 0.1, 0.4) for x in PIECES] + [
    {"move": "brain", "prop": "lit", "to": 1, "word": "thats", "dur": 0.5, "delay": 0.2},
    fade("st", TIP, 0, 0, 0.3),
] + pop("tip", TIP, 0.1) + pulse("saw", "together") + pulse("heard", "together", 0.15) + pulse("felt", "together", 0.3)
scenes.append({"card": 2, "label": "The song's piece glows, yellow signals run along the links and the whole brain lights up. Then the pieces go dim but stay; a house cue bounces off, the song cue clicks into place and the memory lights again: the tip of the tongue.",
               "elements": c3, "moves": m3})

# ---- card 4: put back together, a gap, filled with what it expects
c4 = backdrop() + links("together", 0.6) + [
    piece("saw", (64, 76)), piece("heard", (96, 206)),
    {"id": "gap", "circle": [FELT[0], FELT[1], 16], "stroke": "ink@0.8", "width": 1.6, "dash": [4, 4], "word": "gaps", "hidden": True},
    {"id": "gapL", "label": "GAP", "anchor": [255, 196], "at": [255, 242], "align": "center", "word": "gaps", "delay": 0.2},
    piece("new", FELT, word="expects", hidden=True, scale=0.4),
    {"id": "exL", "label": "WHAT IT\nEXPECTS", "anchor": [240, 186], "at": [112, 228], "align": "center", "word": "expects", "delay": 0.3},
]
m4 = [
    {"move": "saw", "prop": "x", "to": SAW[0], "word": "together", "dur": 0.8, "ease": "eio"},
    {"move": "saw", "prop": "y", "to": SAW[1], "word": "together", "dur": 0.8, "ease": "eio"},
    {"move": "heard", "prop": "x", "to": HEARD[0], "word": "together", "dur": 0.8, "delay": 0.15, "ease": "eio"},
    {"move": "heard", "prop": "y", "to": HEARD[1], "word": "together", "dur": 0.8, "delay": 0.15, "ease": "eio"},
    fade("gap", "gaps", 1, 0, 0.3),
    fade("gap", "expects", 0, 0.3), fade("gapL", "expects", 0, 0, 0.3),
] + pop("new", "expects", 0.1) + pulse("new", "change", 0, 1.25) + pulse("saw", "noticing") + pulse("heard", "noticing", 0.15)
scenes.append({"card": 3, "label": "Two pieces fly back into the brain and link up, leaving a dashed gap; the brain fills the gap with a new lime piece: what it expects.",
               "elements": c4, "moves": m4})

# ---- card 5: a video of a crash; hit (left) gives a lower speed, smashed (right) a higher one and broken glass that was never there
car_body = "M-28 4 L-28 -6 C-28 -10 -24 -12 -20 -12 L-10 -12 L-4 -22 L14 -22 L20 -12 L24 -12 C28 -12 30 -8 30 -4 L30 4 Z"
def car(id_, at, col, mirror=False):
    e = {"id": id_, "group": [
        {"path": car_body, "fill": col},
        {"path": "M-6 -13 L-1 -19 L12 -19 L16 -13 Z", "fill": "white"},
        {"circle": [-16, 5, 6], "fill": "ink", "stroke": "none"},
        {"circle": [18, 5, 6], "fill": "ink", "stroke": "none"}], "at": list(at), "scale": 0.6, "word": "video"}
    if mirror:
        e["mirror"] = True
    return e

def gauge(id_, x, y, col, word):
    return [
        {"id": id_ + "g", "group": [
            {"path": "M-36 0 C-36 -48 36 -48 36 0 Z", "fill": col},
            {"path": "M-28 -2 L-22 -2 M0 -30 L0 -24 M28 -2 L22 -2", "stroke": "ink@0.7", "width": 1.4}], "at": [x, y], "word": word},
        {"id": id_ + "n", "group": [
            {"path": "M0 0 L-29 0", "stroke": "ink", "width": 3},
            {"circle": [0, 0, 3.5], "fill": "ink", "stroke": "none"}], "at": [x, y], "word": word},
    ]

LX, RX = 86, 232
c5 = [
    {"id": "screen", "rect": [106, 14, 132, 72, 8], "fill": "skin", "word": "video"},
    {"id": "road", "path": "M114 70 L230 70", "stroke": "ink", "width": 1.6, "word": "video"},
    car("carA", (128, 64), "blue"), car("carB", (216, 64), "orange", mirror=True),
    {"id": "bang", "part": "glow", "at": [172, 56], "params": {"r": 16, "col": 3, "alpha": 0.8}, "hidden": True},
    {"id": "cols", "group": [
        {"id": "w1", "text": "\"HIT\"", "at": [LX, 118], "size": 24, "word": "hit", "onpicture": True},
        *gauge("h", LX, 192, "blue@0.45", "hit"),
        {"id": "w2", "text": "\"SMASHED\"", "at": [RX, 118], "size": 24, "word": "smashed", "onpicture": True},
        *gauge("s", RX, 192, "orange", "smashed"),
    ]},
    {"id": "glass", "group": [
        {"part": "glow", "params": {"r": 26, "col": 1, "alpha": 0.9}},
        {"path": "M-16 2 L-9 -5 L-5 3 Z", "fill": "blue@0.7"},
        {"path": "M2 -1 L11 -7 L13 3 Z", "fill": "blue@0.7"},
        {"path": "M-4 6 L5 4 L0 11 Z", "fill": "blue@0.7"}], "at": [RX, 220], "word": "glass", "hidden": True},
    text("gl", "BROKEN GLASS", (RX - 6, 256), "glass", delay=0.2),
    text("nt", "NEVER THERE", (RX - 6, 256), "never"),
    text("end", "REBUILDING,\nNOT REPLAYING", (172, 180), "rebuilding", size=28, delay=0.4),
]
m5 = [
    {"move": "carA", "prop": "x", "to": 156, "word": "crash", "dur": 0.6, "ease": "fall"},
    {"move": "carB", "prop": "x", "to": 188, "word": "crash", "dur": 0.6, "ease": "fall"},
    fade("bang", "crash", 1, 0.55, 0.2),
    {"move": "hn", "prop": "rotate", "to": 55, "word": "each", "dur": 0.8, "ease": "snap"},
    {"move": "sn", "prop": "rotate", "to": 140, "word": "faster", "dur": 0.8, "ease": "snap"},
    fade("glass", "glass", 1, 0, 0.4),
] + pop("gl", "glass", 0.2) + [
    fade("gl", "never", 0, 0, 0.3),
    fade("glass", "never", 0.15, 0.3, 0.8),
] + pop("nt", "never", 0.3) + [
    fade("cols", "rebuilding", 0, 0, 0.4), fade("glass", "rebuilding", 0, 0, 0.4), fade("nt", "rebuilding", 0, 0, 0.4),
] + pop("end", "rebuilding", 0.4)
scenes.append({"card": 4, "label": "A small video of two cars crashing. Left, the word hit sends a blue speed needle low; right, smashed sends an orange needle high and broken glass glows below it, then fades: never there. Last: rebuilding, not replaying.",
               "elements": c5, "moves": m5})

json.dump({"scenes": scenes}, open(OUT, "w"), indent=1)
print("wrote", OUT)
