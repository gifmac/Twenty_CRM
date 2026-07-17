# Architecture

## Objective

Build a local proof-of-concept CRM for ProData Analytics.

Twenty is the authoritative CRM database. Trello is the internal delivery layer only. n8n is the integration and automation layer. Cloudflare Tunnel and Cloudflare Access will provide protected temporary access to the local Twenty instance in Phase 2.

## System Boundaries

| Domain | System of record |
| --- | --- |
| Client identity and contact details | Twenty |
| Leads, quotes, engagement status, payment status, deadlines | Twenty |
| Internal delivery tasks, checklists, assignments | Trello |
| Intake routing, duplicate checks, calculations, reminders, synchronization | n8n |
| Documents | Existing approved document storage; CRM stores links only |

## Local Phase 1 Runtime

```text
Windows host
  Docker Desktop / WSL 2
    Docker Compose project: prodata_twenty_test
      server: twentycrm/twenty:v2.17.0
      worker: twentycrm/twenty:v2.17.0
      db: postgres:16
      redis: redis:7
```

Twenty is bound to local loopback at:

```text
http://localhost:3000
```

Do not expose PostgreSQL or Redis ports.

## Future Phase 2 Access Path

```text
n8n on VPS
  Cloudflare Access service token
    crm-test.proeduconnect.com
      Cloudflare Tunnel
        local cloudflared
          http://localhost:3000
```

The named Cloudflare Tunnel and Access policies are owner-managed tasks. This repository may document them but must not make account-level changes without explicit approval.

## Data Handling

Only fake client data is allowed during the local proof-of-concept. Do not store patient records, PHI, payment card data, bank details, sensitive files, or real client records in Twenty, Trello, n8n execution logs, screenshots, workflow exports, or source control.
