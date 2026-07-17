# Cloudflare Tunnel And Access

## Scope

Phase 2 exposes the local Twenty instance at:

```text
https://crm-test.proeduconnect.com
```

The hostname must be protected by Cloudflare Access before n8n, Trello, WordPress, or any production-like integration points at it.

This phase does not move Twenty to production. Twenty continues to run locally at:

```text
http://localhost:3000
```

## Local Preflight

Before touching Cloudflare, confirm the local origin is ready:

```powershell
.\scripts\cloudflare-preflight.ps1
```

Expected:

- Docker services are running.
- `http://localhost:3000` returns `HTTP 200`.
- `cloudflared` is installed and reports a version.

Current preflight result on July 1, 2026:

```text
cloudflared version 2026.1.2
Docker services running
Local Twenty origin: HTTP 200
```

## Owner Dashboard Tasks

Perform these manually in Cloudflare One.

Important: reuse the existing Cloudflare Tunnel if it is already installed on this Windows host and is appropriate for this CRM test. Do not create a duplicate tunnel just because this runbook names `prodata-crm-test`.

Current local finding on July 1, 2026:

```text
Cloudflared Windows service: Running, Automatic
Service command shape: cloudflared.exe tunnel run --token <REDACTED>
Target hostname crm-test.proeduconnect.com: initially not resolving; later configured without Access protection
```

This means the machine already has a dashboard-managed Cloudflare Tunnel connector. Because it was installed with a token, the active tunnel configuration lives in Cloudflare, not in this repository.

Dashboard tunnel inventory provided on July 1, 2026:

```text
Tunnel name: prodata-tunnel
Tunnel type: cloudflared
Tunnel ID: 7c394ccb-969d-4c58-ac2c-3ef777c825f0
Tunnel status: Healthy
Connector ID: 6a17ae97-d1b6-419b-80bc-59d7800388d8
Connector hostname: LenovoG
Connector version: 2026.1.2
Connector platform: windows_amd64
Connector status: Connected
Data centers: iad, cmh, cle
Existing routes:
  ollama.proeduconnect.com -> http://localhost:11434
  crawler.proeduconnect.com -> http://localhost:8002
  searxng.proeduconnect.com -> http://localhost:8080
Catch-all: http_status:404
```

This is a good candidate for reuse because the active CRM hostname is also under `proeduconnect.com`, provided the owner accepts sharing this local connector across these test/local services. Do not edit or remove the three existing `proeduconnect.com` routes.

Access block status on July 1, 2026:

```text
Earlier: https://crm-test.proeduconnect.com returned unauthenticated HTTP 200.
Current: unauthenticated request returns HTTP 302.
Cloudflare Access is now blocking unauthenticated browser access.
Service-token request returns HTTP 200.
```

## Reuse Decision Gate

Reuse the existing tunnel only if all conditions below pass. If any condition fails or cannot be confirmed, create a separate tunnel named `prodata-crm-test`.

| Condition | How to verify | Pass criteria |
| --- | --- | --- |
| Same Cloudflare account owns the zone | Cloudflare dashboard shows `proeduconnect.com` in the same account as the existing tunnel | The tunnel can add a public hostname under `proeduconnect.com` |
| Connector is this Windows machine | Run `.\scripts\cloudflare-tunnel-status.ps1`; compare dashboard connector status and machine name/timing | Dashboard connector is healthy and matches this machine's running `Cloudflared` service |
| Existing tunnel is not dedicated to an unrelated production app | In Cloudflare One > Tunnels, inspect the existing public hostnames on that tunnel | Existing routes are compatible with adding `crm-test.proeduconnect.com`; no owner or environment boundary is being crossed |
| Adding this route will not overwrite another hostname | Search Cloudflare DNS and Tunnel public hostnames for `crm-test.proeduconnect.com` | The hostname is unused, or any existing route is intentionally being replaced |
| Origin service is local Twenty only | Run `.\scripts\cloudflare-preflight.ps1` | Local origin `http://localhost:3000` returns `HTTP 200` and Compose services are healthy |
| Public hostname target is exact | Dashboard public hostname service field | `crm-test.proeduconnect.com` routes to `http://localhost:3000`, not a broad local network route |
| Access protection is applied before integration | Cloudflare Access application and policies exist for the hostname | Browser access is Allow-list only, service access uses `Service Auth`, default is Deny |
| Existing routes still work after adding CRM hostname | Manually test the existing tunnel hostnames that the owner cares about | Existing hostnames behave the same after the CRM route is added |
| Rollback is simple | Dashboard route can be deleted without affecting existing hostnames | Removing only `crm-test.proeduconnect.com` restores the previous state |

