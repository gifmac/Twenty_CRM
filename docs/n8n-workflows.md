# n8n Workflows

## Scope

This document defines the safe n8n setup path for the ProData CRM test. It does not contain importable workflow JSON or secrets.

Current status:

- Cloudflare Access browser block works.
- Cloudflare Access service-token request works.
- n8n manual Access smoke test returns HTTP 200.
- Twenty API key is not documented yet.
- CRM schema is not finalized yet.

Do not activate production workflows until the Twenty schema, fake-data tests, and rollback plan are complete.

## Credential Inventory

Create credentials in n8n with these names.

| Credential name | n8n type | Purpose | Status |
| --- | --- | --- | --- |
| `Cloudflare Access - crm-test` | HTTP Request generic `Custom Auth` | Adds Cloudflare Access service-token headers | Ready to create |
| `Twenty CRM API - crm-test` | HTTP Request header auth or request header | Adds Twenty bearer token | Pending Twenty API key |
| `Trello - ProData Delivery` | Trello credential | Creates and updates delivery cards | Future phase |
| `Forminator Intake Secret - crm-test` | Webhook secret or generic secret | Validates website intake source | Future phase |

Do not store these values in workflow JSON exports, `.env`, Trello cards, screenshots, or repository files.

## Cloudflare Access Credential

n8n has no built-in credential type named `Cloudflare Access`.

Use:

```text
Credential type: HTTP Request
Authentication: Generic Credential Type
Generic Auth Type: Custom Auth
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

Use the real Cloudflare Access service token values in n8n only.

## Manual Smoke Test Workflow

Purpose: confirm n8n can reach Twenty through Cloudflare Access before building CRM automation.

Workflow name:

```text
ProData CRM - 00 Access Smoke Test
```

Trigger:

```text
Manual Trigger
```

Node sequence:

1. Manual Trigger.
2. Set run context.
3. HTTP Request: GET `https://crm-test.proeduconnect.com/healthz`.
4. IF status is `200`.
5. Success log or failure log.

HTTP Request node:

```text
Method: GET
URL: https://crm-test.proeduconnect.com/healthz
Authentication: Generic Credential Type
Generic Auth Type: Custom Auth
Credential: Cloudflare Access - crm-test
Response: Include status code
Timeout: 10000 ms
Retry on fail: off for initial smoke test
```

Pass:

```text
HTTP status 200
```

Current result:

```text
HTTP status 200
```

Fail:

```text
302: Cloudflare Access service token is not being sent or policy does not include the token.
401/403: Access policy or token is wrong.
5xx/timeout: tunnel, local Docker, or Twenty origin is unhealthy.
```

## Twenty API Credential

After the Twenty API key exists, create the credential separately if n8n supports it cleanly:

```text
Credential name: Twenty CRM API - crm-test
Auth type: Header Auth
Name: Authorization
Value: Bearer <TWENTY_API_KEY>
```

If an HTTP Request node can use only one generic credential, keep `Cloudflare Access - crm-test` as the credential and add the Twenty API key as a node header:

```text
Authorization: Bearer <TWENTY_API_KEY>
```

For workflow exports, replace the token with:

```text
Bearer <TWENTY_API_KEY>
```

Detailed Twenty role, API key, and validation steps are in [twenty-api-setup.md](twenty-api-setup.md).

## Workflow 01 Design: Client Intake

Build only after the Twenty schema exists and fake test fields are confirmed.

Intent:

```text
Create or find a Person, then create one Opportunity for a validated website intake.
```

Trigger:

```text
Webhook, POST only
```

Required input fields:

```text
source
source_submission_id
client_name
email or phone
service_category
service_description
deadline
consent_for_follow_up
```

Node sequence:

1. Webhook Trigger.
2. Initialize run context.
3. Validate source authentication.
4. Normalize name, email, phone, deadline, and service category.
5. Build dedup key: `source + source_submission_id`.
6. Check dedup tracker.
7. Search Twenty Person by normalized email.
8. If no email match, search by normalized phone.
9. Create Person only if no match exists.
10. Create Opportunity linked to Person.
11. Write dedup tracker row.
12. Log run outcome.
13. Respond with non-sensitive success body.
14. On validation failure, write review queue item and return safe failure response.

Idempotency:

```text
dedup_key = source + ":" + source_submission_id
```

Duplicate behavior:

- Same `source_submission_id`: do not create another Opportunity.
- Same email with a new submission ID: reuse Person and create a new Opportunity.
- Missing email and ambiguous phone: route to manual review.

Audit fields:

```text
run_id
workflow_name
trigger_type
started_at
source_count
valid_count
duplicate_count
processed_count
failed_count
status
error_summary
finished_at
```

Review queue record:

```json
{
  "run_id": "<string>",
  "dedup_key": "<string>",
  "source_ref": "<source_submission_id>",
  "payload_snapshot": {},
  "failure_stage": "<string>",
  "failure_reason": "<string>",
  "retry_count": 0,
  "review_status": "pending",
  "recommended_action": "<string>"
}
```

No-silent-failure gates:

- Stop if source auth is missing or invalid.
- Stop if required fields are missing.
- Stop if processed count does not equal valid count.
- Alert if duplicate rate is unexpectedly high.
- Alert if Twenty returns permission errors.

## Activation Rule

Keep all workflows inactive until:

- Smoke test succeeds.
- Twenty API key is created with minimal permissions.
- Schema and fields are verified in Twenty.
- Fake intake payloads pass.
- Owner approves activation.
