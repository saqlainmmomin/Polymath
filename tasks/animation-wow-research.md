# What makes an explainer animation feel "oh my god" (research, 2026-10-27)

Goal from the owner: the pictures should make a reader say "this looks amazing", not "this looks okay". This note looks at the explainers people rave about, pulls out what they share, and maps each idea to what the iOS app can do in SwiftUI.

## The references

| Who | What people react to | The lever |
|---|---|---|
| **Bartosz Ciechanowski** (ciechanow.ski: cameras, watches, the internal combustion engine, GPS) | Real-looking 3D objects you can drag and rotate. Colour links each word in the text to a part of the picture. An undo button appears once you start playing. Works on phones. | **Touch a real thing.** The object reacts to your finger with physical motion, not a slideshow. |
| **3Blue1Brown** (manim) | The maths seems to move by itself. Objects morph into the next idea instead of being swapped. Glowing colour-coded lines on a dark background. Mystery, then investigation, then reveal. | **Continuity.** Transform, don't replace. The thing you were watching becomes the next thing. |
| **Kurzgesagt** | Rich, bright, rounded shapes, deep layered scenes, and the "infinite zoom" from a cell out to a planet. | **Scale travel and depth.** Layers in parallax, and zooming through levels of the same world. |
| **Apple product pages** (AirPods Pro, iPad Air) | One object held on screen while your scroll rotates, explodes or rebuilds it. Light sweeps, depth, gradient text. | **Your gesture drives the story.** Animation is tied to scroll or swipe progress, so it plays forward and backward with your finger. |
| **Apple Weather** | The whole screen *is* the weather: rain, snow, sun and clouds animate behind the numbers. | **Ambient, full-screen world.** The background lives and matches the content. |
| **Brilliant** (built with Rive) | Tactile, game-like micro-interactions and celebrations. | **Feedback for every touch.** State machines, springs and celebrations. |
| **Short-form video practice** | The viewer decides in about 1–2 seconds. The first frame must show the tension, the visual must prove the claim, and the picture should change every 2–4 seconds. | **The first second is the hook**, so the picture moves at once. |

## What they share

1. **One world, not five pictures.** The best ones keep a single scene and move the camera through it. Every one of our cards is still a separate picture that starts from nothing. This is the biggest gap.
2. **Continuity.** Things transform instead of appearing. In Shazam, the café's sound could literally *become* the dots, the dots become pairs, the pairs become codes, and the codes slide onto the song.
3. **The reader's finger drives it.** On Apple pages scroll scrubs the animation; on ours, the swipe between cards could. Half-swiping shows the dots half-turned into pairs.
4. **Light, not lines.** 3Blue1Brown and Weather glow: additive colour, soft bloom, particles. The look is lit, not drawn. Our scenes are thin strokes on a gradient, which reads as a diagram.
5. **Depth.** Foreground, middle and background layers move at different speeds, with a little blur on the far layer.
6. **Physical feedback.** Springs, a haptic tick when something clicks into place, and sound where the topic is sound. Shazam could play the café and the music, and the right song could lock in with a haptic thud.
7. **Restraint.** One idea moves at a time and nothing decorates. The wow comes from the one idea moving beautifully, not from more stuff.

## What iOS gives us (all native, no new dependencies)

| Lever | SwiftUI tool | Cost |
|---|---|---|
| Glow and light | `Canvas` with `.blendMode(.plusLighter)`, plus a blurred copy underneath for bloom | Low |
| Living background | `MeshGradient` (iOS 18) animated with `TimelineView`, the way Apple Weather does it | Low |
| Particles (sound, sparks, confetti) | `Canvas` + `TimelineView(.animation)` particle loop | Low–medium |
| Shader polish: ripple, grain, heat shimmer, chromatic glow | Metal `layerEffect` / `colorEffect` (iOS 17). Paul Hudson's open-source **Inferno** has ripples, noise and gradients ready to copy | Medium |
| One world across cards | Feed the swipe progress (already in `TopicView` as `drag`) into a single shared scene for the topic, so swiping scrubs it | Medium (a new stage model) |
| Haptics and sound | Core Haptics, plus a short audio clip per topic where the topic is sound | Low |
| Designer-made interactive art | Rive (Metal renderer on iOS, state machines). Callstack measured it at about 60 fps against Lottie's 17 in React Native | Needs an illustrator and a dependency |

