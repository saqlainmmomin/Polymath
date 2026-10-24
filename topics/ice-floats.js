// Why ice floats. Card 1 = a cube floats while a stone sinks; card 2 = water pieces lock into roomy rings; card 3 = a full bottle cracks (same water, more room), so a glass of ice is lighter than a glass of water.
(function () {
  const r1 = n => Math.round(n * 10) / 10;

  // Card 1: glass of water, an ice cube floating (about 9/10 under), a stone on the bottom.
  const glass = { type: 'diagram', view: [120, 96],
    parts: [
      { id: 'wat', shape: 'rect', x: 38, y: 34, w: 62, h: 54, style: 'blue', label: 'Water', labelAt: [118, 62] },
      { id: 'stone', shape: 'circle', x: 90, y: 79, r: 7.5, style: 'hatch', label: 'Stone', labelAt: [118, 82] },
      { id: 'cube', shape: 'rect', x: 52, y: 30.6, w: 34, h: 34, style: 'accent', label: 'Ice', labelAt: [118, 20] },
      { id: 'br', shape: 'line', from: [33, 34], to: [33, 64.6], style: 'thin', hidden: true },
      { id: 'g1', shape: 'line', from: [30, 34], to: [38, 34], style: 'thin', hidden: true },
      { id: 'g2', shape: 'line', from: [33, 64.6], to: [52, 64.6], style: 'thin', dash: true, hidden: true },
      { id: 't1', shape: 'text', x: 16, y: 46, text: 'About', hidden: true },
      { id: 't2', shape: 'text', x: 16, y: 53, text: '9/10 under', hidden: true },
      { id: 'glass', shape: 'path', points: [[38, 6], [38, 88], [100, 88], [100, 6]], fill: false }
    ],
    steps: [
      { note: 'The stone sinks. The ice floats.' },
      { show: ['br', 'g1', 'g2', 't1', 't2'], focus: ['cube', 'wat', 'br', 'g1', 'g2', 't1', 't2'], note: 'Most of the ice sits underwater' }
    ] };

  // Card 2: 32 water pieces. Water = tight and jostling; ice = honeycomb rings with a hole in the middle of each.
  const R = 5.3, B = 11.5, W3 = Math.sqrt(3) * B;
  const iceRaw = [];
  for (let j = 0; j < 4; j++) for (let i = 0; i < 4; i++) {
    const ax = i * W3 + (j % 2) * W3 / 2, ay = j * 1.5 * B;
    iceRaw.push([ax, ay], [ax, ay + B]);
  }
  const ex = iceRaw.map(p => p[0]), ey = iceRaw.map(p => p[1]);
  const ox = 50 - (Math.min(...ex) + Math.max(...ex)) / 2, oy = 52 - (Math.min(...ey) + Math.max(...ey)) / 2;
  const ice = iceRaw.map(p => [p[0] + ox, p[1] + oy]).sort((a, b) => a[1] - b[1] || a[0] - b[0]);
  // enclosed hexagon centres = the gaps
  const holes = [];
  for (let j = 0; j < 4; j++) for (let i = 0; i < 4; i++) {
    const c = [i * W3 + (j % 2) * W3 / 2 + W3 / 2 + ox, j * 1.5 * B + B / 2 + oy];
    if (ice.filter(p => Math.hypot(p[0] - c[0], p[1] - c[1]) < B * 1.05).length === 6) holes.push([r1(c[0]), r1(c[1])]);
  }
  // water: hex-packed rows 5,6,5,6,5,5, nudged a little
  const D = 12.2, water = [];
  [5, 6, 5, 6, 5, 5].forEach((n, row) => {
    for (let k = 0; k < n; k++) water.push([50 + (k - (n - 1) / 2) * D, 52 + (row - 2.5) * D * 0.866]);
  });
  water.forEach((p, i) => { p[0] += 0.8 * Math.sin(i * 12.99); p[1] += 0.8 * Math.cos(i * 7.82); });
  water.sort((a, b) => a[1] - b[1] || a[0] - b[0]);

  const parts = [
    { id: 'frame', shape: 'rect', x: 6, y: 12, w: 88, h: 80, style: 'thin', fill: false },
    { id: 'tw', shape: 'text', x: 50, y: 6, text: 'Water, zoomed way in' },
    { id: 'ti', shape: 'text', x: 50, y: 6, text: 'Ice, zoomed way in', hidden: true }
  ];
  const s1 = {}, s2 = {};
  water.forEach((p, i) => {
    parts.push({ id: 'm' + i, shape: 'circle', x: r1(p[0]), y: r1(p[1]), r: R, style: 'blue' });
    s1['m' + i] = [r1(2.2 * Math.sin(i * 5.3 + 1)), r1(2.2 * Math.cos(i * 3.7 + 2))];
    s2['m' + i] = [r1(ice[i][0] - p[0]), r1(ice[i][1] - p[1])];
  });
  const gapIds = holes.map((h, k) => {
    parts.push({ id: 'g' + k, shape: 'circle', x: h[0], y: h[1], r: 4, style: 'accent', hidden: true });
    return 'g' + k;
  });
  const rings = { type: 'diagram', view: [100, 96], parts,
    steps: [
      { note: 'Water: packed close together' },
      { move: s1, note: 'The pieces keep sliding past' },
      { move: s2, hide: ['tw'], show: ['ti', ...gapIds], note: 'Ice: locked in rings, with gaps' }
    ] };

  // Card 3: a full, capped bottle. Freeze it: the ice needs more room, pushes the cap up and cracks the wall.
  const bot = [[43, 14], [43, 26], [24, 40], [24, 90], [76, 90], [76, 40], [57, 26], [57, 14]];
  const grow = bot.map(p => [r1(50 + (p[0] - 50) * 1.075), r1(90 + (p[1] - 90) * 1.075)]);
  const bottle = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'wat', shape: 'path', points: bot, closed: true, style: 'blue', label: 'Water', labelAt: [98, 66] },
      { id: 'ice', shape: 'path', points: grow, closed: true, style: 'accent', hidden: true, label: 'Ice', labelAt: [98, 66] },
      { id: 'jar', shape: 'path', points: bot, fill: false },
      { id: 'cap', shape: 'rect', x: 39, y: 8, w: 22, h: 6, style: 'hatch' },
      { id: 'crack', shape: 'path', points: [[24, 68], [19, 74], [25, 80], [19, 86]], style: 'thin', hidden: true },
      { id: 'pl', shape: 'arrow', from: [34, 52], to: [6, 52], hidden: true },
      { id: 'pr', shape: 'arrow', from: [66, 52], to: [94, 52], hidden: true }
    ],
    steps: [
      { note: 'A bottle filled to the top' },
      { hide: ['wat'], show: ['ice', 'crack', 'pl', 'pr'], move: { cap: [0, -7] }, note: 'Frozen: it needs more room' }
    ] };

  window.EXPLAINER = {
    id: 'ice-floats',
    title: 'Why does ice float on the very water it came from?',
    kind: 'full',
    theme: 'nature',
    cards: [
      { type: 'card',
        text: 'Most solids sink in their own melted liquid. Ice is the odd one out: a cube bobs on its own water, mostly hidden below. What did freezing change?',
        visual: glass },
      { type: 'card', title: 'Frozen water locks into roomy rings',
        text: 'Water is made of tiny pieces that slide past each other. Freeze it and they lock into six-sided rings. The gaps are extra room, so ice takes up more space.',
        visual: rings },
      { type: 'card', title: 'The same water takes more room as ice',
        text: 'A full bottle cracks when frozen: ice takes about a tenth more room. So a glass of ice weighs less than a glass of water, and the heavier water holds it up.',
        visual: bottle },
      { type: 'more', links: ['sky-blue'], note: 'Because ice floats, lakes freeze from the top down. The water underneath stays liquid, so fish can survive the winter.' }
    ]
  };
})();
