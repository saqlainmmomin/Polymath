// Usage: node tools/export-topics.mjs
// Evaluates every topic in LIBRARY (build.mjs) the same way build.mjs does and writes ios/Polymath/Resources/topics.json,
// which the iOS app reads. Topic files stay the source of truth; the app never runs JS.
// Each visual keeps its full spec (so a native renderer can use it later) plus `tip`, the interaction cue text the web build would show.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = f => fs.readFileSync(path.join(root, f), 'utf8');

const ids = [...read('build.mjs').match(/const LIBRARY = \[(.*?)\];/s)[1].matchAll(/'([^']+)'/g)].map(m => m[1]);

// Same defaults as UI.tips in core/blocks.js; `tip: false` in a topic removes the cue, a string overrides it.
const TIPS = { crank: 'Drag the crank', strokes: 'Drag to turn the engine', gears: 'Drag the gear to turn it', cylinders: 'Tap a number to compare', scrub: 'Drag the slider', dots: 'Tap a dot to jump' };
function defaultTip(v) {
  switch (v.type) {
    case 'crank': return v.interactive === false ? null : TIPS.crank;
    case 'strokes': return v.interactive === false ? null : TIPS.strokes;
    case 'gears': return v.interactive ? TIPS.gears : null;
    case 'cylinders': return (v.options || []).length > 1 && !(v.hide || []).includes('segs') ? TIPS.cylinders : null;
    case 'diagram': return v.scrub ? TIPS.scrub : (v.steps || []).length >= 3 ? TIPS.dots : null;
    default: return null;
  }
}
const withTip = v => {
  if (!v) return v;
  const tip = v.tip === undefined ? defaultTip(v) : (v.tip || null);
  return { ...v, tip };
};

function load(id) {
  const src = read(`topics/${id}.js`);
  const sandbox = { window: {}, TMH: new Proxy({ blocks: {} }, { get: (t, k) => (k in t ? t[k] : () => {}) }) };
  vm.runInNewContext(src, sandbox, { filename: `topics/${id}.js` });
  const EX = sandbox.window.EXPLAINER;
  if (!EX || !EX.title || !Array.isArray(EX.cards)) throw new Error(`topics/${id}.js must set window.EXPLAINER`);
  return {
    id: EX.id || id, title: EX.title, kind: EX.kind, theme: EX.theme,
    cards: EX.cards.map(c => ({ ...c, visual: withTip(c.visual) }))
  };
}

const topics = ids.map(load);
const out = path.join(root, 'ios/Polymath/Resources/topics.json');
fs.mkdirSync(path.dirname(out), { recursive: true });
// JSON round trip drops anything that is not data (functions), exactly what the app can read.
fs.writeFileSync(out, JSON.stringify({ topics }, null, 1) + '\n');
console.log(`wrote ${path.relative(root, out)}: ${topics.length} topics, ${topics.reduce((n, t) => n + t.cards.length, 0)} cards`);
