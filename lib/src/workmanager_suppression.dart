// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #otel_workmanager_suppress;

/// Whether the current [Zone] has workmanager instrumentation
/// suppressed via [runWithoutWorkmanagerInstrumentation] or
/// [runWithoutWorkmanagerInstrumentationAsync].
bool workmanagerInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

/// Runs [body] with workmanager instrumentation suppressed: the
/// traced helpers invoke their callbacks directly and emit no spans.
T runWithoutWorkmanagerInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

/// Async variant of [runWithoutWorkmanagerInstrumentation]: the
/// suppression zone stays in effect across awaits inside [body].
Future<T> runWithoutWorkmanagerInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
