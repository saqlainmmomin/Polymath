// Engine series 1/4: burning fuel pushes a piston. Card 1 = sealed tube, spark, shove. Guess reveal = where the push comes from.
(function () {
  const tube = { id: 'tube', shape: 'path', points: [[30, 88], [30, 10], [70, 10], [70, 88]], fill: false };
  const shove = {
    type: 'diagram', view: [100, 96],
    parts: [
      { id: 'mix', shape: 'rect', x: 31, y: 11, w: 38, h: 9, style: 'blue', label: 'Fuel + air', labelAt: [98, 12] },
      { id: 'gas1', shape: 'rect', x: 31, y: 11, w: 38, h: 9, style: 'heat', hidden: true, label: 'Fire', labelAt: [98, 12] },
      { id: 'gas2', shape: 'rect', x: 31, y: 11, w: 38, h: 49, style: 'heat', hidden: true, label: 'Hot gas', labelAt: [98, 12] },
      tube,
      { id: 'piston', shape: 'rect', x: 31, y: 20, w: 38, h: 8, style: 'accent', label: 'Piston', labelAt: [2, 24] },
      { id: 'spark', shape: 'dot', x: 50, y: 11, r: 2, style: 'heat', hidden: true },
      { id: 'push', shape: 'arrow', from: [50, 73], to: [50, 93], style: 'accent', hidden: true }
    ],
    steps: [
      { note: 'Trapped above the piston' },
      { show: ['gas1', 'spark'], hide: ['mix'], note: 'A spark lights it' },
      { show: ['gas2', 'push'], hide: ['gas1', 'spark'], move: { piston: [0, 40] }, note: 'The piston is shoved down' }
    ]
  };
  const reveal = {
    type: 'diagram', view: [100, 96],
    parts: [
      { id: 'gas', shape: 'rect', x: 31, y: 11, w: 38, h: 9, style: 'heat', label: 'Hot gas', labelAt: [98, 12] },
      { id: 'gas2', shape: 'rect', x: 31, y: 11, w: 38, h: 49, style: 'heat', hidden: true, label: 'Hot gas', labelAt: [98, 12] },
      tube,
      { id: 'piston', shape: 'rect', x: 31, y: 20, w: 38, h: 8, style: 'accent', label: 'Piston', labelAt: [2, 24] },
      { id: 'a1', shape: 'arrow', from: [50, 14], to: [50, 19], style: 'heat' },
      { id: 'a2', shape: 'arrow', from: [50, 40], to: [50, 58], style: 'heat', hidden: true },
      { id: 'a3', shape: 'arrow', from: [50, 26], to: [50, 13], style: 'heat', hidden: true },
      { id: 'a4', shape: 'arrow', from: [38, 35], to: [32, 35], style: 'heat', hidden: true },
      { id: 'a5', shape: 'arrow', from: [62, 35], to: [68, 35], style: 'heat', hidden: true }
    ],
    steps: [
      { note: 'Hot gas pushes on everything it touches' },
      { show: ['gas2', 'a2', 'a3', 'a4', 'a5'], hide: ['gas', 'a1'], move: { piston: [0, 40] }, note: 'Only the piston can slide' }
    ]
  };
  window.EXPLAINER = {
    id: 'engine-push',
    title: 'How burning fuel pushes an engine',
    kind: 'bite',
    theme: 'machines',
    cards: [
      { type: 'card', title: 'A burst of fire can shove a plug',
        text: 'A mix of fuel and air is trapped in a tube, closed at the top, and set off. Something shoves a sliding plug, the piston, down the tube.',
        visual: shove },
      { type: 'guess', title: 'What gives the piston its push?',
        options: ['The spark that lights the fuel', 'The hot gas from the burning mix', 'Air rushing in through the intake'],
        answer: 1,
        why: 'Burning makes hot gas that needs far more room, so it pushes hard. The spark only lights it.',
        visual: reveal },
      { type: 'more', links: ['crank', 'four-strokes'], note: 'Next: how that push becomes a spin.' }
    ]
  };
})();
