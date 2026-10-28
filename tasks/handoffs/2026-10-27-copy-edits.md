# Handoff: owner's copy edits to round four (Birthday, Seasons, Painkiller)

The owner reviewed `tasks/copy-review-round-four.html` and is angry about avoidable mistakes. Take these instructions literally. Do not improvise beyond them. Do not edit the repo's topic files (`topics/*.js`): this is copy review only.

## Where things are
- `tasks/copy-review-round-four.html`: the editable review page. The copy is the `const DATA=[...]` JSON line near the end of the file (ten topics). Copy it to `tasks/copy-review-round-five.html` and edit the DATA there; keep the page working (open it and check it loads; keep Download edited).
- `tasks/handoffs/round-four-data.json`: the same ten topics as plain JSON, for reading.
- `.claude/skills/write-explainer/SKILL.md`: the copy rules (read it first).
- `tasks/fact-check-round-one.md`: facts already checked. Do not reintroduce a flagged claim.
- The owner's own edited text for Birthday and Seasons is at the bottom of this file. It is the base: use it, not the older text in the page.

## Owner's instructions (verbatim meaning; do all of them)

### Birthday
1. **Name the topic: the birthday paradox.** Do not beat around the bush. Slide 1 must ask directly, in the plainest words, something like: *"In a room with 23 people, what do you think the chance is that two of them share a birthday?"* (The owner's words: "what is the probability in a room with 23 people ... what do you think the probability that two people share a birthday is".) The headline is that question (12 words or fewer if possible; if the sentence is longer, split it: headline = the question, setup/text = the framing). The answer lands on slide 1 or 2: just over 50%, about a coin flip. Mention the name "birthday paradox" once, plainly, as what it is called.
2. **Slide 4 headline "253 small chances make a coin flip" is meaningless to the owner.** Replace it with a plain statement that more pairs raises the probability, e.g. "More pairs means a higher chance of a match". The text under it must say the same simple thing in plain words, using "chance" or "probability" directly (the owner: "can't you just say increase the probability?"). Do not use "coin flip" in a headline.
3. Keep the owner's slide 2 wording ("Walk into a room of 22 strangers ...", "253 people") as written unless it conflicts with item 1.
4. Everything else in Birthday stays as the owner left it.

### Seasons
1. The owner changed the headline to **"Why is it summer when Earth is farthest from the Sun?"**. Keep it exactly.
2. **Slide 1's hook "So how much does the distance really change?" does not connect to slide 2, whose headline opens "Earth's distance from the Sun hardly changes".** Fix the chain: rewrite the slide 1 hook and the slide 2 headline/opening so the hook is a question that slide 2 plainly answers, with no decoding needed. Check that slide 2's own hook then leads naturally into slide 3 ("Earth leans to one side").
3. **Slide 5 headline "Higher sunlight warms more than slanted sunlight" is meaningless ("What is higher sunlight?").** Rewrite the headline and any matching text in plain concrete words the reader can picture (the torch on a table: a straight beam makes a small bright spot, a slanted beam spreads thin). Do not use the phrase "higher sunlight". Do not claim the Sun is "straight down" at ordinary latitudes (fact check: only true in the tropics). Keep the claim true.
4. Everything else in Seasons stays as the owner left it.

### Painkiller (from the owner's review of round four)
1. **Slide 4 says "Each cell has tiny machines, too small to see".** The owner: "no shit it's too small to see". Never state the obvious. Remove "too small to see" and rewrite the sentence so it only says what the machine does. Check the rest of the Painkiller deck, and only the Painkiller deck, for the same habit.
2. **The school fire-alarm analogy on slide 5 "doesn't stick".** Replace it. Propose 3 candidate analogies in your reply with one line each on why each works or fails, pick the best, and use it. It must: be picturable in one image; explain that the medicine switches the messenger machine off everywhere, but only the sore spot was making a lot of it, so only the sore spot feels the change; not claim the rest of the body does nothing (the machines do real jobs, e.g. in the stomach). Keep the slide's bold closing line.

## Rules for you
- Change only what is named above. If you notice the same problem elsewhere (stating the obvious, a hook that does not lead into the next slide's headline, a headline that needs decoding, an analogy that does not stick), do NOT change it: list it at the end of your reply as "also noticed" with slide and line, and let the owner decide.
- Follow SKILL.md: sentences about 8 to 18 words (none over 20), at most 7 per slide, hook answered by the very next slide, no bridges, no jargon, no defined everyday words.
- Each hook must be answered by the next slide's headline or opening. After editing, read each edited slide's hook next to the next slide's headline and confirm they connect.
- Update the "Check before building" notes for any new factual claim.
- Do not commit. Show the owner, in chat, a short before and after for each changed line (old text, new text), then link the round-five page. Be brief and do not explain at length.

## The owner's current Birthday and Seasons text (their edits, from their paste)

### Birthday
- Slide 1. Headline: "How many people do you need for two to share a birthday?" Setup: "Take a guess before you read on." Text: "Many people guess a big number, maybe half the days in a year. The real answer is just 23. At that size a room has the same chance of a shared birthday as a coin has of landing heads." Hook: "So why does 23 feel far too few?"
- Slide 2. Headline: "Matching your birthday is rare". Text: "Walk into a room of 22 strangers, and the odds someone shares your birthday are less than 6%. To get a 50-50 shot that someone matches you, you would need a room of 253 people." Hook: "So why do you only need 23? Because no one said the match has to include you."
- Slide 3. Headline: "Every pair of people is one chance". Text: "Any two people in the room could share a birthday, and every two people make a pair. Pairs pile up much faster than people do. A room of 23 people holds 253 pairs." Hook: "So how likely is it that one of those pairs matches?"
- Slide 4. Headline: "253 small chances make a coin flip". Text: "Each pair has only a 1 in 365 chance of matching, so almost every pair misses. But there are 253 pairs, and each one is a fresh try. Together they make a shared birthday about as likely as not." Hook: "So what happens when more people walk in?"
- Slide 5. Headline: "With 57 people, it's almost certain". Text: "57 people make 1,596 pairs. With that many chances, more than 99 rooms in 100 have a shared birthday." Bold: "Count the pairs, not the people."
- Go deeper (unchanged): about 29 February, uneven births, World Cup 2014 about half of squads.

### Seasons
- Slide 1. Headline: "Why is it summer when Earth is farthest from the Sun?" Setup: "The same Earth and the same Sun, all year." Text: "Summer feels like the Sun has moved closer. But in July, when Europe, India and the USA are in summer, Earth is at its farthest from the Sun." Hook: "So how much does the distance really change?"
- Slide 2. Headline: "Earth's distance from the Sun hardly changes". Text: "Earth travels around the Sun on a path that is almost a perfect circle. It's nearest in early January and farthest in early July, but only by about 3 percent. If the Sun were 100 steps away, that's about 3 steps more. And when Australia has summer, Canada has winter, at almost exactly the same distance." Hook: "So if distance isn't it, what is?"
- Slide 3. Headline: "Earth leans to one side". Text: "Earth doesn't stand straight up as it goes round the Sun. Like a classroom globe on its stand, it leans to one side by about 23 degrees. The north half has Europe, India and the USA, and the south half has Australia. Earth leans toward the same faraway spot all year." Hook: "So what does a lean do as Earth goes round the Sun?"
- Slide 4. Headline: "Earth's halves take turns leaning toward the Sun". Text: "Walk a globe in a circle round a lamp, always leaning toward the same faraway spot. At one place it leans toward the lamp, and on the opposite side it leans away. Earth does this around the Sun. So the north half leans toward the Sun in June and away in December, and the south half does the opposite." Hook: "But why would leaning toward the Sun make a place warmer?"
- Slide 5. Headline: "Higher sunlight warms more than slanted sunlight". Text: "Shine a torch straight down on a table and you get a small, bright circle. Tip the torch sideways and the same light stretches into a long, dim oval. The half of Earth leaning toward the Sun gets sunlight from higher in the sky, so it hits the ground more directly. The half leaning away gets slanted sunlight, spread thin over more ground, so it warms less." Hook: "And why are summer days so much longer than winter days?"
- Slide 6. Headline: "Leaning toward the Sun also makes days longer". Text: "Leaning toward the Sun keeps your half of Earth in the light for more hours of each spin. Leaning away keeps it in the dark for more. In London, a June day is about twice as long as a December day. Long days give the ground more hours of light to warm up." Bold: "Earth has seasons because it leans, not because it gets closer to the Sun."
- Go deeper (unchanged): North Pole six months, then twilight and dark.

(Picture ideas and labels for all slides: use the ones already in the round-four page, adjusted only where your wording changes make them wrong.)
