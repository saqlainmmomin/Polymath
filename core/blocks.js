/* Tell Me How core (v2): card renderers, visual renderers (line art on canvas), canvas/sim infrastructure.
   Topic-agnostic: everything topic-specific comes from the data passed to TMH.build(EXPLAINER).
   The shorts feed (vertical topics, horizontal cards, hash, index) lives in core/library.js. See core/BLOCKS.md. */
(function () {
  'use strict';

  /* ---------- helpers ---------- */
  const UI = {
    play: 'Play', pause: 'Pause', step: 'Step', playAria: 'Play animation', pauseAria: 'Pause animation', stepAria: 'Step the animation',
    swipe: 'Swipe ←', swipeMore: 'Swipe', thisOne: 'This one', guessWait: 'Pick an answer to see it',
    goDeeper: 'Go deeper', swipeUp: 'Swipe up for something new', cards: 'cards',
    // interaction cues (the pill on a picture's bottom edge); each visual picks its own, a `tip` param overrides, `tip: false` removes
    tips: { crank: 'Drag the crank', strokes: 'Drag to turn the engine', gears: 'Drag the gear to turn it', cylinders: 'Tap a number to compare', scrub: 'Drag the slider', dots: 'Tap a dot to jump' }
  };
  const fmt = (str, vars) => String(str).replace(/\{(\w+)\}/g, (m, k) => (k in vars ? vars[k] : m));
  const TAU = Math.PI * 2;
  const rad = d => d * Math.PI / 180;
  const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
  const wrap360 = d => ((d % 360) + 360) % 360;
  const wrap720 = d => ((d % 720) + 720) % 720;
  const MONO = "500 10px 'IBM Plex Mono', ui-monospace, Menlo, monospace";
  const reducedMQ = window.matchMedia('(prefers-reduced-motion: reduce)');
  const LW = 1.25, LW2 = 2;   // line art stroke widths: normal, main part

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
  const TOKENS = { paper: 'paper', panel: 'panel', ink: 'ink', ink2: 'ink2', rule: 'rule', accent: 'accent', blue: 's-blue', heat: 's-heat', green: 's-green', spark: 's-spark' };
  function readTheme() {
    const cs = getComputedStyle(document.documentElement);
    for (const k in TOKENS) T[k] = cs.getPropertyValue('--' + TOKENS[k]).trim();
  }
  const rgbCache = {};
  function rgbOf(c) {
    if (rgbCache[c]) return rgbCache[c];
    const out = c[0] === '#'
      ? [parseInt(c.slice(1, 3), 16), parseInt(c.slice(3, 5), 16), parseInt(c.slice(5, 7), 16)]
      : c.match(/[\d.]+/g).slice(0, 3).map(Number);
    return (rgbCache[c] = out);
  }
  function mixc(a, b, t) {
    const A = rgbOf(a), B = rgbOf(b);
    return 'rgb(' + A.map((v, i) => Math.round(v + (B[i] - v) * t)).join(',') + ')';
  }
  // flat tint: a colour at strength a over the panel (no gradients)
  const tint = (c, a) => mixc(T.panel, c, a);
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
  // 0-180 intake, 180-360 compression, 360-540 power, 540-720 exhaust. Fuel/air = blue, burning = heat.
  function gasAt(p) {
    p = wrap720(p);
    let col, a, count = 1;
    if (p < 180) { const k = p / 180; col = T.blue; a = 0.2 + 0.26 * k; count = k; }
    else if (p < 360) { const k = (p - 180) / 180; col = T.blue; a = 0.46 + 0.3 * k; }
    else if (p < 540) {
      const k = (p - 360) / 180;
      col = mixc(T.blue, T.heat, clamp((p - 358) / 40, 0, 1));
      col = mixc(col, T.ink2, 0.7 * clamp((k - 0.35) / 0.65, 0, 1));
      a = 0.78 - 0.3 * k;
    } else { const k = (p - 540) / 180; col = T.ink2; a = 0.3 - 0.14 * k; count = 1 - k; }
    let flame = 0;
    if (p >= 356 && p < 540) flame = clamp((p - 356) / 40, 0, 1) * (1 - 0.75 * clamp((p - 470) / 70, 0, 1));
    const spark = (p >= 348 && p < 374) ? 1 - Math.abs(p - 361) / 13 : 0;
    const push = (p >= 362 && p < 540) ? clamp(1 - (p - 362) / 178, 0, 1) : 0;
    return { col, a, count, flame, spark: Math.max(0, spark), push, burning: p >= 356 && p < 540 };
  }
  const PTS = Array.from({ length: 30 }, (_, i) => {
    const f = v => v - Math.floor(v);
    return [0.1 + 0.8 * f(Math.sin(i * 12.9898) * 43758.5453), 0.1 + 0.8 * f(Math.sin(i * 78.233 + 1) * 43758.5453)];
  });

  /* ---------- line art drawing ---------- */
  const clearPanel = (ctx, W, H) => { ctx.fillStyle = T.panel; ctx.fillRect(0, 0, W, H); };
  // Mono label: uppercase, letter-spaced. Canvas letterSpacing is optional (Chrome/Safari 17+).
  function mono(ctx, txt, x, y, align, base, col) {
    ctx.font = MONO; ctx.textAlign = align || 'left'; ctx.textBaseline = base || 'middle'; ctx.fillStyle = col || T.ink2;
    if ('letterSpacing' in ctx) ctx.letterSpacing = '0.8px';
    ctx.fillText(String(txt).toUpperCase(), x, y);
    if ('letterSpacing' in ctx) ctx.letterSpacing = '0px';
  }
  const monoW = (ctx, txt) => { ctx.font = MONO; if ('letterSpacing' in ctx) ctx.letterSpacing = '0.8px'; const w = ctx.measureText(String(txt).toUpperCase()).width; if ('letterSpacing' in ctx) ctx.letterSpacing = '0px'; return w; };
  // Label with a thin leader line to the part at (ax, ay); (x, y) is the text anchor.
  function leader(ctx, txt, x, y, ax, ay, right) {
    if (!txt) return;
    const tw = monoW(ctx, txt), sx = right ? x - tw - 5 : x + tw + 5;
    ctx.strokeStyle = T.ink2; ctx.lineWidth = 1; ctx.setLineDash([]); ctx.beginPath(); ctx.moveTo(sx, y); ctx.lineTo(ax, ay); ctx.stroke();
    ctx.fillStyle = T.ink2; ctx.beginPath(); ctx.arc(ax, ay, 2, 0, TAU); ctx.fill();
    mono(ctx, txt, x, y, right ? 'right' : 'left', 'middle');
  }
  // Cut surface: panel fill, 45 degree hatching in --rule, ink outline.
  function hatchRect(ctx, x, y, w, hh, gap) {
    ctx.save(); ctx.beginPath(); ctx.rect(x, y, w, hh); ctx.clip();
    ctx.fillStyle = T.panel; ctx.fillRect(x, y, w, hh);
    ctx.strokeStyle = T.rule; ctx.lineWidth = 1; ctx.beginPath();
    for (let k = -hh; k < w; k += gap) { ctx.moveTo(x + k, y + hh); ctx.lineTo(x + k + hh, y); }
    ctx.stroke(); ctx.restore();
    ctx.strokeStyle = T.ink; ctx.lineWidth = LW; ctx.strokeRect(x, y, w, hh);
  }
  // A thick bar with an outline: stroke wide in the line colour, then narrower in the fill colour.
  function bar(ctx, x0, y0, x1, y1, w, line, fill, lw) {
    ctx.lineCap = 'round';
    ctx.strokeStyle = line; ctx.lineWidth = w + 2 * (lw || LW); ctx.beginPath(); ctx.moveTo(x0, y0); ctx.lineTo(x1, y1); ctx.stroke();
    ctx.strokeStyle = fill; ctx.lineWidth = w; ctx.beginPath(); ctx.moveTo(x0, y0); ctx.lineTo(x1, y1); ctx.stroke();
  }
  function disc(ctx, x, y, rr, fill, line, lw) {
    ctx.beginPath(); ctx.arc(x, y, rr, 0, TAU);
    if (fill) { ctx.fillStyle = fill; ctx.fill(); }
    if (line) { ctx.strokeStyle = line; ctx.lineWidth = lw || LW; ctx.stroke(); }
  }
  const ENGINE_LABELS = { tdc: 'TDC', bdc: 'BDC', stroke: 'STROKE', push: 'PUSH', intake: 'INTAKE', exhaust: 'EXHAUST', spark: 'SPARK PLUG' };
  const pw0 = (bore, r) => bore - 0.1 * r;
  function layoutEngine(W, H, head, rod) {
    const up = head ? 8.5 : 6.4, down = 2.0;
    const r = Math.min(H / (up + down + 0.7), W / (head ? 10.6 : 9.6), 46);
    const cy = (H - (up + down) * r) / 2 + up * r;
    return { r, l: (rod || 3.2) * r, cx: W / 2, cy, bore: 4 * r, wall: 0.9 * r, pinToCrown: 0.6 * r, pistonH: 1.3 * r, headY: cy - 5.1 * r };
  }
  // Ignition flash: a solid spark-yellow disc with short rays, k = 0..1. Only ever drawn where a spark happens.
  function sparkFlash(ctx, x, y, rr, k) {
    if (k < 0.03) return;
    ctx.save(); ctx.globalAlpha = Math.min(1, k * 1.4); ctx.fillStyle = T.spark; ctx.strokeStyle = T.spark; ctx.lineWidth = 2; ctx.lineCap = 'round';
    const R = rr * (0.45 + 0.55 * k);
    ctx.beginPath(); ctx.arc(x, y, R * 0.6, 0, TAU); ctx.fill();
    ctx.beginPath();
    for (let i = 0; i < 8; i++) { const a = i * TAU / 8 + 0.4; ctx.moveTo(x + Math.cos(a) * R * 0.85, y + Math.sin(a) * R * 0.85); ctx.lineTo(x + Math.cos(a) * R * 1.5, y + Math.sin(a) * R * 1.5); }
    ctx.stroke(); ctx.restore();
  }
  function arrowDown(ctx, x, y, len, w, col) {
    ctx.fillStyle = col; ctx.beginPath();
    ctx.rect(x - w / 2, y, w, Math.max(0, len - w * 1.1));
    ctx.fill();
    ctx.beginPath(); ctx.moveTo(x - w * 1.1, y + len - w * 1.3); ctx.lineTo(x + w * 1.1, y + len - w * 1.3); ctx.lineTo(x, y + len); ctx.closePath(); ctx.fill();
  }
  // Same arrow with a darker outline (the bold push arrow).
  function pushArrow(ctx, x, y, len, w, col) {
    const hl = w * 1.3, bw = w / 2, hw = w * 1.15, yb = y + len - hl;
    ctx.beginPath(); ctx.moveTo(x - bw, y); ctx.lineTo(x + bw, y); ctx.lineTo(x + bw, yb); ctx.lineTo(x + hw, yb); ctx.lineTo(x, y + len); ctx.lineTo(x - hw, yb); ctx.lineTo(x - bw, yb); ctx.closePath();
    ctx.fillStyle = col; ctx.fill(); ctx.strokeStyle = mixc(col, T.ink, 0.45); ctx.lineWidth = 1.25; ctx.lineJoin = 'round'; ctx.stroke();
  }

  // Single-cylinder cross-section. o: {theta (deg, 0 = TDC), head, gas, intake, exhaust, guides, hint, labels, parts, text, rod,
  // accent: 'piston' | 'crank' (the one moving part drawn in --accent)}
  function drawEngine(ctx, W, H, o) {
    const head = !!o.head, L = layoutEngine(W, H, head, o.rod), tx = o.text || ENGINE_LABELS;
    const { r, l, cx, cy, bore, wall, headY } = L;
    const th = rad(o.theta), xp = pistonX(th, r, l), pinY = cy - xp, crownY = pinY - L.pinToCrown;
    const x0 = cx - bore / 2, x1 = cx + bore / 2;
    const topY = head ? headY - 1.6 * r : headY - 0.9 * r, botY = cy + 1.95 * r;
    const gap = Math.max(5, r * 0.2), g = o.gas;
    const accP = o.accent === 'piston', accC = o.accent === 'crank';
    clearPanel(ctx, W, H);
    ctx.lineJoin = 'round'; ctx.lineCap = 'round';

    // combustion chamber contents: flat tints, blue = fuel/air, heat = burning
    if (head && g) {
      const hh = crownY - headY;
      ctx.fillStyle = rgba(g.col, g.a); ctx.fillRect(x0, headY, bore, hh);
      if (g.flame > 0.01) { ctx.fillStyle = rgba(T.heat, 0.8 * g.flame); ctx.fillRect(x0, headY, bore, hh * clamp(0.35 + 0.65 * g.flame, 0, 1)); }
      const n = Math.round(PTS.length * g.count);
      ctx.fillStyle = rgba(g.burning ? T.heat : g.col, 0.9);
      const pr = Math.max(1.4, r * 0.05), vh = hh - 6;
      for (let i = 0; i < n; i++) { ctx.beginPath(); ctx.arc(x0 + PTS[i][0] * bore, headY + 3 + PTS[i][1] * vh, pr, 0, TAU); ctx.fill(); }
    }

    // block, walls (cut surfaces)
    hatchRect(ctx, x0 - wall, topY, wall, botY - topY, gap);
    hatchRect(ctx, x1, topY, wall, botY - topY, gap);
    hatchRect(ctx, x0 - wall, cy + 1.7 * r, bore + 2 * wall, botY - (cy + 1.7 * r), gap);

    const vxI = cx - 1.25 * r, vxE = cx + 1.25 * r, portY = headY - 1.15 * r;
    if (head) {
      hatchRect(ctx, x0 - wall, headY - 1.6 * r, bore + 2 * wall, 1.6 * r, gap);
      const lI = o.intake || 0, lE = o.exhaust || 0;
      [[vxI, -1, lI, T.blue], [vxE, 1, lE, T.ink2]].forEach(([vx, dir, lf, gc]) => {
        ctx.save();
        ctx.beginPath(); ctx.moveTo(vx, headY - 0.4 * r); ctx.lineTo(vx, headY - 0.7 * r);
        ctx.quadraticCurveTo(vx, portY, vx + dir * 0.5 * r, portY); ctx.lineTo(dir * 9999 + cx, portY);
        ctx.lineCap = 'butt'; ctx.lineWidth = 0.75 * r + 2 * LW; ctx.strokeStyle = T.ink; ctx.stroke();
        ctx.lineWidth = 0.75 * r; ctx.strokeStyle = T.panel; ctx.stroke();
        if (lf > 0.02) { ctx.strokeStyle = rgba(gc, 0.6 * lf); ctx.stroke(); }
        ctx.restore();
        ctx.fillStyle = T.panel; ctx.fillRect(vx - 0.375 * r, headY - 0.5 * r, 0.75 * r, 0.5 * r);
        if (lf > 0.02) { ctx.fillStyle = rgba(gc, 0.6 * lf); ctx.fillRect(vx - 0.375 * r, headY - 0.5 * r, 0.75 * r, 0.5 * r + 1); }
      });
      // valves: stem, spring, cap, head
      [[vxI, lI], [vxE, lE]].forEach(([vx, lf]) => {
        const ly = headY + lf * 0.55 * r, capY = headY - 2.4 * r + lf * 0.55 * r;
        ctx.lineCap = 'butt'; ctx.strokeStyle = T.ink; ctx.lineWidth = LW2;
        ctx.beginPath(); ctx.moveTo(vx, capY); ctx.lineTo(vx, ly); ctx.stroke();
        ctx.strokeStyle = T.ink2; ctx.lineWidth = LW; ctx.beginPath();
        const sTop = capY, sBot = headY - 1.6 * r, steps = 6;
        ctx.moveTo(vx, sTop);
        for (let i = 1; i <= steps; i++) ctx.lineTo(vx + (i % 2 ? 0.32 : -0.32) * r, sTop + (sBot - sTop) * i / steps);
        ctx.lineTo(vx, sBot); ctx.stroke();
        ctx.fillStyle = T.panel; ctx.strokeStyle = T.ink; ctx.lineWidth = LW;
        ctx.fillRect(vx - 0.3 * r, capY - 0.1 * r, 0.6 * r, 0.14 * r); ctx.strokeRect(vx - 0.3 * r, capY - 0.1 * r, 0.6 * r, 0.14 * r);
        ctx.beginPath(); ctx.moveTo(vx - 0.4 * r, ly - 0.18 * r); ctx.lineTo(vx + 0.4 * r, ly - 0.18 * r);
        ctx.lineTo(vx + 0.52 * r, ly); ctx.lineTo(vx - 0.52 * r, ly); ctx.closePath(); ctx.fill(); ctx.stroke();
      });
      // spark plug
      ctx.fillStyle = T.panel; ctx.strokeStyle = T.ink; ctx.lineWidth = LW;
      ctx.fillRect(cx - 0.27 * r, headY - 2.25 * r, 0.54 * r, 0.7 * r); ctx.strokeRect(cx - 0.27 * r, headY - 2.25 * r, 0.54 * r, 0.7 * r);
      ctx.fillRect(cx - 0.45 * r, headY - 1.85 * r, 0.9 * r, 0.25 * r); ctx.strokeRect(cx - 0.45 * r, headY - 1.85 * r, 0.9 * r, 0.25 * r);
      ctx.strokeStyle = T.ink; ctx.lineWidth = LW2; ctx.lineCap = 'butt';
      ctx.beginPath(); ctx.moveTo(cx, headY - 1.6 * r); ctx.lineTo(cx, headY + 0.32 * r); ctx.stroke();
      ctx.lineWidth = LW; ctx.beginPath(); ctx.moveTo(cx - 0.4 * r, headY); ctx.lineTo(cx - 0.4 * r, headY + 0.32 * r); ctx.lineTo(cx - 0.1 * r, headY + 0.32 * r); ctx.stroke();
      if (g && g.spark > 0.05) {
        sparkFlash(ctx, cx - 0.25 * r, headY + 0.4 * r, 0.9 * r, g.spark);
      }
    }

    // TDC / BDC guides
    const crownTDC = cy - (r + l) - L.pinToCrown;
    if (o.guides) {
      ctx.save(); ctx.setLineDash([5, 4]); ctx.strokeStyle = T.ink2; ctx.lineWidth = 1; ctx.beginPath();
      [crownTDC, crownTDC + 2 * r].forEach(y => { ctx.moveTo(x0, y); ctx.lineTo(x1 + wall + 10, y); });
      ctx.stroke(); ctx.restore();
      mono(ctx, tx.tdc, x1 + wall + 12, crownTDC, 'left'); mono(ctx, tx.bdc, x1 + wall + 12, crownTDC + 2 * r, 'left');
    }

    // crank circle, counterweight, crank arm
    const px = cx + r * Math.sin(th), py = cy - r * Math.cos(th);
    const cwx = cx - 0.95 * r * Math.sin(th), cwy = cy + 0.95 * r * Math.cos(th);
    ctx.setLineDash([]);
    ctx.strokeStyle = T.rule; ctx.lineWidth = 1; ctx.beginPath(); ctx.arc(cx, cy, r, 0, TAU); ctx.stroke();
    disc(ctx, cwx, cwy, 0.7 * r, T.panel, T.ink, LW);
    bar(ctx, cx, cy, px, py, 0.56 * r, accC ? T.accent : T.ink, accC ? tint(T.accent, 0.28) : T.panel, accC ? LW2 : LW);

    // connecting rod
    bar(ctx, cx, pinY, px, py, 0.3 * r, T.ink, T.panel, LW);
    disc(ctx, px, py, 0.42 * r, accC ? tint(T.accent, 0.28) : T.panel, accC ? T.accent : T.ink, accC ? LW2 : LW);
    disc(ctx, px, py, 0.14 * r, T.ink2);
    disc(ctx, cx, cy, 0.34 * r, T.panel, T.ink, LW);

    // piston
    const pw = bore - 0.1 * r;
    ctx.fillStyle = accP ? tint(T.accent, 0.28) : T.panel; ctx.strokeStyle = accP ? T.accent : T.ink; ctx.lineWidth = accP ? LW2 : LW;
    ctx.fillRect(cx - pw / 2, crownY, pw, L.pistonH); ctx.strokeRect(cx - pw / 2, crownY, pw, L.pistonH);
    ctx.strokeStyle = T.ink; ctx.lineWidth = LW; ctx.beginPath();
    [0.3, 0.5].forEach(k => { ctx.moveTo(cx - pw / 2, crownY + k * r); ctx.lineTo(cx + pw / 2, crownY + k * r); });
    ctx.stroke();
    disc(ctx, cx, pinY, 0.2 * r, T.panel, T.ink, LW);

    // push arrow (power stroke)
    if (g && g.push > 0.02) {
      const ax = x0 - wall - 0.55 * r;
      pushArrow(ctx, ax, crownY - 0.3 * r, (0.8 + 1.8 * g.push) * r, 0.34 * r, T.heat);
      mono(ctx, tx.push, ax - 0.6 * r, crownY + 0.3 * r, 'right', 'middle', T.ink);
    }

    // drag hint ring on the crank pin (the thing to grab)
    if (o.hint) {
      const pulse = 0.5 + 0.5 * Math.sin(performance.now() / 350);
      ctx.save(); ctx.setLineDash([4, 4]); ctx.strokeStyle = T.accent; ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.arc(px, py, 0.75 * r + pulse * 4, 0, TAU); ctx.stroke(); ctx.restore();
    }

    // plain-word part labels (o.parts = {piston, rod, crank, cylinder}) with leader lines
    if (o.parts) {
      const pt = o.parts;
      leader(ctx, pt.cylinder, W - 8, headY + 0.2 * r, x1 + wall * 0.5, headY + 0.2 * r, true);
      leader(ctx, pt.piston, 8, cy - 3.6 * r, cx - pw0(bore, r) / 2, crownY + L.pistonH * 0.5, false);
      leader(ctx, pt.rod, W - 8, cy - 1.7 * r, (cx + px) / 2, (pinY + py) / 2, true);
      leader(ctx, pt.crank, W - 8, cy + 1.05 * r, cx + 0.34 * r, cy, true);
    }
    // port and plug labels
    if (head && o.labels) {
      if (tx.intake) mono(ctx, tx.intake, 8, portY - 0.55 * r, 'left', 'bottom');
      if (tx.exhaust) mono(ctx, tx.exhaust, W - 8, portY - 0.55 * r, 'right', 'bottom');
      if (tx.spark) mono(ctx, tx.spark, cx, headY - 2.4 * r - 3, 'center', 'bottom');
    }
    return { px, py, cx, cy, r, bore, xp, L };
  }

  /* ---------- canvas component and sim loop ---------- */
  // Each built topic owns a scope: its sims and ResizeObservers, torn down together by api.destroy().
  const allSims = new Set();
  let scope = null, building = null;   // building: the topic data being rendered (for `more`)
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
    const ro = new ResizeObserver(fit); ro.observe(host); scope.ros.push(ro);
    fit();
    return o;
  }
  function addSim(card, sim) {
    sim.visible = false; sim.playing = false;
    scope.sims.push(sim); allSims.add(sim);
    (card.__sims = card.__sims || []).push(sim);
    return sim;
  }
  let last = performance.now(), raf = 0;
  function loop(t) {
    const dt = Math.min(0.05, (t - last) / 1000); last = t;
    for (const s of allSims) {
      if (!s.visible) continue;
      const was = s.playing;
      if (was) s.update(dt);
      if (was || s.playing || s.alwaysDraw) s.draw();
    }
    raf = requestAnimationFrame(loop);
  }
  function redrawAll() { allSims.forEach(s => s.draw && s.draw()); }
  // Shared services (the one rAF loop, theme listeners) are reference counted: every built topic holds one.
  let holds = 0, mqDark = null, mqHandler = null, themeMO = null;
  function retain() {
    if (holds++) return;
    readTheme();
    mqDark = window.matchMedia('(prefers-color-scheme: dark)');
    mqHandler = () => { readTheme(); redrawAll(); };
    mqDark.addEventListener('change', mqHandler);
    themeMO = new MutationObserver(mqHandler);
    themeMO.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(redrawAll);
    last = performance.now();
    raf = requestAnimationFrame(loop);
  }
  function release() {
    if (!holds || --holds) return;
    cancelAnimationFrame(raf); raf = 0;
    mqDark.removeEventListener('change', mqHandler); mqDark = mqHandler = null;
    themeMO.disconnect(); themeMO = null;
  }

  /* ---------- shared visual controls ---------- */
  let lastDrag = 0; // the feed ignores the tap that ends a drag
  // Interaction cue: a small pill on the picture's bottom edge ("Drag the crank"). It fades in shortly after the card is shown, goes after a few
  // seconds or on the first touch, and stays away for the rest of the session once the reader has used any visual by hand.
  let learned = false;
  function cue(panel, sim, text) {
    if (!text) return;
    const el = h('div', { class: 'cue', 'aria-hidden': 'true' }, h('i', { class: 'cue-ico' }), text);
    panel.append(el);
    let t1 = 0, t2 = 0;
    sim.cueHide = () => { clearTimeout(t1); clearTimeout(t2); el.classList.remove('on'); };
    sim.cueShow = () => {
      sim.cueHide();
      if (learned || sim.touched) return;
      t1 = setTimeout(() => el.classList.add('on'), 700);
      t2 = setTimeout(sim.cueHide, 6200);
    };
  }
  const tipOf = (c, dflt) => c.tip === undefined ? dflt : c.tip;
  // Small mono text link in the panel corner: Play / Pause (Step under reduced motion).
  function playLink(panel, sim, step) {
    const b = h('button', { class: 'pctl tr', type: 'button' });
    sim.syncUI = () => {
      const rm = reducedMQ.matches;
      b.textContent = rm ? UI.step : sim.playing ? UI.pause : UI.play;
      b.setAttribute('aria-label', rm ? UI.stepAria : sim.playing ? UI.pauseAria : UI.playAria);
    };
    b.addEventListener('click', () => {
      sim.touched = true; sim.cueHide && sim.cueHide();
      if (reducedMQ.matches) step(); else sim.playing = !sim.playing;
      sim.syncUI(); sim.draw();
    });
    sim.syncUI(); panel.append(b);
  }
  function autoplay(sim) { if (!reducedMQ.matches && !sim.touched) { sim.playing = true; sim.syncUI && sim.syncUI(); } }
  // A drag that starts on a hit target belongs to the visual: touchstart is cancelled only then, so the feed still pans elsewhere.
  function attachDrag(cv, sim, o) {
    let dragging = false, was = false;
    cv.addEventListener('touchstart', e => { if (o.hit(e.touches[0])) e.preventDefault(); }, { passive: false });
    cv.addEventListener('touchmove', e => { if (dragging) e.preventDefault(); }, { passive: false });
    cv.addEventListener('pointerdown', e => {
      if (!o.hit(e)) return;
      dragging = true; was = sim.playing; sim.playing = false; sim.touched = true; sim.hintOn = false; learned = true; sim.cueHide && sim.cueHide(); sim.syncUI && sim.syncUI();
      o.start(e); cv.setPointerCapture(e.pointerId); cv.classList.add('grabbing');
    });
    cv.addEventListener('pointermove', e => {
      if (!dragging) { cv.classList.toggle('grab', o.hit(e)); return; }
      o.move(e); lastDrag = performance.now(); sim.draw();
    });
    const end = () => {
      if (dragging) { lastDrag = performance.now(); if (o.resume && was) { sim.playing = true; sim.syncUI && sim.syncUI(); } }
      dragging = false; cv.classList.remove('grabbing');
    };
    cv.addEventListener('pointerup', end); cv.addEventListener('pointercancel', end);
  }
  const relPos = (cv, e) => { const rc = cv.getBoundingClientRect(); return [e.clientX - rc.left, e.clientY - rc.top]; };

  /* ---------- visual types ---------- */
  const V = {};

  // crank: slider-crank (piston, rod, crank). interactive (default true) = drag the crank pin; false = quiet ambient spin.
  const CRANK_LABELS = Object.assign({}, ENGINE_LABELS, { partPiston: 'PISTON', partRod: 'ROD', partCrank: 'CRANKSHAFT', partCylinder: 'CYLINDER' });
  V.crank = function (panel, c, card) {
    const P = Object.assign({ rodRatio: 3.2, speed: 50, start: 40, interactive: true, parts: false, guides: false }, c);
    const LB = Object.assign({}, CRANK_LABELS, c.labels);
    let theta = P.start, geom = null, lastA = 0, sim;
    const cv = makeCanvas(panel, () => sim && sim.draw());
    sim = addSim(card, {
      hintOn: P.interactive && P.hint !== false,
      update(dt) { theta = wrap360(theta + P.speed * dt); },
      draw() {
        if (!cv.w) return;
        geom = drawEngine(cv.ctx, cv.w, cv.h, { theta: wrap360(theta), head: false, guides: P.guides, hint: sim.hintOn, text: LB, rod: P.rodRatio,
          accent: P.interactive ? 'crank' : 'piston',
          parts: P.parts ? { piston: LB.partPiston, rod: LB.partRod, crank: LB.partCrank, cylinder: LB.partCylinder } : null });
      },
      onShow() { autoplay(sim); }
    });
    sim.alwaysDraw = sim.hintOn; // keeps the hint ring pulsing while visible
    if (P.interactive) {
      playLink(panel, sim, () => { theta = wrap360(theta + 45); });
      cue(panel, sim, tipOf(c, UI.tips.crank));
      const angleAt = e => { const [x, y] = relPos(cv.cv, e); return Math.atan2(x - geom.cx, -(y - geom.cy)) * 180 / Math.PI; };
      attachDrag(cv.cv, sim, {
        hit(e) {
          if (!geom) return false;
          const [x, y] = relPos(cv.cv, e);
          return Math.hypot(x - geom.cx, y - geom.cy) < geom.r * 2.7 || (Math.abs(x - geom.cx) < geom.bore / 2 + geom.r && y > geom.cy - geom.r * 6.2 && y < geom.cy);
        },
        start(e) { lastA = angleAt(e); sim.alwaysDraw = false; },
        move(e) { const a = angleAt(e); let d = a - lastA; if (d > 180) d -= 360; if (d < -180) d += 360; theta = wrap360(theta + d); lastA = a; }
      });
    }
  };

  // strokes: the four-stroke cycle in a cylinder. params.only = 0..3 loops a single stroke. Drag the crank pin to scrub.
  const STROKE_NAMES = ['Intake', 'Compression', 'Power', 'Exhaust'];
  V.strokes = function (panel, c, card) {
    const P = Object.assign({ intake: [0, 190], exhaust: [530, 720], ramp: 25, speed: 80, start: 440, interactive: true, strokes: STROKE_NAMES }, c);
    const LB = Object.assign({}, ENGINE_LABELS, c.labels);
    const names = P.strokes.map(s => typeof s === 'string' ? s : s.name);
    const ONLY = P.only != null ? clamp(Math.round(P.only), 0, 3) : null, LO = ONLY == null ? 0 : ONLY * 180;
    if (ONLY != null && c.start == null) P.start = LO + 70;
    let phi = P.start, geom = null, lastA = 0, sim;
    const norm = p => ONLY == null ? wrap720(p) : LO + ((((p - LO) % 180) + 180) % 180);
    const cv = makeCanvas(panel, () => sim && sim.draw());
    sim = addSim(card, {
      update(dt) { phi = norm(phi + P.speed * dt); },
      draw() {
        if (!cv.w) return;
        geom = drawEngine(cv.ctx, cv.w, cv.h, { theta: wrap360(phi), head: true, gas: gasAt(phi), labels: P.labels !== false, text: LB, rod: P.rodRatio, accent: 'piston',
          intake: lift(phi, P.intake, P.ramp), exhaust: lift(phi, P.exhaust, P.ramp) });
        const si = Math.floor(phi / 180) % 4;
        mono(cv.ctx, (si + 1) + '/4  ' + names[si], 10, 16, 'left', 'middle', T.ink);
      },
      onShow() { autoplay(sim); }
    });
    playLink(panel, sim, () => { phi = norm(phi + 45); });
    if (P.interactive) {
      cue(panel, sim, tipOf(c, UI.tips.strokes));
      const angleAt = e => { const [x, y] = relPos(cv.cv, e); return Math.atan2(x - geom.cx, -(y - geom.cy)) * 180 / Math.PI; };
      attachDrag(cv.cv, sim, {
        hit(e) { if (!geom) return false; const [x, y] = relPos(cv.cv, e); return Math.hypot(x - geom.cx, y - geom.cy) < geom.r * 2.7; },
        start(e) { lastA = angleAt(e); },
        move(e) { const a = angleAt(e); let d = a - lastA; if (d > 180) d -= 360; if (d < -180) d += 360; phi = norm(phi + d); lastA = a; }
      });
    }
  };

  /* torque model for the cylinders visual (one cylinder, relative units) */
  function makeTQ(rod) {
    const r = 1, l = rod, Vc = 2 * r / 8;
    const x = th => pistonX(th, r, l);
    const dx = th => (x(th + 1e-4) - x(th - 1e-4)) / 2e-4;
    const ss = (a, b, v) => { const k = clamp((v - a) / (b - a), 0, 1); return k * k * (3 - 2 * k); };
    const f = pc => {
      if (pc < 360 || pc >= 540) return 0;
      const th = rad(pc - 360), Vv = Vc + (x(0) - x(th));
      return ss(0, 12, pc - 360) * Math.pow(Vc / Vv, 1.3) * (-dx(th));
    };
    let pk = 0; for (let p = 360; p < 540; p += 0.5) pk = Math.max(pk, f(p));
    return { f, pk };
  }

  // cylinders: pick a cylinder count; cylinders fire in order; a graph shows the push on the crankshaft.
  // params: options [{n, order:[..]}], selected, speed, rodRatio, graph (default true), hide ['segs','play'], labels
  const CYL_LABELS = { unit: 'cylinders', graphTitle: 'Push on the crankshaft', average: 'Average' };
  V.cylinders = function (panel, c, card) {
    const P = Object.assign({ speed: 120, selected: 0, rodRatio: 3.2, graph: true }, c);
    const LB = Object.assign({}, CYL_LABELS, c.labels);
    const HIDE = new Set(P.hide || []), graphOn = P.graph !== false && !HIDE.has('graph');
    const opts = c.options, TQ = makeTQ(P.rodRatio);
    let optI = Math.min(P.selected, opts.length - 1), s = 0, peakAbs = TQ.pk, sim;
    const total = (N, order, sx) => {
      let sum = 0;
      for (let ci = 0; ci < N; ci++) sum += TQ.f(wrap720(sx - order.indexOf(ci + 1) * 720 / N + 360));
      return sum / N;
    };
    function computePeak() { const o = opts[optI]; let mx = 0; for (let a = 0; a < 720; a++) mx = Math.max(mx, total(o.n, o.order, a)); peakAbs = mx; }
    computePeak();
    const cv = makeCanvas(panel, () => sim && sim.draw());
    sim = addSim(card, {
      update(dt) { s += P.speed * dt; },
      draw() {
        if (!cv.w) return;
        const ctx = cv.ctx, W = cv.w, H = cv.h, o = opts[optI], N = o.n, solo = !graphOn;
        clearPanel(ctx, W, H);
        const Hb = solo ? H - 6 : Math.round(H * 0.5), pad = 12, slot = (W - 2 * pad) / N;
        const b = Math.min(slot * (solo ? 0.8 : 0.66), solo ? 96 : 84), r = Math.min(b * (solo ? 0.36 : 0.3), (Hb - 30) / 6.4), l = 3 * r;
        const cyC = Hb - r - 6, sp = wrap720(s);
        ctx.save();
        if (solo) ctx.translate(0, -Math.max(0, (Hb - 6 - (6.4 * r + 26)) / 2));
        ctx.lineCap = 'round'; ctx.lineJoin = 'round';
        const firstX = pad + slot / 2, lastX = pad + slot * (N - 0.5);
        ctx.strokeStyle = T.ink; ctx.lineWidth = LW2; ctx.beginPath();
        ctx.moveTo(Math.max(0, firstX - slot * 0.4), cyC); ctx.lineTo(Math.min(W, lastX + slot * 0.4), cyC); ctx.stroke();
        for (let i = 0; i < N; i++) {
          const cx = pad + slot * (i + 0.5), fire = o.order.indexOf(i + 1) * 720 / N;
          const pc = wrap720(sp - fire + 360), th = rad(wrap360(pc));
          const g = gasAt(pc), xp = pistonX(th, r, l), pinY = cyC - xp, crownY = pinY - 0.55 * r;
          const headY = cyC - (r + l) - 0.55 * r - 0.25 * r;
          const x0 = cx - b / 2, x1 = cx + b / 2;
          ctx.fillStyle = rgba(g.col, g.a); ctx.fillRect(x0, headY, b, crownY - headY);
          if (g.flame > 0.05) { ctx.fillStyle = rgba(T.heat, 0.8 * g.flame); ctx.fillRect(x0, headY, b, Math.min(crownY - headY, b * 0.5)); }
          sparkFlash(ctx, cx, headY + 0.35 * r + 3, 0.9 * r, g.spark);
          ctx.strokeStyle = T.ink; ctx.lineWidth = LW; ctx.beginPath();
          ctx.moveTo(x0, headY); ctx.lineTo(x0, cyC - 1.25 * r); ctx.moveTo(x1, headY); ctx.lineTo(x1, cyC - 1.25 * r); ctx.stroke();
          ctx.lineWidth = LW2; ctx.beginPath(); ctx.moveTo(x0 - 2, headY); ctx.lineTo(x1 + 2, headY); ctx.stroke();
          const px = cx + r * Math.sin(th), py = cyC - r * Math.cos(th);
          ctx.strokeStyle = T.rule; ctx.lineWidth = 1; ctx.beginPath(); ctx.arc(cx, cyC, r, 0, TAU); ctx.stroke();
          bar(ctx, cx, pinY, px, py, Math.max(2, r * 0.22), T.ink, T.panel, LW);
          bar(ctx, cx, cyC, px, py, Math.max(3, r * 0.36), T.ink, T.panel, LW);
          disc(ctx, px, py, Math.max(2.5, r * 0.22), T.ink2);
          const pw = b - 3;
          ctx.fillStyle = tint(T.accent, 0.28); ctx.strokeStyle = T.accent; ctx.lineWidth = LW2;
          ctx.fillRect(cx - pw / 2, crownY, pw, 1.1 * r); ctx.strokeRect(cx - pw / 2, crownY, pw, 1.1 * r);
          if (N > 1) mono(ctx, String(i + 1), cx, headY - 8, 'center', 'bottom');
        }
        ctx.restore();
        if (solo) return;
        // push graph
        const gx0 = 12, gx1 = W - 12, gy0 = Hb + 26, gy1 = H - 14, gw = gx1 - gx0, gh = gy1 - gy0 - 4;
        mono(ctx, LB.graphTitle, gx0, gy0 - 12, 'left', 'middle');
        ctx.strokeStyle = T.ink2; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(gx0, gy1 + 0.5); ctx.lineTo(gx1, gy1 + 0.5); ctx.stroke();
        const ymax = peakAbs * 1.12, samples = 160, startS = s - 720;
        const Y = v => gy1 - clamp(v / ymax, 0, 1) * gh;
        ctx.beginPath(); ctx.moveTo(gx0, gy1);
        for (let i = 0; i <= samples; i++) ctx.lineTo(gx0 + gw * i / samples, Y(total(N, o.order, startS + 720 * i / samples)));
        ctx.lineTo(gx1, gy1); ctx.closePath(); ctx.fillStyle = rgba(T.heat, 0.34); ctx.fill();
        ctx.beginPath();
        for (let i = 0; i <= samples; i++) { const x = gx0 + gw * i / samples, y = Y(total(N, o.order, startS + 720 * i / samples)); i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
        ctx.strokeStyle = T.heat; ctx.lineWidth = LW2; ctx.stroke();
        let tot = 0; for (let a = 0; a < 720; a += 2) tot += total(N, o.order, a);
        const avg = tot / 360;
        ctx.save(); ctx.setLineDash([5, 4]); ctx.strokeStyle = T.ink2; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(gx0, Y(avg)); ctx.lineTo(gx1, Y(avg)); ctx.stroke(); ctx.restore();
        mono(ctx, LB.average, gx1 - 2, Y(avg) - 7, 'right', 'middle');
      },
      onShow() { autoplay(sim); }
    });
    if (!HIDE.has('play')) playLink(panel, sim, () => { s += 90; });
    if (!HIDE.has('segs') && opts.length > 1) {
      cue(panel, sim, tipOf(c, UI.tips.cylinders));
      const btns = opts.map((o, i) => h('button', { class: 'pbtn', type: 'button', 'aria-pressed': String(i === optI), 'aria-label': o.n + ' ' + LB.unit, text: String(o.n),
        onclick: () => { optI = i; btns.forEach((b, k) => b.setAttribute('aria-pressed', String(k === optI))); computePeak(); sim.draw(); } }));
      panel.append(h('div', { class: 'psel tl', role: 'group', 'aria-label': LB.unit }, h('span', { class: 'plab', 'aria-hidden': 'true', text: LB.unit }), btns));
    }
    if (reducedMQ.matches) s = 380; // static frame: a power stroke is under way
  };

  /* ---------- gears: a meshing spur-gear pair with real involute teeth ---------- */
  const GEAR_LABELS = { driver: 'Driver', driven: 'Driven', teeth: '{n} teeth', gear: 'Gear {n}', laps: 'Laps' };
  const INV20 = Math.tan(rad(20)) - rad(20);
  // Closed gear outline (module m). Standard 20 degree involute, addendum 1m, dedendum 1.25m.
  function gearOutline(ctx, cx, cy, N, m, phase) {
    const rp = m * N / 2, rb = rp * Math.cos(rad(20)), ro = rp + m, rr = rp - 1.25 * m, p = TAU / N;
    const back = 0.03 * m / rp; // a little backlash so drawn teeth never overlap
    const half = r => Math.PI / (2 * N) + INV20 - (() => { const a = Math.acos(Math.min(1, rb / r)); return Math.tan(a) - a; })() - back;
    const r0 = Math.max(rb, rr), STEPS = 5;
    const P = (r, a) => [cx + r * Math.cos(a), cy + r * Math.sin(a)];
    ctx.beginPath();
    for (let k = 0; k < N; k++) {
      const c = phase + k * p, pts = [];
      if (rr < rb) pts.push(P(rr, c - half(rb)));
      for (let i = 0; i <= STEPS; i++) { const r = r0 + (ro - r0) * i / STEPS; pts.push(P(r, c - half(r))); }
      for (let i = STEPS; i >= 0; i--) { const r = r0 + (ro - r0) * i / STEPS; pts.push(P(r, c + half(r))); }
      if (rr < rb) pts.push(P(rr, c + half(rb)));
      pts.forEach((q, i) => { if (k === 0 && i === 0) ctx.moveTo(q[0], q[1]); else ctx.lineTo(q[0], q[1]); });
    }
    ctx.closePath();
    return { rp, ro, rr };
  }
  // params: driving, driven (teeth), speed (driver turns/s), phase; or sets [{label, gears:[{name, driving, driven}], spin, rpmStart}] with set/selected;
  // interactive (drag the driver gear, default false = ambient); labels {driver, driven, teeth, laps} turns on the labelled version;
  // count: true adds a LAPS counter under each gear (full turns since the card was shown; both reset to 0 after the slower gear laps + a hold).
  V.gears = function (panel, c, card) {
    const P = Object.assign({ driving: 14, driven: 50, speed: c.count ? 0.36 : 0.08, phase: 0.6, interactive: false, set: 0, selected: 0 }, c);   // count: one driver lap ~2.8 s unless speed is given
    const LB = Object.assign({}, GEAR_LABELS, c.labels);
    const sets = c.sets, showLabels = !!c.labels;
    let si = sets ? Math.min(P.set, sets.length - 1) : 0, gi = sets ? Math.min(P.selected, sets[si].gears.length - 1) : 0;
    let ang = P.phase, geom = null, lastA = 0, sim;
    // Lap counters: driver travel since ang0 (never negative), floor to whole turns. When the slower gear completes a lap both freeze
    // (highlighted, fading over HL ms), then after HOLD ms both reset to 0, so a 12 -> 36 pair reads 3 : 1 forever.
    const CNT = !!c.count, HL = 800, HOLD = 1200;
    let ang0 = ang, hold = null;
    const resetCount = () => { ang0 = ang; hold = null; };
    const lapsNow = (N1, N2) => {
      const now = performance.now();
      if (hold && now - hold.t >= HOLD) resetCount();
      if (!hold) {
        const turns = Math.max(0, ang - ang0) / TAU, d = Math.floor(turns + 1e-9), n = Math.floor(turns * N1 / N2 + 1e-9);
        if (d >= 1 && n >= 1) hold = { t: now, d, n }; else return { d, n, hl: 0 };
      }
      return { d: hold.d, n: hold.n, hl: reducedMQ.matches ? 1 : 1 - easeIO(clamp((now - hold.t) / HL, 0, 1)) };
    };
    const cur = () => sets ? sets[si].gears[gi] : { driving: P.driving, driven: P.driven };
    const speedNow = () => sets ? clamp((sets[si].spin || 0.2) * ((sets[si].rpmStart || 1500) / 1000), 0.03, 0.3) : P.speed;
    const cv = makeCanvas(panel, () => sim && sim.draw());
    sim = addSim(card, {
      update(dt) { ang += TAU * speedNow() * dt; },
      draw() {
        if (!cv.w) return;
        const ctx = cv.ctx, W = cv.w, H = cv.h, g = cur(), N1 = g.driving, N2 = g.driven;
        clearPanel(ctx, W, H);
        let mN1 = N1, mN2 = N2, mD = (N1 + N2) / 2;   // size from the largest gears in the set so shafts stay put when the gear changes
        if (sets) sets[si].gears.forEach(q => { mN1 = Math.max(mN1, q.driving); mN2 = Math.max(mN2, q.driven); mD = Math.max(mD, (q.driving + q.driven) / 2); });
        // Labels sit under the gears: name over the teeth count (second line only when `teeth` is set). Measured so they never overlap:
        // pushed apart when the gear centres are close, and on very narrow panels the right one drops to its own row.
        const ls = showLabels ? [[LB.driver, N1], [LB.driven, N2]].map(([nm, n]) => { const tt = LB.teeth ? fmt(LB.teeth, { n }) : ''; return { nm, tt, w: Math.max(monoW(ctx, nm), tt ? monoW(ctx, tt) : 0), w1: monoW(ctx, nm + (tt ? '  ' + tt : '')) }; }) : [];
        if (CNT && showLabels) ls.forEach((q, k) => { q.ct = LB.laps + ' ' + (k ? 1 : Math.max(1, Math.ceil(N2 / N1))); q.cw = monoW(ctx, q.ct); q.w = Math.max(q.w, q.cw); q.w1 = Math.max(q.w1, q.cw); });   // widest reading, so layout never jumps
        const cn = CNT && showLabels, lp = cn ? lapsNow(N1, N2) : null;
        const stag = showLabels && ls[0].w1 + ls[1].w1 + 12 > W - 16, two = showLabels && !stag && ls.some(q => q.tt);
        const left = mN1 / 2 + 1, right = mN2 / 2 + 1, total = left + mD + right, pad = 14, lab = !showLabels ? 0 : (stag ? 52 + (cn ? 26 : 0) : (two ? 46 : 34) + (cn ? 13 : 0));
        const m = Math.min((W - 2 * pad) / total, (H - 2 * pad - lab) / (Math.max(mN1, mN2) + 2), 8);
        const x0 = (W - m * total) / 2 + m * left, cy = (H - lab) / 2, x1 = x0 + m * (N1 + N2) / 2;
        const ph1 = ang, ph2 = Math.PI + Math.PI / N2 - (N1 / N2) * ang;   // exact mesh
        const drawGear = (cx, N, phase, driver) => {
          const o = gearOutline(ctx, cx, cy, N, m, phase), col = driver ? T.accent : T.ink;
          ctx.fillStyle = tint(driver ? T.accent : T.blue, 0.24); ctx.fill(); ctx.strokeStyle = col; ctx.lineWidth = driver ? LW2 : LW; ctx.lineJoin = 'round'; ctx.stroke();
          // marked tooth, to count turns by
          ctx.save(); ctx.beginPath(); ctx.arc(cx, cy, o.ro + 2, phase - Math.PI / N, phase + Math.PI / N); ctx.arc(cx, cy, o.rr + 1, phase + Math.PI / N, phase - Math.PI / N, true); ctx.closePath();
          ctx.clip(); gearOutline(ctx, cx, cy, N, m, phase); ctx.fillStyle = col; ctx.fill(); ctx.restore();
          ctx.strokeStyle = T.ink2; ctx.lineWidth = LW; ctx.lineCap = 'round'; ctx.beginPath();
          for (let k = 0; k < 4; k++) { const a = phase + k * Math.PI / 2 + Math.PI / N; ctx.moveTo(cx + Math.cos(a) * o.rr * 0.28, cy + Math.sin(a) * o.rr * 0.28); ctx.lineTo(cx + Math.cos(a) * o.rr * 0.6, cy + Math.sin(a) * o.rr * 0.6); }
          ctx.stroke();
          disc(ctx, cx, cy, Math.max(4, o.rr * 0.2), T.panel, T.ink, LW);
          return o;
        };
        const o2 = drawGear(x1, N2, ph2, false), o1 = drawGear(x0, N1, ph1, true);
        geom = { x0, cy, ro: o1.ro };
        if (showLabels) {
          const cs = [x0, x1], os = [o1, o2], lc = cs.slice();
          if (!stag) {
            const dmin = (ls[0].w + ls[1].w) / 2 + 12;
            if (lc[1] - lc[0] < dmin) { const mid = (lc[0] + lc[1]) / 2; lc[0] = mid - dmin / 2; lc[1] = mid + dmin / 2; }
            const sh = Math.max(0, ls[0].w / 2 + 8 - lc[0]) - Math.max(0, lc[1] + ls[1].w / 2 + 8 - W);
            lc[0] += sh; lc[1] += sh;
          }
          ls.forEach((q, k) => {
            const w = stag ? q.w1 : q.w, c0 = stag ? clamp(cs[k], w / 2 + 8, W - w / 2 - 8) : lc[k];
            const row = H - (stag ? (cn ? (k ? 29 : 59) : (k ? 12 : 29)) : (two ? 28 : 16) + (cn ? 13 : 0)), top = row - 8;
            const ex = clamp(cs[k], c0 - w / 2 + 4, c0 + w / 2 - 4);
            ctx.strokeStyle = T.ink2; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(cs[k], cy + os[k].ro + 3); ctx.lineTo(ex, top); ctx.stroke();
            if (stag || !q.tt) mono(ctx, stag ? q.nm + (q.tt ? '  ' + q.tt : '') : q.nm, c0, row, 'center', 'middle');
            else { mono(ctx, q.nm, c0, row, 'center', 'middle'); mono(ctx, q.tt, c0, row + 13, 'center', 'middle'); }
            if (cn) mono(ctx, LB.laps + ' ' + (k ? lp.n : lp.d), c0, row + (stag ? 13 : two ? 26 : 13), 'center', 'middle', mixc(T.ink2, T.accent, lp.hl));
          });
        }
      },
      onShow() { resetCount(); autoplay(sim); }
    });
    if (P.interactive) {
      playLink(panel, sim, () => { ang += CNT ? Math.PI / 2 : 0.5; });
      cue(panel, sim, tipOf(c, UI.tips.gears));
      const angleAt = e => { const [x, y] = relPos(cv.cv, e); return Math.atan2(y - geom.cy, x - geom.x0); };
      attachDrag(cv.cv, sim, {
        resume: true,
        hit(e) { if (!geom) return false; const [x, y] = relPos(cv.cv, e); return Math.hypot(x - geom.x0, y - geom.cy) < geom.ro + 10; },
        start(e) { lastA = angleAt(e); },
        move(e) { const a = angleAt(e); let d = a - lastA; if (d > Math.PI) d -= TAU; if (d < -Math.PI) d += TAU; ang += d; lastA = a; }
      });
    }
    if (P.interactive && sets && (sets[si].gears.length > 1 || sets.length > 1)) {   // a fixed (non-interactive) figure just shows the given set
      const mk = () => {
        const g = sets[si].gears;
        return [
          sets.length > 1 ? sets.map((q, i) => h('button', { class: 'pbtn', type: 'button', 'aria-pressed': String(i === si), text: q.label || String(i + 1), onclick: () => { si = i; gi = Math.min(P.selected, sets[si].gears.length - 1); resetCount(); sync(); sim.draw(); } })) : null,
          g.length > 1 ? g.map((q, i) => h('button', { class: 'pbtn', type: 'button', 'aria-pressed': String(i === gi), 'aria-label': fmt(LB.gear, { n: q.name }), text: q.name, onclick: () => { gi = i; resetCount(); sync(); sim.draw(); } })) : null
        ];
      };
      const box = h('div', { class: 'psel tl', role: 'group' });
      const sync = () => box.replaceChildren(...mk().flat().filter(Boolean));
      sync(); panel.append(box);
    }
  };

  // diagram: a small scene described in data (parts, steps, flows). See core/BLOCKS.md.
  const easeOut = k => 1 - Math.pow(1 - k, 3);
  const easeIO = k => k < 0.5 ? 4 * k * k * k : 1 - Math.pow(-2 * k + 2, 3) / 2;
  const DG = { top: 28, topBare: 10, note: 24, scrub: 32, side: 10, ease: 500, hold: 1100, rest: 1800, dim: 0.25, pop: 480 };
  // Points of a Catmull-Rom spline through pts (optionally closed), sampled into a polyline.
  function splinePts(p, closed) {
    const n = p.length, out = [], seg = closed ? n : n - 1, at = i => closed ? p[(i + n) % n] : p[clamp(i, 0, n - 1)];
    for (let i = 0; i < seg; i++) {
      const a = at(i - 1), b = at(i), c = at(i + 1), d = at(i + 2);
      for (let s = 0; s < 10; s++) {
        const t = s / 10, t2 = t * t, t3 = t2 * t;
        out.push([0, 1].map(j => 0.5 * (2 * b[j] + (-a[j] + c[j]) * t + (2 * a[j] - 5 * b[j] + 4 * c[j] - d[j]) * t2 + (-a[j] + 3 * b[j] - 3 * c[j] + d[j]) * t3)));
      }
    }
    if (!closed) out.push(p[n - 1].slice());
    return out;
  }
  // Nearest point on a polyline (screen px) to (x, y).
  function nearestOn(pts, closed, x, y) {
    let best = null, bd = Infinity;
    const m = closed ? pts.length : pts.length - 1;
    for (let i = 0; i < m; i++) {
      const a = pts[i], b = pts[(i + 1) % pts.length], dx = b[0] - a[0], dy = b[1] - a[1], l2 = dx * dx + dy * dy;
      const t = l2 ? clamp(((x - a[0]) * dx + (y - a[1]) * dy) / l2, 0, 1) : 0, qx = a[0] + dx * t, qy = a[1] + dy * t, d = Math.hypot(x - qx, y - qy);
      if (d < bd) { bd = d; best = [qx, qy]; }
    }
    return best || pts[0];
  }
  const DG_STYLES = ['ink', 'thin', 'hatch', 'blue', 'heat', 'green', 'spark', 'accent'];
  const styleCol = s => ({ blue: T.blue, heat: T.heat, green: T.green, spark: T.spark, accent: T.accent, thin: T.ink, hatch: T.ink, ink: T.ink })[s] || T.ink;

  V.diagram = function (panel, c, card) {
    const P = Object.assign({ view: [100, 100], parts: [], steps: [], flows: [], scrub: false }, c);
    const [VW, VH] = P.view, parts = P.parts, steps = P.steps || [], flows = P.flows || [], N = steps.length;
    const SHAPES = ['rect', 'circle', 'line', 'path', 'arrow', 'dot', 'text'];
    const idx = {};
    parts.forEach((p, i) => {
      if (!SHAPES.includes(p.shape)) throw new Error('TMH diagram: unknown shape "' + p.shape + '" (part ' + (p.id || i) + ')');
      if (p.id != null) idx[p.id] = i;
    });
    const ref = (id, k) => { if (!(id in idx)) throw new Error('TMH diagram: unknown part id "' + id + '" in step ' + k); return idx[id]; };
    // States: arrays per part (visibility v, focus dim d, offsets ox oy), per flow (weight f) and per step (note alpha n).
    // sw: per part, one weight per style (flattened), so a restyle cross-fades like everything else.
    const NS = DG_STYLES.length, swOf = name => { const j = DG_STYLES.indexOf(name || 'ink'); return DG_STYLES.map((_, k) => k === (j < 0 ? 0 : j) ? 1 : 0); };
    parts.forEach((p, i) => { if (p.style && !DG_STYLES.includes(p.style)) throw new Error('TMH diagram: unknown style "' + p.style + '" (part ' + (p.id || i) + ')'); });
    const base = { v: parts.map(p => p.hidden ? 0 : 1), d: parts.map(() => 1), ox: parts.map(() => 0), oy: parts.map(() => 0), sw: parts.flatMap(p => swOf(p.style)) };
    const S = [], FO = [];
    { let v = base.v.slice(), ox = base.ox.slice(), oy = base.oy.slice(), sw = base.sw.slice();
      steps.forEach((st, k) => {
        Object.keys(st.restyle || {}).forEach(id => {
          const i = ref(id, k), nm = st.restyle[id];
          if (!DG_STYLES.includes(nm)) throw new Error('TMH diagram: unknown style "' + nm + '" in step ' + k);
          sw.splice(i * NS, NS, ...swOf(nm));
        });
        (st.show || []).forEach(id => { v[ref(id, k)] = 1; });
        (st.hide || []).forEach(id => { v[ref(id, k)] = 0; });
        Object.keys(st.move || {}).forEach(id => { const i = ref(id, k); ox[i] = st.move[id][0]; oy[i] = st.move[id][1]; });
        const fo = st.focus && st.focus.length ? st.focus.map(id => ref(id, k)) : null;
        FO.push(parts.map((p, i) => !!fo && fo.includes(i)));
        S.push({ v: v.slice(), ox: ox.slice(), oy: oy.slice(), sw: sw.slice(), d: parts.map((p, i) => !fo || fo.includes(i) ? 1 : DG.dim),
          f: flows.map(f => !f.during || f.during.includes(k) ? 1 : 0), n: steps.map((s, j) => j === k ? 1 : 0) });
      }); }
    if (!N) S.push({ v: base.v, d: base.d, ox: base.ox, oy: base.oy, sw: base.sw, f: flows.map(() => 1), n: [] });
    const lerpS = (A, B, e) => { const o = {}; for (const k in A) o[k] = A[k].map((a, i) => a + (B[k][i] - a) * e); return o; };
    const hasNotes = steps.some(s => s.note);

    // pop: when a part appears, gains focus or moves it gets a brief emphasis (scale-in from 0.9 + stroke/glow pulse). popAt = start time, popIn = it appeared.
    const popAt = parts.map(() => -1e9), popIn = parts.map(() => false);
    let cur = 0, from = S[0], t0 = 0, dur = 0, hold = DG.hold, pos = 0, flowT = 0, geom = null, sim;
    const rm = () => reducedMQ.matches;
    const prog = () => dur > 0 ? clamp((performance.now() - t0) / dur, 0, 1) : 1;
    const shown = () => {
      if (P.scrub && N > 1) { const f = Math.min(Math.floor(pos), N - 2); return lerpS(S[f], S[f + 1], pos - f); }
      return lerpS(from, S[cur], easeIO(prog()));
    };
    const goto = k => {   // ease from what is on screen to step k (instant under reduced motion)
      if (P.scrub && N > 1) { pos = k; return; }
      const prev = cur;
      from = shown(); cur = k; t0 = performance.now(); dur = rm() ? 0 : DG.ease;
      if (!rm() && !P.scrub && k !== prev) parts.forEach((p, i) => {
        const B = S[k], appear = B.v[i] - from.v[i] > 0.5 && p.shape !== 'arrow', focusIn = FO[k] && FO[k][i] && !(FO[prev] && FO[prev][i]) && B.v[i] > 0.5;
        const moved = Math.abs(B.ox[i] - from.ox[i]) + Math.abs(B.oy[i] - from.oy[i]) > 0.5;
        if (appear || focusIn || moved) { popAt[i] = t0; popIn[i] = appear; }
      });
      sim.alwaysDraw = true;
    };
    const curStep = () => P.scrub && N > 1 ? Math.round(pos) : cur;

    const cv = makeCanvas(panel, () => sim && sim.draw());
    sim = addSim(card, {
      update(dt) {
        flowT += dt;
        if (P.scrub || N < 2) return;
        if (prog() < 1) return;
        hold -= dt * 1000;
        if (hold <= 0) { goto((cur + 1) % N); hold = (cur === N - 1 ? DG.rest : DG.hold); }
      },
      draw() {
        if (!cv.w) return;
        const ctx = cv.ctx, W = cv.w, H = cv.h;
        const now = performance.now(), pe = parts.map((p, i) => rm() || P.scrub ? 0 : 1 - easeOut(clamp((now - popAt[i]) / DG.pop, 0, 1)));
        if (sim.alwaysDraw && prog() >= 1 && !pe.some(e => e > 0)) sim.alwaysDraw = false;
        const st = shown();
        const hasUI = N > 1 || flows.length;
        const top = hasUI ? DG.top : DG.topBare, bot = 8 + (hasNotes ? DG.note : 0) + (P.scrub && N > 1 ? DG.scrub : 0);
        const aw = W - 2 * DG.side, ah = H - top - bot, s = Math.min(aw / VW, ah / VH);
        const ox = (W - VW * s) / 2, oy = top + (ah - VH * s) / 2;
        geom = { top, bot, W, H };
        clearPanel(ctx, W, H);
        ctx.lineJoin = 'round'; ctx.lineCap = 'round'; ctx.setLineDash([]);
        const X = x => ox + x * s, Y = y => oy + y * s;

        // geometry of a part in screen px: { pts, closed, circ:[x,y,r], bbox, centre }
        const geo = (p, i) => {
          const mx = st.ox[i], my = st.oy[i], pt = a => [X(a[0] + mx), Y(a[1] + my)];
          let g;
          if (p.shape === 'rect') { const a = [p.x, p.y], b = [p.x + p.w, p.y + p.h]; g = { pts: [pt(a), pt([b[0], a[1]]), pt(b), pt([a[0], b[1]])], closed: true }; }
          else if (p.shape === 'circle') g = { circ: [X(p.x + mx), Y(p.y + my), p.r * s] };
          else if (p.shape === 'dot') g = { circ: [X(p.x + mx), Y(p.y + my), (p.r || 1.2) * s], dotc: true };
          else if (p.shape === 'text') g = { pts: [pt([p.x, p.y])], closed: false };
          else {
            let L = (p.points || [p.from, p.to]).map(pt);
            if (p.shape === 'path' && p.smooth && L.length > 2) L = splinePts(L, !!p.closed);
            g = { pts: L, closed: p.shape === 'path' && !!p.closed };
          }
          if (g.circ) g.centre = [g.circ[0], g.circ[1]];
          else { const xs = g.pts.map(q => q[0]), ys = g.pts.map(q => q[1]); g.centre = [(Math.min(...xs) + Math.max(...xs)) / 2, (Math.min(...ys) + Math.max(...ys)) / 2]; }
          return g;
        };
        const gs = parts.map(geo);
        const alphaOf = i => st.v[i] * st.d[i];

        const paint = (p, g, sty, a, pk, frac) => {
          const col = styleCol(sty);
          const subj = sty === 'blue' || sty === 'heat' || sty === 'green' || sty === 'spark' || sty === 'accent';
          const lw = (sty === 'thin' || sty === 'hatch' ? LW : subj && sty !== 'accent' ? 1.75 : LW2) * (1 + 0.7 * pk);
          const closedShape = g.circ || g.closed;
          ctx.save(); ctx.globalAlpha = a;
          if (pk > 0.01) {   // emphasis: glow pulse, and a scale-in from 0.9 for a part that just appeared
            ctx.shadowColor = col; ctx.shadowBlur = 9 * pk * cv.dpr;
            if (p.shape !== 'arrow' && popIn[parts.indexOf(p)]) { const sc = 1 - 0.1 * pk, c0 = g.centre; ctx.translate(c0[0], c0[1]); ctx.scale(sc, sc); ctx.translate(-c0[0], -c0[1]); }
          }
          const path = new Path2D();
          if (g.circ) path.arc(g.circ[0], g.circ[1], g.circ[2], 0, TAU);
          else { g.pts.forEach((q, j) => j ? path.lineTo(q[0], q[1]) : path.moveTo(q[0], q[1])); if (g.closed) path.closePath(); }
          if (closedShape && p.shape !== 'dot' && p.fill !== false) {
            ctx.fillStyle = T.panel; ctx.fill(path);
            if (subj) { ctx.fillStyle = rgba(col, sty === 'accent' ? 0.26 : 0.42); ctx.fill(path); }
            else if (sty === 'hatch') {
              ctx.save(); ctx.clip(path); ctx.strokeStyle = T.rule; ctx.lineWidth = 1; ctx.beginPath();
              const bx = g.circ ? [g.circ[0] - g.circ[2], g.circ[0] + g.circ[2], g.circ[1] - g.circ[2], g.circ[1] + g.circ[2]]
                : [Math.min(...g.pts.map(q => q[0])), Math.max(...g.pts.map(q => q[0])), Math.min(...g.pts.map(q => q[1])), Math.max(...g.pts.map(q => q[1]))];
              const hh = bx[3] - bx[2], ww = bx[1] - bx[0];
              for (let k = -hh; k < ww; k += 6) { ctx.moveTo(bx[0] + k, bx[3]); ctx.lineTo(bx[0] + k + hh, bx[2]); }
              ctx.stroke(); ctx.restore();
            }
          }
          if (p.dash) ctx.setLineDash([5, 4]);
          if (p.shape === 'dot') { ctx.fillStyle = sty === 'hatch' || sty === 'thin' ? T.ink2 : col; ctx.fill(path); }
          else if (p.shape === 'arrow') {
            // drawn in from tail to head: keep the first `frac` of the polyline length
            let q = g.pts; const tot = q.slice(1).reduce((s0, z, j) => s0 + Math.hypot(z[0] - q[j][0], z[1] - q[j][1]), 0);
            if (frac < 0.999 && tot > 0) {
              let rest = tot * frac; const cut = [q[0]];
              for (let j = 1; j < q.length; j++) { const d = Math.hypot(q[j][0] - q[j - 1][0], q[j][1] - q[j - 1][1]); if (rest >= d) { cut.push(q[j]); rest -= d; } else { const u = d ? rest / d : 0; cut.push([q[j - 1][0] + (q[j][0] - q[j - 1][0]) * u, q[j - 1][1] + (q[j][1] - q[j - 1][1]) * u]); break; } }
              q = cut;
            }
            const e = q[q.length - 1], b = q[q.length - 2] || q[0], ang = Math.atan2(e[1] - b[1], e[0] - b[0]), hs = Math.min(1, tot * frac / 14), hl = 10 * hs, hw = 5.2 * hs;
            ctx.strokeStyle = col; ctx.lineWidth = lw; ctx.beginPath();
            q.forEach((z, j) => j < q.length - 1 ? (j ? ctx.lineTo(z[0], z[1]) : ctx.moveTo(z[0], z[1])) : ctx.lineTo(e[0] - Math.cos(ang) * hl * 0.6, e[1] - Math.sin(ang) * hl * 0.6));
            ctx.stroke(); ctx.setLineDash([]);
            ctx.fillStyle = col; ctx.beginPath(); ctx.moveTo(e[0], e[1]);
            ctx.lineTo(e[0] - Math.cos(ang) * hl + Math.sin(ang) * hw, e[1] - Math.sin(ang) * hl - Math.cos(ang) * hw);
            ctx.lineTo(e[0] - Math.cos(ang) * hl - Math.sin(ang) * hw, e[1] - Math.sin(ang) * hl + Math.cos(ang) * hw); ctx.closePath(); ctx.fill();
          } else { ctx.strokeStyle = col; ctx.lineWidth = lw; ctx.stroke(path); }
          ctx.restore();
        };
        // a restyled part is drawn once per style it is blending between, each at the share that gives an even cross-fade
        parts.forEach((p, i) => {
          const isArrow = p.shape === 'arrow', a = isArrow ? Math.min(1, st.v[i] * 3) * st.d[i] : alphaOf(i); if (a < 0.01 || p.shape === 'text') return;
          let cum = 0;
          DG_STYLES.forEach((nm, j) => { const w = st.sw[i * NS + j]; if (w < 0.004) return; cum += w; paint(p, gs[i], nm, a * w / cum, pe[i], isArrow ? clamp(st.v[i], 0, 1) : 1); });
        });

        // flows: dots moving along a polyline at a steady speed, fading in and out at the ends
        flows.forEach((f, fi) => {
          const w = st.f[fi]; if (w < 0.01) return;
          const pts = f.along, seg = [], cum = [0];
          for (let i = 1; i < pts.length; i++) cum.push(cum[i - 1] + Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]));
          const L = cum[cum.length - 1]; if (!L) return;
          const cnt = f.count || 4, speed = f.speed || 16, fade = Math.min(L * 0.15, 6), col = styleCol(f.style === 'thin' ? 'ink' : f.style || 'accent');
          const tt = rm() ? 0 : flowT;
          for (let k = 0; k < cnt; k++) {
            const d = ((tt * speed + k * L / cnt) % L + L) % L;
            let j = 1; while (j < cum.length - 1 && cum[j] < d) j++;
            const u = (d - cum[j - 1]) / ((cum[j] - cum[j - 1]) || 1), x = pts[j - 1][0] + (pts[j][0] - pts[j - 1][0]) * u, y = pts[j - 1][1] + (pts[j][1] - pts[j - 1][1]) * u;
            ctx.globalAlpha = w * clamp(Math.min(d, L - d) / fade, 0, 1);
            disc(ctx, X(x), Y(y), f.size || 4.2, col, T.panel, 1.25);
          }
          ctx.globalAlpha = 1;
        });

        // labels (with leader to the part) and text parts (no leader)
        parts.forEach((p, i) => {
          const a = clamp(2 * st.v[i] - 1, 0, 1) * st.d[i]; if (a < 0.01) return;   // labels fade after their part is mostly in, before it is mostly out
          const txt = p.text || p.label; if (!txt) return;
          const g = gs[i], at = p.labelAt ? [X(p.labelAt[0] + st.ox[i]), Y(p.labelAt[1] + st.oy[i])] : null;
          ctx.save(); ctx.globalAlpha = a;
          if (p.label && at) {
            const tw = monoW(ctx, p.label), ax = at[0];
            const to = g.circ ? (() => { const dx = at[0] - g.circ[0], dy = at[1] - g.circ[1], d = Math.hypot(dx, dy) || 1; return d <= g.circ[2] ? g.centre : [g.circ[0] + dx / d * g.circ[2], g.circ[1] + dy / d * g.circ[2]]; })()
              : g.pts.length === 1 ? g.pts[0] : nearestOn(g.pts, g.closed, at[0], at[1]);
            const right = to[0] < ax;
            const lx = right ? clamp(ax, 6 + tw, W - 6) : clamp(ax, 6, W - 6 - tw);
            leader(ctx, p.label, lx, clamp(at[1], 8, H - 8), to[0], to[1], right);
          } else {
            const q = at || g.centre; mono(ctx, txt, clamp(q[0], 6, W - 6), q[1], 'center', 'middle', T.ink2);
          }
          ctx.restore();
        });

        // note, step dots, scrub slider
        if (hasNotes) {
          const ny = H - (P.scrub && N > 1 ? DG.scrub : 0) - DG.note / 2 - 2;
          steps.forEach((sp, k) => { const na = P.scrub ? (k === curStep() ? 1 : 0) : clamp(2 * st.n[k] - 1, 0, 1);   // outgoing note fades out, then the next fades in
            if (sp.note && na > 0.01) { ctx.globalAlpha = na; mono(ctx, sp.note, W / 2, ny, 'center', 'middle', T.ink); } });
          ctx.globalAlpha = 1;
        }
        if (N > 1) {
          const cs = curStep();
          for (let k = 0; k < N; k++) {
            const x = 16 + k * 14, y = 15;
            if (k === cs) disc(ctx, x, y, 3.4, T.accent);
            else disc(ctx, x, y, 3, T.panel, T.ink2, 1.25);
          }
        }
        if (P.scrub && N > 1) {
          const y = H - DG.scrub / 2, x0 = 20, x1 = W - 20;
          ctx.strokeStyle = T.ink2; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(x0, y); ctx.lineTo(x1, y); ctx.stroke();
          ctx.beginPath(); for (let k = 0; k < N; k++) { const x = x0 + (x1 - x0) * k / (N - 1); ctx.moveTo(x, y - 3); ctx.lineTo(x, y + 3); } ctx.stroke();
          disc(ctx, x0 + (x1 - x0) * pos / (N - 1), y, 6, T.accent);
        }
      },
      onShow() {
        if (!sim.touched) { cur = 0; from = S[0]; dur = 0; hold = DG.hold; pos = 0; flowT = 0; popAt.fill(-1e9); }
        autoplay(sim);
      }
    });
    if (N > 1 || flows.length) playLink(panel, sim, () => { if (N > 1) goto(((P.scrub ? Math.round(pos) : cur) + 1) % N); });
    if (N > 1) {
      cue(panel, sim, tipOf(c, P.scrub ? UI.tips.scrub : N >= 3 ? UI.tips.dots : null));
      const sliderY = e => P.scrub && geom && relPos(cv.cv, e)[1] > geom.H - DG.scrub;
      const dotAt = e => { if (!geom) return -1; const [x, y] = relPos(cv.cv, e); if (Math.abs(y - 15) > 14) return -1; const k = Math.round((x - 16) / 14); return k >= 0 && k < N && Math.abs(x - (16 + k * 14)) < 8 ? k : -1; };
      const setPos = e => { const x = relPos(cv.cv, e)[0]; pos = clamp((x - 20) / (geom.W - 40), 0, 1) * (N - 1); };
      let mode = '';
      attachDrag(cv.cv, sim, {
        hit(e) { return sliderY(e) || dotAt(e) >= 0; },
        start(e) { if (sliderY(e)) { mode = 'slider'; setPos(e); } else { mode = 'dot'; goto(dotAt(e)); } },
        move(e) { if (mode === 'slider') setPos(e); },
        resume: P.scrub && flows.length > 0
      });
    }
  };

  /* ---------- card renderers ---------- */
  const R = {};
  const visualTypes = V;
  function mountVisual(card, panel, v) {
    const f = V[v.type];
    if (!f) throw new Error('TMH: unknown visual type "' + v.type + '"');
    f(panel, v, card);
  }
  const panelOf = (card, v, cls) => {
    const panel = h('div', { class: 'panel' + (cls ? ' ' + cls : '') });
    if (v) mountVisual(card, panel, v);
    return panel;
  };
  const cardEl = (c, cls) => h('section', { class: 'card ' + cls, 'aria-label': c.title || 'Card' });

  R.cover = function (c) {
    const el = cardEl(c, 'cover');
    el.append(panelOf(el, c.visual),
      h('div', { class: 'txt' }, h('h2', { class: 'title', text: c.title }), h('p', { class: 'lead', text: c.lead }), h('div', { class: 'hint meta', text: UI.swipe })));
    return el;
  };

  // card: headline above the picture, one short paragraph below. Card 1 of a topic is the opener: its headline is the topic's question,
  // set big, and the card's own `title` (optional) becomes the smaller setup line under it.
  R.card = function (c, i) {
    const opener = i === 0 && building && building.title;
    const el = cardEl(opener ? { title: building.title } : c, 'plain' + (opener ? ' opener' : ''));
    el.append(
      h('header', { class: 'lead' }, h('h2', { text: opener ? building.title : c.title }), opener && c.title ? h('p', { class: 'setup', text: c.title }) : null),
      panelOf(el, c.visual),
      h('div', { class: 'txt' }, h('p', {}, c.text, c.takeaway ? [' ', h('b', { class: 'take', text: c.takeaway })] : null)));
    return el;
  };

  // bridge: a text-only pause between two cards that closes one idea and sets up the next. No headline, no picture.
  R.bridge = function (c) {
    const el = cardEl({ title: c.text.split(/[.?!]/)[0] }, 'bridge');
    el.append(h('div', { class: 'txt' }, h('p', { text: c.text })));
    return el;
  };

  // guess: unscored. Tapping an option marks the right one, dims the rest, fades in `why`, and reveals the visual (if any).
  R.guess = function (c) {
    const el = cardEl(c, 'guess' + (c.visual ? ' hasvis' : ''));
    let panel = null, done = false;
    el.append(h('header', { class: 'lead' }, h('h2', { text: c.title })));
    if (c.visual) { panel = panelOf(el, c.visual, 'wait'); panel.setAttribute('data-hint', UI.guessWait); el.__hold = true; el.append(panel); }
    const why = h('p', { class: 'why', 'aria-live': 'polite', text: c.why });
    const btns = c.options.map((t, k) => h('button', { class: 'opt', type: 'button' }, h('span', { class: 't', text: t }), h('span', { class: 'tag meta', text: UI.thisOne })));
    btns.forEach((b, k) => b.addEventListener('click', () => {
      if (done) return; done = true;
      btns.forEach((o, j) => { o.classList.add(j === c.answer ? 'right' : 'dim'); o.setAttribute('aria-disabled', 'true'); });
      why.classList.add('show');
      if (panel) { panel.classList.remove('wait'); el.__hold = false; el.__refresh && el.__refresh(); }
    }));
    el.append(h('div', { class: 'txt' }, h('div', { class: 'opts', role: 'group' }, btns), why));
    return el;
  };

  // more: last card. Links to other topics (ids unknown to the host are skipped). With nothing to link, up to 3 other topics of
  // the library are offered instead (same theme first); with none at all, just the note and a calm hint.
  R.more = function (c) {
    const ctx = TMH.ctx, me = building || {};
    let ids = (c.links || []).filter(id => ctx.has(id) && id !== me.id);
    if (!ids.length && ctx.others) {
      const rest = ctx.others(me.id).filter(L => ctx.has(L.id));
      ids = rest.filter(L => L.theme === me.theme).concat(rest.filter(L => L.theme !== me.theme)).slice(0, 3).map(L => L.id);
    }
    const empty = !ids.length, hint = h('div', { class: 'hint meta', text: UI.swipeUp });
    const el = cardEl({ title: UI.goDeeper }, 'more' + (empty ? ' empty' : ''));
    el.append(h('div', { class: 'txt' },
      empty ? null : h('h2', { text: UI.goDeeper }),
      c.note ? h('p', { class: 'note', text: c.note }) : null,
      empty ? null : h('ul', { class: 'links' }, ids.map(id => {
        const t = ctx.info(id);
        return h('li', {}, h('button', { class: 'link', type: 'button', onclick: () => ctx.open(id) },
          h('span', { class: 'lt', text: t.title }),
          h('span', { class: 'lm meta' }, t.cards + ' ' + UI.cards + ' ', h('b', { text: '→' }))));
      })),
      empty || !ctx.single ? hint : null));
    return el;
  };

  /* ---------- build: topic data -> card elements ---------- */
  // Returns { cards, show(active, i), refresh(), destroy() }. Visuals run only while their card is the shown one of an active topic.
  function build(EX) {
    const sc = scope = { sims: [], ros: [] };
    building = EX;
    retain();
    let cards;
    try {
      cards = EX.cards.map((c, i) => {
        if (!R[c.type]) throw new Error('TMH: unknown card type "' + c.type + '" (card ' + i + ')');
        const el = R[c.type](c, i);
        el.dataset.i = i; el.dataset.type = c.type;
        return el;
      });
    } finally { scope = null; building = null; }
    let active = false, idx = 0;
    const apply = () => cards.forEach((card, j) => {
      const vis = active && j === idx && !card.__hold;
      (card.__sims || []).forEach(s => {
        const was = s.visible; s.visible = vis;
        if (vis && !was) { s.onShow && s.onShow(); s.cueShow && s.cueShow(); s.draw(); }
        else if (!vis && was) s.cueHide && s.cueHide();
      });
    });
    const api = {
      cards,
      show(a, i) { active = a; idx = i; apply(); },
      refresh: apply,
      destroy() {
        sc.ros.forEach(r => r.disconnect()); sc.sims.forEach(s => allSims.delete(s));
        sc.ros.length = sc.sims.length = 0; release();
      }
    };
    cards.forEach(el => { el.__refresh = apply; });
    requestAnimationFrame(() => sc.sims.forEach(s => s.draw()));   // static first frames
    return api;
  }

  // Host hooks, replaced by core/library.js: has(id), info(id) -> {title, cards, theme}, others(id) -> other topics, open(id), single (one-topic page).
  const ctxDefault = { has: () => false, info: () => ({}), others: () => [], open() {}, single: true };
  const debug = () => ({ loop: raf ? 1 : 0, holds, sims: allSims.size });

  window.TMH = {
    build, blocks: R, visuals: visualTypes, mountVisual, h, ui: UI, fmt, ctx: ctxDefault,
    makeCanvas, addSim, playLink, sparkFlash, tint, autoplay, attachDrag, relPos, clearPanel, mono, monoW, leader, hatchRect, bar, disc, drawEngine,
    theme: T, rgba, mixc, clamp, reducedMotion: () => reducedMQ.matches, lastDrag: () => lastDrag, debug
  };
})();
