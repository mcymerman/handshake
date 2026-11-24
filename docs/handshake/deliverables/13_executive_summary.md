# 13. Executive summary

**Recommendation: BUILD, as a cheap, time-boxed pilot. Lead with conferences
and decide go or stop on hard numbers after 8 weeks.**
This is not a "build the company" call. The prototype proves the idea works
and keeps its privacy promise. It cannot prove that strangers will bother
using it. Only a real pilot can answer that.

## What Handshake is

Two people who just met say short codes out loud (like 47-12-83), type each
other's, and a private chat opens. There are no phone numbers, no handles and
nothing to install. A chat can grow into a group of up to 8, but only with the
members' agreement. People share their name, socials or phone one person at a
time, and only when both choose to. Chats vanish after 14 days.

## What's done

- **A working prototype.** It's a complete Rails app covering every required
  feature:
  - spoken codes with a 60-second countdown
  - mutual-only connections
  - eavesdropper alerts
  - neighbouring zones
  - lockouts
  - live chat
  - add-in codes and group handshakes, with unanimous, majority or any-member
    approval
  - leave and dissolve
  - the pairwise reveal ladder
  - expiry and purge
  - reports with an admin view
  - venue table tents, live display and a counts-only dashboard
  - demo mode for sales
- **Tests and review.** 82 automated tests plus 4 real-browser tests, all
  passing. Lint and three security scans are clean.
  - A security scan found a critical flaw in the Ruby version we started on,
    so we upgraded.
  - An independent code review found 7 defects, 2 of them serious. All are
    fixed and tested.
- **Deployment.** Docker, docker-compose, Kamal and Render configs, CI and a
  README are written. **Nothing is deployed.** CI now runs on GitHub and
  passed on its first runs. The Docker build and the deploys haven't been
  run; the test plan says exactly what was and wasn't verified.
- **The team package.** All 13 deliverables plus the Phase 1–4 records:
  memos, the Cynic's review, six working sessions and the stage-gate build
  log.

## The case for building

1. **The privacy design is real, not marketing.** Codes are stored scrambled
   and deleted within about 2 minutes. There's no location history; the phone
   rounds its position before sending it. Logs carry no codes, messages, zones
   or IPs, and a test proves it. A big platform can't copy this without
   becoming something else (Cynic, risk 6).
2. **Conferences pay early.** Event licences of $1,500–$7,500 make up about
   46% of modelled revenue. Organizers already pay for "networking" features
   that nobody likes.
3. **It's cheap to run.** One small server plus Postgres costs about $25–75 a
   month at pilot scale, with no Redis and no extra services.

## The case against (the Cynic's top risks)

1. **People just swap Instagram** (High). Codes are only better if the other
   person isn't ready to share yet. We don't know how often that's true.
2. **Cold start** (High). It only works if the other person has heard of it.
   That's why we start with venue tents and event organizers who tell the
   whole room.
3. **Safety misuse** (Medium). Mitigated by mutual-only entry, unanimous
   approval, hidden votes, easy reporting and device suspension. It's never
   zero.

## Money

| | Base case |
|---|---|
| Break-even | March 2028 (month 16) |
| Cash needed at the lowest point | about $114,000 (plan for $140,000 with a buffer) |
| 18-month revenue / costs | $271k / $358k |
| Biggest sensitivity | Event pricing. Halving it pushes break-even out by months |

Main assumptions:
- Michael draws no salary. Drawing $5k a month from January 2028 moves
  break-even to April 2028.
- Pilot venues pay a 50% founding rate. This needs Michael's confirmation.
- Premium costs $5 a month.

The bear case doesn't break even within 18 months.

## Name

The recommended name is **Sayso** ("Keep talking, on your say-so"), because
"Handshake" is trademark-crowded. **A trademark search hasn't been done**; it
must happen before anything is printed.

## The pilot and how we'll decide

The pilot runs 8 weeks (proposed for 1 March to 25 April 2027) at one cafe,
one climbing gym and one bar, with a decision by 7 May. Every measure is a
daily total on the admin Metrics page; nothing tracks a person.

| Measure | Threshold |
|---|---|
| Handshakes | ≥ 600 total |
| Second-conversation rate (messages on 2+ days) | ≥ 35% |
| Chats that become groups | ≥ 8% |
| One-to-one chats reaching reveal step 1 | ≥ 25% |
| Venues wanting to keep paying | ≥ 2 of 3 |
| Serious safety incidents | ≤ 1 per 1,000 chats, none unresolved |

The decision rule:
- **Go** if all six are met.
- **Iterate** for 4 more weeks if one or two are missed.
- **Stop or pivot** if three or more are missed.

There's also an early warning by week 3. If fewer than 20% of chats reach
3+ messages each way (half the 40% target), we rethink early.

**Pivot options if we stop:** "Handshake for events" (organizer-run, B2B
only), or a white-label feature for community and coworking apps.

## Decisions waiting for Michael

1. Approve the pilot budget (about $4,100 cash outside salaries) and the 50%
   founding venue rate.
2. Choose the name, and order the trademark search before printing.
3. Choose where it runs: Render (simplest) or Kamal on a VM (cheapest). Then
   (the GitHub repository and CI are already set up).
4. Legal review of the terms and privacy copy before any public use.
5. Say "deploy" when you want a staging server. Nothing has been deployed.
