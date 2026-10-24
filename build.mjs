// Usage: node build.mjs <topic|library>   (or ./build.sh <topic|library>)
// Reads core/blocks.css, core/blocks.js, core/library.js, topics/<topic>.js and writes
//   dist/<topic>.html          hosting-contract fragment (no doctype/html/head/body)
//   dist/<topic>.preview.html  same content wrapped in a normal document for local testing
// `library` = the shorts feed of every topic in LIBRARY; any other name = a one-topic page (one slot, no vertical feed).
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const root = path.dirname(fileURLToPath(import.meta.url));
const topic = process.argv[2];
if (!topic) { console.error('usage: node build.mjs <topic|library>'); process.exit(1); }
const read = f => fs.readFileSync(path.join(root, f), 'utf8');

const FONTS = 'https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@500&family=Newsreader:ital,opsz,wght@0,6..72,400;0,6..72,500;0,6..72,600;1,6..72,400&display=swap';
// Library: topic ids, one per topic (topics/<id>.js). Title, kind, theme and card count come from the topic file. Old small topics: archive-v3-small/.
const LIBRARY = ['car-engine', 'bike-gears', 'ice-floats', 'sky-blue', 'gps', 'card-payment'];

// TMH is a stub: topic-local blocks only assign functions to TMH.blocks, nothing runs at load.
function loadTopic(name) {
  const src = read(`topics/${name}.js`);
  const sandbox = { window: {}, TMH: new Proxy({ blocks: {} }, { get: (t, k) => (k in t ? t[k] : () => {}) }) };
  vm.runInNewContext(src, sandbox, { filename: `topics/${name}.js` });
  const EX = sandbox.window.EXPLAINER;
  if (!EX || !EX.title || !Array.isArray(EX.cards)) throw new Error(`topics/${name}.js must set window.EXPLAINER with title and cards`);
  if (EX.kind !== 'full' && EX.kind !== 'bite') console.warn(`warning: topics/${name}.js: kind should be 'full' or 'bite'`);
  if (!['machines', 'nature', 'internet', 'money'].includes(EX.theme)) console.warn(`warning: topics/${name}.js: unknown theme "${EX.theme}"`);
  lint(name, EX);
  return { name, src, EX };
}
// House rules from RECIPE.md, checked the same way for every topic. Warnings only: they never stop a build.
function lint(name, EX) {
  const warn = m => console.warn(`warning: topics/${name}.js: ${m}`);
  const words = s => (s || '').trim().split(/\s+/).filter(Boolean).length;
  const body = EX.cards.filter(c => c.type === 'card' || c.type === 'guess');
  if (!/\?$/.test(EX.title) || words(EX.title) > 12) warn(`title should be one question of at most 12 words ("${EX.title}")`);
  if (EX.cards[0].type !== 'card') warn('card 1 must be a plain card (the opener: the title is its headline)');
  if (EX.cards[EX.cards.length - 1].type !== 'more') warn('the last card must be type "more"');
  if (body.length < 1 || body.length > 6) warn(`${body.length} content cards; a topic is 1 to 6`);
  if (EX.kind === 'bite' && body.length > 2) warn('kind "bite" means 1 to 2 content cards');
  if (EX.kind === 'full' && body.length < 3) warn('kind "full" means 3 to 6 content cards');
  EX.cards.forEach((c, i) => {
    if (c.type !== 'card') return;
    const n = words(c.text) + words(c.takeaway);
    if (!c.text) warn(`card ${i + 1} has no text`);
    if (n > 32) warn(`card ${i + 1} has ${n} words of text; keep it to about 30`);
    if (i > 0 && words(c.title) > 9) warn(`card ${i + 1} headline is ${words(c.title)} words; keep it to about 8`);
    if (!c.visual) warn(`card ${i + 1} has no visual`);
  });
}
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
const js = s => s.replace(/<\/script/gi, '<\\/script');
const head = title => `<title>${esc(title)}</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link href="${FONTS}" rel="stylesheet">
<style>
${read('core/blocks.css').trimEnd()}
</style>
`;

const single = topic !== 'library';
const ids = single ? [topic] : LIBRARY;
if (!single) {
  const known = new Set(LIBRARY);
  for (const f of fs.readdirSync(path.join(root, 'topics'))) {
    if (f.endsWith('.js') && !f.startsWith('_') && !known.has(f.slice(0, -3))) console.warn(`warning: topics/${f} is not listed in LIBRARY (build.mjs)`);
  }
}
const topics = ids.map(loadTopic);
const data = topics.map(({ name, EX }) => ({ id: name, title: EX.title, kind: EX.kind, theme: EX.theme, cards: EX.cards.length }));
// Each topic file runs in a function whose `window` is a throwaway object, so window.EXPLAINER assignments cannot collide.
const body = `${head(single ? topics[0].EX.title : 'Tell Me How')}
<div class="app">
  <main class="feed" id="feed"></main>
  <div class="sr" id="announce" aria-live="polite"></div>
</div>

<script>
${js(read('core/blocks.js')).trimEnd()}

var SINGLE = ${single};
var LIBRARY = ${js(JSON.stringify(data))};
var TOPICS = {};
${topics.map(({ name, src }) => `TOPICS[${JSON.stringify(name)}] = (function (window) {\n${js(src).trimEnd()}\nreturn window.EXPLAINER;\n})(Object.create(window));`).join('\n')}

${js(read('core/library.js')).trimEnd()}
</script>
`;
const preview = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
</head>
<body>
${body}</body>
</html>
`;
fs.mkdirSync(path.join(root, 'dist'), { recursive: true });
fs.writeFileSync(path.join(root, `dist/${topic}.html`), body);
fs.writeFileSync(path.join(root, `dist/${topic}.preview.html`), preview);
console.log(`built dist/${topic}.html (${body.length} bytes) and dist/${topic}.preview.html`);
