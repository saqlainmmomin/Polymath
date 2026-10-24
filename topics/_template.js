// Copy to topics/<id>.js, fill every <...>, delete what you do not need, then add the id to LIBRARY in build.mjs.
// Rules live in RECIPE.md. ./build.sh <id> lints the file (title is a question, 1-6 content cards, about 30 words a card).
window.EXPLAINER = {
  id: '<id>',                                   // equals the file name
  title: '<A full question a friend would ask, with a tension or a stake?>',   // shown huge on card 1; at most 12 words
  kind: 'full',                                 // 'bite' = 1-2 content cards, 'full' = 3-6
  theme: 'machines',                            // machines | nature | internet | money (or a new one)
  cards: [
    // 1 OPENER. `title` is optional: a short setup line shown under the question. The picture shows the mystery at once.
    { type: 'card',
      title: '<One line of stakes or surprise>',
      text: '<One thing they have felt or seen. At most 2 short sentences.>',
      visual: { type: 'diagram', view: [100, 96], parts: [], steps: [] } },

    // 2..N BUILD. One idea per card. The headline is a statement or question that says what to watch; the text proves it.
    { type: 'card',
      title: '<Headline, about 8 words>',
      text: '<Short, concrete, in plain words.>',
      takeaway: '<Optional: one bold sentence, only on the card where the idea lands.>',
      visual: { type: 'diagram', view: [100, 96], parts: [], steps: [] } },

    // Optional, at most one: a light guess before a reveal. The headline is the question; options are real misconceptions.
    // { type: 'guess', title: '<Question>', options: ['<a>', '<b>', '<c>'], answer: 1, why: '<1-2 sentences>', visual: { ... } },

    // LAST. Links to topic ids that exist; [] lets the app suggest neighbours.
    { type: 'more', links: [] }
  ]
};
