# Operations: backups, logs and monitoring (within the privacy promise)

The promise: no location history, no selling data, no ads; logs never hold
codes, message text, zones or IPs. Operations must keep that literally true.

## Backups
- **What:** the one PostgreSQL database (app, jobs, cable, cache).
- **How often:** daily, encrypted (Render does this automatically on paid
  plans. With Kamal, run `pg_dump | age -r <public key>` from a cron on a
  different machine, or use your provider's managed snapshots).
- **Kept:** 7 days, then deleted. The privacy page says deleted chats can
  survive in an encrypted backup for up to 7 days; keep that number in sync.
- **Never back up the logs or Solid Cable's message table separately.**
  Cable rows hold rendered messages for at most 10 minutes
  (`message_retention`).
- **Restore drill:** once a month, restore the latest backup into a scratch
  database and run `bin/rails runner 'puts ChatThread.count'`.
- **Encryption keys** (`AR_ENCRYPTION_*`, `SECRET_KEY_BASE`) live in the
  password manager, never alongside backups. Without them a backup's
  messages and reveal details are unreadable.

## Logs
- **Level:** `info` in production (no SQL). Don't run `debug` in production.
- **What's in a line:** method, path with secrets masked (`/dash/[FILTERED]`),
  controller, status, duration, request id. No IPs, no codes, no message
  text, no zones (`config/initializers/privacy_logging.rb`, proven by
  `test/integration/privacy_logging_test.rb`).
- **Kept:** at most 7 days. Kamal: Docker json-file rotation (10 MB × 7),
  set in `config/deploy.yml`. Render: logs stream to Render's dashboard for
  its own retention period; don't add a log drain that keeps them longer.
- **Proxies:** Kamal proxy and Render's edge see client IPs to route
  traffic. Don't enable access logs that keep IPs beyond 7 days.

## Monitoring
- **Uptime:** poll `https://<host>/up` every minute (UptimeRobot, Better
  Stack, Render health checks). `/up` touches the database and returns 200
  or 500.
- **Jobs:** if `PurgeExpiredCodesJob` stops, codes still expire (queries
  check `expires_at`), but rows linger. Alert if
  `SELECT count(*) FROM handshake_codes WHERE expires_at < now() - interval '10 minutes'`
  is above 0.
- **Errors:** if you add an error tracker (e.g. Sentry or Honeybadger), turn off IP
  collection, scrub request bodies and parameters, and don't attach user
  context. The filter list in `config/initializers/filter_parameter_logging.rb`
  must be applied to it.
- **Product metrics:** `/admin/metrics` shows daily totals only (handshakes,
  chats, groups, second-day conversations, reveal steps, reports). No
  analytics scripts, pixels or third-party trackers on any page; the Content
  Security Policy would block them anyway.

## Incident basics
- A safety report arrives in `/admin/reports`. Suspending a device removes it
  from every chat and stops new codes.
- A suspected database leak: rotate `SECRET_KEY_BASE` (signs out every
  device and invalidates all codes) and rotate the encryption keys using
  Active Record Encryption's key rotation (add the new primary key first,
  keep the old one for reading).
