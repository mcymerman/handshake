# Phase 4: the Rails build, stage by stage

The Manager gated each stage, the Tester tried to break it, and the Security
Architect reviewed it. Michael asked us to "work straight through", so the
gates ran inside the team instead of pausing for him. Nothing here was
deployed.

| Stage | What was built | Gate check | Outcome |
|---|---|---|---|
| 1. Skeleton, Docker, CI, health check | Rails 8.1 app; one PostgreSQL database for app, queue, cable and cache; multi-stage non-root Dockerfile; `/up` | App boots; `/up` returns 200 | **Passed.** The Developer folded Solid Queue, Cache and Cable into one migration: one database, cheaper hosting. |
| 2. Data model and migrations | 14 tables, all uuid keys; encrypted columns | Model tests | **Passed after a change.** The Tester showed `time` columns shift with time zones and break overnight bars. Opening hours became minutes after midnight. |
| 3. Codes, zones, mutual handshake | HMAC-stored codes, grace window, claims, neighbours, eavesdropper rotation, locks taken in order | 12 engine tests | **Passed.** The Security Architect insisted on HMAC rather than plain SHA-256: there are only 10,000 codes per zone. |
| 4. One-to-one chat over Action Cable | Sequenced messages; two authorized channels | Channel tests; browser test with two phones | **Failed first.** The Tester found every page's JavaScript dead (a wrong Turbo import), so forms fell back to full page loads. The Developer fixed it and the gate passed on the second run. |
| 5. Groups: add-in, approval, leave, dissolve | Proposals and votes; three policies; group handshake; removal; cap 8 | 10 group tests plus a three-phone browser test | **Failed first, twice.** (a) Approval cards only appeared after a refresh. (b) The "one open add request" rule blocked a second group-handshake joiner. Trust & Safety also asked for votes to stay hidden. Both fixed; passed. |
| 6. Reveal ladder, expiry, purge jobs | Pairwise grants in order; extension needs everyone; recurring purges | Reveal, expiry and retention tests | **Passed.** The Tester found a loophole: one person could loosen the approval policy because the "everyone agreed" check skipped people who hadn't answered yet. Fixed before the gate. |
| 7. Venue pages and dashboard | Printable tent with QR and weekly table word, live display, counts-only dashboard | Request tests; desktop screenshots | **Passed.** Legal and Trust & Safety asked that 1–2 show as "fewer than 3". |
| 8. Hardening | Rack::Attack limits; log scrubbing (request line, SQL, Action Cable); CSP with nonces; host authorization | Log-privacy test, rate-limit tests, Brakeman | **Failed first, three times.** (a) SQL debug lines showed zone numbers, so a scrubber was added. (b) The rate-limit store could keep hashed IPs on disk for a day, which would make the privacy copy untrue, so counters moved to memory. (c) Brakeman flagged Ruby 3.4.9 (CVE-2026-132825), so we upgraded to Ruby 4.0.10. |
| 8b. Independent code review | Security Architect review of the finished code | 7 findings, each proven with a throwaway test | **Failed, then fixed.** Two were serious: a removed member could keep listening through Turbo's own channel, and "any one member" plus a group handshake admitted strangers with no yes. All 7 fixed, with tests; see `deliverables/05_test_plan.md`. |
| 9. Deploy configs, README, final run | Kamal (VM with a Postgres accessory), Render blueprint, docker-compose, GitHub Actions at the repo root, README, operations notes | Full suite, lint, scans; Docker image build | See `deliverables/05_test_plan.md` for the final results. |

## Disagreements worth recording

- **Cynic vs Developer: Solid Cable.** The Cynic called a database-polled
  socket layer "a toy". The Developer showed it's a one-line switch to Redis
  later, and that a pilot of three venues won't reach 100 concurrent sockets.
  Resolved: keep Solid Cable, and list the switch point (about 1,000 sockets)
  in the README.
- **UX vs Security: zone entry.** UX wanted typing "47" to be enough.
  Security wanted proof of presence. Resolved: scan the QR code, or type the
  zone plus a weekly table word (one 4-letter word at first; two words after the code review). Because entry is mutual, a remote
  attacker who gets in still can't connect to anyone.
- **Trust & Safety vs Privacy: report evidence.** T&S wanted messages attached
  automatically. Privacy refused. Resolved: the reporter chooses; it's off by
  default; evidence is kept 90 days.
- **Data vs Privacy: pilot metrics.** Data asked for a label on every chat
  (venue or area). Privacy offered daily totals instead
  (`handshakes_at_venues`, `handshakes_in_areas`). Accepted: nothing is stored
  per chat.
