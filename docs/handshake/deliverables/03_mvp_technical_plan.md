# 3. MVP technical plan

Owner: Developer, with the Privacy & Security Architect and Tester. Built and
running in `handshake/` (Rails 8.1.4.1, Ruby 4.0.10, PostgreSQL 16).

## Architecture

```
 Phone (any modern browser, no install)
   │  HTTPS: Turbo Drive / Frames / Streams + Stimulus (importmap, no JS build)
   │  WSS:   Action Cable (ParticipantChannel, ChatThreadChannel)
   ▼
 Puma (Rails 8.1) ── Rack::Attack (rate limits, lockouts; in-memory counters)
   │        └─ Solid Queue workers inside Puma (purges, expiry)
   ▼
 PostgreSQL 16: app tables + solid_queue_* + solid_cable_messages + solid_cache_entries
```

| Decision | Choice | Why | Rejected |
|---|---|---|---|
| Real-time transport | Solid Cable (Postgres) | No extra service to run, secure or pay for. 100 ms polling is fine for a pilot. | Redis: a second stateful service on day one, for scale we don't have yet. Switching later is one line in `cable.yml`. |
| Jobs | Solid Queue in Puma | Same database, recurring schedule built in, one process to deploy | Sidekiq, which needs Redis |
| Tests | Minitest | Rails default, parallel, system tests with real Chrome and real Action Cable, no extra framework | RSpec: more ceremony, same coverage |
| Front end | Hotwire, importmap, plain CSS | No-install web first, fast on phones, nothing to build | A SPA framework: heavier, and needs a build step |
| Identity | Signed httpOnly device cookie, SHA-256 in the database | Anonymous by default, no email or phone | Magic links: they need an email, which breaks the promise |
| Code storage | HMAC-SHA256 (server key) of "zone:digits" | 10,000 possible codes per zone can't be protected by a plain hash; a keyed hash can | Plain SHA-256 (brute-forced in milliseconds), or storing plaintext |
| Ids | uuid everywhere | Never reveals how few users there are | Counting-up integer ids |

## Core algorithms

- **Issue:** draw 4 digits with `SecureRandom.random_number(10_000)` and retry
  if any code in the zone (live or not yet purged) has the same digest. A
  unique index on `(zone_number, digest)` backs this up.
- **Enter:** parse to `[zone, digits]`, check the zone against your zone and
  its neighbours, then look up by digest. The outcome is one of: typo (counted
  toward the lockout), expired (not counted), used (owner alerted), own code,
  or a claim.
- **Match:**
  1. Lock both people's rows in id order, so two simultaneous entries can't
     miss each other.
  2. If the other person already claimed any of your live codes, it's a match:
     consume both codes.
  3. Two personal codes open a new chat. A personal code plus an add-in code
     sends a join request to the group.
  4. Otherwise, if someone else already claimed this code, it's an
     eavesdropper: cancel the code and alert the owner.
  5. Otherwise, record a claim and wait.
- **Approval:** the voters are every member except the proposer (whose yes is
  implicit, for add-in codes only; a group-handshake opener votes) and the person being removed.
  - Unanimous: any "no" rejects the request; all "yes" approves it.
  - Majority: approved when yes × 2 > total; rejected when no × 2 ≥ total.
  - Any member: the proposer's yes is enough.
  - Requests time out after 10 minutes (removals after 1 day).
- **Ordering:** each message takes `last_seq + 1` under a row lock on the
  chat. The browser sorts by `data-seq`. Turbo de-duplicates by DOM id.
- **Expiry:** queries hide expired chats and codes immediately. Jobs delete
  them: codes every minute, chats every 10 minutes, reports at 90 days,
  idle devices at 30 days.

## Data model (as built)

participants · venues · zones · handshake_codes · code_claims · chat_threads ·
memberships · membership_proposals · proposal_votes · messages ·
reveal_grants · reports · venue_daily_counts · daily_metrics (field-level
detail in `handshake/README.md#data-model` and `handshake/db/schema.rb`).

Changes from the brief's suggested model:
- JoinRequest and JoinApproval became **membership_proposals** and
  **proposal_votes**, covering both adding and removing.
- Area zones are not stored (they're computed from the rounded cell).
- **code_claims** was added: it's the "one side has typed" record that makes
  the handshake mutual.
- A per-chat random alias lives on **memberships**, so nobody can be linked
  across chats.

## Security controls (summary; full threat model in 04)

- Rack::Attack:
  - 30 entries a minute per device, 60 per IP
  - 8 failures in 5 minutes locks the device for 5 minutes
  - 60 failures a minute pauses the zone for 2 minutes
- Strict CSP with nonces and no inline styles, CSRF, `force_ssl` with HSTS,
  host authorization and a permissions policy.
- Log filtering: parameters, SQL values, the request line and Action Cable.
- Active Record Encryption for messages, reveal details and report text.
- Channel authorization on every subscribe; removed members are disconnected.

## Prioritized backlog (after the prototype)

| # | Item | Why now | Size |
|---|---|---|---|
| 1 | Run CI on GitHub and a first Render staging deploy | Prove the deploy path end to end | S |
| 2 | Legal review of terms and privacy copy; age-gate wording | Required before any public pilot | M (external) |
| 3 | Web push notifications (opt-in) for new messages and approval requests | Biggest retention risk: chats go quiet when tabs sleep | M |
| 4 | Staff-only "display token" separate from the dashboard link | The live tent display currently uses the staff link | S |
| 5 | Region prefix or per-metro deployments | Needed before a second city | M |
| 6 | One-tap "How was it?" after a chat ends (aggregate only) | Pilot learning without tracking | S |
| 7 | Premium plan with Stripe: longer chats, more chats, 12-person groups | Revenue test from month 4 | L |
| 8 | Event mode: organizer dashboard, bulk zones per room, zone splitting above ~300 live codes | Conference revenue line | M |
| 9 | Optional account (passkey) to keep chats across devices (`Participant#upgrade!`) | Users switching phones | M |
| 10 | Verified-human badge via a third-party ID check (yes/no only) | Safety and trust ask from venues | L (vendor) |
| 11 | Shared rate-limit store when running more than one server | Scale | S |
| 12 | Invite links: only with Cynic and Security sign-off and pilot evidence | Deliberately last | M |
