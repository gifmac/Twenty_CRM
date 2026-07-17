# ProData CRM Workspace Rules

## Project Context

This workspace is the local proof-of-concept for ProData Analytics CRM using Twenty CRM as the CRM system of record, n8n as the automation layer, Trello as the internal delivery board, and Cloudflare Tunnel plus Cloudflare Access for temporary protected remote access.

Current phase: Phase 3 preparation.

Completed and recorded:

- Phase 0 repository scaffold.
- Phase 1 local Twenty Docker setup and prior smoke test.
- Phase 2 Cloudflare Tunnel and Access protection for `crm-test.proeduconnect.com`.
- n8n Cloudflare Access credential and smoke test.
- Twenty role/API key setup for `n8n CRM Integration` / `n8n-prodata-crm-test`.

Current active work:

- Implement the Twenty data model from `docs/data-model.md`.
- Use fake data only.
- Do not activate intake, Trello sync, payment, or deadline workflows until the schema and fake-record tests pass.

Do not make Cloudflare, production n8n, Trello, WordPress, payment processor, or real-client-data changes from this workspace without explicit owner approval.

## Source Of Truth

- [TwentyCRM.md](TwentyCRM.md) is the handoff and implementation brief.
- [README.md](README.md) is the day-to-day local operator guide.
- [docs/architecture.md](docs/architecture.md) records the intended system boundaries.
- [docs/twenty-setup.md](docs/twenty-setup.md) records the local Twenty setup and smoke-test procedure.
- [docs/cloudflare-access.md](docs/cloudflare-access.md) records Cloudflare Tunnel and Access setup.
- [docs/n8n-workflows.md](docs/n8n-workflows.md) records n8n credential and workflow design.
- [docs/twenty-api-setup.md](docs/twenty-api-setup.md) records Twenty API role/key setup.
- [docs/data-model.md](docs/data-model.md) is the Phase 3 schema implementation guide.

## Boundaries

Keep these categories separate:

- Git: documentation, sanitized examples, helper scripts, compose templates, workflow exports, and test fixtures.
- Local runtime state: Docker volumes, databases, uploads, logs, generated exports, and backups.
- Secret storage: local `.env`, Docker Desktop secrets, Cloudflare, Twenty, n8n, Trello, or payment-provider credential stores.

Never commit real secrets, real client data, patient records, PHI, payment card data, bank details, raw operational transcripts, or screenshots containing sensitive information.

## Local Structure

- `compose/`: Docker Compose files for the local Twenty stack.
- `docs/`: architecture, setup, security, runbooks, and acceptance tests.
- `scripts/`: short PowerShell wrappers for common local actions.
- `n8n/`: sanitized workflow exports and test payloads only.
- `config/`: sanitized mapping examples only.
- `tests/`: fixtures and smoke or integration checks using fake data.
- `backups/` and `exports/`: local generated artifacts only; ignored by git.

## Commands

Run from the repository root unless a script says otherwise:

```powershell
.\scripts\start.ps1
.\scripts\status.ps1
.\scripts\healthcheck.ps1
.\scripts\stop.ps1
.\scripts\cloudflare-preflight.ps1
.\scripts\cloudflare-tunnel-status.ps1
.\scripts\test-cloudflare-access.ps1
```

Direct compose command:

```powershell
docker compose --env-file .env -f .\compose\docker-compose.yml -f .\compose\docker-compose.override.local.yml ps
```

## Operational Workflow

For any live system or external account:

1. Research, plan, and ask questions until 95% confident. Read the relevant local runbook and official docs or GitHub issues when behavior is uncertain.
2. Define the single problem, affected services, rollback point, and verification command.
3. Get explicit owner approval before live changes, destructive operations, or config edits.
4. Back up the relevant live config before changing it.
5. Make one meaningful change.
6. Verify immediately.
7. Stop if verification differs from the expected result.
8. If an approach fails twice, stop. State what was tried, why it failed, and propose a different direction. Never retry blindly.

## Testing Expectations

Before calling local runtime healthy:

- `docker compose config` must pass.
- `docker compose up -d` must start the expected services.
- `docker compose ps` must show services running or healthy.
- `http://localhost:3000` must respond locally.
- Recent logs must not show recurring database or worker failures.
- Persistence must be tested after a stop/start cycle before real usage.

Before moving past Phase 3:

- Opportunity pipeline stages exist.
- Opportunity, Person, Payment, and Milestone fields exist.
- Required saved views exist.
- Fake Person, Opportunity, Payment, and Milestone records exist and are linked correctly.
- n8n can use the scoped Twenty API key against fake data only.

## Commit Style

Use small commits grouped by phase or operational intent. Keep generated runtime files out of git. Do not rewrite or discard user changes without explicit instruction.
