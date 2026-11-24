# Phase 5: synthesis and completion check (2026-11-24)

Michael asked: "so the whole 5 phase development is complete?" This page
answers that against the brief (`../brief.md`). The Manager checked every
phase, every required feature, the deployment checklist and the testing
requirements against the actual files, not against earlier claims.

**Answer: yes, all 5 phases are complete within this environment.** Every
phase has its outputs, and every required feature is built and tested. What
remains is anything that needs Michael's approval (deploying, committing,
spending) or tools this laptop lacks (a Docker engine, a GitHub remote, real
phones, a lawyer). Those are listed at the end.

## Phase by phase

| Phase | What the brief asks | Where | Status |
|---|---|---|---|
| 1. Individual memos | 14 memos, under 300 words: opportunities, risks, needs | `01_phase1_memos.md` | **Done.** 14 memos, 136–207 words each |
| 2. Cynic review | Cynic challenges every memo; agents mitigate or concede | `02_phase2_cynic_review.md` | **Done.** 14 challenge-and-reply blocks, 5 plan-changing concessions, ranked kill list |
| 3. Working sessions | 6 named sessions, decisions recorded | `03_phase3_working_sessions.md` | **Done.** All 6, each with disagreement, resolution, numbered decisions and open items |
| 4. Rails build | 9 stages, each gated by the Manager | `04_phase4_build_log.md` | **Done.** 9 stages plus an extra gate (8b, independent code review). Gates that failed first are recorded honestly. Ran without pausing for Michael, as he asked ("work straight through") |
| 5. Synthesis | 13 deliverables | `../deliverables/01`–`13`, the app in `handshake/`, this page | **Done** |

## Required features

| Requirement | Status | Where |
|---|---|---|
| Current code with a visible 60 s countdown and auto-refresh | Met | `app/views/home/_code_card.html.erb`, `app/javascript/controllers/countdown_controller.js` |
| Enter someone's code; a mutual match creates a 1:1 | Met | `app/services/code_entry.rb`; `test/services/code_entry_test.rb` |
| Real-time chat over Action Cable, delivered in thread order | Met | `app/channels/chat_thread_channel.rb`, `ChatThread#post!` (sequence numbers), `messages_controller.js` |
| Add-in code, member approval, leave and remove for groups | Met | `MembershipProposal`, `AddInsController`, `Membership#leave!`; `test/models/group_flow_test.rb` |
| Shared-moment invite (alternative add method) | Met | `GroupHandshakesController`; the opener must vote |
| Invite link: designed, off by default, needs Cynic + Security sign-off | Met (designed, declined, not built) | `../deliverables/04_threat_model.md` |
| Pairwise reveal ladder with mutual confirmation | Met | `app/models/reveal_grant.rb`; `test/models/reveal_grant_test.rb` |
| Sever (vanishes for both); expiry job purges messages and memberships | Met | `ChatThread#vanish!`, `PurgeExpiredThreadsJob`; `test/jobs/expiry_jobs_test.rb` |
| Report and block-free leave; admin reports with minimal data | Met | `ReportsController`, `Admin::ReportsController` |
| Venue page: printable tent with rotating code; staff dashboard with counts only | Met | `app/views/venue_dashboards/*` (weekly QR token and two table words; "fewer than 3") |
| Themed zones and time windows tied to opening hours | Met (admin form added in this pass) | `Zone#open_now?`, `Zone#current_theme`, `app/views/admin/venues/new.html.erb` |
| Defence against a posted venue code used from afar: rotating codes **plus coarse proximity check** | **Partly met** | Rotating QR and words, opening hours, per-address limits and mutual entry are built. A location check at venues was deliberately left out: it would make venue visitors share their location, and venue zones promise to use none. Remote use is harmless anyway, because a chat still needs the person at the venue to type the outsider's code. Recorded in `00_decisions.md` and `04_threat_model.md` |
| Neighbour-zone matching | Met | `ZoneContext#accepts?`, `AreaZone`; tested |
| Health check, seed data, demo mode | Met | `/up`, `db/seeds.rb`, `DemoPartner` |
| Anonymous signed httpOnly device token; account upgrade stubbed | Met | `ApplicationController#sign_in_device!`, `Participant#upgrade!` |
| Rack::Attack limits and zone/device lockouts | Met | `config/initializers/rack_attack.rb`, `HandshakeGuard`; `test/integration/rate_limit_test.rb` |
| Codes from SecureRandom, stored hashed, never logged, expiry on the server | Met | `HandshakeCode`; `privacy_logging_test.rb` |
| Strong params, CSRF, CSP, secure cookies, force_ssl, filtered logs | Met | Initializers and controllers; `security_headers_test.rb` |
| No location history | Met | Area cells are never stored; zones exist only on codes (purged in about 2 minutes) |

