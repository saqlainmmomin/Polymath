// How does your phone know where you are? 5 cards: it only listens, late thunder = far storm, signal delay = distance, one ring, rings meet at one spot.
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

  // Card 1 scene: three satellites shout the time in every direction, the phone only listens (spark dots travel down to it, none leave it).
  const broadcast = { type: 'diagram', view: [100, 96],
    parts: [
      ground,
      ...sat('a', 18, 18, 1.3, 'Satellite', [2, 5]), ...sat('b', 50, 10, 1.3), ...sat('c', 82, 18, 1.3),
      { id: 'ph', shape: 'rect', x: 44, y: 56, w: 12, h: 20, style: 'accent', label: 'Phone', labelAt: [98, 66] },
      { id: 'none', shape: 'text', x: 27, y: 68, text: 'No reply', hidden: true }
    ],
    steps: [
      { note: 'Satellites shout the time' },
      { focus: ['ph', 'ground', 'none'], show: ['none'], note: 'Your phone only listens' }
    ],
    flows: [
      { along: [[22, 25], [45, 54]], style: 'spark', count: 3, speed: 15 },
      { along: [[50, 18], [50, 54]], style: 'spark', count: 3, speed: 15 },
      { along: [[78, 25], [55, 54]], style: 'spark', count: 3, speed: 15 },
      { along: [[46, 20], [12, 52]], style: 'spark', count: 3, speed: 15 },
      { along: [[54, 20], [88, 52]], style: 'spark', count: 3, speed: 15 }
    ] };

  // Card 2 scene: storm cloud left, you right. A bolt flashes at once (spark), then a blue sound wave crawls along the ground and reaches you late. Takeaway image: the long gap between flash and boom, "3 s = about 1 km".
  const thunder = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'gr', shape: 'rect', x: 0, y: 86, w: 100, h: 10, style: 'hatch' },
      { id: 'cloud', shape: 'path', points: [[4, 24], [6, 14], [16, 10], [24, 6], [34, 12], [42, 16], [42, 26], [30, 30], [14, 30]], closed: true, smooth: true, style: 'thin' },
      { id: 'bolt', shape: 'path', points: [[22, 30], [17, 46], [25, 48], [15, 84]], style: 'spark' },
      { id: 'me', shape: 'rect', x: 80, y: 66, w: 6, h: 20, style: 'accent', label: 'You', labelAt: [98, 58] },
      { id: 'tb', shape: 'text', x: 55, y: 48, text: 'Boom, 3 s later', hidden: true },
      { id: 'tk', shape: 'text', x: 55, y: 62, text: '3 s = about 1 km', hidden: true }
    ],
    steps: [
      { note: 'The flash reaches you at once' },
      { show: ['tb'], note: 'The boom is slow, so it is late' },
      { show: ['tk'], hide: ['tb'], focus: ['tk', 'me', 'bolt'], note: 'The wait tells the distance' }
    ],
    flows: [{ along: [[22, 76], [78, 76]], style: 'blue', count: 4, speed: 18, during: [1, 2] }] };

  // Card 3 scene: one satellite straight overhead. A yellow pulse leaves it ("Sent 0.00 s") and drops to the phone ("Arrives 0.07 s"), then an arrow marks the gap as "About 20,200 km". Takeaway image: a tiny delay measured as a long distance.
  const delay = { type: 'diagram', view: [100, 96],
    parts: [
      ground,
      ...sat('s', 50, 12, 1.4, 'Overhead', [98, 8]),
      { id: 'ph', shape: 'rect', x: 44, y: 56, w: 12, h: 20, style: 'accent' },
      { id: 'ts', shape: 'text', x: 78, y: 28, text: 'Sent 0.00 s' },
      { id: 'ta', shape: 'text', x: 79, y: 52, text: 'Lands 0.07 s', hidden: true },
      { id: 'dist', shape: 'arrow', from: [38, 22], to: [38, 54], style: 'thin', hidden: true },
      { id: 'dt', shape: 'text', x: 20, y: 38, text: 'About 20,200 km', hidden: true },
      { id: 'pulse', shape: 'circle', x: 50, y: 22, r: 3, style: 'spark' }
    ],
    steps: [
      { note: 'A signal leaves the satellite' },
      { move: { pulse: [0, 31] }, hide: ['ts'], show: ['ta'], note: 'It lands a flicker later' },
      { show: ['dist', 'dt'], focus: ['dist', 'dt', 'pulse', 'ta'], note: 'Late by 0.07 s = that far' }
    ] };

  // Card 5 shares one flat picture: rings around three satellites, all crossing at one spot.
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

  // Card 4 scene: top-down map. One satellite in the middle, a single ring around it, and an accent dot circling the ring for the whole card ("you could be anywhere on this ring"). Takeaway image: one distance leaves a whole ring of places.
  const ring1 = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'r1', shape: 'circle', x: 50, y: 48, r: 32, style: 'blue', fill: false },
      ...sat('a', 50, 48, 1.2, 'Satellite', [2, 8]),
      { id: 'ra', shape: 'text', x: 50, y: 90, text: 'A map from above' }
    ],
    steps: [],
    flows: [{ along: ring(50, 48, 32), style: 'accent', count: 3, speed: 22 }] };

  // Card 5 scene (map from above): two rings and two satellites cross in two dots; a third satellite and ring appear and miss one dot; the other dot turns into the accent "You". Takeaway image: three rings meeting at one point.
  const circle3 = { type: 'diagram', view: [100, 96],
    parts: [
      ...ringParts(0, false, true, [98, 10]),
      { id: 'x1', shape: 'dot', x: 50, y: 54, r: 2.6, style: 'ink' },
      { id: 'x2', shape: 'dot', x: 27.5, y: 41, r: 2.6, style: 'ink' },
      { id: 'you', shape: 'circle', x: 50, y: 54, r: 4, style: 'accent', hidden: true, label: 'You', labelAt: [98, 44] }
    ],
    steps: [
      { note: 'Two rings cross in two spots' },
      { show: ['rC', 'cl', 'cr', 'c'], focus: ['rC', 'cl', 'cr', 'c', 'x1', 'x2'], note: 'A third ring joins in' },
      { show: ['you'], hide: ['x1', 'x2'], note: 'Only one spot fits all three' }
    ] };

  window.EXPLAINER = {
    id: 'gps',
    title: 'How does your phone know exactly where you are?',
    kind: 'full',
    theme: 'internet',
    cards: [
      { type: 'card',
        title: 'It never calls a satellite. It just listens.',
        text: 'Satellites high above keep shouting two things: the exact time they sent it, and where they are. Your phone only listens, then works out where you are.',
        visual: broadcast },
      { type: 'card', title: 'A late boom means a far storm',
        text: 'You see lightning at once, but thunder is slow. Count the seconds between flash and boom. Every 3 seconds is about 1 km away.',
        visual: thunder },
      { type: 'card', title: 'A satellite is a very fast thunderclap',
        text: 'Each shout says when it was sent. Signals travel at light speed, 300,000 km a second, so from straight overhead (20,200 km) one lands 0.07 seconds late. Your phone checks that gap.',
        visual: delay },
      { type: 'card', title: 'One distance leaves a whole ring of places',
        text: 'Seen from above, a signal this late could have reached any place that far from the satellite. On a map, those places form a ring.',
        visual: ring1 },
      { type: 'card', title: 'More satellites shrink the ring to one spot',
        text: 'Two rings cross in two spots. A third ring misses one of them.', takeaway: 'The spot left is you.',
        visual: circle3 },
      { type: 'more', links: ['card-payment'], note: "Timing must be exact: a thousandth of a second off is a 300 km mistake. Phones use a fourth satellite to fix their cheap clock, so three give the 3D spot and the fourth corrects the time." }
    ]
  };
})();
