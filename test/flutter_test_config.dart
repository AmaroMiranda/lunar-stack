import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carrega a Roboto real (do SDK) para os golden tests renderizarem tipografia
/// de verdade em vez dos "blocos" da fonte-placeholder de teste.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const base = r'C:/flutter/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final f in ['roboto-light.ttf', 'roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf']) {
    try {
      final bytes = File('$base/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    } catch (_) {}
  }
  await loader.load();
  await testMain();
}
