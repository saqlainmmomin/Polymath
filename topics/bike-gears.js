// How do the gears on your bike work? 5 cards: the same hill feels easy after a gear change; the back wheel has a stack of rings and the
// gear lever slides the chain between them (gear 1 = biggest back ring); a smaller back ring spins the wheel more per pedal turn
// (30 links: 30-tooth ring once, 10-tooth ring 3 times); on a hill, short steps are easier (same lift, more turns, lighter push); pick the gear for the road.
// Copy rewritten 2026-10-26 after owner feedback (numbered gears, no spanner/teeth/car slides). The iOS app draws every card natively
// (ios/Polymath/FlatBike.swift); these web diagrams are simple stand-ins.
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

  // ---- Cards 2 and 3 (stand-in): bicycle front gear (accent, driver) and back gear (driven), 1 : 3 in size, chain as two dashed tangents. ----
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
    title: 'How do the gears on your bike work?',
    kind: 'full',
    theme: 'machines',
    cards: [
      { type: 'card', title: 'Same hill, same legs.',
        text: "On a steep hill, you push as hard as you can and barely move, but change gear and the same hill feels easy. Your legs aren't stronger, and the hill isn't flatter. So what does the gear lever change? To find out, look at the back wheel.",
        visual: hill },
      { type: 'card', title: 'The back wheel has a stack of rings',
        text: 'A geared bike has a stack of rings on its back wheel. Each ring has teeth, and each is a different size. The chain loops from the pedal ring to one of the back rings. The gear lever slides the chain from one back ring to another. Say the bike has 7 gears. Gear 1 uses the biggest back ring, and gear 7 uses the smallest. So why does the size of the back ring change how the pedals feel?',
        visual: bike },
      { type: 'card', title: 'A smaller back ring spins the wheel more',
        text: 'The chain is a loop of links, and each link fits one tooth. Say the pedal ring has 30 teeth. One pedal turn pulls 30 links past. In gear 1, the back ring has 30 teeth, so 30 links turn it once. In gear 7, the back ring has only 10 teeth. 10 fits into 30 three times, so the same pedal turn spins the wheel 3 times. So what does a wheel that spins less, or more, do to your legs?',
        visual: bike },
      { type: 'card', title: 'Short steps are easier uphill',
        text: 'On stairs, you can take one step at a time or leap three at once. Either way you rise to the same top, but leaping makes your legs burn. A hill works the same way: you must lift yourself to the top either way. In gear 1, each pedal turn moves you a short way, so you pedal more turns with a light push each. In gear 7, each pedal turn moves you 3 times as far, so each push is 3 times harder. So how do you choose?',
        visual: hill },
      { type: 'card', title: 'Pick the gear that fits the road',
        text: 'On a steep hill, use gear 1, so each push stays light. On flat ground, nothing pulls you back, so a light push already works and a higher gear lets each turn carry you further. Downhill, gravity helps, so gear 7 suits you. Riders shift often, so that pedalling never feels too hard or too fast.',
        takeaway: 'Low gear number: easy push, slow ride. High gear number: hard push, fast ride.',
        visual: hill },
      { type: 'more', links: ['car-engine'], note: 'Most bikes also have two or three rings at the pedals. Shifting those makes the same kind of change, only bigger.' }
    ]
  };
})();
