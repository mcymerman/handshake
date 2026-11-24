# Phase 3 — Working sessions

Six sessions, each with attendees, agenda, the disagreement, the resolution,
and what was recorded. Every decision here matches `../00_decisions.md`, which
is where these sessions ended up. Nothing here is approved by Michael; these are
the team's recommendations for his review.

---

## Session 1 — Architecture, data model and threat model

**Attendees:** Developer, Privacy & Security Architect, Tester/QA

**Agenda**
1. Real-time transport: Solid Cable or Redis
2. Background jobs
3. How codes are stored and matched
4. Data model
5. Threat model headlines
6. Test framework

**The disagreement**

*Real time.* The Developer opened for Solid Cable. Tester pushed back: "Postgres polling at 100 ms will feel laggy in system tests, and Redis is what everyone knows." Security sided with the Developer: "Every extra service is another place data can sit. Redis keeps messages in memory we don't control and adds a second thing to back up, patch and lock down."

*Code storage.* The Developer first proposed bcrypt for codes. Security: "bcrypt is salted per row, so you can't look a code up. You'd scan every live code on every entry. Use HMAC-SHA256 with a server key over 'zone:digits': deterministic, so it's indexable, and useless without the key."

*Test framework.* Tester proposed RSpec "because the matchers read nicely". The Developer argued for Minitest: "It ships with Rails, system tests and Action Cable test helpers work out of the box, there's one less gem set to keep current, and the brief wants a test report people can read. Plain assertions are easier to explain than a DSL."

**Resolution**
- Solid Cable wins for the pilot: one database, nothing extra to run or secure, latency of roughly 100 ms is fine for chat. Redis is the documented upgrade path past ~1,000 concurrent sockets [Assumption]. Tester accepted on condition that system tests wait on content, not on time.
- HMAC-SHA256 wins, unanimously.
- Tester conceded on Minitest: "Fewer moving parts, and `travel_to` covers everything I need for time."

**Decisions recorded**
1. Action Cable over **Solid Cable** (Postgres). Redis only past ~1k concurrent sockets [Assumption].
2. **Solid Queue** with recurring tasks: purge codes every minute, expire proposals every minute, purge expired chats every 10 minutes, purge old reports and idle devices daily.
3. Codes stored as HMAC-SHA256(server key, "zone:digits"). Never plaintext in the database, never logged. The plaintext lives only in the owner's encrypted session cookie so a reload shows the same code.
4. Code format `ZZ-PP-PP`: zone 10–99, four random digits from SecureRandom, unique among live codes in the zone. 60 s on screen, 10 s server grace.
5. Mutual match: A's entry of B's code creates a pending claim; B entering any live code of A completes the match. A claim alone does nothing.
6. Typo = failed attempt, burns nothing. Expired = "ask for the new one", not a failure.
7. Eavesdropper: a second, different person entering your code cancels it, issues you a fresh one and alerts you. A late entry of an already-used code also alerts the owner.
8. Device identity: random token in a signed, httpOnly, secure cookie; the database stores only its SHA-256.
9. Rate limits (Rack::Attack): 30 entries/min per device, 60/min per IP; 8 failures in 5 minutes locks the device for 5 minutes; 60 failures/min in a zone pauses the zone for 2 minutes. IPs appear only hashed, inside these short windows.
10. Data model: Participant, Zone, HandshakeCode, ChatThread, Membership, JoinRequest, JoinApproval, Message, RevealGrant, Venue, Report.
11. Messages and reveal details encrypted at rest (Active Record Encryption); order by per-chat sequence number.
12. `filter_parameters` covers code, digits, zone, cell, message body and reveal fields. A test greps the log for leaks.
13. **Minitest** + Capybara headless Chrome: ships with Rails, built-in channel and system test helpers, fewer dependencies, plain assertions that read well in the test report.

**Open items**
- Exact Solid Cable socket ceiling on a 2 GB VM: measure in Stage 9, don't guess.
- Key rotation procedure for the HMAC key (live codes last 70 s, so rotation is cheap; write it down).

