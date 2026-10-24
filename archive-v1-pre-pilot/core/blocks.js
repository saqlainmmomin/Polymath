/* Tell Me How core: feed, HUD, progress, theme-token helpers, card chrome and all block renderers.
   Topic-agnostic: everything topic-specific comes from the data passed to TMH.mount(EXPLAINER).
   See core/BLOCKS.md. */
(function () {
  'use strict';

  /* ---------- helpers ---------- */
  /* ---------- generic UI strings (override any with EXPLAINER.ui) ---------- */
  const UI_DEFAULT = {
    modelLabel: 'MENTAL MODEL', cue: 'Swipe up',
    right: 'RIGHT', answer: 'ANSWER', notQuite: 'NOT QUITE', bonus: 'BONUS',
    play: 'Play', pause: 'Pause', playAria: 'Play animation', pauseAria: 'Pause animation',
    intro: 'Intro', score: 'YOUR SCORE', tryAgain: 'Try again', seeScore: 'See score', nextQuestion: 'Next question',
    questionOf: 'QUESTION {i} OF {n}', rightPrefix: 'RIGHT. ', notQuitePrefix: 'NOT QUITE. ',
    recallClosing: 'Pulling it from memory is what makes it stick. Try this again tomorrow and see what you still know.',
    go: 'Read this one'
  };
  let UI = UI_DEFAULT;
  const fmt = (str, vars) => String(str).replace(/\{(\w+)\}/g, (m, k) => (k in vars ? vars[k] : m));
  const headlineNodes = parts => parts.map(p => p.em ? h('em', { text: p.t }) : p.t);

  const TAU = Math.PI * 2;
  const rad = d => d * Math.PI / 180;
  const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
  const wrap360 = d => ((d % 360) + 360) % 360;
  const wrap720 = d => ((d % 720) + 720) % 720;
  const pad2 = n => String(n).padStart(2, '0');
  const MONO = "600 10px 'IBM Plex Mono', ui-monospace, Menlo, monospace";
  const reducedMQ = window.matchMedia('(prefers-reduced-motion: reduce)');

  function h(tag, props, ...kids) {
    const e = document.createElement(tag);
    for (const [k, v] of Object.entries(props || {})) {
      if (v == null || v === false) continue;
      if (k === 'class') e.className = v;
      else if (k === 'text') e.textContent = v;
      else if (k.startsWith('on')) e.addEventListener(k.slice(2), v);
      else if (v === true) e.setAttribute(k, '');
      else e.setAttribute(k, v);
    }
    kids.flat().forEach(c => { if (c != null) e.append(c.nodeType ? c : document.createTextNode(c)); });
    return e;
  }

  /* ---------- theme tokens for canvas ---------- */
  const T = {};
  const TOKENS = ['bg', 'panel', 'ink', 'ink2', 'line', 'soft', 'block', 'hatch', 'metal', 'metalhi', 'mech', 'accent', 'mix', 'mixhi', 'burn', 'burnhot', 'exh', 'good', 'bad'];
  function readTheme() {
    const cs = getComputedStyle(document.documentElement);
    TOKENS.forEach(n => { T[n] = cs.getPropertyValue('--' + n).trim(); });
  }
  const rgbCache = {};
  function rgbOf(c) {
    if (rgbCache[c]) return rgbCache[c];
    let out;
    if (c[0] === '#') {
      out = [parseInt(c.slice(1, 3), 16), parseInt(c.slice(3, 5), 16), parseInt(c.slice(5, 7), 16)];
    } else {
      out = c.match(/[\d.]+/g).slice(0, 3).map(Number);
    }
    rgbCache[c] = out;
    return out;
  }
  function mixc(a, b, t) {
    const A = rgbOf(a), B = rgbOf(b);
    return 'rgb(' + A.map((v, i) => Math.round(v + (B[i] - v) * t)).join(',') + ')';
  }
  function rgba(c, a) { const [r, g, b] = rgbOf(c); return 'rgba(' + r + ',' + g + ',' + b + ',' + a + ')'; }

  /* ---------- physics ---------- */
  // Slider-crank: piston pin height above the crank axis.
  function pistonX(th, r, l) {
    const s = Math.sin(th);
    return r * Math.cos(th) + Math.sqrt(l * l - r * r * s * s);
  }

  function lift(p, win, ramp) {
    const a = win[0], b = win[1];
    if (p < a || p > b) return 0;
    const k = Math.min((p - a) / ramp, (b - p) / ramp, 1);
    return k * k * (3 - 2 * k);
  }
  // Gas state for a cylinder at cycle position p (0..720). TDC at 0, 360, 720.
  // 0-180 intake, 180-360 compression, 360-540 power, 540-720 exhaust.
  function gasAt(p) {
    p = wrap720(p);
    let col, a, count = 1;
    if (p < 180) { const k = p / 180; col = T.mix; a = 0.25 + 0.45 * k; count = k; }
    else if (p < 360) { const k = (p - 180) / 180; col = mixc(T.mix, T.mixhi, k); a = 0.7 + 0.25 * k; }
    else if (p < 540) {
      const k = (p - 360) / 180;
      col = mixc(T.mixhi, T.burn, clamp((p - 358) / 40, 0, 1));
      col = mixc(col, mixc(T.burn, T.exh, 0.55), clamp((k - 0.35) / 0.65, 0, 1));
      a = 0.95 - 0.3 * k;
    } else { const k = (p - 540) / 180; col = T.exh; a = 0.55 - 0.25 * k; count = 1 - k; }
    let flame = 0;
    if (p >= 356 && p < 540) flame = clamp((p - 356) / 40, 0, 1) * (1 - 0.75 * clamp((p - 470) / 70, 0, 1));
    const spark = (p >= 350 && p < 372) ? 1 - Math.abs(p - 361) / 12 : 0;
    const push = (p >= 362 && p < 540) ? clamp(1 - (p - 362) / 178, 0, 1) : 0;
    return { col, a, count, flame, spark: Math.max(0, spark), push, burning: p >= 356 && p < 540 };
  }

  const PTS = Array.from({ length: 30 }, (_, i) => {
    const f = v => v - Math.floor(v);
    return [0.1 + 0.8 * f(Math.sin(i * 12.9898) * 43758.5453), 0.1 + 0.8 * f(Math.sin(i * 78.233 + 1) * 43758.5453)];
  });

  /* ---------- drawing ---------- */
  // Canvas text labels of the cylinder cross-section; any card can override them with card.labels.
  const ENGINE_LABELS = { tdc: 'TDC', bdc: 'BDC', stroke: 'STROKE', push: 'PUSH', drag: 'DRAG', intake: 'INTAKE', exhaust: 'EXHAUST', spark: 'SPARK PLUG' };
  function drawGrid(ctx, W, H) {
    ctx.fillStyle = T.panel; ctx.fillRect(0, 0, W, H);
    ctx.strokeStyle = rgba(T.soft, 0.55); ctx.lineWidth = 1; ctx.beginPath();
    for (let x = 12.5; x < W; x += 24) { ctx.moveTo(x, 0); ctx.lineTo(x, H); }
    for (let y = 12.5; y < H; y += 24) { ctx.moveTo(0, y); ctx.lineTo(W, y); }
    ctx.stroke();
  }
  function hatchRect(ctx, x, y, w, hh, gap) {
    ctx.save(); ctx.beginPath(); ctx.rect(x, y, w, hh); ctx.clip();
    ctx.fillStyle = T.block; ctx.fillRect(x, y, w, hh);
    ctx.strokeStyle = T.hatch; ctx.lineWidth = 1; ctx.beginPath();
    for (let k = -hh; k < w; k += gap) { ctx.moveTo(x + k, y + hh); ctx.lineTo(x + k + hh, y); }
    ctx.stroke(); ctx.restore();
    ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5; ctx.strokeRect(x, y, w, hh);
  }
  const pw0 = (bore, r) => bore - 0.1 * r;
  function layoutEngine(W, H, head, rod) {
    const up = head ? 8.5 : 6.4, down = 2.0;
    const r = Math.min(H / (up + down + 0.7), W / (head ? 10.6 : 9.6), 46);
    const cy = (H - (up + down) * r) / 2 + up * r;
    return { r, l: (rod || 3.2) * r, cx: W / 2, cy, bore: 4 * r, wall: 0.9 * r, pinToCrown: 0.6 * r, pistonH: 1.3 * r, headY: cy - 5.1 * r };
  }
  function arrowDown(ctx, x, y, len, w, col) {
    ctx.fillStyle = col; ctx.beginPath();
    ctx.rect(x - w / 2, y, w, Math.max(0, len - w * 1.1));
    ctx.fill();
    ctx.beginPath(); ctx.moveTo(x - w * 1.1, y + len - w * 1.3); ctx.lineTo(x + w * 1.1, y + len - w * 1.3); ctx.lineTo(x, y + len); ctx.closePath(); ctx.fill();
  }

  // Full single-cylinder cross-section. o: {theta(deg crank angle, 0 = TDC), head, gas, intake, exhaust, guides, hint, labels}
  function drawEngine(ctx, W, H, o) {
    const head = !!o.head, L = layoutEngine(W, H, head, o.rod), tx = o.text || ENGINE_LABELS;
    const { r, l, cx, cy, bore, wall, headY } = L;
    const th = rad(o.theta), xp = pistonX(th, r, l), pinY = cy - xp, crownY = pinY - L.pinToCrown;
    const x0 = cx - bore / 2, x1 = cx + bore / 2;
    const topY = head ? headY - 1.6 * r : headY - 0.9 * r, botY = cy + 1.95 * r;
    const gap = Math.max(5, r * 0.2), g = o.gas;
    drawGrid(ctx, W, H);
    ctx.lineJoin = 'round'; ctx.lineCap = 'round';

    // combustion chamber contents
    if (head && g) {
      ctx.fillStyle = rgba(g.col, g.a); ctx.fillRect(x0, headY, bore, crownY - headY);
      if (g.flame > 0.01) {
        ctx.save(); ctx.beginPath(); ctx.rect(x0, headY, bore, crownY - headY); ctx.clip();
        const R = bore * 0.95 * (0.25 + 0.75 * g.flame);
        const gr = ctx.createRadialGradient(cx, headY + 2, 0, cx, headY + 2, R);
        gr.addColorStop(0, rgba(T.burnhot, 0.95 * g.flame));
        gr.addColorStop(0.45, rgba(T.burn, 0.75 * g.flame));
        gr.addColorStop(1, rgba(T.burn, 0));
        ctx.fillStyle = gr; ctx.fillRect(x0, headY, bore, crownY - headY); ctx.restore();
      }
      const n = Math.round(PTS.length * g.count), pc = g.burning ? T.burnhot : g.col;
      ctx.fillStyle = rgba(pc, 0.95);
      const pr = Math.max(1.5, r * 0.055), vh = crownY - headY - 6;
      for (let i = 0; i < n; i++) {
        ctx.beginPath(); ctx.arc(x0 + PTS[i][0] * bore, headY + 3 + PTS[i][1] * vh, pr, 0, TAU); ctx.fill();
      }
    }

    // block, walls
    hatchRect(ctx, x0 - wall, topY, wall, botY - topY, gap);
    hatchRect(ctx, x1, topY, wall, botY - topY, gap);
    hatchRect(ctx, x0 - wall, cy + 1.7 * r, bore + 2 * wall, botY - (cy + 1.7 * r), gap);

    const vxI = cx - 1.25 * r, vxE = cx + 1.25 * r, portY = headY - 1.15 * r;
    if (head) {
      hatchRect(ctx, x0 - wall, headY - 1.6 * r, bore + 2 * wall, 1.6 * r, gap);
      // ports
      const lI = o.intake || 0, lE = o.exhaust || 0;
      [[vxI, -1, lI, T.mix], [vxE, 1, lE, T.exh]].forEach(([vx, dir, lf, gc]) => {
        ctx.save();
        ctx.beginPath(); ctx.moveTo(vx, headY - 0.4 * r); ctx.lineTo(vx, headY - 0.7 * r);
        ctx.quadraticCurveTo(vx, portY, vx + dir * 0.5 * r, portY); ctx.lineTo(dir * 9999 + cx, portY);
        ctx.lineCap = 'butt'; ctx.lineWidth = 0.75 * r + 3; ctx.strokeStyle = T.ink; ctx.stroke();
        ctx.lineWidth = 0.75 * r; ctx.strokeStyle = T.panel; ctx.stroke();
        if (lf > 0.02) { ctx.strokeStyle = rgba(gc, 0.6 * lf); ctx.stroke(); }
        ctx.restore();
        ctx.fillStyle = T.panel; ctx.fillRect(vx - 0.375 * r, headY - 0.5 * r, 0.75 * r, 0.5 * r);
        if (lf > 0.02) { ctx.fillStyle = rgba(gc, 0.6 * lf); ctx.fillRect(vx - 0.375 * r, headY - 0.5 * r, 0.75 * r, 0.5 * r + 1); }
      });
      // valves
      [[vxI, lI], [vxE, lE]].forEach(([vx, lf]) => {
        const ly = headY + lf * 0.55 * r, capY = headY - 2.4 * r + lf * 0.55 * r;
        ctx.lineCap = 'butt'; ctx.strokeStyle = T.mech; ctx.lineWidth = Math.max(2, 0.14 * r);
        ctx.beginPath(); ctx.moveTo(vx, capY); ctx.lineTo(vx, ly); ctx.stroke();
        // spring
        ctx.strokeStyle = T.ink2; ctx.lineWidth = 1.5; ctx.beginPath();
        const sTop = capY, sBot = headY - 1.6 * r, steps = 6;
        ctx.moveTo(vx, sTop);
        for (let i = 1; i <= steps; i++) ctx.lineTo(vx + (i % 2 ? 0.32 : -0.32) * r, sTop + (sBot - sTop) * i / steps);
        ctx.lineTo(vx, sBot); ctx.stroke();
        ctx.fillStyle = T.metal; ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5;
        ctx.fillRect(vx - 0.3 * r, capY - 0.1 * r, 0.6 * r, 0.14 * r); ctx.strokeRect(vx - 0.3 * r, capY - 0.1 * r, 0.6 * r, 0.14 * r);
        ctx.beginPath(); ctx.moveTo(vx - 0.4 * r, ly - 0.18 * r); ctx.lineTo(vx + 0.4 * r, ly - 0.18 * r);
        ctx.lineTo(vx + 0.52 * r, ly); ctx.lineTo(vx - 0.52 * r, ly); ctx.closePath(); ctx.fill(); ctx.stroke();
      });
      // spark plug
      ctx.fillStyle = T.metalhi; ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5;
      ctx.fillRect(cx - 0.27 * r, headY - 2.25 * r, 0.54 * r, 0.7 * r); ctx.strokeRect(cx - 0.27 * r, headY - 2.25 * r, 0.54 * r, 0.7 * r);
      ctx.fillStyle = T.metal; ctx.fillRect(cx - 0.45 * r, headY - 1.85 * r, 0.9 * r, 0.25 * r); ctx.strokeRect(cx - 0.45 * r, headY - 1.85 * r, 0.9 * r, 0.25 * r);
      ctx.strokeStyle = T.mech; ctx.lineWidth = Math.max(2, 0.1 * r); ctx.lineCap = 'butt';
      ctx.beginPath(); ctx.moveTo(cx, headY - 1.6 * r); ctx.lineTo(cx, headY + 0.32 * r); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(cx - 0.4 * r, headY); ctx.lineTo(cx - 0.4 * r, headY + 0.32 * r); ctx.lineTo(cx - 0.1 * r, headY + 0.32 * r); ctx.stroke();
      if (g && g.spark > 0.05) {
        const sg = ctx.createRadialGradient(cx, headY + 0.3 * r, 0, cx, headY + 0.3 * r, r * 1.1);
        sg.addColorStop(0, rgba(T.burnhot, 0.95 * g.spark)); sg.addColorStop(1, rgba(T.burnhot, 0));
        ctx.fillStyle = sg; ctx.fillRect(cx - 1.2 * r, headY - 0.6 * r, 2.4 * r, 2 * r);
        ctx.strokeStyle = T.ink; ctx.lineWidth = 2; ctx.lineCap = 'round'; ctx.beginPath();
        ctx.moveTo(cx - 0.1 * r, headY + 0.32 * r); ctx.lineTo(cx - 0.22 * r, headY + 0.5 * r); ctx.lineTo(cx - 0.3 * r, headY + 0.28 * r); ctx.lineTo(cx - 0.4 * r, headY + 0.4 * r); ctx.stroke();
      }
    }

    // guides
    const crownTDC = cy - (r + l) - L.pinToCrown;
    if (o.guides) {
      ctx.save(); ctx.setLineDash([5, 4]); ctx.strokeStyle = T.accent; ctx.lineWidth = 1.2; ctx.beginPath();
      [crownTDC, crownTDC + 2 * r].forEach(y => { ctx.moveTo(x0, y); ctx.lineTo(x1 + wall + 10, y); });
      ctx.stroke(); ctx.restore();
      ctx.font = MONO; ctx.fillStyle = T.accent; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
      ctx.fillText(tx.tdc, x1 + wall + 12, crownTDC); ctx.fillText(tx.bdc, x1 + wall + 12, crownTDC + 2 * r);
      // stroke dimension
      const dx = x0 - wall - 12;
      ctx.strokeStyle = T.ink2; ctx.lineWidth = 1; ctx.beginPath();
      ctx.moveTo(dx, crownTDC); ctx.lineTo(dx, crownTDC + 2 * r);
      ctx.moveTo(dx - 4, crownTDC); ctx.lineTo(dx + 4, crownTDC); ctx.moveTo(dx - 4, crownTDC + 2 * r); ctx.lineTo(dx + 4, crownTDC + 2 * r); ctx.stroke();
      ctx.save(); ctx.translate(dx - 8, crownTDC + r); ctx.rotate(-Math.PI / 2); ctx.fillStyle = T.ink2; ctx.textAlign = 'center'; ctx.fillText(tx.stroke, 0, 0); ctx.restore();
    }

    // crank web + counterweight
    const px = cx + r * Math.sin(th), py = cy - r * Math.cos(th);
    const cwx = cx - 0.95 * r * Math.sin(th), cwy = cy + 0.95 * r * Math.cos(th);
    ctx.setLineDash([]);
    ctx.strokeStyle = T.line; ctx.lineWidth = 1; ctx.beginPath(); ctx.arc(cx, cy, r, 0, TAU); ctx.stroke();
    ctx.fillStyle = T.mech; ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.arc(cwx, cwy, 0.7 * r, 0, TAU); ctx.fill(); ctx.stroke();
    ctx.lineCap = 'round'; ctx.strokeStyle = T.ink; ctx.lineWidth = 0.56 * r + 3; ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(px, py); ctx.stroke();
    ctx.strokeStyle = T.mech; ctx.lineWidth = 0.56 * r; ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(px, py); ctx.stroke();

    // connecting rod
    ctx.strokeStyle = T.line; ctx.lineWidth = 0.3 * r + 3; ctx.beginPath(); ctx.moveTo(cx, pinY); ctx.lineTo(px, py); ctx.stroke();
    ctx.strokeStyle = T.mech; ctx.lineWidth = 0.3 * r; ctx.beginPath(); ctx.moveTo(cx, pinY); ctx.lineTo(px, py); ctx.stroke();
    ctx.fillStyle = T.mech; ctx.strokeStyle = T.line; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.arc(px, py, 0.42 * r, 0, TAU); ctx.fill(); ctx.stroke();
    ctx.fillStyle = T.panel; ctx.beginPath(); ctx.arc(px, py, 0.14 * r, 0, TAU); ctx.fill();
    ctx.fillStyle = T.panel; ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.arc(cx, cy, 0.34 * r, 0, TAU); ctx.fill(); ctx.stroke();

    // piston
    const pw = bore - 0.1 * r;
    ctx.fillStyle = T.metal; ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5;
    ctx.fillRect(cx - pw / 2, crownY, pw, L.pistonH); ctx.strokeRect(cx - pw / 2, crownY, pw, L.pistonH);
    ctx.fillStyle = T.metalhi; ctx.fillRect(cx - pw / 2 + 1, crownY + 1, pw - 2, 0.16 * r);
    ctx.strokeStyle = T.ink; ctx.lineWidth = 1.2; ctx.beginPath();
    [0.3, 0.5].forEach(k => { ctx.moveTo(cx - pw / 2, crownY + k * r); ctx.lineTo(cx + pw / 2, crownY + k * r); });
    ctx.stroke();
    ctx.fillStyle = T.panel; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.arc(cx, pinY, 0.2 * r, 0, TAU); ctx.fill(); ctx.stroke();

    // push arrow
    if (g && g.push > 0.02) {
      const ax = x0 - wall - 0.55 * r;
      arrowDown(ctx, ax, crownY - 0.2 * r, (0.5 + 1.6 * g.push) * r, 0.22 * r, T.burn);
      ctx.font = MONO; ctx.fillStyle = T.accent; ctx.textAlign = 'right'; ctx.textBaseline = 'middle';
      ctx.fillText(tx.push, ax - 0.4 * r, crownY + 0.3 * r);
    }

    // hint ring
    if (o.hint) {
      const pulse = 0.5 + 0.5 * Math.sin(performance.now() / 350);
      ctx.save(); ctx.setLineDash([4, 4]); ctx.strokeStyle = T.accent; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc(px, py, 0.75 * r + pulse * 4, 0, TAU); ctx.stroke(); ctx.restore();
      ctx.font = MONO; ctx.fillStyle = T.accent; ctx.textAlign = 'center'; ctx.textBaseline = 'top';
      ctx.fillText(tx.drag, px, py + 0.75 * r + 8);
    }
    if (o.arc) {
      ctx.strokeStyle = T.accent; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(cx, cy, 0.62 * r, -Math.PI / 2, -Math.PI / 2 + th); ctx.stroke();
    }

    // optional plain-word part labels (o.parts = {piston, rod, crank, cylinder}), each with a leader line to the part
    if (o.parts) {
      const pt = o.parts, lead = (txt, x, y, ax, ay, right) => {
        if (!txt) return;
        ctx.font = MONO; ctx.textBaseline = 'middle'; ctx.textAlign = right ? 'right' : 'left';
        const tw = ctx.measureText(txt).width, sx = right ? x - tw - 5 : x + tw + 5;
        ctx.lineCap = 'round';
        [[T.panel, 4], [T.accent, 1.4]].forEach(([col, lw]) => { ctx.strokeStyle = col; ctx.lineWidth = lw; ctx.beginPath(); ctx.moveTo(sx, y); ctx.lineTo(ax, ay); ctx.stroke(); });
        ctx.fillStyle = T.accent; ctx.beginPath(); ctx.arc(ax, ay, 3, 0, TAU); ctx.fill();
        ctx.fillText(txt, x, y);
      };
      lead(pt.cylinder, W - 8, headY + 0.2 * r, x1 + wall * 0.5, headY + 0.2 * r, true);
      lead(pt.piston, 8, cy - 3.6 * r, cx - pw0(bore, r) / 2, crownY + L.pistonH * 0.5, false);
      lead(pt.rod, W - 8, cy - 1.7 * r, (cx + px) / 2, (pinY + py) / 2, true);
      lead(pt.crank, W - 8, cy + 1.05 * r, cx + 0.34 * r, cy, true);
    }

    // labels
    if (head && o.labels) {
      ctx.font = MONO; ctx.fillStyle = T.ink2; ctx.textBaseline = 'bottom';
      ctx.textAlign = 'left'; ctx.fillText(tx.intake, 8, portY - 0.55 * r);
      ctx.textAlign = 'right'; ctx.fillText(tx.exhaust, W - 8, portY - 0.55 * r);
      ctx.textAlign = 'center'; ctx.fillText(tx.spark, cx, headY - 2.4 * r - 3);
    }
    return { px, py, cx, cy, r, bore, xp, L };
  }

  /* ---------- canvas component and sim loop ---------- */
  // Lifecycle bookkeeping: the topic's sims/observers vs the library home tiles' ("ambient") ones.
  // makeCanvas/addSim register into whichever sink is current, so both can be torn down exactly.
  const sims = [], ambientSims = [], topicRO = [], ambientRO = [];
  let simSink = sims, roSink = topicRO;
  function makeCanvas(host, onResize) {
    const cv = h('canvas');
    host.append(cv);
    const o = { cv, ctx: cv.getContext('2d'), w: 0, h: 0, dpr: 1 };
    const fit = () => {
      const w = host.clientWidth, hh = host.clientHeight; // padding box: the canvas fills it, borders excluded
      if (w < 2 || hh < 2) return;
      const dpr = Math.min(window.devicePixelRatio || 1, 3);
      if (w === o.w && hh === o.h && dpr === o.dpr) return;
      o.w = w; o.h = hh; o.dpr = dpr;
      cv.width = Math.round(w * dpr); cv.height = Math.round(hh * dpr);
      o.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      if (onResize) onResize();
    };
    const ro = new ResizeObserver(fit); ro.observe(host); roSink.push(ro);
    fit();
    return o;
  }
  function addSim(card, sim) {
    sim.visible = false; sim.playing = false;
    simSink.push(sim);
    (card.__sims = card.__sims || []).push(sim);
    return sim;
  }
  function playButton(sim) {
    const b = h('button', { class: 'btn sm', type: 'button' });
    sim.syncUI = () => { b.textContent = sim.playing ? UI.pause : UI.play; b.setAttribute('aria-label', sim.playing ? UI.pauseAria : UI.playAria); };
    b.addEventListener('click', () => { sim.playing = !sim.playing; sim.touched = true; sim.syncUI(); });
    sim.syncUI();
    return b;
  }
  let last = performance.now(), raf = 0;
  function loop(t) {
    const dt = Math.min(0.05, (t - last) / 1000); last = t;
    for (const list of [sims, ambientSims]) {
      for (const s of list) {
        if (!s.visible) continue;
        const was = s.playing;
        if (was) s.update(dt);
        if (was || s.playing || s.alwaysDraw) s.draw();
      }
    }
    raf = requestAnimationFrame(loop);
  }
  function redrawAll() { sims.forEach(s => s.draw && s.draw()); ambientSims.forEach(s => s.draw && s.draw()); }

  // Shared services (the one rAF loop, theme listeners) are reference counted: the mounted topic and
  // the ambient tiles each hold one reference, and the last release removes everything.
  let holds = 0, mqDark = null, mqHandler = null, themeMO = null;
  function retain() {
    if (holds++) return;
    readTheme();
    mqDark = window.matchMedia('(prefers-color-scheme: dark)');
    mqHandler = () => { readTheme(); redrawAll(); };
    mqDark.addEventListener('change', mqHandler);
    themeMO = new MutationObserver(mqHandler);
    themeMO.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
    last = performance.now();
    raf = requestAnimationFrame(loop);
  }
  function release() {
    if (!holds || --holds) return;
    cancelAnimationFrame(raf); raf = 0;
    mqDark.removeEventListener('change', mqHandler); mqDark = mqHandler = null;
    themeMO.disconnect(); themeMO = null;
  }

  /* ---------- card chrome ---------- */
  // parts: head (top cluster), mid (flexible middle, direct children of the card), foot (bottom cluster)
  function baseCard(c, parts) {
    const kids = [];
    if (parts.head) kids.push(h('div', { class: 'hd' }, parts.head));
    if (parts.mid) kids.push(...parts.mid);
    if (parts.foot) kids.push(h('div', { class: 'ft' }, parts.foot));
    const inner = h('div', { class: 'inner' }, kids);
    const el = h('section', { class: 'card', 'aria-label': c.title || c.q || c.kicker }, inner);
    return { el, inner };
  }
  function modelBlock(text) {
    return h('div', { class: 'model' }, h('small', { text: UI.modelLabel }), h('b', { text }));
  }
  function stageBox(fig) {
    const host = h('div', { class: 'stage' });
    if (fig) host.append(h('div', { class: 'fig', text: fig }));
    return host;
  }
  function head2(c, title) {
    return [h('div', { class: 'head' }, h('h2', { text: title }), h('div', { class: 'kicker', text: c.kicker }))];
  }

  /* ---------- renderers ---------- */
  const R = {};
  const uid = p => p + '-' + Math.random().toString(36).slice(2, 7);
  const spacer = () => h('div', { style: 'flex:1 1 0' });
  const cueEl = c => h('div', { class: 'cue', text: c.cue || UI.cue });
  const kickerEl = c => h('div', { class: 'kicker', text: c.kicker });

  // intro: cover. visual 'crank' = quiet spinning crank stage; 'none' = no visual.
  R.intro = function (c) {
    const P = Object.assign({ speed: 40, start: 40 }, c.params);
    const vis = c.visual === 'crank', gv = c.visual === 'gears';
    const stage = vis || gv ? stageBox() : null;
    if (stage) stage.classList.add('quiet');
    const start = h('button', { class: 'btn solid start', type: 'button', text: c.start, onclick: () => {
      feed.scrollBy({ top: feed.clientHeight, behavior: reducedMQ.matches ? 'auto' : 'smooth' });
    } });
    const { el } = baseCard(c, {
      head: [kickerEl(c), h('h1', {}, headlineNodes(c.headline))],
      mid: [stage || spacer()],
      foot: [
        h('p', { class: 'lead', text: fmt(c.meta, { n: countedTotal() }) }),
        c.hows && c.hows.length ? h('ul', { class: 'hows' }, c.hows.map(x => h('li', {}, h('b', { text: x.k }), h('span', { text: x.t })))) : null,
        start
      ]
    });
    if (gv) ambientGears(el, stage, c.params);
    if (vis) ambientCrank(el, stage, P);
    return el;
  };
  // Quiet spinning crank (intro visual 'crank').
  function ambientCrank(el, stage, P) {
    let phi = P.start;
    let sim; // declared first: a sized host fits (and calls back) inside makeCanvas, before addSim returns
    const cv = makeCanvas(stage, () => sim && sim.draw());
    sim = addSim(el, {
      update(dt) { phi = wrap360(phi + P.speed * dt); },
      draw() { if (cv.w) drawEngine(cv.ctx, cv.w, cv.h, { theta: phi, head: false, rod: P.rodRatio }); },
      onShow() { if (!reducedMQ.matches) sim.playing = true; }
    });
  }

  // hook: bold opening claim. visual 'engine-cycle' = running four-stroke cylinder; 'none' = no visual.
  R.hook = function (c) {
    const P = Object.assign({ intake: [0, 190], exhaust: [530, 720], ramp: 25, speed: 90, start: 420 }, c.params);
    const vis = c.visual === 'engine-cycle', gv = c.visual === 'gears';
    const stage = vis || gv ? stageBox(c.fig) : null;
    const { el } = baseCard(c, {
      head: [kickerEl(c), h('h1', {}, headlineNodes(c.headline))],
      mid: [stage || spacer()],
      foot: [
        h('p', { class: 'lead', style: 'color:var(--ink);font-weight:700;font-size:18px', text: c.question }),
        c.math && c.math.length ? h('details', {}, h('summary', { text: c.mathLabel }), ...c.math.map(m => h('p', { text: m }))) : null,
        cueEl(c)
      ]
    });
    if (gv) ambientGears(el, stage, c.params);
    if (vis) {
      let phi = P.start;
      const text = Object.assign({}, ENGINE_LABELS, c.labels);
      const cv = makeCanvas(stage, () => sim.draw());
      const sim = addSim(el, {
        update(dt) { phi = wrap720(phi + P.speed * dt); },
        draw() {
          if (!cv.w) return;
          drawEngine(cv.ctx, cv.w, cv.h, {
            theta: wrap360(phi), head: true, gas: gasAt(phi), labels: false, text, rod: P.rodRatio,
            intake: lift(phi, P.intake, P.ramp), exhaust: lift(phi, P.exhaust, P.ramp)
          });
        },
        onShow() { if (!reducedMQ.matches) { sim.playing = true; } }
      });
    }
    return el;
  };

  function optionGroup(opts, pick) {
    const wrapEl = h('div', { class: 'opts', role: 'group', style: '--n:' + opts.length });
    const btns = opts.map((o, k) => {
      const b = h('button', { class: 'opt', type: 'button' },
        h('span', { class: 'opt-key', text: 'ABCD'[k] }),
        h('span', { class: 'opt-body' }, h('span', { class: 'opt-text', text: o.t }), h('span', { class: 'opt-why', text: o.why || '' })),
        h('span', { class: 'opt-tag' }));
      b.addEventListener('click', () => pick(k));
      wrapEl.append(b);
      return b;
    });
    return { wrapEl, btns };
  }
  function lockOptions(c, btns, k) {
    const okIdx = c.options.findIndex(o => o.ok);
    const shown = new Set([k, okIdx]).size;
    btns[0].parentNode.classList.add('locked');
    btns[0].parentNode.style.setProperty('--n', shown);
    btns.forEach((b, j) => {
      if (j !== k && j !== okIdx) { b.hidden = true; return; }
      b.classList.add('answered', j === okIdx ? 'ok' : 'bad');
      b.setAttribute('aria-disabled', 'true');
      b.querySelector('.opt-tag').textContent = j === okIdx ? (j === k ? UI.right : UI.answer) : UI.notQuite;
    });
    return okIdx;
  }

  // predict: multiple-choice guess before the answer; reveals per-option "why" and the mental model.
  R.predict = function (c) {
    const lead = h('p', { class: 'lead', text: c.lead });
    const fb = h('div', { class: 'explain', hidden: true, 'aria-live': 'polite' }, c.model ? modelBlock(c.model) : null, cueEl(c));
    let done = false;
    const g = optionGroup(c.options, k => {
      if (done) return; done = true;
      lockOptions(c, g.btns, k);
      lead.hidden = true; fb.hidden = false; qh.classList.add('sm');
    });
    const qh = h('h2', { class: 'q', text: c.q });
    return baseCard(c, { head: [kickerEl(c), qh, lead], mid: [g.wrapEl], foot: [fb] }).el;
  };

  // reveal: predict-style guess, then an explanation, an optional slider visual (viz), a bonus and the model.
  // viz.kind 'compression' = gas column squeezed by a piston plus a pressure gauge.
  // Without c.options (no guess) it is a plain explainer card: c.q is the title, c.lead is the first line,
  // the explanation, slider visual and extras show at once, and the squeeze plays when the card comes into view.
  R.reveal = function (c) {
    const noQ = !c.options || !c.options.length;
    const V = c.viz && Object.assign({ min: 1, max: 10, start: 1, step: 0.1, decimals: 1, durationMs: 1400, format: '{v}' }, c.viz);
    const lead = h('p', { class: noQ ? 'lead sm' : 'lead', text: c.lead });
    let mini = null, slider = null, out = null, ctrl = null, sim = null, cv = null;
    if (V) {
      mini = h('div', { class: 'mini' });
      out = h('output', { style: 'font-family:var(--mono);font-size:12px;font-weight:600;min-width:64px;text-align:right' });
      slider = h('input', { type: 'range', min: String(V.min), max: String(V.max), step: String(V.step), value: String(V.start), id: uid('sq') });
      ctrl = h('div', { class: 'controls' }, h('label', { for: slider.id, text: V.label }), slider, out);
    }
    const fb = h('div', { class: 'explain grow', hidden: !noQ, 'aria-live': 'polite' },
      c.explain ? h('p', { text: c.explain }) : null, mini, ctrl,
      c.bonus ? h('div', { class: 'bonus' }, h('b', { text: UI.bonus }), c.bonus) : null,
      c.model ? modelBlock(c.model) : null);
    let done = false, tween = null;
    const startTween = () => {
      if (c.fig) mini.append(h('div', { class: 'fig', text: c.fig }));
      setTimeout(() => {
        if (reducedMQ.matches) { slider.value = String(V.max); sim.draw(); return; }
        tween = performance.now(); sim.playing = true;
      }, 120);
    };
    const g = noQ ? null : optionGroup(c.options, k => {
      if (done) return; done = true;
      lockOptions(c, g.btns, k);
      lead.hidden = true; fb.hidden = false; qh.classList.add('sm');
      if (V) startTween();
    });
    const qh = h('h2', { class: 'q', text: c.q });
    const { el } = baseCard(c, { head: [kickerEl(c), qh, lead], mid: [g ? g.wrapEl : null, fb].filter(Boolean) });
    if (!V) return el;
    cv = makeCanvas(mini, () => sim.draw());
    const val = () => parseFloat(slider.value);
    const GG = V.gauge;
    sim = addSim(el, {
      alwaysDraw: false,
      onShow() { if (noQ && !done) { done = true; startTween(); } },
      update() {
        const k = clamp((performance.now() - tween) / V.durationMs, 0, 1);
        slider.value = String(V.min + (V.max - V.min) * (k * k * (3 - 2 * k)));
        if (k >= 1) sim.playing = false;
      },
      draw() {
        if (!cv.w) return;
        const ctx = cv.ctx, W = cv.w, H = cv.h, CR = val(), nrm = (CR - V.min) / (V.max - V.min);
        out.textContent = fmt(V.format, { v: CR.toFixed(V.decimals).replace(/\.0+$/, '') });
        drawGrid(ctx, W, H);
        const bx = W * 0.1, bw = W * 0.42, by = 12, bh = H - 24;
        const gh = bh * 0.9 * V.min / CR, gy = by + bh - gh;
        ctx.fillStyle = rgba(mixc(T.mix, T.mixhi, nrm), 0.55 + 0.35 * nrm);
        ctx.fillRect(bx, gy, bw, gh);
        ctx.fillStyle = rgba(mixc(T.mix, T.mixhi, nrm), 0.95);
        for (let i = 0; i < 40; i++) {
          const f = v => v - Math.floor(v);
          ctx.beginPath(); ctx.arc(bx + 4 + f(Math.sin(i * 9.1) * 4375.5) * (bw - 8), gy + 3 + f(Math.sin(i * 4.7 + 2) * 9137.1) * Math.max(1, gh - 6), 1.8, 0, TAU); ctx.fill();
        }
        ctx.fillStyle = T.metal; ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5;
        ctx.fillRect(bx, gy - 12, bw, 12); ctx.strokeRect(bx, gy - 12, bw, 12);
        ctx.beginPath(); ctx.moveTo(bx + bw / 2, by - 8); ctx.lineTo(bx + bw / 2, gy - 12); ctx.lineWidth = 4; ctx.strokeStyle = T.mech; ctx.stroke();
        ctx.lineWidth = 2; ctx.strokeStyle = T.ink;
        ctx.beginPath(); ctx.moveTo(bx, by); ctx.lineTo(bx, by + bh); ctx.lineTo(bx + bw, by + bh); ctx.lineTo(bx + bw, by); ctx.stroke();
        if (!GG) return;
        // gauge
        const gx = W * 0.6, gw = 26, press = Math.pow(CR, GG.exponent) * GG.scale;
        const gtop = by + 30, gbot = by + bh, gH = gbot - gtop;
        ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5; ctx.strokeRect(gx, gtop, gw, gH);
        ctx.fillStyle = T.burn; const fh = gH * press / GG.full; ctx.fillRect(gx + 1, gbot - fh, gw - 2, fh);
        ctx.font = MONO; ctx.fillStyle = T.ink; ctx.textAlign = 'left'; ctx.textBaseline = 'bottom';
        ctx.fillText((GG.prefix || '') + Math.round(press) + ' ' + GG.unit, gx + gw + 8, Math.min(gbot - 2, Math.max(gtop + 12, gbot - fh + 5)));
        ctx.fillStyle = T.ink2; ctx.textBaseline = 'top'; ctx.fillText(GG.title[0], gx, by - 2);
        if (GG.title[1]) ctx.fillText(GG.title[1], gx, by + 9);
      }
    });
    slider.addEventListener('input', () => { sim.playing = false; sim.draw(); });
    return el;
  };

  // sim-crank: draggable slider-crank (piston, rod, crank) with TDC/BDC guides and a live readout.
  const CRANK_LABELS = Object.assign({}, ENGINE_LABELS, {
    sliderLabel: 'Crank angle in degrees', crank: 'CRANK', piston: 'PISTON', travel: 'TRAVEL',
    top: 'TOP (TDC)', bottom: 'BOTTOM (BDC)', down: 'MOVING DOWN', up: 'MOVING UP', travelUnit: '% DOWN',
    partPiston: 'PISTON', partRod: 'ROD', partCrank: 'CRANKSHAFT', partCylinder: 'CYLINDER'
  });
  R['sim-crank'] = function (c) {
    const P = Object.assign({ rodRatio: 3.2, speed: 50, start: 40 }, c.params);
    const LB = Object.assign({}, CRANK_LABELS, c.labels);
    const HIDE = new Set(P.hide || []);   // optional: 'fig' 'readout' 'stat0' 'stat1' 'stat2' 'guides' (TDC/BDC lines, stroke ruler) 'arc' 'hint' 'play' 'slider'
    const stage = stageBox(HIDE.has('fig') ? undefined : c.fig);
    const readout = h('div', { class: 'readout' });
    const slider = h('input', { type: 'range', min: '0', max: '360', step: '1', value: String(P.start), id: uid('crank') });
    const lab = h('label', { for: slider.id, text: LB.sliderLabel });
    let theta = P.start, dragging = false, lastA = 0, geom = null;
    const play = h('button', { class: 'btn sm', type: 'button' });
    const { el } = baseCard(c, {
      head: [...head2(c, c.title), h('p', { class: 'lead sm', text: c.lead })],
      mid: [stage],
      foot: [HIDE.has('readout') || [0, 1, 2].every(i => HIDE.has('stat' + i)) ? null : readout,
        (HIDE.has('slider') && HIDE.has('play')) ? null : h('div', { class: 'controls' }, HIDE.has('play') ? null : play, lab, HIDE.has('slider') ? null : slider),
        c.model ? modelBlock(c.model) : null].filter(Boolean)
    });
    const cv = makeCanvas(stage, () => sim.draw());
    const sim = addSim(el, {
      alwaysDraw: false, hintOn: !HIDE.has('hint'),
      update(dt) { theta = wrap360(theta + P.speed * dt); },
      draw() {
        if (!cv.w) return;
        const th = wrap360(theta);
        geom = drawEngine(cv.ctx, cv.w, cv.h, { theta: th, head: false, guides: !HIDE.has('guides'), arc: !HIDE.has('arc'), hint: sim.hintOn, text: LB, rod: P.rodRatio,
          parts: P.parts ? { piston: LB.partPiston, rod: LB.partRod, crank: LB.partCrank, cylinder: LB.partCylinder } : null });
        slider.value = String(Math.round(th));
        const travel = Math.round((1 - (geom.xp - (geom.L.l - geom.r)) / (2 * geom.r)) * 100);
        const dir = (th < 3 || th > 357) ? LB.top : (Math.abs(th - 180) < 3) ? LB.bottom : th < 180 ? LB.down : LB.up;
        readout.replaceChildren(...[
          h('span', {}, LB.crank + ' ', h('b', { text: Math.round(th) + '°' })),
          h('span', {}, LB.piston + ' ', h('b', { text: dir })),
          h('span', {}, LB.travel + ' ', h('b', { text: travel + LB.travelUnit }))
        ].filter((_, i) => !HIDE.has('stat' + i)));
      },
      onShow() { if (!reducedMQ.matches && !sim.touched) { sim.playing = true; sim.syncUI(); } }
    });
    // replace play button with synced one
    const pb = playButton(sim); play.replaceWith(pb);
    sim.alwaysDraw = !HIDE.has('hint'); // keeps hint ring pulsing while visible
    function angleAt(e) {
      const rc = cv.cv.getBoundingClientRect();
      return Math.atan2(e.clientX - rc.left - geom.cx, -(e.clientY - rc.top - geom.cy)) * 180 / Math.PI;
    }
    function hit(e) {
      if (!geom) return false;
      const rc = cv.cv.getBoundingClientRect(), x = e.clientX - rc.left, y = e.clientY - rc.top;
      const near = Math.hypot(x - geom.cx, y - geom.cy) < geom.r * 2.7;
      const inBore = Math.abs(x - geom.cx) < geom.bore / 2 + geom.r && y > geom.cy - geom.r * 6.2 && y < geom.cy;
      return near || inBore;
    }
    cv.cv.addEventListener('touchstart', e => { const t = e.touches[0]; if (hit(t)) e.preventDefault(); }, { passive: false });
    cv.cv.addEventListener('touchmove', e => { if (dragging) e.preventDefault(); }, { passive: false });
    cv.cv.addEventListener('pointerdown', e => {
      if (!hit(e)) return;
      dragging = true; lastA = angleAt(e); sim.playing = false; sim.touched = true; sim.hintOn = false; sim.syncUI();
      cv.cv.setPointerCapture(e.pointerId); cv.cv.classList.add('grabbing');
    });
    cv.cv.addEventListener('pointermove', e => {
      if (!dragging) { cv.cv.classList.toggle('grab', hit(e)); return; }
      const a = angleAt(e); let d = a - lastA;
      if (d > 180) d -= 360; if (d < -180) d += 360;
      theta = wrap360(theta + d); lastA = a; sim.draw();
    });
    const end = () => { dragging = false; cv.cv.classList.remove('grabbing'); };
    cv.cv.addEventListener('pointerup', end); cv.cv.addEventListener('pointercancel', end);
    slider.addEventListener('input', () => { theta = parseFloat(slider.value); sim.playing = false; sim.touched = true; sim.hintOn = false; sim.syncUI(); sim.draw(); });
    return el;
  };

  // sequence: the four-stroke cycle (exactly 4 strokes) with chips, scrubber and per-stroke text.
  const SEQ_LABELS = Object.assign({}, ENGINE_LABELS, {
    sliderLabel: 'Engine cycle position, 0 to 720 degrees of crank turn', chipsLabel: 'Jump to a stroke',
    strokeOf: 'STROKE {i} OF {n}', cycle: 'CRANK {deg}° OF 720°'
  });
  R.sequence = function (c) {
    const P = Object.assign({ intake: [0, 190], exhaust: [530, 720], ramp: 25, speed: 80, start: 440 }, c.params);
    const LB = Object.assign({}, SEQ_LABELS, c.labels);
    // optional: params.only = 0..3 makes a one-stroke card (the animation loops that stroke, the scrubber covers only it,
    // the header is a normal title plus c.lead). params.hide: 'fig' 'bar' 'count' 'chips' 'play' 'slider' 'desc'. Defaults: all shown.
    const ONLY = P.only != null ? clamp(Math.round(P.only), 0, 3) : null, LO = ONLY == null ? 0 : ONLY * 180;
    if (ONLY != null && !(c.params && c.params.start != null)) P.start = LO + 70;
    const HIDE = new Set([...(P.hide || []), ...(ONLY != null ? ['bar', 'chips', 'desc'] : [])]);
    const stage = stageBox(HIDE.has('fig') ? undefined : c.fig);
    const no = h('span', { class: 'no' }), nm = h('span', { class: 'nm' });
    const bar = h('div', { class: 'strokebar', 'aria-live': 'polite' }, nm, no);
    const slider = h('input', { type: 'range', min: String(LO), max: String(ONLY == null ? 719 : LO + 179), step: '1', value: String(P.start), id: uid('seq') });
    const lab = h('label', { for: slider.id, text: LB.sliderLabel });
    const desc = h('p', { class: 'desc' });
    const chips = c.strokes.map((s, i) => h('button', { class: 'chip', type: 'button', 'aria-pressed': 'false', onclick: () => { phi = i * 180 + 90; sim.playing = false; sim.touched = true; sim.syncUI(); sim.draw(); } },
      s.word, h('span', { class: 'sw', style: 'background:var(--' + s.gas + ')' })));
    const sp = h('button', { class: 'btn sm', type: 'button' });
    const { el } = baseCard(c, {
      head: ONLY != null
        ? [...head2(c, c.title), c.lead ? h('p', { class: 'lead sm', text: c.lead }) : null].filter(Boolean)
        : [h('div', { class: 'head' }, h('div', { class: 'kicker', text: c.kicker + ' · ' + c.title }), h('h2', { class: 'sr', text: c.title })), HIDE.has('bar') ? null : bar,
          c.lead ? h('p', { class: 'lead sm', text: c.lead }) : null].filter(Boolean),
      mid: [stage],
      foot: [
        HIDE.has('chips') ? null : h('div', { class: 'chips', role: 'group', 'aria-label': LB.chipsLabel }, chips),
        (HIDE.has('slider') && HIDE.has('play')) ? null : h('div', { class: 'controls' }, HIDE.has('play') ? null : sp, lab, HIDE.has('slider') ? null : slider),
        HIDE.has('desc') ? null : desc, c.model ? modelBlock(c.model) : null
      ].filter(Boolean)
    });
    let phi = P.start;
    const cv = makeCanvas(stage, () => sim.draw());
    const sim = addSim(el, {
      alwaysDraw: false,
      update(dt) { phi = ONLY == null ? wrap720(phi + P.speed * dt) : LO + ((phi - LO + P.speed * dt) % 180); },
      draw() {
        if (!cv.w) return;
        const g = gasAt(phi);
        drawEngine(cv.ctx, cv.w, cv.h, { theta: wrap360(phi), head: true, gas: g, labels: true, text: LB, rod: P.rodRatio, intake: lift(phi, P.intake, P.ramp), exhaust: lift(phi, P.exhaust, P.ramp) });
        const si = Math.floor(phi / 180) % 4, s = c.strokes[si];
        nm.textContent = s.name;
        no.replaceChildren(...(HIDE.has('count') ? [] : [fmt(LB.strokeOf, { i: si + 1, n: 4 }), h('br'), fmt(LB.cycle, { deg: Math.round(phi) })]));
        desc.textContent = s.text; slider.value = String(Math.round(phi) % 720);
        chips.forEach((b, i) => b.setAttribute('aria-pressed', String(i === si)));
      },
      onShow() { if (!reducedMQ.matches && !sim.touched) { sim.playing = true; sim.syncUI(); } }
    });
    sp.replaceWith(playButton(sim));
    slider.addEventListener('input', () => { phi = parseFloat(slider.value); sim.playing = false; sim.touched = true; sim.syncUI(); sim.draw(); });
    return el;
  };

  /* torque model for the cylinder-count block (one cylinder, relative units) */
  function makeTQ(rod) {
    const r = 1, l = rod, Vc = 2 * r / 8;
    const x = th => pistonX(th, r, l);
    const dx = th => (x(th + 1e-4) - x(th - 1e-4)) / 2e-4;
    const ss = (a, b, v) => { const k = clamp((v - a) / (b - a), 0, 1); return k * k * (3 - 2 * k); };
    const f = pc => {
      if (pc < 360 || pc >= 540) return 0;
      const th = rad(pc - 360), V = Vc + (x(0) - x(th));
      return ss(0, 12, pc - 360) * Math.pow(Vc / V, 1.3) * (-dx(th));
    };
    let pk = 0; for (let p = 360; p < 540; p += 0.5) pk = Math.max(pk, f(p));
    return { f, pk };
  }

  // sim-cylinders: pick a cylinder count; cylinders animate by firing order, plus a crankshaft push graph.
  const CYL_LABELS = {
    groupLabel: 'Number of cylinders', unit: 'CYL', order: 'ORDER', peak: 'PEAK PUSH', peakUnit: 'x AVERAGE',
    graphTitle: 'PUSH ON THE CRANKSHAFT', now: 'NOW', average: 'AVERAGE'
  };
  R['sim-cylinders'] = function (c) {
    const P = Object.assign({ speed: 120, selected: 1, rodRatio: 3.2 }, c.params);
    const LB = Object.assign({}, CYL_LABELS, c.labels);
    const TQ = makeTQ(P.rodRatio);
    let optI = Math.min(P.selected, c.options.length - 1), s = 0;
    const HIDE = new Set(P.hide || []);   // optional: 'graph' (push graph; cylinders get the full stage) 'segs' (count buttons) 'play' 'order' 'peak'
    const stage = stageBox();
    const info = h('div', { class: 'readout', style: 'display:grid;gap:2px', 'aria-live': 'off' });
    const segs = c.options.map((o, i) => h('button', { class: 'seg', type: 'button', 'aria-pressed': String(i === optI), onclick: () => { optI = i; syncSeg(); computeMin(); sim.draw(); } },
      String(o.n), h('small', { text: o.unit || LB.unit })));
    const pb = h('button', { class: 'btn sm', type: 'button' });
    stage.style.setProperty('--stage-max', HIDE.has('graph') ? '80cqw' : '135cqw');
    const { el } = baseCard(c, {
      head: [...head2(c, c.title), h('p', { class: 'lead sm', text: c.lead })],
      mid: [stage],
      foot: [
        HIDE.has('segs') ? null : h('div', { class: 'segrow', role: 'group', 'aria-label': LB.groupLabel }, segs),
        (HIDE.has('play') && HIDE.has('order') && HIDE.has('peak')) ? null : h('div', { class: 'controls' }, HIDE.has('play') ? null : pb, (HIDE.has('order') && HIDE.has('peak')) ? null : info),
        c.model ? modelBlock(c.model) : null
      ].filter(Boolean)
    });
    const infoSpans = o => [
      HIDE.has('order') ? null : h('span', {}, LB.order + ' ', h('b', { text: o.order.join('-') })),
      HIDE.has('peak') ? null : h('span', {}, LB.peak + ' ', h('b', { text: minPct + LB.peakUnit }))
    ].filter(Boolean);
    function syncSeg() { segs.forEach((b, i) => b.setAttribute('aria-pressed', String(i === optI))); }
    const total = (N, order, sx) => {
      let sum = 0;
      for (let ci = 0; ci < N; ci++) {
        const fire = order.indexOf(ci + 1) * 720 / N;
        sum += TQ.f(wrap720(sx - fire + 360));
      }
      return sum / N;
    };
    let minPct = 0, peakAbs = TQ.pk;
    function computeMin() {
      const o = c.options[optI]; let mx = 0, tot = 0, n = 0;
      for (let a = 0; a < 720; a += 1) { const v = total(o.n, o.order, a); mx = Math.max(mx, v); tot += v; n++; }
      minPct = (mx / (tot / n)).toFixed(1); peakAbs = mx;
      return minPct;
    }
    computeMin();
    const cv = makeCanvas(stage, () => sim.draw());
    const sim = addSim(el, {
      alwaysDraw: false,
      update(dt) { s += P.speed * dt; },
      draw() {
        if (!cv.w) return;
        const ctx = cv.ctx, W = cv.w, H = cv.h, o = c.options[optI], N = o.n;
        drawGrid(ctx, W, H);
        const Hb = HIDE.has('graph') ? H - 6 : Math.round(H * 0.47), pad = 12, slot = (W - 2 * pad) / N;
        const solo = HIDE.has('graph'), b = Math.min(slot * (solo ? 0.8 : 0.72), solo ? 96 : 84), r = Math.min(b * (solo ? 0.36 : 0.3), (Hb - 22) / 6.4), l = 3 * r;
        const cyC = Hb - r - 6, sp = wrap720(s);
        if (solo) { ctx.save(); ctx.translate(0, -Math.max(0, (Hb - 6 - (6.4 * r + 26)) / 2)); }
        // shaft
        const firstX = pad + slot / 2, lastX = pad + slot * (N - 0.5);
        ctx.lineCap = 'round'; ctx.lineJoin = 'round';
        ctx.strokeStyle = T.mech; ctx.lineWidth = Math.max(3, r * 0.3);
        ctx.beginPath(); ctx.moveTo(Math.max(0, firstX - slot * 0.4), cyC); ctx.lineTo(Math.min(W, lastX + slot * 0.4), cyC); ctx.stroke();
        for (let i = 0; i < N; i++) {
          const cx = pad + slot * (i + 0.5), fire = o.order.indexOf(i + 1) * 720 / N;
          const pc = wrap720(sp - fire + 360), th = rad(wrap360(pc));
          const g = gasAt(pc), xp = pistonX(th, r, l), pinY = cyC - xp, crownY = pinY - 0.55 * r;
          const headY = cyC - (r + l) - 0.55 * r - 0.25 * r;
          const x0 = cx - b / 2, x1 = cx + b / 2;
          ctx.fillStyle = rgba(g.col, g.a); ctx.fillRect(x0, headY, b, crownY - headY);
          if (g.flame > 0.05) {
            ctx.fillStyle = rgba(T.burnhot, 0.55 * g.flame); ctx.fillRect(x0, headY, b, Math.min(crownY - headY, b * 0.5));
          }
          ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5; ctx.beginPath();
          ctx.moveTo(x0, headY); ctx.lineTo(x0, cyC - 1.25 * r); ctx.moveTo(x1, headY); ctx.lineTo(x1, cyC - 1.25 * r); ctx.stroke();
          ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(x0 - 2, headY); ctx.lineTo(x1 + 2, headY); ctx.stroke();
          const px = cx + r * Math.sin(th), py = cyC - r * Math.cos(th);
          ctx.strokeStyle = T.line; ctx.lineWidth = 1; ctx.beginPath(); ctx.arc(cx, cyC, r, 0, TAU); ctx.stroke();
          ctx.strokeStyle = T.mech; ctx.lineWidth = Math.max(2, r * 0.22); ctx.beginPath(); ctx.moveTo(cx, pinY); ctx.lineTo(px, py); ctx.stroke();
          ctx.lineWidth = Math.max(3, r * 0.36); ctx.beginPath(); ctx.moveTo(cx, cyC); ctx.lineTo(px, py); ctx.stroke();
          ctx.fillStyle = T.mech; ctx.beginPath(); ctx.arc(px, py, Math.max(2.5, r * 0.26), 0, TAU); ctx.fill();
          const pw = b - 3;
          ctx.fillStyle = T.metal; ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5;
          ctx.fillRect(cx - pw / 2, crownY, pw, 1.1 * r); ctx.strokeRect(cx - pw / 2, crownY, pw, 1.1 * r);
          if (N > 1) { ctx.font = MONO; ctx.fillStyle = T.ink2; ctx.textAlign = 'center'; ctx.textBaseline = 'bottom'; ctx.fillText(String(i + 1), cx, headY - 5); }
        }
        if (solo) ctx.restore();
        if (HIDE.has('graph')) { info.replaceChildren(...infoSpans(o)); return; }
        // graph
        const gx0 = 12, gx1 = W - 12, gy0 = Hb + 22, gy1 = H - 14, gw = gx1 - gx0, gh = gy1 - gy0 - 4;
        ctx.font = MONO; ctx.fillStyle = T.ink2; ctx.textAlign = 'left'; ctx.textBaseline = 'bottom';
        ctx.fillText(LB.graphTitle, gx0, gy0 - 6);
        ctx.textAlign = 'right'; ctx.fillText(LB.now, gx1, gy0 - 6);
        ctx.strokeStyle = T.line; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(gx0, gy1 + 0.5); ctx.lineTo(gx1, gy1 + 0.5); ctx.stroke();
        const ymax = peakAbs * 1.12, samples = 160, startS = s - 720;
        const Y = v => gy1 - clamp(v / ymax, 0, 1) * gh;
        ctx.beginPath(); ctx.moveTo(gx0, gy1);
        for (let i = 0; i <= samples; i++) ctx.lineTo(gx0 + gw * i / samples, Y(total(N, o.order, startS + 720 * i / samples)));
        ctx.lineTo(gx1, gy1); ctx.closePath();
        ctx.fillStyle = rgba(T.burn, 0.28); ctx.fill();
        ctx.beginPath();
        for (let i = 0; i <= samples; i++) { const x = gx0 + gw * i / samples, y = Y(total(N, o.order, startS + 720 * i / samples)); i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
        ctx.strokeStyle = T.accent; ctx.lineWidth = 2.5; ctx.stroke();
        let tot = 0; for (let a = 0; a < 720; a += 2) tot += total(N, o.order, a);
        const avg = tot / 360;
        ctx.save(); ctx.setLineDash([5, 4]); ctx.strokeStyle = T.ink2; ctx.lineWidth = 1.2; ctx.beginPath(); ctx.moveTo(gx0, Y(avg)); ctx.lineTo(gx1, Y(avg)); ctx.stroke(); ctx.restore();
        ctx.textAlign = 'right'; ctx.textBaseline = 'bottom'; ctx.lineWidth = 4; ctx.strokeStyle = T.panel; ctx.strokeText(LB.average, gx1 - 8, Y(avg) - 3); ctx.fillStyle = T.ink2; ctx.fillText(LB.average, gx1 - 8, Y(avg) - 3);
        ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(gx1 - 0.5, gy0); ctx.lineTo(gx1 - 0.5, gy1); ctx.stroke();
        info.replaceChildren(...infoSpans(o));
      },
      onShow() { if (!reducedMQ.matches && !sim.touched) { sim.playing = true; sim.syncUI(); } }
    });
    pb.replaceWith(playButton(sim));
    if (reducedMQ.matches) s = 380; // static frame: a power stroke is under way
    return el;
  };

  /* ---------- sim-gears: a meshing spur-gear pair with real involute teeth ---------- */
  const GEAR_LABELS = {
    engine: 'ENGINE', output: 'OUTPUT', torque: 'TORQUE', road: 'ROAD SPEED', wheelTorque: 'WHEEL TORQUE',
    rpm: 'RPM', kmh: 'KM/H', times: '×',
    driver: 'DRIVER', driven: 'DRIVEN', teeth: '{n} TEETH', slowmo: 'SLOW MOTION',
    band: 'GOOD RANGE', ok: 'IN RANGE', low: 'TOO LOW', over: 'TOO FAST', slip: 'CLUTCH SLIPS',
    sliderRpm: 'Engine speed in rpm', sliderSpeed: 'Road speed in km/h',
    gearsGroup: 'Gear', gear: 'Gear {n}, ratio {r} to 1', setsGroup: 'Vehicle'
  };
  const numFmt = (v, d) => v.toLocaleString('en-US', { minimumFractionDigits: d || 0, maximumFractionDigits: d || 0 });
  const INV20 = Math.tan(rad(20)) - rad(20);
  // Ambient decorative gear pair for intro/hook (visual 'gears'): slow, no labels, no controls. params {driving, driven, speed (driver turns/s)}
  function ambientGears(el, stage, params) {
    const P = Object.assign({ driving: 14, driven: 50, speed: 0.08, phase: 0.6 }, params);
    let ang = P.phase;
    let sim; // see ambientCrank
    const cv = makeCanvas(stage, () => sim && sim.draw());
    sim = addSim(el, {
      update(dt) { ang += TAU * P.speed * dt; },
      draw() {
        if (!cv.w) return;
        const ctx = cv.ctx, W = cv.w, H = cv.h, N1 = P.driving, N2 = P.driven;
        drawGrid(ctx, W, H);
        const total = (N1 + N2) / 2 + N1 / 2 + N2 / 2 + 4;
        const m = Math.min((W - 24) / total, (H - 24) / (Math.max(N1, N2) + 2), 8);
        const x0 = (W - m * total) / 2 + m * (N1 / 2 + 1), x1 = x0 + m * (N1 + N2) / 2, cy = H / 2;
        const ph2 = Math.PI + Math.PI / N2 - (N1 / N2) * ang;
        [[x0, N1, ang, mixc(T.panel, T.accent, 0.16)], [x1, N2, ph2, T.block]].forEach(([cx, N, ph, fill]) => {
          const o = gearOutline(ctx, cx, cy, N, m, ph);
          ctx.fillStyle = fill; ctx.fill(); ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5; ctx.lineJoin = 'round'; ctx.stroke();
          ctx.strokeStyle = T.ink2; ctx.lineWidth = 2; ctx.lineCap = 'round'; ctx.beginPath();
          for (let k = 0; k < 4; k++) { const a = ph + k * Math.PI / 2 + Math.PI / N; ctx.moveTo(cx + Math.cos(a) * o.rr * 0.28, cy + Math.sin(a) * o.rr * 0.28); ctx.lineTo(cx + Math.cos(a) * o.rr * 0.6, cy + Math.sin(a) * o.rr * 0.6); }
          ctx.stroke();
          ctx.beginPath(); ctx.arc(cx, cy, Math.max(4, o.rr * 0.2), 0, TAU); ctx.fillStyle = T.panel; ctx.fill(); ctx.strokeStyle = T.ink; ctx.stroke();
        });
      },
      onShow() { if (!reducedMQ.matches) sim.playing = true; }
    });
  }
  // Closed gear outline (module 1 = tooth size unit scaled by m). Standard 20 degree involute, addendum 1m, dedendum 1.25m.
  function gearOutline(ctx, cx, cy, N, m, phase) {
    const rp = m * N / 2, rb = rp * Math.cos(rad(20)), ro = rp + m, rr = rp - 1.25 * m, p = TAU / N;
    const back = 0.03 * m / rp; // a little backlash so drawn teeth never overlap
    const half = r => Math.PI / (2 * N) + INV20 - (() => { const a = Math.acos(Math.min(1, rb / r)); return Math.tan(a) - a; })() - back;
    const r0 = Math.max(rb, rr), STEPS = 5;
    const P = (r, a) => [cx + r * Math.cos(a), cy + r * Math.sin(a)];
    ctx.beginPath();
    for (let k = 0; k < N; k++) {
      const c = phase + k * p, pts = [];
      // left flank, root to tip
      if (rr < rb) pts.push(P(rr, c - half(rb)));
      for (let i = 0; i <= STEPS; i++) { const r = r0 + (ro - r0) * i / STEPS; pts.push(P(r, c - half(r))); }
      // right flank, tip to root
      for (let i = STEPS; i >= 0; i--) { const r = r0 + (ro - r0) * i / STEPS; pts.push(P(r, c + half(r))); }
      if (rr < rb) pts.push(P(rr, c + half(rb)));
      pts.forEach((q, i) => { if (k === 0 && i === 0) ctx.moveTo(q[0], q[1]); else ctx.lineTo(q[0], q[1]); });
    }
    ctx.closePath();
    return { rp, ro, rr };
  }
  R['sim-gears'] = function (c) {
    const P = Object.assign({ mode: 'rpm', set: 0, selected: 0 }, c.params);
    const LB = Object.assign({}, GEAR_LABELS, c.labels);
    const sets = c.sets;
    const speedMode = P.mode === 'speed';
    const showBar = P.bar != null ? !!P.bar : speedMode;
    const HIDE = new Set(P.hide || []);   // optional: 'legend' 'slowmo' 'fig' 'readout' 'stat0' 'stat1' 'stat2' 'gears' 'slider' 'play'
    let si = Math.min(P.set, sets.length - 1), gi = Math.min(P.selected, sets[si].gears.length - 1);
    let ang = 0, dragging = false, lastA = 0, geom = null, userVal = null;
    const S0 = () => sets[si];
    const ratioOf = g => g.driven / g.driving;
    const finalOf = s => (s.final == null ? 1 : s.final);
    const sliderCfg = s => speedMode
      ? { min: 0, max: s.speedMax || 180, step: 1, val: s.speedStart != null ? s.speedStart : 20 }
      : { min: 0, max: s.rpmMax || (s.redline || 6000), step: s.rpmStep || 100, val: s.rpmStart != null ? s.rpmStart : 2000 };

    const stage = stageBox(HIDE.has('fig') ? undefined : c.fig);
    stage.style.setProperty('--stage-min', '150px');
    // placeholder text reserves the row height before the first draw (no layout jump, no ResizeObserver loop)
    const stat = (cls) => { const small = h('small', { text: '\u00A0' }), val = h('span', { class: 'v', text: '0' }), unit = h('span', { class: 'u' }); return { el: h('div', { class: 'gstat ' + cls }, small, h('b', {}, val, unit)), small, val, unit }; };
    const st = [stat('a'), stat('b'), stat('c')];
    st.forEach((q, i) => { if (HIDE.has('readout') || HIDE.has('stat' + i)) q.el.style.display = 'none'; });
    const stats = h('div', { class: 'gstats' }, st.map(s => s.el));
    const nStat = HIDE.has('readout') ? 0 : st.filter((q, i) => !HIDE.has('stat' + i)).length;
    if (nStat) stats.style.gridTemplateColumns = 'repeat(' + nStat + ',1fr)'; else stats.style.display = 'none';
    const gearRow = h('div', { class: 'segrow gears', role: 'group', 'aria-label': LB.gearsGroup });
    const setRow = sets.length > 1 ? h('div', { class: 'segrow tight', role: 'group', 'aria-label': LB.setsGroup, style: 'grid-template-columns:repeat(' + sets.length + ',1fr)' }) : null;
    const slider = h('input', { type: 'range', id: uid('gears') });
    const lab = h('label', { for: slider.id, text: speedMode ? LB.sliderSpeed : LB.sliderRpm });
    const pb = h('button', { class: 'btn sm', type: 'button' });
    const { el } = baseCard(c, {
      head: [...head2(c, c.title), h('p', { class: 'lead sm', text: c.lead })],
      mid: [stage],
      foot: [stats, setRow, HIDE.has('gears') ? null : gearRow, (HIDE.has('slider') && HIDE.has('play')) ? null : h('div', { class: 'controls' }, HIDE.has('play') ? null : pb, lab, HIDE.has('slider') ? null : slider), c.model ? modelBlock(c.model) : null].filter(Boolean)
    });
    function buildGears() {
      const s = S0();
      gearRow.style.gridTemplateColumns = 'repeat(' + s.gears.length + ',1fr)';
      gearRow.replaceChildren(...s.gears.map((g, i) => h('button', {
        class: 'seg', type: 'button', 'aria-pressed': String(i === gi), text: g.name,
        'aria-label': fmt(LB.gear, { n: g.name, r: numFmt(ratioOf(g), 1) }),
        onclick: () => { gi = i; syncGears(); sim.draw(); }
      })));
    }
    function syncGears() { [...gearRow.children].forEach((b, i) => b.setAttribute('aria-pressed', String(i === gi))); }
    function buildSets() {
      if (!setRow) return;
      setRow.replaceChildren(...sets.map((s, i) => h('button', {
        class: 'seg', type: 'button', 'aria-pressed': String(i === si), text: s.label,
        onclick: () => { si = i; gi = Math.min(P.selected, sets[si].gears.length - 1); applySet(); sim.draw(); }
      })));
    }
    function applySet() {
      const k = sliderCfg(S0());
      slider.min = String(k.min); slider.max = String(k.max); slider.step = String(k.step); slider.value = String(k.val);
      buildGears();
      if (setRow) [...setRow.children].forEach((b, i) => b.setAttribute('aria-pressed', String(i === si)));
    }
    // Engine rpm, road speed, and the state of the engine for the current slider value and gear.
    function state() {
      const s = S0(), g = s.gears[gi], v = parseFloat(slider.value), tot = ratioOf(g) * finalOf(s);
      let rpm, speed = null, slip = false;
      if (speedMode) {
        speed = v;
        rpm = (v * 1000 / 60 / s.wheel) * tot;
        if (rpm < (s.idle || 0)) { rpm = s.idle || 0; slip = true; }
      } else rpm = v;
      let st = null;
      if (s.band) st = slip ? 'slip' : rpm < s.band[0] ? 'low' : rpm > (s.redline || s.band[1]) ? 'over' : 'ok';
      return { s, g, rpm, speed, tot, st, slip };
    }
    function drawBar(ctx, W, s, rpm, stt) {
      const x0 = 12, x1 = W - 12, y = 28, bh = 10, max = s.scaleMax || (s.redline || s.band[1]) * 1.18;
      const X = v => x0 + (x1 - x0) * clamp(v / max, 0, 1);
      ctx.fillStyle = rgba(T.line, 0.28); ctx.fillRect(x0, y, x1 - x0, bh);
      if (s.redline) { ctx.fillStyle = rgba(T.bad, 0.4); ctx.fillRect(X(s.redline), y, x1 - X(s.redline), bh); }
      ctx.fillStyle = rgba(T.good, 0.45); ctx.fillRect(X(s.band[0]), y, X(s.band[1]) - X(s.band[0]), bh);
      ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5; ctx.strokeRect(x0, y, x1 - x0, bh);
      ctx.strokeStyle = T.good; ctx.lineWidth = 2; ctx.strokeRect(X(s.band[0]), y, X(s.band[1]) - X(s.band[0]), bh);
      const nx = X(rpm), col = stt === 'ok' ? T.good : stt === 'low' || stt === 'slip' ? T.ink : T.bad;
      ctx.fillStyle = col; ctx.beginPath(); ctx.moveTo(nx - 6, y - 10); ctx.lineTo(nx + 6, y - 10); ctx.lineTo(nx, y - 1); ctx.closePath(); ctx.fill();
      ctx.fillRect(nx - 1, y, 2, bh);
      ctx.font = MONO; ctx.textBaseline = 'alphabetic';
      ctx.fillStyle = T.ink2; ctx.textAlign = 'left';
      ctx.fillText(LB.band + ' ' + numFmt(s.band[0]) + '–' + numFmt(s.band[1]), x0, y - 14);
      if (stt) { ctx.fillStyle = stt === 'ok' ? T.good : stt === 'over' ? T.bad : T.ink; ctx.textAlign = 'right'; ctx.fillText(LB[stt], x1, y - 14); }
      return y + bh + 10;
    }
    const sim = addSim(el, {
      update(dt) {
        if (dragging) return;
        const s = state();
        ang += TAU * (s.s.spin || 0.2) * (s.rpm / 1000) * dt;
      },
      draw() {
        if (!cv.w) return;
        const ctx = cv.ctx, W = cv.w, H = cv.h, X = state(), s = X.s, g = X.g, N1 = g.driving, N2 = g.driven;
        drawGrid(ctx, W, H);
        let topY = 8;
        if (showBar && s.band) topY = drawBar(ctx, W, s, X.rpm, X.st);
        // size from the largest gears in the whole set so shafts stay put when the gear changes
        let mN1 = 0, mN2 = 0, mD = 0;
        s.gears.forEach(q => { mN1 = Math.max(mN1, q.driving); mN2 = Math.max(mN2, q.driven); mD = Math.max(mD, (q.driving + q.driven) / 2); });
        const left = mN1 / 2 + 1, right = mN2 / 2 + 1, total = left + mD + right, pad = 10;
        const availH = H - topY - 40;
        const m = Math.min((W - 2 * pad) / total, availH / (Math.max(mN1, mN2) + 2), 7);
        const x0 = (W - m * total) / 2 + m * left, cy = topY + availH / 2 + 4;
        const x1 = x0 + m * (N1 + N2) / 2;
        const ph1 = ang, ph2 = Math.PI + Math.PI / N2 - (N1 / N2) * ang;   // exact mesh: tooth of gear 1 meets gap of gear 2 on the line of centres
        const drawGear = (cx, N, phase, fill, ccw) => {
          const o = gearOutline(ctx, cx, cy, N, m, phase);
          ctx.fillStyle = fill; ctx.fill(); ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5; ctx.lineJoin = 'round'; ctx.stroke();
          // marked tooth
          ctx.save(); ctx.beginPath(); ctx.arc(cx, cy, o.ro + 2, phase - Math.PI / N, phase + Math.PI / N); ctx.arc(cx, cy, o.rr + 1, phase + Math.PI / N, phase - Math.PI / N, true); ctx.closePath();
          ctx.clip(); gearOutline(ctx, cx, cy, N, m, phase); ctx.fillStyle = T.accent; ctx.fill(); ctx.restore();
          gearOutline(ctx, cx, cy, N, m, phase); ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5; ctx.stroke();
          // spokes show the turning
          ctx.strokeStyle = T.ink2; ctx.lineWidth = 2; ctx.lineCap = 'round'; ctx.beginPath();
          for (let k = 0; k < 4; k++) { const a = phase + k * Math.PI / 2 + Math.PI / N; ctx.moveTo(cx + Math.cos(a) * o.rr * 0.28, cy + Math.sin(a) * o.rr * 0.28); ctx.lineTo(cx + Math.cos(a) * o.rr * 0.5, cy + Math.sin(a) * o.rr * 0.5); }
          ctx.stroke();
          ctx.beginPath(); ctx.arc(cx, cy, Math.max(4, o.rr * 0.2), 0, TAU); ctx.fillStyle = T.panel; ctx.fill(); ctx.strokeStyle = T.ink; ctx.lineWidth = 1.5; ctx.stroke();
          // turning-direction arrow above the hub
          const ar = Math.max(9, o.rr * 0.8), a0 = -Math.PI / 2 - 0.9, a1 = -Math.PI / 2 + 0.9;
          if (o.rr > 14) {
            ctx.strokeStyle = T.accent; ctx.lineWidth = 2; ctx.beginPath();
            const s0 = ccw ? a1 : a0, s1 = ccw ? a0 : a1;
            ctx.arc(cx, cy, ar, s0, s1, !!ccw); ctx.stroke();
            const ex = cx + ar * Math.cos(s1), ey = cy + ar * Math.sin(s1), dir = s1 + (ccw ? -Math.PI / 2 : Math.PI / 2);
            ctx.fillStyle = T.accent; ctx.beginPath();
            ctx.moveTo(ex + 6 * Math.cos(dir), ey + 6 * Math.sin(dir));
            ctx.lineTo(ex + 4.5 * Math.cos(dir + 2.2), ey + 4.5 * Math.sin(dir + 2.2));
            ctx.lineTo(ex + 4.5 * Math.cos(dir - 2.2), ey + 4.5 * Math.sin(dir - 2.2)); ctx.closePath(); ctx.fill();
          }
          return o;
        };
        const fill2 = T.block, fill1 = mixc(T.panel, T.accent, 0.16);
        const o2 = drawGear(x1, N2, ph2, fill2, true);
        const o1 = drawGear(x0, N1, ph1, fill1, false);
        geom = { x0, cy, ro: o1.ro };
        // captions: one line, a swatch of each gear's colour in front of its name and tooth count
        ctx.font = MONO; ctx.textAlign = 'left'; ctx.textBaseline = 'alphabetic';
        let cxp = 10;
        if (!HIDE.has('legend')) [[fill1, LB.driver, N1], [fill2, LB.driven, N2]].forEach(([f, nm, n]) => {
          ctx.fillStyle = f; ctx.fillRect(cxp, H - 32, 9, 9); ctx.strokeStyle = T.ink; ctx.lineWidth = 1.2; ctx.strokeRect(cxp + 0.5, H - 31.5, 8, 8);
          const tx = nm + ' ' + fmt(LB.teeth, { n });
          ctx.fillStyle = T.ink; ctx.fillText(tx, cxp + 14, H - 24); cxp += 14 + ctx.measureText(tx).width + 14;
        });
        if (LB.slowmo && !HIDE.has('slowmo') && !HIDE.has('legend')) { ctx.fillStyle = T.ink2; ctx.fillText(LB.slowmo, 10, H - 9); }
        // readouts
        const t = X.tot, mult = speedMode ? t : ratioOf(g);
        if (speedMode) {
          st[0].small.textContent = LB.road; st[0].val.textContent = numFmt(X.speed); st[0].unit.textContent = ' ' + LB.kmh;
          st[1].small.textContent = LB.engine; st[1].val.textContent = numFmt(Math.round(X.rpm / 10) * 10); st[1].unit.textContent = ' ' + LB.rpm;
          st[2].small.textContent = LB.wheelTorque;
        } else {
          st[0].small.textContent = LB.engine; st[0].val.textContent = numFmt(X.rpm); st[0].unit.textContent = ' ' + LB.rpm;
          st[1].small.textContent = LB.output; st[1].val.textContent = numFmt(Math.round(X.rpm / ratioOf(g) / 10) * 10); st[1].unit.textContent = ' ' + LB.rpm;
          st[2].small.textContent = LB.torque;
        }
        st[2].val.textContent = LB.times + numFmt(mult, mult >= 10 ? 0 : 1); st[2].unit.textContent = '';
        st[1].el.classList.toggle('warn', speedMode && (X.st === 'over'));
        slider.setAttribute('aria-valuetext', speedMode ? numFmt(X.speed) + ' ' + LB.kmh : numFmt(X.rpm) + ' ' + LB.rpm);
      },
      onShow() { if (!reducedMQ.matches && !sim.touched) { sim.playing = true; sim.syncUI(); } }
    });
    const cv = makeCanvas(stage, () => sim.draw());
    pb.replaceWith(playButton(sim));
    buildSets(); applySet();
    slider.addEventListener('input', () => sim.draw());
    // drag the driver gear by hand (only the small gear grabs the touch, so the feed still scrolls elsewhere)
    const hit = e => {
      if (!geom) return false;
      const rc = cv.cv.getBoundingClientRect();
      return Math.hypot(e.clientX - rc.left - geom.x0, e.clientY - rc.top - geom.cy) < geom.ro + 10;
    };
    const angleAt = e => { const rc = cv.cv.getBoundingClientRect(); return Math.atan2(e.clientY - rc.top - geom.cy, e.clientX - rc.left - geom.x0); };
    cv.cv.addEventListener('touchstart', e => { if (hit(e.touches[0])) e.preventDefault(); }, { passive: false });
    cv.cv.addEventListener('touchmove', e => { if (dragging) e.preventDefault(); }, { passive: false });
    cv.cv.addEventListener('pointerdown', e => {
      if (!hit(e)) return;
      dragging = true; lastA = angleAt(e); cv.cv.setPointerCapture(e.pointerId); cv.cv.classList.add('grabbing');
    });
    cv.cv.addEventListener('pointermove', e => {
      if (!dragging) { cv.cv.classList.toggle('grab', hit(e)); return; }
      const a = angleAt(e); let d = a - lastA;
      if (d > Math.PI) d -= TAU; if (d < -Math.PI) d += TAU;
      ang += d; lastA = a; sim.draw();
    });
    const end = () => { dragging = false; cv.cv.classList.remove('grabbing'); };
    cv.cv.addEventListener('pointerup', end); cv.cv.addEventListener('pointercancel', end);
    return el;
  };

  // recall: N questions (3 options each), one at a time, then a score.
  R.recall = function (c) {
    const body = h('div', { class: 'recallbody' });
    const { el } = baseCard(c, { head: [...head2(c, c.title), h('p', { class: 'lead sm', text: c.lead })], mid: [body] });
    let qi = 0, score = 0;
    function show() {
      body.replaceChildren();
      body.classList.toggle('done', qi >= c.questions.length);
      if (qi >= c.questions.length) {
        body.append(
          h('div', { class: 'qstep', text: UI.score }),
          h('div', { class: 'score', text: score + ' / ' + c.questions.length }),
          h('p', { class: 'lead', text: c.closing || UI.recallClosing }),
          h('button', { class: 'btn', type: 'button', text: UI.tryAgain, onclick: () => { qi = 0; score = 0; show(); } }),
          cueEl(c));
        return;
      }
      const q = c.questions[qi];
      const fb = h('p', { class: 'fb', 'aria-live': 'polite' });
      const next = h('button', { class: 'btn solid ghost', type: 'button', disabled: true, tabindex: '-1', 'aria-hidden': 'true', text: qi === c.questions.length - 1 ? UI.seeScore : UI.nextQuestion, onclick: () => { qi++; show(); } });
      let done = false;
      const opts = q.options.map((t, k) => h('button', {
        class: 'opt', type: 'button', onclick: () => {
          if (done) return; done = true;
          const right = k === q.a; if (right) score++;
          opts.forEach((b, j) => { b.setAttribute('aria-disabled', 'true'); b.classList.add('answered'); if (j === q.a) { b.classList.add('ok'); b.querySelector('.opt-tag').textContent = UI.answer; } else if (j === k) { b.classList.add('bad'); b.querySelector('.opt-tag').textContent = UI.notQuite; } });
          fb.className = 'fb ' + (right ? 'ok' : 'bad');
          fb.replaceChildren(h('b', { text: right ? UI.rightPrefix : UI.notQuitePrefix }), q.why);
          next.disabled = false; next.removeAttribute('tabindex'); next.removeAttribute('aria-hidden'); next.classList.remove('ghost');
        }
      }, h('span', { class: 'opt-key', text: 'ABCD'[k] }), h('span', { class: 'opt-body' }, h('span', { class: 'opt-text', text: t })), h('span', { class: 'opt-tag' })));
      body.append(h('div', { class: 'qstep', text: fmt(UI.questionOf, { i: qi + 1, n: c.questions.length }) }),
        h('h2', { style: 'font-size:clamp(26px,7.4vw,32px)', text: q.q }),
        h('div', { class: 'opts', style: '--n:' + q.options.length }, opts), fb, next);
    }
    show();
    return el;
  };

  // branches: "where next" list. Item = string, or {t, href, topic?}. With href it is a real link (same tab);
  // without, tapping toggles the "coming next" vote note.
  R.branches = function (c) {
    const items = c.items.map(it => {
      const t = typeof it === 'string' ? it : it.t;
      // item.topic: id of a sibling topic. A host page (library build) sets TMH.topicHref(id) to link in-page; otherwise href is used.
      const href = typeof it === 'string' ? null : (it.topic && window.TMH.topicHref ? window.TMH.topicHref(it.topic) : it.href);
      if (href) return h('a', { class: 'vote link', href }, h('span', { text: t }), h('span', { class: 'go', text: c.go || UI.go }));
      const b = h('button', { class: 'vote', type: 'button', 'aria-pressed': 'false' }, h('span', { text: t }), h('span', { class: 'soon', text: c.soon }));
      b.addEventListener('click', () => b.setAttribute('aria-pressed', String(b.getAttribute('aria-pressed') !== 'true')));
      return b;
    });
    const { el } = baseCard(c, {
      head: [...head2(c, c.title), h('p', { class: 'lead sm', text: c.lead })],
      mid: [h('div', { class: 'votes', style: '--n:' + items.length }, items)],
      foot: [h('button', { class: 'btn', type: 'button', text: c.restart, onclick: build })]
    });
    return el;
  };

  /* ---------- build / feed / progress ---------- */
  let EX = null, feed = null, countEl = null, segsEl = null, io = null, cur = -1, nums = [], mounted = false;

  // The intro cover is not counted: cards after it are numbered 01..N and the cover shows "Intro".
  function countedTotal() { return EX.cards.filter(c => c.type !== 'intro').length; }
  function setCurrent(i) {
    if (i === cur) return; cur = i;
    const num = nums[i] || 0;
    if (num) countEl.replaceChildren(h('b', { text: pad2(num) }), ' / ' + pad2(countedTotal()));
    else countEl.replaceChildren(UI.intro);
    [...segsEl.children].forEach((s, k) => { s.className = k < num - 1 ? 'done' : k === num - 1 ? 'now' : ''; });
  }
  function teardownCards() {
    if (io) { io.disconnect(); io = null; }
    topicRO.forEach(r => r.disconnect()); topicRO.length = 0;
    sims.length = 0; cur = -1; nums = [];
  }
  function build() {
    teardownCards();
    feed.replaceChildren(); segsEl.replaceChildren();
    let counted = 0;
    const cards = EX.cards.map((c, i) => {
      if (!R[c.type]) throw new Error('TMH: unknown card type "' + c.type + '" (card ' + i + ')');
      const el = R[c.type](c, i);
      el.dataset.i = i; el.dataset.type = c.type;
      if (c.type === 'intro') nums.push(0);
      else { nums.push(++counted); segsEl.append(h('i')); }
      return el;
    });
    feed.append(...cards);
    setCurrent(0);
    feed.scrollTo({ top: 0 });
    io = new IntersectionObserver(entries => {
      entries.forEach(en => {
        const vis = en.intersectionRatio >= 0.5;
        if (vis) setCurrent(+en.target.dataset.i);
        (en.target.__sims || []).forEach(s => {
          const was = s.visible; s.visible = vis;
          if (vis && !was) { s.onShow && s.onShow(); s.draw(); }
        });
      });
    }, { root: feed, threshold: [0, 0.5, 0.75] });
    cards.forEach(c => io.observe(c));
    // draw static first frames
    requestAnimationFrame(() => sims.forEach(s => { s.visible = true; s.draw(); s.visible = false; }));
  }

  /* ---------- entry point ---------- */
  // Expects the page markup: #count, #segs, #feed (build.mjs emits it).
  function onKey(e) {
    const t = e.target;
    if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.tagName === 'SELECT')) return;
    const k = e.key;
    if (k === 'ArrowDown' || k === 'PageDown') { feed.scrollBy({ top: feed.clientHeight, behavior: reducedMQ.matches ? 'auto' : 'smooth' }); e.preventDefault(); }
    else if (k === 'ArrowUp' || k === 'PageUp') { feed.scrollBy({ top: -feed.clientHeight, behavior: reducedMQ.matches ? 'auto' : 'smooth' }); e.preventDefault(); }
  }
  // Calling mount while a topic is mounted replaces it (unmounts first).
  function mount(explainer) {
    if (mounted) unmount();
    mounted = true;
    EX = explainer;
    UI = Object.assign({}, UI_DEFAULT, EX.ui);
    feed = document.getElementById('feed');
    countEl = document.getElementById('count');
    segsEl = document.getElementById('segs');
    feed.setAttribute('aria-label', EX.ariaLabel || (EX.title + '. Swipe up through the cards.'));
    retain();
    if (document.fonts && document.fonts.ready) { const ex = EX; document.fonts.ready.then(() => { if (EX === ex) redrawAll(); }); }
    document.addEventListener('keydown', onKey);
    build();
  }
  // Full teardown: no rAF work, observers or listeners remain from the topic; feed and HUD are emptied.
  function unmount() {
    if (!mounted) return;
    mounted = false;
    teardownCards();
    document.removeEventListener('keydown', onKey);
    feed.replaceChildren(); segsEl.replaceChildren(); countEl.replaceChildren();
    feed.removeAttribute('aria-label');
    feed.scrollTop = 0;
    EX = null; UI = UI_DEFAULT; sims.length = 0;
    release();
  }

  // Ambient tile visuals (library home): spec {visual: 'crank' | 'gears', params?}. Runs always-visible
  // inside host until clearAmbient(). Same canvases as the intro covers.
  function ambient(host, spec) {
    const sp = spec || {};
    if (sp.visual !== 'crank' && sp.visual !== 'gears') return;
    retain();
    const n0 = ambientSims.length;
    simSink = ambientSims; roSink = ambientRO;
    try {
      const el = {};
      if (sp.visual === 'crank') ambientCrank(el, host, Object.assign({ speed: 40, start: 40 }, sp.params));
      else ambientGears(el, host, sp.params);
    } finally { simSink = sims; roSink = topicRO; }
    ambientSims.slice(n0).forEach(s => { s.visible = true; s.draw(); s.onShow && s.onShow(); });
    ambientHolds++;
  }
  let ambientHolds = 0;
  function clearAmbient() {
    ambientRO.forEach(r => r.disconnect()); ambientRO.length = 0;
    ambientSims.length = 0;
    while (ambientHolds) { ambientHolds--; release(); }
  }
  // Debug counters for leak checks: active rAF loop (0 or 1), live sims, observers.
  const debug = () => ({ loop: raf ? 1 : 0, holds, sims: sims.length, ambientSims: ambientSims.length, resizeObservers: topicRO.length + ambientRO.length, keydown: mounted });

  window.TMH = {
    mount, unmount, ambient, clearAmbient, debug, blocks: R, h, baseCard, modelBlock, stageBox, head2, cueEl, kickerEl, uid, fmt, ui: k => UI[k],
    makeCanvas, addSim, playButton, drawGrid, theme: T, rgba, mixc, clamp, reducedMotion: () => reducedMQ.matches
  };
})();
