# Changelog

## [0.2.1-wip]

### Changed

- README: standard header naming the instrumented library, its supported platforms and project links; pubspec description to match.

## [0.2.0] - 2026-10-11

### Changed

- Requires `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- **Breaking:** depends on `dartastic_opentelemetry_api` only, no
  longer on the SDK. The application chooses and initializes the
  OpenTelemetry SDK. Parameters and fields typed with SDK classes
  now use the API types (`APITracer`, `APISpan`, `APILogger`, ...);
  SDK instances are still accepted wherever an API type is expected.

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
