# Development setup (Handshake app in `handshake/`)

Stack chosen 2026-11-24 (see docs/handshake/00_decisions.md).

- **Ruby 4.0.10** via rbenv: `~/.rbenv/versions/4.0.10/bin` (pinned in
  `handshake/.ruby-version`). Note: the default `ruby` on this laptop is asdf
  3.4.1. Prepend the rbenv path: `export PATH=~/.rbenv/versions/4.0.10/bin:$PATH`.
  3.4.9 was rejected: Brakeman flagged CVE-2026-132825 (fixed in 3.4.13 / 4.0.10).
- **Rails 8.1.4.1**, **PostgreSQL 16** (Homebrew service `postgresql@16`, socket at /tmp:5432).
- **Chrome** for system tests and screenshots (headless, disposable profiles).
- **No Docker engine** on this laptop (CLI only). Docker builds are untested here.

## Commands (run inside `handshake/`)

| What | Command |
|---|---|
| First setup | `bin/setup --skip-server` then `bin/rails db:seed` |
| Dev server (port 3000, jobs in Puma) | `bin/dev` (we used `-p 3100` during the build) |
| Unit, request, channel and job tests | `bin/rails test` |
| Browser tests | `bin/rails test:system` |
| Lint and scans | `bin/rubocop`, `bin/brakeman --no-pager`, `bin/bundler-audit check --update`, `bin/importmap audit` |
| Statistics | `bin/rails stats` |
| Guide screenshots | `bin/rails runner script/guide_screenshots.rb http://localhost:3100 /tmp/hs-shots` (start the dev server and the script with the same `ADMIN_PASSWORD`, 12+ characters, for the admin shots) |
| Build the guide (JPEGs, standalone HTML, PDF) | `ruby script/build_guide.rb /tmp/hs-shots` |

## Laptop workarounds (Intel macOS 13)
- Chrome 158 rejects Capybara 3.40's wildcard storage clear. A cookie-clear
  workaround lives in `test/application_system_test_case.rb`.
- Desktop Chrome won't shrink below 500px; screenshots use device emulation for 390px.
