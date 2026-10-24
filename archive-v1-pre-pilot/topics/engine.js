(function () {
  var STROKES = [
    { name: 'Intake', word: 'Suck', gas: 'mix', text: 'Fuel and air flow in.' },
    { name: 'Compression', word: 'Squeeze', gas: 'mixhi', text: 'The mix is squeezed.' },
    { name: 'Power', word: 'Bang', gas: 'burn', text: 'The burning gas pushes.' },
    { name: 'Exhaust', word: 'Blow', gas: 'exh', text: 'Burnt gas is pushed out.' }
  ];
  var TIMING = { intake: [0, 190], exhaust: [530, 720], ramp: 25 };
  function stroke(i, kicker, title, lead, labels) {
    return {
      type: 'sequence',
      kicker: kicker,
      title: title,
      lead: lead,
      strokes: STROKES,
      params: { intake: TIMING.intake, exhaust: TIMING.exhaust, ramp: TIMING.ramp, speed: 60, only: i },
      labels: Object.assign({ sliderLabel: 'Move through this stroke', intake: '', exhaust: '', spark: '', push: 'PUSH' }, labels)
    };
  }

  window.EXPLAINER = {
    id: 'car-engine',
    title: 'How a Car Engine Works',
    ariaLabel: 'How a car engine works. Swipe up through the cards.',
    cards: [
      {
        type: 'intro',
        title: 'Introduction',
        kicker: 'How a car engine works',
        headline: [
          { t: 'Ever wondered how an ' },
          { t: 'engine', em: true },
          { t: ' works?' }
        ],
        meta: '{n} short cards. You will drag, guess and play with a working engine model.',
        hows: [
          { k: 'Swipe up', t: 'to move to the next card.' },
          { k: 'Guess first', t: 'then see the answer.' }
        ],
        start: 'Start',
        visual: 'crank',
        params: { speed: 40, start: 40 }
      },
      {
        type: 'hook',
        kicker: 'On the highway',
        headline: [
          { t: 'A car engine explodes fuel ' },
          { t: '100 times a second.', em: true }
        ],
        question: 'So how do the wheels spin smoothly?',
        mathLabel: 'Where does 100 come from?',
        math: [
          'On the highway, the engine’s main shaft (the crankshaft) spins about 3,000 times a minute.',
          'A minute has 60 seconds. 3,000 ÷ 60 = 50 spins every second.',
          'Each cylinder (a tube where fuel burns) fires once every 2 spins: 25 a second.',
          'This engine has 4 cylinders. 4 × 25 = 100 bangs a second.'
        ],
        cue: 'Swipe up',
        visual: 'engine-cycle',
        params: { intake: [0, 190], exhaust: [530, 720], ramp: 25, speed: 90, start: 420 },
        labels: { push: 'PUSH' }
      },
      {
        type: 'predict',
        kicker: 'Predict first',
        q: 'What actually pushes the car forward?',
        lead: 'Pick one. A guess makes the answer stick.',
        options: [
          { t: 'Exhaust gas shooting out the back like a rocket', why: 'Exhaust leaves with little force. A rocket moves by throwing gas backwards. A car moves because its wheels grip the road.' },
          { t: 'Burning fuel pushing engine parts', ok: true, why: 'Burning fuel makes hot gas that shoves pistons, metal plugs inside the engine. They spin a shaft, and gears pass that spin to the wheels.' },
          { t: 'The spark plug', why: 'The spark plug only lights the fuel. The push comes from the fuel burning.' },
          { t: 'The battery', why: 'The battery starts the engine and powers the spark. Once the engine runs, burning fuel does the work.' }
        ],
        model: 'Burning fuel pushes parts that spin a shaft.'
      },
      {
        type: 'sim-crank',
        kicker: 'The parts',
        title: 'Meet the parts',
        lead: 'A piston slides up and down inside a tube called the cylinder. A rod links it to the crankshaft, a bent bar that spins.',
        params: { rodRatio: 3.2, speed: 40, start: 40, parts: true, hide: ['readout', 'guides', 'arc', 'hint', 'slider'] },
        labels: { sliderLabel: 'Turn the crankshaft', partPiston: 'PISTON', partRod: 'ROD', partCrank: 'CRANKSHAFT', partCylinder: 'CYLINDER' }
      },
      {
        type: 'sim-crank',
        kicker: 'Try it',
        title: 'Push becomes spin',
        lead: 'Drag the orange ring round and watch the piston. (In a real engine, the piston does the pushing.)',
        params: { rodRatio: 3.2, speed: 50, start: 40, hide: ['guides', 'arc', 'stat0', 'stat2'] },
        labels: { sliderLabel: 'Turn the crankshaft', piston: 'PISTON', top: 'AT THE TOP', bottom: 'AT THE BOTTOM', down: 'MOVING DOWN', up: 'MOVING UP', drag: 'DRAG' },
        model: 'An engine turns straight-line pushes into spinning.'
      },
      stroke(0, 'Stroke 1/4', 'Intake: breathe in',
        'A stroke is one trip of the piston, up or down. Here it drops and sucks fuel and air in through a small door, the intake valve.',
        { intake: 'INTAKE VALVE' }),
      stroke(1, 'Stroke 2/4', 'Compression: squeeze',
        'Both valves, intake and exhaust, are shut. The piston rises and squeezes the fuel-air mix.',
        { intake: 'INTAKE VALVE', exhaust: 'EXHAUST VALVE' }),
      stroke(2, 'Stroke 3/4', 'Power: bang',
        'A spark plug lights the squeezed mix. The burning gas shoves the piston down and pushes the crankshaft. Only this stroke does.',
        { spark: 'SPARK PLUG' }),
      stroke(3, 'Stroke 4/4', 'Exhaust: breathe out',
        'The exhaust valve opens. The piston rises and shoves the burnt gas out through the exhaust pipe.',
        { exhaust: 'EXHAUST VALVE' }),
      {
        type: 'sequence',
        kicker: 'All four, one cycle',
        title: 'Drag to run it',
        lead: 'One stroke is half a spin. Four strokes make two spins, so a cylinder fires once every 2 spins.',
        strokes: STROKES,
        params: { intake: [0, 190], exhaust: [530, 720], ramp: 25, speed: 80, start: 440, hide: ['count', 'chips', 'desc'] },
        labels: {
          sliderLabel: 'Position in the four-stroke cycle',
          intake: 'INTAKE VALVE', exhaust: 'EXHAUST VALVE', spark: 'SPARK PLUG', push: 'PUSH'
        },
        model: 'Suck, squeeze, bang, blow. Only the bang pushes.'
      },
      {
        type: 'predict',
        kicker: 'Predict first',
        q: 'What moves the piston on the other three strokes?',
        lead: 'Only the bang pushes. Pick one.',
        options: [
          { t: 'The battery keeps pushing the piston', why: 'The battery only powers the spark and the starter. It does not push the piston.' },
          { t: 'The crankshaft keeps spinning', ok: true, why: 'The spinning crankshaft keeps the piston moving, helped by a heavy wheel on it, the flywheel. The other cylinders push too. A starter motor spins it to begin.' },
          { t: 'A second engine', why: 'There is only one engine. Its other cylinders take turns pushing, which keeps the crankshaft turning.' }
        ],
        model: 'Only one stroke pushes. The spin carries the rest.'
      },
      {
        type: 'predict',
        kicker: 'Predict first',
        q: 'Why squeeze the mix before lighting it?',
        lead: 'Pick one.',
        options: [
          { t: 'Less room means a harder push', ok: true, why: 'Gas squeezed into less room pushes back harder. The next card shows how much.' },
          { t: 'It mixes the fuel and air better', why: 'The fuel and air are already mixed as they flow in. The squeeze is for a harder push.' },
          { t: 'It fits more fuel in', why: 'The amount of fuel is the same. It is just packed into less room.' }
        ]
      },
      {
        type: 'reveal',
        kicker: 'Our petrol engine',
        q: 'Squeeze more, push harder',
        lead: 'Gas squeezed into less room pushes back harder.',
        explain: 'Squeezed to a tenth of its space (10:1), the burning mix pushes about 70 times harder than the air around you.',
        viz: {
          kind: 'compression',
          label: 'Squeeze ratio',
          min: 1, max: 10, start: 1, step: 0.1, durationMs: 1800,
          format: '{v} : 1',
          gauge: { title: ['PRESSURE WHEN', 'IT BURNS'], unit: 'x AIR', prefix: '~', exponent: 1.3, scale: 3.5, full: 75 }
        },
        model: 'Squeeze first, and the same fuel pushes harder.'
      },
      {
        type: 'predict',
        kicker: 'Predict first',
        q: 'A diesel has no spark plug. What lights it?',
        lead: 'Pick one.',
        options: [
          { t: 'Friction from the piston rubbing the walls', why: 'Friction wastes some heat, but it is not what lights the fuel. The heat comes from squeezing the air.' },
          { t: 'A tiny flame kept burning inside', why: 'There is no pilot flame. The fuel only burns once, at the start of the power stroke.' },
          { t: 'Squeezing makes the air very hot', ok: true, why: 'A diesel squeezes air to a sixteenth or twentieth of its space. That makes it so hot that fuel sprayed in lights by itself.' }
        ],
        model: 'Squeeze air hard enough and it lights the fuel.'
      },
      {
        type: 'sim-cylinders',
        kicker: 'Four cylinders',
        title: 'Taking turns',
        lead: 'Real engines use several cylinders. The numbers name them. They fire in turn, 1-3-4-2, spreading the pushes along the crankshaft.',
        options: [{ n: 4, order: [1, 3, 4, 2] }],
        params: { speed: 90, selected: 0, rodRatio: 3.2, hide: ['graph', 'segs', 'peak'] },
        labels: { groupLabel: 'Number of cylinders', unit: 'CYL', order: 'FIRING ORDER' }
      },
      {
        type: 'sim-cylinders',
        kicker: 'Try 1, 4 and 8',
        title: 'Smoother with more',
        lead: 'Tap how many cylinders. The orange line is the push on the crankshaft. Fewer cylinders, bumpier push.',
        options: [
          { n: 1, order: [1] },
          { n: 4, order: [1, 3, 4, 2] },
          { n: 8, order: [1, 8, 4, 3, 6, 5, 7, 2] }
        ],
        params: { speed: 120, selected: 0, rodRatio: 3.2, hide: ['order'] },
        labels: {
          groupLabel: 'Number of cylinders', unit: 'CYL',
          peak: 'BIGGEST PUSH IS', peakUnit: 'x THE AVERAGE',
          graphTitle: 'PUSH ON CRANKSHAFT', now: 'NOW', average: 'AVERAGE'
        },
        model: 'More, smaller pushes keep the wheels spinning smoothly.'
      },
      {
        type: 'recall',
        kicker: 'Lock it in',
        title: 'Quick recall',
        lead: 'Four questions, no new facts. Answer from memory.',
        closing: 'Pulling it from memory is what makes it stick. Try this again tomorrow and see what you still know.',
        questions: [
          { q: 'Which stroke is the only one that pushes?', options: ['Compression', 'Power', 'Exhaust'], a: 1, why: 'Power. The burning gas shoves the piston down.' },
          { q: 'What turns the piston’s up-and-down push into spinning?', options: ['Spark plug', 'Intake valve', 'Crankshaft'], a: 2, why: 'The crankshaft. The piston pushes it round through the rod.' },
          { q: 'Why squeeze the mix before the spark?', options: ['To keep the valves shut', 'For a harder push', 'To mix fuel and air'], a: 1, why: 'A smaller space means higher pressure when it burns.' },
          { q: 'Why does a 4-cylinder run smoother than a 1-cylinder?', options: ['Its pushes come one after another, with fewer gaps', 'Its pistons are bigger', 'It squeezes the mix harder'], a: 0, why: 'More, smaller pushes arrive one after another, so there are fewer gaps between them.' }
        ]
      },
      {
        type: 'branches',
        kicker: 'Go deeper',
        title: 'Where next?',
        lead: 'Not written yet. Tap the ones you want and your taps decide what comes first.',
        items: [
          'V6 vs V8 vs W16: why the shapes?',
          'What does a turbo do?',
          'Why do engines need oil?',
          { t: 'How a gearbox works', href: 'https://claude.ai/artifact/5vy4i2LsnqvxJd1BUf8dRK', topic: 'gearbox' },
          'How electric motors are different'
        ],
        soon: 'Coming next. You just voted for this one.',
        restart: 'Start over'
      }
    ]
  };
})();
