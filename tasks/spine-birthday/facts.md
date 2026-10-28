# Fact sheet: In a room of 23, what's the chance two share a birthday?

## 1. Is the title literally true?
Yes. It is a plain question with a plain answer: just over half (50.7%). The standard answer assumes every day of the year is equally likely and ignores 29 February; real birth data makes a match slightly more likely, so "just over half" stays true.

## 2. The answer in one sentence
A room of 23 holds 253 pairs of people, and with that many pairs the chance that at least one pair shares a birthday is just over half.

## 3. Safe claims
1. In a room of 23 people, the chance that at least two share a birthday is just over half, about 51%.
   *high, https://en.wikipedia.org/wiki/Birthday_problem (50.7%); checked by hand: 1 − 365·364·…·343 / 365^23 = 0.5073*
2. This surprising result is called the birthday paradox. It is not a real contradiction, just a true fact that sounds wrong.
   *high, https://en.wikipedia.org/wiki/Birthday_problem*
3. Every two people make a pair, and 23 people make 253 pairs.
   *high, https://www.scientificamerican.com/article/bring-science-home-probability-birthday-paradox/ ("253 comparisons"); 23 × 22 ÷ 2 = 253*
4. Of those 253 pairs, only 22 include you.
   *high, https://betterexplained.com/articles/understanding-the-birthday-paradox/*
5. Any one pair almost never matches: two people share a birthday only about 1 time in 365.
   *high, https://en.wikipedia.org/wiki/Birthday_problem*
6. In a room of 22 strangers, the chance that someone shares your birthday is less than 6%.
   *high, computed: 1 − (364/365)^22 = 5.86%; method from https://en.wikipedia.org/wiki/Birthday_problem (same birthday as you)*
7. You would need 253 strangers for a better-than-half chance that one of them shares your birthday.
   *high, https://en.wikipedia.org/wiki/Birthday_problem; 1 − (364/365)^253 = 50.05%*
8. More pairs means a higher chance of a match. Each new person makes a new pair with everyone already in the room, so pairs grow much faster than people.
   *high, https://betterexplained.com/articles/understanding-the-birthday-paradox/*
9. 57 people make 1,596 pairs, and the chance of a match is over 99%.
   *high, computed: 57 × 56 ÷ 2 = 1,596; 1 − 365·…·309 / 365^57 = 99.01%; confirmed in tasks/fact-check-round-one.md*
10. With 70 people the chance is 99.9%; with 366 people a match is certain.
    *high, https://en.wikipedia.org/wiki/Birthday_problem*
11. Real births are not spread evenly across the year, which makes a match a little more likely, not less.
    *high, https://en.wikipedia.org/wiki/Birthday_problem*
12. At the 2014 football World Cup, each of the 32 squads had 23 players, and 16 squads, half of them, had two players with the same birthday.
    *high for the count, https://en.wikipedia.org/wiki/Birthday_problem and https://longreads.com/2014/06/16/why-so-many-teams-at-the-world-cup-have-players-who-share-a-birthday/ (both from the BBC's count of FIFA squad lists, 10 June 2014). Copy says "about half".*

## 4. Myths to avoid
- **"Add up the chances: 253 pairs × 1 in 365."** That gives 69%, which is wrong. Chances of overlapping pairs don't add. So never put "1 in 365" next to "253" where the reader can divide; this is why the lottery-ticket line failed.
- **"You'd need about 183 people, half of 365."** Wrong for the room, and wrong even for your own birthday (that needs 253).
- **"In a room of 23, someone probably shares *your* birthday."** No, that's under 6%. The match is usually between two other people.
- **"It's exactly 50-50."** It's just over half, 50.7%.
- **"Many people guess 180."** No source for a specific guess. "Many people guess a small chance" is safe as framing; don't put a number on it.
- **"Paradox means it's a contradiction."** It's only a surprise. Define it once as a true fact that sounds wrong.

## 5. One good number
A room of 23 has 253 pairs, and only 22 of them include you. Everyday comparison: if all 23 shook hands once with each other, that's 253 handshakes, and you'd be in only 22 of them.
*Source: https://betterexplained.com/articles/understanding-the-birthday-paradox/*

## 6. Everyday comparisons
- **Everyone shakes hands once with everyone else.** Each handshake is one pair; 23 people make 253 handshakes, and you're in 22. Right intuition, and literally true (it is the pair count, not a stand-in). Misleads only if the reader tries to count it (each person shakes 22 hands, 23 × 22 = 506 counts each handshake twice), so give the total, never the method. **Use.**
- **253 lottery tickets, each a 1 in 365 win.** Picturable, but the obvious next thought is 253 ÷ 365 = 69%, which is wrong. Owner already rejected it. **Don't use.**
- **A coin flip.** Right for "about half", but it is a picture of the answer, not the reason, and the owner banned it from headlines. Fine to skip entirely.

## 7. Go deeper thread
At the 2014 football World Cup, each squad had 23 players, and about half the squads had two players with the same birthday. A neat twist: to get a better-than-half chance that a stranger shares *your* birthday, you need 253 strangers, the same number as the pairs in a room of 23. That's no accident: either way it's 253 pairs, each with the same small chance. Real rooms match a little more often than the maths says, because births are not spread evenly across the year.
*World Cup: high (16 of 32 squads). 253 = 253: computed, 50.05% vs 50.7%. Uneven births: high, Wikipedia.*
