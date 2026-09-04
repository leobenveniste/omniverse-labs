import 'package:flutter/material.dart';
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
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data == 'CENTRAL_DE_JUEGOS' || widget.data == 'GAME_NIGHT_HUB'),
      ),
      findsOneWidget,
    );
  });
}
