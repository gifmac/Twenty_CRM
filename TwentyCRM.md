# ProData Analytics CRM — Twenty Local Test Build Handoff

## 1. Objective

Build a local proof-of-concept CRM for ProData Analytics using:

* **Twenty CRM** as the authoritative client and engagement database.
* **Trello** as the internal delivery and task-management layer only.
* **n8n** as the integration and automation layer.
* **Cloudflare Tunnel + Cloudflare Access** for secure temporary remote access to the local Twenty instance.
* **Windows host + Docker Desktop using WSL 2** for local testing.

Do not use Excel as the live CRM. Excel may be used only for export, backup review, or one-time migration.

Do not store patient records, PHI, card numbers, bank account details, or sensitive client files in Twenty, Trello, n8n execution logs, or source control.

---

## 2. Core design decisions

### System of record

| Domain                                                                     | System of record                                                   |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Client identity and contact details                                        | Twenty                                                             |
| Leads, quotes, engagement status, payment status, deadlines                | Twenty                                                             |
| Internal delivery tasks, checklists, assignments                           | Trello                                                             |
| Intake routing, duplicate checks, calculations, reminders, synchronization | n8n                                                                |
| Documents                                                                  | Existing approved document-storage service; save only links in CRM |

### Non-negotiable rules

1. **Twenty owns CRM data.** Trello must not become a second client database.
2. **Trello must never be updated by searching card titles.** Use the saved Trello Card ID.
3. **n8n is the sole synchronization layer.** Do not build competing direct syncs from Trello to Twenty and Twenty to Trello.
4. **One-way synchronization comes first.** Enable limited reverse sync only after acceptance testing.
5. **Use fake client data during the local test phase.**
6. **No secrets in Git, workflow JSON, Trello card descriptions, or screenshots.**
7. **Do not modify the existing production n8n/Trello workflow in place.** Clone it and build a separate ProData CRM bridge.

---

## 3. Target architecture

```text
                    CLIENT / STAFF
                         │
                         ▼
          ProData website form / staff intake form
                         │
                         ▼
                    n8n on VPS
                         │
               Cloudflare Access service token
                         │
                         ▼
      Cloudflare Tunnel + Access-protected hostname
                         │
                         ▼
      Local Windows laptop: cloudflared process
                         │
                         ▼
          Twenty Docker Compose stack on localhost
             ├─ Twenty server
             ├─ Twenty worker
             ├─ PostgreSQL
             └─ Redis
                         │
                         ▼
                      Trello API
                         │
                         ▼
             ProData Client Delivery board
```

### Test hostname

Use:

```text
crm-test.prodatanalytics.com
```

The current `trycloudflare.com` URL is acceptable only as a temporary connectivity test. Do not configure permanent application URLs, API credentials, or production-like integrations around a quick tunnel.

---

## 4. Build boundaries

### Codex may do

* Create the local infrastructure repository and documentation.
* Create Docker Compose configuration based on Twenty’s official self-hosting template.
* Generate local `.env.example` files with placeholders only.
* Start, inspect, stop, and troubleshoot local Docker containers.
* Create scripts for backup, restore verification, health checks, and upgrade preparation.
* Prepare n8n workflow export files or implementation instructions.
* Build a cloned ProData CRM Trello Bridge workflow.
* Create test payloads, smoke tests, and API documentation.
* Prepare schema import/reference documentation.

### Owner must do manually

* Log into Cloudflare.
* Create the named Cloudflare Tunnel.
* Create DNS/public hostname routing.
* Create the Cloudflare Access application and policies.
* Create a Cloudflare service token for n8n.
* Enter secrets into Cloudflare, Twenty, Docker environment files, and n8n credentials.
* Create or approve Twenty users, roles, and API keys.
* Approve access to production n8n, WordPress/Forminator, Trello, payment processors, and real client data.
* Decide when the local test may move to VPS production.

