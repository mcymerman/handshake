# Handshake — the Cynic's final report

*Deliverable 12. Voice: the Cynic. Ranked by how likely each risk is to kill
the company, not by how embarrassing it would be. [A] = assumption. Every
"evidence we have" below is honest: we have a prototype built to
`00_decisions.md` and no real users yet.*

## Summary table

| # | Risk | Residual |
|---|---|---|
| 1 | User apathy: people just swap Instagram | High |
| 2 | Cold start: nobody else in the room has heard of it | High |
| 3 | Safety misuse and stalking | Medium |
| 4 | Revenue concentrated on events | Medium–High |
| 5 | Platform limits (iOS, browser background, camera, location) | Medium |
| 6 | Copycats: Apple, Meta, Snap ship it as a feature | Medium |
| 7 | Venue churn | Medium |
| 8 | Regulatory: minors, GDPR, age laws | Medium |
| 9 | 4-digit code space at large conferences | Low–Medium |
| 10 | Group pile-ons | Low |

---

### 1. User apathy: people just swap Instagram
- **Why it kills us:** Instagram, WhatsApp and NameDrop already work in ten
  seconds. If "private first chat" isn't a felt need, nobody opens us twice.
- **Evidence we have:** none from users. Only the intuition that many people
  hesitate to hand a stranger their real handle.
- **Evidence we don't:** whether that hesitation is strong enough to change
  behaviour in a loud bar.
- **Mitigation in plan:** no install, no account, one code each way; the
  reveal ladder lets you move to Instagram later, so we're the safe first step,
  not a replacement.
- **Residual: High.**
- **Early test:** pilot weeks 1–3. Of chats opened, ≥40% have ≥3 messages from
  each side, and ≥35% of chats have messages on a second day [A
  thresholds; both are daily totals on the admin Metrics page, no per-person tracking]. Below half of that, stop and rethink.

### 2. Cold start: nobody else in the room has heard of it
- **Why it kills us:** a handshake needs *both* people to know Handshake.
  Every first use requires a pitch in the moment.
- **Evidence we have:** the web page needs no install, so the other person can
  join from the table tent in under 30 seconds [A, untested].
- **Evidence we don't:** real time-to-first-chat for a person who's never seen it.
- **Mitigation in plan:** conferences first (everyone is told at once), table
  tents in pilot venues, trivia-night themed zones.
- **Residual: High.**
- **Early test:** measure median "first visit to first chat" at the first
  event; target under 60 seconds and ≥25 chats per venue per week by pilot
  week 4 [A].

### 3. Safety misuse and stalking
- **Why it kills us:** one news story ("met a stalker through Handshake") ends
  venue partnerships overnight.
- **Evidence we have:** the design gives stalkers little: no location history,
  aliases per chat, mutual entry, End chat deletes for both, reveals need both.
- **Evidence we don't:** how real bad actors behave; report rates.
- **Mitigation in plan:** report with opt-in evidence, device suspension, 18+
  gate, "call 911" line, 90-day report retention.
- **Residual: Medium.** The product starts with an in-person meeting. We
  can't vet the person across the table.
- **Early test:** reports per 1,000 chats in the pilot; any threat-level
  report triggers a review before expansion. Target <5 per 1,000 [A].

### 4. Revenue concentrated on events
- **Why it kills us:** events ($1,500–$7,500 each [A]) are lumpy and seasonal.
  If 70%+ of revenue is events [A], one bad conference quarter empties the bank.
- **Evidence we have:** none signed.
- **Evidence we don't:** whether organisers pay for "attendee connection"
  when their event app already claims to do it.
- **Mitigation in plan:** venues $79–$299/month and premium $5/month as
  recurring base; community tiers from $400/month.
- **Residual: Medium–High.**
- **Early test:** three signed letters of intent from organisers by pilot
  week 6; at least one paid venue renewal after the free period.

### 5. Platform limits
- **Why it kills us:** iOS Safari pauses background tabs and drops live
  connections, so "waiting for them" can stall and messages arrive late. Web
  push on iOS needs a home-screen install. Camera and location prompts scare
  people off.
- **Evidence we have:** the flow works on one screen in the foreground; typing
  slack of 10 s on codes.
- **Evidence we don't:** real reconnect behaviour on iPhones in a bar with
  bad signal.