---

## Session 2 — Pilot materials and onboarding

**Attendees:** UX/Product Designer, Marketing, Community & Venue Partnerships Lead

**Agenda**
1. The table tent
2. First-visit onboarding
3. How remote use of a venue code is stopped
4. Themed zones

**The disagreement**

Marketing wanted the tent to lead with the brand and a tagline. UX disagreed: "Nobody reads a tagline from across a table. The zone number and one instruction must be the biggest things on it." Community added the venue view: "Owners will bin anything that looks like an ad. It has to look like it belongs on the table, like the wifi card."

On remote abuse, Community wanted a fixed zone printed once: "Reprinting tents costs me a visit." Security (consulted by message) and UX held firm on a rotating word. Community: "Then the rotation has to fit a weekly visit, not a daily one."

On onboarding, Marketing wanted a three-screen welcome tour. UX: "One screen. 'I'm 18 or older' and the terms, then straight to your code. Every extra screen is a person who puts their phone away."

**Resolution**
- Tent hierarchy: zone number largest, then "Swap codes, not numbers", then QR, then the table word and "valid this week". Brand small at the bottom. Marketing accepted.
- Table word and QR token rotate **weekly**, matching Community's weekly visit. Venue zones only accept codes during opening hours. A printable version and a live display version (for a screen behind the counter) both exist.
- One-screen onboarding.

**Decisions recorded**
1. Table tent shows: zone number, "Swap codes, not numbers", QR, table word (changed to two words, e.g. "maple fox", after the Phase 4 code review), "valid this week", small brand.
2. Table word and QR token rotate weekly. Venue zones are open only during the zone's opening window.
3. Venue zones are numbered 10–49 (admin-assigned); area zones 50–99, from a ~1 km cell rounded on the phone.
4. First visit: one screen, "I'm 18 or older" + terms, then the code screen.
5. Each person gets a random friendly alias per chat ("Teal Otter"), so nobody can be linked across chats.
6. Themed zones: a label plus a time window ("Thursday trivia, 7–10 pm").
7. Staff get a 60-second card: what it is, what to say ("swap codes, not numbers"), what to do if a guest reports a problem.
8. Copy rule: the privacy sentence is printed word for word from the decision sheet. No "age-verified", no "anonymous forever".

**Open items**
- Tent replacement rate (Community guessed 30%/month [Assumption]); track in the pilot.
- Whether a live display version is worth it at the cafe; test in week 1.

---

## Session 3 — Pricing and pitch

**Attendees:** Sales, Finance Analyst, Business Development

**Agenda**
1. Venue tiers
2. Event licence pricing
3. Premium price
4. Pilot commercial terms
5. Pitch order

**The disagreement**

Finance proposed a single venue price of $99/month. Sales: "One price loses both ends. A cafe balks at $99; a conference centre thinks it's a toy." BizDev wanted event licences per attendee ($2 a head). Finance objected: "Per-head invoices get disputed after the event. Bands by attendance are quoted on the spot and never argued about."

On premium, Sales wanted $8 ("people pay for dating apps"). Finance: "We're not a dating app, and we just pushed dating venues back. $5 is the test anchor; we test $4, $6 and $8." The Cynic, sitting in, added: "Don't sell premium features that aren't built. Longer threads and bigger groups are fine to describe as coming; don't take money for them yet."

**Resolution**
- Three venue tiers. Event licence in attendance bands. Premium $5/month as the anchor, with $4/$6/$8 price tests later; no premium billing in the MVP.
- Pilot venues pay a founding rate [Assumption: 50% of list for the 8 weeks] so "willing to keep paying" is a real signal, not a free-trial courtesy.

