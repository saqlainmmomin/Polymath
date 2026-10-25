# Direction: native iOS app, hybrid visuals ("option 5")

> **Update 2026-10-25: live 3D dropped.** A live RealityKit view per card made scrolling laggy and the primitive-built 3D looked rough. The shipped GPS pictures are flat 2D scenes in one SwiftUI `Canvas` (`ios/Polymath/FlatGPS.swift`, registered in `Pictures.swift`): smooth scrolling, haptics, tap to replay. The RealityKit spike was removed; it lives in git history (commit before the "single Polymath app" commit). If 3D returns, use it only as a pre-rendered loop or on a tap, never live while scrolling. The rest of this file is the original reasoning.

Decided 2026-10-24 by the owner. Read `PRODUCT.md` first; this changes how we ship and what the visuals look like, not the product goal (curiosity, effortless, broad appeal).

## Decision

Final target is a **native iOS app**, not a web page. The visual style becomes a **hybrid**:
- **Flat 2D diagrams** (the current ink line-art blocks: gears, pistons, strokes, `diagram`) stay for mechanical topics, where flat is the clearest way to teach.
- **Rich 3D / illustrated scenes** for topics where wonder is the point (GPS, sky, space, nature): a small person on a globe, night sky, real-looking satellite, glowing signals. Reference look: pixel/isometric/cutaway illustrations with tiny people for scale, warm colour, layers you can see into.
- Topics stay **plain data files** so they are easy to write; the renderer is what changes.

Dependencies are fine now. The web build (`dist/*.html`) remains the working reference until the native app replaces it.

## How we got here

1. Owner showed four references (pixel fridge, vending-machine catalogue, isometric "high-rise zoo", hand-inked stacked building) and asked for animations that look like that instead of flat diagrams, e.g. GPS = person standing on Earth, real satellite, night sky.
2. First answer: yes, via an illustrated scene visual (2.5D canvas). Three web routes were weighed: illustrated canvas, real WebGL (three.js), isometric cutaway.
3. Owner then said the end goal is an iOS app, so we are not limited to HTML. Five options were laid out:

| # | Option | Verdict |
|---|---|---|
| 1 | Native SwiftUI + RealityKit (real 3D) | Best 3D quality, but needs a full rewrite and 3D assets |
| 2 | Native SwiftUI + Rive (illustrated, interactive 2D) | Great illustrated look, but scenes are authored in Rive's editor, not code, and it is not true 3D |
| 3 | Existing web app in a native shell (Capacitor/WKWebView) + three.js | Cheapest, reuses everything, but still web rendering; lowest quality ceiling |
| 4 | Pre-rendered Blender clips | Best looking, but not interactive, large app, high cost per topic |
| 5 | **Hybrid: native shell, 2D diagrams in SwiftUI Canvas, hero 3D scenes in RealityKit** | **Chosen** |

Notes behind the choice: SceneKit is being phased out by Apple in favour of RealityKit, so skip it. The real bottleneck for 3D is assets, not code; plan on procedural scenes from primitives (spheres, cylinders, lit and stylized), with Blender scripts or free USDZ for anything fancier.

## What exists now

- `prototypes/gps-3d.html` (+ local `prototypes/three.min.js`, r128): a **three.js mock of all three GPS cards in 3D**. It is a *visual reference only*, not the product code. Cards: (1) satellite broadcasts, side beams to houses then a beam to the person's phone; (2) pulse flies down, clock counts 0.00 to 0.07 s, "About 20,000 km" measuring line; (3) globe pulls back, three coloured circles on the ground sweep out and meet at one spot, "You" pin drops. Same captions and text as `topics/gps.js`. Checked in the browser pane at phone size, not on a physical phone.
- Known rough edges: crude person model, plain cone beam, card 3 camera is top-down so satellites sit near the horizon edge.
- `topics/gps.js` and all other topics are untouched. No Xcode project exists yet.
- Xcode is now installed. The iOS Simulator tools are available in the Claude app, so native builds can be launched and screenshotted headlessly.

## Open decisions (owner is wireframing the app in parallel)

1. **Reuse of the current 2D blocks:** port them to SwiftUI Canvas (clean, native, more work) or keep them in a WKWebView for now (fast, but mixes two renderers). Leaning: port, because mixing renderers in one feed is messy.
2. **Topic data format:** keep JS data files, or convert to JSON/Swift structs the app reads. The current files may only run browser-safe code, so JSON is a straightforward target.
3. **Scene authoring pipeline:** procedural primitives only vs adding Blender/USDZ assets.
4. **Navigation/feed:** the vertical topic feed with horizontal cards (see `core/BLOCKS.md` section 4) is the current behaviour; the owner's wireframe will decide what carries over.

## Proposed next step

A **spike**: a bare Xcode project showing GPS card 1 natively in RealityKit (person on curved Earth, night sky, satellite, signal rings), viewed in the simulator and compared side by side with `prototypes/gps-3d.html`. If it holds up, port cards 2 and 3, then decide on the 2D-block port. Do not start porting other topics until the spike is judged.

## Rules that still apply (from CLAUDE.md and the owner's global rules)

- Every topic defines its own words; needs a newcomer reviewer and a fact check.
- Two-pass design rule: one design pass at build, one before exposure, none between.
- Never republish the testers' artifact link without the owner's OK.
- Several sessions may edit at once: touch only your own files.
