// Why is it summer when Earth is farthest from the Sun? 5 cards + Go deeper note. Spine-first (2026-10-27): facts sheet,
// paragraph and slides in tasks/spine-seasons/. Copy approved by the owner. The iOS app draws every card natively with
// hand-drawn pictures (ios/Polymath/FlatSeasons.swift); these web diagrams are simple stand-ins.
(function () {
  const stand = (label, note) => ({ type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'sun', shape: 'circle', x: 50, y: 44, r: 12, style: 'spark' },
      { id: 'earth', shape: 'circle', x: 82, y: 44, r: 7, style: 'blue', label, labelAt: [50, 82] }
    ],
    steps: [{ note }] });

  window.EXPLAINER = {
    id: "seasons",
    title: "Why is it summer when Earth is farthest from the Sun?",
    kind: 'full',
    theme: "nature",
    cards: [
      { type: 'card',
        title: "Summer feels like the Sun has come closer.",
        text: "But in early July, while Europe and the USA have summer, Earth is at its farthest from the Sun. In early January, in their winter, it's at its closest.",
        hook: "So is it much farther away in July than in January?",
        visual: stand("July: farthest", "July: farthest, January: closest") },
      { type: 'card',
        title: "Earth is only about 3 percent farther in July than in January",
        text: "And when Australia has summer, Canada has winter, at the same distance from the Sun. So distance can't be it.",
        hook: "So if it isn't distance, what is it?",
        visual: stand("100 steps or 103 steps", "January: 100 steps, July: 103 steps") },
      { type: 'card',
        title: "Each half of Earth takes a turn leaning toward the Sun",
        text: "Earth leans about 23 degrees from upright, like a classroom globe, and the lean always points toward the same faraway spot. So in June the north half leans toward the Sun, and in December, on the other side of its trip, it leans away. The south half does the opposite.",
        hook: "But why would leaning toward the Sun make it warmer?",
        visual: stand("The lean never turns", "June: north leans in, December: north leans away") },
      { type: 'card',
        title: "Leaning toward the Sun packs its light into a smaller patch",
        text: "Shine a torch straight down at a table and you get a small, bright spot. Tilt it, and the same light spreads into a long, dim patch. The half leaning toward the Sun gets light more like the straight beam, so each bit of ground warms more.",
        hook: "Does the lean change anything else?",
        visual: stand("Torch over a table", "Straight: small bright spot, tilted: long dim patch") },
      { type: 'card',
        title: "The lean also makes summer days longer",
        text: "It puts more of that half on the sunny side as Earth spins. In London, a June day is about twice as long as a December one.",
        takeaway: "Summer doesn't come when Earth is closer to the Sun. It comes when your half leans toward it.",
        visual: stand("Day and night", "London: long day in June, short day in December") },
      { type: 'more', links: [], note: "At the North Pole, the Sun stays up for about six months, then come months of twilight and dark. The same lean does it." }
    ]
  };
})();
