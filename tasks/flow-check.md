# Flow check, 2026-10-24 (11 topics)

How: built `./build.sh library`, then walked the shuffled feed like a user, twice (light and dark, 375x667): swipe sideways through every card, tap the first option on guess cards, swipe up to the next topic. Orders seen: card-payment > crank > why-gears > two-gears > spanner > cylinders > engine-push > ice-floats > sky-blue > gps > four-strokes, and card-payment > gps > four-strokes > cylinders > two-gears > ice-floats > why-gears > sky-blue > crank > engine-push > spanner. Zero console errors, no overflow, page dots correct on every card.

## What changed this round
- **Titles:** "Why a long spanner is easier" → "How a longer spanner beats a stuck bolt"; "Burning fuel pushes a piston" → "How burning fuel pushes an engine"; "Two gears trade speed for strength" → "How two gears swap speed for strength"; "Why an engine needs four strokes" → "Why an engine works in four strokes". The rest already read as hooks.
- **Layout:** the picture starts at half the card and the text sits right under it; spare height on taller phones is split between a bigger picture and air under the text, so nothing is glued to the bottom.
- **Page dots** at the bottom replace the `01 / 04` counter and the progress line: one dot per card, the current one a rust pill, and a nudging "Swipe →" on card 1.
- **3 new topics:** why the sky is blue (nature), how GPS knows where you are (internet), how a card payment goes through (money). Each 3 cards + more, all `diagram`, reviewed cold and fact-checked.

## How the feed flows
- **Variety:** better than before. Three new looks (light and air, satellites and circles, a money flow) break up the machine line art. Still 7 of 11 topics are machines, so a shuffle often gives 2–3 engine or gear topics in a row (seen: crank > why-gears > two-gears > spanner > cylinders). That run feels like a lesson series, not a feed.
- **Pacing:** even. Every topic is 2–3 cards + more, about a minute each. The new topics are 3 cards each; the engine ones 2–3. No topic drags.
- **Stands alone:** yes. Each topic defines its own words (piston, twist, hold, card network, waves). The flip side: in an engine run the same definitions repeat (crank, four-strokes and cylinders each explain the piston as a sliding plug).
- **Hooks:** the strongest first cards are surprises ("Tapping your card does not move any money", "Your phone only listens to GPS satellites", "Most things sink when they freeze. Ice floats."). The weakest are statements of mechanism ("One cylinder pushes in jerks", "An engine is picky about its speed").
- **Go deeper:** the new topics now link each other (GPS ↔ card payment, sky ↔ ice), so a viewer doesn't fall back onto the engine trio from a money topic.

## Worth deciding next
1. **Space out series in the shuffle** (no two topics from the same series back to back). Small change in `core/library.js`; fixes the engine-run feel.
2. **Two kinds of dots:** diagrams have their own small step dots at the panel's top-left, and the page dots now sit at the bottom. They look different (open circles vs pills) and sat fine in testing, but watch for a tester reading the panel dots as pages.
3. **Weak visual:** the card-payment timeline (card 3) is a thin strip in a big panel.
4. **Balance themes** as the feed grows toward 20: the next topics should mostly be nature, internet and money.
