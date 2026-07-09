import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lunar_stack/app/app.dart';

void main() {
  testWidgets('Home screen shows the two main actions', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: LunarStackApp()));
    await tester.pumpAndSettle();

    expect(find.text('LunarStack'), findsOneWidget);
    expect(find.text('Estabilizar vídeo'), findsOneWidget);
    expect(find.text('Empilhar imagem'), findsOneWidget);
  });
}
