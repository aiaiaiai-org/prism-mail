# Status

## Implemented

- Ruby package and ports/adapters boundary with correctness CI;
- immutable, minimized mail evidence and validated half-open digest windows;
- read-only HQBase Mail API v1 adapter using inbox summaries and OAuth bearer access;
- cursor pagination with mailbox scope preservation, loop detection, response/page budgets;
- deterministic newest-first selection, duplicate detection, provenance and omission counts;
- `prism-mail.digest.v1` JSON output and a one-shot `prism-mail` executable;
- explicit authorization, rate-limit, transport, malformed-response and incomplete-scan errors;
- synthetic tests for source, transport, domain and executable behavior.

## Not yet verified live

The adapter is implemented against the pinned upstream OpenAPI contract. No real
account token was used during implementation and no production mail was read.
A live check requires the deployed HQBase origin, a `mail:read` OAuth access token
with the `/api/v1` audience, and an authorized mailbox ID.

## Next integration work

1. Connect the shared `artificial-intelligence` contract for analysis. Preserve the
   extractive mode as a distinct mode; never label excerpts as model analysis.
2. Have Prism Hub invoke the digest use case or executable, authorize the selected
   mailbox, own token lifecycle, and consume the versioned artifact.
3. Configure Hub scheduling and delivery and validate an end-to-end live run.
4. Add narration and additional sources after the text path is verified.

No AI calls, hosted API, scheduler, persistence, Hub delivery or production
activation are implemented by this slice. The CLI does not refresh OAuth tokens.

<!-- © 2026 aiaiaiai · aiaiaiai.org -->
