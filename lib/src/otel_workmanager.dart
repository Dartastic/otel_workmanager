// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'workmanager_suppression.dart';

const _tracerName = 'otel_workmanager';
const _taskSystem = 'workmanager';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Generic helper for the registration-side spans (called from the
/// app's main isolate). PRODUCER kind because we're scheduling
/// background work to run later.
Future<R> tracedWorkmanagerRegister<R>({
  required String operation,
  required String uniqueName,
  String? taskName,
  required Future<R> Function() invoke,
}) async {
  if (workmanagerInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    'workmanager $operation $uniqueName',
    kind: SpanKind.producer,
    attributes: OTel.attributesFromMap(<String, Object>{
      'task.system': _taskSystem,
      'task.operation': operation,
      'task.name': uniqueName,
      if (taskName != null) 'task.kind': taskName,
    }),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps the user's task body inside `callbackDispatcher` /
/// `executeTask`. Runs in the background isolate.
///
/// **Important**: the background isolate has no OTel state of its
/// own. You MUST call `OTel.initialize()` inside your
/// `callbackDispatcher` before invoking this helper, otherwise
/// the span is dropped.
///
/// ```dart
/// @pragma('vm:entry-point')
/// void callbackDispatcher() {
///   Workmanager().executeTask((taskName, inputData) async {
///     await OTel.initialize(serviceName: 'my-app-bg');
///     return tracedWorkmanagerExecute(
///       taskName: taskName,
///       inputData: inputData,
///       body: () async {
///         // ... actual work
///         return true;
///       },
///     );
///   });
/// }
/// ```
Future<R> tracedWorkmanagerExecute<R>({
  required String taskName,
  Map<String, dynamic>? inputData,
  required Future<R> Function() body,
}) async {
  if (workmanagerInstrumentationSuppressed()) return body();
  final span = _tracer().startSpan(
    'workmanager execute $taskName',
    kind: SpanKind.consumer,
    attributes: OTel.attributesFromMap(<String, Object>{
      'task.system': _taskSystem,
      'task.operation': 'execute',
      'task.name': taskName,
      if (inputData != null) 'task.input_data.size': inputData.length,
    }),
  );
  try {
    return await body();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
