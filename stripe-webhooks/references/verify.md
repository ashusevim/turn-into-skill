# Signature verification

Stripe signs every event. Two layers: IP allowlisting (see `https://docs.stripe.com/ips.md`) + signature check below. Always do the signature check.

## With official libraries (recommended)

Provide raw body + `Stripe-Signature` header + `whsec_` secret. Never let the framework parse/mutate the body first.

**Ruby (Sinatra):**
```ruby
payload = request.body.read
sig_header = request.env['HTTP_STRIPE_SIGNATURE']
begin
  event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
rescue JSON::ParserError
  status 400; return
rescue Stripe::SignatureVerificationError => e
  puts "Signature failed: #{e.message}"
  status 400; return
end
```

**Python (Flask, thin events):**
```python
event_notif = client.parse_event_notification(
    request.data,                       # raw bytes, unparsed
    request.headers.get("Stripe-Signature"),
    webhook_secret,
)
```

**Node (Express):** disable body parsing on the webhook route — `express.raw({type: 'application/json'})` — then `stripe.webhooks.constructEvent(rawBody, sigHeader, secret)`.

Troubleshooting verification errors: `https://docs.stripe.com/events/manage-webhook-endpoints.md#signature-errors`. #1 cause is a framework that parsed the body before verification.

## Manual verification

1. Split `Stripe-Signature` on `,` then on `=` → timestamp `t`, signatures `v1` (ignore `v0` test scheme and any non-`v1` scheme to block downgrade attacks).
2. `signed_payload = "<t>" + "." + <raw JSON body>`.
3. `expected = HMAC_SHA256(key=endpoint_secret, msg=signed_payload)`.
4. Constant-time-compare `expected` against each `v1` signature. During secret rolls multiple secrets are active — Stripe emits one signature per secret.

## Replay protection

`t` is part of the signed payload, so attackers can't alter it. Reject payloads whose `t` differs from now by more than your tolerance (SDK default: 5 minutes). Never set tolerance to `0`. Keep server clock synced via NTP. Retried deliveries get a fresh timestamp + signature each attempt.
