# Changelog

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
