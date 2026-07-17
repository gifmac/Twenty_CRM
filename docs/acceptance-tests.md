# Acceptance Tests

## Phase 1 Infrastructure

- [ ] Docker Compose validates.
- [ ] All Twenty services start successfully.
- [ ] Local browser reaches Twenty.
- [ ] Persistent storage survives restart.
- [ ] Health-check script completes.

## Future Phase 2 Access Security

- [x] Cloudflare hostname works.
- [x] Unauthorized browser is blocked.
- [ ] Authorized browser reaches Twenty.
- [x] n8n without service token is denied.
- [x] n8n with valid service token reaches Twenty.
- [x] Twenty API without bearer key is denied. Owner-verified during setup.
- [x] Scoped n8n API key performs only required operations. Owner-verified during setup.

Local preflight:

- [x] `cloudflared` is installed.
- [x] Local Twenty origin returns `HTTP 200`.
- [x] Docker services are running before the tunnel is started.

Tunnel reuse gate:

- [x] Existing tunnel is in the same Cloudflare account as `proeduconnect.com`.
- [x] Existing tunnel connector matches this Windows machine.
- [x] Owner accepts adding CRM route to `prodata-tunnel` alongside existing local service routes.
- [x] `crm-test.proeduconnect.com` is routed through `prodata-tunnel`.
- [x] Public hostname route is exactly `crm-test.proeduconnect.com -> http://localhost:3000`.
- [x] Access policy is active before any integration uses the hostname. Current unauthenticated test returns `HTTP 302`.
- [ ] Existing tunnel hostnames `ollama.proeduconnect.com`, `crawler.proeduconnect.com`, and `searxng.proeduconnect.com` still work after adding the CRM route.

n8n smoke test:

- [x] `ProData CRM - 00 Access Smoke Test` reaches `https://crm-test.proeduconnect.com/healthz` with `HTTP 200`.

## Future CRM Model

- [ ] Create Person.
- [ ] Create Opportunity linked to Person.
- [ ] Create Payment linked to Opportunity.
- [ ] Create Milestone linked to Opportunity.
- [ ] Engagement code is unique and immutable.
- [ ] Saved views for New Inquiries, Awaiting Deposit, Active Work, Deadline Risk, Waiting on Client, Overdue Balances, and Delivery Review exist.
