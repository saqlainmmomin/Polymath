// Why do you see spots after looking at a bright light? 4 cards + Go deeper note. Spine-first (2026-11-02): facts sheet,
// paragraph and slides in tasks/spine-afterimage/. Copy approved by the owner. No native iOS pictures yet; these web
// diagrams are simple stand-ins.
(function () {
  const stand = (label, note) => ({ type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'eye', shape: 'circle', x: 50, y: 44, r: 24, style: 'thin' },
      { id: 'patch', shape: 'circle', x: 66, y: 44, r: 6, style: 'accent', label, labelAt: [50, 82] }
    ],
    steps: [{ note }] });

  window.EXPLAINER = {
    id: "afterimage",
    title: "Why do you see spots after looking at a bright light?",
    kind: 'full',
    theme: "nature",
    cards: [
      { type: 'card',
        title: "The flash is over in an instant. The spot it leaves is not.",
        text: "Someone takes your photo with a flash, and for the next few seconds a dark spot floats in the middle of everything you look at. Look at the wall: it's there. Look at the floor: it's there too. But there's nothing on the wall or the floor.",
        hook: "So where is the spot?",
        visual: stand("Flash, then a dark spot", "A flash, then a dark spot on the wall and the floor") },
      { type: 'card',
        title: "A flash tires out a patch of cells in your eye",
        text: "It's in your eye. At the back of each eye is a layer of cells that turn light into signals for your brain. The flash hits a patch of those cells so hard that they get tired out. For a little while, they respond less to light than the cells around them.",
        hook: "So why does a tired patch show up as a dark spot?",
        visual: stand("Tired cells", "A flash tires out a patch of the layer of cells at the back of your eye") },
      { type: 'card',
        title: "Tired cells send weaker signals, so you see a dark spot",
        text: "Look at a plain wall. The cells around the patch send signals for the wall as usual, but the tired cells send weaker ones. Your brain gets a normal picture with a dark spot in it.",
        hook: "So why does the spot follow your eyes?",
        visual: stand("Weak signal, dark spot", "Normal cells: strong signal, tired cells: weak signal, what you see: a dark spot") },
      { type: 'card',
        title: "The spot follows your eyes because it's part of your eye",
        text: "It's tied to that part of your eye, not to anything out there. A few seconds later, when the cells recover, it fades.",
        takeaway: "The spot isn't in the room. It's a patch of your eye that got tired out by the flash.",
        visual: stand("Tied to your eye", "The spot turns with your eye, then fades as the cells recover") },
      { type: 'more', links: [], note: "Look at the spot against a far wall and it seems big; against your hand it seems small. The patch on your eye never changes size. Only your brain's guess at its size does." }
    ]
  };
})();