Codex must not make irreversible account-level changes without explicit approval.

---

## 5. Repository layout

Create a new dedicated repository. Do not place this inside the Hermes application repository.

Preferred local location:

```text
~/projects/prodata-crm
```

Recommended structure:

```text
prodata-crm/
├─ README.md
├─ AGENTS.md
├─ .gitignore
├─ .env.example
├─ compose/
│  ├─ docker-compose.yml
│  ├─ docker-compose.override.local.yml
│  └─ README.md
├─ docs/
│  ├─ architecture.md
│  ├─ data-model.md
│  ├─ cloudflare-access.md
│  ├─ twenty-setup.md
│  ├─ n8n-workflows.md
│  ├─ trello-bridge.md
│  ├─ backup-and-recovery.md
│  ├─ upgrade-runbook.md
│  ├─ security-and-data-handling.md
│  ├─ acceptance-tests.md
│  └─ production-migration-plan.md
├─ scripts/
│  ├─ start.ps1
│  ├─ stop.ps1
│  ├─ status.ps1
│  ├─ healthcheck.ps1
│  ├─ backup.ps1
│  ├─ restore-test.ps1
│  ├─ upgrade.ps1
│  └─ generate-test-data.ps1
├─ n8n/
│  ├─ workflows/
│  │  ├─ 01-client-intake.json
│  │  ├─ 02-twenty-to-trello.json
│  │  ├─ 03-trello-to-twenty.json
│  │  ├─ 04-payment-reconciliation.json
│  │  ├─ 05-deadline-watch.json
│  │  └─ 06-error-alerting.json
│  └─ payloads/
│     ├─ intake-new-client.json
│     ├─ intake-existing-client.json
│     ├─ payment-paid.json
│     └─ trello-stage-change.json
├─ config/
│  ├─ service-catalog.json
│  ├─ pipeline-stage-map.json
│  └─ trello-board-map.example.json
└─ tests/
   ├─ smoke/
   ├─ integration/
   └─ fixtures/
```

`.gitignore` must exclude:

```text
.env
.env.*
!.env.example
*.pem
*.key
secrets/
backups/
exports/
node_modules/
```

---

## 6. Local infrastructure phase

### 6.1 Runtime

Use Docker Desktop configured for:

* Linux containers.
* WSL 2 backend.
* Project files stored in the WSL filesystem.
* No direct public port exposure other than local loopback access.

Use a dedicated Docker Compose project name:

```text
prodata_twenty_test
```

### 6.2 Version policy

* Pin Twenty to a tested release tag.
* Do not use `latest`.
* Record the selected Twenty version in `README.md`.
* Record image digests or exact tags after the first successful run.
* Do not enable automatic image updates.

### 6.3 Required environment placeholders

Create `.env.example` with placeholders only:

```env
COMPOSE_PROJECT_NAME=prodata_twenty_test
TAG=<PINNED_TWENTY_VERSION>

SERVER_URL=https://crm-test.prodatanalytics.com

PG_DATABASE_PASSWORD=<GENERATE_STRONG_PASSWORD>
ENCRYPTION_KEY=<GENERATE_AND_STORE_SECURELY>

TWENTY_BASE_URL=https://crm-test.prodatanalytics.com
```

Do not rotate `ENCRYPTION_KEY` casually after data has been created.

### 6.4 Local smoke test

Codex must verify:

```text
1. docker compose config succeeds.
2. docker compose up -d starts all expected containers.
3. docker compose ps shows healthy/running services.
4. http://localhost:3000 responds locally.
5. logs show no recurring database or worker failures.
6. Twenty onboarding can be completed using a fake administrator account.
7. Local database volume persists after docker compose down/up.
```

Create `scripts/healthcheck.ps1` that:

* Checks Docker Desktop availability.
* Checks compose service status.
* Sends an HTTP request to `http://localhost:3000`.
* Reports container names, health, and recent relevant errors.
* Returns non-zero on failure.

