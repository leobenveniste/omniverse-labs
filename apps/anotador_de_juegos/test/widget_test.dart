import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anotador_de_juegos/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CentralDeJuegosApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CentralDeJuegosApp());
    await tester.pumpAndSettle();
    expect(find.text('Central de Juegos'), findsOneWidget);
    expect(find.text('Truco'), findsOneWidget);
    expect(find.text('Generala'), findsOneWidget);
    expect(find.text('Escoba del 15'), findsOneWidget);
  });
}
