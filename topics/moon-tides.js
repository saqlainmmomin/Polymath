// How does the Moon move the oceans? 6 cards + 1 bridge: the tide on a beach; the Moon's pull makes one bulge; the pull
// gets weaker across Earth, so a second bulge is left behind; Earth spins through both (two high tides a day);
// bridge: high tide is about 50 minutes later each day; the Sun adds or works against the Moon (spring tides); the coast's shape.
// Copy approved by the owner 2026-10-25 (.claude/skills/write-explainer/examples/moon-tides.md), fact checked 2026-10-25.
// The iOS app draws every card natively (ios/Polymath/FlatTides.swift); these web diagrams are simple stand-ins.
(function () {
  const beach = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'moon', shape: 'circle', x: 20, y: 16, r: 5, style: 'spark' },
      { id: 'sand', shape: 'path', points: [[0, 50], [100, 86], [100, 96], [0, 96]], closed: true, style: 'hatch' },
      { id: 'sea', shape: 'path', points: [[0, 50], [40, 64], [0, 64]], closed: true, style: 'blue', label: 'Low tide', labelAt: [98, 40] }
    ],
    steps: [
      { note: 'Low tide' },
      { move: { moon: [60, 0], sea: [0, -6] }, note: 'High tide' }
    ] };

  const pull = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'sea', shape: 'circle', x: 34, y: 48, r: 26, style: 'blue' },
      { id: 'earth', shape: 'circle', x: 34, y: 48, r: 22, style: 'green' },
      { id: 'moon', shape: 'circle', x: 88, y: 48, r: 7, style: 'thin' },
      { id: 'g', shape: 'arrow', from: [60, 48], to: [78, 48], style: 'accent', hidden: true, label: 'Gravity', labelAt: [98, 70] }
    ],
    steps: [{ note: 'Water is free to flow' }, { show: ['g'], move: { sea: [4, 0] }, note: 'One bulge toward the Moon' }] };

  const two = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'sea', shape: 'circle', x: 40, y: 48, r: 27, style: 'blue' },
      { id: 'earth', shape: 'circle', x: 40, y: 48, r: 22, style: 'green' },
      { id: 'moon', shape: 'circle', x: 92, y: 48, r: 6, style: 'thin' },
      { id: 'a', shape: 'arrow', from: [62, 48], to: [80, 48], style: 'accent', label: 'Pulls most', labelAt: [98, 30] },
      { id: 'b', shape: 'arrow', from: [40, 48], to: [50, 48], style: 'accent' },
      { id: 'c', shape: 'arrow', from: [18, 48], to: [23, 48], style: 'accent', label: 'Pulls least', labelAt: [2, 84] }
    ],
    steps: [{ note: 'Near side, middle, far side' }, { note: 'Far water is left behind' }] };

  const spin = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'sea', shape: 'path', points: [[12, 48], [40, 30], [68, 48], [40, 66]], closed: true, smooth: true, style: 'blue' },
      { id: 'earth', shape: 'circle', x: 40, y: 48, r: 16, style: 'green' },
      { id: 'beach', shape: 'dot', x: 40, y: 32, r: 2.5, style: 'accent', label: 'Your beach', labelAt: [98, 14] },
      { id: 'moon', shape: 'circle', x: 92, y: 48, r: 5, style: 'thin' }
    ],
    steps: [{ note: 'Low tide' }, { move: { beach: [16, 16] }, note: 'High tide' }] };

  const sun = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'sun', shape: 'circle', x: 6, y: 48, r: 10, style: 'spark' },
      { id: 'sea', shape: 'path', points: [[34, 48], [52, 38], [70, 48], [52, 58]], closed: true, smooth: true, style: 'blue' },
      { id: 'earth', shape: 'circle', x: 52, y: 48, r: 12, style: 'green' },
      { id: 'moon', shape: 'circle', x: 88, y: 48, r: 5, style: 'thin' }
    ],
    steps: [{ note: 'In a line: bigger tides' }, { move: { moon: [-36, -38] }, note: 'Not in a line: smaller' }] };

  const coast = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'open', shape: 'rect', x: 6, y: 70, w: 38, h: 6, style: 'blue', label: 'Open ocean', labelAt: [4, 60] },
      { id: 'bay', shape: 'rect', x: 56, y: 30, w: 38, h: 46, style: 'blue', label: 'Bay of Fundy', labelAt: [96, 20] },
      { id: 'ground', shape: 'rect', x: 0, y: 76, w: 100, h: 20, style: 'hatch' }
    ],
    steps: [{ note: 'Under 1 m out at sea' }, { note: 'About 16 m in a funnel bay' }] };

  window.EXPLAINER = {
    id: 'moon-tides',
    title: 'How does the Moon move the oceans?',
    kind: 'full',
    theme: 'nature',
    cards: [
      { type: 'card',
        title: 'Twice a day, the sea comes in and goes out again.',
        text: 'Stand on a beach for a few hours. The water slowly creeps up the sand. Later, it slowly slides back down. This rise and fall is called the tide. It happens on every coast on Earth. The cause is about 384,000 kilometres away, up in the sky.',
        visual: beach },
      { type: 'card', title: 'The Moon pulls on the ocean',
        text: 'Everything in space pulls on everything else, and this pull is called gravity. The Moon\'s gravity pulls on Earth. Rock is stiff, so it hardly moves. Water is free to flow. So the ocean slides a little toward the Moon. It makes a bulge of water on the side facing the Moon. But Earth actually has two bulges.',
        visual: pull },
      { type: 'card', title: 'The ocean bulges on both sides',
        text: 'The Moon pulls hardest on the side of Earth closest to it. It pulls less on Earth\'s middle. It pulls least on the far side. So the near water moves toward the Moon the most. The far water moves the least, so it gets left behind. That makes a second bulge, on the far side. Next, Earth spins underneath these two bulges.',
        visual: two },
      { type: 'card', title: 'Earth spins through both bulges every day',
        text: 'Earth turns around once a day. Your beach passes through both bulges as it turns. Inside a bulge, the water is high, so it is high tide. Between the bulges, the water is low, so it is low tide. So most beaches get two high tides and two low tides each day. But some days, the high tides are much higher. Something else is pulling too.',
        visual: spin },
      { type: 'bridge',
        text: 'The Moon also moves along its path around Earth. So your beach needs a little extra time to catch up with each bulge. That is why high tide comes about 50 minutes later every day. The Moon is not the only thing in the sky that pulls on the sea.' },
      { type: 'card', title: 'The Sun pulls on the oceans too',
        text: 'The Sun is huge, but it is very far away. Its pull on the tides is a bit less than half the Moon\'s. At full moon and new moon, the Sun and Moon line up. Their pulls add together, and tides get bigger. These are called spring tides, and they have nothing to do with the season. Even so, the bulge is small out at sea. So why do some beaches get giant tides?',
        visual: sun },
      { type: 'card', title: 'The shape of the coast makes tides bigger',
        text: 'Out in the open ocean, the bulge is less than a metre high. Near land, the coast changes it. A long, narrow bay squeezes the water like a funnel, so it piles up higher. In Canada\'s Bay of Fundy, the sea can rise and fall about 16 metres. That is taller than a four-storey building.',
        takeaway: 'Wind makes waves. The Moon lifts the whole ocean, twice a day.',
        visual: coast },
      { type: 'more', links: ['sky-blue'], note: 'The Moon pulls on rock too. Twice a day, the ground under your feet rises and falls by up to about 30 centimetres. You never feel it, because everything around you moves with it.' }
    ]
  };
})();
