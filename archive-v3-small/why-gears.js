// Bite: why cars need more than one gear. Card 1 = engine speed band, card 2 = two jobs, card 3 = gearbox picks a pair (interactive gears with a set).
window.EXPLAINER = {
  id: 'why-gears',
  title: 'Why cars need more than one gear',
  kind: 'bite',
  theme: 'machines',
  cards: [
    { type: 'card', title: 'An engine is picky about its speed',
      text: 'A typical petrol car engine works best at about 2,000 to 5,000 turns a minute (rpm). Too slow, it is weak and can stall (stop). Too fast, it gets loud and thirsty.',
      visual: { type: 'diagram', view: [100, 80],
        parts: [
          { id: 'slow', shape: 'rect', x: 8, y: 30, w: 24, h: 16, style: 'blue', text: 'WEAK' },
          { id: 'ok', shape: 'rect', x: 32, y: 30, w: 36, h: 16, style: 'green', text: 'COMFY' },
          { id: 'fast', shape: 'rect', x: 68, y: 30, w: 24, h: 16, style: 'heat', text: 'LOUD' },
          { shape: 'text', x: 32, y: 54, text: '2,000' },
          { shape: 'text', x: 68, y: 54, text: '5,000' },
          { shape: 'text', x: 50, y: 70, text: 'ENGINE SPEED (RPM)' },
          { id: 'needle', shape: 'arrow', from: [20, 10], to: [20, 27], style: 'accent' }
        ],
        steps: [
          { note: 'Too slow: weak, may stall' },
          { move: { needle: [30, 0] }, note: 'In range: happy' },
          { move: { needle: [60, 0] }, note: 'Too fast: loud and thirsty' }
        ] } },
    { type: 'card', title: 'But a car needs two different things',
      text: 'Setting off takes a big push on slow wheels. Cruising needs fast wheels. The engine wants the same comfy speed for both.',
      takeaway: 'One engine speed, two jobs.',
      visual: { type: 'diagram', view: [100, 80],
        parts: [
          { id: 'road', shape: 'rect', x: 0, y: 62, w: 100, h: 6, style: 'hatch' },
          { id: 'body', shape: 'path', points: [[16, 56], [16, 44], [30, 44], [36, 34], [54, 34], [60, 44], [72, 44], [72, 56]], closed: true },
          { id: 'w1', shape: 'circle', x: 29, y: 56, r: 6, style: 'thin' },
          { id: 'w2', shape: 'circle', x: 60, y: 56, r: 6, style: 'thin' },
          { id: 'push', shape: 'arrow', from: [2, 50], to: [15, 50], style: 'accent', label: 'Wheels push', labelAt: [2, 32] },
          { id: 'sp1', shape: 'line', from: [4, 40], to: [12, 40], style: 'thin', hidden: true },
          { id: 'sp2', shape: 'line', from: [2, 48], to: [12, 48], style: 'thin', hidden: true },
          { shape: 'text', x: 50, y: 14, text: 'ENGINE: SAME COMFY RANGE' }
        ],
        steps: [
          { note: 'Setting off: big push' },
          { hide: ['push'], show: ['sp1', 'sp2'], move: { body: [14, 0], w1: [14, 0], w2: [14, 0], sp1: [14, 0], sp2: [14, 0] }, note: 'Cruising: fast wheels' }
        ],
        flows: [ { along: [[0, 65], [100, 65]], style: 'thin', count: 4, speed: 30, during: [1] } ] } },
    { type: 'card', title: 'A gearbox swaps gear pairs',
      text: 'Small turning big is slower but stronger. 1st gear does that, for setting off; 5th is about even, for cruising. Tap each: the engine side spins the same.',
      visual: { type: 'gears', interactive: true,
        sets: [ { label: 'Gearbox', spin: 0.2, rpmStart: 400, gears: [
          { name: '1st', driving: 12, driven: 36 },
          { name: '3rd', driving: 20, driven: 28 },
          { name: '5th', driving: 25, driven: 23 } ] } ],
        labels: { driver: 'Engine side', driven: 'Output side', teeth: '', gear: 'Gear {n}' } } },
    { type: 'more', links: ['two-gears', 'cylinders'] }
  ]
};
