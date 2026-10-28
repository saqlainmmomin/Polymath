// Why is the sky blue, but red at sunset? 5 cards: the Sun looks yellow but the sky looks blue; sunlight is every colour, as waves; air particles bounce short blue waves far more than long red ones; bounced blue reaches you from everywhere; a low Sun sends light through ~40x more air, so the blue is gone and red is left.
// Copy: slide 1 written by the owner 2026-10-26, the rest redrafted in that voice (pending approval). The iOS app will draw these natively; these web diagrams are simple stand-ins.
(function () {
  const r1 = n => Math.round(n * 10) / 10;
  // wavy line from a to b: wavelength wl, amplitude amp, 6 points per wave
  const wave = (a, b, wl, amp, phase) => {
    const dx = b[0] - a[0], dy = b[1] - a[1], L = Math.hypot(dx, dy), ux = dx / L, uy = dy / L, pts = [];
    const n = Math.max(2, Math.round(L / wl * 6));
    for (let k = 0; k <= n; k++) {
      const s = L * k / n, o = amp * Math.sin(2 * Math.PI * s / wl + (phase || 0));
      pts.push([r1(a[0] + ux * s - uy * o), r1(a[1] + uy * s + ux * o)]);
    }
    return pts;
  };

  // Card 1: the mystery at once. A yellow sun in a blue sky, and a low sun in an orange and red one.
  const twoSkies = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'skyL', shape: 'rect', x: 3, y: 6, w: 45, h: 76, style: 'blue' },
      { id: 'skyR', shape: 'rect', x: 52, y: 6, w: 45, h: 76, style: 'heat' },
      { id: 'ground', shape: 'rect', x: 3, y: 82, w: 94, h: 9, style: 'hatch' },
      { id: 'sunL', shape: 'circle', x: 25.5, y: 34, r: 9, style: 'spark' },
      { id: 'sunR', shape: 'circle', x: 74.5, y: 69, r: 9, style: 'spark' },
      { id: 'tn', shape: 'text', x: 25.5, y: 14, text: 'Noon' },
      { id: 'ts', shape: 'text', x: 74.5, y: 14, text: 'Sunset' }
    ] };

  // Card 4: one sunbeam through air; blue bits bounce off sideways, one reaches your eye.
  const beam = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'air', shape: 'rect', x: 6, y: 30, w: 88, h: 48, style: 'blue', fill: false, label: 'Air', labelAt: [97, 22] },
      { id: 'ground', shape: 'rect', x: 6, y: 86, w: 88, h: 6, style: 'hatch' },
      { id: 'sun', shape: 'circle', x: 14, y: 13, r: 7, style: 'spark', label: 'Sun', labelAt: [42, 10] },
      { id: 'sl', shape: 'arrow', from: [21, 20], to: [72, 71], style: 'spark', label: 'Sunlight', labelAt: [88, 10] },
      { id: 'a1', shape: 'arrow', from: [38, 37], to: [43, 29], style: 'blue', hidden: true },
      { id: 'a2', shape: 'arrow', from: [38, 37], to: [26, 41], style: 'blue', hidden: true },
      { id: 'b1', shape: 'arrow', from: [50, 49], to: [65, 45], style: 'blue', hidden: true },
      { id: 'b2', shape: 'arrow', from: [50, 49], to: [45, 63], style: 'blue', hidden: true },
      { id: 'c1', shape: 'arrow', from: [62, 61], to: [76, 54], style: 'blue', hidden: true },
      { id: 'c2', shape: 'arrow', from: [62, 61], to: [53, 74], style: 'blue', hidden: true },
      { id: 'eye', shape: 'circle', x: 50, y: 80, r: 4.5, style: 'accent', label: 'Your eye', labelAt: [20, 74] }
    ],
    steps: [
      { note: 'Sunlight: a mix of colours' },
      { show: ['a1', 'a2', 'b1', 'b2', 'c1'], focus: ['a1', 'a2', 'b1', 'b2', 'c1', 'sl', 'air'], note: 'Air bounces blue every way' },
      { show: ['c2'], focus: ['c2', 'c1', 'a1', 'a2', 'b1', 'b2', 'eye'], note: 'Some reaches your eye' }
    ] };

  // Card 2: sunlight is every colour; red is a long wave, blue a short one.
  const colours = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'sun', shape: 'circle', x: 12, y: 18, r: 8, style: 'spark', label: 'Sunlight', labelAt: [12, 34] },
      { id: 'beam', shape: 'arrow', from: [22, 18], to: [54, 18], style: 'spark' },
      { id: 'cr', shape: 'arrow', from: [54, 18], to: [92, 6], style: 'heat' },
      { id: 'cg', shape: 'arrow', from: [54, 18], to: [92, 18], style: 'green' },
      { id: 'cb', shape: 'arrow', from: [54, 18], to: [92, 30], style: 'blue' },
      { id: 'tr', shape: 'text', x: 28, y: 52, text: 'Red: long wave' },
      { id: 'wr', shape: 'path', points: wave([6, 62], [94, 62], 14, 4.5), smooth: true, style: 'heat' },
      { id: 'tb', shape: 'text', x: 28, y: 76, text: 'Blue: short wave' },
      { id: 'wb', shape: 'path', points: wave([6, 86], [94, 86], 7, 3), smooth: true, style: 'blue' }
    ] };

  // Card 3: short blue wave is bounced off course by air particles, long red ripple slips through.
  const specks = [];
  [[43, 24], [50, 31], [57, 26], [45, 34], [55, 20], [47, 62], [54, 69], [58, 63], [43, 70], [51, 59]].forEach((p, i) =>
    specks.push({ id: 'k' + i, shape: 'dot', x: p[0], y: p[1], r: 1.8, ...(i === 8 ? { label: 'Gas particles', labelAt: [3, 86] } : {}) }));
  const ripples = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'col', shape: 'rect', x: 38, y: 6, w: 24, h: 84, style: 'blue', fill: false, label: 'Air', labelAt: [97, 84] },
      ...specks,
      { id: 'tb', shape: 'text', x: 18, y: 14, text: 'Blue: short' },
      { id: 'tr', shape: 'text', x: 20, y: 56, text: 'Red: long' },
      { id: 'bi', shape: 'path', points: wave([4, 27], [40, 27], 7, 3), smooth: true, style: 'blue' },
      { id: 'ri', shape: 'path', points: wave([4, 66], [40, 66], 11, 4.5), smooth: true, style: 'heat' },
      { id: 'ro', shape: 'path', points: wave([60, 66], [96, 66], 11, 4.5, 0), smooth: true, style: 'heat', hidden: true },
      { id: 'bo1', shape: 'path', points: wave([60, 27], [92, 6], 7, 3), smooth: true, style: 'blue', hidden: true },
      { id: 'bo2', shape: 'path', points: wave([60, 27], [92, 46], 7, 3), smooth: true, style: 'blue', hidden: true }
    ],
    steps: [
      { note: 'Both enter the air' },
      { show: ['ro'], focus: ['ri', 'ro', 'tr', 'col'], note: 'Long red mostly slips past' },
      { show: ['bo1', 'bo2'], focus: ['bi', 'bo1', 'bo2', 'tb', 'col'], note: 'Short blue gets bounced' }
    ] };

  // Card 5: noon = short trip through air; sunset = long trip, blue bounced away, light turns red.
  const sunset = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'air', shape: 'rect', x: 18, y: 52, w: 76, h: 28, style: 'blue', fill: false, label: 'Air', labelAt: [52, 42] },
      { id: 'ground', shape: 'rect', x: 4, y: 80, w: 90, h: 6, style: 'hatch' },
      { id: 'sunN', shape: 'circle', x: 88, y: 12, r: 6, style: 'spark', label: 'Noon', labelAt: [66, 12] },
      { id: 'nbd', shape: 'line', from: [88, 19], to: [88, 52], style: 'thin', dash: true },
      { id: 'nb', shape: 'arrow', from: [88, 52], to: [88, 71], style: 'spark' },
      { id: 'sunS', shape: 'circle', x: 9, y: 76, r: 5.5, style: 'spark', hidden: true, label: 'Sunset', labelAt: [4, 60] },
      { id: 'sb', shape: 'arrow', from: [15, 76], to: [83, 76], style: 'spark', hidden: true },
      { id: 'u1', shape: 'arrow', from: [34, 74], to: [28, 56], style: 'blue', hidden: true },
      { id: 'u2', shape: 'arrow', from: [48, 74], to: [42, 56], style: 'blue', hidden: true },
      { id: 'u3', shape: 'arrow', from: [62, 74], to: [56, 56], style: 'blue', hidden: true },
      { id: 'eye', shape: 'circle', x: 88, y: 76, r: 4, style: 'thin', label: 'You', labelAt: [78, 94] }
    ],
    steps: [
      { note: 'Noon: a short trip through air' },
      { show: ['sunS', 'sb'], focus: ['sunS', 'sb', 'nb', 'air', 'eye'], note: 'Sunset: a much longer trip' },
      { show: ['u1', 'u2', 'u3'], restyle: { sb: 'heat' }, focus: ['sb', 'u1', 'u2', 'u3', 'eye'], note: 'Blue bounced away, red gets through' }
    ] };

  window.EXPLAINER = {
    id: 'sky-blue',
    title: 'Why is the sky blue at noon and red at sunset?',
    kind: 'full',
    theme: 'nature',
    cards: [
      { type: 'card', title: "It's the same sky and the same Sun.",
        text: "Sunlight looks yellow, but it's really all colours mixed together. Air looks clear, but it isn't quite. So how does clear air turn sunlight into a blue sky, and later an orange one?",
        visual: twoSkies },
      { type: 'card', title: 'Sunlight is every colour at once',
        text: 'After rain, a rainbow shows what is hiding in sunlight: every colour, mixed together. Light travels in tiny waves, and each colour has its own length. Red waves are long and stretched out. Blue waves are short and close together. So what does the air do to these waves?',
        visual: colours },
      { type: 'card', title: 'Clear air still bounces blue light',
        text: "Air looks like nothing, but it's made of gases. The gases are tiny particles, too small to see. Sunlight hits them all the time, and each hit sends the light off in a new direction. Short blue waves bounce much more often than long red ones: about 5 times as much. So where does all that bounced blue go?",
        visual: ripples },
      { type: 'card', title: 'Bounced blue comes at you from everywhere',
        text: "Particles fill the whole sky, not only the part near the Sun. Each one bounces some blue toward your eyes, so you see blue wherever you look. The sky has no blue of its own. It's sunlight, bounced toward you by the air. So why does that blue sky turn orange at sunset?",
        visual: beam },
      { type: 'card', title: 'At sunset, light crosses far more air',
        text: 'Air is a thin layer around Earth. When the Sun is overhead, its light takes a short path down through the layer. At sunset, the Sun is near the horizon, so its light must cross the layer sideways. That is a much longer trip, through about 40 times more air. On the way, the particles bounce away most of the blue, so mostly red and orange reaches your eyes.',
        takeaway: 'Short trip: blue sky; long trip: red sunset.',
        visual: sunset },
      { type: 'more', links: ['moon-tides'], note: 'The Sun looks yellow because the air has already bounced some blue out of its light. Violet bounces even more than blue, but the Sun gives out less violet and our eyes see it poorly, so the sky looks blue, not violet.' }
    ]
  };
})();
