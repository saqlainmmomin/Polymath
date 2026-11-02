// Why does your voice sound different on a recording? 4 cards + Go deeper note. Spine-first (2026-11-02): facts sheet,
// paragraph and slides in tasks/spine-voice/. Copy approved by the owner. No native iOS pictures yet; these web
// diagrams are simple stand-ins.
(function () {
  const stand = (label, note) => ({ type: 'diagram', view: [100, 96], tip: false,
    parts: [
      { id: 'head', shape: 'circle', x: 36, y: 44, r: 20, style: 'thin' },
      { id: 'friend', shape: 'circle', x: 82, y: 44, r: 10, style: 'blue', label, labelAt: [50, 82] }
    ],
    steps: [{ note }] });

  window.EXPLAINER = {
    id: "own-voice",
    title: "Why does your voice sound different on a recording?",
    kind: 'full',
    theme: "nature",
    cards: [
      { type: 'card',
        title: "You know how you sound. Then you play it back.",
        text: "Play a recording of yourself and it feels wrong: that doesn't sound like me. But that's the way your voice reaches everyone else, and always has.",
        hook: "So which is the odd one out, the recording or the voice you hear when you talk?",
        visual: stand("The voice you hear vs the recording", "Your voice as you hear it, and the recording") },
      { type: 'card',
        title: "When you talk, your voice reaches your ears two ways",
        text: "Some goes out through the air and into your ears, like any sound. The rest travels as vibrations inside your head, through bone and flesh. Your friends only get the air route.",
        hook: "So what does the inside route do to your voice?",
        visual: stand("Air route and inside route", "Air route to your ear, inside route through bone and flesh, your friend gets only the air route") },
      { type: 'card',
        title: "The inside route makes your own voice fuller",
        text: "It carries the low, deep part of a voice well. Put your fingers in your ears and talk: your voice turns boomy, because blocking the air route leaves the inside one louder.",
        hook: "So what does a recording pick up?",
        visual: stand("Low, deep part", "The inside route carries the low, deep part; fingers in ears: boomy") },
      { type: 'card',
        title: "A microphone only picks up the air route",
        text: "A microphone sits outside your head, so it only picks up the air route, the same one your friends get. So the recording isn't the odd one out. Your live voice is, because only you get the extra route through your head.",
        takeaway: "Everyone hears your voice through the air. Only you hear it through your head too.",
        visual: stand("Microphone: air route only", "Microphone and friend get the air route only, you get both routes") },
      { type: 'more', links: [], note: "Bone-conduction headphones play sound through the bones of your skull to your inner ear, which leaves your ears free to hear the room. It's the same inside route your own voice uses, now used on purpose." }
    ]
  };
})();