- **Mitigation in plan:** zone by table word needs no camera or location;
  chat reloads on return; no reliance on push for the handshake itself.
- **Residual: Medium.**
- **Early test:** device lab on 5 iPhones and 5 Androids before the pilot:
  ≥95% of handshakes complete; messages appear within 3 s after a tab returns.

### 6. Copycats
- **Why it kills us:** Apple (NameDrop), Meta or Snap could add "temporary
  chat with someone nearby" in one release, to a billion users.
- **Evidence we have:** they've shipped contact-sharing, not anonymous
  expiring chats. Their business models lean on identity and data.
- **Evidence we don't:** their roadmaps.
- **Mitigation in plan:** the promise they can't easily copy: no ads, no
  location history, no account; venue and event relationships.
- **Residual: Medium.**
- **Early test:** in pilot interviews, ask "why not just use X?" If over half
  say "I would if it existed there", our moat is the promise, so lead
  marketing with it.

### 7. Venue churn
- **Why it kills us:** venues are the distribution. If they stop putting out
  tents after a month, zones go dark and the neighbourhood loop breaks.
- **Evidence we have:** none.
- **Evidence we don't:** whether a counts-only dashboard feels worth $79.
- **Mitigation in plan:** free pilot, themed nights, weekly table word gives
  staff a reason to touch it, live display.
- **Residual: Medium.**
- **Early test:** all 3 pilot venues still displaying tents in week 8, and at
  least 1 of 3 says yes to paying.

### 8. Regulatory: minors, GDPR, age laws
- **Why it kills us:** a minor using a stranger-chat product is the worst
  headline and a legal problem. GDPR and US state privacy and age-assurance
  laws are tightening.
- **Evidence we have:** we store little and briefly, which helps a lot.
- **Evidence we don't:** legal review in the pilot metro; whether a self-
  declared 18+ box will satisfy regulators.
- **Mitigation in plan:** 18+ gate, "Underage" report reason, venue-only
  adult settings in the pilot, optional third-party verified-human badge later.
- **Residual: Medium.**
- **Early test:** a lawyer's review of terms and age gate before the pilot;
  zero underage reports in the pilot.

### 9. 4-digit code space at large conferences
- **Why it kills us:** 10,000 codes per zone. With 2,000 phones open in one
  zone, 20% of the space is live: about 1 in 5 typos hits a stranger's code and
  triggers a "Two people entered your code" alert. Remote guessing (section 4
  of the threat model) still never connects anyone, but the noise could make
  the product feel broken.
- **Evidence we have:** the math; mutual entry makes a hit harmless.
- **Evidence we don't:** typo rates in practice.
- **Mitigation in plan:** one zone per hall or floor, aim for ≤300 live codes
  per zone (3% typo hit rate) [A]. Note there are only 40 venue zones (10–49)
  in the metro, so a big event can't take more than about 10 [A].
- **Residual: Low–Medium.**
- **Early test:** at the first conference, alert rate per 100 handshakes; act
  if above 3.

### 10. Group pile-ons
- **Why it kills us:** a group used to gang up on one person is a safety story.
- **Evidence we have:** unanimous approval by default, cap 8, newcomers can't
  see history, leave anytime, reveals pairwise.
- **Evidence we don't:** whether people switch to "any member" and abuse it.
- **Mitigation in plan:** the above plus report; recommended: policy changes
  need unanimous agreement.
- **Residual: Low.**
- **Early test:** share of groups not on unanimous, and reports from groups vs.
  1:1 chats. Act if group report rate is 2× the 1:1 rate.

---

## Where the team pushed back

- **Business Development** argued risk 2 should be Medium because conferences
  solve cold start. The Cynic held at High: a conference is three days, then
  everyone goes home. **Resolution:** High stays until we see repeat use after
  an event.
- **Security** wanted invite links kept off forever. **Resolution:** off for
  the MVP; revisit only with pilot evidence (see threat model, section 6).

## The Cynic's verdict

The privacy design is genuinely good, and it is the one thing a giant can't
copy without changing who they are. But the real risk isn't technical: it's
whether two strangers in a noisy bar will bother with codes when Instagram is
already on their phones. Build the pilot, keep it cheap, and stop if fewer than
40% of chats get past three messages each way by week 3. (The prototype counts this as a daily total, "back-and-forth rate" on the admin Metrics page, without tracking anyone.)
