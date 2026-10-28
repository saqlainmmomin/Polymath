// How does tapping a card send money from your bank to the shop? The tap only sends a message (about 2 seconds); the money moves later. Copy approved 2026-10-26 in the new voice; the iOS app draws every card natively (ios/Polymath/FlatPay.swift), these diagrams are stand-ins. Older summary: what happens in the two seconds after a tap. Card 1 = a message hops terminal -> shop's bank -> network -> your bank and back; card 2 = why a network sits in the middle; card 3 = your bank decides and sets the amount aside; card 4 = the real money moves later.
(function () {
  // Slide 1: the tap sends a message; the money stays put.
  const tap = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'card', shape: 'rect', x: 4, y: 30, w: 30, h: 20, style: 'spark', text: 'CARD' },
      { id: 'rd', shape: 'rect', x: 56, y: 24, w: 36, h: 32, style: 'thin', text: 'CARD READER' },
      { id: 'msg', shape: 'arrow', from: [74, 24], to: [74, 8], style: 'accent', hidden: true, label: 'Message', labelAt: [98, 6] },
      { id: 'cash', shape: 'circle', x: 19, y: 78, r: 8, style: 'accent', text: 'MONEY' }
    ],
    steps: [{ note: 'You tap your card' }, { move: { card: [20, 0] }, show: ['msg'], note: 'A message goes out; the money stays put' }] };

  // Four places in a loop. The message goes out along the accent lane and the yes comes back along the green lane.
  const hops = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 't', shape: 'rect', x: 3, y: 8, w: 40, h: 24, style: 'spark', text: 'CARD READER' },
      { id: 'sb', shape: 'rect', x: 57, y: 8, w: 40, h: 24, style: 'thin', text: "SHOP'S BANK" },
      { id: 'cn', shape: 'rect', x: 57, y: 64, w: 40, h: 24, style: 'blue', text: 'CARD NETWORK' },
      { id: 'yb', shape: 'rect', x: 3, y: 64, w: 40, h: 24, style: 'thin', text: 'YOUR BANK' },
      { id: 'o1', shape: 'arrow', from: [43, 16], to: [57, 16], style: 'accent', hidden: true },
      { id: 'o2', shape: 'arrow', from: [69, 32], to: [69, 64], style: 'accent', hidden: true },
      { id: 'o3', shape: 'arrow', from: [57, 72], to: [43, 72], style: 'accent', hidden: true },
      { id: 'b1', shape: 'arrow', from: [43, 80], to: [57, 80], style: 'green', hidden: true },
      { id: 'b2', shape: 'arrow', from: [85, 64], to: [85, 32], style: 'green', hidden: true },
      { id: 'b3', shape: 'arrow', from: [57, 24], to: [43, 24], style: 'green', hidden: true },
      { id: 'yes', shape: 'circle', x: 23, y: 48, r: 9, style: 'green', hidden: true, text: 'YES' }
    ],
    steps: [
      { note: 'You tap your card' },
      { restyle: { t: 'ink' }, show: ['o1', 'o2', 'o3'], note: 'A message hops to your bank' },
      { restyle: { yb: 'green' }, show: ['yes'], note: 'Your bank says yes' },
      { restyle: { t: 'green' }, hide: ['o1', 'o2', 'o3'], show: ['b1', 'b2', 'b3'], note: 'The yes hops back' }
    ],
    flows: [
      { along: [[43, 16], [57, 16]], style: 'accent', count: 2, speed: 14, during: [1] },
      { along: [[69, 32], [69, 64]], style: 'accent', count: 2, speed: 22, during: [1] },
      { along: [[57, 72], [43, 72]], style: 'accent', count: 2, speed: 14, during: [1] },
      { along: [[43, 80], [57, 80]], style: 'green', count: 2, speed: 14, during: [3] },
      { along: [[85, 64], [85, 32]], style: 'green', count: 2, speed: 22, during: [3] },
      { along: [[57, 24], [43, 24]], style: 'green', count: 2, speed: 14, during: [3] }
    ] };

  // Without a network every shop's bank needs a line to every bank (9 lines). With one, each needs a single line (6).
  const L = [30, 54, 78], X1 = 27, X2 = 73;
  const web = [], webIds = [];
  L.forEach((ly, i) => L.forEach((ry, j) => {
    const id = 'w' + i + j; webIds.push(id);
    web.push({ id, shape: 'line', from: [X1, ly], to: [X2, ry], style: 'thin' });
  }));
  const network = { type: 'diagram', view: [100, 96],
    parts: [
      { shape: 'text', x: 15, y: 8, text: "SHOPS' BANKS" },
      { shape: 'text', x: 85, y: 8, text: "CUSTOMERS' BANKS" }
    ].concat(
      L.map((ly, i) => ({ id: 'l' + i, shape: 'rect', x: 4, y: ly - 8, w: 23, h: 16, style: 'thin' })),
      L.map((ly, i) => ({ id: 'r' + i, shape: 'rect', x: 73, y: ly - 8, w: 23, h: 16, style: 'thin' })),
      web,
      [
        { id: 's0', shape: 'line', from: [X1, 30], to: [40, 49], style: 'blue', hidden: true },
        { id: 's1', shape: 'line', from: [X1, 54], to: [36, 54], style: 'blue', hidden: true },
        { id: 's2', shape: 'line', from: [X1, 78], to: [40, 59], style: 'blue', hidden: true },
        { id: 's3', shape: 'line', from: [60, 49], to: [X2, 30], style: 'blue', hidden: true },
        { id: 's4', shape: 'line', from: [64, 54], to: [X2, 54], style: 'blue', hidden: true },
        { id: 's5', shape: 'line', from: [60, 59], to: [X2, 78], style: 'blue', hidden: true },
        { id: 'hub', shape: 'circle', x: 50, y: 54, r: 14, style: 'accent', hidden: true, text: 'NETWORK' }
      ]),
    steps: [
      { note: 'Every pair needs its own link' },
      { hide: webIds, show: ['s0', 's1', 's2', 's3', 's4', 's5', 'hub'], note: 'One network joins its members' }
    ] };

  // Your bank says yes and holds the amount for the shop. The shop has not been paid yet.
  const decide = { type: 'diagram', view: [100, 96],
    parts: [
      { shape: 'text', x: 50, y: 6, text: 'YOUR ACCOUNT' },
      { id: 'a1', shape: 'text', x: 50, y: 18, text: 'You can spend: 50' },
      { id: 'a2', shape: 'text', x: 50, y: 18, text: 'You can spend: 30', hidden: true },
      { id: 'acc', shape: 'rect', x: 5, y: 28, w: 90, h: 42, style: 'thin' },
      { id: 'cash', shape: 'rect', x: 8, y: 31, w: 84, h: 36, style: 'green' },
      { id: 'held', shape: 'rect', x: 58, y: 31, w: 34, h: 36, style: 'accent', hidden: true },
      { id: 'n50', shape: 'text', x: 50, y: 49, text: '50' },
      { id: 'n30', shape: 'text', x: 33, y: 49, text: '30', hidden: true },
      { id: 'n20', shape: 'text', x: 75, y: 49, text: '20', hidden: true },
      { id: 'tag', shape: 'text', x: 75, y: 79, text: 'Held for the shop', hidden: true },
      { id: 'inn', shape: 'text', x: 50, y: 89, text: 'Shop not paid yet', hidden: true }
    ],
    steps: [
      { note: 'You can spend 50' },
      { show: ['held', 'a2', 'n30', 'n20', 'tag'], hide: ['a1', 'n50'], note: 'Yes: 20 held for the shop' },
      { show: ['inn'], note: 'The shop is not paid yet' }
    ] };

  // The quick yes/no, then a long gap before the money moves bank to bank.
  const later = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'line', shape: 'line', from: [10, 26], to: [22, 26], style: 'ink' },
      { id: 'far', shape: 'line', from: [22, 26], to: [92, 26], style: 'thin', dash: true, hidden: true },
      { id: 'p1', shape: 'circle', x: 10, y: 26, r: 4.2, style: 'spark' },
      { id: 'p2', shape: 'circle', x: 22, y: 26, r: 4.2, style: 'green' },
      { shape: 'text', x: 10, y: 12, text: 'TAP' },
      { shape: 'text', x: 23, y: 12, text: 'YES' },
      { shape: 'text', x: 16, y: 40, text: 'About 2 sec' },
      { id: 'nd', shape: 'text', x: 66, y: 40, text: '1 to 3 working days', hidden: true },
      { id: 'yb', shape: 'rect', x: 3, y: 62, w: 40, h: 26, style: 'thin', text: 'YOUR BANK' },
      { id: 'sb', shape: 'rect', x: 57, y: 62, w: 40, h: 26, style: 'thin', text: "SHOP'S BANK" },
      { id: 'trail', shape: 'arrow', from: [30, 52], to: [66, 52], style: 'thin', dash: true, hidden: true },
      { id: 'coin', shape: 'circle', x: 23, y: 52, r: 6, style: 'accent', hidden: true, text: '20' }
    ],
    steps: [
      { note: 'Tap, then yes, in about 2 sec' },
      { show: ['far', 'nd', 'coin'], note: 'Payments are added up in batches' },
      { show: ['trail'], move: { coin: [54, 0] }, note: 'The shop is finally paid' }
    ] };

  window.EXPLAINER = {
    id: 'card-payment',
    title: 'How does a card tap move your money to a shop?',
    kind: 'full',
    theme: 'money',
    cards: [
      { type: 'card', title: 'You tap, it beeps, and you walk away.',
        text: "Tapping your card feels like paying, but the money doesn't move yet. The card reader, the machine you tap on, only sends a short message asking your bank: can this card pay? So how does that message find your bank and come back with a yes?",
        visual: tap },
      { type: 'card', title: 'The message travels through four places',
        text: "The card reader sends the message to the shop's bank, where the shop keeps its money. That bank passes it to a card network, a company such as Visa that connects banks. The network passes it to your bank, where you keep your money. Your bank answers yes or no, and the answer travels back the same way. So why doesn't the shop's bank just ask your bank itself?",
        visual: hops },
      { type: 'card', title: 'One network saves banks from linking to each other',
        text: 'A link is a line a message can travel along. Picture 10 banks that must all reach each other. Joining every pair needs 45 links. With a network in the middle, each bank needs only one link to it: 10 in all. Real life has thousands of banks, so the network saves a huge number of links. At last the message reaches the bank that knows your account, so what does it do?',
        visual: network },
      { type: 'card', title: 'Your bank checks two things, then sets money aside',
        text: "A computer at your bank checks two things: is the card real, and is there enough money in your account? If both answers are yes, the bank sets the price aside. The money stays in your account for now, but you can't spend it twice. Say you pay 20 from 50: you can spend only 30. So when does the shop get paid?",
        visual: decide },
      { type: 'card', title: 'The shop gets its money later, all at once',
        text: "Moving money for every single tap would be slow and expensive. So banks collect many payments, add them up, and move the money all at once. The shop gets its money 1 to 3 working days after your tap. Weekends don't count.",
        takeaway: 'The tap is a yes today; the money follows later.',
        visual: later },
      { type: 'more', links: ['gps'], note: 'Another thing that feels instant but takes a trip: your phone finding where you are.' }
    ]
  };
})();
