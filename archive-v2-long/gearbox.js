// How a gearbox works (v3): problem -> twist -> two gears trade speed for twist -> gearbox -> 1st vs 5th.
window.EXPLAINER = {
  id: 'gearbox',
  title: 'How a gearbox works',
  kind: 'full',
  theme: 'machines',
  cards: [
    { type: 'cover', title: 'How does a gearbox work?', lead: 'Why a car needs several gears, and what the box does.',
      visual: { type: 'gears', driving: 12, driven: 36, speed: 0.08 } },

    { type: 'card', title: 'An engine likes a narrow speed range', text: 'A car engine pulls best at roughly 2,000 to 5,000 turns a minute (rpm). Slower, it struggles, and near idle (about 800) it can stall, meaning cut out. Faster, it strains.',
      takeaway: 'It wants the middle.',
      visual: { type: 'diagram', view: [100, 80],
        parts: [
          { id: 'slow', shape: 'rect', x: 8, y: 30, w: 24, h: 16, style: 'blue', text: 'WEAK' },
          { id: 'ok', shape: 'rect', x: 32, y: 30, w: 36, h: 16, style: 'green', text: 'COMFY' },
          { id: 'fast', shape: 'rect', x: 68, y: 30, w: 24, h: 16, style: 'heat', text: 'STRAINS' },
          { shape: 'text', x: 32, y: 54, text: '2,000' },
          { shape: 'text', x: 68, y: 54, text: '5,000' },
          { shape: 'text', x: 50, y: 70, text: 'ENGINE SPEED (RPM)' },
          { id: 'needle', shape: 'arrow', from: [20, 10], to: [20, 27], style: 'accent' }
        ],
        steps: [
          { note: 'Too slow: weak, may stall' },
          { move: { needle: [30, 0] }, note: 'In range: happy' },
          { move: { needle: [60, 0] }, note: 'Too fast: it strains' }
        ] } },

    { type: 'card', title: 'The road asks for more than that', text: 'Starting a heavy car from rest takes a big push on the wheels. Cruising needs them spinning fast. The engine only likes its narrow range, so it cannot drive the wheels directly.',
      visual: { type: 'diagram', view: [100, 80],
        parts: [
          { id: 'road', shape: 'rect', x: 0, y: 62, w: 100, h: 6, style: 'hatch' },
          { id: 'body', shape: 'path', points: [[16, 56], [16, 44], [30, 44], [36, 34], [54, 34], [60, 44], [72, 44], [72, 56]], closed: true },
          { id: 'w1', shape: 'circle', x: 29, y: 56, r: 6, style: 'thin' },
          { id: 'w2', shape: 'circle', x: 60, y: 56, r: 6, style: 'thin' },
          { id: 'push', shape: 'arrow', from: [2, 50], to: [15, 50], style: 'accent', label: 'Big push', labelAt: [2, 30] },
          { id: 'sp1', shape: 'line', from: [4, 40], to: [12, 40], style: 'thin', hidden: true },
          { id: 'sp2', shape: 'line', from: [2, 48], to: [12, 48], style: 'thin', hidden: true },
          { shape: 'text', x: 50, y: 14, text: 'ENGINE: SAME COMFY RANGE' }
        ],
        steps: [
          { note: 'Pulling away: big push' },
          { hide: ['push'], show: ['sp1', 'sp2'], move: { body: [14, 0], w1: [14, 0], w2: [14, 0], sp1: [14, 0], sp2: [14, 0] }, note: 'Cruising: fast wheels' }
        ],
        flows: [ { along: [[0, 65], [100, 65]], style: 'thin', count: 4, speed: 30, during: [1] } ] } },

    { type: 'card', title: 'Twist is a push that turns', text: 'Twist, which engineers call torque, is a push that turns. The same push on a longer spanner (wrench) gives more twist, but your hand travels further.',
      takeaway: 'More twist, further to go.',
      visual: { type: 'diagram', view: [100, 80],
        parts: [
          { id: 'big', shape: 'circle', x: 50, y: 40, r: 30, style: 'thin', dash: true, hidden: true },
          { id: 'sm', shape: 'circle', x: 50, y: 40, r: 14, style: 'thin', dash: true, hidden: true },
          { id: 'short', shape: 'rect', x: 50, y: 38, w: 14, h: 4, style: 'ink' },
          { id: 'long', shape: 'rect', x: 50, y: 38, w: 30, h: 4, style: 'ink', hidden: true },
          { id: 'bolt', shape: 'circle', x: 50, y: 40, r: 6, style: 'hatch', label: 'Bolt', labelAt: [14, 66] },
          { id: 'p1', shape: 'arrow', from: [64, 52], to: [64, 42], style: 'accent', label: 'Same push', labelAt: [98, 68] },
          { id: 'p2', shape: 'arrow', from: [80, 52], to: [80, 42], style: 'accent', hidden: true }
        ],
        steps: [
          { note: 'Short spanner: little twist' },
          { hide: ['short', 'p1'], show: ['long', 'p2'], note: 'Long spanner: more twist' },
          { hide: ['short', 'p1'], show: ['long', 'p2', 'big', 'sm'], focus: ['big', 'sm', 'long', 'p2'], note: 'But the hand goes further' }
        ] } },

    { type: 'guess', title: 'A small gear drives a big gear. The big gear turns...',
      options: ['Faster, with more twist', 'Slower, with less twist', 'Slower, with more twist'],
      answer: 2, why: 'Gears cannot make speed and twist from nothing. They trade one for the other, and the big gear gets the twist.',
      visual: { type: 'gears', driving: 10, driven: 30, speed: 0.08 } },

    { type: 'card', title: 'A big gear is a long spanner', text: 'To pass 36 teeth, the 12-tooth gear laps 3 times (36 ÷ 12). The big gear\'s teeth sit 3 times further out: same push, 3 times the twist. Drag to turn.',
      takeaway: 'Slower, stronger.',
      visual: { type: 'gears', driving: 12, driven: 36, speed: 0.07, interactive: true,
        labels: { driver: 'Small', driven: 'Big', teeth: '{n} teeth' } } },

    { type: 'card', title: 'A gearbox is a box of gear pairs', text: 'Changing gear picks a pair, so the engine stays comfy. 1st: slow and strong, for pulling away. 5th: about even, a touch faster, for cruising. 2nd to 4th sit between.',
      visual: { type: 'gears', interactive: true,
        sets: [ { label: 'Gearbox', spin: 0.2, rpmStart: 400, gears: [
          { name: '1st', driving: 12, driven: 36 },
          { name: '3rd', driving: 20, driven: 28 },
          { name: '5th', driving: 28, driven: 24 } ] } ],
        labels: { driver: 'Engine side', driven: 'Output side', teeth: '', gear: 'Gear {n}' } } },

    { type: 'guess', title: 'A manual car pulls away in 5th gear. What happens?',
      options: ['It pulls away, just more slowly', 'The engine usually stalls', 'The gearbox jams'],
      answer: 1, why: '5th gives far less twist than 1st, so the heavy car barely moves. The wheels hardly turn, which holds the engine to a crawl, below its comfy range, and it cuts out.',
      visual: { type: 'gears', interactive: false, selected: 2,
        sets: [ { label: 'Gearbox', spin: 0.2, rpmStart: 400, gears: [
          { name: '1st', driving: 12, driven: 36 },
          { name: '3rd', driving: 20, driven: 28 },
          { name: '5th', driving: 28, driven: 24 } ] } ],
        labels: { driver: 'Engine side', driven: 'Output side', teeth: '', gear: 'Gear {n}' } } },

    { type: 'more', links: ['engine'] }
  ]
};
