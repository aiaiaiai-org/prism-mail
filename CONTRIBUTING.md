# Contributing

Keep changes narrowly scoped and preserve the boundaries in [`docs/architecture.md`](docs/architecture.md).

Before opening a pull request:

```bash
bundle install
bundle exec rubocop
bundle exec rake test
bundle exec rake check
```

Provider, transport, persistence, and AI-vendor dependencies belong behind focused ports. Do not introduce direct Telegram/Matrix delivery, provider switches in product policy, or ambient message retention as shortcuts.

Use a feature/fix branch from the latest `master`; do not commit directly to `master`.

<!-- © 2026 aiaiaiai · aiaiaiai.org -->
