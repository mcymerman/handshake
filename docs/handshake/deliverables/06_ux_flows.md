# Handshake — UX flows

*Deliverable 6. Voice: UX & Product Designer. Matches the prototype screens and
`00_decisions.md`. [A] = assumption, [R] = recommended, not built.*

## Design principles

- **Loud room, calm screen.** Assume a bar at 85 dB, one hand, a drink in the
  other. One big thing per screen, one obvious next tap.
- **Say it, don't spell it.** The code is built to be read aloud: three pairs,
  big digits, spaced like a phone number.
- **Nothing is silent.** Every join, reveal and removal is shown to the people
  it affects.
- **Mobile-first at 390 px.** Desktop is the same column, centred.

## Flow at a glance

```
Welcome / age gate → Choose your zone → Home (my code + enter theirs)
                                          │
                            both entered  ▼
                    Chats list ◄──────► Chat screen
                                          │ menu
      ┌───────────────┬─────────────┬─────┴──────┬────────┬──────────────┐
  Add someone   Group handshake   People &    Extend   Report     Leave / End
                                  reveals
  Newcomer: enter code → "Waiting for approval" → joins chat
Venue: Table tent (print) · Live display · Staff dashboard   Admin: Reports
```

## Screens

### 1. Welcome / age gate
- Headline: **"Meet someone? Keep talking."**
- One line: "Swap a short code, chat privately. No numbers, no handles."
- Checkbox: **"I'm 18 or older"** and a link to the terms. Button: "Let's go".
  The button stays disabled until the box is ticked.
- If unticked and tapped: "Handshake is for adults. Tick the box if that's you."