---

## 7. Cloudflare tunnel and access phase

### 7.1 Initial temporary verification

The current quick tunnel proves that `cloudflared` can expose local port 3000.

Do not proceed with CRM integration until the named tunnel is created.

### 7.2 Named tunnel configuration

Owner tasks:

1. Create a named Cloudflare Tunnel: `prodata-crm-test`.
2. Add hostname:

```text
crm-test.prodatanalytics.com
```

3. Route it to:

```text
http://localhost:3000
```

4. Install/run `cloudflared` on Windows as a managed process or service only after manual testing succeeds.
5. Confirm that the hostname resolves and reaches Twenty.

### 7.3 Cloudflare Access policy

Create a Cloudflare Access self-hosted application for:

```text
crm-test.prodatanalytics.com
```

Policies:

| Policy                                        | Purpose                                    |
| --------------------------------------------- | ------------------------------------------ |
| Allow — Owner email                           | Browser access for the owner               |
| Allow — Approved ProData administrator emails | Optional staff access                      |
| Service Auth — n8n CRM Bridge                 | Allows n8n to call Twenty programmatically |
| Deny — everyone else                          | Default outcome                            |

Do not make the hostname publicly accessible without Access protection.

### 7.4 n8n machine access

Create one Cloudflare Access service token named:

```text
n8n-prodata-crm-test
```

Store its credentials only in n8n credentials or secure environment variables:

```text
CF_ACCESS_CLIENT_ID
CF_ACCESS_CLIENT_SECRET
```

Every n8n HTTP request from the VPS to Twenty must include:

```text
CF-Access-Client-Id
CF-Access-Client-Secret
```

Use a separate Twenty API key for n8n. Restrict it to the minimum CRM role required.

### 7.5 Cloudflare acceptance tests

```text
A. Browser access without approved identity is blocked.
B. Approved owner email can reach the Twenty login page.
C. n8n request without Access service headers fails.
D. n8n request with valid Access service headers succeeds.
E. Twenty API request without Twenty bearer API key fails.
F. Twenty API request with valid scoped bearer key succeeds.
```

---

## 8. CRM schema phase

Build the following minimal schema. Avoid excessive customization during the first test.

### 8.1 Use native Twenty objects

| Object        | ProData usage                                                      |
| ------------- | ------------------------------------------------------------------ |
| Person        | Individual client/contact                                          |
| Company       | Institution, business, university, organization, or research group |
| Opportunity   | One inquiry, quotation, or paid client engagement                  |
| Notes / Tasks | Internal communication history and follow-up actions               |

### 8.2 Opportunity represents the engagement lifecycle

Use the native Opportunity object as the primary project/engagement record from first inquiry through post-delivery.

Create these custom Opportunity fields:

| Field                        | Type / example                                                         |
| ---------------------------- | ---------------------------------------------------------------------- |
| Engagement Code              | Text, immutable, e.g. `PDA-2026-K7M9`                                  |
| Service Category             | Controlled select                                                      |
| Service Description          | Long text                                                              |
| Client Deadline              | Date/time                                                              |
| Deadline Type                | Flexible / Hard / External submission                                  |
| Pipeline Stage               | Controlled select                                                      |
| Quote Amount                 | Number                                                                 |
| Currency                     | Select, default USD                                                    |
| Deposit Required             | Number                                                                 |
| Total Paid Cached            | Number                                                                 |
| Outstanding Balance Cached   | Number                                                                 |
| Payment Status               | Not invoiced / Deposit due / Partial / Paid / Overdue / Refunded       |
| Trello Card ID               | Text                                                                   |
| Trello Card URL              | URL                                                                    |
| Delivery Board               | Text/select                                                            |
| Assigned Owner               | User / select                                                          |
| Next Follow-up Date          | Date                                                                   |
| Lead Source                  | Website / WhatsApp / Referral / Returning client / Other               |
| Intake Complete              | Boolean                                                                |
| Client Consent for Follow-up | Boolean                                                                |
| Risk Flag                    | Normal / Deadline risk / Payment risk / Scope risk                     |
| Internal Delivery Status     | Not started / Active / Waiting on client / Internal review / Delivered |

