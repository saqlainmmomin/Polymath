// Bite: why a long spanner is easier. Card 1 = door pushed near the hinge vs at the handle; card 2 = spanner, then the cost (hand path).
(function () {
  const ang = d => d * Math.PI / 180;
  const door = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'g0', shape: 'line', from: [12, 40], to: [87.8, 34.4], style: 'thin', dash: true },
      { id: 'g1', shape: 'line', from: [12, 40], to: [80.9, 8], style: 'thin', dash: true, hidden: true },
      { id: 'door', shape: 'rect', x: 12, y: 38, w: 76, h: 5, style: 'ink' },
      { id: 'hinge', shape: 'circle', x: 12, y: 40.5, r: 3.5, style: 'hatch', label: 'Hinge', labelAt: [2, 66] },
      { id: 'handle', shape: 'circle', x: 82, y: 40.5, r: 2.2, style: 'thin', label: 'Handle', labelAt: [98, 22] },
      { id: 'p1', shape: 'arrow', from: [28, 78], to: [28, 49], style: 'accent', label: 'Push', labelAt: [40, 90] },
      { id: 'p2', shape: 'arrow', from: [82, 78], to: [82, 49], style: 'accent', hidden: true, label: 'Same push', labelAt: [98, 90] }
    ],
    steps: [
      { note: 'Near the hinge: barely moves' },
      { hide: ['p1', 'g0'], show: ['p2', 'g1'], note: 'At the handle: it swings' }
    ] };

  const arc = (r, a1) => { const pts = []; for (let k = 0; k <= 8; k++) { const a = ang(a1 * k / 8); pts.push([36 + r * Math.cos(a), 52 - r * Math.sin(a)]); } return pts; };
  const spanner = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'arcS', shape: 'path', points: arc(18, 40), style: 'thin', dash: true, hidden: true },
      { id: 'arcL', shape: 'path', points: arc(54, 40), style: 'thin', dash: true, hidden: true },
      { id: 'short', shape: 'rect', x: 36, y: 49.5, w: 18, h: 5, style: 'ink' },
      { id: 'long', shape: 'rect', x: 36, y: 49.5, w: 54, h: 5, style: 'ink', hidden: true },
      { id: 'bolt', shape: 'circle', x: 36, y: 52, r: 6.5, style: 'hatch', label: 'Bolt', labelAt: [6, 84] },
      { id: 'p1', shape: 'arrow', from: [54, 82], to: [54, 58], style: 'accent', label: 'Push', labelAt: [64, 90] },
      { id: 'p2', shape: 'arrow', from: [90, 82], to: [90, 58], style: 'accent', hidden: true, label: 'Same push', labelAt: [62, 90] }
    ],
    steps: [
      { note: 'Short spanner: hard to turn' },
      { hide: ['short', 'p1'], show: ['long', 'p2'], note: 'Long spanner: easier to turn' },
      { show: ['arcS', 'arcL'], focus: ['arcS', 'arcL', 'long', 'bolt', 'p2'], note: 'Your hand: much further' }
    ] };

  window.EXPLAINER = {
    id: 'spanner',
    title: 'How a longer spanner beats a stuck bolt',
    kind: 'bite',
    theme: 'machines',
    cards: [
      { type: 'card', title: 'A door is easy to open at the handle',
        text: 'Push near the hinge and it barely moves. Push at the handle with the same force and it swings. A turning push like this is called twist (engineers say torque).',
        takeaway: 'Further out, more twist.',
        visual: door },
      { type: 'card', title: 'A long spanner works like the handle',
        text: 'On a stuck bolt, the same push gives more twist with a longer spanner (wrench), because you push further out. The price: your hand travels further to turn the bolt the same amount.',
        visual: spanner },
      { type: 'more', links: ['two-gears'] }
    ]
  };
})();
