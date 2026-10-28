// Why does one gear click make the same hill feel easier? 5 cards, written spine-first (2026-10-28, tasks/spine-bike-gears/):
// the same hill feels easier after a click; a smaller back ring spins the wheel more for each pedal turn (each link fits one tooth);
// so it carries you farther per pedal turn, and a bigger back ring a shorter way; a shorter way per turn means a lighter push and
// more turns to the top (walking a steep path, same hill in every gear); to go the same speed on flat road a smaller back ring means slower pedalling and a harder push.
// No numbered gears, no teeth sums, no stairs, no "less work" (facts.md myths). The iOS app draws every card natively
// (ios/Polymath/FlatBike.swift); these web diagrams are simple stand-ins using the text's exact words.
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
      { id: 'ground', shape: 'path', points: [[0, 96], [0, 92], [100, 52], [100, 96]], closed: true, style: 'hatch', label: 'Same hill', labelAt: [98, 88] },
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
      { shape: 'text', x: 26, y: 5, text: 'PUSH' }
    ],
    steps: [
      { note: 'You push as hard as you can and barely move' },
      { hide: ['eh'], show: ['ee'], move: Object.fromEntries(bikeIds.map(id => [id, [22, -8.8]])), note: 'Click the gear lever: the same hill feels easier' }
    ] };

  // ---- Cards 2 and 5: the pedal ring and the chain, with a bigger and a smaller back ring (chain tangents computed from the radii). ----
  const PX = 24, BX = 76, CY = 45, PR = 14;
  const chain = (r1, r2) => {
    const d = BX - PX, s = (r1 - r2) / d, c = Math.sqrt(1 - s * s);
    const f = (v) => +v.toFixed(1);
    return [
      [[f(PX + r1 * s), f(CY - r1 * c)], [f(BX + r2 * s), f(CY - r2 * c)]],
      [[f(PX + r1 * s), f(CY + r1 * c)], [f(BX + r2 * s), f(CY + r2 * c)]]
    ];
  };
  const big = chain(PR, 21), small = chain(PR, 7);
  const ringParts = [
    { id: 'cb1', shape: 'line', from: big[0][0], to: big[0][1], dash: true, label: 'Chain', labelAt: [98, 8] },
    { id: 'cb2', shape: 'line', from: big[1][0], to: big[1][1], dash: true },
    { id: 'cs1', shape: 'line', from: small[0][0], to: small[0][1], dash: true, hidden: true, label: 'Chain', labelAt: [98, 8] },
    { id: 'cs2', shape: 'line', from: small[1][0], to: small[1][1], dash: true, hidden: true },
    { id: 'pedal', shape: 'circle', x: PX, y: CY, r: PR, style: 'accent', label: 'Pedal ring', labelAt: [2, 12] },
    { id: 'backBig', shape: 'circle', x: BX, y: CY, r: 21, style: 'thin', label: 'Bigger back ring', labelAt: [98, 82] },
    { id: 'backSmall', shape: 'circle', x: BX, y: CY, r: 7, style: 'thin', hidden: true, label: 'Smaller back ring', labelAt: [98, 82] },
    { shape: 'dot', x: PX, y: CY, r: 1.4, style: 'accent' },
    { shape: 'dot', x: BX, y: CY, r: 1.4 }
  ];
  const slide = { hide: ['cb1', 'cb2', 'backBig'], show: ['cs1', 'cs2', 'backSmall'] };
  const rings = { type: 'diagram', view: [100, 90], parts: ringParts,
    steps: [
      { note: 'The chain runs from the pedal ring to a back ring' },
      Object.assign({ note: 'The lever slides the chain onto another ring' }, slide)
    ] };

  // ---- Card 3: one pedal turn carries you farther or a shorter way, by the back ring. ----
  const carry = { type: 'diagram', view: [100, 90], tip: false,
    parts: [
      { id: 'road', shape: 'rect', x: 0, y: 70, w: 100, h: 20, style: 'hatch' },
      { id: 'start', shape: 'line', from: [6, 36], to: [6, 70], style: 'thin' },
      { id: 'far', shape: 'arrow', from: [6, 52], to: [92, 52], style: 'accent', label: 'Farther', labelAt: [98, 30] },
      { id: 'near', shape: 'arrow', from: [6, 52], to: [34, 52], style: 'accent', hidden: true, label: 'A shorter way', labelAt: [98, 30] }
    ],
    steps: [
      { note: 'One pedal turn, smaller back ring: farther' },
      { hide: ['far'], show: ['near'], note: 'One pedal turn, bigger back ring: a shorter way' }
    ] };

  // ---- Card 4: walking up a steep path, long strides or short quick steps, same top. ----
  const strides = [], steps = [];
  for (let i = 0; i < 3; i++) strides.push({ id: 'L' + i, shape: 'rect', x: 8 + i * 27, y: 30, w: 24, h: 6, style: 'heat', hidden: true });
  for (let i = 0; i < 8; i++) steps.push({ id: 'S' + i, shape: 'rect', x: 8 + i * 10, y: 56, w: 8, h: 6, style: 'green', hidden: true });
  const path = { type: 'diagram', view: [100, 90], tip: false,
    parts: [
      { id: 'top', shape: 'line', from: [91, 18], to: [91, 76], style: 'thin', dash: true, label: 'Same top', labelAt: [98, 10] },
      { id: 'tl', shape: 'text', x: 8, y: 24, text: 'LONG STRIDES' },
      { id: 'ts', shape: 'text', x: 8, y: 50, text: 'SHORT QUICK STEPS' }
    ].concat(strides, steps),
    steps: [
      { show: strides.map(p => p.id), note: 'Long strides are hard heaves' },
      { show: steps.map(p => p.id), note: 'Short quick steps are light' }
    ] };

  // ---- Card 5: flat road, a smaller back ring and slower legs. Same rings as card 2, other words. ----
  const flat = { type: 'diagram', view: [100, 90], tip: false,
    parts: ringParts.concat([{ id: 'road', shape: 'rect', x: 0, y: 84, w: 100, h: 6, style: 'hatch', label: 'Flat road', labelAt: [2, 78] }]),
    steps: [
      { note: 'Bigger back ring: your legs spin fast, each push is light' },
      Object.assign({ note: 'Smaller back ring: slower pedalling, a harder push' }, slide)
    ] };

  window.EXPLAINER = {
    id: 'bike-gears',
    title: 'Why does one gear click make the same hill feel easier?',
    kind: 'full',
    theme: 'machines',
    cards: [
      { type: 'card', title: 'Same hill, same legs.',
        text: "On a steep hill you push as hard as you can and barely move. Click the gear lever once and the same hill feels easier. Your legs aren't stronger, and the hill isn't flatter.",
        hook: 'So what does the lever change at the back wheel?',
        visual: hill },
      { type: 'card', title: 'A smaller back ring spins the wheel more for each pedal turn',
        text: 'The chain runs from the pedal ring to a stack of rings on the back wheel. The lever slides it onto another ring. Each link fits one tooth, so a ring with fewer teeth turns more times for the same length of chain.',
        hook: 'So how far does one pedal turn carry you?',
        visual: rings },
      { type: 'card', title: 'A smaller back ring carries you farther with each pedal turn',
        text: 'More wheel turns means each pedal turn carries you farther. With a bigger back ring, each turn takes you a shorter way.',
        hook: 'So why does a shorter way per turn make the hill feel easier?',
        visual: carry },
      { type: 'card', title: 'A shorter way per turn means a lighter push, and more turns to the top',
        text: 'Think of walking up a steep path. Long strides are hard heaves, short quick steps are light, and you reach the same top either way. A pedal turn is like a stride, and the hill is the same height in every gear. So each turn lifts you only a little way up, and the push can be light.',
        hook: 'But what about on flat road?',
        visual: path },
      { type: 'card', title: 'To go the same speed on flat road, a smaller back ring means slower pedalling',
        text: 'To go the same speed, a smaller back ring means pedalling slower, with a harder push each time. On flat road that\'s fine, because legs push best in a narrow range of pedalling speeds.',
        takeaway: 'A gear can\'t make the hill any lower. It only decides how many pushes it takes to climb it.',
        visual: flat },
      { type: 'more', links: ['car-engine'], note: 'Before chains, the pedals of the old penny-farthing were fixed straight to the hub of the huge front wheel, so there were no gears at all: one pedal turn was one wheel turn, and the only way to go farther per turn was a bigger wheel, up to about 60 inches across. The chain and a smaller back ring let a smaller wheel go as far as a big one, and that is the idea your gear lever still plays with. Even today the word "gear inches" means how wide a penny-farthing wheel would have to be to match your gear.' }
    ]
  };
})();
