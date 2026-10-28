# Rules audit: the 8 pre-spine topics (2026-10-27)

Audit of the reader-facing copy in `topics/<id>.js` against `write-explainer` v2 (rules 1–10), `RECIPE.md` §2–4 and the owner-taste memory notes. Nothing was rewritten. Superglue (`topics/superglue.js`, `tasks/trial-glue/slides.md`) is the yardstick: 4 cards, about 20–40 words of text each, one `hook` field per card that asks the question the next headline answers.

## Ranked: most work first

| # | Topic | Verdict | Main reasons |
|---|---|---|---|
| 1 | shazam | Full redo | Staccato voice throughout (runs of 4 and 6 short sentences); picture/chart/dots/points/peaks for one thing; key idea lives in a bridge; brand in title; `more` links to retired `ice-floats` |
| 2 | car-engine | Full redo + new title | Textbook title; slide 1 gives the answer; no hooks on cards 3–5; six names for the bang; two analogies; colon lists; "Tap 4." |
| 3 | moon-tides | Full redo + new title | Textbook title that names the answer; three questions in one topic plus a bridge; slide 1 states the obvious; bold line brings in wind and waves |
| 4 | bike-gears | Full redo (keep slide 1) | Order is sound, but cards 2–4 are 80–89 words and card 3 is arithmetic; three sentences over 20; textbook title |
| 5 | card-payment | Line fixes + owner call on card 3 | Spine connects; card 3 is a link-counting detour with four numbers; held/set aside drift; "Weekends don't count." |
| 6 | gps | Line fixes + one cut | Spine connects; two analogies (storm, friend-on-a-ring); "GPS" acronym; satellite defined; "Usually" hedge |
| 7 | feel-wet | Line fixes | Spine connects; "sensors" defined three times; slide 1 says the surprise three times; touch/press drift; "usually" hedges |
| 8 | sky-blue | Line fixes | Closest to passing; red/orange drift; "too small to see"; gases/particles; colon bold line |

**Patterns across all 8**
- Six of eight have no `hook` field: the closing question sits in `text`, so it renders as body copy, not the hook style superglue uses (only feel-wet and shazam use `hook`).
- Four titles are textbook "how does X work" questions (car-engine, bike-gears, moon-tides, shazam).
- Most hooks that fail don't fail on keywords — they *announce* the next headline ("But Earth actually has two bulges.") instead of asking the question it answers.
- Cards average 50–80 words against superglue's 20–40. Length lint passes because sentences are short, not because cards are.
- Two bridges remain (shazam c5, moon-tides c5); both are off-by-default under the new rules.

## How to read this
- **Spine** is title → hook → headline → … → bold line. Where a topic has no `hook` field, the closing line of `text` is used as the hook and marked _(in text)_.
- **⚠ link** = the hook and the next headline share no key word, or the hook gives the headline away.
- Rule numbers are the 10 meaning rules in `.claude/skills/write-explainer/SKILL.md`. "RECIPE" means `RECIPE.md` §2–4.
- **Length:** `./build.sh <id>` was run per topic. Its 15-word warning is stale, so the counts below use the real limit (8–18 words, none over 20). "Short run" = sentences in a row under 7 words; the voice note says never three.

---

## 1. car-engine — **Verdict: full spine-first redo, new title**

**Spine**
1. Title: How does a car engine actually work?
2. Setup: Tiny controlled explosions, one after another.
3. Hook 1 _(in text)_: A wheel needs spin, not a push.
4. Headline 2: A bent shaft turns the shove into a spin
5. Hook 2 _(in text)_: What brings the piston back up?
6. Headline 3: One bang takes four strokes, two full turns ⚠ link
7. Hook 3: _none_
8. Headline 4: Why squeeze the fuel before lighting it? ⚠ link
9. Hook 4: _none_
10. Headline 5: So engines use several cylinders, taking turns ⚠ link
11. Bold: More cylinders, smoother push.

Read aloud, this is five facts about engines, not one answer. Cards 3→4→5 have no hooks, and card 4 (compression) is a side question.

