// One big engine topic: merges engine-push, crank, four-strokes and cylinders into a single flowing answer.
(function () {
  const shove = {
    type: 'diagram', view: [100, 96],
    parts: [
      { id: 'mix', shape: 'rect', x: 23, y: 11, w: 54, h: 9, style: 'blue', label: 'Fuel + air', labelAt: [98, 12] },
      { id: 'gas1', shape: 'rect', x: 23, y: 11, w: 54, h: 9, style: 'heat', hidden: true, label: 'Fire', labelAt: [98, 12] },
      { id: 'gas2', shape: 'rect', x: 23, y: 11, w: 54, h: 49, style: 'heat', hidden: true, label: 'Hot gas', labelAt: [98, 12] },
      { id: 'tube', shape: 'path', points: [[22, 88], [22, 10], [78, 10], [78, 88]], fill: false },
      { id: 'piston', shape: 'rect', x: 23, y: 20, w: 54, h: 8, style: 'accent', label: 'Piston', labelAt: [2, 24] },
      { id: 'spark', shape: 'dot', x: 50, y: 11, r: 2, style: 'spark', hidden: true },
      { id: 'push', shape: 'arrow', from: [50, 73], to: [50, 93], style: 'heat', hidden: true }
    ],
    steps: [
      { note: 'Trapped above the piston' },
      { show: ['gas1', 'spark'], hide: ['mix'], note: 'A spark lights it' },
      { show: ['gas2', 'push'], hide: ['gas1', 'spark'], move: { piston: [0, 40] }, note: 'The piston is shoved down' }
    ]
  };
  const strokeNames = ['Suck in', 'Squeeze', 'Bang', 'Blow out'];
  const strokeLabels = { intake: 'Fuel + air in', exhaust: 'Exhaust out', spark: 'Spark plug' };
  window.EXPLAINER = {
    id: 'car-engine',
    title: 'How does a car engine actually work?',
    kind: 'full',
    theme: 'machines',
    cards: [
      { type: 'card', title: 'Tiny controlled explosions, one after another.',
        text: 'Fuel and air are trapped in a tube, the cylinder, and lit. The very hot gas pushes hard on a sliding plug, the piston. A wheel needs spin, not a push.',
        visual: shove },
      { type: 'card', title: 'A bent shaft turns the shove into a spin',
        text: 'A rod links the piston to a bent shaft, the crankshaft. Pushing the bend turns it, like a foot on a bike pedal. What brings the piston back up?',
        visual: { type: 'crank', speed: 40, start: 40, parts: true } },
      { type: 'card', title: 'One bang takes four strokes, two full turns',
        text: 'Each trip up or down is a stroke: suck in, squeeze, bang, blow out. Four half-turns make two turns. Only the bang pushes; the shaft\'s spin carries the piston through the rest.',
        visual: { type: 'strokes', speed: 70, strokes: strokeNames, labels: strokeLabels } },
      { type: 'card', title: 'Why squeeze the fuel before lighting it?',
        text: 'Squeezing first packs the fuel and air tight and warm. After the burn, that gas is under far more pressure, so the bang hits like a punch, not a nudge.',
        visual: { type: 'strokes', speed: 70, only: 1, strokes: strokeNames, labels: strokeLabels } },
      { type: 'card', title: 'So engines use several cylinders, taking turns',
        text: 'One cylinder bangs once per two turns, so the engine shudders. Four share those two turns, one bang every half turn, and feel smooth. Tap 4.',
        takeaway: 'More cylinders, smoother push.',
        visual: { type: 'cylinders', speed: 120, selected: 0, options: [{ n: 1, order: [1] }, { n: 4, order: [1, 3, 4, 2] }] } },
      { type: 'more', links: ['bike-gears'], note: 'The spin still has to reach the wheels, and a steep hill makes that hard.' }
    ]
  };
})();
