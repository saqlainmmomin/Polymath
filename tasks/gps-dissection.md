# GPS: what is the reader really asking? (dissection, 2026-10-25)

Goal: before writing any card, work out what a curious stranger actually wonders when they see this title. The cards then answer *their* questions in the order they would ask them. The feed is random, so this topic must stand alone. It does not lean on, or lead into, other location topics.

## 1. The title

**Recommended: "How does GPS on your phone actually work?"** (8 words, ends `?`, literally true.)
- Alternative: "How does your phone know where you are?" It's plainer, but not literally answered by GPS alone, since indoors the phone uses Wi-Fi and cell towers. We'd need a hedge card, so the GPS title is safer.
- Rejected: "How does GPS actually work?" Without "phone" it reads like a school question. "On your phone" makes it about the thing in their hand.

## 2. What a reader is really wondering (ranked)

These are the questions people actually type about GPS, not the ones an engineer would list. Ranked by how many readers have this question in their head when they tap the title, and how much the answer pays off.

| Rank | The reader's real question | Have they felt it? | The answer, in one line | Card? |
|---|---|---|---|---|
| 1 | "Is something up there tracking me?" | Yes: a vague privacy unease | No. Satellites only shout. Your phone only listens and works out its own position. | **Yes, opener** |
| 2 | "How does it work with no signal, or in airplane mode?" | Yes: offline maps abroad, hiking, on a plane | Same answer: it never sends anything, so it needs no network. | **Yes, the opener's proof** |
| 3 | "OK, but how can just listening tell it where I am?" | No, but it's the question rank 1 creates | Late means far, and three distances cross at one spot. | **Yes, cards 2-3** |
| 4 | "How can a phone time something moving at the speed of light?" | No, but a reader who gets card 2 asks it next | It can't, well enough: a thousandth of a second off is about 300 km. So a fourth satellite fixes the clock too. | **Yes, card 4** |
| 5 | "Why does my blue dot jump around downtown?" | Yes, everyone in a city | Signals bounce off towers and arrive late, so the phone thinks a satellite is farther away. | **Yes, ending** (it reuses "late means far" on something they've seen) |
| 6 | "Why does it take ages to find me after a flight?" | Yes, travellers | With no fresh data the chip must hear the satellites' orbit details over a slow radio, which takes minutes. With internet it downloads them in seconds. | No. Too much setup. Its own bite (see 6) |
| 7 | "Why doesn't it work indoors?" | Yes | Signals are faint and roofs block them. Phones use Wi-Fi names instead. | No. Separate topic. Mentioning Wi-Fi here muddies the one idea |
| 8 | "Who runs it? Is it free?" | Rarely | US Space Force, free to use. | No. Low curiosity |
| 9 | "Does it need Einstein?" | No, this is a nerd's question | Satellite clocks run fast by about 38 millionths of a second a day. | No, but it's the best `more` teaser |

**What this changes.** The old draft opened on mechanism ("satellites broadcast where they are and the exact time"). The reader's real first questions are personal ones: *is it watching me?* and *how does it work with no signal?* The mechanism is the answer to those, so it should arrive as their payoff. The clock problem then comes up naturally as the reader's own next question, not as an engineer's footnote. The topic closes on a glitch the reader has personally seen, explained by the idea they just learned. That's the sentence they'll repeat to a friend.

## 3. Shape

Problem they've noticed → simple answer → how it works → "but it breaks" → the same idea explains your own experience.
5 content cards plus `more`. Every card ends on the question the next headline answers.

## 4. Card spine (draft copy, about 30 words each)

**Card 1. Opener.** Headline: the title. Setup line: *"It even works in airplane mode."*
> Switch off data, open an offline map, and the blue dot still finds you. Your phone never talks to the satellites. It only listens. So how is that enough?
- Picture: satellites send yellow dots down. Nothing goes up from the phone, which wears a little airplane-mode icon. A "No reply" label fades in.
- Answers: rank 1 + 2. Numbers: 0. Words: 29.

**Card 2.** Headline: **Late means far**
> Each satellite keeps shouting the time. Its signal flies at the speed of light, yet still lands a hair late. Like lightning then thunder, the delay tells you how far.
- Picture: a pulse drops from an overhead satellite. "Sent" then "Lands a hair later" appear, and a distance arrow grows.
- The fact arrives exactly when it's needed: "shouting the time" only appears once we need a delay. Numbers: 0. Words: 30.

**Card 3.** Headline: **Three distances, one spot. Nearly.**
> Each signal also says where its satellite is. So each distance draws a circle around it. Three circles cross at just one spot. There's a catch, though.
- Picture: map from above. One circle, then two crossing at two points, then a third leaves one point, which becomes "You". Label it "Seen from above" so the switch from sky to map is said, not jumped.
- Numbers: 0. Words: 27.

**Card 4. The break (middle of the topic, not a footnote).** Headline: **Your phone's clock is far too sloppy**
> Light is so fast that a clock off by a thousandth of a second puts you about 300 km out. Phone clocks are cheap. So it listens to a fourth satellite, and fixes the time too.
- Picture: the three circles from card 3 swell by the same amount and miss each other. A fourth circle arrives, they all snap back to meet, and a clock icon corrects itself.
- Numbers: 1 pair (thousandth of a second ↔ 300 km). That's one comparison, but the lint may count two. Words: 35, so it needs one trim pass.

**Card 5. The payoff from their own life.** Headline: **So that's why the dot jumps downtown**
> Glass towers bounce the signals. A bounced signal arrives late, so your phone thinks that satellite is farther away, and the dot slides down the street.
- Takeaway: **Your phone finds itself by timing whispers from space.**
- Picture: street canyon. One signal hits a tower and bounces into the phone, and the blue dot slides sideways.
- Numbers: 0. Words: 26 + 8.

**More.** Note (teaser, not a recap):
> Up in orbit, satellite clocks run fast by a few millionths of a second a day. Einstein predicted it. Without a fix, GPS would drift about 10 km every day.
- `links`: any topic outside phones and location, since the feed is random. Do not chain to the indoor or Maps topics.

## 5. Checks
- Cover test (could you guess the body from the headline?): Late means far: pass (the thunder link and "shouting the time" are unguessable). Three distances, one spot. Nearly.: pass ("Nearly" pulls you on). Your phone's clock is far too sloppy: pass (why would a clock matter?). So that's why the dot jumps downtown: pass (you can't guess the bounce).
- No em dashes, no "not X but Y", one new idea per card.
- Words stay defined inside the topic: satellite, signal, "late". No term borrowed from another topic.

## 6. Left out on purpose
- Indoors and Wi-Fi (rank 7): its own topic, so it doesn't blur "it only listens".
- Slow start after a flight (rank 6): a good standalone bite. "Why does your phone take so long to find you after a flight?" Cold start takes about 2-4 minutes, versus seconds with downloaded help.
- 3D spheres instead of circles: true, but it adds a concept without adding curiosity. The flat "Seen from above" picture is labelled as such.
- Satellite count, altitude, who runs it: trivia that answers no question the reader has.

## 7. Facts and sources (opened)
| Claim | Source |
|---|---|
| Satellites only transmit; they "do not know where any particular user or device is located" | EFF Surveillance Self-Defense: https://ssd.eff.org/module/mobile-phones-phone-components-and-sensors |
| GPS keeps working in airplane mode on iPhone (since iOS 8.3); slower without A-GPS | https://mjtsai.com/blog/2015/07/05/gps-in-airplane-mode/ (quotes Gaia GPS) |
| About 20,200 km up; at least four satellites visible from virtually anywhere | https://archive.gps.gov/systems/gps/space/ |
| 1 ms × 300,000 km/s = 300 km | Computed |
| Signals bounce off buildings; reflections arrive "at slightly different times" | https://novotech.com/pages/multipath-interference |
| Cold start takes 2-4 min, almanac sent every 12.5 min, A-GPS downloads data over the network | https://en.wikipedia.org/wiki/Time_to_first_fix |
| Satellite clocks run about 38 µs/day fast; uncorrected, positions drift about 10 km a day | https://www.astronomy.ohio-state.edu/pogge.1/Ast162/Unit5/gps.html |

**Unverified:**
- "The dot slides down the street" is the right direction in general (a bounced signal always reads as longer), but how big the jump is varies. One search snippet said 2 m in open country versus up to 30 m in cities, but I didn't open that page, so no number is used.
- That airplane mode keeps GPS on for *every* Android phone: confirmed for iPhone only. Card 1 says "it even works in airplane mode", which holds on iPhone and most Android phones. The fact checker should confirm.
