# Prism Mail

Calm mail intelligence for the Prism ecosystem: turn inbox noise into focused, actionable digests without making mail providers, AI vendors, or delivery clients part of the product core.

## Status

The first executable slice reads HQBase Mail API v1 inbox summaries and produces a versioned, deterministic JSON digest. It uses source excerpts, not AI-generated analysis. Live account access and Hub delivery are not yet verified.

## Responsibility

Prism Mail owns the mail-specific application semantics:

- ingest mail through focused source ports;
- normalize provider data into product-owned mail evidence;
- classify, rank, and compose digest inputs without binding the domain to an AI vendor;
- request analysis through a provider-neutral AI port backed by the `aiaiaiai-org/artificial-intelligence` foundation;
- produce presentation-neutral digest artifacts, including text and narration-ready scripts;
- integrate those artifacts with Prism Hub through an explicit, versioned service boundary.

Prism Mail is **not** a second Prism control plane. Prism Hub remains the owner of identity, service configuration, schedules, delivery policy, and client-facing APIs. Telegram, Matrix, future 0x1 clients, and other messaging surfaces consume Prism Hub; they do not call Prism Mail directly.

```text
mail providers
     │
     ▼
source adapters
     │
     ▼
Prism Mail domain + application
     │
     ├── AI port ──> artificial-intelligence ──> remote/local inference adapters
     │
     └── digest artifacts
              │
              ▼
          Prism Hub
              │
              ▼
      messaging / UI clients
```

## First product path

The intended first useful slice is deliberately narrow:

1. read mail from HQBase through its existing read-only Mail API/MCP surface;
2. normalize the selected messages without persisting unnecessary provider payloads;
3. generate a focused morning digest through a remote AI provider behind the shared AI boundary;
4. return a text artifact to Prism Hub;
5. add narration and voice delivery only after the text path is correct and observable.

Gmail, Proton, additional AI providers, local inference, and voice synthesis are later adapters behind the same boundaries rather than reasons to branch the product core.

## Design rules

- Product semantics stay in Prism Mail; generic inference/runtime semantics stay in `artificial-intelligence`.
- Provider SDKs and network clients live in adapters, never in domain or application policy.
- Mail, AI, and delivery credentials never enter client payloads.
- A generated digest is data, not authority to send, reply, archive, or mutate mail.
- Delivery is Hub-owned; Prism Mail never calls Telegram, Matrix, or another client transport directly.
- Persistence of message bodies requires an explicit retention policy; bootstrap code must not introduce ambient retention.
- Failures are explicit and observable. Missing mail, unavailable inference, and failed delivery are not converted into empty success.

See [`docs/architecture.md`](docs/architecture.md) for the normative boundary and [`docs/status.md`](docs/status.md) for the implemented/TODO split.

## Development

Ruby `4.0.6` is the bootstrap runtime.

```bash
bundle install
bundle exec rubocop
bundle exec rake test
bundle exec rake check
```

## Run a read-only digest

The `prism-mail` executable takes server-side configuration from the environment.
See [`docs/running.md`](docs/running.md) for its credential contract, time window,
limits, error behavior, and a synthetic example. It writes one JSON artifact to
stdout only after the full bounded scan succeeds. Scheduling and delivery remain
Hub-owned.

## License

Licensed under the Apache License, Version 2.0. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

---

© 2026 aiaiaiai · aiaiaiai.org