Use this pipeline:

```text
New Inquiry
Qualified
Proposal Sent
Awaiting Deposit
Active
Waiting on Client
Internal Review
Ready for Delivery
Delivered
Follow-up / Revisions
Closed Won
Closed Lost
```

### 8.3 Payment custom object

Create `Payment` as a custom object linked to Opportunity.

Fields:

| Field                    | Purpose                                                |
| ------------------------ | ------------------------------------------------------ |
| Payment Reference        | Immutable external or internal reference               |
| Payment Date             | Date/time                                              |
| Amount                   | Number                                                 |
| Currency                 | Select                                                 |
| Status                   | Pending / Paid / Failed / Refunded / Voided            |
| Payment Method           | Stripe / PayPal / Zelle / Bank transfer / Cash / Other |
| Processor Transaction ID | Text                                                   |
| Invoice or Receipt Link  | URL                                                    |
| Recorded By              | User                                                   |
| Notes                    | Long text                                              |

Never store payment card data, account numbers, or processor secrets.

### 8.4 Milestone custom object

Create `Milestone` linked to Opportunity.

Fields:

| Field          | Purpose                                                            |
| -------------- | ------------------------------------------------------------------ |
| Milestone Name | Controlled text                                                    |
| Due Date       | Date/time                                                          |
| Status         | Not started / In progress / Waiting on client / Complete / Skipped |
| Completed Date | Date/time                                                          |
| Assigned Owner | User                                                               |
| Client Visible | Boolean                                                            |
| Trello Card ID | Text, optional                                                     |
| Notes          | Long text                                                          |

Suggested milestones:

```text
Initial consultation complete
Scope confirmed
Deposit received
Materials received
Dataset received
Analysis complete
Draft delivered
Revision received
Final delivery complete
```

### 8.5 Person fields

Add only what is genuinely needed:

```text
Phone
WhatsApp Number
Preferred Contact Method
Lead Source
Consent for follow-up
Country / Time Zone
Client Status
```

Use email as the first duplicate-matching key. Use normalized phone as a secondary key when email is absent.

---

## 9. Trello delivery-board phase

### 9.1 Create a dedicated board

Board name:

```text
ProData Client Delivery
```

Lists:

```text
New Intake
Qualified / Scoping
Proposal Sent
Awaiting Deposit
Active Work
Waiting on Client
Internal Review
Ready for Delivery
Delivered
Closed / Archived
```

### 9.2 Card naming convention

```text
[PDA-2026-K7M9] Client Name — Service Category — Due YYYY-MM-DD
```

Do not include full payment history, sensitive client notes, document contents, or private contact details in card titles or descriptions.

### 9.3 Correct the current Trello bridge design

Do not modify the existing gateway directly. Create:

```text
ProData CRM Trello Bridge v1
```

Required improvements:

1. Use a dedicated ProData board configuration.
2. Store board/list configuration outside hard-coded workflow JavaScript where possible.
3. Add authentication to inbound webhook actions.
4. Add idempotency keys for repeated requests.
5. Persist Trello Card ID and URL in Twenty immediately after card creation.
6. Update cards only by Card ID.
7. Add description intentionally; do not rely on an unused prepared field.
8. Correct card movement so the target list ID is actually written to Trello.
9. Use timezone-aware deadlines.
10. Log sync failures in a structured error table or alert channel.

### 9.4 Allowed synchronization direction

#### First release: Twenty → Trello only

When Opportunity stage becomes `Active`:

```text
Twenty Opportunity
      ↓
n8n
      ↓
Create Trello Card
      ↓
Write Trello Card ID and URL back to Opportunity
```

