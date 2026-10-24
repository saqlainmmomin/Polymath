// Why is the sky blue, but red at sunset? 4 cards: (1) same sun, two skies, (2) air bounces short blue ripples far more than long red ones, (3) bounced blue reaches you from everywhere, (4) at sunset light crosses far more air, the blue is bounced away and red is left.
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

  // Card 1: the mystery at once. Same sun, a blue sky at noon and a red one at sunset.
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

  // Card 3: one sunbeam through air; blue bits bounce off sideways, one reaches your eye.
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
      { show: ['a1', 'a2', 'b1', 'b2', 'c1'], focus: ['a1', 'a2', 'b1', 'b2', 'c1', 'sl', 'air'], note: 'Air scatters blue every way' },
      { show: ['c2'], focus: ['c2', 'c1', 'a1', 'a2', 'b1', 'b2', 'eye'], note: 'Some reaches your eye' }
    ] };

  // Card 2: short blue ripple is bounced off course by air specks, long red ripple slips through.
  const specks = [];
  [[43, 24], [50, 31], [57, 26], [45, 34], [55, 20], [47, 62], [54, 69], [58, 63], [43, 70], [51, 59]].forEach((p, i) =>
    specks.push({ id: 'k' + i, shape: 'dot', x: p[0], y: p[1], r: 1.8, ...(i === 8 ? { label: 'Gas specks', labelAt: [3, 86] } : {}) }));
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
      { show: ['ro'], focus: ['ri', 'ro', 'tr', 'col'], note: 'Long red slips through' },
      { show: ['bo1', 'bo2'], focus: ['bi', 'bo1', 'bo2', 'tb', 'col'], note: 'Short blue gets scattered' }
    ] };

  // Card 4: noon = short trip through air; sunset = long trip, blue bounced away, light turns red.
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
      { show: ['u1', 'u2', 'u3'], restyle: { sb: 'heat' }, focus: ['sb', 'u1', 'u2', 'u3', 'eye'], note: 'Blue flung off, red gets through' }
    ] };

  window.EXPLAINER = {
    id: 'sky-blue',
    title: 'Why is the sky blue, but red at sunset?',
    kind: 'full',
    theme: 'nature',
    cards: [
      { type: 'card', title: 'The same sun paints two different skies.',
        text: 'Sunlight is every colour mixed together. So something in the air must be sorting them.',
        visual: twoSkies },
      { type: 'card', title: 'Air scatters blue light far more than red',
        text: 'Light travels in waves: blue short and tightly packed, red long and lazy. The shorter the wave, the more tiny gas specks scatter it in new directions.',
        takeaway: 'Long waves roll past.',
        visual: ripples },
      { type: 'card', title: 'Scattered blue reaches you from everywhere',
        text: 'Scattered blue flies off in every direction, so some always reaches your eyes, wherever you look.',
        takeaway: 'That is the blue sky. So why red at sunset?',
        visual: beam },
      { type: 'card', title: 'At sunset, light crosses far more air',
        text: 'Air wraps round Earth like a skin. A low sun shines sideways through far more of it, flinging blue away and leaving red and orange to reach you.',
        takeaway: 'Same trick, longer trip.',
        visual: sunset },
      { type: 'more', links: ['ice-floats'], note: 'Violet scatters even more, but the sun gives off less of it and our eyes notice it less, so we see blue.' }
    ]
  };
})();
