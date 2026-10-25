# Handoff: find the best "twist" for each daily-tech question (Polymath)

You have zero context from the session that wrote this. Everything you need is here or in the files listed. This is a thinking-and-research task. You write NO topic code.

## Goal

Polymath is a phone app (a shorts-style feed) whose one job is to **make people curious**. Each topic answers one everyday "how does X actually work?" question in 3-5 swipeable cards. We keep failing to make the explanations land. Your job is to fix the *idea layer* before any card is written:

For each of the 4 questions below, (1) list every plausible **twist** (the moment the answer is not what the reader expected), (2) score them, (3) choose the best one, and (4) deliver a draft card spine built around it.

Done means: the Results section at the bottom of this file contains, for each question, a twist longlist (at least 6 candidates each, from different explanation types), a scored comparison, one chosen twist with the reason, and a 4-5 card spine. Every factual claim in a chosen twist is backed by a source link you actually opened.

## The product and the reader

- Reader: a curious adult with no background, on a phone, swiping. Entertainment first, education second. Never lessons, quizzes, scores, or homework tone.
- Success test: after one topic the reader can explain it to a friend two days later, and wants to swipe to the next question.
- Format: a topic is ONE question title plus 3-5 cards. Each card is a headline above, an animated picture in the middle, and about 30 words below. One idea per card.

## Why we are failing (diagnosis from the previous session)

