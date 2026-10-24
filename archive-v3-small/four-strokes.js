// Engine series 3/4: why an engine needs four strokes.
window.EXPLAINER = {
  id: 'four-strokes',
  title: 'Why an engine works in four strokes',
  kind: 'bite',
  theme: 'machines',
  cards: [
    { type: 'card', title: 'Each piston pushes once every four trips',
      text: 'A piston is a plug sliding in a tube; each trip up or down is a stroke. Fuel must come in, be squeezed, burn, then leave: one stroke each.',
      visual: { type: 'strokes', speed: 70, strokes: ['Suck in', 'Squeeze', 'Bang', 'Blow out'], labels: { intake: 'Fuel + air in', exhaust: 'Gas out', spark: 'Spark plug' } } },
    { type: 'card', title: 'Only the bang pushes the piston',
      text: 'The bang is a spark lighting the squeezed fuel. Squeezing first makes it stronger. The other three strokes only get ready for it.',
      takeaway: 'One push in four trips.',
      visual: { type: 'strokes', speed: 70, only: 2, strokes: ['Suck in', 'Squeeze', 'Bang', 'Blow out'], labels: { intake: 'Fuel + air in', exhaust: 'Gas out', spark: 'Spark plug' } } },
    { type: 'guess', title: 'What moves the piston on the other three trips?',
      options: ['The spinning crankshaft drags it along', 'A spring pulls it back up', 'Air rushing in pushes it'],
      answer: 0,
      why: 'The piston turns a shaft, the crankshaft. A heavy spinning wheel on it, the flywheel, keeps going between bangs and drags the piston along, like a merry-go-round after a shove.',
      visual: { type: 'crank', interactive: false, speed: 60, start: 40, parts: true, hint: false } },
    { type: 'more', links: ['crank', 'cylinders'], note: 'One cylinder gets a push only once in four trips. Next: how engines smooth that out.' }
  ]
};
