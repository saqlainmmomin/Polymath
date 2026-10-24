// Usage: node build.mjs <topic>   (or ./build.sh <topic>)
// Reads core/blocks.css, core/blocks.js, topics/<topic>.js and writes
//   dist/<topic>.html          hosting-contract fragment (no doctype/html/head/body)
//   dist/<topic>.preview.html  same content wrapped in a normal document for local testing
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const root = path.dirname(fileURLToPath(import.meta.url));
const topic = process.argv[2];
if (!topic) { console.error('usage: node build.mjs <topic>'); process.exit(1); }
const read = f => fs.readFileSync(path.join(root, f), 'utf8');

const FONTS = 'https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@700;800;900&family=IBM+Plex+Mono:wght@500;600&family=Public+Sans:wght@400;500;600;700&display=swap';
// Library home list. One line per topic: id = topics/<id>.js; title/teaser shown on the home tile;
// visual (optional) = 'crank' | 'gears' small ambient canvas on the tile. Card count comes from the topic file.
const LIBRARY = [
  { id: 'engine', title: 'How a car engine works', teaser: 'Suck, squeeze, bang, blow: the four strokes, hands on.', visual: 'crank' },
  { id: 'gearbox', title: 'How a gearbox works', teaser: 'Trade speed for pull with gears you can turn.', visual: 'gears', params: { driving: 12, driven: 20, speed: 0.12 } }
];

// TMH is a stub: topic-local blocks only assign functions to TMH.blocks, nothing runs at load.
function loadTopic(name) {
  const src = read(`topics/${name}.js`);
  const sandbox = { window: {}, TMH: new Proxy({ blocks: {} }, { get: (t, k) => (k in t ? t[k] : () => {}) }) };
  vm.runInNewContext(src, sandbox, { filename: `topics/${name}.js` });
  const EX = sandbox.window.EXPLAINER;
  if (!EX || !EX.title || !Array.isArray(EX.cards)) throw new Error(`topics/${name}.js must set window.EXPLAINER with title and cards`);
  return { src, EX };
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
const HUD_COUNT = `<span class="count" id="count" aria-live="polite"></span>
    <div class="segs" id="segs" aria-hidden="true"></div>`;

let body;
if (topic === 'library') {
  // Topic files are wrapped in a function whose `window` is a throwaway object, so each topic's
  // window.EXPLAINER assignment cannot collide with another's.
  const topics = LIBRARY.map(L => ({ L, ...loadTopic(L.id) }));
  const known = new Set(LIBRARY.map(L => L.id));
  for (const f of fs.readdirSync(path.join(root, 'topics'))) {
    if (f.endsWith('.js') && !known.has(f.slice(0, -3))) console.warn(`warning: topics/${f} is not listed in LIBRARY (build.mjs)`);
  }
  const data = topics.map(({ L, EX }) => ({ ...L, cards: EX.cards.filter(c => c.type !== 'intro').length }));
  body = `${head('Tell Me How')}
<div class="app" id="topicview" hidden>
  <div class="hud">
    <a class="homebtn" id="homebtn" href="#">\u2039 All topics</a>
    ${HUD_COUNT}
  </div>
  <main class="feed" id="feed"></main>
</div>
<div class="app home" id="home" hidden>
  <div class="homeinner">
    <header class="homehd">
      <div class="kicker">Workshop manual</div>
      <h1 id="hometitle" tabindex="-1">Tell Me <em>How</em></h1>
      <p class="lead">Short, hands-on explainers for how everyday things work.</p>
    </header>
    <ul class="tiles" id="tiles" aria-label="Topics"></ul>
  </div>
</div>

<script>
${js(read('core/blocks.js')).trimEnd()}

var LIBRARY = ${js(JSON.stringify(data))};
var TOPICS = {};
${topics.map(({ L, src }) => `TOPICS[${JSON.stringify(L.id)}] = (function (window) {\n${js(src).trimEnd()}\nreturn window.EXPLAINER;\n})(Object.create(window));`).join('\n')}

${js(read('core/library.js')).trimEnd()}
</script>
`;
} else {
  const { src: topicSrc, EX } = loadTopic(topic);
  body = `${head(EX.title)}
<div class="app">
  <div class="hud">
    ${HUD_COUNT}
  </div>
  <main class="feed" id="feed"></main>
</div>

<script>
${js(read('core/blocks.js')).trimEnd()}

${js(topicSrc).trimEnd()}

TMH.mount(window.EXPLAINER);
</script>
`;
}
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