### 2. Choose your zone
Three large choices, top to bottom:
1. **Scan the table tent** — opens the camera; the QR carries the weekly token.
2. **Type zone + table word** — two fields: zone (2 digits, numeric keypad)
   and table words (two short words like "maple fox"; spaces, dashes and capitals don't matter).
3. **Use my area** — explainer under the button: "Your phone rounds your
   location to about 1 km before sending it. We never keep it."
- Errors:
  - Wrong word: "That table word doesn't match. Check the card on your table."
  - Outside hours: "This venue's zone is closed right now. Try 'Use my area'."
  - Location denied: "No problem. Scan the table tent or type the zone instead."

### 3. Home
- Big code, 48 px+, monospaced: **47-12-83**, with "Your code" above it.
- A **60-second countdown ring** around the code. At 0 it quietly swaps to a
  new code; no tap needed.
- **"Enter their code"** box: numeric keypad, auto-inserts dashes as you type
  (`4` `7` → `47-`). Submits on the sixth digit.
- **Waiting state** after you enter theirs: the box shows their code with a
  soft pulse and **"Waiting for them to enter your code"**. Your code stays big
  so you can read it to them.
- **Matched:** "You're connected" and straight into the chat.
- **Alert** (eavesdropper): a banner in amber, not red: **"Two people entered
  your code, so we made you a fresh one. Read the new one to the person you're
  with."**
- Error states:

| State | Copy |
|---|---|
| Typo / no such code | "Hmm, that code isn't live. Check the digits and try again." |
| Expired | "That code just expired. Ask them for the new one." |
| Wrong zone | "That code is from a different area. Are you both in the same place?" |
| Zone paused | "This zone is taking a two-minute breather. Try again shortly." |
| Device locked | "Too many tries. Take five minutes, then have another go." |
| Suspended | "This device can't make new codes. Contact us if you think that's a mistake." |

### 4. Chats list
- One row per chat: alias(es), last message preview, **"vanishes in N days"**.
- Pending approvals show a small dot and "1 person waiting to join".
- Empty: "No chats yet. Show your code to someone you've met."

### 5. Chat screen
- Header: chat name (aliases, or "Group of 4"), **"vanishes in N days"**.
- Messages in order; your own on the right. Members who left show "(left)".
- Composer pinned to the bottom, 44 px send button.
- **Pending approval banner** at the top: "Coral Fox wants to add someone.
  Approve?" with **Approve** and **Decline** (equal size, no dark pattern).
  Shows "Waiting on 2 people · 8 min left".
- **Menu:** Add someone · Group handshake · People & reveals · Extend 14 days ·
  Report · Leave (group) / End chat (1:1).
- End chat confirm: **"End this chat for both of you? It will vanish for them
  too."** Buttons: "End chat" / "Keep chatting".
- Extend: "You'd like 14 more days. We'll extend when everyone taps it."

### 6. Add someone
- Top: the one-time **thread code** with a 60 s ring: "Show this to the new
  person."
- Below: "Enter their code" (same keypad box as Home).
- Done: "Sent to the group for approval. Nobody joins until they agree."
- Full: "This chat is full (8 people, including anyone waiting)."

### 7. Group handshake
- Large code with a **2-minute ring**: "Anyone here can enter this. You'll
  all approve each person before they join."
- Live count: "2 people waiting for approval".

### 8. Newcomer: waiting for approval
- "You're in the queue. The group is deciding." Calm spinner, timer
  "up to 10 minutes".
- Approved: "You're in! You'll see messages from now on."
- Declined or timed out: "This one didn't work out. No hard feelings." (Never
  says who declined.)

### 9. People & reveal ladder
- One card per person, by alias. Three steps as a ladder:
  1. First name + photo 2. Social handles 3. Phone
- Each step shows one of: "Share" / "You've offered, waiting for them" /
  "Shared both ways" (and the detail appears).
- Line under the ladder: **"Only this person sees what you share. Never the
  whole group."**

### 10. My details
- First name, photo, socials, phone. Every field optional.
- Note: "Saved privately. Shared one person at a time, only when you both
  agree."

### 11. Report
- Reason (radio list): Harassment · Threats · Scam or spam · Underage ·
  Something else. Optional note.
- **Evidence toggle, off by default:** "Attach the last 20 messages so we can
  see what happened."
- Under it: "If you're in danger, call 911." [A: US pilot metro]
- Sent: "Thanks for telling us. You can leave this chat anytime."

### 12. Venue table tent (printable)
See the mock below. A4/Letter folded, both faces identical.

### 13. Venue live display
- Full-screen for a TV or tablet: zone number, QR, table word, today's theme
  ("Thursday trivia, 7–10 pm"), and "Say hi. Swap codes. That's it."
- No counts on the public display [R], so a quiet night never looks empty.

### 14. Staff dashboard
- Connections and groups per day, last 7 days. Under 3 shows **"fewer than
  3"**. No names, aliases, times of day or messages. Button: "Rotate table
  word now" [R].

### 15. Admin reports
- List: reason, date, status. Detail: note, evidence only if attached, device
  status. Action: **Suspend device** or **Close**. "Deletes automatically 90
  days after it was made."

## Table tent mock

```
+--------------------------------------------+
|                                            |
|            HANDSHAKE  ·  ZONE              |
|                                            |
|                  4 7                       |
|                                            |
|          +----------------+                |
|          |  ▓▓ ▓ ▓▓▓  ▓▓  |   Table word   |
|          |  ▓  ▓▓ ▓ ▓▓ ▓  |                |
|          |  ▓▓▓ ▓  ▓▓▓ ▓  |     M O S S    |
|          |  ▓ ▓▓▓ ▓ ▓  ▓  |                |
|          +----------------+  valid this    |
|          scan to start       week          |
|                                            |
|   1  Scan, or type 47 + the table word     |
|   2  Read your code to them. Type theirs.  |
|   3  Chat. No numbers, no handles.         |
|                                            |
|   18+ · We never keep your location.       |
+--------------------------------------------+
```

## Accessibility

- **Large text:** code at 48 px+, body 18 px, respects system text size up to
  200% without clipping; the code wraps to two lines before shrinking.
- **Contrast:** 4.5:1 minimum for text, 3:1 for the countdown ring; alerts use
  icon + words, never colour alone.
- **Screen readers:** the code is read as pairs ("forty-seven, twelve,
  eighty-three"); the ring announces at 30 s and 10 s only, not every second;
  the waiting state and alerts are live regions; Approve/Decline say what
  they approve ("Approve adding a new person").
- **Touch:** 44 px minimum targets; keypad digits 56 px.
- **Motion:** the pulse and ring stop under "reduce motion"; a number
  countdown takes over.
- **390 px phones:** everything in one column, no horizontal scroll, composer
  stays above the keyboard.
- **Noisy rooms:** [R] a "Show big" tap fills the screen with the code so the other
  person can read it instead of hearing it.
