// Why is the sky blue at noon and red at sunset? 4 cards, written spine-first (2026-10-30, tasks/spine-sky-blue/):
// the Sun looks yellow but its light is all colours mixed; air is molecules that scatter light in all directions, blue about four times as strongly as red,
// so blue comes from all over the sky; at sunset the Sun's light slants through far more air, much of the blue is scattered off, red and orange are left.
// Slide 1 is the owner's own wording (two changes approved 2026-10-30). No "particles", "dust", "bounce", "reflect", "absorb", no "times more" (facts.md myths).
// The iOS app draws every card natively; these web diagrams are simple stand-ins using the text's exact words. Only the Sun and the sky near it go orange and red.
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

  // ---- Card 1: the Sun's light is all colours mixed, it crosses clear air, and the question: a blue sky at noon, a red and orange sunset. ----
  const question = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'sun', shape: 'circle', x: 50, y: 12, r: 8, style: 'spark' },
      { shape: 'text', x: 82, y: 13, text: 'THE SUN' },
      { id: 'ray', shape: 'arrow', from: [50, 22], to: [50, 42], style: 'accent' },
      { shape: 'text', x: 76, y: 33, text: 'ALL COLOURS MIXED' },
      { id: 'air', shape: 'rect', x: 8, y: 44, w: 84, h: 14, style: 'thin', text: 'CLEAR AIR' },
      { id: 'noon', shape: 'rect', x: 8, y: 66, w: 40, h: 22, style: 'blue', text: 'NOON ?', hidden: true },
      { id: 'sunset', shape: 'rect', x: 52, y: 66, w: 40, h: 22, style: 'heat', text: 'SUNSET ?', hidden: true }
    ],
    steps: [
      { note: 'The Sun looks yellow, but its light is all colours mixed' },
      { show: ['noon', 'sunset'], note: 'How does clear air turn it into a blue sky, and later a red and orange sunset?' }
    ] };

  // ---- Card 2: a short blue wave and a long red wave reach a molecule, which scatters light in all directions. ----
  const molecule = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'bw', shape: 'path', points: wave([4, 26], [40, 26], 7, 3), smooth: true, style: 'blue' },
      { shape: 'text', x: 24, y: 14, text: 'BLUE WAVE: SHORT' },
      { id: 'rw', shape: 'path', points: wave([4, 66], [40, 66], 14, 4.5), smooth: true, style: 'heat' },
      { shape: 'text', x: 24, y: 80, text: 'RED WAVE: LONG' },
      { id: 'mol', shape: 'circle', x: 50, y: 46, r: 5, style: 'accent' },
      { shape: 'text', x: 50, y: 56, text: 'MOLECULE OF AIR' },
      { id: 'o1', shape: 'arrow', from: [55, 41], to: [80, 20], style: 'blue', hidden: true },
      { id: 'o2', shape: 'arrow', from: [56, 46], to: [92, 46], style: 'blue', hidden: true },
      { id: 'o3', shape: 'arrow', from: [55, 51], to: [80, 74], style: 'blue', hidden: true },
      { id: 'o4', shape: 'arrow', from: [45, 41], to: [66, 8], style: 'blue', hidden: true },
      { id: 'sc', shape: 'text', x: 78, y: 90, text: 'SCATTERED IN ALL DIRECTIONS', hidden: true }
    ],
    steps: [
      { note: 'Light travels in waves, and each colour has its own length' },
      { note: 'Air is made of molecules, tiny bits of gas far too small to see' },
      { show: ['o1', 'o2', 'o3', 'o4', 'sc'], note: 'They scatter light: they send it off in all directions' }
    ] };

  // ---- Card 3: blue is scattered about four times as strongly as red, so blue reaches your eyes from all over the sky. ----
  const everywhere = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'air', shape: 'rect', x: 4, y: 26, w: 92, h: 44, style: 'blue', fill: false },
      { shape: 'text', x: 90, y: 22, text: 'AIR' },
      { id: 'sun', shape: 'circle', x: 10, y: 10, r: 5, style: 'spark' },
      { shape: 'text', x: 34, y: 8, text: 'SUNLIGHT' },
      { id: 'beam', shape: 'arrow', from: [14, 14], to: [66, 52], style: 'spark' },
      { id: 'b1', shape: 'arrow', from: [26, 28], to: [14, 42], style: 'blue', hidden: true },
      { id: 'b2', shape: 'arrow', from: [38, 36], to: [30, 52], style: 'blue', hidden: true },
      { id: 'b3', shape: 'arrow', from: [48, 42], to: [56, 30], style: 'blue', hidden: true },
      { id: 'b4', shape: 'arrow', from: [58, 48], to: [78, 38], style: 'blue', hidden: true },
      { id: 'b5', shape: 'arrow', from: [58, 48], to: [72, 62], style: 'blue', hidden: true },
      { id: 'r1', shape: 'arrow', from: [34, 32], to: [40, 24], style: 'heat', hidden: true },
      { id: 'bt', shape: 'text', x: 70, y: 30, text: 'BLUE: ABOUT FOUR TIMES', hidden: true },
      { id: 'bt2', shape: 'text', x: 70, y: 35, text: 'AS STRONGLY AS RED', hidden: true },
      { id: 'rt', shape: 'text', x: 24, y: 22, text: 'RED', hidden: true },
      { id: 'e1', shape: 'arrow', from: [18, 46], to: [44, 82], style: 'blue', dash: true, hidden: true },
      { id: 'e2', shape: 'arrow', from: [60, 34], to: [54, 82], style: 'blue', dash: true, hidden: true },
      { id: 'e3', shape: 'arrow', from: [80, 44], to: [60, 82], style: 'blue', dash: true, hidden: true },
      { id: 'eye', shape: 'circle', x: 50, y: 86, r: 4, style: 'thin' },
      { shape: 'text', x: 50, y: 94, text: 'YOUR EYES' },
      { id: 'all', shape: 'text', x: 14, y: 66, text: 'ALL OVER THE SKY', hidden: true }
    ],
    steps: [
      { note: 'Sunlight crosses the air' },
      { show: ['b1', 'b2', 'b3', 'b4', 'b5', 'r1', 'bt', 'bt2', 'rt'], note: 'Air scatters blue about four times as strongly as red' },
      { show: ['e1', 'e2', 'e3', 'all'], note: 'That scattered blue reaches your eyes from all over the sky' }
    ] };

  // ---- Card 4: noon is a short path through the air; sunset is a long slanted path. Much of the blue is scattered off. Only the Sun and the sky near it go orange and red. ----
  const sunset = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'air', shape: 'rect', x: 18, y: 52, w: 76, h: 28, style: 'blue', fill: false },
      { shape: 'text', x: 56, y: 46, text: 'FAR MORE AIR' },
      { id: 'ground', shape: 'rect', x: 4, y: 80, w: 90, h: 6, style: 'hatch' },
      { id: 'sunN', shape: 'circle', x: 88, y: 12, r: 6, style: 'spark' },
      { shape: 'text', x: 66, y: 12, text: 'SUN OVERHEAD' },
      { id: 'nbd', shape: 'line', from: [88, 19], to: [88, 52], style: 'thin', dash: true },
      { id: 'nb', shape: 'arrow', from: [88, 52], to: [88, 71], style: 'spark' },
      { id: 'sunS', shape: 'circle', x: 9, y: 76, r: 5.5, style: 'spark', hidden: true },
      { id: 'low', shape: 'text', x: 14, y: 62, text: 'LOW SUN', hidden: true },
      { id: 'sb', shape: 'arrow', from: [15, 76], to: [83, 76], style: 'spark', hidden: true },
      { id: 'u1', shape: 'arrow', from: [34, 74], to: [28, 56], style: 'blue', hidden: true },
      { id: 'u2', shape: 'arrow', from: [48, 74], to: [42, 56], style: 'blue', hidden: true },
      { id: 'u3', shape: 'arrow', from: [62, 74], to: [56, 56], style: 'blue', hidden: true },
      { id: 'ut', shape: 'text', x: 50, y: 40, text: 'BLUE SCATTERED OFF', hidden: true },
      { id: 'ro', shape: 'text', x: 70, y: 92, text: 'RED AND ORANGE', hidden: true },
      { id: 'eye', shape: 'circle', x: 88, y: 76, r: 4, style: 'thin' },
      { shape: 'text', x: 78, y: 94, text: 'YOUR EYES' }
    ],
    steps: [
      { note: 'Sun overhead: a short path through the air' },
      { show: ['sunS', 'low', 'sb'], note: 'At sunset the Sun is low, so its light slants through far more air' },
      { show: ['u1', 'u2', 'u3', 'ut'], restyle: { sb: 'heat' }, note: 'Much of the blue is scattered off in other directions' },
      { show: ['ro'], note: 'Red and orange are what is left' }
    ] };

  window.EXPLAINER = {
    id: 'sky-blue',
    title: 'Why is the sky blue at noon and red at sunset?',
    kind: 'full',
    theme: 'nature',
    cards: [
      { type: 'card', title: "It's the same sky and the same Sun.",
        text: "The Sun looks yellow, but its light is really all colours mixed together. Air looks clear, but it isn't quite.",
        hook: 'So how does clear air turn sunlight into a blue sky, and later a red and orange sunset?',
        visual: question },
      { type: 'card', title: 'Air is made of molecules that scatter light in all directions',
        text: 'Light travels in waves, and each colour has its own length. Blue waves are short and red waves are long. Air is made of molecules, tiny bits of gas far too small to see. They scatter light, which means they send it off in all directions.',
        hook: 'So does air scatter blue light the same as red light?',
        visual: molecule },
      { type: 'card', title: 'Air scatters blue about four times as strongly as red, so the blue comes from all over the sky',
        text: 'Air scatters blue about four times as strongly as red, so far more blue than red is sent off. That scattered blue reaches your eyes from all over the sky. The sky has no blue of its own. The blue was in the sunlight all along.',
        hook: 'So why is a sunset red and orange?',
        visual: everywhere },
      { type: 'card', title: "At sunset the Sun's light slants through far more air, so red and orange are what is left",
        text: 'At sunset the Sun is low, so its light slants through far more air. Right at the horizon, that is about 38 times as much air as when the Sun is straight overhead. On the way, much of the blue is scattered off in other directions and never reaches you. Red and orange are what is left. The Sun looks yellow at noon for the same reason. The air has already scattered some blue out of its light.',
        takeaway: 'The same scattering that makes the sky blue takes much of the blue out of the sunset.',
        visual: sunset },
      { type: 'more', links: ['moon-tides'], note: 'Clouds are white because their drops of water are much bigger than air molecules, and they scatter all the colours alike.' }
    ]
  };
})();
