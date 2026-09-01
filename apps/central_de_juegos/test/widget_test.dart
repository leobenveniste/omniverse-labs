import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:central_de_juegos/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CentralDeJuegosApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CentralDeJuegosApp());
    await tester.pumpAndSettle();
    expect(find.text('Central de Juegos'), findsOneWidget);
    expect(find.text('30 Pts'), findsOneWidget);
    expect(find.text('10.000 Pts'), findsOneWidget);
    expect(find.text('3000 Pts'), findsOneWidget);
  });
}
