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
    steps: [{ note: 'One note: one bright line' }, { show: ['b', 'c'], note: 'A chord: several at once' }] };

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
    steps: [{ note: 'The whole sound picture' }, { hide: ['f'], show: ['s1', 's2', 's3'], note: 'Only the peaks stay' }] };

  const pairs = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'a', shape: 'dot', x: 20, y: 50, r: 3, style: 'accent', label: 'Peak', labelAt: [6, 70] },
      { id: 'b', shape: 'dot', x: 50, y: 30, r: 2.5, style: 'spark' },
      { id: 'c', shape: 'dot', x: 64, y: 62, r: 2.5, style: 'spark' },
      { id: 'l1', shape: 'line', from: [20, 50], to: [50, 30], style: 'thin', hidden: true },
      { id: 'l2', shape: 'line', from: [20, 50], to: [64, 62], style: 'thin', hidden: true }
    ],
    steps: [{ note: 'One peak is too common' }, { show: ['l1', 'l2'], note: 'Each pair becomes a code' }] };

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
        title: 'Any song. Out of millions. In a few seconds.',
        text: 'You are in a noisy café. People talk. Cups clink. Music plays somewhere. You hold up your phone, and Shazam tells you the name of the song. How? First, Shazam turns the sound into a picture.',
        visual: listen },
      { type: 'card', title: 'Shazam turns sound into a chart',
        text: 'Time goes from left to right. High notes go near the top. Low notes go near the bottom. This height is called frequency. A loud note shows bright. A quiet note shows dim. So what does your noisy café look like on this chart?',
        visual: stack },
      { type: 'card', title: 'Your café becomes a chart too',
        text: 'When you tap Shazam, your phone records a few seconds of sound. This short recording is your clip. It has the song in it, and also the talking and the cups. Shazam turns the whole clip into one chart. The song makes bright lines. The noise makes faint dots everywhere. Shazam cannot keep all those dots.',
        visual: clip },
      { type: 'card', title: 'Shazam keeps only the loudest points',
        text: 'Shazam cannot compare every dot with millions of songs. That is too slow, even for a computer. So Shazam keeps only the loudest points on the chart. These points are called peaks. The faint noise disappears. Only the music\'s peaks stay. But one peak alone does not tell Shazam much.',
        visual: peaks },
      { type: 'bridge',
        text: 'One peak is just one note at one moment. Thousands of songs have that same note. But two peaks together are much rarer. Picture a 1,200 Hz note, then a 2,400 Hz note exactly 0.3 seconds later. Hz measures how high a note is. Very few songs have that exact pair. So Shazam uses pairs of peaks.' },
      { type: 'card', title: 'Two peaks make a code',
        text: 'Shazam joins each peak to a few peaks that come just after it. For each pair, it writes down three numbers. The first two numbers say how high each note is. The third number is the time between them. These three numbers make one code. Now Shazam must find the song that has your codes.',
        visual: pairs },
      { type: 'card', title: 'Shazam looks up each code, like a book\'s index',
        text: 'Shazam does not check millions of songs one by one. That takes days. A book\'s index shows every page that has a word. Shazam\'s list shows every song that has a code. One song comes up again and again, at the same times as your clip. That song is the answer.',
        takeaway: 'Shazam never hears the whole song, only pairs of loud notes.',
        visual: lookup },
      { type: 'more', links: ['ice-floats'], note: 'In 2002 Shazam wasn\'t an app. You dialled 2580, held your phone to the speaker, and got the song\'s name by text.' }
    ]
  };
})();
