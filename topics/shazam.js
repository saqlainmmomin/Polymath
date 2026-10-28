// How can your phone name a song from a few noisy seconds? 5 cards, written spine-first (2026-10-27, tasks/spine-shazam/):
// a few seconds of chatter with music inside; it draws the sound as a chart and keeps only dots brighter than those around them; one note is
// common, so it writes pairs (two notes and the gap) as codes; a list like a book's index gives every song with each code,
// and when; only the right song has your codes lined up with the same spacing. Brand name kept out of the title (RECIPE §2).
// The iOS app draws its own pictures (ios/Polymath/FlatShazam.swift); these web diagrams are simple stand-ins.
(function () {
  // Card 1: a phone in a café. Chatter and one thread of music reach it together.
  const listen = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'ph', shape: 'rect', x: 66, y: 24, w: 22, h: 42, style: 'accent' },
      { id: 'tc', shape: 'text', x: 24, y: 14, text: 'Chatter' },
      { id: 'tm', shape: 'text', x: 24, y: 82, text: 'Music' },
      { id: 'tf', shape: 'text', x: 77, y: 76, text: 'A few seconds' }
    ],
    flows: [
      { along: [[6, 22], [64, 36]], style: 'thin', count: 4, speed: 14 },
      { along: [[6, 46], [64, 46]], style: 'thin', count: 4, speed: 12 },
      { along: [[6, 74], [64, 56]], style: 'blue', count: 3, speed: 14 }
    ] };

  // Card 2: the chart. Each dot brighter than its neighbours stays (one in a quiet patch too); the rest fade away.
  const faint = [[18, 60], [26, 30], [34, 70], [42, 44], [50, 22], [58, 64], [66, 36], [74, 72], [82, 50], [30, 50], [62, 52], [46, 76]];
  const bright = [[22, 40], [38, 26], [54, 54], [70, 30], [86, 62, 'thin']];
  const chart = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { shape: 'arrow', from: [10, 84], to: [94, 84], style: 'thin' },
      { shape: 'arrow', from: [10, 84], to: [10, 8], style: 'thin' },
      { shape: 'text', x: 84, y: 92, text: 'Time' },
      { shape: 'text', x: 26, y: 6, text: 'High notes' },
      ...faint.map(([x, y], i) => ({ id: 'f' + i, shape: 'dot', x, y, r: 1.4, style: 'thin' })),
      ...bright.map(([x, y, s], i) => ({ id: 'b' + i, shape: 'dot', x, y, r: s ? 2.2 : 2.8, style: s || 'spark',
        ...(i === 3 ? { label: 'Brighter than around it', labelAt: [98, 14] } : {}) }))
    ],
    steps: [
      { note: 'Louder sound, brighter dot' },
      { hide: faint.map((_, i) => 'f' + i), note: 'Brighter than all around it' }
    ] };

  // Card 3: one dot joins to a few dots just after it. One pair becomes a code: note, note, gap.
  const pairs = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'l1', shape: 'line', from: [18, 50], to: [40, 24], style: 'thin', hidden: true },
      { id: 'l2', shape: 'line', from: [18, 50], to: [48, 68], style: 'thin', hidden: true },
      { id: 'l3', shape: 'line', from: [18, 50], to: [58, 40], style: 'accent', hidden: true, label: 'A pair', labelAt: [70, 14] },
      { id: 'a', shape: 'dot', x: 18, y: 50, r: 3, style: 'spark', label: 'One note', labelAt: [4, 76] },
      { shape: 'dot', x: 40, y: 24, r: 2.6, style: 'spark' },
      { shape: 'dot', x: 48, y: 68, r: 2.6, style: 'spark' },
      { shape: 'dot', x: 58, y: 40, r: 2.6, style: 'spark' },
      { id: 'code', shape: 'rect', x: 54, y: 76, w: 42, h: 12, style: 'thin', hidden: true, label: 'Code', labelAt: [30, 90] },
      { id: 'ct', shape: 'text', x: 75, y: 82, text: 'Note, note, gap', hidden: true }
    ],
    steps: [
      { note: 'One note: in nearly every song' },
      { show: ['l1', 'l2', 'l3'], note: 'Joined to dots just after it' },
      { show: ['code', 'ct'], focus: ['a', 'l3', 'code', 'ct'], note: 'Two notes and the gap' }
    ] };

  // Card 4: a code goes into the list, like the back of a book. Out come several songs, each with a moment.
  const index = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'k', shape: 'rect', x: 4, y: 40, w: 26, h: 14, style: 'accent', text: 'Code' },
      { id: 'ar', shape: 'arrow', from: [32, 47], to: [48, 47], style: 'thin', hidden: true },
      { id: 'list', shape: 'rect', x: 50, y: 12, w: 46, h: 70, style: 'thin', hidden: true, label: 'Every song with this code', labelAt: [96, 6] },
      { id: 'r1', shape: 'text', x: 73, y: 26, text: 'Song A · 0:49', hidden: true },
      { id: 'r2', shape: 'text', x: 73, y: 42, text: 'Song B · 1:43', hidden: true },
      { id: 'r3', shape: 'text', x: 73, y: 58, text: 'Song C · 2:35', hidden: true },
      { id: 'tw', shape: 'text', x: 73, y: 90, text: 'And when', hidden: true }
    ],
    steps: [
      { note: 'Look up one code' },
      { show: ['ar', 'list', 'r1', 'r2', 'r3', 'tw'], note: 'Every song, and when' }
    ] };

  // Card 5: the topic's one hands-on picture. Slide your strip of codes along; only the right song's marks line up.
  const lineUp = { type: 'diagram', view: [100, 96], scrub: true, tip: 'Slide your codes along',
    parts: [
      { id: 'w1', shape: 'rect', x: 4, y: 24, w: 92, h: 10, style: 'thin' },
      { shape: 'line', from: [14, 24], to: [14, 34], style: 'thin' },
      { shape: 'line', from: [47, 24], to: [47, 34], style: 'thin' },
      { shape: 'line', from: [83, 24], to: [83, 34], style: 'thin' },
      { id: 'tw', shape: 'text', x: 50, y: 41, text: 'Wrong song: scattered' },
      { id: 'w2', shape: 'rect', x: 4, y: 62, w: 92, h: 10, style: 'thin' },
      { shape: 'line', from: [56, 62], to: [56, 72], style: 'thin' },
      { shape: 'line', from: [64, 62], to: [64, 72], style: 'thin' },
      { shape: 'line', from: [75, 62], to: [75, 72], style: 'thin' },
      { id: 'tr', shape: 'text', x: 50, y: 82, text: 'Right song: same order', hidden: true },
      // Your strip is drawn last so it stays on top as it slides.
      { id: 'strip', shape: 'rect', x: 4, y: 4, w: 30, h: 10, style: 'accent', label: 'Your few seconds', labelAt: [96, 9] },
      { id: 's1', shape: 'line', from: [10, 4], to: [10, 14], style: 'ink' },
      { id: 's2', shape: 'line', from: [18, 4], to: [18, 14], style: 'ink' },
      { id: 's3', shape: 'line', from: [29, 4], to: [29, 14], style: 'ink' }
    ],
    steps: [
      { note: 'Three of your codes' },
      { move: { strip: [23, 0], s1: [23, 0], s2: [23, 0], s3: [23, 0] }, note: 'Still scattered' },
      { move: { strip: [46, 46], s1: [46, 46], s2: [46, 46], s3: [46, 46] }, restyle: { w2: 'green' }, show: ['tr'], note: 'They line up' }
    ] };

  window.EXPLAINER = {
    id: 'shazam',
    title: 'How can your phone name a song from a few noisy seconds?',
    kind: 'full',
    theme: 'internet',
    cards: [
      { type: 'card',
        title: 'It picks one song out of millions, with people talking over it.',
        text: 'All it gets is a few seconds of chatter with music somewhere inside.',
        hook: 'So what does it keep, and what does it throw away?',
        visual: listen },
      { type: 'card', title: 'It draws the sound and keeps only the loudest dots',
        text: 'On the chart, time runs left to right and high notes sit higher. The louder a sound, the brighter its dot. It keeps only the dots brighter than everything right around them, and throws the rest away. They\'re the hardest for chatter to cover up.',
        hook: 'But one dot is just one note, and nearly every song has that. So what\'s rarer?',
        visual: chart },
      { type: 'card', title: 'A pair of notes is much rarer than one',
        text: 'So it joins each dot to a few dots just after it. Each pair is two notes and the exact gap between them. It writes each pair down as a short code.',
        hook: 'So how does it find the songs with your codes?',
        visual: pairs },
      { type: 'card', title: 'A giant list shows every song with each code',
        text: 'The app\'s makers turned every song they have into codes ahead of time. The list works like a book\'s index, giving each song with that code and the moment it turns up.',
        hook: 'But one code points at lots of songs. So which is the right one?',
        visual: index },
      { type: 'card', title: 'In the right song, many of your codes line up',
        text: 'In wrong songs, a few codes match but turn up scattered. In the right one, they come in the same order, as far apart in time as in those few seconds.',
        takeaway: 'It never listens for the words or the tune, only for where the loudest dots sit.',
        visual: lineUp },
      { type: 'more', links: ['feel-wet'], note: 'In 2002 it wasn\'t an app. You dialled 2580, held your phone up to the music, and a text message came back with the song and the singer.' }
    ]
  };
})();
