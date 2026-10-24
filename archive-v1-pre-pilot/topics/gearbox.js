window.EXPLAINER = {
  id: 'gearbox',
  title: 'How a Gearbox Works',
  ariaLabel: 'How a gearbox works, in cars and motorcycles. Swipe up through the cards.',
  cards: [
    {
      type: 'intro',
      title: 'Introduction',
      kicker: 'How a gearbox works',
      headline: [
        { t: 'Ever wondered why cars need ' },
        { t: 'gears', em: true },
        { t: '?' }
      ],
      meta: '{n} short cards. You will guess first, then turn real gears and shift a car and a motorbike.',
      hows: [
        { k: 'Swipe up', t: 'to move to the next card.' },
        { k: 'Guess first', t: 'then see the answer.' },
        { k: 'Drag', t: 'the small gear to turn it.' }
      ],
      start: 'Start',
      visual: 'gears',
      params: { driving: 14, driven: 50, speed: 0.07 }
    },
    {
      type: 'hook',
      kicker: 'How a gearbox works',
      headline: [
        { t: 'Pulling away, the engine spins ' },
        { t: '14 times per wheel turn.', em: true }
      ],
      question: 'Why would a car spin its engine that much?',
      mathLabel: 'Where does 14 come from?',
      math: [
        'Pulling away uses 1st gear.',
        'In 1st gear the engine turns about 3.3 times for each turn of the rod out of the gearbox.',
        'That rod turns about 4.2 times for each wheel turn.',
        '3.3 × 4.2 is about 14. Rough values.'
      ],
      cue: 'Swipe up',
      visual: 'gears',
      params: { driving: 20, driven: 44, speed: 0.1 }
    },
    {
      type: 'predict',
      kicker: 'Twisting force',
      q: 'Where is a heavy door easiest to push?',
      lead: 'Twisting force turns doors, lids and bolts.',
      options: [
        { t: 'Right next to the hinge', why: 'Near the hinge your push has almost no lever.' },
        { t: 'Far from the hinge, at the handle', ok: true, why: 'A long lever turns the same push into more twisting force. A long spanner works the same way.' },
        { t: 'It is the same everywhere', why: 'Try it. Distance from the hinge changes the twist.' }
      ],
      model: 'A longer lever gives more twisting force.'
    },
    {
      type: 'reveal',
      kicker: 'A bicycle on a hill',
      q: 'On a bicycle, why shift to an easy gear for a hill?',
      lead: 'Easy gear: you pedal a lot, the wheel turns little.',
      options: [
        { t: 'The bicycle goes faster', why: 'The opposite. The wheel turns only a little per pedal turn.' },
        { t: 'The wheel turns slower but twists harder', ok: true },
        { t: 'It gives the bicycle more power', why: 'Gears never add power. They trade speed for twist.' }
      ],
      explain: 'An easy gear trades speed for twist: the wheel turns slowly but pushes hard, enough for a hill. A hard gear is the opposite.',
      model: 'Easy gear: slow but strong. Hard gear: fast but weak.'
    },
    {
      type: 'reveal',
      kicker: 'Back to the car',
      q: 'So why does a car need several gears?',
      lead: 'Remember the 14 engine turns per wheel turn.',
      options: [
        { t: 'One gear would be enough', why: 'A heavy car needs a big twist to start, but a small one to cruise.' },
        { t: 'No single gear can start strongly and go fast', ok: true },
        { t: 'Gears make the engine more powerful', why: 'Gears never add power. They trade speed for twist.' }
      ],
      explain: 'In 1st, the engine turns about 14 times per wheel turn. That multiplies its twist, enough to move a heavy car. But 1st cannot go fast.',
      model: 'No single gear can both pull away and go fast.'
    },
    {
      type: 'sim-gears',
      kicker: 'The gearbox',
      title: 'Pairs of gears',
      lead: 'A gearbox is a set of gear pairs between engine and wheels. The engine turns the small gear. The big one passes the turn on.',
      params: { mode: 'rpm', hide: ['readout', 'gears', 'slider', 'play', 'fig', 'slowmo'] },
      sets: [
        {
          gears: [{ name: '1', driving: 15, driven: 50 }],
          rpmMax: 6000, rpmStart: 2000, rpmStep: 100, spin: 0.15
        }
      ],
      labels: { driver: 'FROM ENGINE', driven: 'TO WHEELS', teeth: '' }
    },
    {
      type: 'sim-gears',
      kicker: 'Gears',
      title: 'Count the teeth',
      lead: 'The small gear has 15 teeth, the big one 50. Drag the small one: it turns about 3.3 times for each big turn.',
      params: { mode: 'rpm', hide: ['readout', 'gears', 'slider', 'play', 'fig', 'slowmo'] },
      sets: [
        {
          gears: [{ name: '1', driving: 15, driven: 50 }],
          rpmMax: 6000, rpmStart: 2000, rpmStep: 100, spin: 0.15
        }
      ],
      labels: { driver: 'SMALL', driven: 'BIG', teeth: '{n} TEETH' }
    },
    {
      type: 'reveal',
      kicker: 'Why it works',
      q: 'Why does the big gear turn slower but twist harder?',
      lead: 'Think of the door.',
      options: [
        { t: 'It has more teeth, so more power', why: 'Gears never add power. They trade speed for twist.' },
        { t: 'Its teeth are far from its centre', ok: true },
        { t: 'It is heavier, so it resists more', why: 'Weight is not the reason. Distance from the centre is.' }
      ],
      explain: 'The small gear pushes on teeth far from the big gear’s centre, like pushing a door at the handle. More twist. But that edge has further to travel, so it turns slower.',
      model: 'A big gear is a long lever: slower, but stronger. Twice the teeth: half the speed, double the twist.'
    },
    {
      type: 'sim-gears',
      kicker: 'A car’s five gears',
      title: 'Pick a gear',
      lead: 'You use one gear at a time. 1st is the lowest and easiest: slow, strong. Top gear is hardest: fast, weak, and can outspin the engine.',
      params: { mode: 'rpm', set: 0, selected: 0, hide: ['legend', 'slowmo', 'fig', 'stat0', 'play', 'slider'] },
      sets: [
        {
          gears: [
            { name: '1', driving: 15, driven: 50 },
            { name: '2', driving: 21, driven: 44 },
            { name: '3', driving: 27, driven: 38 },
            { name: '4', driving: 32, driven: 33 },
            { name: '5', driving: 35, driven: 30 }
          ],
          rpmMax: 6000, rpmStart: 3000, rpmStep: 100, spin: 0.2
        }
      ],
      labels: { output: 'BIG GEAR', torque: 'TWIST', rpm: 'TURNS/MIN', gearsGroup: 'Gear' },
      model: 'Lower gear: slower, stronger. Higher gear: faster, weaker.'
    },
    {
      type: 'predict',
      kicker: 'The engine’s pace',
      q: 'On a bicycle, which pedalling pace is best?',
      lead: 'An engine has legs too.',
      options: [
        { t: 'As slowly as possible', why: 'You wobble and stop. A too-slow engine cuts out. That is stalling.' },
        { t: 'As fast as possible', why: 'Tiring and risky. A too-fast engine screams (turns near its top limit) and can break.' },
        { t: 'A steady, comfortable pace', ok: true, why: 'Engines too. A petrol car engine is happiest at about 1,500 to 6,000 turns a minute, called rpm.' }
      ],
      model: 'An engine has a comfy speed, like your legs.'
    },
    {
      type: 'reveal',
      kicker: 'Predict first',
      q: 'In 1st gear you keep speeding up. The engine?',
      lead: 'Remember its comfy range.',
      options: [
        { t: 'Stays at the same speed', why: 'It is tied to the wheels by the gears.' },
        { t: 'Speeds up until it screams', ok: true },
        { t: 'Slows down to save fuel', why: 'Faster wheels pull the engine faster, not slower.' }
      ],
      explain: 'Gears tie engine speed to wheel speed. In 1st, a faster car means a faster engine, until it nears its limit of about 6,000 rpm, at roughly 50 km/h.',
      model: 'In any gear, engine speed follows road speed.'
    },
    {
      type: 'reveal',
      kicker: 'The fix',
      q: 'The engine is screaming. What helps?',
      lead: 'Think of a hard gear on a bicycle.',
      options: [
        { t: 'A higher gear (bigger number)', ok: true },
        { t: 'A lower gear', why: 'A lower gear spins the engine even faster per wheel turn.' },
        { t: 'Stay put and press harder', why: 'That pushes it further past its limit.' }
      ],
      explain: 'A higher gear turns the engine fewer times per wheel turn. The engine calms down and the car keeps speeding up.',
      model: 'Shift up to calm the engine down.'
    },
    {
      type: 'reveal',
      kicker: 'Starting and shifting',
      q: 'What does the clutch pedal do?',
      lead: 'It is the extra pedal in a manual car.',
      options: [
        { t: 'Turns the engine off', why: 'The engine keeps running. Only its link is cut.' },
        { t: 'Briefly disconnects the engine from the wheels', ok: true },
        { t: 'Slows the car down, like a brake', why: 'Brakes slow the wheels. The clutch only breaks the link.' }
      ],
      explain: 'Pressing it briefly disconnects the engine from the wheels, so the gears can switch without grinding.',
      model: 'Disconnect, switch gear, reconnect.'
    },
    {
      type: 'reveal',
      kicker: 'Starting off',
      q: 'The car is stopped, engine running. How?',
      lead: 'The wheels are not turning, but the engine is.',
      options: [
        { t: 'The engine switches off at each stop', why: 'It would cut out. A running engine needs a way to stay free.' },
        { t: 'The clutch keeps the engine disconnected', ok: true },
        { t: 'The wheels spin freely', why: 'The wheels stay locked to the gears. The clutch does the separating.' }
      ],
      explain: 'Clutch down: the engine runs while the car stands still. Pedal up slowly: the clutch slips, passing the turn bit by bit, and the car eases away.',
      model: 'The clutch slips to ease the car into motion.'
    },
    {
      type: 'sim-gears',
      kicker: 'Try it: car',
      title: 'Keep the arrow green',
      lead: 'Start in 1st, then speed up. Change gear to keep the arrow in the green zone.',
      params: { mode: 'speed', set: 0, selected: 0, hide: ['legend', 'slowmo', 'fig', 'stat2', 'play'] },
      sets: [
        {
          gears: [
            { name: '1', driving: 15, driven: 50 },
            { name: '2', driving: 21, driven: 44 },
            { name: '3', driving: 27, driven: 38 },
            { name: '4', driving: 32, driven: 33 },
            { name: '5', driving: 35, driven: 30 }
          ],
          final: 4.2, wheel: 1.98,
          band: [1500, 6000], redline: 6500, idle: 800, scaleMax: 7500,
          speedMax: 180, speedStart: 25, spin: 0.2
        }
      ],
      labels: {
        engine: 'ENGINE', road: 'ROAD SPEED', rpm: 'RPM',
        band: 'COMFY RANGE', ok: 'COMFY', low: 'TOO SLOW', over: 'TOO FAST', slip: 'CLUTCH SLIPS',
        gearsGroup: 'Gear'
      }
    },
    {
      type: 'sim-gears',
      kicker: 'Try it: motorbike',
      title: 'Same game, higher range',
      lead: 'Motorbike engines like a much higher speed, about 9,000 to 14,000 rpm.',
      params: { mode: 'speed', set: 0, selected: 0, hide: ['legend', 'slowmo', 'fig', 'stat2', 'play'] },
      sets: [
        {
          gears: [
            { name: '1', driving: 18, driven: 46 },
            { name: '2', driving: 21, driven: 43 },
            { name: '3', driving: 24, driven: 40 },
            { name: '4', driving: 26, driven: 38 },
            { name: '5', driving: 28, driven: 36 },
            { name: '6', driving: 30, driven: 34 }
          ],
          final: 5.8, wheel: 1.98,
          band: [9000, 14000], redline: 14500, idle: 1300, scaleMax: 17000,
          speedMax: 250, speedStart: 20, spin: 0.08
        }
      ],
      labels: {
        engine: 'ENGINE', road: 'ROAD SPEED', rpm: 'RPM',
        band: 'COMFY RANGE', ok: 'COMFY', low: 'TOO SLOW', over: 'TOO FAST', slip: 'CLUTCH SLIPS',
        gearsGroup: 'Gear'
      }
    },
    {
      type: 'recall',
      kicker: 'Lock it in',
      title: 'Quick recall',
      lead: 'Three questions, no new facts. Trying to remember is what makes it stick.',
      questions: [
        { q: 'A small gear turns a gear with twice its teeth. The big gear is?', options: ['Half the speed, half the twist', 'Same speed, double the twist', 'Half the speed, double the twist'], a: 2, why: 'Twice the teeth: half the speed, double the twist.' },
        { q: 'Why does a car need more than one gear?', options: ['Gears add power', 'Easy gear to pull away, hard gear for speed', 'Bigger engines do not need gears'], a: 1, why: 'One gear cannot give both a strong start and a high top speed.' },
        { q: 'The engine screams as the car speeds up. Best move?', options: ['Shift to a higher gear', 'Shift to a lower gear', 'Press the accelerator harder'], a: 0, why: 'A higher gear needs fewer engine turns for the same road speed.' }
      ]
    },
    {
      type: 'reveal',
      kicker: 'Bonus: motorbikes',
      q: 'On a motorbike, which way is 1st gear?',
      lead: 'No stick, just a foot lever. Neutral (no gear) sits between 1st and 2nd.',
      options: [
        { t: 'Tap the lever up', why: 'Up is for 2nd to 6th.' },
        { t: 'Tap the lever down', ok: true, why: 'Down once for 1st, then up for 2nd to 6th.' }
      ],
      explain: 'First gear is one tap down. Second to sixth are five taps up. One down, five up.'
    },
    {
      type: 'branches',
      kicker: 'Go deeper',
      title: 'Where next?',
      lead: 'Tap the ones you want. Your taps decide what we write first.',
      items: [
        { t: 'How does an engine work?', href: 'https://claude.ai/artifact/47dT3dkGhANEzEWf64UFhP', topic: 'engine' },
        'Automatic gearboxes and CVTs',
        'Clutch slip and starting off',
        'Why do trucks have 18 gears?',
        'Electric cars have one gear. How?'
      ],
      go: 'Read this one',
      soon: 'Coming next. You just voted for this one.',
      restart: 'Start over'
    }
  ]
};
