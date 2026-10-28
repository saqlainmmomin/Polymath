# Fact sheet: How can your phone name a song from a few noisy seconds?

## 1. Is the title literally true?
- **"How does Shazam know what song is playing?"** True, but it breaks the plain-words rule: brand name in the title. Don't use.
- **"How can your phone name a song from a few noisy seconds?"** True. The original method was tested on 5, 10 and 15 second clips mixed with noise recorded in a pub. One small stretch: the phone makes the codes, but the matching happens on Shazam's computers, so "your phone names it" is how the reader sees it, not where the work happens. Acceptable. **Best of the four.**
- **"How does an app name a song in a noisy café?"** True, but "an app" is vague and impersonal, and it loses the "only a few seconds" surprise.
- **"How does your phone name a song it only heard for five seconds?"** Not safe. Five seconds can work, but there is no source that today's app stops at five; Wikipedia says it records about ten. Don't put a number in the title.
- **Suggested twist:** "How can your phone name a song when the room is louder than the music?" Literally true for the original method: with noise as loud as the music, a 10-second clip was named about 96 out of 100 times, and with noise louder than the music a 15-second clip still got about 94 out of 100 (Wang 2003, Figure 4). It puts the reader in a daily scene and states the surprise. Alternative: "How can your phone name a song over a café full of chatter?"

## 2. The answer in one sentence
Your phone keeps only the loudest points of the sound, turns pairs of them into short codes, and the song whose codes turn up in the same order and spacing as yours is the match.

## 3. Safe claims
(16 listed; pick 8 to 12 for the spine. All are about the original 2003 method unless marked "today".)
1. The original phone service listened for up to 30 seconds, and the method was tested on clips as short as 5 seconds.
   *high, https://en.wikipedia.org/wiki/Shazam_(music_app) (30-second hang-up, citing CNET UK 2006); Wang 2003, Section 3.1 and Figure 4 (15, 10 and 5 second clips): https://www.ee.columbia.edu/~dpwe/papers/Wang03-shazam.pdf. Do not claim an exact length for today's app; "a few seconds" is safe.*
2. First the sound is turned into a picture: time runs left to right, how high a note is runs bottom to top, and louder sounds show up brighter.
   *high, Wang 2003 Figure 1A; https://en.wikipedia.org/wiki/Spectrogram. Called a spectrogram; the word is optional.*
3. A peak is a spot in that picture that is louder than everything right around it.
   *high, Wang 2003 Section 2.1 ("higher energy content than all its neighbors").*
4. It keeps only the peaks and throws everything else away, because the loudest points are the ones most likely to survive chatter and clatter.
   *high, Wang 2003 Section 2.1.*
5. Once the peaks are picked, it forgets how loud they were and keeps only where they sit: when, and how high.
   *high, Wang 2003 Section 2.1 ("the amplitude component has been eliminated"). Wang notes the dots look like a star map.*
6. One peak on its own is just one note at one moment, and nearly every song has that note somewhere.
   *high, Wang 2003 Section 2.2 (a single peak carries "only at most 10 bits", about a thousand possible values).*
7. So it joins each peak to a few later peaks and records the pair: two notes and the time between them.
   *high, Wang 2003 Section 2.2 and Figure 1C/1D (anchor point and target zone).*
8. A pair is about a million times rarer than a single peak, so a matching pair is a real clue.
   *high, Wang 2003 Section 2.2 ("about a million times greater" specificity). This is the original method; the idea still holds.*
9. Each pair is squeezed into a short code, like a number, called a hash.
   *high, Wang 2003 Section 2.2 (each hash packed into one 32-bit number).*
10. Ahead of time, every song in the catalogue was turned into codes, and a giant list says, for each code, which songs have it and at what moment.
    *high, Wang 2003 Section 2.2 ("database index": hash, time offset, track ID, sorted by hash).*
11. In the right song, many of your codes show up in the same order and with the same spacing as in your clip; in wrong songs, matches are scattered.
    *high, Wang 2003 Section 2.3 and Figures 2 and 3 (diagonal line, offset histogram).*
12. Noise adds extra peaks and hides some real ones, but stray peaks don't line up, so the right song still wins even when most codes are lost.
    *high, Wang 2003 Sections 2.1 and 3.1.*
13. Today your phone sends Shazam only these codes, not your recording, and the sound cannot be rebuilt from them.
    *high for Apple's ShazamKit, medium for the Shazam app itself: Apple WWDC 2021 "Explore ShazamKit", https://developer.apple.com/videos/play/wwdc2021/10044/ (signature is "not invertible", "at least an order of magnitude smaller"). The 2002 phone service did send the sound itself, over the phone call.*