**Findings**
- Title "How does a car engine actually work?" is the textbook "how X works" framing the owner passes over (topic-question taste). No twist, nothing about the reader.
- Rule 8: the setup "Tiny controlled explosions, one after another." gives the answer on slide 1, and the text goes on to explain the mechanism and name two parts.
- Rule 6 / RECIPE: two terms defined in brackets-by-comma on slide 1: "a tube, the cylinder", "a sliding plug, the piston". Card 2 adds "a bent shaft, the crankshaft", which is never used again (card 3 says "the shaft").
- Rule 4: one event has six names: "explosions" (setup), "lit" (c1), "Fire" (c1 label), "shove" (H2), "bang" (c3, c5), "burn" (c4). Push/shove/punch also drift.
- Rule 5: two analogies: "like a foot on a bike pedal" (c2) and "the bang hits like a punch, not a nudge" (c4).
- RECIPE "No 'not X but Y'": "A wheel needs spin, not a push." (c1); "a punch, not a nudge" (c4).
- RECIPE no colon lists / semicolons: "Each trip up or down is a stroke: suck in, squeeze, bang, blow out." and "Only the bang pushes; the shaft's spin carries the piston through the rest." (c3).
- Rule 2: H3 "One bang takes four strokes, two full turns" does not decode cold: "bang" and "stroke" are undefined at the headline, and it carries two numbers.
- ⚠ link c2→c3: the hook "What brings the piston back up?" is answered only in c3's last sentence; the headline is about counting strokes.
- Rule 7: "Four half-turns make two turns." (c3) and "One cylinder bangs once per two turns… Four share those two turns, one bang every half turn" (c5) leave the reader doing sums, with 3–4 numbers per slide.
- Rule 6: "pressure" (c4) is undefined.
- Rule 10: "Tap 4." (c5) describes the interaction, not the idea.
- ⚠ link c4→c5: H5 opens with "So" but nothing on c4 leads to cylinders.
- Bold "More cylinders, smoother push." is not the line a friend would repeat about the title question; it answers only card 5.
- Voice (rule 1): textbook definitions, no "you", no "but/so" joins on slides 1–3.
- Picture labels: c1 "Fuel + air", "Fire", "Hot gas" — "+" sign, and "Fire" is not a word the text uses.

**Length:** lint clean at the real limit; c4 "After the burn, that gas is under far more pressure, so the bang hits like a punch, not a nudge." is 20 words (at the cap). Cards are 26–32 words, which is fine; the problem is structure, not length.

**Bridges:** none.

**If the owner wants line fixes anyway:** none worth doing in isolation. The title, the slide-1 spoiler, the missing hooks and the side card all need the paragraph stage.

---

## 2. bike-gears — **Verdict: full spine-first redo (keep slide 1's voice)**

**Spine**
1. Title: How do the gears on your bike work?
2. Setup: Same hill, same legs.
3. Hook 1 _(in text)_: So what does the gear lever change? To find out, look at the back wheel.
4. Headline 2: The back wheel has a stack of rings
5. Hook 2 _(in text)_: So why does the size of the back ring change how the pedals feel?
6. Headline 3: A smaller back ring spins the wheel more ⚠ link
7. Hook 3 _(in text)_: So what does a wheel that spins less, or more, do to your legs?
8. Headline 4: Short steps are easier uphill ⚠ link
9. Hook 4 _(in text)_: So how do you choose?
10. Headline 5: Pick the gear that fits the road
11. Bold: Low gear number: easy push, slow ride. High gear number: hard push, fast ride.

The story order is sound (rings → wheel turns → effort → choosing). What fails is density: cards 2–4 are 80–89 words with 6–7 sentences, three times superglue's size, and card 3 is a page of arithmetic.

