// How does your phone find you with no mobile signal? 5 cards, written spine-first (2026-10-29, tasks/spine-gps/):
// the phone only listens, so it needs no mobile signal; satellites keep sending a radio signal that says where they are and when it was sent;
// the gap between sent and arrived, times the speed of light, is a distance (one analogy: lightning to thunder); one distance is a ring, three
// satellites leave two spots and only one is on Earth; the phone's own clock is not exact, so a fourth satellite fixes it.
// No "GPS", no satellite count, no "usually", no school-friend analogy (facts.md myths). The iOS app draws every card natively
// (ios/Polymath/FlatGPS.swift); these web diagrams are simple stand-ins using the text's exact words.
(function () {
  // Ground: an arc (big circle top) hatched, closed across the bottom of the box.
  const arc = [];
  for (let x = 0; x <= 100; x += 5) arc.push([x, +(176 - Math.sqrt(10000 - (x - 50) * (x - 50))).toFixed(1)]);
  const ground = (extra) => Object.assign({ id: 'ground', shape: 'path', points: arc.concat([[100, 96], [0, 96]]), closed: true, style: 'hatch' }, extra || {});

  // Satellite: body plus two panels, scaled by k. `extra` is merged into every piece (e.g. hidden).
  const sat = (id, x, y, k, label, labelAt, extra) => [
    Object.assign({ id: id + 'l', shape: 'rect', x: x - 9 * k, y: y - 1.5 * k, w: 5 * k, h: 3 * k, style: 'thin' }, extra || {}),
    Object.assign({ id: id + 'r', shape: 'rect', x: x + 4 * k, y: y - 1.5 * k, w: 5 * k, h: 3 * k, style: 'thin' }, extra || {}),
    Object.assign({ id: id, shape: 'rect', x: x - 4 * k, y: y - 3 * k, w: 8 * k, h: 6 * k, style: 'ink', label, labelAt }, extra || {})
  ];

  // ---- Card 1: no mobile signal. Satellites send pulses down to the phone; nothing goes back. ----
  const listen = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      ground(),
      ...sat('a', 18, 18, 1.3, 'Satellite', [2, 5]), ...sat('b', 50, 10, 1.3), ...sat('c', 82, 18, 1.3),
      { id: 'ph', shape: 'rect', x: 44, y: 56, w: 12, h: 20, style: 'accent', label: 'Your phone', labelAt: [98, 66] },
      { id: 'bars', shape: 'text', x: 27, y: 68, text: 'NO MOBILE SIGNAL' },
      { id: 'lis', shape: 'text', x: 27, y: 80, text: 'LISTENING', hidden: true }
    ],
    steps: [
      { note: 'Your phone has no mobile signal' },
      { show: ['lis'], note: 'It never calls anyone. It only listens' }
    ],
    flows: [
      { along: [[22, 25], [45, 54]], style: 'spark', count: 3, speed: 15, during: [1] },
      { along: [[50, 18], [50, 54]], style: 'spark', count: 3, speed: 15, during: [1] },
      { along: [[78, 25], [55, 54]], style: 'spark', count: 3, speed: 15, during: [1] }
    ] };

  // ---- Card 2: one satellite sends a radio signal that says where it is and when it was sent; the phone sends nothing back. ----
  const send = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      ground(),
      ...sat('s', 50, 12, 1.4, 'Satellite', [98, 8]),
      { id: 'ph', shape: 'rect', x: 44, y: 56, w: 12, h: 20, style: 'accent', label: 'Your phone', labelAt: [98, 66] },
      { id: 'w', shape: 'text', x: 24, y: 28, text: 'WHERE IT IS', hidden: true },
      { id: 't', shape: 'text', x: 24, y: 40, text: 'TIME SENT', hidden: true },
      { id: 'none', shape: 'text', x: 78, y: 40, text: 'Nothing goes back', hidden: true }
    ],
    steps: [
      { note: 'A satellite keeps sending out a radio signal' },
      { show: ['w', 't'], note: 'It says where it is and what time it was sent' },
      { show: ['none'], note: 'Your phone catches it and sends nothing back' }
    ],
    flows: [{ along: [[50, 20], [50, 54]], style: 'spark', count: 4, speed: 15 }] };

  // ---- Card 3: lightning to thunder first (a wait is a distance), then the satellite signal: sent, arrived about 0.07 seconds later. ----
  const stormIds = ['gr', 'cloud', 'bolt', 'me', 'tw'];
  const delay = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'gr', shape: 'rect', x: 0, y: 86, w: 100, h: 10, style: 'hatch' },
      { id: 'cloud', shape: 'path', points: [[4, 24], [6, 14], [16, 10], [24, 6], [34, 12], [42, 16], [42, 26], [30, 30], [14, 30]], closed: true, smooth: true, style: 'thin' },
      { id: 'bolt', shape: 'path', points: [[22, 30], [17, 46], [25, 48], [15, 84]], style: 'spark' },
      { id: 'me', shape: 'rect', x: 80, y: 66, w: 6, h: 20, style: 'accent', label: 'You', labelAt: [98, 58] },
      { id: 'tw', shape: 'text', x: 55, y: 48, text: 'FLASH, THEN THUNDER: THE WAIT' },
      ground({ hidden: true }),
      ...sat('s', 50, 12, 1.4, 'Satellite', [98, 8], { hidden: true }),
      { id: 'ph', shape: 'rect', x: 44, y: 56, w: 12, h: 20, style: 'accent', hidden: true },
      { id: 'ts', shape: 'text', x: 78, y: 28, text: 'SENT', hidden: true },
      { id: 'ta', shape: 'text', x: 78, y: 52, text: 'ARRIVED', hidden: true },
      { id: 'dist', shape: 'arrow', from: [38, 22], to: [38, 54], style: 'thin', hidden: true },
      { id: 'dt', shape: 'text', x: 20, y: 38, text: 'DISTANCE', hidden: true },
      { id: 'sec', shape: 'text', x: 78, y: 40, text: 'ABOUT 0.07 SECONDS', hidden: true },
      { id: 'pulse', shape: 'circle', x: 50, y: 22, r: 3, style: 'spark', hidden: true }
    ],
    steps: [
      { note: 'The wait from lightning to thunder tells you how far away the storm is' },
      { hide: stormIds, show: ['ground', 'sl', 'sr', 's', 'ph', 'ts', 'pulse'], note: 'A satellite signal is sent' },
      { move: { pulse: [0, 31] }, hide: ['ts'], show: ['ta', 'sec'], note: 'It arrives about 0.07 seconds later' },
      { show: ['dist', 'dt'], note: 'The gap, times the speed of light, is the distance' }
    ] };

  // ---- Card 4: a map from above. One ring, then three rings; they meet on the ground at one spot, and the other spot is far out in space. ----
  const ring = (cx, cy, r) => {
    const pts = [];
    for (let a = 0; a <= 330; a += 15) pts.push([+(cx + r * Math.cos(a * Math.PI / 180)).toFixed(1), +(cy + r * Math.sin(a * Math.PI / 180)).toFixed(1)]);
    return pts;
  };
  const spots = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'rA', shape: 'circle', x: 50, y: 28, r: 26, style: 'blue', fill: false },
      { id: 'rB', shape: 'circle', x: 27.5, y: 67, r: 26, style: 'blue', fill: false, hidden: true },
      { id: 'rC', shape: 'circle', x: 72.5, y: 67, r: 26, style: 'blue', fill: false, hidden: true },
      ...sat('a', 50, 28, 1.2, 'Satellite', [98, 8]),
      ...sat('b', 27.5, 67, 1.2, undefined, undefined, { hidden: true }),
      ...sat('c', 72.5, 67, 1.2, undefined, undefined, { hidden: true }),
      { id: 'x1', shape: 'dot', x: 50, y: 54, r: 2.6, style: 'ink', hidden: true },
      { id: 'x2', shape: 'dot', x: 90, y: 10, r: 2.6, style: 'ink', hidden: true, label: 'Far out in space', labelAt: [98, 20] },
      { id: 'up', shape: 'arrow', from: [60, 40], to: [86, 14], style: 'thin', dash: true, hidden: true },
      { id: 'you', shape: 'circle', x: 50, y: 54, r: 4, style: 'accent', hidden: true, label: 'On Earth', labelAt: [98, 54] }
    ],
    steps: [
      { note: 'One distance leaves a whole ring of places you could be' },
      { show: ['rB', 'rC', 'bl', 'br', 'b', 'cl', 'cr', 'c', 'x1', 'x2', 'up'], note: 'With three satellites, only two spots fit' },
      { show: ['you'], hide: ['x1'], note: 'Only one of them is on Earth' }
    ],
    flows: [{ along: ring(50, 28, 26), style: 'accent', count: 2, speed: 22, during: [0] }] };

  // ---- Card 5: the phone's clock is wrong, so the spot is 300 metres off; a fourth satellite lets it fix the clock. ----
  const clock = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'rt', shape: 'dot', x: 50, y: 62, r: 2.6, style: 'ink', label: 'Where you are', labelAt: [98, 72] },
      { id: 'est', shape: 'circle', x: 66, y: 50, r: 4, style: 'accent' },
      { id: 'off', shape: 'arrow', from: [66, 50], to: [52, 60], style: 'thin', dash: true, label: 'About 300 metres off', labelAt: [98, 40] },
      ...sat('d', 50, 14, 1.3, 'Fourth satellite', [98, 8], { hidden: true }),
      { id: 'pc', shape: 'text', x: 27, y: 88, text: "YOUR PHONE'S CLOCK" },
      { id: 'sc', shape: 'text', x: 75, y: 88, text: "SATELLITE'S CLOCK", hidden: true }
    ],
    steps: [
      { note: "Your phone's clock isn't as exact, so you land about 300 metres off" },
      { show: ['dl', 'dr', 'd', 'sc'], note: 'A fourth satellite shows it how wrong its clock is' },
      { move: { est: [-16, 12] }, hide: ['off'], note: 'It fixes its own clock and lands on the right spot' }
    ] };

  window.EXPLAINER = {
    id: 'gps',
    title: 'How does your phone find you with no mobile signal?',
    kind: 'full',
    theme: 'internet',
    cards: [
      { type: 'card', title: 'Zero bars, and your phone still finds you.',
        text: 'Out in the open, with no mobile signal at all, your phone still finds you. It doesn\'t need to call anyone. It only listens.',
        hook: 'So what radio signal is it listening to?',
        visual: listen },
      { type: 'card', title: 'Satellites keep sending a radio signal that says where they are and when it was sent',
        text: 'Satellites circle Earth far above you, and each one keeps sending out a radio signal. The signal says where the satellite is and what time it was sent. Your phone catches it and sends nothing back.',
        hook: 'So how does the time a radio signal was sent tell your phone a distance?',
        visual: send },
      { type: 'card', title: 'The gap between when a radio signal was sent and when it arrived is a distance',
        text: "Count the seconds from lightning to thunder, and the wait tells you how far away the storm is. A satellite's radio signal is far faster than sound, but its delay is a distance too. From straight overhead it arrives in about 0.07 seconds, shorter than a blink. Your phone compares when it was sent with when it arrived. That gap, times the speed of light, is the distance.",
        hook: 'So how many satellites does it take to pin down your spot?',
        visual: delay },
      { type: 'card', title: 'With three satellites, only two spots fit, and only one is on Earth',
        text: 'One distance leaves a whole ring of places you could be, all the same distance from that satellite. With three satellites, only two spots fit all three distances, and only one of them is on Earth. The other is far out in space.',
        hook: "But how exact is your phone's own clock?",
        visual: spots },
      { type: 'card', title: "Your phone's own clock isn't exact, so it listens to a fourth satellite",
        text: "One problem is left. Your phone times the arrival with its own clock, and that clock is nowhere near as exact as a satellite's. A clock a millionth of a second wrong puts you about 300 metres off. So the phone listens to a fourth satellite. That lets it work out how wrong its own clock is, and fix it.",
        takeaway: 'Your phone doesn\'t need to call anyone. It listens to satellites and turns the delay into where you are.',
        visual: clock },
      { type: 'more', links: ['card-payment'], note: "The satellites' clocks are set to tick a little slower before launch. Up there, far from Earth's pull and moving fast, they would otherwise run about 38 millionths of a second ahead of clocks on the ground every day, and that would pile up into a position error of about 11 kilometres a day. Engineers fixed this before launch by changing how fast the clocks tick, one of the few places where Einstein's ideas about time are used by something in your pocket." }
    ]
  };
})();