Do not reuse the existing tunnel when:

- It belongs to a different Cloudflare account, customer, project, or security boundary.
- It is intentionally dedicated to another production service.
- Adding `crm-test.proeduconnect.com` would require changing existing public hostnames, ingress rules, tokens, or service installation.
- You cannot verify which tunnel the local Windows service belongs to.
- The hostname would be reachable without Cloudflare Access protection.
- The owner wants CRM traffic isolated for audit, uptime, or migration reasons.

## Reuse Test Plan

Run these tests in order.

1. Local connector/origin test:

```powershell
.\scripts\cloudflare-tunnel-status.ps1
.\scripts\cloudflare-preflight.ps1
```

Pass:

```text
Cloudflared service is Running
Local Twenty origin: HTTP 200
```

2. Dashboard tunnel match:

In Cloudflare One > Networks > Connectors > Cloudflare Tunnels, open the existing tunnel and verify the connector is healthy. The connector should match this Windows machine and the service should already be connected.

Pass:

```text
Existing dashboard tunnel has a healthy connector from this machine.
```

3. Route addition:

Add this public hostname on the existing tunnel:

```text
Hostname: crm-test.proeduconnect.com
Service: http://localhost:3000
```

Pass:

```powershell
Resolve-DnsName crm-test.proeduconnect.com
```

returns a Cloudflare-routed hostname or address instead of `DNS name does not exist`.

4. Access block test:

Before setting service-token environment variables, run:

```powershell
.\scripts\test-cloudflare-access.ps1
```

Pass:

```text
Unauthenticated request is not HTTP 200.
```

Fail immediately if unauthenticated access returns `HTTP 200`; delete the public hostname route until Access is fixed.

Current result:

```text
Unauthenticated status: 302
```

5. Service-token pass test:

After creating the `n8n-prodata-crm-test` Access service token, set it only in the current PowerShell session:

```powershell
$env:CF_ACCESS_CLIENT_ID = '<CLIENT_ID>'
$env:CF_ACCESS_CLIENT_SECRET = '<CLIENT_SECRET>'
.\scripts\test-cloudflare-access.ps1
Remove-Item Env:\CF_ACCESS_CLIENT_ID
Remove-Item Env:\CF_ACCESS_CLIENT_SECRET
```

Pass:

```text
Authenticated status: 200
```

Current result:

```text
Client ID present: length 39
Client Secret present: length 64
Authenticated status: 200
```

6. Existing-route regression test:

Manually test any pre-existing public hostnames on that tunnel. Do not proceed if adding `crm-test.proeduconnect.com` broke another route.

For the current tunnel, regression-test:

```text
ollama.proeduconnect.com
crawler.proeduconnect.com
searxng.proeduconnect.com
```

Recommended owner path:

1. Go to Cloudflare One > Networks > Connectors > Cloudflare Tunnels.
2. Open the existing tunnel:

```text
prodata-tunnel
```

3. Apply the reuse decision gate above.
4. If the existing tunnel passes every condition, reuse it.
5. If the existing tunnel fails any condition, create a separate tunnel named:

```text
prodata-crm-test
```

6. If creating a new tunnel, choose `cloudflared` as the connector and use the Windows connector command Cloudflare gives you. It will include an account-specific token. Do not paste that token into git, chat, screenshots, or docs.
7. On the reused or newly created tunnel, add only this new public hostname route:

```text
crm-test.proeduconnect.com
```

8. Route that hostname to the local service:

```text
http://localhost:3000
```

9. Leave these existing routes unchanged:

```text
ollama.proeduconnect.com -> http://localhost:11434
crawler.proeduconnect.com -> http://localhost:8002
searxng.proeduconnect.com -> http://localhost:8080
```

10. Confirm the connector remains healthy in Cloudflare One.

Cloudflare's dashboard flow creates the tunnel, gives the connector command, and shows the connector once `cloudflared` is running.

## Access Application

Create one self-hosted Access application:

| Field | Value |
| --- | --- |
| Application type | Self-hosted |
| Application name | `ProData CRM Test` |
| Domain | `crm-test.proeduconnect.com` |

Policies:

| Policy | Action | Purpose |
| --- | --- | --- |
| Owner access | Allow | Owner browser access |
| Approved admin access | Allow | Optional staff browser access |
| n8n CRM Bridge | Service Auth | Machine access from n8n |
| Default | Deny | Everyone else |

