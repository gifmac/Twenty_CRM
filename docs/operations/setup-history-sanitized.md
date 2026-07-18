# Setup History Sanitized

## July 1, 2026

- Read the ProData Analytics CRM handoff in `TwentyCRM.md`.
- Initialized this folder as a git repository.
- Created the Phase 0 and Phase 1 local scaffold:
  - repository rules,
  - README,
  - git ignore rules,
  - Twenty Docker Compose files,
  - local PowerShell scripts,
  - architecture, setup, security, operations, memory, and acceptance-test docs.
- Pinned Twenty to `v2.17.0`, the latest GitHub release visible on July 1, 2026.
- Validated compose syntax using `.env.example`.
- Parsed all PowerShell scripts successfully.
- Owner created `.env` and populated local secrets.
- Started Docker Desktop.
- Started the local Twenty Compose stack.
- Confirmed the local URL returned HTTP 200.
- Stopped and restarted the stack without deleting Docker volumes.
- Recorded a non-blocking Marketplace registry certificate warning from the worker logs.
- Prepared Phase 2 Cloudflare Tunnel and Access runbook.
- Added local Cloudflare preflight and post-Access verification scripts.
- Ran Phase 2 local preflight successfully with `cloudflared` version `2026.1.2` and local Twenty `HTTP 200`.
- Detected an existing running `Cloudflared` Windows service installed as a dashboard-managed token connector.
- Corrected Phase 2 guidance to reuse the existing tunnel when suitable and create `prodata-crm-test` only if a separate CRM tunnel is needed.
- Replaced vague tunnel reuse wording with explicit pass/fail criteria and a concrete reuse test plan.
- Recorded dashboard-provided tunnel details for `prodata-tunnel` and its existing local service routes.
- Recorded Cloudflare Access fix: `crm-test.proeduconnect.com` changed from unauthenticated `HTTP 200` to unauthenticated `HTTP 302`.
- Updated the Cloudflare Access verifier to print a start banner, format DNS output immediately, and reject literal service-token placeholders.
- Recorded Cloudflare Access service-token validation success: authenticated request returned `HTTP 200`.
- Documented n8n credential setup using HTTP Request generic `Custom Auth` headers because n8n has no dedicated Cloudflare Access credential type.
- Added n8n workflow runbook with credential inventory, Access smoke test, and guarded client-intake workflow design.
- Recorded n8n manual Access smoke test success: `https://crm-test.proeduconnect.com/healthz` returned `HTTP 200`.
- Added detailed Twenty API setup runbook for the restricted n8n role, API key creation, role assignment, and validation tests.
- Recorded owner completion of Twenty role `n8n CRM Integration` and API key `n8n-prodata-crm-test`; API validation tests remain pending.
- Recorded owner confirmation that Twenty API boundary tests were already completed during setup.
- Added Phase 3 Twenty data model runbook, service catalog, pipeline-stage map, and fake n8n payload fixtures.

No real secrets, real client data, Cloudflare changes, n8n changes, Trello changes, WordPress changes, or payment-system changes were made.

## July 17, 2026

- Ran live Docker status and health checks.
- Confirmed `db`, `redis`, `server`, and `worker` containers are running; `db`, `redis`, and `server` are healthy.
- Confirmed `http://localhost:3000` returns `HTTP 200`.
- Confirmed recent container logs had no warning/error patterns in the last 120 lines.
- Confirmed `crm-test.proeduconnect.com` resolves through Cloudflare and unauthenticated browser access returns `HTTP 302`.
- Ran a headless browser inspection with Playwright:
  - local Twenty loaded at `http://localhost:3000/welcome`;
  - page title was `Sign in or Create an account`;
  - app navigation and workspace data rendered;
  - no browser console errors, page errors, failed requests, or HTTP 4xx/5xx browser responses were observed.
- Captured browser screenshots under ignored `tmp/browser-check/`.


## July 18, 2026

- Investigated owner-reported unstable clicks after login.
- Confirmed the running app was still configured with `SERVER_URL=http://localhost:3000` while browser access used `https://crm-test.proeduconnect.com`.
- Reproduced that Twenty advertised `localhost` in `/client-config` and workspace metadata before the fix.
- Backed up the local `.env` to `.env.backup.20260718-035823`.
- Updated local `.env` so `SERVER_URL=https://crm-test.proeduconnect.com`.
- Recreated only the Twenty `server` and `worker` containers; database and Redis volumes were not recreated.
- Verified:
  - `docker compose config --quiet` passed;
  - `db`, `redis`, and `server` are healthy;
  - `http://localhost:3000` still returns `HTTP 200` for origin health;
  - `/client-config` now returns `frontDomain: "crm-test.proeduconnect.com"`;
  - workspace metadata now returns `https://crm-test.proeduconnect.com/`;
  - unauthenticated browser access to `https://crm-test.proeduconnect.com` still lands on Cloudflare Access.
