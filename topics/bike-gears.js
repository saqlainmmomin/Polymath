// Big topic: bike first, car at the end. Replaces spanner, two-gears and why-gears.
// 1 hill (effort gauge, bike), 2 long spanner, 3 meshing gears count laps, 4 same push, 3x further out, 5 bike easy/fast gear, 6 car gearbox picks a pair.
(function () {
  // ---- Card 1: a bike on a hill. Hard gear: big leg effort, bike crawls. Easy gear: small effort, bike climbs. ----
  // Hill surface y = 92 - 0.4 x. Local bike coords: a along the slope (uphill), b away from it, scaled by K.
  const K = 1.6, L = Math.hypot(1, 0.4);
  const U = [1 / L, -0.4 / L], N = [0.4 / L, -1 / L];
  const X0 = 4, Y0 = 92 - 0.4 * X0;
  const W = (a, b) => [+(X0 + K * (a * U[0] + b * N[0])).toFixed(1), +(Y0 + K * (a * U[1] + b * N[1])).toFixed(1)];
  const bikeIds = [];
  const bp = (p) => { bikeIds.push(p.id); return p; };
  const hubR = W(0, 9), hubF = W(30, 9), bb = W(13, 7), seat = W(10, 24), top = W(25, 23), hand = W(27, 27);
  const hip = W(9, 24), shoulder = W(22, 34), head = W(24, 38.5), knee = W(19, 15), foot = W(19, 7);
  const hill = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'ground', shape: 'path', points: [[0, 96], [0, 92], [100, 52], [100, 96]], closed: true, style: 'hatch' },
      bp({ id: 'wr', shape: 'circle', x: hubR[0], y: hubR[1], r: 9 * K, style: 'thin' }),
      bp({ id: 'wf', shape: 'circle', x: hubF[0], y: hubF[1], r: 9 * K, style: 'thin' }),
      bp({ id: 'f1', shape: 'line', from: hubR, to: bb, style: 'ink' }),
      bp({ id: 'f2', shape: 'line', from: bb, to: seat, style: 'ink' }),
      bp({ id: 'f3', shape: 'line', from: hubR, to: seat, style: 'ink' }),
      bp({ id: 'f4', shape: 'line', from: seat, to: top, style: 'ink' }),
      bp({ id: 'f5', shape: 'line', from: bb, to: top, style: 'ink' }),
      bp({ id: 'f6', shape: 'line', from: top, to: hubF, style: 'ink' }),
      bp({ id: 'body', shape: 'path', points: [foot, knee, hip, shoulder, hand], style: 'accent' }),
      bp({ id: 'head', shape: 'circle', x: head[0], y: head[1], r: 4 * K, style: 'accent' }),
      { id: 'gt', shape: 'rect', x: 6, y: 9, w: 40, h: 7, style: 'thin', fill: false },
      { id: 'eh', shape: 'rect', x: 6, y: 9, w: 38, h: 7, style: 'heat' },
      { id: 'ee', shape: 'rect', x: 6, y: 9, w: 11, h: 7, style: 'green', hidden: true },
      { shape: 'text', x: 26, y: 5, text: 'HOW HARD YOU PUSH' }
    ],
    steps: [
      { note: 'One gear: hard push, crawling' },
      { hide: ['eh'], show: ['ee'], move: Object.fromEntries(bikeIds.map(id => [id, [22, -8.8]])), note: 'Other gear: light push, keeps climbing' }
    ] };

  // ---- Card 2: long spanner. ----
  const ang = d => d * Math.PI / 180;
  const arc = (r, a1) => { const pts = []; for (let k = 0; k <= 8; k++) { const a = ang(a1 * k / 8); pts.push([36 + r * Math.cos(a), 44 - r * Math.sin(a)]); } return pts; };
  const spanner = { type: 'diagram', view: [100, 88],
    parts: [
      { id: 'arcS', shape: 'path', points: arc(18, 40), style: 'thin', dash: true, hidden: true, label: 'Short', labelAt: [72, 28] },
      { id: 'arcL', shape: 'path', points: arc(54, 40), style: 'thin', dash: true, hidden: true, label: 'Long', labelAt: [98, 6] },
      { id: 'short', shape: 'rect', x: 36, y: 41.5, w: 18, h: 5, style: 'ink' },
      { id: 'long', shape: 'rect', x: 36, y: 41.5, w: 54, h: 5, style: 'ink', hidden: true },
      { id: 'bolt', shape: 'circle', x: 36, y: 44, r: 6.5, style: 'hatch', label: 'Bolt', labelAt: [6, 76] },
      { id: 'p1', shape: 'arrow', from: [54, 74], to: [54, 50], style: 'accent', label: 'Push', labelAt: [64, 82] },
      { id: 'p2', shape: 'arrow', from: [90, 74], to: [90, 50], style: 'accent', hidden: true, label: 'Same push', labelAt: [62, 82] }
    ],
    steps: [
      { note: 'Short spanner: hard to turn' },
      { hide: ['short', 'p1'], show: ['long', 'p2'], note: 'Long spanner: easier to turn' },
      { show: ['arcS', 'arcL'], focus: ['arcS', 'arcL', 'long', 'bolt', 'p2'], note: 'Your hand: much further' }
    ] };

  // ---- Card 4: two gears touching at one point; a spanner drawn on each gear (bolt at its middle, handle end at the contact). Same push; 1x vs 3x. ----
  const lever = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'gs', shape: 'circle', x: 25, y: 50, r: 9, style: 'thin', fill: false, label: 'Small gear', labelAt: [2, 20] },
      { id: 'gb', shape: 'circle', x: 61, y: 50, r: 27, style: 'thin', fill: false, label: 'Big gear', labelAt: [98, 14] },
      { id: 'cs', shape: 'dot', x: 25, y: 50, r: 1.6 },
      { id: 'cb', shape: 'dot', x: 61, y: 50, r: 1.6 },
      { id: 'rs', shape: 'rect', x: 25, y: 48.25, w: 9, h: 3.5, style: 'ink', hidden: true },
      { id: 'rb', shape: 'rect', x: 34, y: 48.25, w: 27, h: 3.5, style: 'ink', hidden: true },
      { id: 'bs', shape: 'circle', x: 25, y: 50, r: 2.6, style: 'hatch', hidden: true },
      { id: 'bb', shape: 'circle', x: 61, y: 50, r: 2.6, style: 'hatch', hidden: true },
      { id: 'ts', shape: 'text', x: 29.5, y: 45.5, text: '1x', hidden: true },
      { id: 'tb', shape: 'text', x: 47.5, y: 45.5, text: '3x', hidden: true },
      { id: 'a1', shape: 'arrow', from: [34, 84], to: [34, 55], style: 'accent', label: 'Same push', labelAt: [2, 92] }
    ],
    steps: [
      { note: 'Teeth push where they touch' },
      { show: ['rs', 'bs', 'ts'], focus: ['rs', 'bs', 'ts', 'gs', 'cs', 'a1'], note: 'Small gear: a short spanner' },
      { show: ['rs', 'bs', 'ts', 'rb', 'bb', 'tb'], focus: ['rs', 'bs', 'ts', 'rb', 'bb', 'tb', 'gb', 'cb', 'a1'], note: 'Big gear: a spanner 3x longer' }
    ] };

  // ---- Card 5: bicycle front gear (accent, driver) and back gear (driven), 1 : 3 in size, chain as two dashed tangents. ----
  const bike = { type: 'diagram', view: [100, 90],
    parts: [
      { id: 'cS', shape: 'line', from: [22.1, 38.3], to: [70.4, 24.8], dash: true, label: 'Chain', labelAt: [98, 8] },
      { id: 'cS2', shape: 'line', from: [22.1, 51.7], to: [70.4, 65.2], dash: true },
      { id: 'cH', shape: 'line', from: [29.7, 24.8], to: [77.9, 38.3], dash: true, hidden: true, label: 'Chain', labelAt: [98, 8] },
      { id: 'cH2', shape: 'line', from: [29.7, 65.2], to: [77.9, 51.7], dash: true, hidden: true },
      { id: 'ringS', shape: 'circle', x: 24, y: 45, r: 7, style: 'accent', label: 'Front: 3 turns', labelAt: [2, 12] },
      { id: 'ringB', shape: 'circle', x: 24, y: 45, r: 21, style: 'accent', hidden: true, label: 'Front: 1 turn', labelAt: [2, 12] },
      { id: 'cogB', shape: 'circle', x: 76, y: 45, r: 21, style: 'thin', label: 'Back: 1 turn', labelAt: [98, 82] },
      { id: 'cogS', shape: 'circle', x: 76, y: 45, r: 7, style: 'thin', hidden: true, label: 'Back: 3 turns', labelAt: [98, 82] },
      { shape: 'dot', x: 24, y: 45, r: 1.4, style: 'accent' },
      { shape: 'dot', x: 76, y: 45, r: 1.4 }
    ],
    steps: [
      { note: 'Easy: 3 pedal turns, 1 wheel turn' },
      { hide: ['ringS', 'cogB', 'cS', 'cS2'], show: ['ringB', 'cogS', 'cH', 'cH2'], note: 'Fast: 1 pedal turn, 3 wheel turns' }
    ] };

  window.EXPLAINER = {
    id: 'bike-gears',
    title: 'Why does a slower gear make a steep hill easier?',
    kind: 'full',
    theme: 'machines',
    cards: [
      { type: 'card',
        title: 'Same hill, same legs, different gear.',
        text: 'Shifting gear changes how your pedals drive the wheel. In one gear you stand on the pedals and barely move. In another, the same hill is easy.',
        visual: hill },
      { type: 'card',
        title: 'A longer spanner turns a stuck bolt',
        text: 'Turning force is how hard the bolt gets twisted. Push twice as far out, get twice the twist. The price: your hand travels further for the same turn.',
        visual: spanner },
      { type: 'card',
        title: 'One big-gear turn costs 3 small-gear turns',
        text: 'Gears are wheels with teeth. The small gear\'s teeth push the big gear round, like a spanner on a bolt. 36 teeth to 12 means 3 small turns per big one.',
        visual: { type: 'gears', driving: 12, driven: 36, phase: 0.6, interactive: true, count: true, labels: { driver: 'Small', driven: 'Big', teeth: '{n} teeth', laps: 'Turns' } } },
      { type: 'card',
        title: 'The big gear is a spanner 3 times longer',
        text: 'The teeth meet at each gear\'s edge with the same push. The big gear\'s edge is 3 times as far from its middle as the small one\'s: 3 times the turning force.',
        visual: lever },
      { type: 'card',
        title: 'That is your bike\'s easy gear on the hill',
        text: 'A chain links the small front gear you pedal to the big back one. Say 3 pedal turns give 1 wheel turn, each push worth 3. A hill needs force, not speed.',
        visual: bike },
      { type: 'card',
        title: 'A car needs its easy gear to start',
        text: 'A stopped car is heavy to get rolling, so it starts in an easy pair of gears. Cruising uses faster pairs. A gearbox holds them all.',
        takeaway: 'Gears trade speed for turning force.',
        visual: { type: 'gears', interactive: true, tip: 'Tap 1st, 3rd, 5th',
          sets: [ { label: 'Gearbox', spin: 0.2, rpmStart: 400, gears: [
            { name: '1st', driving: 12, driven: 36 },
            { name: '3rd', driving: 20, driven: 28 },
            { name: '5th', driving: 24, driven: 16 } ] } ],
          labels: { driver: 'Engine side', driven: 'Output side', teeth: '', gear: 'Gear {n}' } } },
      { type: 'more', links: ['car-engine'] }
    ]
  };
})();