**Decisions recorded**
1. Venue tiers [Assumption]: $79 / $149 / $299 per month.
2. Event licence [Assumption]: $1,500–$7,500 per event by attendance band.
3. Community and enterprise tiers from $400/month [Assumption].
4. Premium $5/month anchor [Assumption]; test $4, $6, $8 later. Not built for MVP; copy never promises it as available.
5. Core handshake free, always.
6. Pitch order: conferences for early revenue, neighbourhood venues for the pilot, dating and social venues not before month 7.
7. Venue pitch leads with "we never see your guests". The dashboard is counts only; that's a feature.
8. One-line answer to "why not WhatsApp?": "WhatsApp needs your number. This needs six digits that expire in a minute."

**Open items**
- First conference target and decision-maker (BizDev, before week 2).
- Founding-rate level to be confirmed with Michael before any venue is quoted.

---

## Session 4 — Misuse and group policy

**Attendees:** Legal & Compliance, Trust & Safety, Cynic

**Agenda**
1. Approval policy for adding people
2. Removal
3. Proposal timeouts
4. Reports and evidence
5. Retention
6. Invite links

**The disagreement**

T&S wanted unanimous approval locked on, with no other options. The Cynic agreed. Legal argued for flexibility: "A conference team of eight will find unanimous approval annoying, and annoyed people route around rules. Offer majority and any-member, but keep unanimous as the default." T&S: "Fine, if changing the policy is itself visible to everyone in the chat."

On removal, the Cynic asked: "Can the group vote out the one person who's objecting?" Legal: "Removal uses the same policy as adding, counted among everyone except the target. The target can't veto their own removal, but they can always just leave."

On timeouts, T&S proposed 30 minutes. The Cynic: "A newcomer standing there for 30 minutes waiting to be let in is a pressure tactic. Ten minutes, then it simply lapses." Legal agreed: no silent adds, ever.

On evidence, the session confirmed the Phase 2 concession: opt-in only.

On invite links, the Cynic and Security (by message) were asked for sign-off. **Both declined for the MVP.**

**Resolution**
Unanimous by default, majority and any-member available per thread, policy changes shown to all. Ten-minute proposal timeout. Evidence opt-in. Invite link stays off and unbuilt.

**Decisions recorded**
1. Approval policy per thread: **unanimous (default)**, majority, any member. An add-in sponsor's yes is implicit (they did a face-to-face handshake); a group-handshake opener votes like everyone else (changed after the Phase 4 code review). Any "no" under unanimous rejects.
2. Everyone in the chat is notified of every proposal. Nobody is added silently.
3. Proposals **time out after 10 minutes** and lapse quietly.
4. Removal: any member proposes; same policy as adding, counted among members other than the target.
5. Cap 8 members; pending newcomers count toward the cap.
6. New members see only messages sent after they join. Joining a group never reveals anyone's identity.
7. Leave anytime. In a 1:1, leaving ends the chat for both and deletes it. In a group, the leaver's past messages stay, marked "(left)"; under 2 members, the chat is deleted.
8. Report: reason + optional note. **Evidence opt-in**: the reporter may attach the last 20 messages; off by default.
9. Reports kept 90 days, then purged. Admin can suspend a device (no new codes).
10. **Invite link: designed, off, not built.** Cynic and Security declined sign-off for MVP because links can be forwarded. Revisit with pilot evidence.
11. "For adults" wording only; the 18+ gate is self-declared and we say so.

**Open items**
- Ban evasion by clearing cookies. Accepted as a residual risk for the pilot; the verified-human badge is the later answer.
- Written evidence-handling policy for admins (Legal, before pilot week 1).

---

## Session 5 — Metrics and go/no-go

**Attendees:** Data & Growth Analyst, Manager / Project Lead

**Agenda**
1. What we can measure without tracking people
2. Pilot go/no-go thresholds
3. Venue dashboard rules

**The disagreement**

The Manager wanted a single headline number: total handshakes. Data refused: "Handshakes are the easy part. A thousand handshakes that never talk again is a stop signal dressed as a win. The headline is the second-conversation rate." The Manager: "Then I want a volume floor too, or 40% of 50 chats will look like success."

