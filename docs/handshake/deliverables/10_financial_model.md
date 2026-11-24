# 10 — Financial model (18 months: Dec 2026 – May 2028)

Owner: Finance Analyst (agent 12), with Sales (6), BizDev (2) and Data (14).
The month-by-month numbers are in `10_financial_model.csv` (one row per month
plus an 18-month total row). Every total in the CSV was computed by script, and
revenue minus costs equals net income in every row.
Labels: **[D]** decided, **[A]** assumption, **[O]** open. Nearly everything
here is an assumption: we have no customers yet.

## 1. The headline

- **Base case break-even month: March 2028** (month 16). Revenue $33,675 vs
  costs $29,701. It stays profitable through April and May 2028.
- **Cash needed:** the deepest point is **−$114,447 at the end of February 2028**.
  With a 20% buffer, plan for about **$140,000** of founder money, grants or
  investment to get there [A].
- **18-month totals:** revenue $271,260; costs $358,353; net −$87,093.
- **May 2028 run-rate:** $43,540 revenue, $30,229 costs, $13,311 monthly profit.
- **Bear case:** no break-even within 18 months (still −$4,913 in May 2028);
  cash need about $198,000. **Bull case:** first profitable month October
  2027, steady profit from January 2028; cash need about $78,000.
- **Gross margin is high (about 95%)** because hosting is cheap. The business
  question is whether enough events and venues pay, not whether the servers are affordable.

## 2. User assumptions

MAU = devices active in a month, estimated from daily aggregate counters (no
per-person tracking). [A] for every number.

| Period | MAU (end of month) | Why |
|---|---|---|
| Dec 2026 | 200 | Demo meetup, team testing |
| Jan–Feb 2027 | 1,500 → 3,000 | First two conferences (~25% of attendees try it) |
| Mar–Apr 2027 | 5,000 → 7,000 | Neighbourhood pilot + 2 events a month |
| May–Aug 2027 | 9,000 → 15,000 | Venues expand from 2 to 14; summer is slow for events |
| Sep–Nov 2027 | 20,000 → 32,000 | Universities, coworking, conference season |
| Dec 2027 | 36,000 | Holiday dip in events, venues keep growing |
| Jan–May 2028 | 42,000 → 72,000 | ~80 venues, second neighbourhood, 2–5 events a month |

## 3. Revenue lines

| Line | Assumption | May 2028 | 18-month total |
|---|---|---|---|
| Premium subscriptions | $5/month [A]. Launches May 2027. Active subscribers = 1.0% of MAU in May 2027, rising to 2.5% by Mar 2028 [A] | 1,800 subs → $9,000 | $49,280 |
| Event licences | Events per month 0–5 [A] × average price rising from $1,500 (founding) to $3,500 [A] | 5 events → $17,500 | $125,500 |
| Venue partnerships | Paying venues (2 in May 2027 → 80 in May 2028) × blended $120/month (mix of $79/$149/$299, founding venues at $79) [A] | 80 → $9,600 | $54,600 |
| Community / enterprise | Accounts (1 in Jun 2027 → 12) × blended $500/month (from $400) [A] | 12 → $6,000 | $34,000 |
| Verified badge | $4 one-time [A]. Launches Sep 2027. 0.5% of MAU buy one each month [A] | 360 → $1,440 | $7,880 |
| **Total** | | **$43,540** | **$271,260** |

Revenue mix over 18 months: events 46%, venues 20%, premium 18%,
community 13%, badge 3%. Events are lumpy and seasonal (see July and December dips).

## 4. Cost lines

| Line | Assumption | May 2028 | 18-month total |
|---|---|---|---|
| Hosting | $75/month base (one 2 GB VM ~$24 + managed Postgres ~$50, from `00_decisions.md`) + $0.006 per MAU for scaling, Redis past ~1k concurrent sockets, backups and monitoring [A] | $507 | $4,102 |
| ID-check fees | $1.50 per badge check paid to the third-party vendor [A] | $540 | $2,955 |
| Payment fees | Cards: 2.9% + $0.30 per transaction on subscriptions and badges; invoices (events, venues, community): 1% [A] | $1,282 | $7,346 |
| People | See below [A]. Michael unpaid | $21,000 | $253,000 |
| Marketing | Materials, drops, events, travel, website; no paid ads (see `08_go_to_market.md`) [A] | $6,000 | $68,000 |
| Legal | Dec 2026 $4,000 (terms, privacy policy, age gate review, name clearance); Feb 2027 $2,000 (trademark filing); Sep 2027 $1,000 (badge vendor/privacy review); Mar 2028 $1,000 (annual review); otherwise $500/month [A] | $500 | $16,000 |
| Insurance | General liability + cyber + professional liability, $250/month from Jan 2027 [A] | $250 | $4,250 |
| Software and admin | Email, domain, design tools, accounting, $150/month [A] | $150 | $2,700 |
| **Total** | | **$30,229** | **$358,353** |

