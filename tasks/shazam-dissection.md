# Shazam: what is the reader really asking? (dissection v2, 2026-10-25)

Fresh topic, chosen because it's a feature people use, the "how is that even possible?" is built in, and it stands alone in a random feed.
v2 restructures the cards after the owner read Per Thirty Six's interactive explainer (https://perthirtysix.com/how-the-heck-does-shazam-work). The v1 anchor points stay. v2 fills the gaps the owner hit when reading v1.

## 1. The title
**"How does Shazam know what song is playing?"** (8 words, ends `?`, literally true; brand allowed because it's what people say.)

## 2. What a reader is really wondering (ranked)
| Rank | The reader's real question | Felt it? | Answer in one line |
|---|---|---|---|
| 1 | "How does it pick one song out of millions, in seconds?" | Yes, every use | It turns sound into a few codes, then looks each code up like a word in a book's index. |
| 2 | "How does it work in a loud bar with people talking?" | Yes | It only keeps the loudest spots, and it needs only a few codes to agree. |
| 3 | "Why can't it find the song when I hum it?" | Yes | Your hum makes different codes. It knows exact recordings, not tunes. |
| 4 | "Why doesn't it work at a concert?" | Some | Same reason, which is how its makers caught singers miming. |

**What v1 left unclear (owner's reading) and how v2 fixes it**
| Gap in v1 | Why it mattered | v2 fix |
|---|---|---|
| "Loudest blip" was never explained | The reader can't picture a blip of what | New card 2: every sound is a stack of pitches, shown as a picture where height = pitch and brightness = loudness. A "blip" = a bright spot on that picture. |
| How sound turns into a map was skipped | The star map arrived from nowhere | Card 2 builds the picture; card 3 keeps only the brightest spot in each patch. |
| Noise was asserted, not shown | "Chatter adds stars" was just a claim | Card 3 shows faint room noise losing to the music's bright spots; card 5 shows stray codes being outvoted. |
| Pairs/codes (hashing) were missing | Without them, "index" makes no sense | New card 4: one star is common, but two stars plus the gap between them make a near-unique code. |
| The reverse search was vague ("an index") | It's the real answer to "millions in seconds" | Card 5: look up the code, not the song. Then the timing check confirms it. |

## 3. Shape
Wonder → what sound looks like → throw almost all of it away → pairs make codes → look the code up, not the song → payoff.
Each step is one thing the article animates, in the article's order, with one idea per card. 6 content cards (the maximum).
The counterintuitive moment (card 3: it gets *better* by throwing away almost everything) and the big "ohh" (card 5: reverse lookup) both sit in the middle, not at the end.

## 4. Card spine (draft copy, about 30 words each)

**Card 1. Opener.** Headline: the title. Setup line: *"A noisy bar. A few seconds. One song out of millions."*
> Hold up your phone and it names the song in seconds. The trick is that it throws away almost everything it hears. To see what it keeps, first look at a sound.
- Picture: sound waves pour into the phone, then thin out to a few bright dots.
- Numbers: 0 in the text. Words: 32.

**Card 2. What a sound looks like (fixes "what's a blip?").** Headline: **Every sound is a stack of notes**
> Your phone splits each split-second of sound into its pitches, like the bouncing bars on a stereo. Line those moments up and you get a picture: low notes bottom, high notes top, louder is brighter.
- Picture (touchable, one thing): tap "Note" or "Chord". One note draws one bright stripe; a chord draws several stacked stripes, scrolling left as time passes.
- Fact: a spectrogram plots time across, pitch up, and loudness as brightness. Numbers: 0. Words: 34, trim.

**Card 3. Throw almost all of it away (counterintuitive; noise shown).** Headline: **Then it keeps only the brightest spots**
> In each small patch of the picture, only the brightest point survives. Faint room noise rarely wins a patch. What's left looks like stars in a night sky, and every recording has its own.
- Picture (touchable): a slider "Raise the bar". Faint smudges vanish and bright points stay as stars. Grey noise speckles disappear first.
- Fact: the paper calls these sparse peaks "constellation maps" because they "resemble a star field". Numbers: 0. Words: 33, trim.

**Card 4. Pairs make codes (hashing, plus why humming fails).** Headline: **One star is common. Two make a code.**
> Thousands of songs share a single note. So Shazam pairs each star with a few just after it: this pitch, then that pitch, this far apart. Your hum makes different pairs, so it misses.
- Picture (touchable): tap a star to make it the anchor. A box lights up to its right, lines join it to each star inside, and each line shows a short code tag.
- Fact: each hash is two frequencies plus the time gap. Covers and singing produce different peaks. Numbers: 0. Words: 33.

**Card 5. The big "ohh": reverse lookup, timing check and noise.** Headline: **It looks up the code, not the song**
> Like a word in a book's index, each code points to the few songs that contain it. The song whose codes also line up in time wins, even if only one or two in a hundred survive the noise.
- Picture (touchable, one toggle): "Song by song" shows a pointer crawling through a shelf of songs; "Code first" shows codes jumping straight to two or three songs, with one song's tally racing ahead.
- Facts: an inverted index of hashes to tracks; the time-offset agreement confirms the match; about 1-2% of hashes surviving is enough. Numbers: 1. Words: 37, the densest card. If it won't trim, move "even if... noise" into the picture caption.

**Card 6. Payoff.** Headline: **So at a concert, a match is suspicious**
> Live music makes brand-new stars, so it shouldn't match the record. Yet Shazam's makers found some concert singers matching perfectly. Their polite guess was miming.
- Takeaway: **It matches a recording's stars, not its tune.**
- Picture: a stage, a phone lighting "Match!", and a winking mouth.
- Numbers: 0. Words: 25 + 8.

**More.** Note:
> In 2002 Shazam wasn't an app. You dialled 2580, held your phone to the speaker, and a text arrived with the song's name.
- `links`: any non-music topic.

## 5. What this asks of the build
- Four new interactive pictures (cards 2-5) in the article's style. The current `diagram` block can fake 3 and 4 with steps, but 2 (live note/chord stripes) and 5 (toggle plus tally) need a custom visual type, like the gearbox flagship had. Estimate: one visual agent before the writer.
- Microphone input (the article lets you hum into it) would be a delight, but it needs mic permission and goes against the "untouched animation still makes sense" rule. Leave it out for now.
- Every card needs a word trim: cards 1, 2, 3 and 5 run 32-37 words.

## 6. Checks
- Cover test: stack of notes ✔ (you can't guess "stereo bars", or that brightness means loudness); keeps only the brightest ✔ (raises "why throw it away?"); two make a code ✔; looks up the code, not the song ✔ (raises "what does that mean?"); concert match suspicious ✔.
- Words defined in the topic: pitch, stack, star, code, index. No "spectrogram", "hash" or "FFT" in reader text.
- Card 5's headline "the code, not the song" brushes the RECIPE's "no not X but Y" rule. Alternative: **"It starts from the code and works back."**

## 7. Sources (opened)
| Claim | Source |
|---|---|
| Waveform → frequencies per slice; spectrogram axes (time, frequency, brightness = loudness); threshold keeps loudest peaks; anchor + target zone → hash of two frequencies plus time gap; inverted index (hash-first) vs song-first; time-gap agreement confirms; singing/covers make different peaks | Per Thirty Six, "How the heck does Shazam work?": https://perthirtysix.com/how-the-heck-does-shazam-work |
| "Constellation maps" that "resemble a star field"; transparent-plastic sliding analogy; pairs hashed with time offset; a match with "only about 1-2%" of hashes surviving; works through voices, traffic and other music | Avery Wang, "An Industrial-Strength Audio Search Algorithm" (Shazam, 2003): https://www.ee.columbia.edu/~dpwe/papers/Wang03-shazam.pdf |
| "Not expected to generalize to live recordings"; concert matches "more plausibly lip synching"; picks between performances "virtually indistinguishable by the human ear" | Same paper, §3.3 |
| 2002 UK launch; dial 2580, hold phone to speaker, text with title and artist | https://www.stereonet.com/features/2580-shazams-first-killer-app-was-a-phone-call |

**Unverified, for the fact checker:**
- Whether today's app handles humming or live music any better. The paper is from 2003, and the copy keeps that in the past tense ("Shazam's makers found").
- "Only the brightest point in each patch survives" simplifies the paper's peak picking: a point is kept if it is louder than its neighbours, with a density rule for even coverage. Fine for a reader, but the checker should agree.
- "Faint room noise rarely wins a patch": the article says this. In a really loud bar, chatter *does* win some patches, which is why card 5's voting matters. The two cards together are honest; card 3 alone overclaims slightly.
