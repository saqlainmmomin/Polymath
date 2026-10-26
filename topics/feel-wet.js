// How do you know something is wet? 4 cards: you have no sensor for wet; water cools your skin fast; it touches you softly and
// evenly, and the brain adds the two signals into "wet"; a dry hand in a bag still feels wet in cold water, less in warm.
// Copy approved by the owner 2026-10-26, then cold-read and fact checked 2026-10-26 (Filingeri et al. 2014, J Neurophysiol;
// Bentley 1900). Replaces ice-floats in the feed. The web diagrams are simple stand-ins until native iOS pictures exist.
(function () {
  // Card 1: a shirt that feels damp, and a zoom into the skin: four sensors, and an empty slot for wet.
  const names = ['Cold', 'Heat', 'Touch', 'Pain'];
  const sensorParts = [], sensorIds = [];
  names.forEach((n, i) => {
    const y = 52 + i * 9;
    sensorParts.push({ id: 's' + i, shape: 'circle', x: 30, y, r: 3.5, style: 'accent', hidden: true },
      { id: 'n' + i, shape: 'text', x: 58, y: y + 1.5, text: n, hidden: true });
    sensorIds.push('s' + i, 'n' + i);
  });
  const noSensor = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'shirt', shape: 'path', points: [[36, 12], [28, 16], [22, 26], [30, 30], [32, 26], [32, 40], [68, 40], [68, 26], [70, 30], [78, 26], [72, 16], [64, 12], [58, 16], [42, 16]], closed: true, style: 'blue' },
      { id: 'damp', shape: 'text', x: 50, y: 6, text: 'Feels damp, can still be dry' },
      { id: 'skin', shape: 'rect', x: 18, y: 45, w: 64, h: 49, style: 'thin', fill: false, hidden: true },
      ...sensorParts,
      { id: 'wet', shape: 'circle', x: 30, y: 88, r: 3.5, style: 'thin', fill: false, hidden: true },
      { id: 'x1', shape: 'line', from: [28, 86], to: [32, 90], style: 'thin', hidden: true },
      { id: 'x2', shape: 'line', from: [32, 86], to: [28, 90], style: 'thin', hidden: true },
      { id: 'wn', shape: 'text', x: 58, y: 89.5, text: 'Wet: none', hidden: true }
    ],
    steps: [
      { note: 'Feels damp' },
      { show: ['skin', ...sensorIds, 'wet', 'x1', 'x2', 'wn'], note: 'No sensor for wet' }
    ] };

  // Card 2: two fingertips, one in air and one in water. Heat leaves the wet one much faster.
  const cooling = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'pool', shape: 'rect', x: 54, y: 46, w: 42, h: 44, style: 'blue' },
      { id: 'f1', shape: 'rect', x: 18, y: 18, w: 14, h: 46, style: 'accent' },
      { id: 'f2', shape: 'rect', x: 68, y: 18, w: 14, h: 46, style: 'accent' },
      { id: 'ta', shape: 'text', x: 25, y: 80, text: 'In air: slow' },
      { id: 'tw', shape: 'text', x: 70, y: 6, text: 'In water:' },
      { id: 'tw2', shape: 'text', x: 70, y: 12, text: 'over 20× faster' },
      { id: 'a1', shape: 'arrow', from: [32, 56], to: [42, 56], style: 'thin', hidden: true },
      { id: 'b1', shape: 'arrow', from: [82, 52], to: [94, 52], hidden: true },
      { id: 'b2', shape: 'arrow', from: [82, 60], to: [94, 60], hidden: true },
      { id: 'b3', shape: 'arrow', from: [68, 56], to: [56, 56], hidden: true }
    ],
    steps: [
      { note: 'Same finger, air and water' },
      { show: ['a1', 'b1', 'b2', 'b3'], note: 'Heat leaves your skin' }
    ] };

  // Card 3: water rests on skin. A cooling signal and a touch signal travel up and add into "wet".
  const guess = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'skin', shape: 'rect', x: 4, y: 76, w: 92, h: 16, style: 'hatch' },
      { id: 'drop', shape: 'path', points: [[20, 76], [34, 66], [66, 66], [80, 76]], closed: true, smooth: true, style: 'blue' },
      { id: 'c', shape: 'arrow', from: [34, 62], to: [34, 34], style: 'accent', hidden: true },
      { id: 't', shape: 'arrow', from: [66, 62], to: [66, 34], style: 'accent', hidden: true },
      { id: 'ct', shape: 'text', x: 30, y: 28, text: 'Cooling', hidden: true },
      { id: 'tt', shape: 'text', x: 70, y: 28, text: 'Touch', hidden: true },
      { id: 'w', shape: 'text', x: 50, y: 14, text: 'Cooling + touch = "wet"', hidden: true }
    ],
    steps: [
      { note: 'Water on your skin' },
      { show: ['c', 't', 'ct', 'tt'], note: 'Two signals' },
      { show: ['w'], note: 'Your brain\'s guess' }
    ] };

  // Card 4: a hand in a plastic bag, dipped in a bowl. Cold water: feels wet. Warm water: feels less wet. The hand stays dry.
  const bag = { type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'cold', shape: 'rect', x: 14, y: 50, w: 72, h: 36, style: 'blue' },
      { id: 'warm', shape: 'rect', x: 14, y: 50, w: 72, h: 36, style: 'spark', hidden: true },
      { id: 'bowl', shape: 'path', points: [[12, 40], [12, 88], [88, 88], [88, 40]], fill: false },
      { id: 'bag', shape: 'rect', x: 38, y: 10, w: 24, h: 64, style: 'thin', fill: false },
      { id: 'hand', shape: 'rect', x: 42, y: 14, w: 16, h: 56, style: 'accent' },
      { id: 'dry', shape: 'text', x: 50, y: 6, text: 'Hand: dry' },
      { id: 'tc', shape: 'text', x: 50, y: 94, text: 'Cold water: feels wet' },
      { id: 'tw', shape: 'text', x: 50, y: 94, text: 'Warm water: feels less wet', hidden: true }
    ],
    steps: [
      { note: 'Cold water' },
      { hide: ['cold', 'tc'], show: ['warm', 'tw'], note: 'Warm water' }
    ] };

  window.EXPLAINER = {
    id: 'feel-wet',
    title: 'How do you know something is wet?',
    kind: 'full',
    theme: 'nature',
    cards: [
      { type: 'card',
        title: 'You have no sense for wet. Your brain works it out.',
        text: 'Take clothes off a washing line on a cold evening. They can feel damp, even when they are dry. Your skin cannot sense wet at all. It has tiny nerve endings, called sensors, for cold, heat, touch and pain. None of them senses wet.',
        hook: 'So what are you really feeling?',
        visual: noSensor },
      { type: 'card', title: 'First, you feel your skin cool down',
        text: 'Water is usually cooler than your skin. It pulls heat out of your skin over 20 times faster than air does. Your skin has tiny nerve endings, called sensors, that notice cold. They feel your skin cool down fast, so they send a signal to your brain.',
        hook: 'But cooling alone does not always say "wet". Your brain also checks how the thing touches you.',
        visual: cooling },
      { type: 'card', title: 'Then you feel how it touches your skin',
        text: 'A liquid touches you gently and evenly, all over at once. It moves and fits every bump of your skin. Touch sensors, tiny nerve endings, feel how the liquid presses and moves. Now your brain has two signals: fast cooling and a soft, even touch. Together, they usually mean a liquid. So your brain decides: "wet".',
        hook: 'But that is only a guess, and you can fool it.',
        visual: guess },
      { type: 'card', title: 'You can feel wet when nothing is wet',
        text: 'Put your hand in a thin plastic bag, and dip it in cold water. Your hand stays dry. Yet it feels wet, because your skin cools fast and feels that soft, even press. Now try warm water, close to your skin\'s own heat. It feels less wet, because your skin hardly cools.',
        takeaway: 'You can\'t actually feel wet. Your brain guesses it from cold and touch.',
        visual: bag },
      { type: 'more', links: ['sky-blue'], note: 'Some insects really do have sensors for wet. Mosquitoes and fruit flies have them on their antennae. These sensors notice how wet the air is. They help the insects find water, and help mosquitoes find you.' }
    ]
  };
})();
