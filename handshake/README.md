# Handshake

Two people who meet in person start a private chat by saying short codes out
loud, without swapping phone numbers or social handles. Chats can grow into
small groups, but only with everyone's agreement, and they vanish on their own.

This folder is a complete, working Ruby on Rails app: the MVP from the brief,
with tests, Docker, CI and deployment configs. The user guide with
screenshots is in `../docs/handshake/guide/`.

## Contents

1. [Run it](#run-it)
2. [How it works](#how-it-works)
3. [Architecture](#architecture)
4. [Data model](#data-model)
5. [Security and privacy](#security-and-privacy)
6. [Tests](#tests)
7. [Deploy](#deploy)
8. [Operations](#operations)
9. [Known limitations](#known-limitations)
10. [Extension points](#extension-points)

## Run it

You need Ruby 4.0.10 (see `.ruby-version`) and PostgreSQL 14 or newer.

```sh
bin/setup              # installs gems, creates and migrates the database, starts the server
bin/rails db:seed      # pilot venues: a cafe (zone 47), climbing gym (48), bar (21), conference (12, 13)
bin/dev                # http://localhost:3000, with background jobs running inside Puma
```

The seed prints each venue's zone, this week's table word, and its staff link
(in development: `/dash/dev-bean`, `/dash/dev-summit`, `/dash/dev-lantern`,
`/dash/dev-conf`). The conference zone 12 is open around the clock, so it's
the easiest to try.

**Try it alone (demo mode).** Demo mode is on in development. On your code
screen, tap **Try with a demo friend**: a bot has already typed your code, so
type its code and a chat opens. The bot replies, says yes to join requests
and matches your reveal steps. Inside a chat, the menu has **Demo: a
newcomer asks to join** so you can try the approval flow. Turn it on for a
pilot with `DEMO_MODE=true`.

**Try it for real.** Open two different browsers (or one normal window and
one private window), choose zone 12 with the table word from `bin/rails
db:seed`, and swap codes.

**Admin.** Set `ADMIN_PASSWORD` (12+ characters) and visit `/admin` (user
`admin`). Without it, admin pages return 404.

**With Docker.** `docker compose up` runs development at http://localhost:3000.
`docker compose --profile prod up --build prod` runs the real production
image at http://localhost:3001.

## How it works

| Step | What happens |
|---|---|
| Choose where you are | Scan a venue's table-tent QR code, or type its zone and this week's two table words (e.g. "maple fox"), or tap "Use my area" (the phone rounds its location to a ~1 km grid square before sending). The zone lives only in your encrypted session cookie. |
| Show your code | `ZZ-PP-PP`: zone, then 4 random digits. Lives 60 s on screen (plus 10 s grace), with a countdown ring, then refreshes itself. |
| Enter theirs | Creates a *claim*. Nothing happens until they enter yours too. When both claims exist, both codes are used up and a private chat opens on both phones at once. |
| Typos | Burn nothing. Wrong codes count toward a lockout: 8 in 5 minutes rests the device for 5 minutes. |
| Eavesdroppers | If a second, different person enters your code, it's cancelled, you get a new one and an alert. An already-used code entered later also alerts you. |
| Neighbouring zones | A code from a neighbouring zone is accepted (venue zones list neighbours; area zones use the 8 surrounding squares). |
| Add someone (default) | A member shows a one-time 60 s *thread code* and types the newcomer's personal code: the same mutual handshake. Then the group is asked. |
| Group handshake (alternative) | A member opens a 2-minute code that anyone nearby can enter. Each joiner still needs the group's yes. |
| Approval | Unanimous by default; per chat, "most people" or "any one member". An add-in sponsor's yes is implicit (they did a face-to-face handshake); a group handshake's opener votes like everyone else. Requests time out in 10 minutes. Votes are never shown. Making the rule stricter takes effect at once; looser needs every member. |
| Invite links | Designed but not built; off for the MVP (see `../docs/handshake/deliverables/04_threat_model.md`). |
| Reveal ladder | Pairwise, inside a chat: 1 first name and photo, 2 social handles, 3 phone. A step shows only when both chose it; steps go in order; you can step back. |
| Leaving | Ending a one-to-one deletes it for both. Leaving a group keeps it going while 2 or more remain; at 1 it's deleted. |
| Removal | Any member can ask; same approval rule, among everyone except the person in question. |
| Expiry | 14 days. "Extend 14 days" needs every member's tap. Expired chats are hidden at once and purged within 10 minutes. |
| Reports | Reason plus optional note. The reporter can choose to attach the last 20 messages (off by default). Kept 90 days. Admin can suspend a device. |
| Venues | Printable table tent (zone, QR, table word, valid dates) and a live display, both rotating weekly. Staff dashboard shows daily counts only, with 1–2 shown as "fewer than 3". Opening hours and themed windows ("Thursday trivia night") per zone. |

## Architecture

- **Rails 8.1.4.1 on Ruby 4.0.10, PostgreSQL 16.** One database holds the
  app, Solid Queue (jobs), Solid Cable (real time) and Solid Cache.
- **Hotwire.** Turbo Drive, Frames and Streams with Stimulus; importmap, so
  there is no JavaScript build step. Plain CSS, mobile first.
- **Action Cable over Solid Cable.** We chose Solid Cable over Redis because it
  adds no new service to run, pay for or secure. Postgres already holds
  everything. It polls every 100 ms, which is fine at pilot scale. Past roughly
  1,000 concurrent sockets [assumption], switch the `cable.yml` adapter to
  Redis. Two channels re-check permission on every subscribe:
  `ParticipantChannel` (your own alerts and redirects) and `ChatThreadChannel`
  (members only; removed members are disconnected and refused on reconnect).
  Turbo's built-in stream channel is locked down to refuse everyone, so it
  can't be used to bypass those checks. Live-delivery rows are deleted when a
  chat ends and purged a minute after their 10-minute window.
- **Solid Queue** runs recurring jobs (`config/recurring.yml`): purge codes
  (every minute), expire join requests (every minute), purge expired chats
  (every 10 minutes), and daily retention (reports after 90 days, idle
  devices after 30 days).
- **The handshake engine** is `app/services/code_entry.rb`. It locks both
  people's rows in a fixed order, so two people typing at the same instant
  always match.
- **Ordering.** Each message gets a per-chat sequence number under a row lock;
  the browser keeps messages sorted by it.

```
Phone A ──Turbo/HTTPS──▶ Rails (Puma) ──▶ PostgreSQL
Phone B ◀──WebSocket── Action Cable  ◀─── solid_cable_messages
                         Solid Queue ───▶ purge / expiry jobs
```

## Data model

All tables use random uuid keys (no counting-up ids anywhere public).

| Table | Holds | Lifetime |
|---|---|---|
| participants | SHA-256 of the device token; optional encrypted first name, photo, socials, phone | deleted after 30 idle days or on "Delete everything" |
| venues / zones | venue name, staff-token digest, tent secret; zone 10–49, neighbours, hours, theme | until removed |
| handshake_codes | owner, zone number, HMAC of the code, kind (personal / add_in / group), expiry | about 2 minutes |
| code_claims | "I typed your code" | with the code |
| chat_threads | expiry, approval policy, cap (8), message sequence | 14 days (extendable) |
| memberships | per-chat random alias, joined time | with the chat or on leaving |
| membership_proposals / proposal_votes | add or remove requests, votes | with the chat |
| messages | encrypted body, sequence | with the chat |
| reveal_grants | what one member offers another (0–3) | with the chat |
| reports | reason, encrypted note and optional evidence, alias | 90 days |
| venue_daily_counts / daily_metrics | daily totals only | 13 months / kept |

The brief suggested JoinRequest and JoinApproval tables. They are here as
`membership_proposals` and `proposal_votes`, because the same tables also
handle removals.

## Security and privacy

- **Anonymous device.** A random 32-byte token in a signed, httpOnly,
  `SameSite=Lax`, secure (in production) cookie. The database stores only its
  SHA-256. An 18+ confirmation comes first.
- **Codes.** Digits come from `SecureRandom`. Only
  `HMAC-SHA256(server key, "zone:digits")` is stored, so a database copy can't
  be reversed. The plain code lives only in the owner's encrypted session
  cookie. Expiry is enforced on the server.
- **Rate limits** (Rack::Attack, `config/initializers/rack_attack.rb`):
  - 30 code entries a minute per device, 60 per IP.
  - 8 failures in 5 minutes lock the device for 5 minutes.
  - 30 failures in 10 minutes from one IP lock that IP for 10 minutes.
  - 20 wrong table words an hour from one IP rest it for 15 minutes.
  - 60 failures a minute in one zone pause it for 2 minutes.
  - Welcome is limited to 20 a minute per IP.
  - Counters are kept in memory only, keyed by hashed IP, device digest or
    zone number, and vanish when their window ends.
- **Logs.**
  - `filter_parameters` covers codes, digits, message bodies, zones, cells,
    table words, reveal details, notes and evidence. It also filters SQL bind
    values.
  - The request line drops the IP, and secret path segments (`/here/…`,
    `/dash/…`) are masked.
  - SQL debug lines have zone and digest values blanked. Production logs at
    `info`, which includes no SQL.
  - Action Cable logs only warnings, because its debug output would include
    message text.
  - The test `privacy_logging_test.rb` proves all of this on a full flow.
- **Encryption at rest.** Active Record Encryption covers message bodies,
  reveal details, report notes and evidence.
  - This is not end-to-end encryption: the server holds the keys.
- **Web hardening.**
  - Strict CSP: self only, nonces for scripts and styles, no inline styles,
    `frame-ancestors 'none'`.
  - A permissions policy allows geolocation only for us.
  - CSRF protection on every form.
  - `force_ssl` with HSTS in production, and host authorization via
    `APP_HOSTS`.
  - Strong parameters everywhere.
  - Brakeman and bundler-audit run in CI.
- **No location history.** Venue zones use no location at all. Area zones
  receive only a rounded grid cell. It's mapped to a zone and dropped, never
  stored or logged. Zone numbers exist only on codes, which are deleted within
  about 2 minutes.

## Tests

We use Minitest, the Rails default. It needs no extra test framework, runs
fast in parallel, and its system tests drive real headless Chrome against a
real Puma and Action Cable. Several browser sessions act as separate phones.

```sh
bin/rails test           # 82 model, service, job, request and channel tests
bin/rails test:system    # 4 real-browser tests (needs Google Chrome)
bin/rubocop && bin/brakeman && bin/bundler-audit check --update
```

What the tests cover, as the brief asks:

- code expiry and grace
- single use
- typos don't burn a code
- eavesdroppers, before and after a match
- mutual entry inside the window
- neighbouring zones
- device lockout, throttling and zone pause
- unanimous, majority and any-member approval
- rejection and timeout
- the group cap
- new members seeing only new messages
- removal
- leave and dissolve
- extension
- the pairwise reveal ladder
- expiry purge
- encryption at rest
- no codes, zones, locations, message text or IPs in logs
- channel authorization
- the CSP header
- CSRF
- the age gate
- the venue dashboard showing counts only
- admin auth

The latest results are recorded in `../docs/handshake/deliverables/05_test_plan.md`.

To regenerate the guide screenshots against a running dev server:
`bin/rails runner script/guide_screenshots.rb http://localhost:3000 /tmp/hs-shots`.

## Deploy

Every option needs the same production variables (see `.env.example`):

- `DATABASE_URL`
- `SECRET_KEY_BASE` (from `bin/rails secret`)
- the three `AR_ENCRYPTION_*` keys (from `bin/rails db:encryption:init`). Store
  them safely: losing them makes stored messages unreadable.
- `APP_HOSTS`
- optionally `ADMIN_PASSWORD`

Migrations run automatically when the container starts.

### Option A: Kamal (your own VM, about $12–24/month)

1. Rent a small Ubuntu VM (2 GB RAM). Point a DNS name at it.
2. In `config/deploy.yml`, replace each `CHANGE` value: server IP, host name
   and registry user.
3. Export the secrets listed in `.kamal/secrets` in your shell, or pull them
   from a password manager.
4. `kamal setup`: installs Docker, starts PostgreSQL as an accessory, builds
   and boots the app behind Kamal proxy with Let's Encrypt TLS, and checks `/up`.
5. Later releases: `kamal deploy`. Roll back with `kamal rollback <version>`
   (`kamal app containers` lists versions).
6. Seed venues once: `kamal app exec "bin/rails db:seed"`. In production the
   staff links are random and printed once.

### Option B: Render (managed, about $7 + $6/month to start)

1. Push this repository to GitHub.
2. In Render: **New → Blueprint**, pick the repo. It reads `../render.yaml`
   and creates the web service (Docker, root `handshake/`) and a PostgreSQL
   database.
3. Fill in the variables marked "sync: false":
   - the three `AR_ENCRYPTION_*` keys
   - `ADMIN_PASSWORD`
   - `APP_HOSTS` (your `*.onrender.com` name or custom domain)
4. Deploy. Render health-checks `/up`. Roll back from the service's Events
   page.
5. Seed venues from the Render shell: `bin/rails db:seed`.

## Operations

See `docs/OPERATIONS.md` for backups, log retention and monitoring, all
within the privacy promise. In short:

- encrypted daily database backups kept 7 days
- application logs kept 7 days at most
- uptime monitoring on `/up`
- error tracking must scrub request bodies and never record IPs
- no analytics scripts: the admin Metrics page shows daily totals only

## Known limitations

These are honest notes on the prototype, not hidden problems.

- **One metro.** Zone numbers 10–99 are shared by everyone, so venues need
  numbers assigned per city. Running several cities needs a region prefix or
  separate deployments.
- **Busy zones.** 4 digits gives 10,000 codes per zone. A zone with more than
  about 2,000 live codes (a very large conference hall) should be split into
  several zones.
- **Rate-limit counters.** They live in each server's memory. With several app
  servers, the limits apply per server. Use a shared store (e.g. Redis) at that
  point; it must keep IPs hashed and short-lived.
- **Background tabs.** Phones pause web pages in the background. A code card
  that was in the background refreshes as soon as it's visible again, and
  live updates resume when the connection reconnects. An open chat reloads itself when you come back to it
  after more than 5 seconds away, so nothing sent meanwhile is missed.
- **No push notifications** (not built for the prototype).
- **Not end-to-end encrypted.** Messages are encrypted at rest; the server
  can decrypt them in order to deliver them. The copy says so.
- **Staff live display link.** The live table-tent display uses the staff
  link. Use a kiosk-mode tablet, or print the table tent instead.
- **Premium, payments and the verified-human badge** are in the business plan,
  not in the code. Plan limits (`Participant::PLANS`) are the extension point.
- **Legal.** The terms page is a draft pending legal review.
- **Not yet run:** the Render and Kamal deploys, and the Docker image build.
  GitHub Actions CI has run and passed (2026-11-24). See the test plan.

## Extension points

- `Participant#upgrade!`: optional accounts (email or passkey) to keep chats
  across devices. It raises `NotImplementedError` for now.
- `Participant::PLANS`: premium limits (more simultaneous chats; longer or
  larger chats can read from here).
- `MembershipProposal::VIAS`: add `"invite_link"` here if invite links are
  ever approved. The approval flow already applies to every way in.
- `config/cable.yml`: switch the adapter to Redis for scale.
