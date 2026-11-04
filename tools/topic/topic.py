"""One command from a finished topic to something you can look at: voice, scene check, simulator build, frames, contact sheets.

    python3 topic.py make <id> [--phone] [--skip-voice] [--skip-frames]

Needs, already written: ios/Polymath/Topics/<id>.json (the words), ios/Polymath/Scenes/<id>.json (the pictures). The spoken script
tools/voice/<id>.txt is drafted from the cards if it is missing. Steps, each timed:

    voice   narrate.py render <id>          only if the script is newer than voice-<id>.json (or there is none)
    check   scene.py check <id>             stops here if there are errors, so an agent can fix and run again
    build   ios/run.sh                      builds the simulator app and installs it
    frames  scene.py frames <id>            one screenshot per moment of each card
    sheets  one contact sheet per card      ios/build/frames/<id>/card<N>.png, frames in time order with their second on top
    phone   ios/run-device.sh <id>          only with --phone

The agent looks at the sheets (what to look for: .claude/skills/topic/drafting.md), fixes the scene file and runs this again.
"""
import argparse, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
IOS, APP, VOICE = ROOT / "ios", ROOT / "ios" / "Polymath", ROOT / "tools" / "voice"
STEPS = []


def step(name, fn):
    t = time.time()
    ok = fn()
    STEPS.append((name, time.time() - t))
    if ok is False:
        summary()
        sys.exit(f"\nStopped at {name}.")


def run(cmd, cwd=None):
    r = subprocess.run(cmd, cwd=cwd)
    return r.returncode == 0


def voice(tid):
    script, out = VOICE / f"{tid}.txt", APP / "Resources" / f"voice-{tid}.json"
    if not script.exists():
        print(f"drafting {script.name} from the cards")
        if not run([sys.executable, str(VOICE / "narrate.py"), "new", tid]):
            return False
    if out.exists() and out.stat().st_mtime >= script.stat().st_mtime:
        print("voice is up to date")
        return True
    return run([sys.executable, str(VOICE / "narrate.py"), "render", tid])


def sheets(tid, frames_dir):
    from PIL import Image, ImageDraw
    by_card = {}
    for p in sorted(frames_dir.glob("card*-scene.png")):
        by_card.setdefault(p.name.split("-")[0], []).append(p)
    if not by_card:
        print("no frames found")
        return False
    for card, files in by_card.items():
        ims = [Image.open(f).convert("RGB") for f in files]
        w, h = ims[0].size
        cols = min(3, len(ims))
        rows = (len(ims) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * w, rows * (h + 22)), "white")
        d = ImageDraw.Draw(sheet)
        for i, (f, im) in enumerate(zip(files, ims)):
            x, y = (i % cols) * w, (i // cols) * (h + 22)
            d.text((x + 6, y + 5), f"{float(f.name.split('-')[1]):.1f} s", fill="black")
            sheet.paste(im, (x, y + 22))
        out = frames_dir / f"{card}.png"
        sheet.save(out)
        print(out)
    return True


def summary():
    print("\nTimings")
    for name, s in STEPS:
        print(f"  {name:7s} {s:6.1f} s")
    print(f"  {'total':7s} {sum(s for _, s in STEPS):6.1f} s")


def make(a):
    tid = a.id
    for need in (APP / "Topics" / f"{tid}.json", APP / "Scenes" / f"{tid}.json"):
        if not need.exists():
            sys.exit(f"Missing {need.relative_to(ROOT)}")
    if not a.skip_voice:
        step("voice", lambda: voice(tid))
    step("check", lambda: run([sys.executable, str(ROOT / "tools" / "scene" / "scene.py"), "check", tid]))
    if not a.skip_frames:
        step("build", lambda: run(["xcodegen", "generate", "--quiet"], cwd=IOS) and run(["./run.sh"], cwd=IOS))
        out = IOS / "build" / "frames" / tid
        for old in out.glob("*.png") if out.exists() else []:
            old.unlink()
        step("frames", lambda: run([sys.executable, str(ROOT / "tools" / "scene" / "scene.py"), "frames", tid, "--out", str(out)]))
        step("sheets", lambda: sheets(tid, out))
    if a.phone:
        step("phone", lambda: run(["./run-device.sh", tid], cwd=IOS))
    summary()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["make"]); ap.add_argument("id")
    ap.add_argument("--phone", action="store_true", help="also build and launch on the iPhone")
    ap.add_argument("--skip-voice", action="store_true"); ap.add_argument("--skip-frames", action="store_true")
    make(ap.parse_args())


if __name__ == "__main__":
    main()
