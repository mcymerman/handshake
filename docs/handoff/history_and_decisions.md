# History and decisions

## 2026-11-24: project set up
- Michael: "copy settings ... and prepare that project with all best practices
  and guidance I have given you in the past such as logging, guidance, checkin etc."
- Copied `.claude/settings.local.json` from the Fellow Residents workspace as is.
  Its allow rules point at Fellow Residents scripts and are harmless here; trim
  or replace them when stchat's own tools exist, using the proposed-settings flow.
- Carried over his standing preferences into CLAUDE.md: simplicity first, emailed
  reports, ask before releases, the review team, the permission flow, no
  counting-up ids, every promise literally true, screenshot review, daily logs.

## 2026-11-24: Handshake prototype
- Michael sent the "Handshake" brief (14-agent virtual startup) and asked for "a completely functional prototype in addition to what is asked", "a guide on how to use the system with screenshots", delivery by email via the Fellow Residents agent and the claude-dropbox, "work straight through", and hourly progress files.
- The stack and product decisions are in `docs/handshake/00_decisions.md`. Key choices:
  - Solid Cable over Redis.
  - Minitest.
  - One PostgreSQL database.
  - Add-in code as the default way to add people; group handshake also built; invite links designed but not built.
  - Unanimous approval by default.
  - Weekly table word plus QR code for venue zones.
  - Counts only on venue dashboards ("fewer than 3").
  - Rate-limit counters in memory.
  - Ruby 4.0.10 (3.4.9 rejected for CVE-2026-132825).
- Pilot decision rule: all six met = go; 1–2 missed = iterate; 3+ missed = stop/pivot.
