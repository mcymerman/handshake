# Handshake — threat model and abuse-prevention plan

*Deliverable 4. Voices: Privacy & Security Architect (PSA) and Trust & Safety
(T&S), with the Cynic where they disagreed. Consistent with `00_decisions.md`.
Labels: [D] decided and in the prototype, [A] assumption, [R] recommended but
not built in the prototype, [O] open.*

## 1. What we protect (assets)

| Asset | Why it matters |
|---|---|
| Who met whom | The core secret. A connection graph is a stalking map. |
| Where people are | Even a zone number at a time is sensitive. We never keep history. |
| Message text | Private first conversations. |
| Revealed details | Name, photo, handles, phone: given to one person, never a group. |
| Live codes | Whoever holds a live code can try to start a connection. |
| The device cookie | It is the person's only identity in the system. |
| Reports and evidence | Contain the most sensitive moments, by definition. |
| Venue trust | A venue that feels unsafe drops us; the network goes with it. |

## 2. Who might attack (actors)

| Actor | Goal | Main defence |
|---|---|---|
| Curious bystander | Peek at a stranger's chat | Nothing visible without the device cookie; aliases per chat |
| Eavesdropper | Overhear a code and hijack the connection | Mutual entry; second entry cancels the code and alerts the owner |
| Remote guesser | Type random codes to reach strangers | 10,000-code space, rate limits, mutual entry (section 4) |
| Stalker | Find or follow a specific person | No location history, no profiles, aliases per chat, End chat deletes for both |
| Harasser | Abuse someone after a real meeting | End chat, report, device suspension; no reveal without consent |
| Hostile group member | Add allies, expose or humiliate someone | Unanimous approval, pairwise reveals, leave anytime (section 7) |
| Pile-on group | Many people swarm one target | Cap 8, approvals, removal rules, report |
| Scammer | Romance or crypto scams after a friendly meeting | Report, suspension, no phone reveal without both agreeing, in-chat safety tip [R] |
| Malicious venue staff | Learn who connected at their venue | Dashboard shows counts only, under 3 shown as "fewer than 3" |
| Insider / admin | Read chats or link people | No admin screen for messages; reports show minimal data; key access limited [R] |
| Database thief | Dump and mine the database | Hashed tokens, HMAC codes, encrypted messages, keys kept outside the DB |
| Subpoena | Compel records | We hold very little, for a short time (section 6) |

## 3. STRIDE summary

| Threat | Example | Defence | Residual |
|---|---|---|---|
| **S**poofing | Fake being in a venue zone | Weekly QR token or table word + opening hours + mutual entry | Low–Med |
| **S**poofing | Steal a device cookie | httpOnly, secure, signed cookie; force_ssl; only SHA-256 stored | Low |
| **T**ampering | Edit another chat's messages or reveals | Server checks membership on every action; strong params; CSRF | Low |
| **R**epudiation | "I never sent that" in a report | Reporter can attach last 20 messages; report kept 90 days | Med (evidence is opt-in) |
| **I**nformation disclosure | Logs leak codes, zones, IPs | Filtered logs; codes never logged; tests check logs | Low |
| **I**nformation disclosure | Staff infer who connected | Counts only, small-number masking | Low |
| **I**nformation disclosure | Group reveals someone's identity | Reveals pairwise only, per chat aliases | Low |
| **D**enial of service | Flood a zone with guesses | Device lock, IP limit, zone pause | Med (pause itself hurts a venue for 2 min) |
| **D**enial of service | Eavesdropper keeps cancelling a person's codes | Fresh code each time; device lock; report | Low–Med |
| **E**levation of privilege | Join a group without approval | Proposals need approval; only an add-in sponsor's yes is implicit; a group-handshake opener must vote | Low |
| **E**levation of privilege | Admin over-reach | Admin sees reports only; can suspend, cannot read chats in the app | Med (server holds keys) |

## 4. Code-space math (remote guesser)

**Setup.** Each zone has 10,000 possible personal codes (`00-00` to `99-99`).
The chance one guess hits *some* live code is `live codes ÷ 10,000`.

