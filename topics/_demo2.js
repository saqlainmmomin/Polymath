// Fixture bite: one card, then more.
window.EXPLAINER = {
  id: '_demo2',
  title: 'Why gears have teeth',
  kind: 'bite',
  theme: 'machines',
  cards: [
    { type: 'card', title: 'Teeth stop gears from slipping', text: 'Smooth wheels would slip against each other under load. Teeth lock together, so every turn is passed on exactly.',
      takeaway: 'Teeth turn friction into a grip.',
      visual: { type: 'gears', driving: 12, driven: 20, speed: 0.12, labels: { driver: 'Driver', driven: 'Driven', teeth: '{n} teeth' } } },
    { type: 'more', links: ['_demo', '_demo3'] }
  ]
};
