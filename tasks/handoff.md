# Handoff: add many more Tell Me How topics

You are continuing Tell Me How in `/Users/saqlainmomin/tell-me-how/` from a different Claude account. You cannot see the earlier conversation, so read these first, in order:
1. `PRODUCT.md`: the goal.
2. `RECIPE.md`: content rules.
3. `RECIPE.md` section 9 and `ios/Polymath/Topics/`: the topic file format, with real examples.
4. `tasks/session-log-2026-10-24.md`: decisions so far and why.
5. `tasks/fix-log.md`: the mistakes reviewers keep catching.

**Your job:** research and add many more topics across a broad range of subjects, not just cars. Every topic should leave someone curious for the next one.

## The goal, in one paragraph
Tell Me How exists to spark curiosity, organically. A reader should be fascinated and pulled forward with no effort, and come away wanting to know more. There should be something for everyone: your body, food, home, nature, phones, money, animals, cities, sport and music. It is entertainment first, never edtech: no scores, quizzes or lessons.

## Format (non-negotiable)
- **One idea per topic, 2–4 cards, then a `more` card.** Big subjects become a series of small topics linked via `more`.
- **The first card hooks on its own.** The headline is a surprise or a question, and the visual shows the idea at once. Topics arrive in random order.
- **Define every word inside the topic,** even if a sibling topic already did. This is the most common review finding.
- **Why before how.** Use the reader's own body and experience as the analogy (a door handle, a bike on a hill, a cup of ice).
- **Screen budget:** about an 8-word headline, at most 2 sentences / about 30 words per card, one visual, no captions. Trim after every fix round, because writers drift over.
- **Guess cards are optional,** at most one per topic. Wrong options must be real misconceptions. The right answer must not echo earlier wording and must not be the longest option.
- **Voice:** plain, warm, playful, like a smart friend. Short active sentences, real typical numbers, no em-dash asides, no "not X but Y".
- **The topic `title`** (shown big in the top bar) must read as a natural, curious hook, not a textbook heading.

## Production line per topic (use Sonnet subagents)
1. **Writer:** creates `ios/Polymath/Topics/<id>.json` following RECIPE.md (section 9 has the format), then its pictures in a new `ios/Polymath/Flat<Name>BP.swift`, wired in `Pictures.swift`.
2. **Newcomer reviewer, a separate agent:** reads ONLY the reader-visible text, cold, as an adult with no background. It lists unexplained words, jumps and hanging "why?"s, plus the one-sentence idea and a 1–5 "I get it" score.
3. **Fact checker, a separate agent:** checks every claim AND the picture geometry (directions, ratios, what's above or below a line).
4. **Fixes:** the writer applies the combined, prioritised fixes. You trim the word count.
5. **Phone check:** every card on the iPhone 17 simulator (`ios/run.sh <id> <card> out.png`) in light and dark. No overflow or overlap; look at the PNGs. Log what each review caught in `tasks/fix-log.md`.

## Pictures
- Every card's picture is Swift drawing code on blueprint paper: a `BlueprintStage` with a `draw` function (see `Blueprint.swift` for the paper, isometric helpers and line styles, `BPColors.swift` for the palette). `FlatGpsBP.swift` is a good model.
- **Colour must mean something.** Mustard is the one focal thing; other hues sparingly.
- A narrated topic also needs `voice-<id>.json` and `.m4a` in `Resources/`, rendered by `tools/voice/render.py`.

## Adding to the feed without clobbering parallel sessions
- Other sessions may be editing this folder at the same time. **Only create or edit your own topic's files** (its JSON, its `Flat*.swift`, its case in `Pictures.swift`). Don't edit shared Swift files, `RECIPE.md` or other topics unless the owner asks.
- A topic is in the feed as soon as its JSON is in `ios/Polymath/Topics/`. Run `cd ios && xcodegen generate` after adding Swift files.
- `more` links may only use ids that exist in `ios/Polymath/Topics/`. Link related topics across themes, since that is how curiosity travels.
- Set `theme` to one of `machines`, `nature`, `internet` or `money`, or add a new one (e.g. `body`, `food`, `home`, `animals`, `cities`, `sport`). The `more` fallback groups topics by theme.

## Verify and publish
- Simulator: `cd ios && ./run.sh [topic-id] [card] [out.png] [light|dark]`. Phone: `./run-device.sh` (see `ios/README.md`).
- The web feed and its preview links were removed on 2026-11-02; older notes that mention `topics/*.js`, `build.sh` or `core/` describe that removed version.
- **Never republish the testers' link** https://claude.ai/artifact/47dT3dkGhANEzEWf64UFhP without the owner's explicit OK in chat.

## Starting list (already done: engines, gears, ice-floats, sky-blue, gps, card-payment)
1. **Why you get goosebumps:** tiny muscles raise hairs your ancestors used to look bigger and stay warm. (body)
2. **Why your stomach rumbles when it's empty:** the gut keeps sweeping even with nothing in it. (body)
3. **Why onions make you cry:** cutting mixes two chemicals that make a gas aimed at your eyes. (food)
4. **How popcorn pops:** water trapped inside a hard shell turns to steam until the shell bursts. (food)
5. **How a microwave heats food:** it shakes water molecules millions of times a second. (home)
6. **How a fridge makes cold:** a liquid boils inside the fridge and carries the heat out the back. (home)
7. **Why the sea is salty:** rivers carry salt in, and only the water leaves. (nature)
8. **How lightning forms:** ice crashing about in a storm cloud builds up a huge charge. (nature)
9. **How your phone screen feels your finger:** your finger steals a little electric charge from a grid. (internet)
10. **How a photo gets to a friend's phone in a second:** it is chopped into small packets that each find their own way. (internet)
11. **Why prices end in .99:** your brain reads the left digit first. (money)
12. **How a cat always lands on its feet:** it twists its front and back halves separately in mid-air. (animals)
13. **How bees agree on a new home:** scouts dance, and the best site wins the most dancers. (animals)
14. **How traffic lights know you're waiting:** a loop of wire in the road feels the metal of your car. (cities)
15. **Why a curveball curves:** spin drags air round the ball and pushes it sideways. (sport)
16. **Why a guitar string makes a note:** it shakes a set number of times a second, and shorter means faster. (music)

## Setup note
This folder has **no git**. If your account runs on this same Mac, work in the folder directly. If it runs in the cloud, the folder must be shared first, e.g. by putting it in a git repo the owner pushes to GitHub. Ask the owner before doing that.
