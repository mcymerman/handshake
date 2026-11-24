# Phase 2 — Cynic review

The Cynic read all fourteen memos and challenged each one. Each agent then
replied with either a **mitigation** (here's how we handle it) or a
**concession** (you're right, we change the plan). Five concessions changed the
plan; they are marked **[Plan changed]**.

---

## 1. Manager / Project Lead

**Cynic:** "You say scope creep is the biggest risk, then you accept thirteen deliverables, groups, reveals, venues *and* premium. Which of those can die?"

**Manager (mitigation):** "Premium billing dies for the MVP: we describe it, we don't build it. Accounts are a stub. Anything not on the decision sheet is out by default. The build goes in nine gated stages, each with a demo, so we notice drift within a day, not a month."

---

## 2. Business Development

**Cynic:** "You want a dating venue in the pilot. That's the highest-risk crowd, the most likely press story, and the least representative of 'meet people at a cafe'. If the first incident report comes from a singles night, every cafe on your list goes quiet."

**BizDev (concession) [Plan changed]:** "Fair. One bad story would cost us the venue channel we need most. The pilot stays cafe, climbing gym and a regular neighbourhood bar, with no singles nights. Dating and social venues move to month 7 at the earliest, and only if the pilot safety threshold holds. I'll keep two dating venues warm, not signed."

---

## 3. Cynic (self-review, at the Manager's request)

**Manager:** "Your memo lists seven risks and no numbers. Which one actually kills us?"

**Cynic (concession):** "Retention. Everything else has a technical answer. 'People connect once and never talk again' has no technical answer. I'll rank it first on my list and I'll stop treating the code-guessing risk as fatal if Security shows me the maths."

---

## 4. Developer

**Cynic:** "You want a fourth pair of digits for a million codes per zone. That fixes my guessing worry by making the product worse for every honest user. Eight digits in a loud bar? And it breaks the 'three pairs' story Marketing is already selling."

**Developer (concession) [Plan changed]:** "UX ran it out loud: three pairs is a breath, four pairs is a phone number. Security's numbers show rate limits cover it. We keep 10,000 codes per zone. To compensate: codes live 60 seconds plus 10 seconds of server grace, live codes are unique within the zone, a match needs *both* people to enter codes, and if a second person enters your code it's cancelled and you're alerted. If a zone ever runs above ~2,000 live codes at once [Assumption], we split it rather than lengthen the code."

---

## 5. Tester / QA

**Cynic:** "150 tests in three minutes sounds great until real-time tests flake and someone marks them 'skip'. How do I know the green tick means anything?"

**Tester (mitigation):** "No silent skips. Any skipped or failing test is listed by name in the test report. Time logic uses a frozen clock, not sleeps. Channel tests use Action Cable's test helpers, not a live socket, and only two system tests touch real browsers. The log-leak test greps the actual test log for every code, digit string and zone used in the run."

---

## 6. Sales

**Cynic:** "'Why not WhatsApp?' Your memo asks Marketing for the answer. You're the one in the room. What do you say?"

**Sales (mitigation):** "'WhatsApp needs your number. This needs six digits that expire in a minute. If it goes nowhere, nothing of you is left behind.' I'll also stop pitching counts-only dashboards as a weakness: for a venue, 'we never see your guests' is a selling point, not a gap."

---

## 7. Marketing

**Cynic:** "You want to print 'no location history'. The phone sends a location cell to the server. Isn't that a location?"

**Marketing (mitigation):** "It's a coarse square the phone rounds to about 1 km before sending, turned into a zone number and forgotten. Security and Legal wrote the exact sentence; I print only that sentence, word for word. No 'we don't know where you are', because at the moment of the handshake, roughly, we do."

**Cynic (follow-up):** "And invite links? You wanted a 'share your chat' button for growth."

**Marketing (concession) [Plan changed]:** "Dropped for MVP. A forwarded link breaks 'only people you've met'. Invite links are designed, documented, and off; not built. We'll revisit with pilot evidence."

---

## 8. UX / Product Designer

**Cynic:** "Sixty seconds in a bar. Your friend reads the code, you mishear 'fifteen' as 'fifty', it expires, you both give up. That's the whole product failing in the first minute."

**UX (mitigation):** "Three things. The screen shows 60 seconds, but the server accepts the code for 10 more, so typing at the buzzer still works. A typo burns nothing: you just try again. An expired code says 'ask for the new one', and the new code is already on their screen. Pairs are read as 'forty-seven, twelve, eighty-three', which mishears less than single digits."

---

## 9. Privacy & Security Architect

**Cynic:** "Show me the maths. How long does a script take to hit a live code?"

**Security (mitigation):** "One zone, 10,000 possible codes, say 200 live [Assumption]. Each guess hits with chance 2%. One device: 30 entries a minute, locked for 5 minutes after 8 failures in 5 minutes, so realistically ~8 guesses per 10 minutes. Expect a hit after ~50 guesses: about an hour. And a hit gets them nothing: a match needs the owner to enter *their* code too, and the owner is alerted and gets a fresh code. A botnet trips the zone-wide pause at 60 failures a minute. Guessing yields an alert, not a chat."

**Cynic:** "And the venue table tent photographed and used from home?"

**Security (mitigation):** "The tent carries a table word and QR token that rotate weekly, and venue zones only work during opening hours. A week-old photo is dead. Remote use within the week is possible but still needs a mutual handshake with someone physically there, who can simply not enter your code. Residual risk: low."

---

## 10. Legal & Compliance

**Cynic:** "'I'm 18 or older' is a checkbox. A 15-year-old can tick it."

**Legal (concession, partial):** "True, and we won't claim otherwise. We say 'for adults' in copy, never 'age-verified'. The pilot venues are adult spaces (the bar checks ID at the door; the gym and cafe have mostly adult evening crowds). The optional verified-human badge is a later feature, yes/no only. I'm conceding the claim, not the gate."

---

## 11. Trust & Safety

**Cynic:** "Reports with message evidence leak a private conversation to us. Reports without evidence can't be acted on. Pick one."

**T&S (concession) [Plan changed]:** "Neither, both. The reporter *chooses* to attach the last 20 messages; it's off by default. Reports are kept 90 days, then purged. Without evidence we can still suspend a device after repeated reports. I'd wanted evidence attached automatically; Legal and Privacy were right that it breaks the promise to the other people in the chat."

**Cynic:** "And groups of 8 ganging up on someone?"

**T&S (mitigation):** "Unanimous approval by default, so anyone already in the chat can say no. Anyone can leave in one tap, and joining reveals nothing about anyone. Group-specific policy is on the Legal + T&S + Cynic session agenda."

---

## 12. Finance Analyst

**Cynic:** "Twenty premium subscribers pays for the servers. It doesn't pay for anyone's time. Where's the downside case?"

**Finance (mitigation):** "The 18-month model will carry three cases. The downside case assumes 1% premium conversion, venue churn of 8% a month [Assumption], and only two event licences in year one. If the downside case can't reach break-even on hosting plus one part-time person by month 18, I'll say so in the executive summary."

---

## 13. Community & Venue Partnerships Lead

**Cynic:** "Staff turnover and lost tents. Your plan depends on baristas evangelising a product they've never used."

**Community (mitigation):** "The tent must work with zero staff explanation; that's the test UX is designing for. Staff get a 60-second card, not a training. I visit each venue weekly in the pilot to swap tents (the word rotates weekly anyway) and catch turnover early."

---

## 14. Data & Growth Analyst

**Cynic:** "Your 'second-conversation rate' needs to know which chats had messages on different days. That's tracking."

**Data (concession) [Plan changed]:** "Partly. I'd planned to keep anonymous per-device activity across chats for retention curves. I've dropped that: there's no cross-chat data at all. What remains is a per-chat count of distinct days with messages, deleted with the chat, and aggregate daily counts with no identities. We lose per-person retention curves. We keep the one number that matters."

---

## Concessions that changed the plan

1. **Code space stays 10,000 per zone** (no fourth pair); rate limits, grace window and eavesdropper alerts compensate. *(Developer)*
2. **Invite links not built for MVP**: designed, off, revisit after the pilot. *(Marketing, with Security)*
3. **Dating venues pushed to month 7 at the earliest**, gated on pilot safety. *(BizDev)*
4. **Report evidence is opt-in**, last 20 messages, off by default; reports purged at 90 days. *(T&S)*
5. **No cross-chat analytics**: per-chat day counter only, deleted with the chat. *(Data)*

---

## The Cynic's initial kill list (ranked)

What could kill Handshake, worst first.

1. **Nobody talks twice.** People connect, say "hi", and the chat expires unread. No retention, no business.
2. **Cold start at the moment of meeting.** If the other person doesn't know the product, explaining it kills the moment.
3. **A harassment story in the press.** One incident at a pilot venue, badly handled, ends the venue channel.
4. **Group pile-ons.** Anonymous groups of up to 8 used to gang up on or pressure one person.
5. **Venue churn.** Cafes cancel after one slow month; staff turnover kills evangelism.
6. **Fumbled codes.** 60 seconds, loud rooms, misheard pairs. Friction at the one moment that matters.
7. **Privacy claim not literally true.** One overstated sentence and we're the company that lied about privacy.
8. **Remote venue-code abuse.** Photographed tents used from outside the venue.
9. **Monetisation gap.** Free core, 1–3% premium conversion, event sales take 3–6 months.
10. **Trademark collision on "Handshake".** Renaming after launch costs every printed tent and sticker.
