// Why doesn't instant glue stick inside its own tube? 4 cards: runny for months in the tube, hard in seconds on a finger;
// superglue goes hard when water arrives (school glue when water leaves); skin and almost everything carry a thin film of
// water; a sealed tube lets none in. First topic written spine-first (2026-10-27): facts sheet, paragraph and slides in
// tasks/trial-glue/. The web diagrams are simple stand-ins until native iOS pictures exist.
(function () {
  // Card 1: a capped tube and a fingertip, each with glue. The drop on the finger goes hard; the tube stays runny.
  const tubeAndFinger = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'body', shape: 'rect', x: 14, y: 36, w: 26, h: 48, style: 'thin' },
      { id: 'neck', shape: 'path', points: [[18, 36], [24, 22], [30, 22], [36, 36]], closed: true, style: 'thin' },
      { id: 'cap', shape: 'rect', x: 21, y: 10, w: 12, h: 12 },
      { id: 'glue', shape: 'rect', x: 17, y: 54, w: 20, h: 27, style: 'thin', label: 'Runny', labelAt: [2, 28] },
      { id: 'finger', shape: 'rect', x: 62, y: 30, w: 20, h: 54, style: 'hatch' },
      { id: 'drop', shape: 'circle', x: 72, y: 26, r: 5, style: 'thin' },
      { id: 'hard', shape: 'circle', x: 72, y: 26, r: 5, style: 'accent', hidden: true, label: 'Hard', labelAt: [96, 14] },
      { id: 'tt', shape: 'text', x: 27, y: 92, text: 'In the tube' },
      { id: 'tf', shape: 'text', x: 72, y: 92, text: 'On your finger' }
    ],
    steps: [
      { note: 'Both start runny' },
      { show: ['hard'], hide: ['drop'], note: 'Finger: hard in seconds' },
      { focus: ['body', 'neck', 'cap', 'glue', 'tt'], note: 'Tube: runny for months' }
    ] };

  // Card 2: two drops. Water rises out of school glue; moisture drifts into superglue. Both go hard.
  const twoGlues = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'base', shape: 'rect', x: 4, y: 72, w: 92, h: 8, style: 'hatch' },
      { id: 'pva', shape: 'path', points: [[10, 72], [16, 58], [34, 58], [40, 72]], closed: true, smooth: true, style: 'thin' },
      { id: 'sg', shape: 'path', points: [[60, 72], [66, 58], [84, 58], [90, 72]], closed: true, smooth: true, style: 'thin' },
      { id: 'tp', shape: 'text', x: 25, y: 8, text: 'School glue' },
      { id: 'ts', shape: 'text', x: 75, y: 8, text: 'Superglue' },
      { id: 'wl', shape: 'text', x: 25, y: 90, text: 'Water leaves' },
      { id: 'wa', shape: 'text', x: 75, y: 90, text: 'Water arrives' }
    ],
    steps: [
      { note: 'Both start runny' },
      { restyle: { pva: 'ink', sg: 'accent' }, note: 'Both go hard' }
    ],
    flows: [
      { along: [[25, 58], [25, 16]], style: 'blue', count: 3, speed: 14, during: [0] },
      { along: [[75, 16], [75, 58]], style: 'blue', count: 3, speed: 14, during: [0] }
    ] };

  // Card 3: a close-up of skin with a film of water on top (drawn much thicker). A glue drop lands and goes hard.
  const skinFilm = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'skin', shape: 'rect', x: 4, y: 60, w: 92, h: 26, style: 'hatch' },
      { id: 'film', shape: 'rect', x: 4, y: 53, w: 92, h: 7, style: 'blue' },
      { id: 'tw', shape: 'text', x: 80, y: 47, text: 'Film of water' },
      { id: 'drop', shape: 'path', points: [[24, 53], [32, 36], [52, 36], [60, 53]], closed: true, smooth: true, style: 'thin', hidden: true },
      { id: 'ts', shape: 'text', x: 50, y: 93, text: 'Skin' }
    ],
    steps: [
      { note: 'Film drawn much thicker' },
      { show: ['drop'], note: 'Glue lands on the film' },
      { restyle: { drop: 'accent' }, note: 'Glue goes hard' }
    ] };

  // Card 4: the topic's one hands-on picture. Slide the cap off: moisture creeps into the tip and the glue there goes hard.
  const capOff = { type: 'diagram', view: [100, 96], scrub: true, tip: 'Slide the cap off',
    parts: [
      { id: 'body', shape: 'rect', x: 37, y: 40, w: 26, h: 50, style: 'thin' },
      { id: 'neck', shape: 'path', points: [[41, 40], [47, 24], [53, 24], [59, 40]], closed: true, style: 'thin' },
      { id: 'glue', shape: 'rect', x: 40, y: 56, w: 20, h: 31, style: 'thin', label: 'Runny glue', labelAt: [4, 74] },
      { id: 'plug', shape: 'path', points: [[45.5, 29], [47, 24], [53, 24], [54.5, 29]], closed: true, style: 'accent', hidden: true, label: 'Hard glue', labelAt: [96, 34] },
      { id: 'cap', shape: 'rect', x: 44, y: 12, w: 12, h: 12 },
      { id: 'tm', shape: 'text', x: 18, y: 8, text: 'Moisture', hidden: true }
    ],
    steps: [
      { note: 'Cap on: no water in' },
      { move: { cap: [26, -6] }, show: ['tm'], note: 'Cap off: moisture creeps in' },
      { show: ['plug'], note: 'Hard glue blocks the tip' }
    ],
    flows: [ { along: [[12, 14], [50, 26]], style: 'blue', count: 3, speed: 12, during: [1, 2] } ] };

  window.EXPLAINER = {
    id: 'superglue',
    title: 'Why doesn\'t instant glue stick inside its own tube?',
    kind: 'full',
    theme: 'nature',
    cards: [
      { type: 'card',
        title: 'It goes hard on your fingers in seconds.',
        text: 'But it can sit in its tube for months and stay runny.',
        hook: 'So what is it waiting for?',
        visual: tubeAndFinger },
      { type: 'card', title: 'Superglue goes hard when it touches water',
        text: 'White school glue goes hard as its water dries away. Superglue works the other way round. Even the moisture in the air is enough to make it go hard.',
        hook: 'So where does it find water on your fingers?',
        visual: twoGlues },
      { type: 'card', title: 'Your skin carries a thin film of water',
        text: 'It\'s too thin to feel, and almost everything around you has one too. When superglue lands on it, the glue touches water straight away. That\'s why it goes hard on your fingers in seconds.',
        hook: 'So why doesn\'t it go hard inside the tube?',
        visual: skinFilm },
      { type: 'card', title: 'A sealed tube lets no water in',
        text: 'So the glue inside just waits, runny, for months. Leave the cap off, though, and moisture from the air creeps in. The glue at the tip goes hard and blocks it.',
        takeaway: 'School glue goes hard when water leaves. Superglue goes hard when water arrives.',
        visual: capOff },
      { type: 'more', links: ['feel-wet'], note: 'What does the water actually do? It makes the glue\'s tiny building blocks hook onto each other in long chains, and long chains can\'t flow. Makers also add a tiny dash of acid that stops any chain that starts by accident.' }
    ]
  };
})();
