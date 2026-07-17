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
