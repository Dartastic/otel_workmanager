# Changelog

## [1.0.0-wip]

### Changed

- Requires `dartastic_opentelemetry ^1.1.0-beta.17` and
  `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- First 1.0 release: the public API of this package is stable and
  follows semantic versioning from here on.

## [0.1.0] - 2026-08-10

### Added

- `tracedWorkmanagerRegister<R>(...)` — PRODUCER span around
  `registerOneOffTask` / `registerPeriodicTask` (called from the
  app's main isolate).
- `tracedWorkmanagerExecute<R>({taskName, inputData, body})` —
  CONSUMER span wrapping the user's task body inside
  `callbackDispatcher.executeTask`. Runs in the background
  isolate; requires `OTel.initialize()` to have been called
  inside that isolate.
- Zone-scoped suppression
  (`runWithoutWorkmanagerInstrumentation` / async variant).
- `WorkmanagerSemantics` enum for the `task.*` attribute keys
  (no registry background-task convention exists yet).
- `example/example.md` covering both isolates.
- 5 tests.

### Changed

- `workmanager` constraint widened to `>=0.6.0 <0.11.0`
  (supports the latest 0.10.x; no workmanager API is called
  directly).
