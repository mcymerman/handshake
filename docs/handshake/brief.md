# Original brief (from Michael's email, Tue Nov 24, 2026 6:11 AM)

Michael's added instructions (conversation, 2026-11-24): "i want a completely functional prototype in addition to what is asked in the prompt. i also want a guide on how to use the system with screenshots." Deliver through the claude-dropbox to be emailed. "work straight through", hourly progress files.

---

# Project Brief: "Handshake" - Private First-Meeting Connection System

## Your Role
You are the Orchestrator of a 14-agent virtual startup team. Take the product idea below from concept to a launch-ready package: designed, built, tested, priced, and marketed. Run the agents as distinct voices, let them disagree, and synthesize their work into clear deliverables, including a working, deployment-ready Ruby on Rails application.

## The Product Idea
Two people who meet in person can start a private conversation without exchanging phone numbers or social handles. Others can then be added to the conversation, with everyone's consent.

### Core mechanic: the spoken code
- Each person's app (or a lightweight web page, no install required) shows a code of three pairs of digits, like 47-12-83.
- First pair (47) = location zone. It comes from a venue (a poster or table tent says "Zone 47") or from a coarse area cell. Never exact GPS.
- Last two pairs (12-83) = a rotating personal code, unique within the zone.
- The code is single-use and expires after about 60 seconds.
- Connection is mutual: both people must enter each other's code within the window. Nobody can start a thread unilaterally.
- A typo does not burn a code. Only a successful match consumes it. If someone else uses your code, the owner gets an alert and a fresh code is issued automatically.
- Neighboring zones are accepted so people on either side of a zone boundary can still connect.
- Failed guesses are rate limited and can briefly lock a zone or device.

### Chat: one-to-one and group threads
Every thread starts as a private one-to-one chat. It can grow into a group (cap: 8 members) through any of these mechanisms (design all three, recommend a default, and implement the default plus at least one alternative):
1. Add-in code (default). Any current member taps "Add someone" and gets a one-time, 60-second, three-pair thread code. The newcomer enters it and also shares their own personal code with that member (mutual handshake, same as the original). Then:
2. Member approval. Before the newcomer joins, existing members are notified and must approve. Default policy: unanimous approval; configurable per thread to "majority" or "any member." Nobody is added silently.
3. Shared-moment invite (alternative). When everyone is together in person, members can open a "Group handshake" that shows a fresh code anyone nearby can enter within 2 minutes. The joiner still needs approval from existing members.
4. Invite link (optional, off by default). A single-use, expiring link, which the Cynic and Security Architect must explicitly sign off on, since links can be forwarded.

Group rules:
- New members see only messages sent after they join.
- Any member can leave at any time. Leaving removes them, and if fewer than 2 members remain the thread dissolves.
- The reveal ladder stays pairwise. In a group, identity reveals (name/photo, social handles, phone number) are granted person-to-person, never to the whole group by default. Joining a group never exposes anyone's identity.
- Any member can propose removing someone; removal requires the same approval policy as adding.
- Group threads still auto-expire (default 14 days, extendable by agreement or premium).

### The reveal ladder (one-to-one)
Each person independently unlocks further steps, and a step unlocks only if both choose it:
1. Chat only (anonymous, auto-expires in 14 days)
2. First name and photo
3. Social handles
4. Phone number
Either person can sever a thread at any time, and it vanishes for both with no block drama.

### Venue codes
Venues (cafes, gyms, bars, coworking spaces, events) display a zone code. Explore rotating venue codes, themed zones ("Thursday trivia night"), time windows tied to opening hours, and a staff dashboard showing connection counts but never identities. Defend against someone using a posted venue code from afar (rotating table-tent codes plus coarse proximity check).

### Privacy promise
We never store location history, never sell data, never run ads. The server receives only a coarse zone at the moment of exchange and discards it once the thread opens or the code expires.

### Monetization (starting hypothesis)
- Core handshake free (protects network effects)
- Premium ($4-8/month): longer threads, multiple personas, more simultaneous threads, larger groups
- Event and conference licensing (likely early revenue driver)
- Venue partnerships ($50-300/month)
- Enterprise and community tiers
- Optional verified-human badge via third-party ID check (yes/no only)

