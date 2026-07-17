# Production Migration Plan

Production migration is out of scope for Phase 0 and Phase 1.

Before production planning:

1. Complete local Twenty smoke tests.
2. Complete Cloudflare Access acceptance tests.
3. Implement and validate the CRM schema with fake data.
4. Build isolated n8n test credentials.
5. Validate one-way Twenty to Trello synchronization.
6. Validate backup and restore.
7. Obtain owner approval for production architecture.

No VPS production deployment should happen from this repository without explicit owner approval.

