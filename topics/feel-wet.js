// Can your skin feel wet when it is dry? 4 cards, written spine-first (2026-10-30, tasks/spine-feel-wet/):
// your skin has no sensor made just for wet; water cooler than your skin takes heat out of it and your cold sensors notice;
// your brain puts the cold signal and a close, even touch together into wet; in 1900 a dry finger in a thin rubber sheath felt wet in water.
// No "guess", "adds" or "decides", no plastic bag, no 20-times figure, no "damp" outside Go deeper (facts.md myths).
// The iOS app draws every card natively (ios/Polymath/FlatWet.swift); these web diagrams are simple stand-ins using the text's exact words.
(function () {
  // ---- Card 1: skin from the side, sensors tagged with what they react to, and an empty slot for wet. ----
  const names = ['COLD SENSOR', 'WARM SENSOR', 'TOUCH SENSOR'];
  const sensorParts = [], sensorIds = [];
  names.forEach((n, i) => {
    const y = 30 + i * 12;
    sensorParts.push({ id: 's' + i, shape: 'circle', x: 22, y, r: 3.5, style: 'accent', hidden: true },
      { id: 'n' + i, shape: 'text', x: 58, y: y + 1.5, text: n, hidden: true });
    sensorIds.push('s' + i, 'n' + i);
  });
  const noSensor = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'skin', shape: 'rect', x: 8, y: 8, w: 84, h: 84, style: 'thin', fill: false },
      { shape: 'text', x: 50, y: 16, text: 'SKIN' },
      ...sensorParts,
      { id: 'wet', shape: 'circle', x: 22, y: 66, r: 3.5, style: 'thin', fill: false, hidden: true },
      { id: 'wn', shape: 'text', x: 58, y: 67.5, text: 'NO SENSOR JUST FOR WET', hidden: true }
    ],
    steps: [
      { show: sensorIds, note: 'Tiny sensors react to cold, warmth and touch' },
      { show: ['wet', 'wn'], note: 'No sensor made just for wet' }
    ] };

  // ---- Card 2: a drop on skin; heat leaves into the water, the cold sensor lights up, a cold signal goes to the brain. ----
  const cooling = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'skin', shape: 'rect', x: 4, y: 70, w: 92, h: 22, style: 'hatch' },
      { id: 'drop', shape: 'path', points: [[24, 70], [38, 58], [62, 58], [76, 70]], closed: true, smooth: true, style: 'blue' },
      { shape: 'text', x: 50, y: 52, text: 'WATER' },
      { id: 'h1', shape: 'arrow', from: [40, 78], to: [40, 62], style: 'thin', hidden: true },
      { id: 'h2', shape: 'arrow', from: [60, 78], to: [60, 62], style: 'thin', hidden: true },
      { id: 'ho', shape: 'text', x: 84, y: 66, text: 'HEAT OUT', hidden: true },
      { id: 'cs', shape: 'circle', x: 50, y: 82, r: 3.5, style: 'accent', hidden: true },
      { id: 'csn', shape: 'text', x: 50, y: 90, text: 'COLD SENSOR', hidden: true },
      { id: 'sig', shape: 'arrow', from: [14, 80], to: [14, 24], style: 'accent', hidden: true },
      { id: 'sgn', shape: 'text', x: 26, y: 50, text: 'COLD SIGNAL', hidden: true },
      { id: 'br', shape: 'rect', x: 2, y: 8, w: 40, h: 14, style: 'spark', text: 'YOUR BRAIN', hidden: true }
    ],
    steps: [
      { note: 'Water touches your skin' },
      { show: ['h1', 'h2', 'ho'], note: 'Water cooler than your skin takes heat out of it' },
      { show: ['cs', 'csn', 'sig', 'sgn', 'br'], note: 'Your cold sensors notice and send a cold signal to your brain' }
    ] };

  // ---- Card 3: the same drop gives a close, even touch; the touch sensor lights up; both signals meet at the brain as "wet". ----
  const together = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'skin', shape: 'rect', x: 4, y: 76, w: 92, h: 16, style: 'hatch' },
      { id: 'drop', shape: 'path', points: [[20, 76], [34, 66], [66, 66], [80, 76]], closed: true, smooth: true, style: 'blue' },
      { id: 'tt', shape: 'text', x: 50, y: 86, text: 'CLOSE, EVEN TOUCH', hidden: true },
      { id: 'c', shape: 'arrow', from: [34, 62], to: [34, 36], style: 'accent' },
      { id: 'ct', shape: 'text', x: 24, y: 48, text: 'COLD SIGNAL' },
      { id: 't', shape: 'arrow', from: [66, 62], to: [66, 36], style: 'accent', hidden: true },
      { id: 'ts', shape: 'text', x: 80, y: 48, text: 'TOUCH SENSOR', hidden: true },
      { id: 'br', shape: 'rect', x: 30, y: 20, w: 40, h: 14, style: 'spark', text: 'YOUR BRAIN', hidden: true },
      { id: 'w', shape: 'text', x: 50, y: 10, text: 'WET', hidden: true }
    ],
    steps: [
      { note: 'The cold signal' },
      { show: ['tt', 't', 'ts'], note: 'A wet thing also gives your skin a close, even touch' },
      { show: ['br', 'w'], note: 'Your brain puts the cold signal and the touch together into wet' }
    ] };

  // ---- Card 4: a finger in a thin rubber sheath dips into water; it stays dry but feels wet; warmer water feels less wet. ----
  const sheath = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'cold', shape: 'rect', x: 14, y: 50, w: 72, h: 36, style: 'blue' },
      { id: 'warm', shape: 'rect', x: 14, y: 50, w: 72, h: 36, style: 'spark', hidden: true },
      { id: 'glass', shape: 'path', points: [[12, 40], [12, 88], [88, 88], [88, 40]], fill: false },
      { id: 'sh', shape: 'rect', x: 38, y: 10, w: 24, h: 64, style: 'thin', fill: false },
      { id: 'fn', shape: 'rect', x: 42, y: 14, w: 16, h: 56, style: 'accent' },
      { shape: 'text', x: 50, y: 6, text: 'DRY FINGER' },
      { id: 'shn', shape: 'text', x: 80, y: 30, text: 'THIN RUBBER SHEATH' },
      { id: 'fw', shape: 'text', x: 50, y: 94, text: 'FEELS WET', hidden: true },
      { id: 'wm', shape: 'text', x: 50, y: 94, text: 'WARMER: LESS WET', hidden: true },
      { id: 'lk', shape: 'text', x: 50, y: 94, text: 'LUKEWARM: BARELY', hidden: true }
    ],
    steps: [
      { note: 'A finger in a thin rubber sheath' },
      { show: ['fw'], note: 'The finger stays dry, but it feels wet' },
      { hide: ['cold', 'fw'], show: ['warm', 'wm'], note: 'Warmer water felt less wet' },
      { hide: ['wm'], show: ['lk'], note: 'Lukewarm water barely at all' }
    ] };

  window.EXPLAINER = {
    id: 'feel-wet',
    title: 'Can your skin feel wet when it is dry?',
    kind: 'full',
    theme: 'nature',
    cards: [
      { type: 'card', title: 'Your skin has no sensor made just for wet.',
        text: 'Your skin has tiny nerve endings, called sensors, that react to things such as cold, warmth and touch. But scientists have looked for one and found none made just for wet.',
        hook: 'So what do your sensors feel when water touches you?',
        visual: noSensor },
      { type: 'card', title: 'Water cooler than your skin takes heat out of it, and your cold sensors notice',
        text: 'When something wet touches you, water cooler than your skin takes heat out of it fast. Your cold sensors notice your skin getting colder and send a cold signal to your brain.',
        hook: 'But is a cold signal all it takes to feel wet?',
        visual: cooling },
      { type: 'card', title: 'Your brain puts a cold signal and a close, even touch together into wet',
        text: 'A wet thing also gives your skin a close, even touch, and your touch sensors feel it. Your brain puts the cold signal and the touch together into wet.',
        hook: 'So could a dry finger feel wet?',
        visual: together },
      { type: 'card', title: 'In 1900, a dry finger in a thin rubber sheath felt wet in water',
        text: 'So you can feel wet when you are dry. In 1900, a psychologist covered a finger with a thin rubber sheath, like a glove for one finger. The finger was then lowered into water, and it stayed dry but felt wet. The people who tried it at first refused to believe the finger was dry. In the same test, warmer water felt less wet, and lukewarm water barely at all.',
        takeaway: 'Wet is not a sense of its own. Your brain builds it from cold and touch.',
        visual: sheath },
      { type: 'more', links: ['sky-blue'], note: 'Some animals do have a sensor for how damp the air is, which people do not. Fruit flies keep humidity sensors in their antennae, and mosquitoes have two kinds on theirs: one that reacts to dry air and one to damp air. Up close the sensors help a mosquito tell a person is near, and the damp-air kind helps it find water to lay eggs in. They sense water vapour in the air, not the feeling of a wet surface.' }
    ]
  };
})();