**Findings**
- Title "How do the gears on your bike work?" is the textbook "how X works" framing (topic-question taste). Slide 1's own tension ("same hill, same legs… so what does the gear lever change?") is the better question.
- Slide 1 is good: joined sentences, "aren't stronger… isn't flatter", no spoiler. But "To find out, look at the back wheel." is a stage direction after the hook (rule 10), and the first sentence is 23 words (over 20).
- RECIPE "don't repeat the headline": H2 "The back wheel has a stack of rings" → text opens "A geared bike has a stack of rings on its back wheel."
- Rule 2/⚠ link c2→c3: the hook asks how the pedals *feel*; H3 answers how much the *wheel spins*. The feel is only answered on card 4.
- Rule 7 (card 3): "Say the pedal ring has 30 teeth. One pedal turn pulls 30 links past. In gear 1, the back ring has 30 teeth… In gear 7, the back ring has only 10 teeth. 10 fits into 30 three times" — five numbers and a sum the reader must follow.
- Rule 7 (card 2): "Say the bike has 7 gears. Gear 1 uses the biggest back ring, and gear 7 uses the smallest." — gear numbers start piling up here.
- ⚠ link c3→c4: hook "…do to your legs?" → H4 "Short steps are easier uphill" shares no word; "steps" arrives before the stairs analogy that explains it. Read cold, H4 says nothing about bikes (rule 2).
- Rule 5: one analogy (stairs, c4) — fine. But c4 also adds "A hill works the same way: you must lift yourself to the top either way" (colon, RECIPE).
- Rule 4: "change gear" (c1) vs "shift" (c5, "Riders shift often"); "pedal ring" (text) vs "Front" (web picture labels); "choose" (hook 4) vs "Pick" (H5) is fine.
- Rule 3: c5 "On a steep hill, use gear 1, so each push stays light." restates card 4.
- Bold line is two colon fragments (RECIPE colon rule) and introduces "low/high gear number", a new frame; it's a summary table, not a line a friend would say.
- Picture labels (rule 10): web labels "Front: 3 turns", "Back: 1 turn", "One gear: hard push, crawling", "Other gear: light push, keeps climbing" don't use the text's words ("pedal ring", "gear 1", "gear 7"). The iOS `FlatBike.swift` labels mostly do ("PEDAL RING", "BACK RING: 30 TEETH"), but "FLAT ROAD: GEAR 4" names a gear the text never mentions ("a higher gear").

**Length (real limit):** 4 sentences over 18, three over 20 — c1 "On a steep hill, you push as hard as you can and barely move, but change gear and the same hill feels easy." (23), c4 "In gear 1, each pedal turn moves you a short way, so you pedal more turns with a light push each." (21), c5 "On flat ground, nothing pulls you back, so a light push already works and a higher gear lets each turn carry you further." (23); c4 "In gear 7…3 times harder." (19). Card 2 and 3 hit the 7-sentence cap.

**Bridges:** none.

**Why redo, not fixes:** cutting cards 2–4 to superglue size means choosing which ideas and numbers survive, which is a paragraph-stage decision. Keep slide 1's voice as the starting point.

---

## 3. feel-wet — **Verdict: line fixes**

**Spine**
1. Title: How do you know something is wet?
2. Setup: You have no sense for wet. Your brain works it out.
3. Hook 1: So what are you really feeling?
4. Headline 2: First, you feel your skin cool down
5. Hook 2: But cooling alone does not always say "wet". Your brain also checks how the thing touches you.
6. Headline 3: Then you feel how it touches your skin ⚠ link (hook gives it away)
7. Hook 3: But that is only a guess, and you can fool it.
8. Headline 4: You can feel wet when nothing is wet ⚠ link (weak: "fool" not in headline)
9. Bold: You can't actually feel wet. Your brain guesses it from cold and touch.

The spine tells one story (no sensor → cooling → touch → fooled) and reads well aloud. Problems are padding and repeated definitions inside cards.

