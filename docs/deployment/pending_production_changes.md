# Pending production changes

The live answer to "what is waiting for production?". Each entry: what changed,
source (commit), validation, the production action needed, and blockers. No
secrets or customer data. Once released, move entries to `releases/YYYY-MM-DD-<rev>.md`.

## Handshake prototype: first deploy (not started)
- **What:** the whole Rails app in `handshake/` (MVP from the brief).
- **Source:** branch `handshake-prototype`. Uncommitted as of 2026-11-24 (Michael hasn't asked for a commit).
- **Validation (local, 2026-11-24):** `bin/rails test` 73/0 failures; `bin/rails test:system` 4/0; RuboCop, Brakeman, bundler-audit and importmap audit clean; production-mode boot checked. See `docs/handshake/deliverables/05_test_plan.md`.
- **Production action needed:**
  - Choose Render or Kamal.
  - Create the GitHub repo and run CI once.
  - Set `SECRET_KEY_BASE`, the 3 `AR_ENCRYPTION_*` keys, `APP_HOSTS` and `ADMIN_PASSWORD`.
  - Deploy, then `bin/rails db:seed` for the pilot venues.
  - Check `/up`.
  - Send the completion email.
- **Blockers:**
  - Michael's "deploy" instruction.
  - Hosting choice and accounts.
  - Legal review of terms and privacy copy before public use.
  - Trademark check on the name.
