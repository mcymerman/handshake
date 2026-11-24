# Requirements-First Development

Use this workflow for a new product, a large feature, a cross-cutting change,
or work where unclear requirements could cause rework. It is inspired by
[GitHub Spec Kit](https://github.com/github/spec-kit), whose core sequence is
constitution, specification, plan, tasks, implementation, and convergence.

## Recommendation

Adopt the process and artifact discipline now. Do **not** make the Spec Kit CLI
a mandatory dependency for every repository or small fix. The local documents
below work with any coding agent, remain easy to review in Git, and avoid
installing generated agent prompts into every existing project.

Use the Spec Kit CLI later for a greenfield or large program when the team
wants its generated commands, templates, task-to-issue flow, or consistency
analysis. Pin a reviewed version and keep its managed files separate from
product artifacts.

## Local artifact sequence

1. Fill in `concept.md` for a new idea.
2. The agent inspects the repository and creates `questions.md`, using `[ ]`
   for unanswered questions and `[x]` for settled answers.
3. After answers arrive, the agent creates or refines `backlog.md` and the
   relevant foundational documents.
4. For a major feature, create `specs/YYYY-MM-DD-feature-name/` containing:
   - `spec.md`: user outcomes, scope, acceptance criteria, non-goals, and
     risks;
   - `plan.md`: architecture, data/permission changes, UI approach,
     validation, migration/deployment, and rollback;
   - `tasks.md`: ordered `[ ]`/`[x]` implementation tasks; and
   - optional `checklists/`: independent requirement-quality reviews.
5. Implement tasks in dependency order. Mark a task complete only after its
   implementation and validation are complete.
6. Run a convergence review: compare the finished code, tests, and docs with
   the spec and append gaps as unchecked tasks or backlog items.

## How to use GitHub Spec Kit when warranted

1. Install `uv` and a pinned reviewed `specify-cli` release.
2. In a new or isolated repository, run `specify init <project> --integration
   <supported-agent>`.
3. Establish the project constitution. Keep `AGENTS.md` and this project's
   documentation rules authoritative for local operating practices.
4. Run `specify`, optionally `clarify`, then `plan`, `tasks`, `analyze`, and
   `implement` for a meaningful feature.
5. Review generated files before adopting them. Do not overwrite existing
   project documents, agent instructions, or an established backlog without a
   migration plan.
6. Use `converge` or the local convergence review before closing the work.

Spec Kit is particularly useful for greenfield work, complex parallel work, and
features with multiple user roles. It is unnecessary overhead for focused copy,
styling, or isolated bug fixes.
