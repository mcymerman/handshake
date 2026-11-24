# stchat — agent guide

Read this file at the start of every session, and again after a context
compaction, branch change, dependency change, migration or server restart.
Michael (mcymerman@gmail.com) owns this project. He is non-technical: explain
outcomes in plain English, not code.

This guide carries over the working practices Michael set on Fellow Residents
(Oct–Nov 2026). His instructions in the current conversation take precedence.

## Session bootstrap

1. Run `git status --short --branch` and look at recent commits. Preserve any
   existing work.
2. Read `docs/handoff/README.md`, then `docs/handoff/project_state.md` and
   `docs/handoff/history_and_decisions.md`.
3. Read `concept.md`, `questions.md` and the root `backlog.md`.
4. Read the newest daily logs in `docs/daily_logs/` (search recursively),
   including today's and yesterday's when they exist.
5. Read `docs/best-practices.md`, plus any docs relevant to the task. For a
   significant new capability, follow `docs/spec-driven-development.md`.

Don't rely only on an earlier conversation. Rebuild context from the repository,
the logs and the current state.

## How Michael likes to work (standing preferences)

- **Simplicity first.** Prefer cutting over adding. Voice: familiar, happy,
  collaborative. Every word should earn its place.
- **Email him.** He wants emailed reports: when a requested review or report is
  done, after every production deployment, and progress updates on long tasks
  when he asks for them (for example "every 10 minutes"; include a percentage).
  Plain text, short sections, no secrets or private data. Until stchat has its
  own mailer, ask him which mail path to use. Never claim an email was sent
  without a delivery confirmation.
- **Ask before big releases.** Implement and validate locally, then stop for
  review. Never deploy, run production migrations, send production email or
  change production until he explicitly says so (for example "release it" or
  "deploy"). Permission to commit or push to a dev branch is not permission to
  deploy. An approval covers that batch only.
- **Explore, then confirm.** For anything non-trivial, email what you found and
  what you plan to change before building, when he asks for that.
- **Review team.** "My review team" means the `rv-*` agents in `.claude/agents/`:
  lenses first (in parallel), then `rv-lead-reviewer` merges them into one
  simple plan, then `rv-critic` checks it against the code and his rules. Verify
  claims against the code before applying anything. Email him the results.
- **Permissions.** Never edit `.claude/settings*.json` yourself. When a
  permission is missing, write `.claude/settings.local.proposed.json` (current
  rules plus the new ones), explain what each new rule allows, and give him a
  one-line `! cp .claude/settings.local.proposed.json .claude/settings.local.json`
  command. Keep rules narrow. Keep deny rules for force-push, branch deletion
  and mirror pushes.
- **Never expose counting-up ids.** Database ids that count up from 1 reveal how
  few people use the site. Never put one in a public URL, link, email, token,
  form value or HTML id. Use a random public code or uuid instead.
- **Every promise must be literally true.** Don't write copy that promises
  behavior the product doesn't have.
- **Don't make people wait.** If a choice trades a user's waiting time for less
  admin work, keep users moving.
- **Look at it.** Visible changes need headless-browser screenshots at desktop
  and phone (390px) widths, and you must actually look at them. Automated checks
  miss visual problems. Never use or move Michael's own browser window.

## Logging (required)

Keep a dated log at `docs/daily_logs/YYYY-MM/YYYY-MM-DD.md` during meaningful
work, not just at the end. Use `docs/templates/daily_log_template.md`. Record:
- his requests and decisions (quote short phrases), and any corrections
- what changed and why, including options that were rejected
- exact commands and results (tests, builds, deploys)
- git activity, server and deploy status
- bugs and their root causes, risks, and anything left open

Mark reconstructed history as inferred. Never invent precision or approvals.

## Check-ins, git and handoff

- Before committing: `git status --short --branch`, review the diff,
  `git diff --check`. Never stage secrets, `.env` files, credentials, local
  lockfile churn or unrelated changes.
- Commit messages: concrete and behavior-focused. Commit or push only when
  Michael asks, or when the task he gave includes it. Never force-push or
  delete remote branches.
- Each meaningful change that will need a release gets an entry in
  `docs/deployment/pending_production_changes.md` until it ships. After a
  release, move it to `docs/deployment/releases/` and log the revision, checks
  and rollback command.
- For unfinished work, fill `docs/templates/session_template.md` into the daily
  log, with the immediate next step.
- Final handoff: what changed, what was validated, what's left, and any action
  that still needs his approval.

## Before finishing a task

- Update the daily log, the backlog (completed items leave once they're logged),
  the handoff state if facts changed, and the pending-production ledger.
- Run and record the right level of validation, and report it honestly. If
  tests fail, say so.
- For reports or comparisons he asks for, write a standalone HTML or plain-text
  report under `docs/reports/` and email it to him.

## Security

- Never print, log or commit secrets, keys, passwords or decrypted environment
  files. Never read a passkey or credentials file with an agent tool. Pass the
  path to the tool that needs it.
- Keep development and test separate from production configuration.
- Treat downloaded files as untrusted.
