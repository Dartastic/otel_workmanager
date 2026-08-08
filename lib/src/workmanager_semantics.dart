// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

/// Background-task attribute keys used by this package's spans.
///
/// The OpenTelemetry semantic-conventions registry has no
/// background-job/task convention yet, so these are neutral
/// `task.*` keys kept in one place as an enum implementing
/// [OTelSemantic]. When the registry adds a convention, these can
/// `@Deprecated`-pivot to it.
enum WorkmanagerSemantics implements OTelSemantic {
  /// The scheduling system. Always `workmanager` here.
  taskSystem('task.system'),

  /// What was done: `register_one_off`, `register_periodic`,
  /// `cancel_by_unique_name`, `cancel_all`, `execute`, ...
  taskOperation('task.operation'),

  /// The task's unique name (registration side) or the `taskName`
  /// delivered to `executeTask` (execution side).
  taskName('task.name'),

  /// The optional Workmanager task-kind label passed at
  /// registration (`taskName` in `registerOneOffTask`).
  taskKind('task.kind'),

  /// Number of entries in the `inputData` map delivered to the
  /// task, when present. The map's contents are never recorded.
  taskInputDataSize('task.input_data.size');

  const WorkmanagerSemantics(this.key);

  @override
  final String key;

  @override
  String toString() => key;
}
