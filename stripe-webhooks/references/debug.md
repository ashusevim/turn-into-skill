# Debug + delivery behavior

## Status codes (Event deliveries tab, Workbench → Webhooks → endpoint)

| Status | Meaning | Fix |
|---|---|---|
| `200` | Delivered | — |
| ERR can't connect | Host unreachable | Endpoint must be public internet-reachable |
| `3xx` | Redirect treated as failure | Register the final resolved URL |
| `4xx` | Won't process / not found / blocked | Endpoint public, accepts POST, path correct |
| `5xx` | Your code errored | Check app logs |
| TLS ERR | Cert / chain issue, needs TLS ≥ 1.2 | Run an SSL server test |
| Timed out | Too slow | Return `2xx` first, defer work to a queue |

## Retries

- Live: exponential backoff up to 3 days. Sandbox: 3 retries over hours.
- Dashboard → event → **Resend** (15-day window) or `stripe events resend <event_id> --webhook-endpoint=<id>` (30 days). Manual resend does NOT cancel automatic retries — dedupe by event ID.

## Ordering

No order guarantee. Don't use `created` (second resolution, ties happen). Track event IDs; fetch missing objects via API from any event that arrives first.

## Checklist

- [ ] Subscribed to minimum event set only
- [ ] Async queue for heavy work; `2xx` returned immediately
- [ ] Duplicate event IDs skipped (also dedupe on `data.object.id` + `type` for double-generated events)
- [ ] Route exempted from CSRF (Rails `protect_from_forgery except:`, Django exemption, etc.)
- [ ] HTTPS with valid cert in live mode
- [ ] Secrets rolled periodically (Workbench ⋯ → Roll secret; 24h dual-active window supported)
