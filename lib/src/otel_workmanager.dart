// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'workmanager_semantics.dart';
import 'workmanager_suppression.dart';

const _tracerName = 'otel_workmanager';
const _taskSystem = 'workmanager';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

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
    attributes: OTelAPI.attributesFromMap(<String, Object>{
      WorkmanagerSemantics.taskSystem.key: _taskSystem,
      WorkmanagerSemantics.taskOperation.key: operation,
      WorkmanagerSemantics.taskName.key: uniqueName,
      if (taskName != null) WorkmanagerSemantics.taskKind.key: taskName,
    }),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
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
    attributes: OTelAPI.attributesFromMap(<String, Object>{
      WorkmanagerSemantics.taskSystem.key: _taskSystem,
      WorkmanagerSemantics.taskOperation.key: 'execute',
      WorkmanagerSemantics.taskName.key: taskName,
      if (inputData != null)
        WorkmanagerSemantics.taskInputDataSize.key: inputData.length,
    }),
  );
  try {
    return await body();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
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
