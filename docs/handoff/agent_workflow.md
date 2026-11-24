# Continuing instructions for future agents

This workflow complements [CLAUDE.md](../../CLAUDE.md). It is intended to survive
new chats, model changes, compaction and handoff. It does not authorize new work
or override current user instructions.

## Start or recover a session

1. Establish the user request, current date/time zone and authorized scope. A
   follow-up usually steers the same task; preserve unfinished requirements.
2. Run `git status --short --branch`; read `CLAUDE.md`, this package's
   [index](README.md), [state](project_state.md) and relevant [history](history_and_decisions.md).
   Inspect branch/HEAD and local tracking refs. A tracking ref may be stale until
   fetched; a clean working tree does not establish deployed state.
3. Read the foundational map, rollout checklist, root backlog, production ledger,
   newest recursive logs and applicable spec/questions/decision records. Read
   today's and yesterday's logs if present; otherwise read the newest available.
4. Inspect actual code and tests for the behavior. Identify stale documentation,
   ambiguous permissions, outstanding changes and reproduction gaps explicitly.
5. Briefly state what you learned, relevant assumptions, and the next useful
   action. Ask only for missing information that blocks the work; do not request
   permission again for actions already authorized in the current scope.

After compaction, branch/dependency/migration changes or a server restart, repeat
the applicable bootstrap checks. Read a [session handoff](session_template.md)
and `git diff` before changing existing work. Do not restart completed work or
silently drop pending verification, an email obligation or a failed operation.

## Record decisions while doing the work

Update a dated daily log during meaningful work. Use the established month folder
when one exists; find earlier flat files recursively. Record the user request,
corrections/rejections, source state, changes, failures/root causes, exact commands
and results, external mutations, deployment/server status and remaining risks.
Mark retrospective reconstruction as inferred and avoid invented precision.

For a durable new decision, write a decision record when useful, or reference the
specific daily-log section from current docs/spec questions. Clearly mark a
proposal, accepted direction, rejected/superseded option and unresolved question.
Do not create a fictional transcript to fill gaps in the conversation history.

Keep each type of documentation in its canonical location. Completed work leaves
the backlog after its result is recorded; the production ledger remains until
release/reconciliation, then moves into a dated release archive. A short branch
summary is not a substitute for the log. Add document-map links for new artifacts.

## Local implementation and validation

Record this project's exact runtime, test and server commands in
`docs/foundational/01_development_setup.md` once the stack is chosen, and use
them every time. Start with the failing behavior, test the relevant permission
and failure paths, then broaden when shared behavior is involved. Never report
old test counts as a fresh run.

For visible UI changes, use isolated headless Chrome, review desktop and 390px
mobile captures, and test the real interaction. Protect the user's own browser
and session.

## Review, Git and production

Default to local implementation/validation and a review handoff. A historical
approval is scoped to its batch. Obtain a current deployment instruction before
new production mutations; `origin/dev` push permission alone is insufficient.

Before a requested commit/push, inspect status/diff and `git diff --check`, and
exclude secrets and unrelated work. Run and record the project's statistics
command when one exists.

An authorized release uses the documented deployment path, a fresh backup
first, the exact reviewed source revision, migration and health checks, and a
scoped shakeout. Inspect the latest
release and operational runbooks first; deployment commands are not instructions
to execute during onboarding. Never source or print secret files just to learn
the project. Keep customer content and routing identifiers out of handoff exports.

After every production deployment, send the standing completion email to
mcymerman@gmail.com through the recorded mail path and confirm delivery handoff. Include
failed deployment/rollback outcomes honestly. If email fails, leave it outstanding
and tell the user. Transport acceptance is not proof of inbox receipt.

## Before stopping or transferring work

- Update the daily log and relevant current docs/spec questions/tasks.
- Update backlog, release ledger/archive, branch summary and this package if
  their scope changed. Date evidence and identify any stale/unreconciled item.
- Record what was actually tested, unresolved failures, server/asset status,
  source versus deployed revision, external effects and production approval scope.
- For unfinished work, fill the session template with the immediate next step
  and paths to evidence. Do not copy secrets, user sessions or private messages.
- Give a concise self-contained user handoff with links, completed outcome,
  limitations and any exact approval/action still required.
