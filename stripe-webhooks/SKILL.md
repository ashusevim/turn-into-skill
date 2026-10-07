---
name: stripe-webhooks
description: Receive and handle Stripe webhook events. Use when setting up a Stripe webhook endpoint, verifying Stripe-Signature headers, handling payment_intent/subscription/invoice events, testing webhooks locally with stripe listen, debugging delivery failures, or working with thin vs snapshot events.
---

# Stripe Webhooks

Build a webhook endpoint that receives Stripe events, verifies they came from Stripe, handles them idempotently, and returns `2xx` fast.

Distilled from `https://docs.stripe.com/webhooks`. Covers thin + snapshot events, Connect/Organization scopes in `references/scopes.md`.

## When to use

- Creating a webhook endpoint or event destination (Dashboard, API, CLI)
- Writing the handler: signature verification, event routing, idempotency
- Testing locally with `stripe listen` / `stripe trigger`
- Debugging deliveries: retries, ordering, HTTP status codes
- Choosing thin vs snapshot payloads, Connect or Organization scopes

## Instructions

1. **Register the destination, get the secret.** Workbench → Webhooks → Create event destination → pick Thin (new integrations) or Snapshot (need full object / `previous_attributes`) → select only the event types the integration needs → destination type Webhook endpoint → URL `https://<domain>/<route>`. Copy the `whsec_…` signing secret. Done when: secret stored in env, never in code.
2. **Scaffold a POST route that returns 2xx fast.** Accept POST with JSON body, verify signature (step 3), route on `event.type`, return `200` before any heavy work — queue complex logic async. Done when: unhandled types log + return `200`, no business logic blocks the response.
3. **Verify every request.** Read the raw body untouched (no framework body parsing before verification), take the `Stripe-Signature` header + `whsec_` secret, verify with the official SDK (`Stripe::Webhook.construct_event`, `client.parse_event_notification`, etc.). On failure return `400` and do nothing else. See `references/verify.md` for per-language snippets + manual HMAC. Done when: forged payload without valid signature gets `400`.
4. **Handle events idempotently and order-free.** Log processed event IDs, skip repeats; never depend on delivery order (Stripe retries up to 3 days, no ordering guarantee). Subscribe to the minimum event set. Exempt the route from CSRF. Done when: redelivered event ID is a no-op, handler tolerates any arrival order.
5. **Test locally, then debug live.** `stripe login` → `stripe listen --forward-to localhost:4242/webhook` (snapshot) or `--forward-thin-to … --thin-events "*"` → trigger with `stripe trigger payment_intent.succeeded` or Dashboard actions. For live failures check the destination's Event deliveries tab; see `references/debug.md` for the status-code table. Done when: triggered test event arrives, verifies, returns `2xx`.

## References

- `references/verify.md` — signature verification snippets (Ruby/Python/Node) + manual HMAC steps + replay protection
- `references/debug.md` — delivery status codes, retries, ordering, best-practices checklist
- `references/scopes.md` — thin vs snapshot, Connect (`@self`/`@accounts`), Organization contexts
