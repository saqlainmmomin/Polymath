// Engine series 4/4: why engines have several cylinders.
window.EXPLAINER = {
  id: 'cylinders',
  title: 'Why engines have several cylinders',
  kind: 'bite',
  theme: 'machines',
  cards: [
    { type: 'card', title: 'One cylinder pushes in jerks',
      text: 'A cylinder is a tube with a piston, a sliding plug. Its four strokes take two turns of the crankshaft, and only one, the bang of burning fuel, pushes.',
      visual: { type: 'cylinders', speed: 120, selected: 0, options: [{ n: 1, order: [1] }] } },
    { type: 'card', title: 'Four cylinders take turns',
      text: 'Four cylinders share those two turns, so one bangs every half turn. The push comes far more often, so the shaft spins smoothly.',
      takeaway: 'More cylinders, smoother push.',
      visual: { type: 'cylinders', speed: 120, selected: 1, options: [{ n: 1, order: [1] }, { n: 4, order: [1, 3, 4, 2] }] } },
    { type: 'more', links: ['four-strokes', 'why-gears'], note: 'Next: the engine spins fast, so how do the wheels cope?' }
  ]
};
