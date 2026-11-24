# 5. Test plan and results

Owner: Tester / QA. Framework: **Minitest**, the Rails default. It needs no
extra framework, runs tests in parallel, and its system tests drive real
headless Chrome against a real Puma and Action Cable, with separate browser
sessions acting as separate phones. RSpec would give the same coverage with
more setup.

## Test layers

| Layer | Files | What it proves |
|---|---|---|
| Model and service | `test/models/*`, `test/services/code_entry_test.rb` | The handshake engine, groups, reveals, zones, expiry |
| Job | `test/jobs/expiry_jobs_test.rb` | Purges and retention actually delete data |
| Request (integration) | `test/integration/*` | Web flows, rate limits and lockouts, logs, headers, access control |
| Channel | `test/channels/channels_test.rb` | Socket auth, membership checks, ordered broadcasts |
| System (real browser) | `test/system/handshake_system_test.rb` | Two or three phones connecting, chatting live, approving, revealing, ending |

## Top 25 test cases

| # | Case | Where | Result |
|---|---|---|---|
| 1 | Mutual entry opens a 1:1 chat for exactly those two people | code_entry_test "mutual entry opens…" | PASS |
| 2 | One-sided entry never starts a chat | code_entry_test "one-sided entry…" | PASS |
| 3 | Mutual entry must happen inside the window (expired at 75 s) | code_entry_test "inside the window" | PASS |
| 4 | Code expiry: still accepted at 65 s (grace), refused at 71 s | handshake_code_test "expires about 60 seconds…" | PASS |
| 5 | Single use: a code consumed by a match can't be used again | code_entry_test "single-use" | PASS |
| 6 | A typo doesn't burn the code; the real code still works | code_entry_test "typo does not burn" | PASS |
| 7 | Eavesdropper: a second person typing an overheard code is not connected; the owner gets a fresh code and 2 live pushes (alert and refresh) | code_entry_test "eavesdropper…" | PASS |
| 8 | Real partner still connects when an eavesdropper typed first, and the eavesdropper isn't in the chat | code_entry_test "real partner still connects…" | PASS |
| 9 | Neighbouring zones accepted (47↔48), distant ones refused (21) | code_entry_test "neighbouring zones…", "either side of a boundary" | PASS |
| 10 | Codes are stored only as a keyed hash; 300 issued codes are all unique | handshake_code_test | PASS |
| 11 | 8 wrong codes lock the device; it works again after 5 minutes | rate_limit_test "8 wrong codes…" | PASS |
| 12 | Over 30 entries a minute from one device are throttled (429) | rate_limit_test "more than 30…" | PASS |
| 13 | A guessing storm (60 failures a minute) pauses the zone for 2 minutes, then recovers | rate_limit_test "guessing storm" | PASS |
| 14 | Add-in code needs mutual entry, then unanimous approval; nobody added silently; sponsor's yes is implicit | group_flow_test "add-in code needs…" | PASS |
| 15 | Under unanimous approval, one "no" rejects | group_flow_test "one no rejects" | PASS |
| 16 | Join requests time out after 10 minutes (job) | group_flow_test "time out" | PASS |
| 17 | Majority and any-member policies; loosening needs everyone | group_flow_test (2 tests) | PASS |
| 18 | Group handshake: several people can ask to join, each still approved (a newly admitted member votes too) | group_flow_test "group handshake" | PASS |
| 19 | Cap of 8 counts pending newcomers | group_flow_test "cap is 8" | PASS |
| 20 | New members see only messages sent after they join | group_flow_test; system test "add someone…" | PASS |
| 21 | Leave and dissolve: 1:1 end deletes for both; group continues with 2+, dissolves at 1 | leave_and_dissolve_test; system test "ending a chat…" | PASS |
| 22 | Pairwise reveal: a step shows only when both chose it, in order; groups never expose anyone | reveal_grant_test (3); system test "reveal ladder" | PASS |
| 23 | Thread expiry purge deletes messages, memberships and reveals; expired chats are hidden before the job runs | expiry_jobs_test | PASS |
| 24 | No codes (full, unformatted, or the 4 digits as a standalone number), message text, zones, rounded cells, table words, staff tokens or IPs in logs on a full flow at debug level | privacy_logging_test | PASS |
| 25 | Sockets: no cookie, no connection; non-members and removed members refused; forged stream names refused; Turbo's own channel refuses everyone; messages broadcast in order | channels_test (8) | PASS |

Also covered:
- the age gate
- the httpOnly device cookie, with only its digest stored
- the venue word and QR checks
- opening hours, including overnight
- themed windows
- weekly rotation with the Monday-noon grace
- area cells
- "fewer than 3" counts
- the CSP header
- CSRF (a forged post is refused)
- the secret staff link
- admin switched off without a password
- outsiders can't read or post
- report evidence attached only when asked
- encryption at rest for messages and phone numbers
- daily retention

## Actual results (run on this laptop, 2026-11-24, Ruby 4.0.10, Rails 8.1.4.1, PostgreSQL 16, Chrome 158)

