// Engine series 2/4: how a push becomes a spin (crank visual).
window.EXPLAINER = {
  id: 'crank',
  title: 'How a push becomes a spin',
  kind: 'bite',
  theme: 'machines',
  cards: [
    { type: 'card', title: 'An engine pushes up and down. Wheels need spin.',
      text: 'In a car engine, a plug called the piston slides up and down a tube. Something must turn that straight push into a spin.',
      visual: { type: 'crank', interactive: false, speed: 40, start: 40, parts: true, hint: false } },
    { type: 'card', title: 'A bent shaft turns the push into a spin',
      text: 'A rod links the piston to a bent shaft, the crankshaft. Pushing down on the bend turns it, like your foot on a bike pedal.',
      takeaway: 'Straight push in, spin out.',
      visual: { type: 'crank', speed: 40, start: 40, parts: true, labels: { drag: 'Drag' } } },
    { type: 'more', links: ['engine-push', 'four-strokes'], note: 'One push is only part of the job. Next: why an engine needs four strokes.' }
  ]
};
