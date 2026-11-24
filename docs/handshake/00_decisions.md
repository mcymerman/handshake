# Handshake — working decisions (Orchestrator, 2026-11-24)

The shared source of truth for every team document and for the Rails app in
`handshake/`. Label: **[D]** = decided, **[A]** = assumption, **[O]** = open.

## Product mechanics
- [D] Code = `ZZ-PP-PP`. `ZZ` = zone 10–99. `PP-PP` = 4 random digits (SecureRandom), unique among live codes in that zone.
- [D] Personal code lives 60 s on screen; the server accepts it for 10 s more (typing slack). Screen counts down and auto-refreshes.
- [D] Stored as HMAC-SHA256(server key, "zone:digits") — never plaintext, never logged. The plaintext lives only in the owner's encrypted session cookie so a page reload shows the same code.
- [D] Mutual: A enters B's code → a pending "claim". B enters any live code of A → match. A claim alone does nothing.
- [D] Typo (no such code) = failed attempt, burns nothing. Expired code = "ask for the new one", not counted as a failure.
- [D] Eavesdropper: if a second, different person enters your code, the code is cancelled, you get a fresh one and an alert ("Two people entered your code…"). A late entry of an already-used code also alerts the owner. Nobody is connected unilaterally.
- [D] Zones: (1) **Venue zones** 10–49, assigned by admin, entered by scanning the table-tent QR (rotating weekly token) or typing zone + the weekly "table word" (two words since the security review; see the end of this file). Only accepted during the zone's opening window. (2) **Area zones** 50–99: the browser rounds location to a ~1 km grid cell *on the phone*; the server maps the cell to a zone number and its 8 neighbours, then forgets the cell. [A] One pilot metro; multi-metro needs a region prefix later.
- [D] Neighbour matching: a code in zone N is accepted if N is your zone or one of its neighbours (venue zones list neighbours explicitly).
- [D] Rate limits (Rack::Attack): 30 code entries/min per device, 60/min per IP; 8 failed entries in 5 min locks the device for 5 min; 60 failures/min in one zone pauses that zone for 2 min. IPs only ever appear (hashed) inside these short windows.
- [D] Identity: anonymous signed, httpOnly, secure device cookie (random token; DB stores only its SHA-256). Age gate on first visit: "I'm 18 or older" + terms. Account upgrade = stub extension point (`Participant#upgrade!` raises NotImplemented, documented).
- [D] Each person gets a random friendly alias **per chat** ("Teal Otter"), so you can't be linked across chats.

## Chats and groups
- [D] Every chat starts 1:1. Auto-expires in 14 days. "Extend 14 days" needs every member to tap it.
- [D] Cap 8 members (pending newcomers count toward the cap).
- [D] **Default add mechanism: add-in code.** A member taps "Add someone", sees a one-time 60 s thread code, and enters the newcomer's personal code (mutual, same engine). Then a proposal goes to the group.
- [D] **Implemented alternative: Group handshake.** A member opens a 2-minute multi-use group code; anyone nearby who enters it becomes a pending newcomer needing approval.
- [D] **Invite link: designed, OFF and not built.** Cynic + Security Architect declined sign-off for the MVP (forwardable). Revisit with evidence after the pilot.
- [D] Approval policy per thread: unanimous (default), majority, any member. An add-in sponsor's yes is implicit (group-handshake openers vote; see the end of this file). Any "no" under unanimous rejects. Proposals time out after 10 minutes. Everyone is notified; nobody is added silently.
- [D] New members see only messages sent after they join.
- [D] Leave anytime. In a 1:1, leaving = "End chat": it vanishes for both (all rows deleted). In a group, the leaver's past messages stay (shown "(left)"); if fewer than 2 remain the chat is deleted.
- [D] Removal: any member proposes; same policy as adding, counted among members other than the target.
- [D] Reveal ladder is pairwise, inside a chat: 1 first name + photo, 2 social handles, 3 phone. You see a step only when both of you chose it; steps go in order. Group membership never reveals anyone.
- [D] Report: reason + optional note; reporter may *choose* to attach the last 20 messages as evidence (off by default). Reports kept 90 days, then purged. Admin can suspend a device (no new codes).
- [D] Real time: Action Cable over **Solid Cable** (Postgres) — no Redis to run, one database, adequate for pilot scale (polling ~100 ms). Redis is the upgrade path past ~1k concurrent sockets [A].
- [D] Jobs: **Solid Queue** (Postgres) with recurring tasks: purge codes every minute, expire proposals every minute, purge expired chats every 10 min, purge old reports and idle devices daily.
- [D] Messages and reveal details encrypted at rest (Active Record Encryption). Message order by a per-chat sequence number.

## Venues
- [D] Venue page: printable table tent (zone number, QR, table word, "valid this week"), a live display version, and a staff dashboard (connections and groups per day, counts under 3 shown as "fewer than 3"). No identities, ever.
- [D] Themed zones: a zone can have a label and a time window ("Thursday trivia, 7–10 pm").

## Privacy promise (literal)
We never store location history, sell data or run ads. Your phone rounds your location to a ~1 km square before sending it; we turn that into a zone number and forget it. Zone numbers live only on short-lived codes, deleted within about two minutes of expiry or a match. Logs never contain codes, message text, zones or IP addresses.

## Business (assumptions for the docs)
- [A] Premium $5/month (tested $4/$6/$8). Event licence $1,500–$7,500 per event by attendance. Venue $79/$149/$299 per month. Community/enterprise from $400/month.
- [A] Hosting at pilot: one 2 GB VM (~$24/mo) + managed Postgres (~$15–50/mo).
- [A] Pilot: 8 weeks, one cafe, one climbing gym, one bar in a single neighbourhood.
- Working name "Handshake" (trademark-crowded; brand doc must propose alternatives).

## Stack
Ruby 4.0.10 (3.4.9 rejected for CVE-2026-132825), Rails 8.1.4.1, PostgreSQL 16, Hotwire, importmap, Propshaft, plain CSS, Minitest + Capybara/headless Chrome, Kamal + Render.

## Added after Phase 1–3 records (2026-11-24)
- [D] Pilot decision rule: all six thresholds met = **Go**; one or two missed = **Iterate** (extend those metrics 4 weeks); three or more missed = **Stop or pivot**.
- [A] Pilot venues pay a founding rate of 50% of list price (needs Michael's confirmation before quoting).
- [D] Dating venues not before month 7.
- [A] Split a zone if it routinely has more than ~2,000 live codes.
- [D] Copy says "for adults (18+)", never "age-verified".
- [D] Policy changes in a chat are shown to every member as a system message.

## Changed after the Phase 4 security review (2026-11-24)
- [D] Table word is **two words** ("maple fox", about 5,000 combinations), compared forgivingly (case, spaces, dashes). Wrong words are limited per device (8 per 5 minutes) and per network address (20 per hour, then a 15-minute rest).
- [D] Per network address: 30 wrong codes in 10 minutes rests that address for 10 minutes, so one address can't pause a zone with fresh devices.
- [D] Group handshake: the opener's yes is **not** implicit (anyone nearby can enter the code), so the opener votes like everyone else. Under "any one member", a real yes is still needed. Add-in sponsors keep their implicit yes (they did a mutual handshake face to face).
- [D] Turbo's built-in stream channel refuses all subscriptions; only our permission-checking channels can stream.
- [D] Live-delivery copies (Solid Cable) are deleted when a chat ends and purged every minute after 10 minutes. The privacy page says so.
