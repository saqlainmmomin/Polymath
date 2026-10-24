/* Tell Me How library shell: home screen + hash routing over the topics inlined by build.mjs.
   Expects #topicview, #home, #tiles, #homebtn, #feed, and the globals LIBRARY and TOPICS.
   Routing uses bare hash tokens only: #engine, #gearbox. Empty or unknown hash = home. */
(function () {
  var h = TMH.h;
  var topicview = document.getElementById('topicview');
  var home = document.getElementById('home');
  var tiles = document.getElementById('tiles');
  var feed = document.getElementById('feed');
  var pad2 = function (n) { return String(n).padStart(2, '0'); };

  // Branch items with a `topic` field link in-page instead of using their href.
  TMH.topicHref = function (id) { return '#' + id; };

  function renderTiles() {
    tiles.replaceChildren.apply(tiles, LIBRARY.map(function (L) {
      var stage = L.visual ? h('div', { class: 'tstage', 'aria-hidden': 'true' }) : null;
      var a = h('a', { class: 'tile', href: '#' + L.id },
        stage,
        h('div', { class: 'tbody' },
          h('h2', { text: L.title }),
          h('p', { class: 'teaser', text: L.teaser }),
          h('span', { class: 'tmeta' }, h('b', { text: pad2(L.cards) }), ' cards')));
      return h('li', {}, a);
    }));
    LIBRARY.forEach(function (L, i) {
      if (L.visual) TMH.ambient(tiles.children[i].querySelector('.tstage'), L);
    });
  }

  var shown = null; // 'home' or a topic id
  function route(first) {
    var id = decodeURIComponent(location.hash.slice(1));
    var ex = Object.prototype.hasOwnProperty.call(TOPICS, id) ? TOPICS[id] : null;
    var next = ex ? id : 'home';
    if (next === shown) return;
    shown = next;
    TMH.clearAmbient();
    if (!ex) {
      TMH.unmount();
      topicview.hidden = true; home.hidden = false;
      home.scrollTop = 0;
      renderTiles();
      if (!first) document.getElementById('hometitle').focus({ preventScroll: true });
    } else {
      home.hidden = true; topicview.hidden = false;
      tiles.replaceChildren();
      TMH.mount(ex); // replaces any mounted topic
      if (!first) { feed.tabIndex = -1; feed.focus({ preventScroll: true }); }
    }
  }
  window.addEventListener('hashchange', function () { route(false); });
  route(true);
})();
