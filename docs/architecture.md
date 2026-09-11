# Prism Mail architecture

This document is normative for the repository. A change that violates these boundaries is not ready to merge even when tests pass.

## Product role

Prism Mail is the mail-intelligence vertical in the Prism ecosystem. It converts authorized mail evidence into focused digest artifacts. It is not a mail server, not a generic AI runtime, not a delivery transport, and not a second control plane.

The architecture follows ports and adapters with dependencies directed inward:

```text
mail provider adapters ──> source ports ──> application use cases ──> domain values
                                              │
                                              ├──> AI port ──> AI adapter/foundation
                                              └──> Hub port ──> Prism Hub adapter
```

Domain and application code may depend on focused ports and product-owned values. They must not depend on provider SDKs, HTTP clients, databases, job frameworks, AI vendors, or messaging transports.

## Ownership boundary

### Prism Mail owns

- mail-specific evidence and normalization semantics;
- digest selection, grouping, ranking, and composition policy;
- the distinction between factual evidence, extracted actions, analysis, and presentation projections;
- narration-ready scripts as artifacts derived from the same evidence as text digests;
- focused ports for mail sources, AI analysis, persistence when justified, and Hub integration.

### Prism Hub owns

- canonical human/workspace identity;
- service registration and configuration exposed by the control plane;
- schedules and delivery policy;
- client-facing APIs;
- delivery history and cross-channel routing semantics;
- authorization for effects outside Prism Mail.

### `artificial-intelligence` owns

- product-agnostic inference/runtime contracts;
- provider-neutral model execution boundaries;
- generic proposal/authority/runtime semantics shared by products.

Prism Mail may consume those contracts but must not move mail vocabulary into the AI foundation.

### Clients own

Clients render and interact with Hub capabilities. Telegram, Matrix, future 0x1 clients, web panels, and other surfaces do not authenticate directly to mail providers and do not call Prism Mail as an alternate backend.

## Security and privacy invariants

1. Read access does not imply write authority. Digest generation cannot send, reply, archive, delete, star, or otherwise mutate mail.
2. Provider credentials remain inside server-side adapters or secret stores and never appear in domain values, artifacts, logs, or client payloads.
3. Message bodies are sensitive evidence. Persistence requires an explicit retention purpose, lifetime, deletion path, and access policy; bootstrap defaults to no ambient persistence.
4. AI input is minimized to the evidence required for the configured digest policy. A provider adapter must not silently widen that payload.
5. Vendor/model substitution cannot change product semantics. Provider-specific response shapes are normalized before they cross the AI port.
6. A narration artifact is a presentation projection, not a new source of facts. It must remain traceable to the same digest evidence as the text projection.
7. Failures remain failures. Missing source access, unavailable inference, invalid provider output, and failed Hub delivery are observable typed outcomes rather than empty digests.

## Extension rule

Add a provider, model, speech engine, persistence mechanism, or client transport behind an existing focused contract when the semantics are shared. If new semantics are genuinely required, add the smallest product-owned contract that expresses them instead of introducing a central provider switch.

## Initial sequence

The first production path should prove one boundary at a time:

```text
HQBase read-only source
        ↓
canonical mail evidence
        ↓
remote inference through shared AI boundary
        ↓
text digest artifact
        ↓
Prism Hub
```

Only after this path is correct should the repository add Gmail/Proton adapters, narration, TTS, local inference, or additional delivery surfaces.

<!-- © 2026 aiaiaiai · aiaiaiai.org -->
