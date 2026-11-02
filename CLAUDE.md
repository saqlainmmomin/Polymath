# Tell Me How

A phone-first shorts feed of tiny animated "how things work" topics whose one job is to make people curious (read `PRODUCT.md` first). It is an iOS app (SwiftUI) only: each topic's words are a JSON file, and its pictures are Swift drawing code.

**Words we use:** a topic comes in two versions. **Narrated** is the audio + animation version: one screen, a voice plays, the picture changes on each beat, captions light up (Shazam so far; code: `Narration`, `VoiceTopicView`). **Cards** is the version you read and swipe sideways through (`TopicView`).

| File | What |
|---|---|
| `PRODUCT.md` | Product goal: curiosity, effortless, broad appeal |
| `RECIPE.md` | How to write a topic (one big question, 1–6 cards) and its file format |
| `ios/Polymath/Topics/<id>.json` | One topic's words; every file in the folder is in the feed |
| `ios/Polymath/Pictures.swift` | Which picture each topic's card shows; pictures live in `Flat*.swift` |
| `ios/Polymath/VoiceTopicView.swift`, `tools/voice/` | Narrated topics: the player, and the offline voice renderer |
| `ios/README.md` | Run on the simulator or a phone |
| `tasks/todo.md`, `tasks/fix-log.md` | Plan, decisions, lessons |
| `tasks/handoff.md` | How to pick up work from another session |

**Build:** `cd ios && xcodegen generate` (after adding Swift files), then `./run.sh` (simulator) or `./run-device.sh` (phone).

**Gotchas**
- Every topic must define its own words. Topics arrive at random, so never rely on a sibling topic.
- Writers drift over ~30 words per card during fixes; trim.
- Copy is spine-first (`write-explainer` skill): facts sheet, then one paragraph the owner approves, then slides. Never paste fact-check wording into copy. Only a human new to the topic can judge clarity.
- Several sessions may edit at once: only touch your own topic's files (its JSON, its `Flat*.swift`, its lines in `Pictures.swift`).
- The web feed was removed on 2026-11-02 (it lives in git history before that). Never republish the testers' link (https://claude.ai/artifact/47dT3dkGhANEzEWf64UFhP) without the owner's OK.
- Git: `github.com/saqlainmmomin/Polymath` (`main`). `ios/Polymath.xcodeproj` and `ios/build/` are not committed.