### Rollout hypothesis
Conferences first, then sticker and card drops, then an 8-week neighborhood pilot (one cafe, one climbing gym, one bar), then dating and social venues.

## The Rails Application (Required Deliverable)
[Stack: latest Rails/Ruby, PostgreSQL, Hotwire, Action Cable (Solid Cable or Redis; justify), Solid Queue or Sidekiq; no-install mobile-first web; anonymous signed httpOnly device token; Rack::Attack; SecureRandom codes stored hashed, never logged, server-side expiry; strong params, CSRF, CSP, secure cookies, force_ssl, filtered logs; no location history.]
[Suggested data model: Participant, Zone, HandshakeCode, ChatThread, Membership, JoinRequest, JoinApproval, Message, RevealGrant, Venue, Report.]
[Required features: code with 60 s countdown and auto-refresh; mutual match creates 1:1; real-time chat in order; add-in, approval, leave/remove; pairwise reveal ladder; sever; auto-expiry purge job; report and block-free leave; admin reports with minimal data; venue table tent with rotating code and counts-only staff dashboard; neighbour-zone matching; health check, seeds, demo mode.]
[Deployment checklist: multi-stage non-root Dockerfile, docker-compose, .env.example, database.yml, credentials, asset precompile, Kamal + Render or Fly with steps, bin/setup, migrations, /up, GitHub Actions CI (RuboCop, Brakeman, bundler-audit, tests), backup/log-retention/monitoring notes respecting privacy, README.]
[Testing: Minitest or RSpec (justify); model, request, channel, system tests; must cover code expiry, single-use, typo not burning, eavesdropper, mutual entry, neighbour zones, rate limiting and lockouts, unanimous group join, rejection and timeout, leave and dissolve, pairwise reveal, expiry purge, no location or code values in logs. Report results honestly.]

## The Team (14 Agents)
1 Manager/Project Lead; 2 Business Development; 3 Cynic; 4 Developer; 5 Tester/QA; 6 Sales; 7 Marketing; 8 UX/Product Designer; 9 Privacy and Security Architect; 10 Legal and Compliance; 11 Trust and Safety; 12 Finance Analyst; 13 Community and Venue Partnerships Lead; 14 Data and Growth Analyst.

## How to Run the Team
Phase 1 - Individual memos (<300 words each): opportunities, risks, needs from others.
Phase 2 - Cynic review: challenges every memo; agents respond with mitigations or concede.
Phase 3 - Working sessions (record decisions): Dev+Security+Tester (architecture, data model, threat model); UX+Marketing+Community (pilot materials, onboarding); Sales+Finance+BizDev (pricing, pitch); Legal+T&S+Cynic (misuse, group policy); Data+Manager (metrics, go/no-go); UX+Dev+T&S (final group-add mechanism and defaults).
Phase 4 - Rails build in 9 gated stages.
Phase 5 - Synthesis.

## Deliverables
1 One-page product spec; 2 Working Rails app; 3 MVP technical plan (architecture, data model, prioritized backlog); 4 Threat model and abuse-prevention plan (incl. group-chat abuse); 5 Test plan with top 25 test cases and actual results; 6 UX flow descriptions for all key screens and the venue table tent; 7 Brand and messaging doc with 3 name options and taglines; 8 Go-to-market plan (12 months, channel by channel); 9 Sales kit (conference pitch, venue pitch, objection handling); 10 18-month financial model with assumptions; 11 8-week pilot plan with success metrics and go/no-go threshold; 12 Cynic's final report: top 10 risks with mitigation and residual rating; 13 Executive summary with build/pivot/stop recommendation.

## Rules of Engagement
Be specific (numbers, examples, decisions). Label assumptions. Show disagreement then resolution. Never compromise the privacy promise. Real runnable code, no placeholders in core flows. Honest about anything untested. Distinct professional voices. Make reasonable assumptions and keep going.