**Findings**
- Rule 8 (borderline): the setup's second sentence "Your brain works it out." previews the answer. "You have no sense for wet." alone is the surprise.
- Rule 3: slide 1 says the surprise three times: setup "You have no sense for wet", text "Your skin cannot sense wet at all", then "None of them senses wet."
- Rule 6/3: "sensors" is defined three times: c1 "tiny nerve endings, called sensors", c2 "Your skin has tiny nerve endings, called sensors, that notice cold", c3 "Touch sensors, tiny nerve endings". Define once on c1.
- Hook 2 states H3 instead of asking it: "Your brain also checks how the thing touches you." → "Then you feel how it touches your skin". Also two sentences, and "does not always say 'wet'" is a hedge.
- Rule 4: c3 "gently and evenly" / "a soft, even touch" vs c4 "that soft, even press"; "cool"/"cooling" (c2–c4) vs "cold" in the bold line.
- Hedges (fact-check wording as copy): c2 "Water is usually cooler than your skin"; c3 "Together, they usually mean a liquid."
- Short runs: c1 and c3 have two short sentences in a row ("It moves and fits every bump of your skin.", "So your brain decides: 'wet'."). Not over the three limit, but c3 is 7 sentences, 67 words.
- Picture label c3 "Cooling + touch = 'wet'" uses symbols; text says "fast cooling and a soft, even touch".
- Bold line repeats the setup almost word for word. That's a fair landing, but with the setup trimmed it lands harder.

**Length:** lint clean, nothing over 18.

**Bridges:** none.

**Line fixes**
1. Setup → "You have no sense for wet." (drop "Your brain works it out.")
2. c1: cut "Your skin cannot sense wet at all." or "None of them senses wet." — keep one.
3. c2: "Your skin has tiny nerve endings, called sensors, that notice cold." → "Your cold sensors feel your skin cool down fast…"; c3: "Touch sensors, tiny nerve endings, feel…" → "Your touch sensors feel…".
4. Hook 2 → one question that uses "touches", e.g. "So what else does your brain check?" — let H3 say "touch".
5. Pick one of "touch"/"press" and use it in c3, c4 and the bold line.
6. Drop "usually" in c2 and c3 unless the facts sheet needs it; if it does, rewrite as a plain true sentence.
7. c3 label: "Cooling + touch = 'wet'" → "Cooling and touch: wet".

---

## 4. sky-blue — **Verdict: line fixes (closest to passing)**

**Spine**
1. Title: Why is the sky blue at noon and red at sunset?
2. Setup: It's the same sky and the same Sun.
3. Hook 1 _(in text)_: So how does clear air turn sunlight into a blue sky, and later an orange one?
4. Headline 2: Sunlight is every colour at once
5. Hook 2 _(in text)_: So what does the air do to these waves?
6. Headline 3: Clear air still bounces blue light
7. Hook 3 _(in text)_: So where does all that bounced blue go?
8. Headline 4: Bounced blue comes at you from everywhere
9. Hook 4 _(in text)_: So why does that blue sky turn orange at sunset?
10. Headline 5: At sunset, light crosses far more air
11. Bold: Short trip: blue sky; long trip: red sunset.

Every hook shares a key word with the next headline. Slide 1 is the owner's own voice bar.

