# Security And Data Handling

## Local Test Rules

- Use fake client data only.
- Do not store patient records, PHI, payment card data, bank account details, or sensitive client files in this system.
- Do not commit `.env`, backups, exports, logs, screenshots with sensitive content, or workflow files containing credential values.
- Do not place secrets in Trello card names, Trello descriptions, n8n workflow JSON, or documentation.

## Secret Locations

| Secret | Storage location |
| --- | --- |
| Twenty `ENCRYPTION_KEY` | Local `.env`; future production secret store |
| Postgres password | Local `.env`; future production secret store |
| Cloudflare Access service token | n8n credential store or secure environment variables |
| Twenty API key for n8n | n8n credential store |
| Trello API credential | n8n credential store |
| WordPress webhook secret | n8n credential store or source platform secret storage |

Checked-in `.env.example` files may document variable names only.

## Redaction Rules

When documenting issues, replace real values:

- Emails: `owner@example.com`
- Phone numbers: `+15555550123`
- API keys/tokens: `<REDACTED>`
- Client names: `Fake Client`
- Payment references: `TEST-PAYMENT-001`