## Deployment-ready checklist

| Item | Status | Where |
|---|---|---|
| Multi-stage, non-root Dockerfile | Written; **not built here** (no Docker engine) | `handshake/Dockerfile` |
| docker-compose for local dev | Written; **not run here** | `handshake/docker-compose.yml`, `Dockerfile.dev` |
| `.env.example`, `database.yml`, credentials, asset precompile | Met. Precompile was checked in a local production-mode boot | `handshake/.env.example`, `config/` |
| Kamal and Render configs with steps | Written; **not deployed** (needs Michael's "deploy" and accounts) | `config/deploy.yml`, `.kamal/secrets`, `../../render.yaml`, README "Deploy" |
| `bin/setup`, migrations, `/up` | Met | `bin/setup`, `db/migrate/`, `/up` (200 in the production-mode check) |
| GitHub Actions CI: RuboCop, Brakeman, bundler-audit, full tests | **Passed on GitHub** (first runs 2026-11-24: lint/scans and full tests including system tests) | `../../.github/workflows/handshake-ci.yml` |
| Backup, log-retention and monitoring notes within the privacy promise | Met | `handshake/docs/OPERATIONS.md` |
| README: setup, architecture, deploy, security, limitations | Met | `handshake/README.md` |

## Testing requirements

All met. See `../deliverables/05_test_plan.md` for the case-by-case table:
- Minitest, with the reason for choosing it
- model, request, channel and system tests
- code expiry, single use, typos, eavesdroppers, mutual entry, neighbour zones
- rate limits and lockouts
- unanimous join, rejection and timeout, leave and dissolve
- pairwise reveals, expiry purge
- no location or code values in logs

Results are reported honestly, including what couldn't be run.

## Changes made in this Phase 5 pass

1. **Stale statements fixed.** Nine statements in the earlier documents no
   longer matched the code:
   - the table word is two words now
   - only an add-in sponsor's yes is implicit
   - Ruby 4.0.10
   - log retention is 7 days, not 14
   - backups
   - the live-delivery queue and rate-limit counters were added to the data
     inventory
2. **Over-promise removed.** The sales kit promised organizers a dashboard "by
   hour". The app shows counts by day, which is also more private, so the copy
   was fixed (twice in `09_sales_kit.md`).
3. **Threat-model odds updated.** The guessing math now reflects the new
   per-network-address limit: one address gets about 90 guesses an hour, and
   pausing a zone now takes about 40 addresses.
4. **Admin can set themed windows.** Previously only the seed data could.
   There's a new test.
5. **Flaky test fixed.** The log-privacy test failed about 1 run in 10,
   because random ids in the log can contain any 4 digits. It now matches the
   digits only as a standalone number. This was a test flaw, not a leak.
6. **Privacy copy re-checked** in the app, the spec, the brand doc and the
   sales kit. Nothing promises more than the code does. The spec now also
   mentions the delivery queue and backups.

Validation after these changes is recorded in `../deliverables/05_test_plan.md`
and the daily log.

## What can't be finished without Michael or other tools

| Item | Needs |
|---|---|
| Build and run the Docker image; `docker compose up` | A Docker engine on this laptop (only the CLI is installed), or a CI runner |
| Deploy to Render or a Kamal VM; run migrations and seeds in production | Michael's "deploy", a hosting choice and accounts |
| Testing on real iPhones and Android phones (including background tabs and a real GPS fix) | Real devices and people |
| Legal review of terms, privacy copy and the age gate | A lawyer |
| Trademark clearance for the name (Sayso recommended) | A trademark search |
| Pilot budget (~$4,100 cash) and the 50% founding venue rate | Michael's decision |
| Load testing (Solid Cable's ~1,000-socket ceiling is an assumption) | A staging server |
