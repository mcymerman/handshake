# Phase 1 — Individual memos

Fourteen memos, one per agent, written before anyone had seen the others.
Each is under 300 words. Numbers marked **[Assumption]** are guesses to be tested,
not facts. These are first positions; several changed in Phase 2 and 3, and the
final calls live in `../00_decisions.md`.

---

## 1. Manager / Project Lead

**Opportunities**
- One simple mechanic (say six digits, swap six digits) that nobody owns yet. If it feels like magic in the first 10 seconds, the rest is details.
- A real pilot is cheap: three venues, one neighbourhood, 8 weeks, one small server.
- Privacy is the product, not a feature. That gives us a clear filter for every decision.

**Risks**
- Fourteen people, thirteen deliverables, one working app. Scope creep is the biggest risk I can see.
- Groups, reveals, venues and payments all at once could bury the core handshake.
- We could build something we're proud of that nobody uses twice.

**What I need from others**
- Developer: a staged build with a working demo at every gate, not a big reveal at the end.
- Cynic: a ranked kill list, not a cloud of worries.
- Data: three or four numbers that tell us go or stop after the pilot, agreed *before* it starts.
- Everyone: label your guesses. I'd rather see "[Assumption] 30%" than a confident wrong fact.

---

## 2. Business Development

**Opportunities**
- Conferences are the fastest door. Organisers already pay for "networking apps" that attendees ignore. A spoken code works in a hallway with no download. [Assumption] 40 mid-size events (500–3,000 people) in our first metro per year.
- Coworking chains and climbing gyms have members who meet strangers weekly and want a low-risk way to stay in touch.
- Dating venues (speed-dating nights, singles events) are an obvious fit and pay well. I'd want one in the pilot.

**Risks**
- Event apps (Whova, Brella) are entrenched; we must sell as an add-on, not a replacement.
- A single bad press story ("app used to stalk") would close doors with every venue at once.
- Long sales cycles at large events: 3–6 months.

**What I need from others**
- Sales: a one-page conference pitch with a live demo that works on venue Wi-Fi.
- Finance: a price ladder by attendance so I can quote on the spot.
- Legal: a short, readable venue agreement. No 20-page contract for a cafe.
- Community: two warm intros to venue owners in the pilot neighbourhood.

---

## 3. Cynic

**Opportunities**
- I'll be honest: the idea is better than most. Swapping six spoken digits is faster than "what's your Instagram?" and less awkward than a phone number.
- The privacy line is a real differentiator, *if* it is literally true.

**Risks**
- Four digits per zone is 10,000 codes. That is guessable. Someone will script it.
- A venue zone posted on a table tent can be photographed and used from home.
- Invite links get forwarded. That is what links do.
- Groups up to 8 with anonymous members is a harassment room waiting to happen.
- "Unique per zone" plus 60-second expiry means people will fumble codes under bar noise.
- Network effect cuts both ways: if your new friend doesn't have it open, the moment dies.
- Dating venues bring the highest-risk users first.

**What I need from others**
- Security: a number for how long a script takes to hit a live code, with our rate limits.
- T&S: what happens in the first hour after a harassment report, step by step.
- Data: proof that people come back, not just that they connect.
- Everyone: be ready to cut. I'll publish a kill list after Phase 2.

---

## 4. Developer

**Opportunities**
- Rails 8 gives us Solid Queue and Solid Cable on Postgres. One database, one VM, no Redis to babysit for a pilot.
- Hotwire means a no-install mobile web page that updates live without a JavaScript framework.
- The handshake engine (claim, match, consume) is one well-tested service object. The add-in flow can reuse it.

**Risks**
- Real-time chat over Postgres polling is fine at pilot scale but not forever. [Assumption] ceiling around 1,000 concurrent sockets.
- Hashing codes means we can't look one up by prefix; uniqueness checks must use the HMAC of "zone:digits".
- Three-pair codes are tight. I'd like a fourth pair (1,000,000 per zone) for safety margin.
- Invite links add a whole token lifecycle for a feature we may never turn on.

**What I need from others**
- Security: the exact HMAC scheme and which keys live in credentials.
- Tester: the must-pass list early, so I write the code to it.
- UX: final screen list before Stage 3, so I don't rebuild views twice.
- Manager: a hard "not in MVP" list.

---

## 5. Tester / QA

