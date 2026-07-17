# Compose Notes

This directory contains the local Twenty Docker Compose configuration.

The base file follows Twenty's official self-hosting compose shape: `server`, `worker`, `db`, and `redis`, with persistent database and local-storage volumes.

Project-specific choices:

- Twenty is pinned through `TAG` in the root `.env`.
- Port `3000` is bound to `127.0.0.1` only.
- Runtime data remains in Docker volumes.
- Secrets belong in root `.env`, never in git.

Run compose from the repository root:

```powershell
docker compose --env-file .env -f .\compose\docker-compose.yml -f .\compose\docker-compose.override.local.yml config
```