| Command | Result |
|---|---|
| `bin/rails test` | **82 runs, 429 assertions, 0 failures, 0 errors** (clean in 11 consecutive full runs: 8 before and 3 after the final test fix) |
| `bin/rails test:system` | **4 runs, 38 assertions, 0 failures, 0 errors** (2–3 real headless Chrome sessions each) |
| `bin/rubocop` | 101 files, **no offenses** |
| `bin/brakeman --exit-on-warn` | **0 warnings** (after upgrading Ruby; see below) |
| `bin/bundler-audit check --update` | **No vulnerabilities** |
| `bin/importmap audit` | **No vulnerable packages** |
| Production-mode boot (`RAILS_ENV=production`, precompiled assets, scratch database) | `/up` 200; sign-up, zone and code flow worked; CSP header present; Solid Queue scheduler started all 5 recurring tasks and the purge jobs ran on schedule; log had no IPs or location values |

### Problems the tests caught (all fixed before the final run)

1. **All JavaScript dead.** A wrong Turbo import meant forms posted as full pages.
2. **Approval cards not live.** They only appeared after a refresh.
3. **Push race.** The person ending a chat received their own push, which
   raced their redirect.
4. **Notice wiped.** The "chat ended" notice was cleared by the page change.
5. **Second joiner blocked.** The "one open add request" rule blocked a second
   person joining through a group handshake.
6. **Policy loophole.** One person could loosen the approval policy, because
   the check ignored members who hadn't voted yet.
7. **Silent report.** Sending a report showed nothing, because Turbo ignores a
   reply that isn't a redirect.
8. **Zones in logs.** SQL debug lines contained zone numbers.
9. **Ruby vulnerability.** Brakeman flagged Ruby 3.4.9 (CVE-2026-132825, remote
   code execution). Upgraded to Ruby 4.0.10.
10. **Flaky test.** It looked up "the last report" by random id. Fixed by
    sorting on creation time.
11. **Flaky test (found in the Phase 5 check).** The log-privacy test failed
    about 1 run in 10, because random request ids and uuids in the log can
    contain any 4-digit run. Now it looks for the digits only as a standalone
    number. This was a test flaw, not a leak.

### Independent security review (Privacy & Security Architect, after the first full run)

A separate reviewer read the code and found 7 real defects. Each was proven
with a throwaway test, then fixed and covered by a permanent test:

| # | Severity | Defect | Fix | Test |
|---|---|---|---|---|
| 1 | High | A removed member could keep reading a chat live by subscribing to Turbo's built-in channel with a stream name they'd kept | Turbo's own channel now refuses everyone; only permission-checking channels stream | channels_test "Turbo's own channel refuses everyone" |
| 2 | High/Medium | Under "any one member", a group handshake admitted strangers with no human yes | The opener of a group handshake votes like everyone else; a real yes is needed | group_flow_test "any-member … still needs a real yes" |
| 3 | Medium | Plaintext copies of messages in the live-delivery queue outlived "End chat" | Deleted when a chat ends; purged every minute after 10 minutes; privacy page updated | expiry_jobs_test "clears its queued live deliveries" |
| 4 | Medium | The 4-letter table word (71 options) could be worked through from home, and one address could keep a zone paused | Two-word table word (~5,000 options), wrong-word limit per address, wrong-code limit per address | rate_limit_test (3 new tests) |
| 5 | Low | Crafted requests caused 500 errors (missing reveal level, unknown vote) | Handled politely | handshake_flow_test "crafted requests", group_flow_test "unknown vote" |
| 6 | Low | Two simultaneous leaves could strand a one-person chat | Member count checked under the chat's lock | (race not reproducible in a test; reviewed) |
| 7 | Low | An error message would have put a zone number in the logs | Message no longer includes it | (reviewed) |

## Not verified in this environment

We say so plainly rather than claim it passes.

- **Docker image build.** This laptop has the Docker command-line tool but no
  Docker engine, so `docker build` and `docker compose` were not run. The
  Dockerfile follows the Rails 8.1 template (multi-stage, non-root). The same
  production boot was checked without Docker (above).
- **Kamal and Render deploys.** Not run; there is no server or Render account
  for this project yet, and deploying needs Michael's go-ahead.
- **GitHub Actions.** Now verified: the first two runs on 2026-11-24 (branch `handshake-prototype`) passed both jobs: lint and security scans, and the full test suite including the headless-Chrome system tests.
- **Real phones.** Phones were tested only through Chrome's device emulation
  at 390 px. Not tested on real iOS Safari or Android Chrome, including how
  they pause background tabs.
- **"Use my area" with a real GPS fix.** Only the server side was tested, with
  rounded cells. The browser rounding code ran in emulation without a
  location.
- **Load.** No load test. Solid Cable's capacity (~1,000 sockets) is an
  assumption, not a measurement.
- **Accessibility.** No screen-reader pass. The pages use labels, live regions
  and focus styles, but nothing was audited.