#### Second release: limited Trello → Twenty

Only these Trello list moves may update Twenty:

| Trello list        | Twenty update                                |
| ------------------ | -------------------------------------------- |
| Waiting on Client  | Internal Delivery Status = Waiting on client |
| Internal Review    | Internal Delivery Status = Internal review   |
| Ready for Delivery | Pipeline Stage = Ready for Delivery          |
| Delivered          | Pipeline Stage = Delivered                   |

Do not allow Trello list movement to change quote amount, payment status, deadlines, contact fields, or Closed Won/Lost status.

---

## 10. n8n workflow build plan

### Workflow 01 — Client Intake

Trigger:

```text
WordPress/Forminator submission → n8n webhook
```

Steps:

1. Validate required values.
2. Normalize name, email, and phone.
3. Validate consent field if marketing/follow-up communications apply.
4. Search Twenty Person by normalized email.
5. If no email, search by normalized phone.
6. Create Person if no match exists.
7. Create Opportunity linked to Person.
8. Generate immutable engagement code.
9. Set stage to `New Inquiry`.
10. Set deadline and lead source.
11. Create internal notification.
12. Send acknowledgement to client only after confirmation of the correct message template.
13. Save form submission ID and workflow execution reference.
14. Return a non-sensitive success response.

Idempotency key:

```text
source + source_submission_id
```

Acceptance criteria:

```text
Same form submission twice creates one Opportunity.
Same email with a new request creates one Person and two Opportunities.
No email creates a manual-review queue rather than an uncontrolled duplicate.
```

### Workflow 02 — Approved Engagement to Trello

Trigger:

```text
Opportunity enters Active stage
```

Steps:

1. Confirm there is no stored Trello Card ID.
2. Confirm required deposit/payment condition if configured.
3. Create Trello card in `Active Work`.
4. Include engagement code, service category, due date, Twenty URL, and safe scope summary.
5. Write Card ID and URL back to Twenty.
6. Create initial Trello checklist or milestone tasks if needed.
7. Notify owner.

Idempotency key:

```text
opportunity_id + trello_create_v1
```

### Workflow 03 — Trello Stage Event to Twenty

Trigger:

```text
Trello Trigger event
```

Steps:

1. Verify event originates from the dedicated ProData board.
2. Ignore unsupported Trello actions.
3. Read Card ID.
4. Search Twenty Opportunity by Trello Card ID.
5. Use the approved list mapping only.
6. Update Internal Delivery Status or approved Pipeline Stage.
7. Record event action ID to prevent replay.
8. Alert on unmatched Trello cards rather than creating CRM records automatically.

### Workflow 04 — Payment Recording and Balance Update

Initial trigger options:

```text
Manual staff form
Payment processor webhook
Invoice system webhook
```

Steps:

1. Validate payment reference.
2. Find Opportunity.
3. Create Payment record.
4. Recalculate `Total Paid Cached`.
5. Recalculate `Outstanding Balance Cached`.
6. Determine Payment Status.
7. If deposit threshold is met and Opportunity is `Awaiting Deposit`, move it to `Active`.
8. Trigger Workflow 02 only after the stage transition.
9. Send receipt/acknowledgement only through an approved payment process.

### Workflow 05 — Deadline and Follow-up Watch

Schedule:

```text
Daily at 8:00 AM America/New_York
```

Rules:

* Flag hard deadlines within 3 days.
* Flag milestones due within 2 days.
* Flag overdue payment status.
* Flag Proposal Sent opportunities with no follow-up after 5 business days.
* Flag Waiting on Client items with no activity after 7 business days.
* Send one concise owner summary via Telegram or email.
* Do not send client messages automatically in version one.

### Workflow 06 — Error Monitoring and Reconciliation

Schedule:

```text
Every 6 hours during testing; daily after stabilization
```

Checks:

