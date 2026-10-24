// Fixture bite: two `diagram` cards (a 4-step process with labels, focus and flows; a scrubbed before/after), then more.
window.EXPLAINER = {
  id: '_demo3',
  title: 'Everyday mechanisms',
  kind: 'bite',
  theme: 'nature',
  cards: [
    { type: 'card', title: 'A kettle moves heat with the water', text: 'Heat at the bottom makes the water there lighter, so it rises as bubbles. Steam leaves at the top.',
      takeaway: 'Heat goes up with the water.',
      visual: { type: 'diagram', view: [100, 96],
        parts: [
          { id: 'water', shape: 'rect', x: 29, y: 46, w: 42, h: 32, style: 'blue', hidden: true, label: 'Water', labelAt: [98, 62] },
          { id: 'kettle', shape: 'path', points: [[28, 26], [28, 78], [72, 78], [72, 26]], fill: false },
          { id: 'base', shape: 'rect', x: 24, y: 78, w: 52, h: 6, style: 'hatch' },
          { id: 'h1', shape: 'arrow', from: [38, 95], to: [38, 87], style: 'heat', hidden: true },
          { id: 'h2', shape: 'arrow', from: [50, 95], to: [50, 87], style: 'heat', hidden: true, label: 'Heat', labelAt: [2, 91] },
          { id: 'h3', shape: 'arrow', from: [62, 95], to: [62, 87], style: 'heat', hidden: true },
          { id: 'steam', shape: 'path', points: [[50, 24], [44, 18], [52, 12], [46, 6]], smooth: true, style: 'thin', dash: true, hidden: true, label: 'Steam', labelAt: [98, 14] }
        ],
        steps: [
          { show: ['water'], note: 'Cold water goes in' },
          { show: ['h1', 'h2', 'h3'], focus: ['h1', 'h2', 'h3', 'base'], note: 'Heat warms the bottom' },
          { focus: ['water'], note: 'Bubbles rise' },
          { show: ['steam'], focus: ['steam'], note: 'Steam escapes' }
        ],
        flows: [
          { along: [[50, 4], [50, 52]], style: 'blue', count: 3, speed: 20, during: [0] },
          { along: [[50, 26], [47, 6]], style: 'thin', count: 3, speed: 14, during: [3] },
          { along: [[38, 76], [38, 50]], style: 'blue', count: 2, speed: 13, during: [2, 3] },
          { along: [[52, 76], [52, 50]], style: 'blue', count: 3, speed: 16, during: [2, 3] },
          { along: [[64, 76], [64, 50]], style: 'blue', count: 2, speed: 12, during: [2, 3] }
        ] } },
    { type: 'card', title: 'A bigger back cog makes pedalling easier', text: 'The chain joins the pedal ring to a cog on the back wheel. A big cog turns the wheel slowly but with less effort.',
      takeaway: 'Drag to change gear.',
      visual: { type: 'diagram', view: [100, 90], scrub: true,
        parts: [
          { id: 'ring', shape: 'circle', x: 24, y: 45, r: 14, style: 'ink', label: 'Front ring', labelAt: [2, 12] },
          { id: 'ringc', shape: 'dot', x: 24, y: 45, r: 1.6 },
          { id: 'chA', shape: 'line', from: [24, 31], to: [78, 39], dash: true },
          { id: 'chA2', shape: 'line', from: [24, 59], to: [78, 51], dash: true },
          { id: 'chB', shape: 'line', from: [24, 31], to: [78, 36], dash: true, hidden: true },
          { id: 'chB2', shape: 'line', from: [24, 59], to: [78, 54], dash: true, hidden: true },
          { id: 'chC', shape: 'line', from: [24, 31], to: [78, 33], dash: true, hidden: true },
          { id: 'chC2', shape: 'line', from: [24, 59], to: [78, 57], dash: true, hidden: true },
          { id: 'cogA', shape: 'circle', x: 78, y: 45, r: 6, style: 'accent', label: 'Small cog', labelAt: [98, 82] },
          { id: 'cogB', shape: 'circle', x: 78, y: 45, r: 9, style: 'accent', hidden: true, label: 'Middle cog', labelAt: [98, 82] },
          { id: 'cogC', shape: 'circle', x: 78, y: 45, r: 12, style: 'accent', hidden: true, label: 'Big cog', labelAt: [98, 82] },
          { id: 'cdot', shape: 'dot', x: 78, y: 45, r: 1.2, style: 'accent' }
        ],
        steps: [
          { note: 'Small cog: hard, fast' },
          { hide: ['cogA', 'chA', 'chA2'], show: ['cogB', 'chB', 'chB2'], note: 'Middle cog' },
          { hide: ['cogB', 'chB', 'chB2'], show: ['cogC', 'chC', 'chC2'], note: 'Big cog: easy, slow' }
        ] } },
    { type: 'more', links: ['_demo2'] }
  ]
};