**Ceilings from our limits [D].**
- One device: 8 failures in 5 minutes triggers a 5-minute lock, so at most
  about **8 failures per 5 minutes ≈ 96 per hour**.
- New devices are cheap (clear cookies), but since the Phase 4 code review
  each **network address** is also limited: 30 failures in 10 minutes rests
  that address for 10 minutes, so **one address ≈ 90 per hour**, however many
  devices it creates.
- The real ceiling is the zone: 60 failures/minute pauses it, so an attacker
  stays under **≈59 per minute ≈ 3,540 per hour**, which now needs about 40
  separate addresses (a botnet).

| Scenario | Live codes [A] | Per guess | One device or one address, 1 hour (~90–96 tries) | Botnet at zone ceiling, 1 hour |
|---|---|---|---|---|
| Quiet cafe | 5 | 0.05% | 4.4–4.7% | ~83% (1.8 expected hits) |
| Busy bar | 20 | 0.2% | 16.5–17.5% | ~99.9% (7 hits) |
| Conference hall | 800 | 8% | ~100% (7–8 hits) | certain (283 hits) |

**What a hit gets the attacker: nothing.** A hit creates a one-sided claim.
A connection needs the code's owner to type the *attacker's* code, which they
never heard. The owner's code stays unique in the zone, so their real partner's
code can never be the attacker's. The only accidental path is the owner
mistyping their partner's code into exactly the attacker's live code: about
**1 in 10,000 per typo**, and the attacker would need to have claimed that
owner first. Realistically zero.

**What a hit costs the victim: a nuisance.** When their real partner then
enters the code, that is a second person, so the code is cancelled, a fresh one
appears, and they see "Two people entered your code". They retry in seconds.

**Disagreement.** The Cynic: "Botnets turn the alert into a griefing tool at
conferences." PSA: "True, but it never connects anyone." **Resolution:** keep
the limits; split big events into one zone per hall [A ≤300 live codes per
zone]; admin can suspend devices; watch alert rates in the pilot.

## 5. Zone spoofing and venue codes from afar

Venue zones (10–49) require one of:
- the **QR token** on the table tent (rotates weekly), or
- zone number + the **two-word table word**, e.g. "maple fox" (about 5,000 combinations, rotates weekly; wrong words are limited per device and per network address. Changed from one 4-letter word after the code review showed 71 words could be worked through from home),
- and the zone's **opening-hours window**.

A photo of a table tent posted online works for at most a week, only during
opening hours. Area zones (50–99) rely on the phone's rounded location, which
any browser can fake. In both cases the real defence is **mutual entry**: you
still need a person in the room to say their code to you and type yours.
Zones mainly keep code collisions low and make guessing pointless.

**[R]** Show "valid this week" on the tent and let staff rotate the word early
from the dashboard if a photo leaks.

## 6. Invite links: risk analysis and sign-off

| Risk | Why |
|---|---|
| Forwarding | A link moves to people nobody met; breaks "met in person" |
| Screenshots | One-time links get screenshotted and shared in group chats |
| Remote harassment | Lets a harasser bring in allies who were never there |
| Phishing | Fake "Handshake" links are easy to make |

Mitigations considered: single use, 15-minute expiry, approval still required,
bound to the first device that opens it. Even with all of them, the link proves
possession, not presence.

**Sign-off: declined for the MVP** by the Cynic and the PSA [D]. Designed, off,
not built. Revisit after the pilot only if evidence shows real demand (for
example, people asking to add a friend who just left) and report rates stay low.

## 7. Data inventory

