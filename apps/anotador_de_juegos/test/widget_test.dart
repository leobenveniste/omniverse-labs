import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anotador_de_juegos/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ScorekeeperApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScorekeeperApp());
    await tester.pumpAndSettle();
    expect(find.text('Anotador de Juegos'), findsOneWidget);
    expect(find.text('Truco'), findsOneWidget);
    expect(find.text('Generala'), findsOneWidget);
  });
}
