window.EXPLAINER = {
  id: 'engine',
  title: 'How a car engine works',
  kind: 'full',
  theme: 'machines',
  cards: [
    { type: 'cover', title: 'How does a car engine work?', lead: 'Tiny fires push a plug up and down, and a shaft spins.',
      visual: { type: 'crank', interactive: false, speed: 40, start: 40 } },
    { type: 'card', title: 'Burning fuel gives a big push', text: 'Burning fuel makes very hot gas that pushes hard to expand. Sealed in a tube, it shoves a sliding plug, the piston.',
      takeaway: 'An engine does this again and again.',
      visual: { type: 'diagram', view: [100, 96],
        parts: [
          { id: 'mix', shape: 'rect', x: 31, y: 11, w: 38, h: 9, style: 'blue', label: 'Fuel + air', labelAt: [98, 12] },
          { id: 'gas1', shape: 'rect', x: 31, y: 11, w: 38, h: 9, style: 'heat', hidden: true, label: 'Hot gas', labelAt: [98, 12] },
          { id: 'gas2', shape: 'rect', x: 31, y: 11, w: 38, h: 49, style: 'heat', hidden: true, label: 'Hot gas', labelAt: [98, 12] },
          { id: 'tube', shape: 'path', points: [[30, 88], [30, 10], [70, 10], [70, 88]], fill: false },
          { id: 'piston', shape: 'rect', x: 31, y: 20, w: 38, h: 8, style: 'accent', label: 'Piston', labelAt: [2, 24] },
          { id: 'spark', shape: 'dot', x: 50, y: 11, r: 2, style: 'heat', hidden: true },
          { id: 'push', shape: 'arrow', from: [50, 73], to: [50, 93], style: 'accent', hidden: true }
        ],
        steps: [
          { note: 'Fuel and air, sealed in' },
          { show: ['gas1', 'spark'], hide: ['mix'], note: 'A spark lights it' },
          { show: ['gas2', 'push'], hide: ['gas1', 'spark'], move: { piston: [0, 40] }, note: 'Hot gas swells and pushes' }
        ] } },
    { type: 'guess', title: 'Where does the engine\'s push come from?',
      options: ['The spark that lights the fuel', 'The waste gas rushing out the tailpipe', 'The fuel burning inside the engine'],
      answer: 2, why: 'Burning fuel makes hot gas that pushes the pistons. The spark only lights it, and the waste gas leaves with little force.',
      visual: { type: 'crank', interactive: false, speed: 40, start: 40 } },
    { type: 'card', title: 'A crank turns the push into a spin', text: 'A rod joins the piston to a bent shaft, the crankshaft. Each push down makes it turn, like your foot on a pedal.',
      takeaway: 'Straight push in, spin out.',
      visual: { type: 'crank', speed: 40, start: 40, parts: true, labels: { drag: 'Drag' } } },
    { type: 'card', title: 'One cycle takes four trips', text: 'One cycle is four piston trips, called strokes: suck in, squeeze, bang, blow out. Squeezing first makes the bang stronger.',
      takeaway: 'Only the bang pushes.',
      visual: { type: 'strokes', speed: 70, labels: { intake: 'Fuel + air in', exhaust: 'Gas out', spark: 'Spark plug' } } },
    { type: 'guess', title: 'So what moves the piston on the other three trips?',
      options: ['The spinning shaft drags it along', 'A spring pulls it back up', 'Air rushing in pushes it'],
      answer: 0, why: 'A heavy wheel on the shaft, the flywheel, keeps it spinning between bangs and drags the piston along, like a bike wheel turning the pedals.',
      visual: { type: 'crank', interactive: false, speed: 60, start: 40, parts: true } },
    { type: 'card', title: 'Several cylinders take turns', text: 'A cylinder is a tube with its piston. Its four strokes take two turns of the shaft, so one cylinder alone pushes in jerks. Four take turns.',
      takeaway: 'More cylinders, smoother push.',
      visual: { type: 'cylinders', speed: 120, selected: 1, options: [{ n: 1, order: [1] }, { n: 4, order: [1, 3, 4, 2] }, { n: 8, order: [1, 8, 4, 3, 6, 5, 7, 2] }] } },
    { type: 'card', title: 'The engine spins too fast for the wheels', takeaway: 'Gears slow the spin down.', text: 'The shaft drives the wheels through gears. Engines work best spinning fast, about 3,000 a minute on the highway, but each wheel turns only about 800.',
      visual: { type: 'diagram', view: [100, 90],
        parts: [
          { id: 'eng', shape: 'rect', x: 4, y: 26, w: 30, h: 26, style: 'accent', label: 'Engine', labelAt: [2, 18] },
          { id: 'e1', shape: 'text', x: 19, y: 39, text: '3,000' },
          { id: 'axle', shape: 'line', from: [34, 39], to: [61, 39], style: 'thin' },
          { id: 'gb', shape: 'rect', x: 38, y: 27, w: 24, h: 24, style: 'thin', hidden: true, label: 'Gears', labelAt: [50, 8] },
          { id: 'wheel', shape: 'circle', x: 78, y: 39, r: 17, style: 'ink', label: 'Each wheel', labelAt: [98, 18] },
          { id: 'w1', shape: 'text', x: 78, y: 39, text: '800', hidden: true },
          { id: 'u', shape: 'text', x: 50, y: 72, text: 'Spins per minute' }
        ],
        steps: [
          { note: 'Engine: about 3,000' },
          { show: ['w1'], focus: ['wheel', 'w1', 'axle'], note: 'Each wheel: about 800' },
          { show: ['gb'], focus: ['gb', 'axle', 'eng', 'wheel'], note: 'Gears slow it down' }
        ] } },
    { type: 'more', links: ['gearbox'], note: 'The engine spins fast. Next, how gears slow it.' }
  ]
};