**People plan [A]** (contractors, not employees, for the first 18 months):

| From | Who | Monthly cost | People line |
|---|---|---|---|
| Dec 2026 | Part-time Rails developer | $6,000 | $6,000 |
| Feb 2027 | + part-time Community and Venue Lead | $3,000 | $9,000 |
| Mar 2027 | + part-time Trust & Safety moderator (reports, same-day venue response) | $1,500 | $10,500 |
| Sep 2027 | + part-time sales/BD ($3,500); Community Lead goes full-time (+$2,000) | $5,500 | $16,000 |
| Jan 2028 | Developer goes full-time (+$5,000) | $5,000 | $21,000 |

The 14 "agents" are a planning device; real work needs these real people.

## 5. Month by month (summary of the CSV)

| Month | MAU | Premium subs | Revenue | Direct costs | Operating costs | Net | Cumulative |
|---|---|---|---|---|---|---|---|
| Dec 2026 | 200 | 0 | $0 | $76 | $10,650 | −$10,726 | −$10,726 |
| Jan 2027 | 1,500 | 0 | $1,500 | $99 | $10,400 | −$8,999 | −$19,725 |
| Feb 2027 | 3,000 | 0 | $1,500 | $108 | $13,900 | −$12,508 | −$32,233 |
| Mar 2027 | 5,000 | 0 | $4,000 | $145 | $14,900 | −$11,045 | −$43,278 |
| Apr 2027 | 7,000 | 0 | $4,000 | $157 | $14,900 | −$11,057 | −$54,335 |
| May 2027 | 9,000 | 90 | $5,690 | $221 | $13,900 | −$8,431 | −$62,766 |
| Jun 2027 | 11,000 | 132 | $6,760 | $261 | $14,400 | −$7,901 | −$70,667 |
| Jul 2027 | 13,000 | 182 | $4,990 | $275 | $14,400 | −$9,685 | −$80,352 |
| Aug 2027 | 15,000 | 240 | $6,380 | $324 | $14,400 | −$8,344 | −$88,696 |
| Sep 2027 | 20,000 | 360 | $15,100 | $676 | $22,400 | −$7,976 | −$96,671 |
| Oct 2027 | 26,000 | 520 | $20,360 | $884 | $21,900 | −$2,424 | −$99,095 |
| Nov 2027 | 32,000 | 672 | $19,580 | $1,028 | $20,900 | −$2,348 | −$101,444 |
| Dec 2027 | 36,000 | 792 | $15,240 | $1,094 | $19,900 | −$5,754 | −$107,198 |
| Jan 2028 | 42,000 | 966 | $21,450 | $1,317 | $26,400 | −$6,267 | −$113,465 |
| Feb 2028 | 48,000 | 1,152 | $27,460 | $1,543 | $26,900 | −$983 | −$114,447 |
| **Mar 2028** | 55,000 | 1,375 | $33,675 | $1,801 | $27,900 | **+$3,974** | −$110,473 |
| Apr 2028 | 63,000 | 1,575 | $40,035 | $2,066 | $27,900 | +$10,069 | −$100,405 |
| May 2028 | 72,000 | 1,800 | $43,540 | $2,329 | $27,900 | +$13,311 | −$87,093 |

Direct costs = hosting + ID checks + payment fees. Operating costs = people +
marketing + legal + insurance + software. Figures rounded to the dollar here; the CSV has cents.

## 6. Unit economics

All [A]; they become real only once the pilot and first events report.

- **Premium.** $5 price − $0.30 − $0.145 card fees = **$4.56 net per month**.
  Assumed average life 8 months (12.5% monthly churn) → **lifetime value ≈ $36**.
  If 30% of marketing spend is credited to premium sign-ups, CAC ≈ $20,400 ÷
  1,800 subs ≈ **$11** → LTV:CAC ≈ 3.2.
- **Blended ARPU per active device:** $43,540 ÷ 72,000 = **$0.60/month** in May 2028.
- **Consumer CAC (upper bound):** $68,000 total marketing ÷ 72,000 MAU reached ≈
  **$0.94 per active device**, crediting every marketing dollar to consumers.
- **Venue.** $120/month, ~99% margin after invoice fees and hosting. Assumed 5%
  monthly churn → ~20-month life → **LTV ≈ $2,380**. CAC ≈ $300 (about 6 hours
  of sales/community time at $40, $60 of tents and posters) → LTV:CAC ≈ 8.
