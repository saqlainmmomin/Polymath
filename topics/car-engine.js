// Why does a car engine need an electric motor just to start? 5 cards, written spine-first (2026-10-27, tasks/spine-car-engine/):
// an electric motor turns the engine first; hot gas pushes a sliding plug that turns a bent shaft; the piston makes four moves
// and only one pushes; the turning shaft drags it through the other three, which nothing can do at the start; a heavy wheel
// and several cylinders taking turns keep it going. "Explosion" and "bang" are out (facts.md myths: it burns, it doesn't explode).
(function () {
  // Card 1: press start, a small electric motor turns the engine's wheel, the engine catches and the motor lets go.
  const starter = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'engine', shape: 'rect', x: 8, y: 14, w: 50, h: 50, style: 'thin', label: 'Engine', labelAt: [4, 6] },
      { id: 'wheel', shape: 'circle', x: 33, y: 39, r: 16, style: 'ink' },
      { id: 'motor', shape: 'circle', x: 76, y: 39, r: 8, style: 'accent', label: 'Electric motor', labelAt: [98, 14] },
      { id: 'link', shape: 'line', from: [49, 39], to: [68, 39], style: 'thin' },
      { id: 'btn', shape: 'circle', x: 76, y: 78, r: 6, style: 'thin', text: 'Start' },
      { id: 'runs', shape: 'text', x: 33, y: 80, text: 'Runs by itself', hidden: true }
    ],
    steps: [
      { note: 'Press start' },
      { restyle: { wheel: 'accent' }, note: 'The motor turns the engine' },
      { hide: ['link'], restyle: { motor: 'thin' }, show: ['runs'], note: 'Then it runs by itself' }
    ],
    flows: [ { along: [[33, 23], [49, 39], [33, 55], [17, 39], [33, 23]], style: 'ink', count: 3, speed: 30, during: [1, 2] } ] };

  // Card 3 and 4 share the four move names, in the slides' words.
  const moves = ['Pulls in', 'Squeezes', 'Push', 'Clears out'];
  const moveLabels = { intake: 'Fuel and air in', exhaust: 'Used gas out', spark: 'Spark' };

  // Card 4: at the start the electric motor turns the shaft, which drags the piston in and squeezes; a spark, then the push.
  const firstSpark = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'tube', shape: 'path', points: [[18, 62], [18, 8], [58, 8], [58, 62]], fill: false, label: 'Cylinder', labelAt: [2, 4] },
      { id: 'mix', shape: 'rect', x: 19, y: 9, w: 38, h: 30, style: 'blue', hidden: true },
      { id: 'tight', shape: 'rect', x: 19, y: 9, w: 38, h: 9, style: 'blue', hidden: true },
      { id: 'fire', shape: 'rect', x: 19, y: 9, w: 38, h: 9, style: 'heat', hidden: true },
      { id: 'piston', shape: 'rect', x: 19, y: 40, w: 38, h: 8, style: 'accent' },
      { id: 'rod', shape: 'line', from: [38, 48], to: [38, 74], style: 'ink' },
      { id: 'shaft', shape: 'circle', x: 38, y: 78, r: 6, style: 'ink', label: 'Shaft drags the piston', labelAt: [2, 92] },
      { id: 'motor', shape: 'circle', x: 82, y: 78, r: 7, style: 'thin', label: 'Electric motor', labelAt: [98, 60] },
      { id: 'link', shape: 'line', from: [44, 78], to: [75, 78], style: 'thin' },
      { id: 'spark', shape: 'dot', x: 38, y: 9, r: 2, style: 'spark', hidden: true, label: 'First spark', labelAt: [98, 20] }
    ],
    steps: [
      { show: ['mix'], restyle: { motor: 'accent' }, note: 'The motor pulls fuel and air in' },
      { move: { piston: [0, -22] }, hide: ['mix'], show: ['tight'], note: 'The motor squeezes it' },
      { show: ['spark', 'fire'], hide: ['tight'], note: 'A spark lights the load' },
      { move: { piston: [0, 0] }, hide: ['spark', 'link'], restyle: { motor: 'thin' }, note: 'The push: the motor lets go' }
    ] };

  window.EXPLAINER = {
    id: 'car-engine',
    title: 'Why does a car engine need an electric motor just to start?',
    kind: 'full',
    theme: 'machines',
    cards: [
      { type: 'card',
        title: 'Once it\'s running, it keeps itself going for hours.',
        text: 'Press start, and a small electric motor turns the engine for a moment before it runs by itself.',
        hook: 'So how does burning petrol turn an engine at all?',
        visual: starter },
      { type: 'card', title: 'Hot gas pushes a sliding plug that turns a shaft',
        text: 'Inside, petrol and air burn in a metal tube called a cylinder. The hot gas pushes a sliding plug, the piston, along the tube. A rod links the piston to a bent shaft. Each push turns the shaft, like your leg on a bike pedal.',
        hook: 'But can the piston push every time it moves?',
        visual: { type: 'crank', interactive: false, speed: 40, start: 40, parts: true,
          labels: { partPiston: 'Piston', partRod: 'Rod', partCrank: 'Bent shaft', partCylinder: 'Cylinder' } } },
      { type: 'card', title: 'The piston makes four moves, and only one pushes',
        text: 'First it pulls fuel and air in, then squeezes them tight. Then a spark lights them. Packed tight, the burning gas pushes the piston much harder. Last, it clears the used gas out of the engine.',
        hook: 'So what moves the piston for the other three?',
        visual: { type: 'strokes', interactive: false, speed: 70, strokes: moves, labels: moveLabels } },
      { type: 'card', title: 'The turning shaft drags the piston through the other three',
        text: 'At the start nothing is turning yet, so nothing can drag it. The electric motor turns the shaft until a spark lights the first squeezed load.',
        hook: 'So once it\'s going, what keeps the shaft turning?',
        visual: firstSpark },
      { type: 'card', title: 'A heavy wheel keeps the shaft turning between pushes',
        text: 'Its weight carries the piston through the other three moves. And several cylinders take turns, so the pushes come close together and the engine runs smoothly.',
        takeaway: 'An engine can only push once it has pulled in and squeezed its fuel, so something else turns it first.',
        visual: { type: 'cylinders', speed: 120, selected: 0, tip: 'Tap 4 to compare',
          labels: { unit: 'Cylinders', graphTitle: 'Push on the shaft' }, options: [{ n: 1, order: [1] }, { n: 4, order: [1, 3, 4, 2] }] } },
      { type: 'more', links: ['bike-gears'], note: 'The first engine to squeeze its fuel and air before lighting it was built by Nicolaus Otto in Germany in 1876, and it ran far better than every engine before it. Engines that squeeze their fuel and air and work in four moves still run on what\'s called the Otto cycle.' }
    ]
  };
})();
