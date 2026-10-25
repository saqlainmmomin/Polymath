# Topic recipe (v3)

How to turn a big everyday question into a Tell Me How topic. A topic is data (`topics/<id>.js`, start from `topics/_template.js`) rendered by shared blocks. Card and visual types: `core/BLOCKS.md`. Build and lint with `./build.sh <id>`; it warns when a topic breaks the rules marked (lint) below.

## Who it's for
A curious adult with no background, on a phone, swiping a feed like shorts. It sits between entertainment and education, closer to entertainment, and never feels like edtech: no quizzes, scores, lessons or homework tone. They should enjoy it and be able to explain the thing to a friend two days later.

## 1. Size: one big question, then stop
A topic answers ONE question people already half-have in their head ("How does a car engine work?"). The answer is the topic; the cards are its steps.
| Size | Content cards | Use for |
|---|---|---|
| Quick (`kind: 'bite'`) | 1-2 | One surprise, one picture (a single fact that clicks) |
| Standard (`kind: 'full'`) | 3-4 | Most topics |
| Big (`kind: 'full'`) | 5-6, the most | Flagship machines and systems |
Plus a `more` card at the end (lint: 1 to 6 content cards). Never more than 6: if it needs 7, it is two questions, so it is two topics, each with its own question title. Small pieces of a big machine are cards, not topics: nobody opens the app to learn "how a crank turns".
A foundation the idea needs is a card inside the topic, not a separate topic. Every topic still defines its own words (topics arrive in random order).

## 2. The title is the hook
The title is the topic's question, shown huge on card 1. It is the first thing read, so it carries the whole curiosity.
- **A full question a friend would ask out loud,** at most 12 words, ending in `?` (lint). "Why does ice float on water?" not "Why ice floats".
- **Give it a tension or a stake:** a paradox ("Why does ice float on the very water it came from?"), the reader themselves ("How does your phone know where you are?"), or a hidden moment ("What happens in the two seconds after you tap your card?").
- **Plain words only,** no jargon or brand names in the title. It must make sense to someone who has never studied the subject.
- **The title must be literally true.** Test the contrast you promise ("when almost everything sinks" was false: wood floats). Put the nuance in card 1 and keep the title safe.
- Test: would you tap it in a feed? Is the answer something the reader does not already know? If a friend would shrug, rewrite.

| Weak | Strong |
|---|---|
| Why ice floats | Why does ice float on the very water it came from? |
| How GPS knows where you are | How does your phone know exactly where you are? |
| Why the sky is blue | Why is the sky blue, but red at sunset? |
| Why an engine works in four strokes | How does a car engine actually work? |

## 3. Card anatomy (one system, every card)
Three zones, no dead space: **headline, then the short paragraph, then the picture** (owner, 2026-10-25: read the idea first, then watch it; the iOS app already does this). The picture takes whatever height is left. Spend the words on the idea, never on describing the interaction.
- **Card 1 (opener).** The topic question is the headline (33px). The card's own `title` is optional and becomes a smaller setup line under it (one line of stakes). The picture shows the mystery at once. The paragraph gives the first piece of the answer.
- **Cards 2-N.** `title` is the headline (about 8 words, 26px): a statement or question that tells the reader what to watch. `text` proves it in 1-2 short sentences. Optional bold `takeaway` on the card where the idea lands, nowhere else.
- **Thread:** the end of each paragraph raises the question the next headline answers. The reader should want the next card.
- Budget (lint, owner 2026-10-25): sentences of 15 words or fewer, at most 7 sentences per card, headline about 8 words, a visual on every card (bridges excepted). Short sentences beat a low word count.
- **Bridge (`type: 'bridge'`, owner 2026-10-25):** a text-only card, no headline or picture, set big. Use it where an idea needs closing in words before the next card builds on it (e.g. "one peak is common, a pair is specific" before the pairing card). About 35 words; it does not count toward the 6.
- The last content card lands the idea in one sentence a friend would repeat, then `more` offers where to go next.

