// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_workmanager/otel_workmanager.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('workmanager OTel', () {
    late _MemorySpanExporter exporter;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'workmanager-otel-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('register emits PRODUCER span', () async {
      await tracedWorkmanagerRegister<void>(
        operation: 'register_one_off',
        uniqueName: 'sync-uploads',
        taskName: 'upload-pending-photos',
        invoke: () async {},
      );

      final span = exporter.spans.single;
      expect(span.kind, equals(SpanKind.producer));
      expect(span.name, equals('workmanager register_one_off sync-uploads'));
      final attrs = _attrs(span);
      expect(attrs['task.system'], equals('workmanager'));
      expect(attrs['task.operation'], equals('register_one_off'));
      expect(attrs['task.name'], equals('sync-uploads'));
      expect(attrs['task.kind'], equals('upload-pending-photos'));
    });

    test('execute emits CONSUMER span', () async {
      final result = await tracedWorkmanagerExecute<bool>(
        taskName: 'upload-pending-photos',
        body: () async => true,
      );
      expect(result, isTrue);

      final span = exporter.spans.single;
      expect(span.kind, equals(SpanKind.consumer));
      expect(span.name, equals('workmanager execute upload-pending-photos'));
      final attrs = _attrs(span);
      expect(attrs['task.operation'], equals('execute'));
      expect(attrs['task.name'], equals('upload-pending-photos'));
    });

    test('exception flips span to Error', () async {
      await expectLater(
        tracedWorkmanagerExecute<bool>(
          taskName: 'broken',
          body: () async => throw StateError('out of disk'),
        ),
        throwsStateError,
      );
      expect(exporter.spans.single.status, equals(SpanStatusCode.Error));
    });

    test('runWithoutWorkmanagerInstrumentationAsync bypasses spans', () async {
      await runWithoutWorkmanagerInstrumentationAsync(() async {
        await tracedWorkmanagerExecute<bool>(
          taskName: 't',
          body: () async => true,
        );
      });
      expect(exporter.spans, isEmpty);
    });
  });
}
