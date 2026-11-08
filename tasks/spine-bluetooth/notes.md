# Notes for the builder's log (not for the approver's cold read)

## Angle and why
Chosen: Bluetooth survives a crowd of Wi-Fi not by being strong but by never staying on one channel (frequency hopping), told as one story in four slides. Why: it is the one genuinely surprising thing about how Bluetooth works, it is a daily moment (earbuds beside Wi-Fi), and it needs one picturable analogy (a radio dial). It also answers "it's not Wi-Fi" by showing the two as neighbours.

## Round 2 (approver verdict CHANGES, four items)
1. **Stake in title and setup.** Title now "Why doesn't Wi-Fi drown out your Bluetooth earbuds?" (reader's earbuds, premise they already feel: Wi-Fi is everywhere and strong). Setup delivers the collision in one beat: "They share the same airwaves, and Wi-Fi can be far stronger." Slide 1 no longer explains why it is a problem; it states the weak-signal puzzle and asks "where does a weak signal find room?". Titles tried are on facts.md section 1.
2. **Slide 4 lands the answer to "the music keeps playing".** Each hop carries one tiny piece of the music; a clash loses only that piece; it is sent again on a later hop; if it comes too late the music skips for a split second. Stays true to claim 9 (resend, or flush and a short glitch). I wrote "a later hop", not "the next hop on a different channel", because I found no rule that consecutive hops differ.
3. **Second mechanism cut.** "Your devices also notice which channels keep losing pieces, and skip them" is out of the main story and sits in facts.md section 7 as the Go deeper line.
4. **Spine rebuilt, one idea per slide, hooks leading into the next headline.**
   - Spine: Title (Why doesn't Wi-Fi drown out your Bluetooth earbuds?) -> hook 1 "So where does a weak signal find room?" -> headline 2 (Bluetooth uses one narrow channel at a time) -> hook 2 "But stay on one, and you could land under Wi-Fi." -> headline 3 (so Bluetooth never stays on one channel) -> hook 3 "What if a hop lands on Wi-Fi?" -> headline 4 (one lost piece does not wreck the music) -> bold line.
   - Slide 2 = radio dial + dozens of narrow channels + uses one at a time + size of Wi-Fi ("about a quarter of the dial"). The contrast is sized by a fraction instead of 79 (true of both Classic and LE; see facts claim 13). 79 is gone from the copy.
   - Slide 3 = never stays on one + the same order of channels worked out at connection + 1,600 held against a blink ("over a hundred in one blink"). Who leads and "the beat" are gone.
   - "Bluetooth's original design" is gone: "dozens of channels" and "up to 1,600" are true of Bluetooth as a whole.
   - One name for the other side: Wi-Fi.

## Claims used per slide (facts.md section 3)
[1] 2, 3 · [2] 13, 14, 6, analogy section 6 (radio dial) · [3] 8, 7, 15 · [4] 16 (claim 9) · Bold: 3, 6.
Numbers: [1] none · [2] a quarter · [3] 1,600 (plus the blink comparison) · [4] none.

## What I cut and why
Classic vs Low Energy, pairing, the name (trivia, keep for Go deeper/more card, no year), range, Lamarr, security, data rates, minimum 20 channels, the channel-skipping mechanism (to Go deeper), who leads, "the beat", the exact 79.

## Slide most likely to lose a reader
Slide 3: "they work out the same order of channels and hop through it together" (how do they work it out?). It is true (the leader's address and clock, learned at connection) but the text gives the reader no picture of it; the picture will have to show two dials turning in step. Second: slide 2's "you could land on Wi-Fi" (a quarter chance, not certain). Third: slide 3 now ends on the hook "What if a hop lands on Wi-Fi?", which pushes the paragraph to exactly 150 words; there is no room left for additions.

## Things I am least sure of
- "up to 1,600 times a second, over a hundred in one blink": at the maximum rate and a blink of 0.1 s or more, true; real rates are lower when packets are longer.
- Whether "dozens of narrow channels" is concrete enough to picture; the dial picture carries it.
- Earbud transmit power unsourced; only the class limit is, so the setup says "can be far stronger".
- "Weak signal" (slide 1) vs "stronger" (setup, bold line): same scale, deliberate.

## Cold read, round 2 (fresh agent, read only paragraph.md)
Answer back: correct (Bluetooth jumps between many narrow channels in an order both agree on, only some hops hit Wi-Fi, a blocked hop is resent). Hook check: slides 1, 2 and 3 each ended on a hook the next slide answered. Fixed: "land under Wi-Fi" read oddly (now "land on Wi-Fi", the same words as slide 4); "If it comes too late" had an unclear "it" (now "If the resend is late"). Open, not fixed (word budget is 150/150): how the earbuds know a piece was lost; why a late resend skips (a buffer); a quarter of hops landing on Wi-Fi sounds like a lot against "only that piece is lost" (true: resend recovers most; the channel-skipping in Go deeper cuts the rate; a structure call for the approver, either add the skipping back as part of slide 4 or accept); "cuts its dial" blurs the analogy (a dial is continuous); "stronger" is never said to mean power.