Read this carefully; your output must avoid these.
1. **No puzzle is ever created.** Cards hand over answers to a question the reader has not asked. The first card gives a small surprise, then the rest reads as a lecture outline.
2. **Headlines are section titles, not hooks.** "One distance gives a ring of places": cover the body text and you can guess it, so there is no reason to read on. Test every headline with the cover test.
3. **Facts arrive before they are needed.** The GPS draft told the reader the satellites broadcast "the exact time they sent the signal" before the reader had any use for it.
4. **Order is backwards.** We explained how a thing is measured before the reader had a reason to want it. Better order, as in Bartosz Ciechanowski's GPS article: problem, simple solution, "but it breaks", fix.
5. **The best material got buried.** In the GPS draft the real surprise (a phone's clock error of one thousandth of a second becomes a 300 km position error, so a fourth satellite is needed) sat in a footnote card.
6. **Cards repeat each other or narrate the picture.** Two cards said "delay becomes distance". One said "Look at a map from above..." instead of letting the picture show it.
7. **Inventing a clever puzzle title was wrong too.** The owner said "How does your phone know the way to somewhere you've never been?" is not a question that comes to his head. His real curiosity is plain: "how do the features I use every day actually work, what's the deal behind them?" Titles must be that plain question, brand names allowed when it is the phrase people say (e.g. "How does Google Maps ...").

## Decisions already made (do not relitigate)

- Titles are plain everyday questions, 12 words or fewer, ending with `?`, literally true.
- Big daily-use subjects are split into separate topics when a stranger would type each piece as its own question. These four pass that test. (Pieces like "how a crank turns" fail it and stay as cards.)
- Each topic must define its own words, because the feed shuffles topics randomly. Topics link onward with a "Go deeper" chain, so each should end with a pull into another.
- Pattern for cards: what the reader sees on screen, then what is really behind it, one layer per card.

## The four questions

| # | Title | Core idea | Seeds already thought of (go beyond them) |
|---|---|---|---|
| 1 | How does Google Maps know there's traffic? | Your phone is the sensor. While Maps is on, phones send location and speed, anonymised and averaged. Many slow dots on one road turns it red. History (past Fridays) plus now forecasts the jam ahead. | "You are the sensor"; "the jam is drawn by the drivers stuck in it"; "it knows before you get there"; "a lone slow phone is just a parked car, so how does it tell?" |
| 2 | How does Google Maps find the fastest route? | The map is dots (junctions) joined by lines (roads) each carrying a travel time. The fastest route is the smallest total. Checking every route is far too slow, so it leans on big roads as shortcuts and searches from both ends. | "It never checks every route"; "a map is a web with minutes on it"; "ripples spreading out"; "meeting in the middle" |
| 3 | How does GPS actually work? | Satellites broadcast; your phone only listens. Signal delay gives distance; one distance is a ring, several rings cross at a spot. A phone's cheap clock breaks this, so a fourth satellite is used to fix position and clock together. | "The satellite doesn't know you exist"; "1 ms of clock error = 300 km"; "satellite clocks drift about 38 microseconds a day from relativity, roughly 10 km of error a day if uncorrected" (verify) |
| 4 | How does your phone find you inside a building? | No GPS needed: it matches nearby Wi-Fi networks and cell towers against known locations. Reported accuracy is about 5-100 m for Wi-Fi and 50-5,000 m for cell towers (single source, verify). | "Your phone knows where you are from the names of Wi-Fi networks"; "the blue dot is a best guess, and it can be wrong" |

## What a "twist" is, and the menu of types

A twist is the card-sized moment where the reader's assumption flips and curiosity turns into "ohh". Generate candidates across these explanation types, not just one:
- **Reversal of who does the work** (the user is the sensor; the satellite never hears you).
- **It almost works, then breaks, then the fix** (the clock problem).
- **Scale shock** (a number that staggers, with something to hold it against).
- **Hidden helper** (something unseen quietly carries it: other drivers, Wi-Fi routers, history).
- **Shortcut / what it skips** (it ignores almost everything).
- **Trade-off or hidden cost** (accuracy vs speed vs privacy).
- **Counterintuitive cause** (the obvious reason is wrong).
- **Analogy that maps cleanly** (and what it costs the reader to map back).
- **Misconception to bust** (what most people wrongly believe, with a guess-tap at the start).

## How to choose (score each candidate 1-5, show the table)

1. **Surprise:** would a smart non-expert not have guessed it?
2. **Felt, not just stated:** can a picture or one concrete scene make it land with little text?
3. **Truth:** is it literally correct and sourced? Anything shaky scores low or is dropped.
4. **Fits 3-5 cards** with one idea per card and a real thread (each card ends on the question the next headline answers).
5. **Pulls onward:** does it leave a thread toward the next topic in the chain?
6. **Relatable:** does it connect to something the reader has personally done or seen?

Pick the highest total. Break ties by criterion 2. Also name the runner-up and say whether it works as a "Go deeper" bite.

## What to deliver per question

1. Longlist: at least 6 twists, tagged by type above, each in one sentence plus the surprise it creates.
2. Score table (criteria 1-6).
3. Chosen twist and why in two sentences.
4. Card spine of 4-5 cards: for each, a headline that passes the cover test (a hook, not a section title), the one idea, and the one fact it uses. Mark which card holds the twist and make sure the topic's "it breaks / it flips" moment is in the middle, not a footnote. End with the `more` link.
5. Sources: URL list for every fact, opened and read.

Then, after all four, add a short section: the chain of "Go deeper" links across the four topics, and three more daily-use features that would fit the same mould (plain title, why a stranger would type it), no twist work needed for those.

## Key files (read first, in order)

- `/Users/saqlainmomin/tell-me-how/PRODUCT.md`: product goal (curiosity, effortless, broad appeal).
- `/Users/saqlainmomin/tell-me-how/RECIPE.md`: topic rules. Note: its title-formula bullets (tension/stake, no brand names) are superseded by the Decisions section above; the rest (card anatomy, copy rules, one number per card, about 30 words per card) still applies.
- `/Users/saqlainmomin/tell-me-how/topics/gps.js`: the existing GPS draft, the thing being diagnosed. Do not edit.
- `/Users/saqlainmomin/tell-me-how/topics/ice-floats.js` and `topics/card-payment.js`: reference for the intended voice and card shape.
- `/Users/saqlainmomin/tell-me-how/tasks/fix-log.md`: mistakes reviewers keep catching.

## Constraints

- Write only to the Results section of this file. Do not create or edit topic files, `core/`, `build.mjs`, `RECIPE.md`, or `LIBRARY`.
- Do not publish or republish any artifact, and do not touch the testers' link.
- Keep ideas conservative on facts: use "about" for rough numbers, and drop a claim you cannot source rather than assert it.
- No em dashes or textbook phrasing in the draft headlines; they should sound like something a friend would say.

## Verification

- Open every source you cite (WebFetch/WebSearch) and check the claim appears there. List claims you could not confirm under "Unverified".
- Confirm each proposed title is a question of at most 12 words ending in `?`.
- Run the cover test on every headline and mark pass/fail.
- Count the numbers in each card draft: at most one.

## Report back

Append a `## Results` section to this same file with the deliverables above, then a three-line summary at the top of it: the four chosen twists, the single riskiest assumption, and one question for the owner if any.

## Results

**Summary.** Chosen twists: (1) Traffic: a man walked 99 phones down a Berlin street in a wagon and Maps drew a jam, which proves the red line is just phones counting themselves. (2) Fastest route: the obvious "ripple" method is perfect but drowns on long trips, so route finders skip almost every street. (3) GPS: a thousandth of a second of phone-clock error puts you about 300 km off, so a fourth satellite is used to fix the clock. (4) Indoors: your phone finds you from the names of Wi-Fi networks it never joins, which is why people who move house with their router get placed at the old address.
**Riskiest assumption:** Topic 2 says Google Maps uses the "big roads plus search from both ends" family of tricks. Google has never published its routing method. The numbers come from an academic benchmark on Western Europe's road map. The spine words it as "route finders like Maps", but card 5 could still be read as a claim about Google.
**Question for the owner:** Is "route finders like Maps do this" honest enough for the topic 2 title, or do you want an explicit "Google doesn't say exactly, but the standard trick is..." line? That line costs about 8 words on card 5.

Score key: S = surprise, F = felt (picture or scene), T = truth (sourced), C = fits 3-5 cards, P = pulls onward, R = relatable. Each is 1-5, max 30.

---

### 1. How does Google Maps know there's traffic? (7 words, ends `?`)

**Longlist**
| # | Twist | Type | The surprise it creates |
|---|---|---|---|
| A | A man pulled 99 phones in a wagon down Berlin streets, and Maps turned the empty road red and sent cars around it. | It breaks, then the fix (plus scene) | "Wait, it's *just* counting phones?" Funny proof of the whole mechanism. |
| B | You are the sensor: while Maps is open, your phone sends anonymous speed and location, and thousands are combined. | Reversal of who does the work | The reader has been doing the reporting without knowing it. |
| C | The jam is drawn by the drivers stuck in it. | Hidden helper | The people suffering the jam are the ones painting it red for everyone behind. |
| D | It forecasts the jam you haven't reached by mixing live speeds with how that road behaved at the same hour on past days. | Counterintuitive cause | Your ETA is partly a memory of past Fridays. |
| E | In lockdown, traffic fell by up to half, so the "memory" was suddenly wrong and Google had to trust only the last 2-4 weeks. | It breaks, then the fix | The history that makes it smart can lie. |
| F | A scooter weaving through a jam doesn't clear it: in some countries Maps tells cars from motorbikes. | Misconception to bust | "Fast phone = road is clear" is wrong, so it has to be picky about whose speed counts. |
| G | Google deletes the start and end of every trip, so even it can't see where an anonymous phone came from. | Trade-off / hidden cost | Privacy is the price of the crowd, and it trims your trip's ends to pay it. |
| H | It's been doing this since 2009, on phones that weren't even running navigation. | Scale shock | Weak: a date is not a staggering number. |

**Scores**
| # | S | F | T | C | P | R | Total |
|---|---|---|---|---|---|---|---|
| A | 5 | 5 | 5 | 5 | 4 | 4 | **28** |
| B | 4 | 4 | 5 | 4 | 4 | 5 | 26 |
| C | 4 | 4 | 5 | 3 | 3 | 5 | 24 |
| D | 3 | 3 | 5 | 4 | 4 | 5 | 24 |
| E | 4 | 3 | 5 | 3 | 3 | 4 | 22 |
| F | 3 | 4 | 4 | 3 | 2 | 3 | 19 |
| G | 3 | 2 | 5 | 2 | 2 | 2 | 16 |
| H | 1 | 1 | 4 | 2 | 1 | 2 | 11 |

**Chosen: A (the 99-phone wagon), built on B.** The wagon is a real, funny scene that proves the mechanism without any explaining: if 99 slow phones in a cart make a red road, the red road must be phones. It also gives us the "it breaks" moment the GPS draft buried, and it sets up the fix (Maps has to be picky about whose speed counts).
**Runner-up:** E (lockdown broke the memory). Works as a Go-deeper bite: "Why did Google Maps get worse in lockdown?"

**Card spine** (problem, simple answer, it breaks, fix, forecast)
| Card | Headline | One idea | One fact | Ends on | Cover test | Numbers |
|---|---|---|---|---|---|---|
| 1 (opener) | *Title.* Setup line: "Nobody is watching that road." | No cameras or helicopters. The red comes from inside the cars. | Live traffic comes from aggregated phone location data. | "So who's reporting?" | Pass (the setup line raises a question it doesn't answer) | 0 |
| 2 | Your phone is quietly reporting your speed | While Maps is on, each phone sends anonymous speed and place. Put many together and one road's speed appears. | Speeds from thousands of phones across a city are combined. | "Lots of slow phones on one road means red. But is that all it takes?" | Pass (you can't guess *how*, or that it's anonymous and pooled) | 1 |
| **3 (twist, middle)** | One man faked a jam with a wagon | An artist pulled a cartful of phones with Maps on along empty Berlin streets. The road went red and cars were sent around it. | 99 second-hand phones, a hand-pulled wagon, Berlin, 2020. | "So it really is just counting phones. Can it tell a wagon from a car?" | Pass (the headline makes you ask "how?") | 1 |
| 4 | A scooter in a jam can't fool it | Maps has to be picky: in some countries it tells cars from motorbikes, so one bike zipping through doesn't turn the road green. Google admitted wagons still beat it. | Google says it can tell cars from motorcycles in some regions. | "Fine for now. But how does it know about a jam you haven't reached?" | Pass | 0 |
| 5 | It also remembers every Friday | It mixes what phones say now with how this road usually behaves at this hour, then guesses the road ahead. Takeaway: *The jam is drawn by the people stuck in it.* | Arrival times are accurate for over 97% of trips. | `more` | Pass (the "remembers" claim needs the body to explain) | 1 |
| more | links: `fastest-route` | Note: "Now Maps knows which roads are slow. But how does it pick your way through millions of them in a blink?" | | | | |

**Sources (all opened)**
- https://googleblog.blogspot.com/2009/08/bright-side-of-sitting-in-traffic.html : phones send "anonymous bits of data ... describing how fast you're moving"; "across thousands of phones moving around a city"; "we find the start and end points of every trip and permanently delete that data".
- https://blog.google/products/maps/google-maps-101-how-ai-helps-predict-traffic-and-determine-routes/ : "aggregate location data"; historical patterns plus live conditions; "accurate for over 97% of trips"; lockdown traffic down "up to 50%", models reweighted to the last 2-4 weeks; user incident reports.
- https://9to5google.com/2020/02/03/google-maps-hack-virtual-traffic-jam/ : Simon Weckert, 99 smartphones, a handcart, Berlin streets incl. outside Google's office, green to red, rerouting; Google: can distinguish cars and motorcycles in some regions, "haven't quite cracked traveling by wagon".
- https://www.technologyreview.com/s/428732/androids-rise-helps-google-grow-its-traffic-surveillance-system/ : Android sends anonymous position and current speed; a sudden slowdown on a freeway signals a jam.

---

### 2. How does Google Maps find the fastest route? (8 words, ends `?`)

**Longlist**
| # | Twist | Type | The surprise it creates |
|---|---|---|---|
| A | The obvious method (spread out like a ripple, nearest junction first) is perfect, but across Europe it checks about 9 million of 18 million junctions for one trip, so real route finders skip almost every street. | It almost works, then breaks, then the fix | "The perfect method is too slow, and the fast one wins by ignoring nearly everything." |
| B | Even a small grid of streets hides about 185,000 routes that never turn back. A city is astronomically worse. | Scale shock | Checking every route is hopeless, so how does it answer in a blink? |
| C | The method at its heart was invented in about 20 minutes at a café in Amsterdam in 1956, with no pencil or paper. | Hidden helper (a person) | Your everyday app runs on a coffee-break idea from before smartphones. |
| D | It searches from both ends at once and stops where the two searches meet. | Shortcut / what it skips | Like digging a tunnel from both sides. |
| E | A map to a computer is just dots with minutes written on the lines between them. | Analogy that maps cleanly | Your city becomes a web of numbers. Clean, but not surprising on its own. |
| F | Long trips almost always funnel onto a few big roads, so once you're far from home and destination, the small streets can be ignored. | Shortcut / what it skips | "It doesn't even look at most streets." |
| G | Adding a road can make everyone's trip slower (Braess's paradox), and removing one can speed things up (Seoul, Times Square). | Counterintuitive cause | Fastest for you can be slower for everyone. True, but it's about traffic, not about how Maps routes. |
| H | "Fastest" uses predicted minutes for each road at the time you'll reach it, not distance. | Misconception to bust | People assume shortest equals fastest. |

**Scores**
| # | S | F | T | C | P | R | Total |
|---|---|---|---|---|---|---|---|
| A | 5 | 4 | 4 | 5 | 4 | 4 | **26** |
| B | 4 | 5 | 5 | 2 | 3 | 4 | 23 |
| C | 4 | 3 | 5 | 2 | 3 | 3 | 20 |
| F | 4 | 4 | 4 | 3 | 3 | 4 | 22 |
| D | 3 | 4 | 4 | 3 | 2 | 3 | 19 |
| G | 5 | 3 | 5 | 1 | 3 | 3 | 20 |
| H | 2 | 3 | 5 | 3 | 3 | 5 | 21 |
| E | 2 | 4 | 5 | 3 | 2 | 3 | 19 |

(T = 4 for A and F because Google doesn't publish its method. The numbers are from the standard academic benchmark, not from Google.)

**Chosen: A, opened with B and fixed with D and F.** It is the only candidate with the full Ciechanowski arc: the reader gets a simple method that is guaranteed right, watches it drown, then sees the fix win by ignoring almost every street. B, C, D and F become its cards, so no good material is buried.
**Runner-up:** G (Braess's paradox). Strong Go-deeper bite: "Can a new road make traffic worse?" It's sourced and surprising, but it's off-question for this title.

**Card spine**
| Card | Headline | One idea | One fact | Ends on | Cover test | Numbers |
|---|---|---|---|---|---|---|
| 1 (opener) | *Title.* Setup line: "There are far too many ways to check them all." | Even a small grid of streets has a staggering number of routes across. Maps answers in a blink. | A 10 x 10 grid has 184,756 routes across that never turn back (simple counting). Say "about 185,000". | "So it can't be trying them all. What does it do?" | Pass | 1 |
| 2 | To Maps, your city is dots and minutes | Junctions are dots, roads are lines, and each line carries the minutes it takes right now (from the traffic topic). Fastest = smallest total. | Routes weigh predicted traffic and road type. | "Smallest total. But how do you find it without adding up every route?" | Pass (you can't guess "minutes, not distance") | 0 |
| 3 | Spread out like a ripple, closest first | Grow outward from your start, always settling the nearest junction next. When the ripple reaches the destination, that path is the fastest. Invented on a coffee break. | Dijkstra designed it in about twenty minutes at an Amsterdam café, 1956. | "It's always right. There's one problem." | Pass | 1 |
| **4 (twist, middle)** | On a long trip, the ripple drowns | The ripple doesn't know where you're going, so it floods in every direction. Across Europe it checks about half the map for one trip. Far too slow for millions of people at once. | Plain Dijkstra on Western Europe scans about 9.3 million of 18 million junctions per query (about 2 seconds). Use only "about half the map" or "about 9 million". | "So how does Maps answer instantly?" | Pass | 1 |
| 5 | The trick: ignore almost every street | Long trips funnel onto big roads, so route finders pre-build shortcuts along them and search from both ends until they meet. A few hundred junctions instead of millions. Takeaway: *It finds the best route by skipping nearly all of them.* | Contraction hierarchies scan about 280 junctions per query on the same map. "A few hundred." | `more` | Pass | 1 |
| more | links: `gps` | Note: "Every route starts with 'you are here'. So how does your phone know where here is?" | | | | |

**Sources (all opened)**
- https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm : visits nodes in order of distance; café terrace in Amsterdam with his fiancée, about twenty minutes, 1956, Rotterdam to Groningen.
- https://arxiv.org/abs/1504.05140 (Bast, Delling, Goldberg et al., "Route Planning in Transportation Networks", Microsoft Research; full PDF read): Western Europe instance "18.0 million vertices"; Table 1, Dijkstra about 9,326,696 scanned vertices and about 2.2 s per query; CH about 280 scanned vertices; "Sufficiently long shortest paths eventually converge to a small arterial network of important roads, such as highways"; "bidirectional search visits roughly half as many vertices"; directions "in milliseconds or less even at continental scale".
- https://en.wikipedia.org/wiki/Contraction_hierarchies : shortcuts made in preprocessing "to skip over 'unimportant' vertices"; bidirectional query.
- https://blog.google/products/maps/google-maps-101-how-ai-helps-predict-traffic-and-determine-routes/ : routing weighs predicted traffic, road quality and size.
- https://en.wikipedia.org/wiki/Braess%27s_paradox : runner-up (Seoul, Stuttgart, New York examples).
- 184,756 = C(20,10): computed, not sourced (a math fact).

---

### 3. How does GPS actually work? (5 words, ends `?`)

**Longlist**
| # | Twist | Type | The surprise it creates |
|---|---|---|---|
| A | Phone clocks are cheap: a thousandth of a second of error puts you about 300 km off, so a fourth satellite is used to solve your clock along with your position. | It almost works, then breaks, then the fix | "Three should be enough... oh, my *clock* is the problem." |
| B | The satellite doesn't know you exist: GPS only broadcasts, and your phone only listens. | Reversal of who does the work | Nothing is "tracking" you. You are tracking them. |
| C | Satellite clocks run fast by about 38 millionths of a second a day because of relativity. Uncorrected, positions would drift about 10 km a day. | Scale shock / counterintuitive cause | Einstein is in your pocket. |
| D | By the time it reaches you, the signal is about 80 times weaker than the background hiss, and the phone still digs it out. | Scale shock | It's listening to a whisper under a roar. |
| E | Late means far: the delay of a signal is a distance, like counting between lightning and thunder. | Analogy that maps cleanly | Time becomes distance. Familiar, so a moderate surprise. |
| F | One distance only puts you on a ring. You need rings to cross. | Shortcut / geometry | Clean, but it's a step, not a twist. |
| G | The whole system rests on satellite timing good to about 20-30 billionths of a second. | Scale shock | Staggering, but abstract with nothing to hold it against. |

**Scores**
| # | S | F | T | C | P | R | Total |
|---|---|---|---|---|---|---|---|
| A | 5 | 4 | 5 | 5 | 4 | 4 | **27** |
| C | 5 | 3 | 5 | 2 | 5 | 2 | 22 |
| B | 4 | 4 | 5 | 3 | 3 | 4 | 23 |
| D | 4 | 3 | 4 | 2 | 3 | 3 | 19 |
| E | 3 | 5 | 5 | 4 | 2 | 5 | 24 |
| F | 2 | 5 | 5 | 4 | 2 | 2 | 20 |
| G | 4 | 2 | 5 | 2 | 2 | 1 | 16 |

**Chosen: A (the 300 km clock error).** It is the real "it breaks" moment, it was buried in the old draft's footnote, and it explains the one thing people wonder about (why four satellites). The diagnosis's fix is to put it at card 4 of 5, after the reader trusts the simple three-circle answer.
**Runner-up:** C (relativity). The best Go-deeper bite in the set: "Why does GPS need Einstein?"

**Card spine** (problem, simple answer, it breaks, fix)
| Card | Headline | One idea | One fact | Ends on | Cover test | Numbers |
|---|---|---|---|---|---|---|
| 1 (opener) | *Title.* Setup line: "Your phone never says a word to a satellite." | Satellites only broadcast, like a radio station. Your phone just listens. | Users can see at least four satellites from virtually anywhere. Keep it as a picture, no number. | "So how can just listening tell you where you are?" | Pass | 0 |
| 2 | The signal is late, and late means far | Each signal says when it left. It lands a hair later, because even light takes time. Like lightning then thunder, the wait is the distance. | From overhead (about 20,200 km) the trip takes about a fifteenth of a second. | "But one distance isn't a place yet." | Pass (you can't guess the thunder link or *how* late) | 1 |
| 3 | Three distances, one spot. Nearly. | Each signal also says where its satellite is, so a distance becomes a circle around it. Three circles meet at one spot. | Geometry. | "That should be it. Except your phone has a secret flaw." | Pass (the "Nearly." is the hook) | 0 |
| **4 (twist, middle)** | Your phone's clock is too sloppy for this | Satellites carry superb clocks. Your phone's is cheap. Since light is so fast, a tiny timing slip becomes a huge distance slip. | 1 thousandth of a second off = about 300 km wrong (300,000 km/s x 0.001 s). | "So how does a cheap phone ever get it right?" | Pass | 1 |
| 5 | So it asks a fourth satellite | Treat the clock error as one more unknown. Four signals together solve where you are *and* the true time. Takeaway: *The fourth satellite fixes your phone's clock.* | Four satellites are visible from almost anywhere. | `more` | Pass | 0 |
| more | links: `indoor-location` | Note: "Those signals are faint whispers, and roofs block most of them. So how does your phone find you inside a mall?" (Alternative bite: relativity, 38 microseconds a day.) | | | | |

**Sources (all opened)**
- https://archive.gps.gov/systems/gps/space/ : "approximately 20,200 km"; "circles the Earth twice a day"; 31 operational; "users can view at least four satellites from virtually any point on the planet".
- https://www.astronomy.ohio-state.edu/pogge.1/Ast162/Unit5/gps.html : satellite clocks tick faster by "about 38 microseconds per day" (45 - 7); uncorrected, the fix is false "after only 2 minutes" and errors grow "about 10 kilometers each day"; timing needed to "20-30 nanoseconds".
- https://ocw.tudelft.nl/wp-content/uploads/Lecture_3_-_GNSS_receivers.pdf (TU Delft GNSS lecture, PDF text extracted): received signal about -157.6 dBW vs noise about -138.5 dBW in 2 MHz, "well below noise level". About 19 dB, about 80 times weaker (computed).
- 300 km per millisecond and about 0.067 s for 20,200 km: computed from the speed of light.

---

### 4. How does your phone find you inside a building? (9 words, ends `?`)

**Longlist**
| # | Twist | Type | The surprise it creates |
|---|---|---|---|
| A | Your phone finds you from the names of Wi-Fi networks it never joins. Move house with your router and phones can place you at your old address for weeks. | Hidden helper, then it breaks | "My *router* tells strangers' phones where they are?" |
| B | The map of every router was built by phones like yours. iPhones send the geotagged locations of nearby hotspots to Apple's crowd-sourced database. | Reversal of who does the work | You have been mapping your neighbours' Wi-Fi. |
| C | The pale circle around the blue dot is a confession. On Android its radius is set so there's about a 2 in 3 chance you're inside. | Misconception to bust | The dot isn't where you are. It's a best guess with odds. |
| D | Adding `_nomap` to your Wi-Fi name removes it from Google's location map. | Hidden helper (the off switch) | A secret word in a network name opts it out. |
| E | Street View cars collected Wi-Fi network IDs while photographing streets. | Hidden helper | The car taking your street's photo was also logging your router. |
| F | Wi-Fi gets you to tens of metres. A single cell tower might only say "somewhere in this town". | Trade-off | Why the circle swells and shrinks. |
| G | Indoors, satellite signals are already about 80 times weaker than background hiss, and the roof cuts them further. | Scale shock | Explains why GPS gives up, but it's GPS-topic material. |

**Scores**
| # | S | F | T | C | P | R | Total |
|---|---|---|---|---|---|---|---|
| A | 5 | 5 | 4 | 5 | 4 | 5 | **28** |
| B | 4 | 4 | 5 | 3 | 4 | 4 | 24 |
| C | 4 | 5 | 4 | 3 | 3 | 5 | 24 |
| D | 4 | 2 | 5 | 2 | 2 | 3 | 18 |
| E | 3 | 3 | 4 | 2 | 2 | 3 | 17 |
| F | 2 | 4 | 4 | 3 | 2 | 4 | 19 |
| G | 3 | 2 | 4 | 2 | 3 | 3 | 17 |

(A gets T = 4 because the "moved router" story comes from user reports, not an official doc. The mechanism behind it is official: a router's ID is looked up in a database of where it was seen. Word it as "people who move house have found...".)

**Chosen: A, with B as its middle and C as its landing.** It turns an invisible thing (router IDs) into a scene everyone gets: you moved, your phone didn't. The "it breaks" moment proves how the system works better than any explanation could.
**Runner-up:** C (the blue circle's odds). It works as a Go-deeper bite: "What does the blue circle on your map mean?"

**Card spine**
| Card | Headline | One idea | One fact | Ends on | Cover test | Numbers |
|---|---|---|---|---|---|---|
| 1 (opener) | *Title.* Setup line: "Satellites can barely hear you in here." | GPS signals are faint and roofs block them, yet the blue dot still finds you in a mall. | Google: things between you and the sky or towers make the dot less accurate. | "So what is it using instead?" | Pass | 0 |
| 2 | It reads the Wi-Fi names around you | Every router keeps shouting its name and ID, even ones you can't join. Your phone just listens to the list. It never needs to connect. | Google uses "publicly broadcast Wi-Fi information". | "But a name isn't a place. Who knows where each router is?" | Pass (you can't guess "networks you never joined") | 0 |
| 3 | Phones like yours mapped every router | When a phone outside knows where it is from GPS, it notes the routers it hears and sends them in. Millions of phones built a giant router map. | iPhones periodically send "geo-tagged locations of nearby Wi-Fi hotspots" to Apple. | "So what happens when a router moves?" | Pass | 0 |
| **4 (twist, middle)** | Move house, and your phone moves you back | People who took their router to a new home have seen their phone insist they're still at the old one. The map only updates once enough phones notice. | One user reported it took about six weeks to fix itself. | "So how much should you trust that blue dot?" | Pass | 1 |
| 5 | The pale circle is the honest part | The circle shows how unsure it is. Lots of routers nearby make it small. A lone cell tower makes it huge. Takeaway: *Indoors, your phone finds you by who's shouting nearby.* | Android sets the radius for about a 2 in 3 chance you're inside. | `more` | Pass | 1 |
| more | links: `maps-traffic` | Note: "Phones quietly reporting what they hear also paint something else: the red lines on your traffic map." | | | | |

**Sources (all opened)**
- https://support.google.com/maps/answer/1725632?hl=en : Google uses "publicly broadcast Wi-Fi information from wireless access points and GPS, cell tower, and sensor data"; `_nomap` opt-out.
- https://support.apple.com/en-us/102515 : uses cellular, Wi-Fi, GPS and Bluetooth; device "will periodically send the geo-tagged locations of nearby Wi-Fi hotspots and cell towers to Apple to augment Apple's crowd-sourced database".
- https://support.google.com/android/answer/3467281 : Location Accuracy uses GPS, Wi-Fi, mobile networks and sensors; Wi-Fi scanning helps apps get better location.
- https://developer.android.com/reference/android/location/Location : getAccuracy is the radius "at the 68th percentile confidence level ... 68% chance that the true location falls within this circle".
- https://support.google.com/maps/answer/2839911?hl=en : "You could be anywhere within the light blue circle. The smaller the circle, the more certain the app is"; parking garages and tall buildings hurt accuracy.
- https://ichnaea.readthedocs.io/en/latest/algo/accuracy.html (Mozilla Location Service): Wi-Fi "usually accurate to 100 meters", "10 or 20 meters" with many networks; cell from 1 to 10 km and up to tens of km.
- https://healy.econ.ohio-state.edu/otherstuff/help/googlemapswifi.html : moved 30 miles with the router, Maps showed the old house, fixed itself after about 6 weeks (anecdote).
- https://discussions.apple.com/thread/4370143 : Apple user whose router still showed at the old residence in another state (anecdote).

---

### Unverified (not used as stated, or used only with "about"/"some")
- The handoff's "5-100 m Wi-Fi, 50-5,000 m cell" accuracy: not found in one source. Mozilla gives Wi-Fi 10-100 m and cell 1 km to tens of km. Use "tens of metres" vs "a whole neighbourhood or town".
- "A lone slow phone is just a parked car" (how Maps filters stopped phones): no official source found. Only the car/motorcycle distinction and "concentration of devices" are confirmed, so the topic 1 spine uses those.
- Whether Google Maps uses contraction hierarchies or bidirectional search specifically: not published. The spine says "route finders".
- Why the moved-router problem fixes itself (Street View car vs other phones): the anecdote's explanation is a guess. The spine only says "once enough phones notice", which is consistent with Apple's crowd-sourcing doc but not confirmed for that case.
- "Roofs cut GPS a further ~20 dB indoors": seen only in a search-result snippet of a patent, not opened. Not used as a number.
- Google's Street View Wi-Fi logging (longlist 4E): seen only in search snippets (news on the 2010 case), not opened. It is not in any chosen spine.

### Checks
- Titles: 7, 8, 5 and 9 words, all ending in `?` and all literally true. ✔
- Cover test: all 20 content headlines pass. (I rewrote "One distance gives a ring of places"-style section titles into claims or scenes the body has to pay off.)
- Numbers per card: at most 1 on every card (counted in the tables). ✔
- No em dashes in headlines. ✔

### Go-deeper chain
`maps-traffic` → `fastest-route` ("now it knows which roads are slow, how does it pick your way?") → `gps` ("every route starts with 'you are here'") → `indoor-location` ("signals die under a roof") → back to `maps-traffic` ("phones reporting what they hear also paint the traffic map"). It's a closed loop, so any entry point leads through all four.
Bites that hang off the chain: "Why does GPS need Einstein?" (relativity, 38 µs/day), "Can a new road make traffic worse?" (Braess), "Why did Google Maps get worse in lockdown?", "What does the blue circle on your map mean?".

### Three more daily-use features for the same mould
1. **How does your phone's face unlock actually work?** People do it dozens of times a day and openly wonder whether a photo would fool it.
2. **How does Shazam recognise a song in seconds?** It's a classic "how is that even possible" that people type after it works in a noisy bar.
3. **How does autocorrect know what you meant to type?** Everyone has been helped and humiliated by it, and the question comes up naturally after a bad correction.
