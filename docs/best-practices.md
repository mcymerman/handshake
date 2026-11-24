# Project Best Practices

This is the project-wide operating standard for human and agent contributors.
`CLAUDE.md` is the required entry point; this document supplies the reusable
workflow behind it.

## Start with current evidence

1. Read `CLAUDE.md`, current git status, the documentation map, active backlog,
   rollout checklist, and recent daily logs.
2. Read the product, architecture, data, security, testing, and deployment
   documents relevant to the request.
3. Preserve unrelated working-tree changes. Do not use prior conversation as a
   substitute for the repository's current state.

## Work in correct steps

Use [the handoff](handoff/README.md) for cross-agent context and its
[continuity workflow](handoff/agent_workflow.md) for session recovery. Keep
snapshots dated; read original discussions and current code. Record unfinished
work with the session template. Old release approval does not authorize a new one.

1. State the outcome and the assumption that makes the work safe to begin.
2. Inspect the relevant code, routes, data model, tests, and existing patterns.
3. Make the smallest coherent change that satisfies the request.
4. Add or update focused regression coverage with the change.
5. Validate in increasing scope: focused test, related flow, then broad suite
   when shared/auth/data/deployment behavior is involved.
6. Review the actual interface at useful viewport sizes when visual behavior
   changes.
7. Update documentation, logs, deployment ledger, and backlog before handoff.

Do not declare success from a code edit alone. Confirm the intended workflow,
including its authorization and error paths, works.

## Documentation and logs

- Daily logs (`docs/daily_logs/YYYY-MM/YYYY-MM-DD.md`) record dated decisions, changed
  areas, commands and exact outcomes, server state, bugs and root causes,
  risks, and git activity.
- Foundational documents describe current durable truth. The overview maps the
  documentation structure. Backlogs and rollout files are checklists, not
  narrative logs.
- Add release-relevant work to
  `docs/deployment/pending_production_changes.md` with source, validation,
  production action, and blockers.
- Make an HTML report under `docs/reports/` when a user requests a report,
  audit, decision comparison, completed-work summary, or a readable handoff.
  Keep it standalone and open it after completion when requested.

## UI and accessibility

Follow the UI standards in `foundational/` once they exist.
New visible behavior needs role-safe access, clear feedback, and responsive
review, not only a happy-path rendering test.

## Development asset freshness

- Local CSS and JavaScript must revalidate on refresh, even when Rails
  controller caching is enabled for development. Do not use multi-day browser
  cache headers for development assets. Sprockets serves changed development
  assets with `must-revalidate`.
- If a stylesheet, asset-pipeline configuration, or asset URL changes, restart
  the development server when required and verify the served asset contains
  the intended rule before evaluating a visual fix.
- Use a deliberate asset URL version only when Turbo navigation needs to learn
  about an already-loaded stylesheet change. The development layout refreshes
  asset stylesheet URLs after Turbo navigation for this reason; keep that hook
  development-only.

## Non-disruptive visual verification

- Run visual checks in headless Chrome with a disposable local profile and
  save screenshots outside the repository. Do not take focus, navigate, or
  resize a contributor's active browser window.
- Use an isolated development-only account for authenticated browser checks.
  Never reuse a contributor's active session, credentials, or browser profile.
- Keep visual checks at least at one desktop and one narrow/mobile viewport;
  use the shared navigation, filter, form, list, and dialog contracts to
  select representative screens for each page family.
- Treat the captured headless-browser review as required evidence for every
  visible UI change. A stylesheet source check or an integration assertion is
  useful but does not replace reviewing the rendered screenshot. If headless
  Chrome is unavailable, state the blocker rather than reporting visual work
  as complete.

## Git, statistics, and handoff

- Before committing, run `git status --short --branch`, inspect the intended
  diff, and run `git diff --check`.
- Never stage secrets, local configuration, generated credentials, or
  unrelated user changes.
- Before a requested commit/push, run the project statistics command when one
  exists. For Rails projects this is normally `bin/rails stats` (or the
  project-specific documented equivalent). Record the output or update the
  repository's designated statistics section when one exists.
- Use concrete, behavior-oriented commit messages. Push only when requested.
- Use a two-phase production workflow: implement and validate locally, then
  stop for the user's review. Do not deploy, run production migrations, send
  production email, or make other production changes until the user explicitly
  authorizes production deployment. A request to commit or push to `origin/dev`
  does not grant that authorization.
- Final handoff states what changed, what was validated, relevant URLs/server
  status, known failures or blockers, and any remaining production action.
- Every production deployment requires a completion email to
  `mcymerman@gmail.com` after verification, under the user's standing October 10,
  2026 authorization. Include the revision, change summary, deployment outcome,
  migrations, health checks, and residual risks/feature-flag state. Confirm
  transport handoff; report email failures explicitly. Follow the mail path recorded in `deployment/` (ask Michael until one exists).

## Requirements-first enhancement

For a significant new capability, use the local requirements workflow in
[`spec-driven-development.md`](spec-driven-development.md). It adopts the
useful parts of GitHub Spec Kit without requiring its CLI for ordinary,
low-risk maintenance.
