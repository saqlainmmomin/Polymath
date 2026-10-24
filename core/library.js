/* Tell Me How feed: vertical scroll-snap of topic slots (shuffled; #id first), each a horizontal scroll-snap row of cards.
   Mounts only the current topic and its neighbours (+-1). Expects #feed and #announce in the page and the globals
   LIBRARY ([{id, title, kind, theme, cards}]), TOPICS ({id: EXPLAINER}), SINGLE (true on the one-topic page). */
(function () {
  var h = TMH.h;
  var feed = document.getElementById('feed');
  var announce = document.getElementById('announce');
  var app = feed.parentNode;
  var info = {};
  LIBRARY.forEach(function (L) { info[L.id] = L; });
  var smooth = function () { return TMH.reducedMotion() ? 'auto' : 'smooth'; };

  function shuffle(a) {
    for (var i = a.length - 1; i > 0; i--) { var j = Math.floor(Math.random() * (i + 1)); var t = a[i]; a[i] = a[j]; a[j] = t; }
    return a;
  }
  var hashId = function () { return decodeURIComponent(location.hash.slice(1)); };
  var order = shuffle(LIBRARY.map(function (L) { return L.id; }));
  (function pinFirst() {
    var k = order.indexOf(hashId());
    if (k > 0) { order.splice(k, 1); order.unshift(hashId()); }
  })();

  var slots = [];   // in feed order: {id, el, api, row, dots, nudge, cur}
  var current = null;
  function makeSlot(id) { return { id: id, el: h('section', { class: 'slot', 'aria-label': info[id].title }), api: null, cur: 0 }; }
  var slotFor = function (id) { return slots.filter(function (s) { return s.id === id; })[0]; };

  // Page dots: one per card, the current one in accent; on card 1 a nudging "Swipe" hint says there is more sideways.
  function updateBar(s) {
    s.dots.forEach(function (d, k) { d.classList.toggle('on', k === s.cur); });
    s.nudge.hidden = s.cur !== 0;
    s.el.classList.toggle('first', s.cur === 0);
  }
  function say(s) { announce.textContent = info[s.id].title + ', card ' + (s.cur + 1) + ' of ' + s.api.cards.length; }

  function mountSlot(s) {
    if (s.api) return;
    var EX = TOPICS[s.id];
    s.api = TMH.build(EX);
    s.dots = s.api.cards.map(function () { return h('i'); });
    s.nudge = h('span', { class: 'nudge', text: TMH.ui.swipeMore });
    var bar = h('div', { class: 'bar' },
      h('span', { class: 'ttl', text: EX.title }),
      SINGLE ? null : h('button', { class: 'idxlink', type: 'button', text: 'Index', onclick: function (e) { openIndex(e.currentTarget); } }));
    s.row = h('div', { class: 'row', tabindex: '-1' }, s.api.cards);
    var dots = h('div', { class: 'dots meta', 'aria-hidden': 'true' }, h('span', { class: 'dd' }, s.dots), s.dots.length > 1 ? s.nudge : null);
    s.el.replaceChildren(bar, h('div', { class: 'prog', 'aria-hidden': 'true' }), s.row, dots);
    s.cur = 0; updateBar(s);
    var ticking = false;
    s.row.addEventListener('scroll', function () {
      if (ticking) return; ticking = true;
      requestAnimationFrame(function () {
        ticking = false;
        if (!s.api) return;
        var i = Math.round(s.row.scrollLeft / s.row.clientWidth);
        if (i === s.cur) return;
        s.cur = i; updateBar(s);
        s.api.show(s === current, i);
        if (s === current) say(s);
      });
    }, { passive: true });
  }
  function unmountSlot(s) {
    if (!s.api) return;
    s.api.destroy(); s.api = null; s.el.replaceChildren(); s.cur = 0;
  }

  // Keep the current topic and its neighbours mounted; everything else is torn down so its canvases stop.
  function setCurrent(s) {
    current = s;
    var i = slots.indexOf(s);
    slots.forEach(function (t, k) { if (Math.abs(k - i) <= 1) mountSlot(t); else unmountSlot(t); });
    slots.forEach(function (t) { if (t.api) t.api.show(t === s, t.cur); });
    say(s);
    if (!SINGLE) history.replaceState(null, '', '#' + s.id);
  }

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (en.intersectionRatio < 0.6) return;
      var s = slots.filter(function (t) { return t.el === en.target; })[0];
      if (s && s !== current) setCurrent(s);
    });
  }, { root: feed, threshold: [0.6] });

  function scrollToSlot(s, behavior) {
    var i = slots.indexOf(s);
    mountSlot(s);
    feed.scrollTo({ top: i * feed.clientHeight, behavior: behavior || 'auto' });
  }

  // `more` links: the linked topic becomes the very next slot and the feed scrolls to it.
  function slideIn(id) {
    if (!info[id]) return;
    var ci = slots.indexOf(current), s = slotFor(id);
    if (s === current) return;
    if (!s) { s = makeSlot(id); io.observe(s.el); }
    else {
      var si = slots.indexOf(s);
      if (si !== ci + 1) {
        // detach, then reinsert right after the current slot; compensate scrollTop when the slot came from above
        slots.splice(si, 1); s.el.remove();
        if (si < ci) feed.scrollTop -= feed.clientHeight;
      }
    }
    if (slots.indexOf(s) < 0) { slots.splice(slots.indexOf(current) + 1, 0, s); current.el.after(s.el); }
    scrollToSlot(s, smooth());
  }
  TMH.ctx = {
    single: !!SINGLE,
    has: function (id) { return !SINGLE && !!info[id]; },
    info: function (id) { return info[id]; },
    others: function (id) { return SINGLE ? [] : LIBRARY.filter(function (L) { return L.id !== id; }); },
    open: slideIn
  };

  /* ---------- index ---------- */
  var indexEl = null, indexFrom = null;
  function closeIndex() {
    if (!indexEl) return;
    indexEl.remove(); indexEl = null;
    if (indexFrom && indexFrom.isConnected) indexFrom.focus({ preventScroll: true });
  }
  function openIndex(from) {
    if (indexEl) return;
    indexFrom = from;
    var close = h('button', { type: 'button', class: 'meta', text: 'Close', onclick: closeIndex });
    indexEl = h('div', { class: 'index', role: 'dialog', 'aria-label': 'Topics' },
      h('div', { class: 'ihd meta' }, h('span', { text: 'Index' }), close),
      h('ul', {}, LIBRARY.map(function (L) {
        return h('li', {}, h('button', { class: 'link', type: 'button', onclick: function () {
          var s = slotFor(L.id); closeIndex(); if (s) scrollToSlot(s, 'auto');
        } }, h('span', { class: 'lt', text: L.title }), h('span', { class: 'lm meta', text: L.cards + ' ' + TMH.ui.cards })));
      })));
    app.append(indexEl);
    close.focus({ preventScroll: true });
  }

  /* ---------- gestures: tap edges, keyboard ---------- */
  function goCard(d) {
    if (!current || !current.row) return;
    current.row.scrollBy({ left: d * current.row.clientWidth, behavior: smooth() });
  }
  function goTopic(d) {
    var i = slots.indexOf(current) + d;
    if (SINGLE || i < 0 || i >= slots.length) return;
    scrollToSlot(slots[i], smooth());
  }
  feed.addEventListener('click', function (e) {
    if (e.target.closest('a, button, input, select, textarea, summary')) return;
    if (performance.now() - TMH.lastDrag() < 350) return;   // the tap that ends a drag is not a tap
    var card = e.target.closest('.card');
    if (!card) return;
    var rc = card.getBoundingClientRect(), x = (e.clientX - rc.left) / rc.width;
    if (x > 0.75) goCard(1); else if (x < 0.25) goCard(-1);
  });
  document.addEventListener('keydown', function (e) {
    var t = e.target;
    if (e.key === 'Escape' && indexEl) { closeIndex(); return; }
    if (indexEl || (t && /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName)) || e.altKey || e.ctrlKey || e.metaKey) return;
    var k = e.key;
    if (k === 'ArrowRight') goCard(1);
    else if (k === 'ArrowLeft') goCard(-1);
    else if (k === 'ArrowDown') { if (SINGLE) return; goTopic(1); }
    else if (k === 'ArrowUp') { if (SINGLE) return; goTopic(-1); }
    else return;
    e.preventDefault();
  });
  window.addEventListener('hashchange', function () {
    var id = hashId();
    if (SINGLE || !info[id] || (current && current.id === id)) return;
    slideIn(id);
  });

  /* ---------- start ---------- */
  slots = order.map(makeSlot);
  feed.replaceChildren.apply(feed, slots.map(function (s) { return s.el; }));
  slots.forEach(function (s) { io.observe(s.el); });
  feed.setAttribute('aria-label', 'Tell Me How. Swipe up for the next topic, sideways for the next card.');
  setCurrent(slots[0]);
})();
