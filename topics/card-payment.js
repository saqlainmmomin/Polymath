// Why isn't the shop paid the moment you tap your card? 4 cards, written spine-first (2026-10-28, tasks/spine-card-payment/):
// the tap only sends a short message asking your bank if the card can pay; the message goes shop's bank -> card network -> your bank and the
// yes comes back in a couple of seconds; the yes takes the amount off what you can spend but the money hasn't reached the shop (a promise to pay);
// banks move money in totals, so the shop is usually paid a few working days later.
// No link counting (45 against 10), no "sets money aside", no "1 to 3 working days", no "about 2 seconds" (facts.md myths). The iOS app draws
// every card natively (ios/Polymath/FlatPay.swift); these web diagrams are simple stand-ins using the text's exact words.
(function () {
  // ---- Card 1: the tap sends a short message asking if the card can pay. ----
  const tap = { type: 'diagram', view: [100, 96],
    parts: [
      { id: 'card', shape: 'rect', x: 4, y: 30, w: 30, h: 20, style: 'spark', text: 'CARD' },
      { id: 'rd', shape: 'rect', x: 56, y: 24, w: 36, h: 32, style: 'thin', text: 'CARD READER' },
      { id: 'msg', shape: 'arrow', from: [74, 24], to: [74, 8], style: 'accent', hidden: true, label: 'Message', labelAt: [98, 6] },
      { id: 'q', shape: 'text', x: 50, y: 78, text: 'CAN THIS CARD PAY?', hidden: true }
    ],
    steps: [
      { note: 'You tap your card' },
      { move: { card: [20, 0] }, show: ['msg', 'q'], note: 'The reader sends a short message: can this card pay?' }
    ] };

  // ---- Card 2: four places in a loop. The message goes out along the accent lane and the yes comes back along the green lane. ----
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
      { restyle: { t: 'ink' }, show: ['o1', 'o2', 'o3'], note: "The message goes to the shop's bank, then a card network, then your bank" },
      { restyle: { yb: 'green' }, show: ['yes'], note: 'Your bank says yes' },
      { restyle: { t: 'green' }, hide: ['o1', 'o2', 'o3'], show: ['b1', 'b2', 'b3'], note: 'The yes comes back the same way' }
    ],
    flows: [
      { along: [[43, 16], [57, 16]], style: 'accent', count: 2, speed: 14, during: [1] },
      { along: [[69, 32], [69, 64]], style: 'accent', count: 2, speed: 22, during: [1] },
      { along: [[57, 72], [43, 72]], style: 'accent', count: 2, speed: 14, during: [1] },
      { along: [[43, 80], [57, 80]], style: 'green', count: 2, speed: 14, during: [3] },
      { along: [[85, 64], [85, 32]], style: 'green', count: 2, speed: 22, during: [3] },
      { along: [[57, 24], [43, 24]], style: 'green', count: 2, speed: 14, during: [3] }
    ] };

  // ---- Card 3: the yes takes the amount off what you can spend; the shop's till stays empty. No numbers. ----
  const decide = { type: 'diagram', view: [100, 96],
    parts: [
      { shape: 'text', x: 32, y: 10, text: 'WHAT YOU CAN SPEND' },
      { id: 'bank', shape: 'rect', x: 4, y: 18, w: 56, h: 34, style: 'thin' },
      { id: 'full', shape: 'rect', x: 8, y: 22, w: 48, h: 26, style: 'green' },
      { id: 'less', shape: 'rect', x: 8, y: 22, w: 28, h: 26, style: 'green', hidden: true },
      { id: 'gone', shape: 'rect', x: 36, y: 22, w: 20, h: 26, style: 'accent', hidden: true },
      { id: 'yb', shape: 'text', x: 32, y: 62, text: 'YOUR BANK' },
      { id: 'yes', shape: 'text', x: 32, y: 74, text: "YOUR BANK'S YES", hidden: true },
      { id: 'shop', shape: 'rect', x: 70, y: 18, w: 26, h: 34, style: 'thin', text: 'THE SHOP' },
      { id: 'no', shape: 'text', x: 83, y: 62, text: 'NO MONEY YET', hidden: true }
    ],
    steps: [
      { note: 'This is what you can spend' },
      { hide: ['full'], show: ['less', 'gone', 'yes'], note: 'The yes takes the amount off what you can spend' },
      { show: ['no'], note: "The money hasn't reached the shop yet" }
    ] };

  // ---- Card 4: many taps are added up into totals, and the totals reach the shop a few working days later. ----
  const dots = [];
  for (let i = 0; i < 5; i++) dots.push({ id: 'd' + i, shape: 'circle', x: 8 + i * 6, y: 14, r: 2.4, style: 'spark' });
  const later = { type: 'diagram', view: [100, 96],
    parts: [
      { shape: 'text', x: 20, y: 6, text: 'MANY PAYMENTS' }
    ].concat(dots, [
      { id: 'tot', shape: 'rect', x: 4, y: 26, w: 32, h: 12, style: 'accent', text: 'TOTALS', hidden: true },
      { id: 'days', shape: 'text', x: 66, y: 40, text: 'A FEW WORKING DAYS', hidden: true },
      { id: 'yb', shape: 'rect', x: 3, y: 62, w: 40, h: 26, style: 'thin', text: 'THE BANKS' },
      { id: 'sb', shape: 'rect', x: 57, y: 62, w: 40, h: 26, style: 'thin', text: 'THE SHOP' },
      { id: 'trail', shape: 'arrow', from: [30, 52], to: [66, 52], style: 'thin', dash: true, hidden: true },
      { id: 'coin', shape: 'circle', x: 23, y: 52, r: 6, style: 'accent', hidden: true, text: 'TOTALS' }
    ]),
    steps: [
      { note: 'Many taps' },
      { hide: dots.map(d => d.id), show: ['tot'], note: 'Banks add many payments up into totals' },
      { show: ['days', 'trail', 'coin'], move: { coin: [54, 0] }, note: 'A few working days later the totals reach the shop' }
    ] };

  window.EXPLAINER = {
    id: 'card-payment',
    title: "Why isn't the shop paid the moment you tap your card?",
    kind: 'full',
    theme: 'money',
    cards: [
      { type: 'card', title: 'You tap, it beeps, and you walk away.',
        text: 'Tapping your card feels like paying. But the card reader only sends a short message asking your bank if this card can pay.',
        hook: 'So where does that message go before it comes back with a yes?',
        visual: tap },
      { type: 'card', title: "The message goes to the shop's bank, then a card network, then your bank",
        text: "The reader's message reaches the shop's bank. That bank passes it to a card network, a company such as Visa or Mastercard that links banks. The network passes it to your bank, which answers yes or no. The answer travels back the same way, in a couple of seconds.",
        hook: 'So when your bank says yes, does the shop get the money?',
        visual: hops },
      { type: 'card', title: "Your bank's yes is a promise to pay, and the money hasn't reached the shop yet",
        text: "Your bank checks that the card is real and that you have enough money or credit. If so, it takes that amount off what you can spend straight away. So you can't spend the same money twice. But the money hasn't reached the shop yet.",
        hook: 'So why does the shop have to wait to be paid?',
        visual: decide },
      { type: 'card', title: 'Banks move money in totals, so the shop is usually paid a few working days later',
        text: "Banks don't move money for every single tap. They gather many payments and add them up, and the shop's bank is paid in totals. So the shop is usually paid a few working days after your tap.",
        takeaway: 'The yes comes back in seconds, and the shop is usually paid a few working days later.',
        visual: later },
      { type: 'more', links: ['gps'], note: 'The shop gets a little less than you paid, because a small fee is shared among your bank, the card network and the shop\'s bank. The fee that goes to your bank is called the interchange fee.' }
    ]
  };
})();
