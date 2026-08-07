import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lunar_stack/app/theme.dart';
import 'package:lunar_stack/features/processing/presentation/processing_screen.dart';

void main() {
  testWidgets('render processing preview', (tester) async {
    tester.view.physicalSize = const Size(820, 1780);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLunarDarkTheme(),
      home: const RepaintBoundary(
        key: Key('shot'),
        child: ProcessingPreview(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));

    await expectLater(
      find.byKey(const Key('shot')),
      matchesGoldenFile('processing_preview.png'),
    );
  });
}
