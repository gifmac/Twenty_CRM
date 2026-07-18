# ProData Analytics CRM Local Test Build

This repository contains the local proof-of-concept scaffold for ProData Analytics CRM.

Twenty is the CRM system of record. Trello is only the internal delivery board. n8n is the synchronization layer. Cloudflare Tunnel and Cloudflare Access protect the temporary CRM test hostname.

## Current Scope

Active proof-of-concept scope:

- Repository scaffold and documentation.
- Local Twenty Docker Compose configuration.
- Local start, stop, status, and health-check scripts.
- Cloudflare Access protected CRM test hostname.
- n8n credential and smoke-test documentation.
- Twenty data-model preparation with fake records only.
- No production n8n, Trello, WordPress, payment processor, or real-client-data changes.

## Version

Pinned Twenty image tag:

```text
v2.17.0
```

This tag was selected from the latest GitHub release visible on July 1, 2026. Do not use `latest` for this project.

## Setup

1. Create a local `.env` from the placeholder file:

```powershell
Copy-Item .\.env.example .\.env
```

2. Edit `.env` and replace every placeholder secret. Generate each secret separately:

```powershell
openssl rand -base64 32
```

Twenty's official guidance says `PG_DATABASE_PASSWORD` should be strong and avoid special characters.

3. Validate the compose config:

```powershell
docker compose --env-file .env -f .\compose\docker-compose.yml -f .\compose\docker-compose.override.local.yml config
```

4. Start the local stack:

```powershell
.\scripts\start.ps1
```

5. Browser access:

```text
https://crm-test.proeduconnect.com
```

`http://localhost:3000` is still used for local health/origin checks. Once `SERVER_URL` is set to the Cloudflare hostname, use the Cloudflare URL for interactive browser sessions.

Use fake accounts and fake client records only.

## Common Commands

```powershell
.\scripts\start.ps1
.\scripts\status.ps1
.\scripts\healthcheck.ps1
.\scripts\stop.ps1
```

Phase 2 local preflight and post-Cloudflare tests:

```powershell
.\scripts\cloudflare-preflight.ps1
.\scripts\cloudflare-tunnel-status.ps1
.\scripts\test-cloudflare-access.ps1
```

## Runtime State

Runtime state lives in Docker volumes and ignored local folders, not in git:

- `prodata_twenty_test_db-data`
- `prodata_twenty_test_server-local-data`
- `backups/`
- `exports/`
- `.env`

Do not move database volumes, uploads, generated exports, logs, credentials, or backups into source control.

## Security Rules

- No real client data during local proof-of-concept work.
- No patient records, PHI, payment card data, bank details, or sensitive client files in Twenty, Trello, n8n logs, screenshots, exports, or git.
- No secrets in `.env.example`, workflow JSON, Trello card descriptions, screenshots, or documentation.
- Use Cloudflare Access before exposing `crm-test.proeduconnect.com`.

Phase 2 setup details are in [docs/cloudflare-access.md](docs/cloudflare-access.md).

n8n credential and workflow setup details are in [docs/n8n-workflows.md](docs/n8n-workflows.md).

Twenty API role/key setup details are in [docs/twenty-api-setup.md](docs/twenty-api-setup.md).

Twenty schema setup details are in [docs/data-model.md](docs/data-model.md).
