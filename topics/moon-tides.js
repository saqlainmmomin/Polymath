// Why does one Moon give most beaches two high tides a day? 5 cards, written spine-first (2026-10-28, tasks/spine-moon-tides/):
// the Moon pulls the sea, so you'd expect one high tide; it pulls the near sea harder and the far sea less than the ground;
// the sea piles up in two bulges; Earth turns your beach through both; the Moon moves on, so high tide is about 50 minutes
// later each day. Sun, spring tides and Bay of Fundy are out (other questions). The iOS app draws every card natively
// (ios/Polymath/Pictures.swift); these web diagrams are simple stand-ins using the text's exact words.
(function () {
  // Card 1: the sea rises and falls twice. No Moon in the scene: a Moon parked overhead would suggest high tide is when it passes.
  const beach = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'sand', shape: 'path', points: [[0, 50], [100, 86], [100, 96], [0, 96]], closed: true, style: 'hatch' },
      { id: 'sea', shape: 'path', points: [[0, 50], [40, 64], [0, 64]], closed: true, style: 'blue' }
    ],
    steps: [
      { note: 'Low tide' },
      { move: { sea: [0, -6] }, note: 'High tide' },
      { move: { sea: [0, 0] }, note: 'Low tide' },
      { move: { sea: [0, -6] }, note: 'High tide' }
    ] };

  // Card 2: three pulls, longest on the near sea, shortest on the far sea.
  const pulls = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'sea', shape: 'circle', x: 40, y: 48, r: 27, style: 'blue' },
      { id: 'earth', shape: 'circle', x: 40, y: 48, r: 22, style: 'green' },
      { id: 'moon', shape: 'circle', x: 92, y: 48, r: 6, style: 'thin', label: 'Moon', labelAt: [98, 70] },
      { id: 'a', shape: 'arrow', from: [70, 48], to: [84, 48], style: 'accent', label: 'Near sea', labelAt: [98, 30] },
      { id: 'b', shape: 'arrow', from: [40, 48], to: [50, 48], style: 'accent', label: 'Ground', labelAt: [40, 86] },
      { id: 'c', shape: 'arrow', from: [14, 48], to: [19, 48], style: 'accent', label: 'Far sea', labelAt: [2, 20] }
    ],
    steps: [{ note: 'The near sea is pulled most' }, { note: 'The far sea is pulled least' }] };

  // Card 3: three runners pulled by one magnet spread apart; the same three become the sea's two bulges.
  const bulges = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'far', shape: 'dot', x: 16, y: 20, r: 3.5, style: 'accent', label: 'Far sea', labelAt: [2, 6] },
      { id: 'mid', shape: 'dot', x: 38, y: 20, r: 3.5, style: 'accent', label: 'Ground', labelAt: [50, 6] },
      { id: 'near', shape: 'dot', x: 60, y: 20, r: 3.5, style: 'accent', label: 'Near sea', labelAt: [98, 6] },
      { id: 'moon', shape: 'circle', x: 90, y: 20, r: 5, style: 'thin', label: 'Moon', labelAt: [98, 38] },
      { id: 'ring', shape: 'circle', x: 36, y: 70, r: 18, style: 'blue' },
      { id: 'bulges', shape: 'path', points: [[8, 70], [36, 54], [64, 70], [36, 86]], closed: true, smooth: true, style: 'blue', hidden: true, label: 'Two bulges', labelAt: [98, 88] },
      { id: 'earth', shape: 'circle', x: 36, y: 70, r: 14, style: 'green' }
    ],
    steps: [
      { note: 'One magnet pulls all three' },
      { move: { far: [-8, 0], near: [10, 0] }, note: 'The front one is pulled hardest' },
      { hide: ['ring'], show: ['bulges'], note: 'The sea piles up on both sides' }
    ] };

  // Card 4: Earth turns under two bulges that stay lined up with the Moon.
  const turn = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'sea', shape: 'path', points: [[12, 48], [40, 30], [68, 48], [40, 66]], closed: true, smooth: true, style: 'blue' },
      { id: 'earth', shape: 'circle', x: 40, y: 48, r: 16, style: 'green' },
      { id: 'b1', shape: 'dot', x: 66, y: 48, r: 1.5, style: 'thin', label: 'Bulge', labelAt: [98, 30] },
      { id: 'b2', shape: 'dot', x: 14, y: 48, r: 1.5, style: 'thin', label: 'Bulge', labelAt: [2, 84] },
      { id: 'beach', shape: 'dot', x: 40, y: 32, r: 2.5, style: 'accent', label: 'Your beach', labelAt: [98, 10] },
      { id: 'moon', shape: 'circle', x: 92, y: 48, r: 5, style: 'thin' }
    ],
    steps: [
      { note: 'Low tide' },
      { move: { beach: [16, 16] }, note: 'High tide' },
      { move: { beach: [0, 32] }, note: 'Low tide' },
      { move: { beach: [-16, 16] }, note: 'High tide' }
    ] };

  // Card 5: a day later the Moon has moved on, so the beach turns a little further to reach it.
  const later = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'earth', shape: 'circle', x: 36, y: 56, r: 16, style: 'green' },
      { id: 'beach', shape: 'dot', x: 52, y: 56, r: 2.5, style: 'accent', label: 'Your beach', labelAt: [98, 84] },
      { id: 'moon', shape: 'circle', x: 92, y: 56, r: 5, style: 'thin', label: 'Moon', labelAt: [98, 70] },
      { id: 'extra', shape: 'text', x: 50, y: 14, text: 'About 50 extra minutes', hidden: true }
    ],
    steps: [
      { note: 'High tide' },
      { move: { moon: [-4, -22] }, note: 'A day later the Moon has moved on' },
      { move: { moon: [-4, -22], beach: [-3, -11] }, show: ['extra'], note: 'The beach needs about 50 extra minutes' }
    ] };

  window.EXPLAINER = {
    id: 'moon-tides',
    title: 'Why does one Moon give most beaches two high tides a day?',
    kind: 'full',
    theme: 'nature',
    cards: [
      { type: 'card',
        title: 'There\'s only one Moon, and it\'s on one side of the sky at a time.',
        text: 'The Moon pulls the sea toward it, so you\'d expect one high tide a day. But most beaches get two.',
        hook: 'So how does the Moon\'s pull make a second high tide?',
        visual: beach },
      { type: 'card', title: 'The Moon pulls the near sea harder than the ground, and the far sea less',
        text: 'The Moon pulls harder on whatever is closer. So the sea facing it, the near sea, is pulled harder than the ground. The sea on the far side, the far sea, is pulled less hard than the ground.',
        hook: 'So where does all that pulling make the sea pile up?',
        visual: pulls },
      { type: 'card', title: 'The sea piles up on both sides of Earth, in two bulges',
        text: 'Picture three runners in a line. One magnet ahead pulls them all, the front one hardest and the back one least. The front runner is the near sea, the middle one the ground, the back one the far sea. The near sea is pulled ahead of the ground, and the ground is pulled ahead of the far sea. So the sea piles up on both sides of Earth, in two bulges.',
        hook: 'So what happens to your beach as Earth turns?',
        visual: bulges },
      { type: 'card', title: 'As Earth turns under the bulges, your beach gets two high tides',
        text: 'The bulges stay lined up with the Moon while Earth turns once a day beneath them. Your beach passes under one, then the other. That\'s two high tides, a bit over twelve hours apart.',
        hook: 'But why does each day\'s high tide come a little later?',
        visual: turn },
      { type: 'card', title: 'The Moon moves on, so each day\'s high tide comes about 50 minutes later',
        text: 'The Moon also moves round Earth the way Earth spins. So each day your beach needs about 50 extra minutes to catch up with it.',
        takeaway: 'One Moon stretches the sea on both sides of Earth, and Earth turns your beach through both.',
        visual: later },
      { type: 'more', links: ['sky-blue'], note: 'A tide is really a very slow wave moving through the sea, and in each ocean it circles a point where the sea hardly rises or falls at all, called an amphidromic point. That is why high tide never lines up neatly with the Moon overhead. In 1687 Isaac Newton explained tides as the pull of the Moon and Sun on the sea.' }
    ]
  };
})();
