// How does your phone know where you are? 4 cards: it only listens, delay = distance, one/two circles, three circles = one spot.
(function () {
  // Ground: an arc (big circle top) hatched, closed across the bottom of the box.
  const arc = [];
  for (let x = 0; x <= 100; x += 5) arc.push([x, +(176 - Math.sqrt(10000 - (x - 50) * (x - 50))).toFixed(1)]);
  const ground = { id: 'ground', shape: 'path', points: arc.concat([[100, 96], [0, 96]]), closed: true, style: 'hatch' };

  // Satellite: body plus two panels, scaled by k. `extra` is merged into every piece (e.g. hidden).
  const sat = (id, x, y, k, label, labelAt, extra) => [
    Object.assign({ id: id + 'l', shape: 'rect', x: x - 9 * k, y: y - 1.5 * k, w: 5 * k, h: 3 * k, style: 'thin' }, extra || {}),
    Object.assign({ id: id + 'r', shape: 'rect', x: x + 4 * k, y: y - 1.5 * k, w: 5 * k, h: 3 * k, style: 'thin' }, extra || {}),
    Object.assign({ id: id, shape: 'rect', x: x - 4 * k, y: y - 3 * k, w: 8 * k, h: 6 * k, style: 'ink', label, labelAt }, extra || {})
  ];

  // Card 1: three satellites shout to everyone, the phone just listens.
  const broadcast = { type: 'diagram', view: [100, 96],
    parts: [
      ground,
      ...sat('a', 18, 18, 1.3, 'Satellite', [2, 5]), ...sat('b', 50, 10, 1.3), ...sat('c', 82, 18, 1.3),
      { id: 'ph', shape: 'rect', x: 44, y: 56, w: 12, h: 20, style: 'accent', label: 'Phone', labelAt: [98, 66] },
      { id: 'none', shape: 'text', x: 27, y: 68, text: 'No reply', hidden: true }
    ],
    steps: [
      { note: 'Satellites shout to everyone' },
      { focus: ['ph', 'ground', 'none'], show: ['none'], note: 'Your phone only listens' }
    ],
    flows: [
      { along: [[22, 25], [45, 54]], style: 'spark', count: 3, speed: 15 },
      { along: [[50, 18], [50, 54]], style: 'spark', count: 3, speed: 15 },
      { along: [[78, 25], [55, 54]], style: 'spark', count: 3, speed: 15 },
      { along: [[46, 20], [12, 52]], style: 'spark', count: 3, speed: 15 },
      { along: [[54, 20], [88, 52]], style: 'spark', count: 3, speed: 15 }
    ] };

  // Card 2: the pulse takes a moment to arrive, and that moment is a distance.
  const delay = { type: 'diagram', view: [100, 96],
    parts: [
      ground,
      ...sat('s', 50, 12, 1.4, 'Overhead', [98, 8]),
      { id: 'ph', shape: 'rect', x: 44, y: 56, w: 12, h: 20, style: 'accent' },
      { id: 'ts', shape: 'text', x: 78, y: 28, text: 'Sent 0.00 s' },
      { id: 'ta', shape: 'text', x: 79, y: 52, text: 'Arrives 0.07 s', hidden: true },
      { id: 'dist', shape: 'arrow', from: [38, 22], to: [38, 54], style: 'thin', hidden: true },
      { id: 'dt', shape: 'text', x: 20, y: 38, text: 'About 20,000 km', hidden: true },
      { id: 'pulse', shape: 'circle', x: 50, y: 22, r: 3, style: 'spark' }
    ],
    steps: [
      { note: 'A signal leaves the satellite' },
      { move: { pulse: [0, 31] }, hide: ['ts'], show: ['ta'], note: 'It lands a flicker later' },
      { show: ['dist', 'dt'], focus: ['dist', 'dt', 'pulse', 'ta'], note: 'A distance, but not yet a place' }
    ] };

  // Cards 3 and 4 share one flat picture: rings around three satellites, all crossing at one spot.
  const ring = (cx, cy, r) => {
    const pts = [];
    for (let a = 0; a <= 330; a += 15) pts.push([+(cx + r * Math.cos(a * Math.PI / 180)).toFixed(1), +(cy + r * Math.sin(a * Math.PI / 180)).toFixed(1)]);
    return pts;
  };
  // dx shifts the whole picture sideways (card 3 shows only two circles, so it is centred differently).
  const ringParts = (dx, hideB, hideC, label) => [
    { id: 'rA', shape: 'circle', x: 50 + dx, y: 28, r: 26, style: 'blue', fill: false },
    { id: 'rB', shape: 'circle', x: 27.5 + dx, y: 67, r: 26, style: 'blue', fill: false, hidden: hideB },
    { id: 'rC', shape: 'circle', x: 72.5 + dx, y: 67, r: 26, style: 'blue', fill: false, hidden: hideC },
    ...sat('a', 50 + dx, 28, 1.2, label ? 'Satellite' : undefined, label ? label : undefined),
    ...sat('b', 27.5 + dx, 67, 1.2, undefined, undefined, { hidden: hideB }),
    ...sat('c', 72.5 + dx, 67, 1.2, undefined, undefined, { hidden: hideC })
  ];

  const circle1 = { type: 'diagram', view: [100, 96],
    parts: [
      ...ringParts(11, true, true, [2, 16]),
      { id: 'x1', shape: 'dot', x: 61, y: 54, r: 2.6, style: 'ink', hidden: true },
      { id: 'x2', shape: 'dot', x: 38.5, y: 41, r: 2.6, style: 'ink', hidden: true }
    ],
    steps: [
      // Step 0 parks the first circle mid-panel so the lone picture fills it; step 1 moves it home and adds the second.
      { move: { rA: [-11, 20], al: [-11, 20], ar: [-11, 20], a: [-11, 20] }, note: 'Flat map: a circle of spots' },
      { move: { rA: [0, 0], al: [0, 0], ar: [0, 0], a: [0, 0] }, show: ['rB', 'bl', 'br', 'b', 'x1', 'x2'], note: 'Two circles cross in two spots' }
    ],
    flows: [{ along: ring(50, 48, 26), style: 'accent', count: 3, speed: 22, during: [0] }] };

  const circle3 = { type: 'diagram', view: [100, 96],
    parts: [
      ...ringParts(0, false, true, [98, 10]),
      { id: 'x1', shape: 'dot', x: 50, y: 54, r: 2.6, style: 'ink' },
      { id: 'x2', shape: 'dot', x: 27.5, y: 41, r: 2.6, style: 'ink' },
      { id: 'you', shape: 'circle', x: 50, y: 54, r: 4, style: 'accent', hidden: true, label: 'You', labelAt: [98, 44] }
    ],
    steps: [
      { note: 'Flat map: two circles, two spots' },
      { show: ['rC', 'cl', 'cr', 'c'], focus: ['rC', 'cl', 'cr', 'c', 'x1', 'x2'], note: 'A third circle joins in' },
      { show: ['you'], hide: ['x1', 'x2'], note: 'Only one spot fits all three' }
    ] };

  window.EXPLAINER = {
    id: 'gps',
    title: 'How does your phone know exactly where you are?',
    kind: 'full',
    theme: 'internet',
    cards: [
      { type: 'card',
        title: 'Strangely, it never calls a single satellite.',
        text: 'Satellites circle Earth about 20,000 km up, each announcing where it is and when it spoke. Your phone\'s GPS chip only listens.',
        visual: broadcast },
      { type: 'card', title: 'How late the message is tells the distance',
        text: 'Each message is stamped with its send time. Your phone times the delay and multiplies by light speed, about 300,000 km a second. So 0.07 seconds means about 20,000 km.',
        visual: delay },
      { type: 'card', title: 'One distance is a circle. Two give two spots.',
        text: 'On a flat map, one distance means you could be anywhere that far from the satellite. That is a circle. A second satellite adds a circle that crosses it in two spots.',
        visual: circle1 },
      { type: 'card', title: 'A third circle picks the right spot',
        text: 'A third satellite, not in line with the first two, has a circle that misses the other spot. Only one spot fits all three.', takeaway: 'That spot is you.',
        visual: circle3 },
      { type: 'more', links: ['card-payment'], note: "An error of just a thousandth of a second would mean a 300 km mistake, so timing must be exact. Real GPS works in 3D, and a fourth satellite lets your phone solve for its own clock error." }
    ]
  };
})();