| Data | Stored as | Kept for | Encrypted |
|---|---|---|---|
| Device token | SHA-256 only | Until idle purge [A 30 days idle] | Hashed |
| Age-gate acceptance | Timestamp on device | With device | No (not sensitive) |
| Personal / thread / group codes | HMAC-SHA256 of zone + digits | Deleted within ~2 min of expiry or match | Keyed hash |
| Zone number | Only on live codes | Same as codes | With code |
| Rounded location cell | Not stored; mapped to a zone and forgotten | Seconds (request only) | n/a |
| Location history | **Never stored** | — | — |
| Chats, memberships, aliases | Rows | 14 days (or extended), or until ended / dissolved | Aliases no |
| Messages | Text | Deleted with the chat | Yes, at rest |
| My details / reveals | Name, photo, handles, phone | Deleted with the chat or when edited | Yes, at rest |
| Join proposals and votes | Rows | Until decided or 10-minute timeout | No (no content) |
| Reports | Reason, note, optional last 20 messages | 90 days | Note and evidence yes [A] |
| IP addresses | Keyed hash, inside rate-limit counters only | 1–5 min windows | Hashed |
| Venue staff counts | Daily totals | Kept for the venue | No (aggregates) |
| Logs | Never codes, zones, IPs or message text | At most 7 days (`handshake/docs/OPERATIONS.md`) | n/a |
| Live-delivery queue (Solid Cable) | Rendered messages on their way to phones | Deleted when the chat ends; otherwise purged every minute after 10 minutes | No (short-lived) |
| Rate-limit counters | Hashed address, device digest, zone number | In memory only, for the window (1 min to 1 hour) | Hashed |
| Backups | Database copies | 7 days (`OPERATIONS.md`) | Encrypted |

**Honesty notes (PSA).** Messages are encrypted at rest, not end-to-end: the
server holds the keys, so someone with production key access could read live
chats. Deleted chats can survive in encrypted backups until those backups
expire [A 7 days]. IPv4 hashes can be brute-forced, which is why the hash is
keyed and only lives for minutes. Our copy must never say "instantly erased
everywhere" or "end-to-end encrypted".

## 8. Group-chat abuse

| Abuse | How it looks | Mitigation |
|---|---|---|
| Adding hostile members | A member sponsors their friends to outnumber someone | Unanimous by default; one "no" rejects; everyone notified; cap 8 including pending |
| Policy downgrade | Switch to "any member" then flood in allies | [R] Changing the policy needs unanimous agreement [O: confirm in app] |
| Pile-on | Several members gang up on one | Leave anytime, report, cap 8, newcomers can't see history |
| Removal vote weaponised | A majority votes out the person they target | Same policy as adding, counted without the target; target can always leave first; report covers it |
| Sponsor spam | One member keeps proposing strangers | Proposals time out in 10 min; [R] one open proposal per sponsor |
| Group handshake crashers | Strangers nearby enter the 2-minute code | Each joiner needs approval; code closes after 2 min |
| Identity exposure | A member screenshots someone's reveal | Reveals are pairwise only; we tell people a screenshot can't be stopped |

**Disagreement.** T&S wanted any report to freeze the chat so evidence
survives. PSA: "That keeps everyone's messages after they chose to end."
**Resolution:** evidence is the reporter's opt-in snapshot of the last 20
messages, kept 90 days. Nothing else is frozen.

## 9. Escalation flow (built for chats that vanish)

1. **In the moment:** "Leave" or "End chat" is always one tap away. The chat
   menu shows: "If you're in danger, call 911." [A: US pilot metro]
2. **Report:** reason + optional note; evidence toggle off by default with the
   line "Attach the last 20 messages so we can see what happened."
3. **Triage:** admin reviews within [A 24 hours]; urgent reasons (threats,
   minors) first.
4. **Action:** suspend the device (no new codes). No public "blocked" signal.
5. **Law enforcement:** we hand over only what exists: the report and its
   evidence. We tell reporters to keep their own screenshots too.
6. **Close:** reports purge at 90 days.

## 10. Residual risks

| Risk | Rating | Why it remains |
|---|---|---|
| In-person bad actors | High | The product starts with a real meeting; we can't vet people |
| Minors lying at the age gate | Medium | Self-declared; verified-human badge is optional and later |
| Evidence lost when chats vanish | Medium | Evidence is opt-in by design |
| Server-side key access | Medium | Not end-to-end; mitigated by access control and audit [R] |
| Area zone spoofing | Low | Mutual entry still required |
| Griefing alerts at big events | Low–Medium | Never connects anyone; split zones |
| Leaked table word photo | Low | One week, opening hours only, mutual entry |
| Screenshots of reveals | Medium | Can't be prevented technically; reveals are consent-based |
