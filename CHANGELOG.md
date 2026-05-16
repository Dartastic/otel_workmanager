# Changelog

## [0.1.0-beta.1-wip]

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
- 4 tests.
