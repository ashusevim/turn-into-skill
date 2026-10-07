# Payloads + scopes

## Thin vs snapshot

- **Thin (recommended for new integrations):** small payload, `related_object` stub + `fetchRelatedObject()` / `fetchEvent()` to hydrate. Unknown post-SDK event types arrive as `UnknownEventNotification` — match on `.type`.
- **Snapshot:** full `Event` object, `data.object` usable directly, `previous_attributes` without extra calls. Required if a third-party tool needs the complete payload.
- Separate endpoints per payload type. API version pinned at event creation — version upgrades never rewrite old events.

## Connect (`events_from`)

- `@self` — your platform account only.
- `@accounts` — connected accounts (direct charges, connected Customers/payment methods, payout failures, legacy lifecycle events).
- Local test: `stripe listen --forward-connect-to …` / `--forward-thin-connect-to …`.
- Details: `https://docs.stripe.com/connect/webhooks.md`.

## Organizations

- `@organization_members` — events in org accounts. `@organization_members/@accounts` — their connected accounts.
- Limits: can't subscribe org destinations to `issuing_authorization.request`; `checkout_sessions.completed` can't drive redirect behavior; failed `invoice.created` can't stop auto-finalization. Handle those with account-level endpoints.
- Thin handlers: `fetchRelatedObject()` / `fetchEvent()` apply `context` automatically; all other API calls need `stripe_context=event_notification.context` manually.