**Opportunities**
- The rules are crisp (expiry, single-use, typo doesn't burn, mutual entry). Crisp rules make great tests.
- Time-based logic can be tested exactly with Rails' `travel_to`.
- A system test that drives two browsers through a real handshake is the best demo we'll have.

**Risks**
- Timing edge cases: entry at 59.9 s, 69.9 s, 70.1 s. Clock skew between phone and server.
- Race: two people entering the same code in the same second.
- Silent leaks: codes or zones appearing in logs. Nobody notices until it's too late.
- Real-time tests are flaky in CI if we're not careful with waits.

**What I need from others**
- Developer: a test-friendly clock and a single place where codes are generated.
- Security: a list of strings that must never appear in logs, so I can grep for them in tests.
- Manager: agreement that we report failing tests honestly, never skip them quietly.
- [Assumption] Minitest + Capybara headless Chrome; ~150 tests at MVP, under 3 minutes in CI.

---

## 6. Sales

**Opportunities**
- The demo sells itself: two phones, six digits each, chat open in under 15 seconds.
- Conference organisers measure "connections made". We can give them a count without giving them anyone's data, which is rare.
- Venues want repeat visits. "Meet people here" is a story they can tell.

**Risks**
- "Why not just use WhatsApp?" will be the first objection every time.
- Venue owners are busy; if setup takes more than 10 minutes, we lose them.
- Counts-only dashboards may feel thin to buyers used to lead-capture tools.

**What I need from others**
- Marketing: a one-line answer to "why not WhatsApp?"
- Finance: three simple venue tiers, not a calculator.
- UX: a table tent a cafe would actually leave out.
- BizDev: which conference to target first and who decides there.
- [Assumption] Close rate 1 in 5 venue pitches, 1 in 8 conference pitches in year one.

---

## 7. Marketing

**Opportunities**
- A story people can retell: "We swapped codes instead of numbers." Word of mouth is the channel.
- Privacy fatigue is real. "No ads, no location history, nothing to download" lands in one breath.
- Stickers and table tents are cheap media: [Assumption] $0.40 per tent, $0.08 per sticker.

**Risks**
- The name "Handshake" is crowded (a large careers app already uses it). Trademark and search trouble.
- Privacy claims we can't literally keep would be worse than no claims.
- "Meet strangers" can read as dating, which scares some venues off.

**What I need from others**
- Legal: a trademark scan on three name options.
- Privacy: the exact privacy sentence I'm allowed to print.
- Community: venue photos (with permission) for pilot materials.
- Data: a referral signal I can measure without tracking people.

---

## 8. UX / Product Designer

**Opportunities**
- The code screen can be one screen: big digits, a countdown ring, one input. Nothing else.
- Saying "forty-seven, twelve, eighty-three" is natural. Pairs are easier to hear than six single digits.
- Per-chat aliases ("Teal Otter") make anonymity feel friendly, not cold.

**Risks**
- 60 seconds feels short when your friend is typing in a loud bar.
- Approvals, reveals and groups could turn a chat app into a settings app.
- If a typo locks you out, people will blame the app, not themselves.
- Phones at 390 px wide: the code must fit large without wrapping.

**What I need from others**
- Developer: a grace period server-side so a code typed at 59 s still works.
- T&S: the minimum wording for report and leave, so it's calm, not scary.
- Marketing: voice guide (warm, short, no jargon).
- Community: what staff will actually say when handing out tents.
- [Assumption] Target: handshake complete in under 20 seconds for 80% of pairs.

---

## 9. Privacy & Security Architect

**Opportunities**
- We can make the privacy promise structurally true: the server never receives exact location, and the zone lives only on a short-lived code.
- HMAC-SHA256 with a server key means a stolen database doesn't reveal live codes.
- Anonymous device tokens (store only a SHA-256) mean there's no account to breach.

**Risks**
- 10,000 codes per zone. With no limits, a script tries all of them in minutes. With 30 tries/min per device and an 8-failure lockout, one device needs days. Botnets change that; zone-wide pause is the backstop.
- Venue codes used remotely. A static zone number is a public secret.
- IP addresses are personal data. Rate limiting needs them, briefly.
- Logs are the classic leak. Default Rails logs params.
- Invite links: forwardable, screenshot-able, bearer tokens. I won't sign off for MVP.

**What I need from others**
- Developer: `filter_parameters` covering code, digits, zone, cell, body, and a test proving it.
- Legal: confirmation that hashed IPs held under 5 minutes are acceptable.
- UX: a way for the phone, not the server, to round location.
- Cynic: keep pushing on the venue-code abuse case.

---

## 10. Legal & Compliance

**Opportunities**
- Collecting almost nothing is the cheapest compliance strategy there is. No accounts, no location history, short retention.
- A plain-English privacy notice can be a marketing asset.

**Risks**
- Minors. A chat with strangers needs an 18+ gate; self-declaration is weak but standard for an MVP. [Assumption] acceptable for pilot with venue age checks at the bar.
- GDPR/CCPA: even a coarse location cell is personal data at the moment of use. We need a lawful basis and a deletion story.
- Reports with message evidence are sensitive. Who sees them, for how long?
- Trademark on "Handshake".
- Venue liability if a meeting there goes badly.

**What I need from others**
- Privacy: a data map: every field, how long it lives, who can see it.
- T&S: retention period for reports. I'd propose 90 days.
- Marketing: every public claim sent to me before it's printed.
- BizDev: venue agreements kept to two pages.

---

## 11. Trust & Safety

**Opportunities**
- Mutual entry means nobody can cold-message anyone. That removes most spam at the root.
- Leaving with no "block drama" lowers the cost of getting out of a bad chat.
- Venues give us a physical context: staff can help in person.

**Risks**
- Groups: a person can be outnumbered. Seven people approving the eighth, who is a friend of nobody.
- Anonymous reports with no evidence are hard to act on; reports with evidence leak conversations.
- Someone pressures another person to reveal their phone number.
- Ban evasion: a suspended device clears cookies and comes back.

**What I need from others**
- UX: report and leave reachable from every chat screen in one tap.
- Developer: device suspension that stops new codes immediately.
- Legal: a written policy for evidence handling.
- Data: incident rate per 1,000 chats, reported weekly.
- [Assumption] 1–3 reports per 1,000 chats in the pilot.

---

## 12. Finance Analyst

**Opportunities**
- Running costs are tiny at pilot: [Assumption] $24/month VM plus $15–50 managed Postgres. Under $100/month all-in.
- Event licences could cover a year of hosting with one sale.
- Premium at $5/month needs only ~20 subscribers to pay for the servers.

**Risks**
- Freemium conversion for social apps is low. [Assumption] 1–3% of monthly active users.
- Venue churn: small cafes cancel at the first slow month.
- Free core handshake means growth costs money before it makes money.

**What I need from others**
- Sales: realistic close rates and deal sizes.
- Data: monthly active users and retention curves from the pilot.
- BizDev: one signed event licence to anchor the model.
- Manager: agreement that the 18-month model shows a downside case, not only the hopeful one.

---

## 13. Community & Venue Partnerships Lead

**Opportunities**
- Climbing gyms have built-in rituals (belay partners, bouldering sessions). A "Zone 23 — Wednesday night bouldering" tent fits naturally.
- Cafes with long tables and regulars are ideal first-meeting places.
- Staff are our best onboarding: a barista saying "swap codes, not numbers" beats any ad.

**Risks**
- Staff turnover. The person we trained leaves in a month.
- Tents get lost, coffee-stained or nicked. [Assumption] 30% replacement per month.
- Bars are loud and late; we'll get the most use and the most incidents there.

**What I need from others**
- UX: a tent that works without staff explaining it.
- Finance: a founding-venue price that's easy to say yes to.
- T&S: a one-page "what to do if a guest reports a problem" card for staff.
- Data: a weekly venue report I can hand to an owner in two minutes.

---

## 14. Data & Growth Analyst

**Opportunities**
- We can measure what matters without tracking people: counts per chat, per zone, per day.
- The best signal is a second conversation: messages on two or more separate days. That's a friendship, not a fumble.
- Groups forming is a viral loop we can count directly.

**Risks**
- Privacy limits our data. No user IDs across chats, no funnels per person. That's correct, but it means we must design metrics up front.
- Small numbers at three venues make results noisy. [Assumption] 50–150 handshakes per venue per week.
- Vanity metrics (page loads, codes shown) will look great and mean nothing.

**What I need from others**
- Developer: aggregate counters written at the moment of each event (handshake, group formed, reveal step), with no identities.
- Manager: agreement on go/no-go thresholds before week 1.
- Community: weekly venue footfall estimates so we can see adoption rate.
- Legal: sign-off that per-chat "days with messages" counters are fine if deleted with the chat.
