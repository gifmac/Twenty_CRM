# Active Paths

## Local Repository

```text
C:\Users\gifma\projects\Twenty CRM
```

## Local Runtime

| Item | Path or name |
| --- | --- |
| Compose project | `prodata_twenty_test` |
| Compose file | `compose/docker-compose.yml` |
| Local override | `compose/docker-compose.override.local.yml` |
| Local env file | `.env` |
| Local URL | `http://localhost:3000` |
| Database volume | `prodata_twenty_test_db-data` |
| Server storage volume | `prodata_twenty_test_server-local-data` |
| Local cloudflared executable | `C:\Program Files (x86)\cloudflared\cloudflared.exe` |
| Local Cloudflared service | `Cloudflared`, running as `LocalSystem`, automatic startup |

## Verification Commands

```powershell
docker compose --env-file .env -f .\compose\docker-compose.yml -f .\compose\docker-compose.override.local.yml config
.\scripts\status.ps1
.\scripts\healthcheck.ps1
.\scripts\cloudflare-preflight.ps1
.\scripts\cloudflare-tunnel-status.ps1
.\scripts\test-cloudflare-access.ps1
```

## Future External Systems

| System | Status |
| --- | --- |
| Existing Cloudflare connector | Running locally as a dashboard-managed service token connector |
| Existing Cloudflare tunnel | `prodata-tunnel` / `7c394ccb-969d-4c58-ac2c-3ef777c825f0` |
| Existing connector ID | `6a17ae97-d1b6-419b-80bc-59d7800388d8` |
| Existing connector hostname | `LenovoG` |
| Existing tunnel routes | `ollama.proeduconnect.com`, `crawler.proeduconnect.com`, `searxng.proeduconnect.com` |
| Cloudflare Tunnel for CRM | Reuse `prodata-tunnel` if same-account/domain boundary is confirmed; otherwise create `prodata-crm-test` |
| Hostname `crm-test.proeduconnect.com` | Resolves; unauthenticated access returns `HTTP 302` |
| Cloudflare Access app | Browser block active; service-token request returns `HTTP 200` |
| n8n CRM bridge | Future phase |
| n8n Cloudflare Access credential | `Cloudflare Access - crm-test` |
| n8n smoke test workflow | `ProData CRM - 00 Access Smoke Test`, returns `HTTP 200` |
| Twenty integration role | `n8n CRM Integration`, created |
| Twenty API key | `n8n-prodata-crm-test`, created and owner-validated |
| Twenty data model runbook | `docs/data-model.md`, pending implementation in Twenty UI |
| Trello board `ProData Client Delivery` | Future phase |
| WordPress/Forminator intake | Future phase |
