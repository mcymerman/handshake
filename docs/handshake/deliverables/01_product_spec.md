# Handshake — one-page product spec

*Deliverable 1. Consistent with `00_decisions.md` (2026-11-24). [A] = assumption.*

## What it is

Handshake lets two people who just met start a private chat without swapping
numbers or handles. Each phone shows a short code like **47-12-83**. You say
yours, they say theirs, you both type them in, and a chat opens. No install, no
account, no name. If it goes well, you can later reveal more of yourself, one
step at a time, only when you both want to.

- **47** is the zone: a venue's table tent, or your ~1 km area (rounded on your
  phone). Never exact GPS.
- **12-83** is your personal code: random, single-use, 60 seconds on screen.

## Core flows

1. **Show code.** Open the page, confirm "I'm 18 or older", pick a zone (scan
   the table tent, type zone + table word, or use my area). Your code appears
   with a 60-second ring and refreshes itself.
2. **Enter code.** Type their code into the box. Nothing happens until *they*
   also type yours. One-sided entry does nothing.
3. **Chat.** When both entries meet, a 1:1 chat opens. Each of you gets a
   random alias for this chat only ("Teal Otter"). Messages arrive live, in
   order. The chat vanishes in 14 days unless everyone taps "Extend 14 days".
4. **Add someone.** A member taps "Add someone", shows the newcomer a one-time
   60-second thread code, and types the newcomer's personal code. That creates a
   proposal; the group approves before anyone joins.
5. **Group handshake.** When everyone is together, a member opens a 2-minute
   group code anyone nearby can enter. Each joiner still needs group approval.
6. **Reveal ladder.** Per person, per chat: (1) first name + photo, (2) social
   handles, (3) phone. A step shows only when both of you chose it, in order.
7. **End / leave.** In a 1:1, "End chat" deletes it for both, no block drama.
   In a group, "Leave" removes you; if fewer than 2 remain, the chat is deleted.
8. **Report.** Pick a reason, add a note if you like, and *choose* whether to
   attach the last 20 messages (off by default). Admins can stop a device from
   getting new codes.

## Privacy guarantees (literal)

We never store location history, sell data or run ads. Your phone rounds your
location to a ~1 km square before sending it; we turn that into a zone number
and forget it. Zone numbers live only on short-lived codes, deleted within about
two minutes of expiry or a match. Logs never contain codes, message text, zones
or IP addresses.

Also true, and worth saying plainly:
- Codes are stored only as a keyed hash (HMAC), never as plain digits.
- Your device is recognised by a random cookie; we store only its SHA-256.
- Messages and revealed details are encrypted in our database and deleted
  with the chat. They are **not** end-to-end encrypted; we don't claim that.
- Reports are kept 90 days, then deleted.
- To arrive instantly, messages pass through a short delivery queue, cleared
  within about 10 minutes and at once when a chat ends. Encrypted backups are
  kept up to 7 days, so deleted data can remain in a backup until it rolls off.

## Group-chat rules

- Cap: **8 members**, pending newcomers included.
- Nobody is added silently. Everyone is notified of every proposal.
- Approval policy per chat: **unanimous (default)**, majority, or any member.
  An add-in sponsor's yes is implicit (a group-handshake opener votes like everyone else); under unanimous, one "no" rejects. Proposals
  time out after 10 minutes.
- Newcomers see only messages sent after they join.
- Removal: any member proposes; same policy, counted among everyone except
  the person being removed.
- Joining a group reveals nothing. Reveals stay strictly person-to-person.
- A leaver's past group messages stay, marked "(left)".

## MVP scope

**In:** spoken-code handshake, venue and area zones with neighbour matching,
rate limits and lockouts, eavesdropper alerts, 1:1 and group chat (add-in code
+ group handshake), approvals, leave/remove, reveal ladder, extend, expiry
purge, reports and admin review, venue table tent, live display and
counts-only staff dashboard, demo mode.

**Not in scope:**
- **Invite links** — designed, off and not built. The Cynic and Security
  Architect declined sign-off: links can be forwarded. Revisit after the pilot
  with evidence.
- **Native apps** — mobile web only.
- **Accounts** — anonymous devices only; `upgrade!` is a documented stub.
- **Payments** — premium is priced [A $5/month] but not built.
- **Multi-metro** — one pilot metro; a region prefix comes later.

## Defaults

| Setting | Default |
|---|---|
| Code format | `ZZ-PP-PP` (zone 10–99, 4 random digits) |
| Personal code life | 60 s on screen, +10 s server slack |
| Venue zones / area zones | 10–49 / 50–99 |
| Area cell | ~1 km, rounded on the phone; zone + 8 neighbours |
| Venue entry proof | weekly QR token or weekly two-word table word (e.g. "maple fox"), within opening hours |
| Typo | counts as a failure, burns nothing |
| Expired code | "ask for the new one", not a failure |
| Rate limits | 30 entries/min/device, 60/min/IP |
| Device lock | 8 failures in 5 min → 5 min lock |
| Zone pause | 60 failures/min in a zone → 2 min pause |
| Chat life | 14 days; extend needs every member |
| Group cap | 8 including pending |
| Add mechanism | add-in code (default), group handshake (alternative) |
| Group code life | 2 minutes, multi-use, approval still required |
| Approval policy | unanimous; proposals time out in 10 min |
| Report evidence | off unless the reporter opts in (last 20 messages) |
| Report retention | 90 days |
| Staff dashboard | counts only; under 3 shown as "fewer than 3" |
