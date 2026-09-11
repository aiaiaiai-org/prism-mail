# Status

## Implemented

- repository and Ruby package bootstrap;
- normative product/control-plane boundary;
- provider/client isolation check for future domain/application code;
- minimal CI for syntax, style, tests, and architecture checks.

## Next

1. Define canonical mail evidence and source-port contracts without provider vocabulary.
2. Implement the first read-only HQBase source adapter against its existing Mail API/MCP surface.
3. Define the product-facing AI analysis port and integrate it through `aiaiaiai-org/artificial-intelligence` rather than a vendor SDK in application code.
4. Produce a deterministic text digest artifact with fact/analysis provenance.
5. Define the Prism Hub service integration contract for configuration, scheduling, and delivery.
6. Add persistence only where a concrete recovery/audit requirement justifies retention.

## Later

- Gmail source adapter;
- Proton source adapter;
- additional remote inference providers;
- local inference adapter;
- narration projection and provider-neutral speech synthesis;
- voice-message delivery through Hub-supported clients;
- richer administration through the Prism Hub web interface.

## Explicitly not implemented

There is currently no live mail ingestion, AI call, scheduler, database, Prism Hub integration, Telegram/Matrix integration, speech synthesis, or production deployment. Documentation must not imply otherwise.

<!-- © 2026 aiaiaiai · aiaiaiai.org -->
