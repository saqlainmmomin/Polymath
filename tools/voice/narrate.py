"""Make a topic Narrated: draft its script, show its pictures' timings, render the voice, bundle it.

    python3 narrate.py new <id>       # writes <id>.txt from the topic's cards (one paragraph per card) and prints picture timings
    python3 narrate.py moments <id>   # prints each card's picture: length and when each label appears, to place {t} markers
    python3 narrate.py render <id> [--voice af_heart] [--speed 1.0]
                                      # checks the script, renders voice-<id>.m4a/.json with Kokoro, regenerates the Xcode project

The script is a draft until the owner approves it (spine-first, see RECIPE.md). Markers: `{1.6}word` = picture time 1.6 s as that
word starts, `word{1.6}` = as it ends (render.py). Between markers the picture moves in straight lines; with none, it plays at its own pace.
Only cards of type "card" are beats; the "more" card is not narrated. Once voice-<id>.* is bundled the app opens the topic Narrated.
"""
import argparse, json, re, subprocess, sys
from pathlib import Path

VOICE = Path(__file__).resolve().parent
ROOT = VOICE.parent.parent
APP = ROOT / "ios" / "Polymath"
VENV_PY = Path.home() / "kokoro-venv" / "bin" / "python"
STYLE_PREFIX = {"blueprint": "BP", "drafting": "DR", "wireframe": "WF"}


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


def moments(t):
    pics = pictures(t)
    for i, c in enumerate(beats_of(t)):
        name = pics.get(i)
        body = struct_body(name) if name else ""
        length = re.search(r"length: ([\d.]+)", body)
        print(f"\nBeat {i + 1}: {name or 'no picture'}" + (f", {length.group(1)} s" if length else ""))
        found = re.findall(r'\.(?:label|text)\(&c, "([^"]+)".*?BP\.pr\(t, ([\d.]+), ([\d.]+)\)', body)
        for text, a, b in sorted(found, key=lambda x: float(x[1])):
            print(f"  {a}-{b}  {text.replace(chr(92) + 'n', ' / ')}")
        for note in (c.get("visual") or {}).get("notes", []):
            print(f"  note: {note}")


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
    ap.add_argument("cmd", choices=["new", "moments", "render"]); ap.add_argument("id")
    ap.add_argument("--voice", default="af_heart"); ap.add_argument("--speed", type=float, default=1.0)
    a = ap.parse_args()
    t = topic(a.id)
    script = VOICE / f"{a.id}.txt"
    if a.cmd == "new":
        if script.exists():
            sys.exit(f"{script.name} exists; edit it, or delete it to draft again")
        script.write_text(draft(t))
        print(f"Drafted {script.relative_to(ROOT)} from the cards. Rewrite it as speech, add markers, get it approved.")
        moments(t)
    elif a.cmd == "moments":
        moments(t)
    else:
        if not script.exists():
            sys.exit(f"No {script.name}; run: python3 narrate.py new {a.id}")
        check(t, script)
        if not VENV_PY.exists():
            sys.exit("No Kokoro venv; see README.md")
        subprocess.run([str(VENV_PY), str(VOICE / "render.py"), str(script), str(APP / "Resources"),
                        "--voice", a.voice, "--speed", str(a.speed)], check=True)
        subprocess.run(["xcodegen", "generate", "--quiet"], cwd=ROOT / "ios", check=True)
        print(f"Bundled. {a.id} now opens Narrated.")


if __name__ == "__main__":
    main()
