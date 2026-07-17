# Data Model

## Scope

Phase 3 builds the minimum ProData CRM schema in Twenty using fake data only.

Twenty remains the system of record for:

- clients and contacts,
- leads and opportunities,
- engagement deadlines and stages,
- payment status summaries,
- delivery milestone status,
- Trello card linkage.

Trello must not store contact details, payment history, document contents, or sensitive notes.

## Implementation Order

Build in this order:

1. Confirm native objects are enabled: Person, Company, Opportunity, Notes, Tasks.
2. Configure Opportunity stages.
3. Add Opportunity custom fields.
4. Add Person custom fields.
5. Create Payment custom object and fields.
6. Create Milestone custom object and fields.
7. Create saved views.
8. Create fake test records.
9. Verify n8n role can read/write only intended objects.

Do not build n8n intake automation until this schema exists and the fake records validate.

## Opportunity Pipeline

Configure Opportunity stages exactly:

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

Operational rule:

- Website intake creates `New Inquiry`.
- Payment/deposit clearance may move to `Active`.
- Trello can update only the limited delivery statuses approved in the Trello bridge design.
- Trello must not set `Closed Won`, `Closed Lost`, payment fields, contact fields, or quote fields.

## Opportunity Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| Engagement Code | Text | Yes | Immutable after creation, e.g. `PDA-2026-K7M9` |
| Service Category | Select | Yes | Use `config/service-catalog.json` categories |
| Service Description | Long text | Yes | Safe scope summary only; no sensitive files |
| Client Deadline | Date/time | Optional | Store timezone-aware deadline if source provides timezone |
| Deadline Type | Select | Optional | `Flexible`, `Hard`, `External submission` |
| Pipeline Stage | Select/stage | Yes | Use pipeline above |
| Quote Amount | Number | Optional | USD default, no card data |
| Currency | Select | Yes | Default `USD` |
| Deposit Required | Number | Optional | Amount required before active work |
| Total Paid Cached | Number | Optional | Derived by payment workflow |
| Outstanding Balance Cached | Number | Optional | Derived by payment workflow |
| Payment Status | Select | Yes | `Not invoiced`, `Deposit due`, `Partial`, `Paid`, `Overdue`, `Refunded` |
| Trello Card ID | Text | Optional | Required for Trello updates; never search by title |
| Trello Card URL | URL | Optional | Link to delivery card |
| Delivery Board | Text/select | Optional | Default `ProData Client Delivery` |
| Assigned Owner | User/select | Optional | Internal owner |
| Next Follow-up Date | Date | Optional | Used by follow-up watch |
| Lead Source | Select | Optional | `Website`, `WhatsApp`, `Referral`, `Returning client`, `Other` |
| Intake Complete | Boolean | Yes | Default false |
| Client Consent for Follow-up | Boolean | Optional | Do not infer consent |
| Risk Flag | Select | Yes | `Normal`, `Deadline risk`, `Payment risk`, `Scope risk` |
| Internal Delivery Status | Select | Yes | `Not started`, `Active`, `Waiting on client`, `Internal review`, `Delivered` |

## Person Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| Phone | Phone/text | Optional | Normalize before matching |
| WhatsApp Number | Phone/text | Optional | May equal phone |
| Preferred Contact Method | Select | Optional | `Email`, `WhatsApp`, `Phone`, `Other` |
| Lead Source | Select | Optional | Same values as Opportunity |
| Consent for follow-up | Boolean | Optional | Do not use as marketing consent unless source explicitly says so |
| Country / Time Zone | Text/select | Optional | Prefer IANA timezone when known |
| Client Status | Select | Optional | `Lead`, `Active client`, `Past client`, `Do not contact` |

Duplicate matching:

1. Normalized email.
2. Normalized phone when email is absent.
3. Manual review when neither key is reliable.

## Payment Object

Create custom object:

```text
Payment
```

Relation:

```text
Payment -> Opportunity
```

Fields:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| Payment Reference | Text | Yes | Immutable reference |
| Payment Date | Date/time | Yes | Transaction or recorded date |
| Amount | Number | Yes | Positive amount |
| Currency | Select | Yes | Default `USD` |
| Status | Select | Yes | `Pending`, `Paid`, `Failed`, `Refunded`, `Voided` |
| Payment Method | Select | Optional | `Stripe`, `PayPal`, `Zelle`, `Bank transfer`, `Cash`, `Other` |
| Processor Transaction ID | Text | Optional | Never store processor secret |
| Invoice or Receipt Link | URL | Optional | Link only |
| Recorded By | User/select | Optional | Staff or workflow |
| Notes | Long text | Optional | No card/bank data |

Never store card numbers, CVV, bank account numbers, processor credentials, or raw payment payloads.

## Milestone Object

Create custom object:

```text
Milestone
```

Relation:

```text
Milestone -> Opportunity
```

Fields:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| Milestone Name | Select/text | Yes | Use suggested values below |
| Due Date | Date/time | Optional | Used by deadline watch |
| Status | Select | Yes | `Not started`, `In progress`, `Waiting on client`, `Complete`, `Skipped` |
| Completed Date | Date/time | Optional | Set only when complete |
| Assigned Owner | User/select | Optional | Internal owner |
| Client Visible | Boolean | Yes | Default false |
| Trello Card ID | Text | Optional | Optional card linkage |
| Notes | Long text | Optional | No sensitive document contents |

Suggested milestone names:

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

## Saved Views

Create these Twenty views:

| View | Object | Filter | Sort |
| --- | --- | --- | --- |
| New Inquiries | Opportunities | Stage = `New Inquiry` | Created date ascending |
| Awaiting Deposit | Opportunities | Stage = `Awaiting Deposit` or Payment Status = `Deposit due` | Client Deadline ascending |
| Active Work | Opportunities | Stage = `Active` | Client Deadline ascending |
| Deadline Risk | Opportunities | Risk Flag = `Deadline risk` or Client Deadline within 7 days | Client Deadline ascending |
| Waiting on Client | Opportunities | Internal Delivery Status = `Waiting on client` | Next Follow-up Date ascending |
| Overdue Balances | Opportunities | Payment Status = `Overdue` | Client Deadline ascending |
| Delivery Review | Opportunities | Stage = `Internal Review` or `Ready for Delivery` | Client Deadline ascending |

## Fake Records To Create

Create these manually in Twenty after schema setup:

1. Person: `Fake Client Alpha`, email `fake.alpha@example.com`.
2. Opportunity: `PDA-2026-TEST1`, stage `New Inquiry`, service category `Statistical Analysis`.
3. Payment: `TEST-PAYMENT-001`, status `Paid`, amount `100`, linked to `PDA-2026-TEST1`.
4. Milestone: `Scope confirmed`, status `Complete`, linked to `PDA-2026-TEST1`.

Pass:

- Person exists.
- Opportunity is linked to Person.
- Payment is linked to Opportunity.
- Milestone is linked to Opportunity.
- Opportunity payment totals can be represented without storing payment secrets.
- Deadline views sort/filter correctly.
- Engagement Code is not casually edited after creation.