* Active Opportunity without Trello Card ID.
* Trello Card ID in Twenty but no matching Trello card.
* Trello card moved to a controlled list but CRM status not updated.
* Payment record exists but cached totals do not reconcile.
* Duplicate Person candidates using matching phone or email.
* n8n workflow failures within the prior 24 hours.
* Expiring Cloudflare service token or Twenty API key, when applicable.

---

## 11. API and credential design

### Twenty credentials

Create a dedicated Twenty role:

```text
n8n CRM Integration
```

Minimum privileges:

* Read/create/update Persons.
* Read/create/update Opportunities.
* Read/create/update Payments.
* Read/create/update Milestones.
* No unnecessary user-management or administrative permissions.

Create API key:

```text
n8n-prodata-crm-test
```

Store only in n8n credential storage or secured environment variables.

### n8n credential inventory

| Credential                          | Purpose                                 |
| ----------------------------------- | --------------------------------------- |
| Twenty CRM API key                  | Authenticates to Twenty                 |
| Cloudflare Access service token     | Reaches protected local Twenty endpoint |
| Trello API credential               | Creates/updates delivery cards          |
| WordPress/Forminator webhook secret | Validates client intake source          |
| Telegram/email credential           | Sends internal alerts                   |

### Required request model from n8n to Twenty

```text
Cloudflare Access headers
+
Twenty Bearer API key
+
Strict request timeout
+
Retry only for safe/idempotent operations
+
Structured error logging
```

---

## 12. Security and data handling

1. Use Cloudflare Access for browser and machine access.
2. Keep Twenty bound to local access; Cloudflare Tunnel is the exposure path.
3. Do not expose PostgreSQL or Redis ports publicly.
4. Use a separate strong database password.
5. Keep all secrets outside Git.
6. Restrict n8n API key scope.
7. Use fake client records during all early tests.
8. Minimize personal data collection.
9. Retain only necessary client communications and documents.
10. Create a documented deletion/archive procedure for closed engagements.
11. Use separate test and production credentials.
12. Never send full client records in Telegram alerts.
13. Do not enable AI/MCP write access until the core CRM and authorization model are stable.

---

## 13. Backup, recovery, and upgrade plan

### Local backup

Build `scripts/backup.ps1` to:

1. Create a timestamped PostgreSQL dump.
2. Store it in a local excluded `backups/` directory.
3. Verify the dump is non-empty.
4. Optionally encrypt the archive before off-device storage.
5. Retain a limited rolling number of backups.

### Restore verification

Build `scripts/restore-test.ps1` to:

1. Restore a backup into a separate temporary database or test compose project.
2. Confirm Twenty starts against the restored data.
3. Confirm a known dummy Person, Opportunity, Payment, and Milestone exist.
4. Delete the temporary restore environment after verification.

### Upgrade policy

Before every Twenty upgrade:

```text
1. Back up database.
2. Export configuration and workflow files.
3. Record current image tag.
4. Upgrade local test only.
5. Confirm migration completes.
6. Run smoke tests.
7. Run integration tests.
8. Upgrade production only after explicit approval.
```

No automatic upgrades.

---

## 14. Acceptance test matrix

### Infrastructure

* [ ] Docker Compose validates.
* [ ] All Twenty services start successfully.
* [ ] Local browser reaches Twenty.
* [ ] Persistent storage survives restart.
* [ ] Backup script completes.
* [ ] Restore test succeeds.

### Access security

* [ ] Cloudflare hostname works.
* [ ] Unauthorized browser is blocked.
* [ ] Authorized browser reaches Twenty.
* [ ] n8n without service token is denied.
* [ ] n8n with valid service token reaches Twenty.
* [ ] Twenty API without bearer key is denied.
* [ ] Scoped n8n API key performs only required operations.

### CRM model

* [ ] Create Person.
* [ ] Create Opportunity linked to Person.
* [ ] Create Payment linked to Opportunity.
* [ ] Create Milestone linked to Opportunity.
* [ ] Opportunity shows correct payment totals.
* [ ] Deadline fields sort/filter correctly.
* [ ] Engagement code is unique and immutable.