## Recommendation: one final experiment on Shazam cards 1–3

Build the first three Shazam cards as **one continuous scene that the swipe scrubs**, rendered as light on the gradient:
- **Card 1:** the café as soft glowing silhouettes in parallax. Glowing sound particles (chatter grey-blue, music in the accent) stream into the phone, and the phone ripples (a Metal ripple) as it listens. Sound on, if the device isn't muted.
- **Swipe to card 2:** the particles don't vanish. They fly out of the phone and land as the dots of the chart, bright ones blooming. The rest dim like embers. Half a swipe leaves them mid-flight.
- **Swipe to card 3:** a kept dot reaches to the dots after it with a light trail. The pair snaps together with a haptic tick and condenses into a glowing code.

If that gets the reaction, the same recipe (one world, continuity, light, the swipe as scrubber, haptics) becomes the house style, and cards 4–5 follow.

**Cost and risk:** this is a new stage model, a continuous scene per topic instead of a picture per card. It changes `TopicView`, `CardViews` and the Shazam scenes. Battery and frame rate need checking on the phone. Reduce Motion needs a still fallback.

## Sources
- [Three good interactive explainers](https://unsung.aresluna.org/three-good-interactive-explainers/) · [Everything Bartosz Ciechanowski makes is gold](https://ericholscher.com/blog/2025/jan/7/everything-bartosz-ciechanowski-makes/) · [Want to know how cameras and lenses work?](https://statusq.org/archives/2022/06/28/)
- [3Blue1Brown FAQ (manim)](https://www.3blue1brown.com/faq/) · [3b1b-style animation guide](https://cdn.jsdelivr.net/gh/subinium/3b1b-style-animation-skill@main/README.md) · [Simon Willison on 3Blue1Brown](https://simonwillison.net/2024/Apr/11/3blue1brown/)
- [Simple, Bright, Beautiful: The Work of Kurzgesagt](https://artsatmichigan.umich.edu/ink/2019/09/27/simple-bright-beautiful-the-work-of-kurzgesagt)
- [iPad Air launch website (Cannes Lions)](https://www.lovethework.com/work-awards/campaigns/ipad-air-launch-website-1542435) · [How Apple builds scroll pages (dev.to)](https://www.Dev.to/jackharner/how-does-apple-create-such-stunning-landing-pages-4ak4) · [Scrollytelling mechanics](https://theplusaddons.com/blog/scrollytelling/)
- [AppleInsider: Weather gets animated](https://appleinsider.com/articles/13/06/18/inside-ios-7-apples-weather-app-gets-animated) · [Hacking with Swift: Remaking Weather](https://www.hackingwithswift.com/plus/remaking-weather) · [Weather-style animated background in SwiftUI](https://vp0.com/blogs/weather-app-animated-background-swiftui)
- [How Brilliant motivates learners with Rive](https://rive.app/blog/how-brilliant-org-motivates-learners-with-rive-animations) · [Callstack: Lottie vs Rive](https://callstack.com/blog/lottie-vs-rive-optimizing-mobile-app-animation)
- [Inferno: Metal shaders for SwiftUI](https://www.hackingwithswift.com/articles/262/introducing-inferno-metal-shaders-for-swiftui) · [Metal layer effects in SwiftUI](https://hackingwithswift.com/quick-start/swiftui/how-to-add-metal-shaders-to-swiftui-views-using-layer-effects) · [Siri glow clone in SwiftUI](https://vp0.com/blogs/apple-intelligence-siri-overlay-clone-swiftui)
- [Mesh gradients in SwiftUI](https://www.donnywals.com/getting-started-with-mesh-gradients-on-ios-18/) · [Animated mesh gradient](https://www.createwithswift.com/creating-a-mesh-gradient-in-swiftui/)
- [Nicky Case: explorable explanations](https://blog.ncase.me/explorable-explanations) · [Data Stories with Nicky Case](https://datastori.es/103-explorable-explanations-with-nicky-case/)
- [Hooking viewers in the first 2 seconds](https://www.gofaceless.ai/blog/mastering-first-impressions-two-second-rule) · [Motion graphics for Shorts and Reels](https://hera.video/blog/motion-graphics-for-youtube-shorts-and-reels)