## 4. Writing it so it doesn't put the reader off
**Use the `write-explainer` skill** (`.claude/skills/write-explainer/`): Simplified Technical English at about 80%, written for a 10-year-old, every slide standalone, every slide ending on a hook the next slide answers, picture labels in the text's words. The rules below still hold.
Most failures so far were textbook sentences and too much per card. Rewrite until these hold:
- **Open with something felt or seen,** never a definition. Not "Water is made of tiny pieces called molecules." but "Water's tiny building blocks slide past each other."
- **One idea per card.** If a card needs "also", split it or cut it.
- **Plain words first, term second.** Use a technical word only if the reader needs it again in this topic, and define it in the same sentence. At most one new term per card.
- **Short sentences:** 15 words at most, active voice, "you" and "your" freely. No semicolons, colon lists, brackets or em dashes. No "not X but Y".
- **One number per card,** rounded, with something to hold it against ("about a tenth bigger: a full glass of ice is a bit more than a glass of water").
- **Show, don't assert.** If the picture can show the cause, the text only points at it. Mechanisms asserted in words don't land.
- **Warm, a little playful, never smug.** Write like a smart friend, not a teacher. Read each card aloud; if you would never say it to a friend, rewrite it.
- **Don't repeat the headline** in the paragraph.
- **Start from zero:** list every idea the reader must already hold and assume they hold none. Why before how. Use their own experience (a bike on a hill, a long spanner, a door pushed near the hinge).

Before and after:
| Before | After |
|---|---|
| Water is made of tiny pieces called molecules. When it freezes, they lock into a pattern with gaps. | Water's tiny building blocks slide past each other. Freeze it and they lock in place, leaving gaps. |
| Thanks to those gaps, ice takes about 9% more room. So a cupful of ice weighs less than a cupful of water. | Those gaps make ice about a tenth bigger. So a glass of ice is lighter than a glass of water, and the water pushes it up. |

## 5. Interaction cue (automatic)
Visuals that can be touched (drag a crank or gear, scrub a slider, tap a count or a step dot) show a small dark pill on the picture's bottom edge, for example "Drag the crank". It fades in about 0.7s after the card appears, goes after a few seconds or on the first touch, and stays away for the rest of the session once the reader has used any visual by hand. Defaults are built in per visual; override with `tip: '<verb first, 4 words or fewer>'`, remove with `tip: false`. Design rule: the animation must still make sense untouched, and a card offers one thing to touch.

## 6. Guess cards
Optional, at most one per topic, only when it is the most fun way into the idea. The headline is the question; 2 or 3 real misconceptions as options, never jokes; the right answer does not echo the previous card's wording and is not the longest option; vary its position. `why` is 1-2 sentences. Unscored.

## 7. Visuals
- Every card has a visual from `core/BLOCKS.md`. `diagram` covers process steps, cycles, before/after, flows and labelled reveals; flagships may add a parametric custom type.
- Technical line art; colour carries meaning (blue water/air/data, heat orange fire, green OK/living, yellow only for sparks and energy, rust accent for the one moving or important part).
- The visual is the explanation, not decoration. Only the explaining part moves. Fill the panel: draw big, no empty bands.

## 8. Production line (the quality bar)
1. **Writer** follows this recipe from `_template.js`; build is lint-clean.
2. **Newcomer reviewer,** a separate agent: reads only the reader-visible text, cold. Lists unexplained words, jumps, hanging "why?"s, anything that sounds like a textbook; gives the one-sentence idea and a 1-5 "I get it" score.
3. **Fact checker,** a separate agent: every fact, number, mechanism and the diagram geometry (directions, ratios, above/below).
4. **Phone check** at 375x667, light and dark: nothing overflows or overlaps, no dead space, cue pill clear of labels, no console errors.
Fix every finding, trim words again, log fixes in `tasks/fix-log.md`. `more` links only use ids of existing topics.
