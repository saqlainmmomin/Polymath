# Topic recipe

How to turn "how does X work?" into a Tell Me How explainer. A topic is data (`topics/<id>.js`) rendered by shared blocks (`core/BLOCKS.md` lists them and their schemas). Build with `./build.sh <id>`.

## Who it's for
A curious adult with no engineering background, on a phone, for about 3 minutes. They should be able to explain the thing to a friend two days later.

## Shape (8 cards after the intro)
1. **intro**: "Ever wondered how/why …?" plus what they'll do.
2. **hook**: one surprising, true, concrete fact with a number. Ends in the question the topic answers.
3. **predict**: a guess about the core mechanism, before any explanation.
4. **sim**: the core idea as something they can drag or scrub. This card carries the topic.
5. **sequence / sim**: how it runs over time or step by step.
6. **predict + reveal**: the main "why" question, answered after the guess.
7. **sim / comparison**: what changes when you vary the key parameter.
8. **recall**: 3 questions, no new information.
9. **branches**: 4–5 rabbit holes.

Bend the shape when the topic needs it, but keep these: at least 2 predict-before-reveal moments, at least 2 hands-on visuals, a recall card, and branches. Add cards freely when foundations need their own cards or a card is too full (see the screen budget); clarity beats brevity.

## Start from zero
Before writing, list every idea the reader must already hold for the topic to make sense (for a gearbox: what twisting force is, that an engine has a comfortable speed range). Assume they hold none of them.
- **Why before how.** The reader must feel the problem before seeing the solution. Show what goes wrong without the thing ("with one gear, you either can't pull away or can't go fast") before explaining how it works.
- **Foundations get their own card.** A concept the topic depends on (torque, pressure, rpm) gets a short card with an everyday analogy the reader has felt in their body: a bicycle on a hill, a long spanner, pushing a door near the hinge.
- **No unexplained words.** Every technical word (torque, ratio, rpm, final drive, clutch) is either explained in plain words the first time it appears, or replaced with plain words. A word explained only in a later card counts as unexplained.
- **Arithmetic is shown, not stated.** Any calculation is broken into steps the reader can follow one at a time, each step tied to something they can picture ("the engine turns 3.6 times to turn the gearbox's output once"). If it can't be made obvious, cut it.
- **Prefer the reader's own experience.** Hook explanations to things people do: cycling, carrying shopping, riding a motorcycle, opening a jar.

## Screen budget (from tester feedback: screens felt cluttered)
More cards with less on each beats fewer, denser cards. Readers happily swipe more if each screen is clear. There is no card cap; 12–16 is fine.
- **Per card, at most:** a headline of about 8 words, 1–2 short sentences (about 30 words in total), one visual, one row of controls, two live readouts.
- **Labels on visuals:** only the ones the card's idea needs. No figure captions, tooth counts, "slow motion" notes or angle readouts unless they are the point of the card.
- **Split instead of squeezing.** If an interactive card needs a setup sentence, a visual, controls, readouts and a takeaway, make it two cards: one to see it, one to play with it.
- **The mental model is the payoff.** Put it on the card where the idea lands, and nowhere else. Never on a card that is already full.
- **Pace check:** each card should take 10–20 seconds. If a card takes longer, split it.

## Rules for every card
- One idea per card. If a card needs "also", split it.
- A teaching card ends with a **mental model**: one sentence they can repeat ("Gears trade speed for force").
- Plain words. Name a technical term only after the idea is clear, then use it consistently.
- Numbers are real and typical ("about 3,000 rpm"), never invented precision. Mark illustrative values as rough.
- Wrong options in a predict card are the misconceptions real people hold, not jokes.
- The correct option is not habitually the longest or in the same position; vary both.
- One name per part. Pick it, define it once, and never switch to a synonym.
- Recall questions test the mental models, phrased differently from the cards.
- No em-dash asides, no "not X, but Y", no stock phrases. Short, active sentences.

## Visuals
- Reuse an existing block whenever it fits. Add a new block only when the core mechanism can't be shown otherwise, and make it parametric (data in, no topic text hard-coded).
- Intro and hook always get an ambient visual; never leave visual:'none'.
- The visual must be the explanation, not decoration: moving it should show the cause and effect.
- Everything must fit a 375x667 screen at rest; check with the preview build.

## Quality bar before shipping
- **Newcomer review passed.** A separate reviewer who has not seen the topic reads only the card text, as someone who has never studied it, and lists every unexplained word, unexplained jump, and "why?" left hanging. Fix all of them before shipping.
- Every fact checked. Every mechanism shown matches reality (direction of rotation, ratios, timing).
- No console errors; no horizontal scroll; light and dark both readable.
- Branches link to existing topics with `href` where they exist.
