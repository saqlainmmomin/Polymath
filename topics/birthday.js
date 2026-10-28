// In a room of 23, what's the chance two share a birthday? 5 cards + Go deeper note. Spine-first (2026-10-27): facts sheet, paragraph and
// slides in tasks/spine-birthday/. The iOS app draws every card natively (ios/Polymath/FlatBirthday.swift); these web diagrams are simple stand-ins.
(function () {
  const stand = label => ({ type: 'diagram', view: [100, 96], tip: false,
    parts: [{ id: 'a', shape: 'circle', x: 50, y: 44, r: 22, style: 'blue', label, labelAt: [50, 80] }], steps: [{ note: label }] });

  window.EXPLAINER = {
    id: "birthday",
    title: "In a room of 23, what's the chance two share a birthday?",
    kind: 'full',
    theme: "nature",
    cards: [
      { type: 'card',
        title: "Take a guess before you read on.",
        text: "Many people guess a small chance, but it's about 50%. A true fact that sounds wrong is called a paradox, and this one is the birthday paradox.",
        hook: "So why does 50% feel so wrong?",
        visual: stand("A room of 23 people") },
      { type: 'card',
        title: "It feels wrong because we think of our own birthday",
        text: "Walk into a room of 22 strangers, and the chance someone shares your birthday is less than 6%.",
        hook: "But does the match have to include you?",
        visual: stand("You and 22 strangers") },
      { type: 'card',
        title: "The match doesn't have to include you",
        text: "If all 23 of you shook hands once with each other, there'd be 253 handshakes. Each handshake is a pair who could share a birthday, and only 22 of them include you.",
        hook: "So what do all those pairs do to the chance?",
        visual: stand("253 handshakes") },
      { type: 'card',
        title: "More pairs means a higher chance of a match",
        text: "Any one pair almost never matches. But 253 pairs push the chance of a match to about 50%.",
        hook: "So what happens as more people walk in?",
        visual: stand("Rooms with a match") },
      { type: 'card',
        title: "Pairs pile up fast",
        text: "Each new person makes a new pair with everyone already in the room. By 57 people there are 1,596 pairs, and the chance of a match is over 99%.",
        takeaway: "Count the pairs, not the people.",
        visual: stand("People, pairs, chance") },
      { type: 'more', links: [], note: "At the 2014 football World Cup, each squad had 23 players, and about half the squads had two players with the same birthday. To get a 50% chance that a stranger shares your birthday, you'd need 253 strangers, the same number as the pairs in a room of 23. Real rooms match a little more often, because births aren't spread evenly across the year." }
    ]
  };
})();