14. It matches one exact recording, not the tune, so it cannot name a song you hum.
    *high, Apple staff answer, https://developer.apple.com/forums/thread/682024 ("exact audio matching"); https://library.bellevue.edu/articles/jakes-tech-tools-music-identification-tools/ (a fingerprinting engine, not a humming search).*
15. A live concert is a different recording from the studio one, and the method was not built to match it.
    *high, Wang 2003 Section 3.3 ("not expected to generalize to live recordings"); Apple staff, same forum thread ("wouldn't be a good fit for recognizing live performances"). Wang adds that a few live acts matched anyway, which is why this is not "never works live".*
16. It is so exact that it can tell apart two recordings of the same song by the same singer that sound the same to people.
    *high for the original method, Wang 2003 Section 3.3 ("virtually indistinguishable by the human ear").*

## 4. Myths to avoid
- **"It listens to the words."** It never uses lyrics. Instrumental music works the same way; it only uses where the loud points sit.
- **"It recognises the melody."** It recognises one exact recording. That is why humming fails and why it can tell two takes of the same song apart. Apps that do hum-to-search use a different method; don't say "no app can do humming".
- **"It compares your clip to every song, one by one."** It looks each code up in a ready-made list, like a book's index, so it only ever checks songs that share codes with your clip.
- **"It sends your whole recording."** False today (only the codes go; Apple WWDC 2021). True only of the 2002 phone service, where Shazam heard the call itself.
- **"It needs the start of the song" / "it needs the whole song."** Any few seconds from anywhere in the song work, because each code is stored with its moment in the song.
- **"It checks millions of songs in a fraction of a second."** The catalogue is "millions of tracks" (shazam.com/company), but no source gives today's search time. The 2003 paper's speeds were on a test catalogue of about 20,000 tracks; don't reuse them for today.
- **"It works on any sound."** The song must already be in the catalogue.
- **"Five seconds."** Fine as "tested on clips as short as five seconds" for the original method; not as how long today's app listens.

## 5. One good number
In the original tests, a badly damaged 15-second clip could still be named when only 1 or 2 of every 100 codes survived the noise. Everyday comparison: like naming a book from a page where 98 of every 100 words are scribbled out, because the few left are still in the right places.
*Source: Wang 2003, Section 3.1 ("only about 1-2% of the generated hash tokens actually surviving"), https://www.ee.columbia.edu/~dpwe/papers/Wang03-shazam.pdf. Say "the original tests".*

## 6. Everyday comparisons
- **A book's index.** Look up a word, get every page it is on; look up a code, get every song and moment it is in. Right intuition for why it never reads every song. Misleads if the reader thinks one lookup finds the song: one code points at many songs, and the answer is the song where many codes point to the same spot with the same spacing. Show several lookups agreeing. **Use.**
- **A star map / join-the-dots.** Wang's own word: the peaks look like stars, and he describes laying your clip's dots on clear plastic and sliding it along the song until many dots line up. Right for the matching step, and literally how it works. Misleads if the reader thinks the shape can be stretched or rotated like spotting a constellation from a different angle; it needs the same spacing in time. Also don't imply star brightness matters (loudness is thrown away). **Use, especially the sliding clear sheet.**
- **A fingerprint.** Right for "a small mark that identifies one thing". Misleads two ways: a person has one fingerprint, but a song gives a great many tiny codes; and the obvious next thought is "it identifies the song", when it actually identifies one recording. Fine as a single word, weak as the main picture.

## 7. Go deeper thread
Before smartphone apps, Shazam started in the UK in 2002 as a phone number: you dialled 2580, held your phone up to the music, and the call hung up after 30 seconds. A few moments later a text message arrived with the song title and the singer. The digits 2, 5, 8, 0 run straight down the middle of a phone keypad, though no source says that is why they were chosen. Shazam became one of the first iPhone apps in 2008, and Apple bought it in 2018.
*2580, holding the phone up, text message: high, https://www.shazam.com/company. 30-second hang-up: medium-high, https://en.wikipedia.org/wiki/Shazam_(music_app) citing CNET UK 2006. Keypad column: true by looking; reason unsourced, so don't claim one. Apple 2018: high, https://www.apple.com/newsroom/2018/09/apple-acquires-shazam-offering-more-ways-to-discover-and-enjoy-music/*
