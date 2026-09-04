import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutina_journal/main.dart';
import 'package:rutina_journal/services/app_services.dart';

void main() {
  testWidgets('RitmoApp smoke test and splash screen display', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (call) async {
      return null;
    });
    final services = await AppServices.init();

    await tester.pumpWidget(RitmoApp(services: services));
    await tester.pump();

    // Verify splash elements
    expect(find.text('RITMO'), findsOneWidget);
    expect(find.text('Hábitos, Rutinas & Diario'), findsOneWidget);

    // Pump past the 1800ms timer and 500ms transition without infinite settle on looping animations
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 600));

    // Verify main navigation loaded with tabs and elevated focus button
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'Hoy' || w.data == 'Today'),
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'Rutinas' || w.data == 'Routines'),
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'Diario' || w.data == 'Journal'),
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'Progreso' || w.data == 'Progress'),
      ),
      findsWidgets,
    );
    expect(find.byIcon(Icons.self_improvement_rounded), findsOneWidget);
  });
}
