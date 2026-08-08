# otel_workmanager example

```dart
// example/lib/main.dart

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/material.dart';
import 'package:otel_workmanager/otel_workmanager.dart';
import 'package:workmanager/workmanager.dart';

/// Runs in a SEPARATE background isolate that shares no OTel state
/// with your main isolate: initialize OTel here too, or the traced
/// helper short-circuits (no errors, no spans).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    await OTel.initialize(serviceName: 'workmanager-demo-bg');

    // ✨ Span: `workmanager execute upload-pending-photos`
    //
    //    CONSUMER kind - this is the deferred work actually running.
    //    Carries task.system / task.operation / task.name and, when
    //    inputData is present, task.input_data.size (count only -
    //    the map's contents are never recorded).
    final ok = await tracedWorkmanagerExecute<bool>(
      taskName: taskName,
      inputData: inputData,
      body: () async {
        // ... upload the pending photos ...
        return true;
      },
    );

    await OTel.shutdown();
    return ok;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Bring up OTel in the main isolate.
  await OTel.initialize(serviceName: 'workmanager-demo');

  // 2. Initialize Workmanager with the background entry point.
  await Workmanager().initialize(callbackDispatcher);

  // 3. Wrap registrations so scheduling is traced.
  //
  // ✨ Span: `workmanager register_one_off sync-uploads`
  //
  //    PRODUCER kind - we're scheduling work to run later.
  await tracedWorkmanagerRegister<void>(
    operation: 'register_one_off',
    uniqueName: 'sync-uploads',
    taskName: 'upload-pending-photos',
    invoke: () => Workmanager().registerOneOffTask(
      'sync-uploads',
      'upload-pending-photos',
      inputData: {'quality': 'high'},
    ),
  );

  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('demo')))));
}
```

## Trace shape

```
(main isolate, at scheduling time)
workmanager register_one_off sync-uploads          PRODUCER
  task.system = workmanager
  task.operation = register_one_off
  task.name = sync-uploads
  task.kind = upload-pending-photos

(background isolate, when the OS runs the task - a separate trace,
because the background isolate has its own OTel state)
workmanager execute upload-pending-photos          CONSUMER
  task.system = workmanager
  task.operation = execute
  task.name = upload-pending-photos
  task.input_data.size = 1
```

## Turning it off

Wrap any call in `runWithoutWorkmanagerInstrumentationAsync` (or the
sync variant) to suppress spans for that zone:

```dart
await runWithoutWorkmanagerInstrumentationAsync(() async {
  await tracedWorkmanagerExecute<bool>(
    taskName: 'quiet',
    body: () async => true,
  );
});
// no spans emitted
```
