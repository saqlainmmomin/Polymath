// How does Shazam know what song is playing? 6 cards + 1 bridge: the feat (millions, through noise); sound as a 3D chart (time, frequency, brightness = loudness); your clip played and drawn as that chart; keep only the peaks;
// bridge: one peak is common, a pair is specific; two peaks and their time gap make a code; one-by-one search vs an index.
// First draft (2026-10-25), not yet reviewed or fact checked. Dissection and sources: tasks/shazam-dissection.md.
// The iOS app draws every card natively (ios/Polymath/FlatShazam.swift); these web diagrams are simple stand-ins.
(function () {
  const note = (id, text) => ({ id, shape: 'text', x: 50, y: 90, text, hidden: true });

  const listen = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'ph', shape: 'rect', x: 40, y: 22, w: 20, h: 40, style: 'accent', label: 'Phone', labelAt: [98, 30] },
      { id: 'w', shape: 'arrow', from: [6, 42], to: [36, 42], style: 'blue' },
      note('n1', 'It keeps almost nothing')
    ],
    steps: [{ note: 'It hears everything' }, { show: ['n1'], note: 'It keeps almost nothing' }] };

  const stack = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'a', shape: 'rect', x: 10, y: 60, w: 70, h: 4, style: 'spark' },
      { id: 'b', shape: 'rect', x: 10, y: 40, w: 70, h: 4, style: 'spark', hidden: true },
      { id: 'c', shape: 'rect', x: 10, y: 24, w: 70, h: 4, style: 'spark', hidden: true },
      { shape: 'text', x: 92, y: 14, text: 'High' }, { shape: 'text', x: 92, y: 80, text: 'Low' }
    ],
    steps: [{ note: 'One note: one bright stripe' }, { show: ['b', 'c'], note: 'A chord: several at once' }] };

  const clip = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'w', shape: 'arrow', from: [8, 18], to: [92, 18], style: 'blue', label: 'Your recording', labelAt: [8, 10] },
      { id: 'f', shape: 'rect', x: 8, y: 30, w: 84, h: 52, style: 'blue', hidden: true }
    ],
    steps: [{ note: 'A few seconds of the room' }, { show: ['f'], note: 'The same sound, as a chart' }] };

  const peaks = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'f', shape: 'rect', x: 8, y: 10, w: 84, h: 70, style: 'blue' },
      { id: 's1', shape: 'dot', x: 22, y: 30, r: 2.5, style: 'spark', hidden: true },
      { id: 's2', shape: 'dot', x: 48, y: 58, r: 2.5, style: 'spark', hidden: true },
      { id: 's3', shape: 'dot', x: 74, y: 24, r: 2.5, style: 'spark', hidden: true }
    ],
    steps: [{ note: 'The whole sound picture' }, { hide: ['f'], show: ['s1', 's2', 's3'], note: 'Only the brightest spots stay' }] };

  const pairs = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'a', shape: 'dot', x: 20, y: 50, r: 3, style: 'accent', label: 'Anchor', labelAt: [6, 70] },
      { id: 'b', shape: 'dot', x: 50, y: 30, r: 2.5, style: 'spark' },
      { id: 'c', shape: 'dot', x: 64, y: 62, r: 2.5, style: 'spark' },
      { id: 'l1', shape: 'line', from: [20, 50], to: [50, 30], style: 'thin', hidden: true },
      { id: 'l2', shape: 'line', from: [20, 50], to: [64, 62], style: 'thin', hidden: true }
    ],
    steps: [{ note: 'One dot is too common' }, { show: ['l1', 'l2'], note: 'Each pair becomes a code' }] };

  const lookup = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'k', shape: 'rect', x: 4, y: 36, w: 24, h: 14, style: 'accent', text: 'CODE' },
      { id: 'x', shape: 'rect', x: 64, y: 20, w: 32, h: 12, style: 'thin', text: 'SONG' },
      { id: 'y', shape: 'rect', x: 64, y: 54, w: 32, h: 12, style: 'thin', text: 'SONG' },
      { id: 'ar', shape: 'arrow', from: [28, 43], to: [64, 26], style: 'accent', hidden: true }
    ],
    steps: [{ note: 'Look the code up' }, { show: ['ar'], restyle: { x: 'green' }, note: 'It points to the song' }] };

  window.EXPLAINER = {
    id: 'shazam',
    title: 'How does Shazam know what song is playing?',
    kind: 'full',
    theme: 'internet',
    cards: [
      { type: 'card',
        title: 'Any song, out of millions, in any language.',
        text: 'Hold your phone up and it names the song in seconds, even with people talking over it. How?',
        visual: listen },
      { type: 'card', title: 'First, Shazam turns sound into a 3D chart',
        text: 'Time runs along the bottom. Frequency, how high a note is, runs up the side. Brightness shows how loud each note is.',
        visual: stack },
      { type: 'card', title: 'Your clip becomes a chart like this',
        text: 'Tap Shazam and your phone records a few seconds of the room, song and chatter together. That recording becomes this chart.',
        visual: clip },
      { type: 'card', title: 'Then Shazam throws most of it away',
        text: 'Searching every point would be far too slow, even for a computer. So Shazam keeps only the peaks, the loudest points. Faint chatter vanishes.',
        visual: peaks },
      { type: 'bridge',
        text: 'One peak isn\'t much use: thousands of songs have a 1,200 Hz note. But 1,200 Hz, then 2,400 Hz exactly 0.3 seconds later? That\'s rare.' },
      { type: 'card', title: 'So Shazam pairs peaks into codes',
        text: 'Each peak is paired with a few just after it. Each pair becomes three numbers: both frequencies and the time between them. That\'s a code.',
        visual: pairs },
      { type: 'card', title: 'Then it looks the codes up',
        text: 'Instead of reading every song, Shazam flips the question: which songs contain this code? Like a book\'s index, each code jumps straight to its songs. The one that keeps turning up is yours.',
        visual: lookup },
      { type: 'more', links: ['ice-floats'], note: 'In 2002 Shazam wasn\'t an app. You dialled 2580, held your phone to the speaker, and got the song\'s name by text.' }
    ]
  };
})();
