# otel_workmanager

OpenTelemetry instrumentation for
[`package:workmanager`](https://pub.dev/packages/workmanager).

```dart
// Registration side (main isolate)
await tracedWorkmanagerRegister<void>(
  operation: 'register_one_off',
  uniqueName: 'sync-uploads',
  taskName: 'upload-pending-photos',
  invoke: () => Workmanager().registerOneOffTask(
    'sync-uploads',
    'upload-pending-photos',
  ),
);

// Execution side (background isolate)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    await OTel.initialize(serviceName: 'my-app-bg');
    return tracedWorkmanagerExecute<bool>(
      taskName: taskName,
      inputData: inputData,
      body: () async {
        // ... actual work
        return true;
      },
    );
  });
}
```

Spans:
- `workmanager register_one_off <name>` — PRODUCER
- `workmanager register_periodic <name>` — PRODUCER
- `workmanager execute <name>` — CONSUMER

All carry `task.system=workmanager`, `task.operation`, `task.name`.

## Background-isolate gotcha

The `callbackDispatcher` runs in a separate background isolate
that does **not** share OTel state with your main isolate. You
must call `OTel.initialize()` inside the dispatcher before any
traced helper will emit anything. If you don't, the helpers
short-circuit (no errors, no spans).

Suppression: `runWithoutWorkmanagerInstrumentationAsync`.

## License

Apache 2.0