On reveal step 1, the Manager wanted 40%. Data: "Reveal is a big trust step and many good chats stay anonymous on purpose. 25% is a strong signal; 40% would make us push people to reveal, which T&S would rightly hate."

On safety, the Manager wanted "zero incidents". Data: "Zero is a target we'd hit by not counting. Set a rate, and make 'unresolved' the hard zero."

**Resolution**
Six thresholds, agreed before week 1. All must be met for "go"; missing two or more is "stop or pivot"; missing one triggers a 4-week extension on that metric alone.

**Decisions recorded**
1. Metrics are aggregate counts only, written at the moment of each event. No cross-chat or per-person data.
2. The only per-chat measure is a count of distinct days with messages, deleted with the chat.
3. Venue dashboard: connections and groups per day; counts under 3 shown as **"fewer than 3"**. No identities, ever.
4. **Go/no-go thresholds for the 8-week pilot:**
   - **≥ 600 handshakes total** across the three venues.
   - **≥ 35% second-conversation rate**: chats with messages on 2 or more separate days.
   - **≥ 8% of chats become groups** (3+ members).
   - **≥ 25% of 1:1 chats reach reveal step 1** (first name and photo).
   - **≥ 2 of 3 venues want to continue paying** after the pilot.
   - **≤ 1 serious safety incident per 1,000 chats, with zero unresolved.**
5. Decision rule: all six met = go; one or two missed = iterate (extend those metrics 4 weeks); three or more missed = stop or pivot. (Manager relaxed the Cynic's "two missed = stop" after Data argued two near-misses in week 8 are noise, not failure.)
6. Weekly two-minute venue report for owners (Community), from the same counts.

**Open items**
- Definition of "serious safety incident" (T&S to write before week 1; working draft: any report involving threats, sexual harassment, stalking or a minor).
- Statistical noise at three venues: Data will report ranges, not single numbers.

---

## Session 6 — Final group-add mechanism and defaults

**Attendees:** UX/Product Designer, Developer, Trust & Safety

**Agenda**
1. Which add mechanism is the default
2. Which alternative ships
3. Invite link status
4. Chat expiry and extension
5. Reveal ladder in groups

**The disagreement**

UX favoured Group handshake as the default: "Everyone's together, someone holds up a phone, done. It's the friendliest moment." T&S disagreed: "A multi-use code anyone nearby can enter is the loosest door we have. In a bar, 'nearby' includes strangers. The default should be the tightest door." The Developer backed T&S on effort: "The add-in code reuses the exact handshake engine: same claim, same match, same tests. Group handshake is new code with a new failure mode."

UX conceded the default but held out for Group handshake as the shipped alternative: "Conference teams will want it." T&S agreed, on two conditions: it lasts only 2 minutes, and every joiner still needs approval.

On expiry, the Developer suggested anyone could extend. T&S: "Then one person keeps a chat alive that another wanted to fade." Resolved: everyone must tap "Extend".

**Resolution**
Add-in code is the default. Group handshake ships as the alternative. Invite link stays designed-only.

**Decisions recorded**
1. **Default: add-in code.** A member taps "Add someone", sees a one-time 60 s thread code, and enters the newcomer's personal code (mutual, same engine). Then a proposal goes to the group.
2. **Implemented alternative: Group handshake.** A member opens a 2-minute multi-use group code; anyone nearby who enters it becomes a pending newcomer needing approval.
3. **Invite link: off and not built** (per Session 4).
4. Every chat starts 1:1 and auto-expires in 14 days. "Extend 14 days" needs every member to tap it.
5. Reveal ladder is pairwise inside a chat: step 1 first name + photo, step 2 social handles, step 3 phone. A step shows only when both people chose it; steps go in order. Never granted to a whole group.
6. Report and leave reachable in one tap from every chat screen.

**Open items**
- Whether conference licences should get Group handshake turned up to larger groups (premium/enterprise, after pilot).
- Real-world test of the 2-minute window at the climbing gym in pilot week 2.
