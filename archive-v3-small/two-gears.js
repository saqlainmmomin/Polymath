// Bite: two gears trade speed for strength. Card 1 = count the laps (12 vs 36 teeth), card 2 = the big gear's teeth are further out, card 3 = bicycle easy gear.
(function () {
  // Two real gears touching at one point (pitch circles): same push at the contact, radius to the contact 1x vs 3x.
  const lever = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'gs', shape: 'circle', x: 25, y: 50, r: 9, style: 'thin', fill: false, label: 'Small gear', labelAt: [2, 20] },
      { id: 'gb', shape: 'circle', x: 61, y: 50, r: 27, style: 'thin', fill: false, label: 'Big gear', labelAt: [98, 14] },
      { id: 'cs', shape: 'dot', x: 25, y: 50, r: 1.6 },
      { id: 'cb', shape: 'dot', x: 61, y: 50, r: 1.6 },
      { id: 'rs', shape: 'line', from: [25, 50], to: [34, 50], style: 'ink', hidden: true },
      { id: 'rb', shape: 'line', from: [34, 50], to: [61, 50], style: 'ink', hidden: true },
      { id: 'ts', shape: 'text', x: 29.5, y: 44, text: '1x', hidden: true },
      { id: 'tb', shape: 'text', x: 47.5, y: 44, text: '3x', hidden: true },
      { id: 'a1', shape: 'arrow', from: [34, 84], to: [34, 57], style: 'accent', label: 'Same push', labelAt: [2, 92] }
    ],
    steps: [
      { note: 'Teeth push where they touch' },
      { show: ['rs', 'ts'], focus: ['rs', 'ts', 'gs', 'cs', 'a1'], note: 'Small gear: short distance' },
      { show: ['rs', 'ts', 'rb', 'tb'], focus: ['rs', 'ts', 'rb', 'tb', 'gb', 'cb', 'a1'], note: 'Big gear: 3x further out' }
    ] };

  // Bicycle: front pedal ring (driver, accent) and back cog, chain as two dashed tangents.
  const bike = { type: 'diagram', view: [100, 90],
    parts: [
      { id: 'cS', shape: 'line', from: [24, 37], to: [76, 30], dash: true },
      { id: 'cS2', shape: 'line', from: [24, 53], to: [76, 60], dash: true },
      { id: 'cH', shape: 'line', from: [24, 29], to: [76, 38], dash: true, hidden: true },
      { id: 'cH2', shape: 'line', from: [24, 61], to: [76, 52], dash: true, hidden: true },
      { id: 'ringS', shape: 'circle', x: 24, y: 45, r: 8, style: 'accent', label: 'Pedal ring', labelAt: [2, 12] },
      { id: 'ringB', shape: 'circle', x: 24, y: 45, r: 16, style: 'accent', hidden: true, label: 'Pedal ring', labelAt: [2, 12] },
      { id: 'cogB', shape: 'circle', x: 76, y: 45, r: 15, style: 'thin', label: 'Back cog', labelAt: [98, 78] },
      { id: 'cogS', shape: 'circle', x: 76, y: 45, r: 7, style: 'thin', hidden: true, label: 'Back cog', labelAt: [98, 78] },
      { shape: 'dot', x: 24, y: 45, r: 1.4, style: 'accent' },
      { shape: 'dot', x: 76, y: 45, r: 1.4 }
    ],
    steps: [
      { note: 'Easy gear: small turns big' },
      { hide: ['ringS', 'cogB', 'cS', 'cS2'], show: ['ringB', 'cogS', 'cH', 'cH2'], note: 'Hard gear: big turns small' }
    ] };

  window.EXPLAINER = {
    id: 'two-gears',
    title: 'How two gears swap speed for strength',
    kind: 'bite',
    theme: 'machines',
    cards: [
      { type: 'card', title: 'Small gear: 3 turns. Big gear: 1.',
        text: 'For the big gear to go round once, all 36 of its teeth must pass. The small gear only has 12, so it must go round 3 times.',
        visual: { type: 'gears', driving: 12, driven: 36, phase: 0.6, interactive: true, count: true, labels: { driver: 'Small', driven: 'Big', teeth: '{n} teeth', laps: 'Turns' } } },
      { type: 'card', title: 'Why the big gear is stronger',
        text: 'The small gear pushes the big one where they touch. That push lands 3 times further from the big gear\'s centre, so it turns with 3 times the strength, like a door pushed at the handle.',
        visual: lever },
      { type: 'card', title: 'A bicycle in its easy gear does this',
        text: 'In easy gear, a small pedal ring turns a big back cog. You pedal lots for each wheel turn, and the hill feels easy.',
        takeaway: 'Small turns big: slower, but stronger.',
        visual: bike },
      { type: 'more', links: ['spanner', 'why-gears'] }
    ]
  };
})();
