# Twenty API Setup

## Purpose

Create a dedicated Twenty API key for n8n that can perform only the CRM operations required for the test build.

Do not use a personal admin API key for n8n. Do not give n8n broad admin, settings, delete, destroy, import/export, workflow-management, or metadata permissions unless a later phase explicitly requires it.

## Official Twenty Behavior To Account For

Twenty generates REST and GraphQL APIs from the workspace schema. The exact endpoint names depend on the objects and fields in this workspace.

Twenty documents API key creation under:

```text
Settings -> API & Webhooks -> + Create key
```

Twenty documents role assignment for API keys under:

```text
Settings -> Members -> Roles -> <role> -> Assignment -> API Keys -> + Assign to API key
```

The API key is shown once. Copy it directly into the target credential store and do not save it in repository files.

## Step 1: Create The Role

In Twenty:

```text
Settings -> Members -> Roles -> + Create Role
```

Role name:

```text
n8n CRM Integration
```

Role intent:

```text
Machine role for the ProData CRM bridge. Used by n8n only.
```

## Step 2: Set Default Object Permissions

Use a deny-by-default shape if the UI allows it.

Recommended baseline:

```text
All Objects:
  See Records: off
  Create Records: off, if shown
  Edit Records: off
  Delete Records: off
  Destroy Records: off
```

If Twenty's UI only exposes `See Records` and `Edit Records` at this level, leave both off and add object-level exceptions below.

Do not enable:

```text
Delete Records
Destroy Records
Settings All Access
Application All Access
Import CSV
Export CSV
Send Email
Workflow management
Data model / metadata configuration
Role assignment
Security settings
```

## Step 3: Add Object-Level Exceptions

Add object-level rules for only the objects n8n must touch.

For the first safe test phase:

| Object | See | Create | Edit | Delete | Destroy | Why |
| --- | --- | --- | --- | --- | --- | --- |
| People / Persons | Yes | Yes, if shown | Yes | No | No | Create/update contacts from intake |
| Companies | Yes | Optional | Optional | No | No | Link institutions if used |
| Opportunities | Yes | Yes, if shown | Yes | No | No | Create/update engagements |

After custom objects exist, add:

| Object | See | Create | Edit | Delete | Destroy | Why |
| --- | --- | --- | --- | --- | --- | --- |
| Payments | Yes | Yes, if shown | Yes | No | No | Record payment status and reconciliation records |
| Milestones | Yes | Yes, if shown | Yes | No | No | Track delivery milestones |

If the UI has no separate `Create` permission, Twenty may group creation under `Edit Records`. In that case, enable `See Records` and `Edit Records` only for the objects above.

## Step 4: Field-Level Rules

Start simple for the local fake-data phase. Allow n8n to see/edit only the fields it must write.

Do not grant n8n access to fields that would contain:

```text
PHI
payment card data
bank details
private document contents
internal credentials
unnecessary personal notes
```

For initial CRM bridge testing, n8n needs these field groups:

People / Persons:

```text
Name
Email
Phone
WhatsApp Number
Preferred Contact Method
Lead Source
Consent for follow-up
Country / Time Zone
Client Status
```

Opportunities:

```text
Engagement Code
Service Category
Service Description
Client Deadline
Deadline Type
Pipeline Stage
Quote Amount
Currency
Deposit Required
Total Paid Cached
Outstanding Balance Cached
Payment Status
Trello Card ID
Trello Card URL
Delivery Board
Assigned Owner
Next Follow-up Date
Lead Source
Intake Complete
Client Consent for Follow-up
Risk Flag
Internal Delivery Status
```

Payments:

```text
Payment Reference
Payment Date
Amount
Currency
Status
Payment Method
Processor Transaction ID
Invoice or Receipt Link
Recorded By
Notes
Opportunity relation
```

Milestones:

```text
Milestone Name
Due Date
Status
Completed Date
Assigned Owner
Client Visible
Trello Card ID
Notes
Opportunity relation
```

## Step 5: Create The API Key

In Twenty:

```text
Settings -> API & Webhooks -> + Create key
```

Key name:

```text
n8n-prodata-crm-test
```

Copy the key immediately. It is shown once.

Store it only in:

```text
n8n credential storage
```

Do not store it in:

```text
.env
.env.example
docs
workflow JSON exports
screenshots
chat
Trello cards
```

## Step 6: Assign The Role To The API Key

In Twenty:

```text
Settings -> Members -> Roles -> n8n CRM Integration -> Assignment -> API Keys -> + Assign to API key
```

Select:

```text
n8n-prodata-crm-test
```

Confirm assignment.

This step matters. If the API key is not assigned to the restricted role, it may inherit default permissions that are broader than intended.

## Step 7: Add The API Key To n8n

Option A, preferred if n8n lets the node combine a credential and a header:

```text
Credential: Cloudflare Access - crm-test
Header:
  Authorization: Bearer <TWENTY_API_KEY>
```

Option B, if the HTTP Request node cannot combine credentials cleanly:

Create one combined Custom Auth credential:

```text
Credential name: Twenty via Cloudflare - crm-test
Credential type: HTTP Request / Custom Auth
```

Custom Auth JSON:

```json
{
  "headers": {
    "CF-Access-Client-Id": "<CLIENT_ID>",
    "CF-Access-Client-Secret": "<CLIENT_SECRET>",
    "Authorization": "Bearer <TWENTY_API_KEY>"
  }
}
```

Option A is easier to rotate cleanly. Option B is acceptable for the local test if n8n's UI forces one credential per HTTP Request node.

## Step 8: Validation Tests

Run these in order from n8n using fake data only.

### A. Cloudflare Access Only

Already passed:

```text
GET https://crm-test.proeduconnect.com/healthz
Credential: Cloudflare Access - crm-test
Expected: HTTP 200
```

### B. API Without Twenty Bearer Key

Create a temporary HTTP Request node:

```text
URL: https://crm-test.proeduconnect.com/rest/people
Credential: Cloudflare Access - crm-test
Authorization header: omitted
```

Expected:

```text
401 or 403 from Twenty
```

If it returns CRM data, stop. The API is not enforcing bearer authentication as expected.

### C. API With Twenty Bearer Key

Create a temporary HTTP Request node:

```text
URL: https://crm-test.proeduconnect.com/rest/people
Credential: Cloudflare Access - crm-test
Header:
  Authorization: Bearer <TWENTY_API_KEY>
```

Expected:

```text
HTTP 200
```

If `/rest/people` is not the generated endpoint name in this workspace, use the workspace-specific API documentation in:

```text
Settings -> API & Webhooks
```

Twenty's API docs are generated from the workspace schema.

### D. Permission Boundary Test

Try a request n8n should not be allowed to perform, such as delete/destroy or metadata modification.

Expected:

```text
401 or 403
```

Do not run destructive tests against real data.

## Ready Criteria

This phase is ready when:

- API key exists. Completed July 1, 2026.
- API key is assigned to `n8n CRM Integration`. Completed July 1, 2026.
- n8n can reach a harmless Twenty read endpoint through Cloudflare Access.
- Missing bearer token is denied.
- Forbidden operation is denied.
- No real client data was used.

## Sources

- Twenty API docs: https://docs.twenty.com/developers/extend/api
- Twenty permissions docs: https://docs.twenty.com/user-guide/permissions-access/capabilities/permissions
