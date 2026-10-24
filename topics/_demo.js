// Fixture topic: exercises every card type and every visual type. Placeholder text at the realistic length.
window.EXPLAINER = {
  id: '_demo',
  title: 'How a demo engine works',
  kind: 'full',
  theme: 'machines',
  cards: [
    { type: 'cover', title: 'How does an engine turn fuel into motion?', lead: 'Four strokes, one spinning shaft, and a lot of tiny bangs.',
      visual: { type: 'crank', interactive: false, speed: 40, start: 40 } },
    { type: 'card', title: 'A piston pushes, a crank spins', text: 'A piston slides up and down in a tube. A rod links it to a bent shaft, so the straight push becomes a turn.',
      takeaway: 'Straight pushes in, spinning out.',
      visual: { type: 'crank', speed: 40, start: 40, parts: true, labels: { drag: 'Drag' } } },
    { type: 'card', title: 'Four strokes make one cycle', text: 'Suck air and fuel in, squeeze it, light it, then blow the burnt gas out. Only the third stroke pushes.',
      takeaway: 'One bang for every two spins.',
      visual: { type: 'strokes', speed: 70, labels: { intake: 'Air + fuel in', exhaust: 'Gas out', spark: 'Spark plug' } } },
    { type: 'card', title: 'More cylinders push more smoothly', text: 'One cylinder fires once every two spins, so the push is bumpy. Four take turns and fill the gaps.',
      takeaway: 'Take turns and the push evens out.',
      visual: { type: 'cylinders', speed: 120, selected: 1, options: [{ n: 1, order: [1] }, { n: 4, order: [1, 3, 4, 2] }, { n: 8, order: [1, 8, 4, 3, 6, 5, 7, 2] }] } },
    { type: 'guess', title: 'What actually pushes the car forward?',
      options: ['Exhaust gas shooting out the back', 'Burning fuel pushing the pistons', 'The spark plug'],
      answer: 1, why: 'Burning fuel makes hot gas that shoves the pistons. The spark only lights it, and exhaust leaves with little force.' },
    { type: 'guess', title: 'Which way does the big gear turn?',
      options: ['The same way as the small one', 'The opposite way', 'It depends on the speed'],
      answer: 1, why: 'Teeth that mesh push each other round in opposite directions. The big one is slower but stronger.',
      visual: { type: 'gears', driving: 14, driven: 36, speed: 0.1 } },
    { type: 'card', title: 'Count the teeth to find the ratio', text: 'The small gear has 15 teeth, the big one 50. Drag the small one and count how often it turns per big turn.',
      takeaway: 'More teeth means slower and stronger.',
      visual: { type: 'gears', interactive: true, labels: { driver: 'Small', driven: 'Big', teeth: '{n} teeth' },
        sets: [{ label: 'Low', gears: [{ name: '1', driving: 15, driven: 50 }, { name: '2', driving: 20, driven: 40 }, { name: '3', driving: 28, driven: 30 }], spin: 0.15, rpmStart: 1500 }] } },
    { type: 'more', links: ['_demo2'], note: 'Gears are only half of the story.' }
  ]
};