### Intake

* [ ] New client creates Person + Opportunity.
* [ ] Existing client creates no duplicate Person.
* [ ] Duplicate submission is idempotent.
* [ ] Missing required data routes to review.
* [ ] Client-facing response contains no internal details.

### Trello

* [ ] Active Opportunity creates one Trello card.
* [ ] Trello Card ID and URL are stored in Twenty.
* [ ] Re-running the workflow does not create a duplicate card.
* [ ] Approved Trello list move updates Twenty.
* [ ] Unsupported Trello move does not modify financial or client data.
* [ ] Trello event replay does not duplicate updates.

### Reporting

* [ ] View for New Inquiries.
* [ ] View for Awaiting Deposit.
* [ ] View for deadlines within 7 days.
* [ ] View for overdue balances.
* [ ] View for Waiting on Client.
* [ ] Daily alert gives only the required summary.

---

## 15. Definition of done for local proof-of-concept

The local proof-of-concept is complete only when:

1. Twenty runs reliably in Docker Desktop.
2. `crm-test.prodatanalytics.com` is protected by Cloudflare Access.
3. The CRM schema is implemented and documented.
4. A fake website intake creates or updates the appropriate Person and Opportunity.
5. An Active Opportunity creates exactly one linked Trello card.
6. A controlled Trello list change updates only the designated Twenty status field.
7. A test payment updates payment totals and status correctly.
8. Daily deadline monitoring produces an internal summary.
9. Backup and restore are verified.
10. No secrets, real client data, or payment credentials exist in the repository.
11. All workflow exports and operational runbooks are committed.
12. Owner approves transition to VPS production planning.

---

## 16. Explicitly out of scope for version one

* Full accounting or invoicing system.
* Automated client billing.
* Automatic WhatsApp follow-ups.
* Mass marketing campaigns.
* AI agent write access to CRM.
* Direct payment processor credential storage in Twenty.
* Full two-way synchronization of every Trello field.
* Migration of all historical data before schema and automation tests pass.
* Multi-user production access beyond approved administrators.
* Any storage of patient or health-record information.

---

## 17. Recommended execution order

```text
Phase 0 — Repository, security boundaries, documentation
Phase 1 — Local Docker Twenty deployment
Phase 2 — Named Cloudflare Tunnel and Access protection
Phase 3 — Twenty schema and views
Phase 4 — Create isolated n8n test credentials
Phase 5 — Intake workflow with fake data
Phase 6 — Twenty-to-Trello one-way card creation
Phase 7 — Limited Trello-to-Twenty status sync
Phase 8 — Payment and deadline workflows
Phase 9 — Backup/restore and reconciliation tests
Phase 10 — Production migration design; no deployment without approval
```

## 18. First Codex task

Start with Phase 0 and Phase 1 only.

Deliver:

```text
- Repository scaffold
- AGENTS.md
- Docker Compose implementation
- .env.example
- Start/stop/status/health-check scripts
- Architecture and setup documentation
- Smoke-test report
- No Cloudflare, production n8n, Trello, WordPress, or real-data changes yet
```

Stop after Phase 1 and present:

```text
1. Files created/changed
2. Exact local start command
3. Container status
4. Local URL test result
5. Required owner actions before Phase 2
6. Any blockers or deviations from official Twenty deployment guidance
```
npx skillfish add lev-os/agents interpreting-electrocardiograms

Codex instllation: curl -sSL https://app.mcpmarket.com/install/DMiikzjxSXDX0hj4BfcWZFb9lhEHU3Y7y6xQ6oPYBb0 | bash

clude code: curl -sSL https://app.mcpmarket.com/install/5EfghAKz44cdRxSWm3zB6l_ntd8naCs4d-S-zmCo7gY | bash