The service-token policy must use `Service Auth`; otherwise machine requests will be redirected to an identity-provider login.

## Service Token

Create one Access service token named:

```text
crm-test
```

Store the generated values only in n8n credentials or secure environment variables:

```text
CF_ACCESS_CLIENT_ID
CF_ACCESS_CLIENT_SECRET
```

n8n requests to Twenty must include:

```text
CF-Access-Client-Id: <CLIENT_ID>
CF-Access-Client-Secret: <CLIENT_SECRET>
```

Do not store these values in `.env`, source control, workflow JSON, Trello cards, or screenshots.

## n8n Credential Setup

n8n does not provide a credential type named `Cloudflare Access` or `cloudflared access`.

Use an HTTP Request generic `Custom Auth` credential because Cloudflare Access service-token auth requires two headers.

Recommended credential:

```text
Credential type: HTTP Request / Generic Credential Type / Custom Auth
Credential name: Cloudflare Access - crm-test
```

Custom Auth JSON:

```json
{
  "headers": {
    "CF-Access-Client-Id": "<CLIENT_ID>",
    "CF-Access-Client-Secret": "<CLIENT_SECRET>"
  }
}
```

In each n8n HTTP Request node that calls Twenty through Cloudflare:

```text
URL: https://crm-test.proeduconnect.com/<twenty-api-path>
Authentication: Generic Credential Type
Generic Auth Type: Custom Auth
Credential: Cloudflare Access - crm-test
```

When the Twenty API key exists, the request must also include:

```text
Authorization: Bearer <TWENTY_API_KEY>
```

If n8n allows only one credential on the HTTP Request node, either:

1. Add the Twenty bearer token as a normal request header in the node while using the Cloudflare Access credential, or
2. Create one combined `Custom Auth` credential for this CRM test that includes all three headers:

```json
{
  "headers": {
    "CF-Access-Client-Id": "<CLIENT_ID>",
    "CF-Access-Client-Secret": "<CLIENT_SECRET>",
    "Authorization": "Bearer <TWENTY_API_KEY>"
  }
}
```

Prefer option 1 while testing, because it keeps Cloudflare Access and Twenty API credentials easier to rotate independently. Never export workflows with real header values embedded.

## Acceptance Tests

After the tunnel and Access app exist, run:

```powershell
.\scripts\cloudflare-tunnel-status.ps1
.\scripts\test-cloudflare-access.ps1
```

This verifies:

- DNS resolves for `crm-test.proeduconnect.com`.
- A request without Access service-token headers is blocked or redirected.
- A request with service-token headers succeeds, when `CF_ACCESS_CLIENT_ID` and `CF_ACCESS_CLIENT_SECRET` are set in the current shell.

Set the service-token headers for one PowerShell session:

```powershell
$env:CF_ACCESS_CLIENT_ID = '<CLIENT_ID>'
$env:CF_ACCESS_CLIENT_SECRET = '<CLIENT_SECRET>'
.\scripts\test-cloudflare-access.ps1
Remove-Item Env:\CF_ACCESS_CLIENT_ID
Remove-Item Env:\CF_ACCESS_CLIENT_SECRET
```

Replace `<CLIENT_ID>` and `<CLIENT_SECRET>` with the actual Cloudflare Access service token values. The test script rejects those literal placeholder strings.

Do not paste the real token values into this repository.

## Running As A Windows Service

This machine already has a running `Cloudflared` Windows service. Do not install a second service unless the existing one is intentionally removed or replaced.

For a new machine only, install `cloudflared` as a Windows service after the manual dashboard tunnel works. Cloudflare's Windows service flow requires an elevated shell and installs the service with:

```text
cloudflared.exe service install
```

The installed service uses machine-level paths and credentials. Treat those files as live runtime state, not repository content.

## Rollback

If the hostname is reachable without Access protection, immediately disable or delete the public hostname route in Cloudflare.

If the tunnel behaves unexpectedly:

1. Stop the `cloudflared` process or service.
2. Disable the public hostname route.
3. Confirm `https://crm-test.proeduconnect.com` is no longer reachable.
4. Keep local Twenty available only at `http://localhost:3000`.

## Official References

- Cloudflare dashboard tunnel creation: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/
- Cloudflare locally managed tunnel commands: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/create-local-tunnel/
- Cloudflare Access service tokens: https://developers.cloudflare.com/cloudflare-one/access-controls/service-credentials/service-tokens/
- Cloudflare Windows service setup: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/as-a-service/windows/