- **Event.** Average $3,000; direct cost about $1,150 (materials $400, travel
  $350, ~10 hours of sales time $400) → **about $1,850 contribution (62%)**.
  Rebooking assumed 50% [A].
- **Gross margin:** 94.7% over 18 months ($271,260 revenue − $14,403 direct costs).

## 7. Pricing tests

| Test | When | Variants | What we watch (aggregate only) | Decision rule |
|---|---|---|---|---|
| Premium price | May–Jul 2027 | $4 / $5 / $6 / $8, shown to new visitors by week (one price per week, not per person) | Weekly new subscriptions and cancellations | Pick the highest-revenue price unless cancellations double |
| Venue tiers | Jun–Aug 2027 | Starter at $59 vs $79 for new venues in alternate months | Trial-to-paid rate | Keep $79 unless $59 converts ≥ 1.5× better |
| Event pricing | Sep–Nov 2027 | Per-attendee ($3/attendee, min $1,500) vs current bands | Win rate, average deal | Choose higher average revenue per proposal |
| Badge | Sep–Oct 2027 | $3 / $4 / $6 one-time | Weekly purchases | Must cover $1.50 vendor fee + fees with margin |

Modelled premium outcome at May 2028 MAU, with assumed sign-up changes
(+25% at $4, −15% at $6, −40% at $8) [A]: $4 → 2,250 subs, $9,000; $5 →
1,800 subs, $9,000; $6 → 1,530 subs, $9,180; $8 → 1,080 subs, $8,640. Price
barely moves revenue; **$5 keeps more people on premium for the same money**, so it stays the default.

Weekly-price variants avoid per-person experiment tracking, which would break
the privacy rules.

## 8. Sensitivity

| Scenario | Users | Premium/badge uptake | Events, venues, community | Break-even | Lowest cash | May 2028 revenue | 18-month revenue |
|---|---|---|---|---|---|---|---|
| Bear | ×0.6 | ×0.7 | ×0.6 | Not within 18 months (extrapolated ~Aug 2028) | −$198,146 | $24,144 | $153,528 |
| **Base** | ×1.0 | ×1.0 | ×1.0 | **Mar 2028** | −$114,447 | $43,540 | $271,260 |
| Bull | ×1.4 | ×1.2 | ×1.4 | Oct 2027 (dips in Dec 2027, steady from Jan 2028) | −$78,258 | $63,980 | $394,711 |

Costs are held the same in all three (people and marketing are planned, not
driven by volume). Other quick sensitivities:
- **Michael draws $5,000/month from Jan 2028:** break-even moves to **April 2028**.
- **Events stay at the $1,500 founding price:** the 18-month event revenue drops by
  $62,500 (42 events × $1,500 = $63,000 instead of $125,500) and break-even slips to
  **April 2028**, with the cash low point about $38,500 deeper (about −$153,000, in March 2028). Events are the most important assumption.
- **Hosting costs double:** about +$4,100 over 18 months; break-even unchanged.
- **Venue churn 10% instead of 5%:** roughly 20 fewer venues by May 2028 (about −$2,400/month) [A, rough estimate]; break-even likely stays March 2028 but with a thin margin.

## 9. What this model does not include

- Founder salary, taxes, company formation, sales tax/VAT handling.
- Any fundraising costs or equity.
- Revenue from dating/social venues (gated, earliest test Mar–Apr 2028).
- A second metro (needs a zone region prefix first).
- Refunds and bad debt (assume small; invoices are prepaid where possible).

## 10. Disagreements

- **Cynic vs Finance on event revenue.** Cynic: "46% of revenue from one-off
  events is a services business wearing a software costume." Finance accepts the
  risk; the plan requires venues + community to reach ~34% of monthly revenue by
  Nov 2027 and ~36% by May 2028 (model: $15,600 of $43,540).
- **Sales vs Finance on premium conversion.** Sales wanted 4%. Finance kept 2.5%
  as a ceiling because chats are short-lived by design and most people need only
  the free tier. Upside sits in the bull case.
- **Privacy Architect vs Data on price testing.** Data wanted per-person A/B
  tests. **Resolved:** one price per week for everyone; compare weeks.

## 11. How the CSV is built

Columns, in order: month, mau, premium_subs, paid_events, paying_venues,
community_accounts, badges_sold, five revenue columns, revenue_total, three
direct-cost columns, cogs_total, five operating-cost columns, opex_total,
costs_total, net_income, cumulative_cash, gross_margin_pct. The final row
(TOTAL_18M) sums each money column. Check: revenue_total − costs_total =
net_income in every row, and cumulative_cash in May 2028 equals the 18-month net (−$87,093.43).