**Findings**
- Rule 4: the sunset colour changes name: title "red", hook 1 and hook 4 "orange", c5 "mostly red and orange", bold "red sunset". Pick one (the title's "red") and keep it.
- Rule 3 — the owner's own named example of stating the obvious: c3 "The gases are tiny particles, too small to see." (Compare "tiny machines, too small to see".)
- Rule 4: c3 "it's made of gases. The gases are tiny particles" then "particles" for the rest of the topic; label "Gas particles". Say "particles" once and stay there. ("gases are tiny particles" is also loose as a fact.)
- RECIPE "don't repeat the headline": H2 "Sunlight is every colour at once" → c2 "a rainbow shows what is hiding in sunlight: every colour, mixed together." The rainbow is good; the colon restatement is not needed.
- Rule 3/7: c3 "Short blue waves bounce much more often than long red ones: about 5 times as much." says the comparison twice ("much more often", "5 times") and uses a colon.
- c5 is 69 words; "Air is a thin layer around Earth." and "When the Sun is overhead, its light takes a short path down through the layer." are needed, but "At sunset, the Sun is near the horizon, so its light must cross the layer sideways." could merge with "That is a much longer trip".
- Bold "Short trip: blue sky; long trip: red sunset." uses colons and a semicolon (RECIPE). The idea is right.
- Picture labels (iOS `FlatSky.swift`): "SPLIT INTO COLOURS" — the text never says "split" (it says "every colour, mixed together"); "AIR PARTICLES (DRAWN MUCH BIGGER)" vs text "particles" is fine.
- Not a reader issue: `FlatSky.swift` and `FlatPay.swift` header comments still carry old titles. Comments only.

**Length (real limit):** only c5 "On the way, the particles bounce away most of the blue, so mostly red and orange reaches your eyes." at 19 words. No sentence over 20. All hooks are the last line of `text`, not a `hook` field — it renders as body text rather than the hook style superglue uses.

**Bridges:** none.

**Line fixes**
1. Use "red" everywhere the sunset colour is named (hook 1, hook 4, c5).
2. c3: cut "too small to see"; replace "it's made of gases. The gases are tiny particles" with one plain sentence that uses "particles".
3. c3: "Short blue waves bounce about 5 times as often as long red ones." (one number, no colon).
4. c2: drop the restating clause after "rainbow"; let the rainbow show it.
5. Bold → a sentence, e.g. "A short trip through air gives a blue sky, and a long one gives a red sunset."
6. Optional: move closing questions into `hook` fields so they render like superglue's.
7. Picture: "SPLIT INTO COLOURS" → "EVERY COLOUR" (text's words).

---

## 5. gps — **Verdict: line fixes, plus one cut (the second analogy)**

**Spine**
1. Title: How does your phone know exactly where you are?
2. Setup: It finds you within a few metres, anywhere on Earth.
3. Hook 1 _(in text)_: So what is it listening to?
4. Headline 2: Satellites keep calling out the time
5. Hook 2 _(in text)_: How can a time tell your phone how far away something is? A storm shows you.
6. Headline 3: A storm turns a delay into a distance
7. Hook 3 _(in text)_: GPS uses the same trick, but with a signal that travels much faster.
8. Headline 4: The satellite signal works like a very fast thunderclap
9. Hook 4 _(in text)_: But knowing a distance is not the same as knowing a place.
10. Headline 5: One distance gives a ring of places
11. Hook 5 _(in text)_: So how does your phone pick the one right place on the ring?
12. Headline 6: More satellites give one place
13. Bold: That place is you.

The spine connects at every step and the bold line is a good friend line. It uses all 6 cards, two of them on the storm.

**Findings**
- Rule 9 (minor): the title says "exactly" and the setup says "within a few metres". Literally, a few metres isn't exact. Either drop "exactly" or accept it as everyday speech.
- Rule 6: "GPS" is an acronym, used in c2 ("About 30 GPS satellites"), c3 and c5, never spelled out or needed.
- Rule 6: c2 "A satellite is a machine that orbits our planet." defines an everyday word, and "orbits" is a synonym for the "circle Earth" of the sentence before (rule 4).
- Rule 3: c1 "Open a map on your phone. A blue dot shows where you stand." states what every reader already sees; the surprise is "Your phone never sends a message to space to find you."
- Rule 5: two analogies: the storm (c3–c4) and the friend on a ring around the school (c5: "A friend says, 'I am 1 kilometre from the school.'"). The ring picture works on its own.
- Rule 4: c3 "lightning" / "flash", "thunder" / "boom" / "sound", then H4 "thunderclap". One word each.
- Rule 2: H4 "The satellite signal works like a very fast thunderclap" restates the analogy rather than the idea (time gap = distance), which c3's headline already said.
- Rule 7 (pictures): c4 label "About 20,200 km" plus "Sent 0.00 s" / "Lands 0.07 s" — the text has one number (0.07 s), the picture adds two. iOS label "REAL PHONES USE 4 OR MORE" (c6) adds a number the text never mentions.
- Hedge: c6 "Usually, only one of the two crossing places is on it." Rewrite as a plain true sentence.
- Voice (rule 1): c1 and c3 run short: "It only listens." / "So you hear it later." — two-in-a-row, under the limit, but the cards read as lists. c3 is 7 sentences.
- Rule 10: c5 "Look at a map from above." is a stage direction to the picture.
- Picture labels: text says "what time it left… what time it arrived"; iOS says "TIME SENT 0.00 s" / "TIME ARRIVED 0.07 s" — "left" vs "sent". Pick one.

**Length:** nothing over 20; c2 and c5 quotes push two sentence-pairs close. Lint clean.

**Bridges:** none.

**Line fixes**
1. c2: cut "A satellite is a machine that orbits our planet."; replace "GPS satellites" with "satellites" throughout (c2, c3 "GPS uses the same trick", c5 "GPS has the same problem" → "Your phone has the same problem").
2. c1: cut "Open a map on your phone. A blue dot shows where you stand." or fold to one sentence.
3. c3: pick "flash" and "thunder" and keep them; H4 → a headline about the idea, e.g. "The signal's delay tells your phone the distance".
4. c5: cut the friend and school; let the ring picture carry it ("One satellite gives one distance, and that distance could be anywhere on a ring.") — this is the one structural cut; show the owner the new spine.
5. c6: drop "Usually".
6. c4 picture: drop "About 20,200 km"; use "left"/"arrived" or "sent"/"arrived" in both text and labels.
7. Optional: title without "exactly".

---

## 6. card-payment — **Verdict: line fixes, and the owner decides on card 3 (cutting it is a paragraph-stage change)**

**Spine**
1. Title: How does a card tap move your money to a shop?
2. Setup: You tap, it beeps, and you walk away.
3. Hook 1 _(in text)_: So how does that message find your bank and come back with a yes?
4. Headline 2: The message travels through four places
5. Hook 2 _(in text)_: So why doesn't the shop's bank just ask your bank itself?
6. Headline 3: One network saves banks from linking to each other
7. Hook 3 _(in text)_: At last the message reaches the bank that knows your account, so what does it do?
8. Headline 4: Your bank checks two things, then sets money aside
9. Hook 4 _(in text)_: So when does the shop get paid?
10. Headline 5: The shop gets its money later, all at once
11. Bold: The tap is a yes today; the money follows later.

Hooks and headlines connect. Slide 1's twist ("feels like paying, but the money doesn't move yet") is the right kind. Card 3 is a detour: it answers "why a network?" with link counting, which the title question doesn't need.

**Findings**
- Rule 7 (card 3): "Picture 10 banks… Joining every pair needs 45 links… each bank needs only one link to it: 10 in all. Real life has thousands of banks" — four numbers and a sum (45) the reader has to take on trust.
- Rule 6: c3 "A link is a line a message can travel along." defines an everyday word.
- Rule 2: H2 "The message travels through four places" — "four places" is a count the reader can't picture until the text lists them. H3 "One network saves banks from linking to each other" decodes only after c2.
- Rule 4: c4 headline "sets money aside", text "sets the price aside", picture "Held for the shop". c3 hook "the bank that knows your account" for "your bank".
- Rule 7 (c4): "Say you pay 20 from 50: you can spend only 30." — three numbers, no unit; colon. (c5 picture adds "About 2 sec" and "1 to 3 working days" — two numbers on one slide.)
- Rule 3: c5 "Weekends don't count." is a fact-check caveat pasted as copy (the iOS label "WEEKENDS DON'T COUNT" repeats it).
- Rule 6: c1 "The card reader, the machine you tap on," defines a thing the reader just tapped. c2 "a card network, a company such as Visa that connects banks" is a needed definition — keep.
- RECIPE colon/semicolon: c1 "asking your bank: can this card pay?"; c3 "only one link to it: 10 in all"; c4 "checks two things: is the card real…"; bold "The tap is a yes today; the money follows later."
- Rule 9 (minor): the title says the tap "moves your money", slide 1 says it doesn't yet. That's a fair twist (the money does move, later), not a false premise. Keep.
- Picture labels: iOS "MESSAGE OUT", "ANSWER BACK", "PAYMENTS ADDED UP" match the text well.

**Length (real limit):** two sentences at 20 words — c1 "The card reader, the machine you tap on, only sends a short message asking your bank: can this card pay?" and c4 "A computer at your bank checks two things: is the card real, and is there enough money in your account?". None over 20. c2–c4 are 63–73 words.

**Bridges:** none.

**Line fixes**
1. c1: cut ", the machine you tap on,"; turn "asking your bank: can this card pay?" into "asking your bank if this card can pay."
2. c4: one word for setting money aside ("holds" or "sets aside") in headline, text and picture.
3. c4: "Say you pay 20 from 50: you can spend only 30." → one number, e.g. "Pay 20 pounds and that 20 is held, so you can't spend it twice."
4. c5: cut "Weekends don't count." and the matching label.
5. Bold → one sentence without a semicolon, e.g. "The tap gets a yes today, and the money follows later."
6. Card 3 (owner's call): either cut it and let c2's hook go straight to "your bank checks two things", or keep one number ("one network instead of thousands of links between banks"). Cutting is structural, so show the owner the new spine.

---

## 7. shazam — **Verdict: full spine-first redo**

**Spine**
1. Title: How does Shazam know what song is playing?
2. Setup: Any song. Out of millions. In a few seconds.
3. Hook 1: How? First, Shazam turns the sound into a picture.
4. Headline 2: Shazam turns sound into a chart ⚠ link (hook gives it away; "picture" ≠ "chart")
5. Hook 2: So what does your noisy café look like on this chart?
6. Headline 3: Your café becomes a chart too
7. Hook 3: Shazam cannot keep all those dots.
8. Headline 4: Shazam keeps only the loudest points ⚠ link ("dots" → "points")
9. Hook 4: But one peak alone does not tell Shazam much.
10. _Bridge:_ One peak is just one note at one moment… Hook: So Shazam uses pairs of peaks.
11. Headline 6: Two peaks make a code
12. Hook 6: Now Shazam must find the song that has your codes.
13. Headline 7: Shazam looks up each code, like a book's index
14. Bold: Shazam never hears the whole song, only pairs of loud notes.

Most hooks are statements that announce the next headline rather than questions it answers. The voice is the staccato the owner rejected on sky-blue.

**Findings**
- Rule 1 / voice note ("never a run of three sentences under 7 words"): c1 has a run of 4 ("You are in a noisy café. People talk. Cups clink. Music plays somewhere."); c2 a run of 6 ("Time goes from left to right. High notes go near the top. Low notes go near the bottom. This height is called frequency. A loud note shows bright. A quiet note shows dim."); c3 and c4 runs of 3. The setup "Any song. Out of millions. In a few seconds." is three fragments.
- RECIPE §2: brand name in the title ("Shazam"). The "How does it know?" framing fits owner taste; the brand doesn't fit the title rule.
- Rule 4: the same thing has four names: "picture" (hook 1) → "chart" (H2–c3) → "dots" (c3, hook 3) → "points" (H4) → "peaks" (c4 on). Also "index" (H7) vs "list" (c7 "Shazam's list shows every song").
- Rule 6: "frequency" (c2) is defined and never used in text again. The bridge adds "Hz" — an acronym, defined after use ("Picture a 1,200 Hz note… Hz measures how high a note is").
- Rule 7: the bridge has three numbers in one sentence ("a 1,200 Hz note, then a 2,400 Hz note exactly 0.3 seconds later"). c6 "three numbers… The first two numbers… The third number… three numbers" counts at the reader.
- Rule 3: c4 "That is too slow, even for a computer."; c7 "That takes days." (unsourced claim, iOS repeats "THIS TAKES DAYS").
- Rule 8: hook 1 tells slide 2's answer ("First, Shazam turns the sound into a picture").
- Bold line: "pairs of loud notes" — the topic called them "peaks"; "never hears the whole song" is ambiguous (it hears your clip, and it does store whole songs).
- Picture labels (iOS `FlatShazam.swift`): "A MINOR", "B MINOR", "C MAJOR" (music jargon, never in text), "FREQUENCY ↑", "TIME →", "CHECKED … OF 50,000,000…" (a number the text never gives), "PLAY THE CAFÉ", "TAP A NOTE OR CHORD", "SHOW MORE PAIRS" (interaction, rule 10). Several screens have more labels than the card has sentences.
- Broken link: the `more` card links to `ice-floats`, which was retired in bb08768 (`topics/ice-floats.js` no longer exists). RECIPE §8: "`more` links only use ids of existing topics."
- Size: 6 content cards plus a bridge, 36–57 words each, all at or near the 7-sentence cap.

**Length:** nothing over 18 words; the failure is the opposite (too many sentences under 7).

**Bridges:** c5 is a bridge, now off by default. Its content (one peak is common, a pair is rare) is the heart of the answer, so it belongs in the paragraph, not in a bridge.

**Why redo:** the voice, the synonym chain and the bridge-as-key-idea all need a new paragraph. Quick fix that can't wait: change the `more` link from `ice-floats` to an existing id.

---

## 8. moon-tides — **Verdict: full spine-first redo, new title**

**Spine**
1. Title: How does the Moon move the oceans?
2. Setup: Twice a day, the sea comes in and goes out again.
3. Hook 1 _(in text)_: The cause is about 384,000 kilometres away, up in the sky.
4. Headline 2: The Moon pulls on the ocean
5. Hook 2 _(in text)_: But Earth actually has two bulges.
6. Headline 3: The ocean bulges on both sides ⚠ link (hook gives it away)
7. Hook 3 _(in text)_: Next, Earth spins underneath these two bulges.
8. Headline 4: Earth spins through both bulges every day ⚠ link (hook gives it away)
9. Hook 4 _(in text)_: But some days, the high tides are much higher. Something else is pulling too.
10. _Bridge:_ The Moon also moves along its path… high tide comes about 50 minutes later every day… The Moon is not the only thing in the sky that pulls on the sea. ⚠ link (hook 4 promises "something else"; the bridge answers a different question first)
11. Headline 6: The Sun pulls on the oceans too
12. Hook 6 _(in text)_: Even so, the bulge is small out at sea. So why do some beaches get giant tides?
13. Headline 7: The shape of the coast makes tides bigger
14. Bold: Wind makes waves. The Moon lifts the whole ocean, twice a day.

Three questions share one topic (why two bulges, why spring tides, why giant tides in some bays), plus a bridge about the 50-minute delay. Several hooks announce rather than ask.

**Findings**
- Title "How does the Moon move the oceans?" is the plain mechanism framing the owner passed over (topic-question taste). It also names the answer (the Moon), so slide 1's "The cause is… up in the sky" withholds something the title already said.
- Rule 3: the setup "Twice a day, the sea comes in and goes out again." and c1 "Stand on a beach… The water slowly creeps up the sand. Later, it slowly slides back down." state what the reader knows; "slowly" twice.
- Rule 6: c1 "This rise and fall is called the tide." defines an everyday word; c2 "this pull is called gravity" likewise.
- Rule 9 / literal truth: c1 "It happens on every coast on Earth." Some coasts have almost no tide; needs a plain true sentence from a facts sheet.
- Rule 7: c1 "about 384,000 kilometres away" has nothing familiar to hold it against.
- Rule 4: "sea" (setup, bridge), "ocean" (H2, c2), "oceans" (title, H6), "water" (c2–c4); "spins" (H4) vs "turns around" (c4).
- Rule 3/6: c6 "These are called spring tides, and they have nothing to do with the season." — a term the topic never uses again, plus a disclaimer for it.
- Bold: "Wind makes waves." introduces wind and waves for the first time in the topic. "The Moon lifts the whole ocean" contradicts c2's "the ocean slides a little toward the Moon".
- Fact consistency: c2 "Rock is stiff, so it hardly moves." vs the `more` note "the ground under your feet rises and falls by up to about 30 centimetres."
- Rule 5: one analogy ("squeezes the water like a funnel", c7) — fine. c7 has two numbers ("less than a metre", "about 16 metres") plus "a four-storey building"; the comparison is good, the extra number isn't needed.
- Size: 6 content cards plus a bridge; c2–c4 and c6 are at the 7-sentence cap, 58–74 words.
- Picture labels: "Pulls most" / "Pulls least" match c3; "Your beach", "Open ocean", "Bay of Fundy" match. Fine.

**Length:** nothing over 18 words; lint clean.

**Bridges:** c5 is a bridge, now off by default. Its 50-minute fact answers a question nobody asked in the spine; it should go to `more` or be cut.

**Why redo:** the title, the three-questions-in-one structure and the bridge are all paragraph-stage choices. A narrower title with a twist (e.g. why two high tides a day when there's only one Moon) would also pick which half of the current copy survives.

