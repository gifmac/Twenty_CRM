# Twenty Local Setup

## Official Guidance Used

The local compose setup follows Twenty's official Docker Compose self-hosting guidance:

- Services: server, worker, PostgreSQL, Redis.
- Minimum runtime requirement: Docker with at least 2 GB RAM available.
- Generate and preserve `ENCRYPTION_KEY`; losing it means losing access to secrets stored in the database.
- Use a strong Postgres password without special characters.
- Configure `SERVER_URL` to match how users access the app.
- Use persistent volumes for database and server local storage.

## Local Setup Steps

1. Create `.env`:

```powershell
Copy-Item .\.env.example .\.env
```

2. Replace placeholders:

```text
PG_DATABASE_PASSWORD
ENCRYPTION_KEY
```

3. Validate compose:

```powershell
docker compose --env-file .env -f .\compose\docker-compose.yml -f .\compose\docker-compose.override.local.yml config
```

4. Start:

```powershell
.\scripts\start.ps1
```

5. Check status:

```powershell
.\scripts\status.ps1
```

6. Check local reachability and recent logs:

```powershell
.\scripts\healthcheck.ps1
```

## Smoke Test Checklist

- [ ] Docker Desktop is running.
- [ ] `docker compose config` succeeds.
- [ ] `docker compose up -d` starts `server`, `worker`, `db`, and `redis`.
- [ ] `docker compose ps` shows expected services running or healthy.
- [ ] `http://localhost:3000` responds.
- [ ] Recent logs show no recurring database or worker failures.
- [ ] Twenty onboarding is completed with a fake administrator account.
- [ ] Data persists after `.\scripts\stop.ps1` and `.\scripts\start.ps1`.

## Current Smoke Test Report

Validation completed on July 1, 2026:

- [x] Repository scaffold created.
- [x] `docker compose --env-file .env.example -f .\compose\docker-compose.yml -f .\compose\docker-compose.override.local.yml config` succeeds.
- [x] PowerShell scripts parse successfully.
- [x] `.env` created with owner-provided local secrets.
- [x] `docker compose up -d` run against real local secrets.
- [x] Container status captured.
- [x] `http://localhost:3000` local URL test completed.
- [x] Stack stopped and restarted without deleting Docker volumes.

Container status after restart:

```text
prodata_twenty_test-db-1       postgres:16                Up, healthy
prodata_twenty_test-redis-1    redis:7                    Up, healthy
prodata_twenty_test-server-1   twentycrm/twenty:v2.17.0   Up, healthy, 127.0.0.1:3000->3000
prodata_twenty_test-worker-1   twentycrm/twenty:v2.17.0   Up
```

Local URL result:

```text
http://localhost:3000 -> HTTP 200
```

Observed warnings:

- Initial startup logged expected first-run database relation errors while migrations created missing tables.
- Worker logs currently show a Marketplace registry certificate warning when fetching apps from `https://registry.npmjs.org`. This does not block the local CRM HTTP health check.
