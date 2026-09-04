import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutina_journal/main.dart';
import 'package:rutina_journal/services/app_services.dart';

void main() {
  testWidgets('RitmoApp smoke test and splash screen display', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final services = await AppServices.init();

    await tester.pumpWidget(RitmoApp(services: services));
    await tester.pump();

    // Verify splash elements
    expect(find.text('RITMO'), findsOneWidget);
    expect(find.text('Hábitos, Rutinas & Diario'), findsOneWidget);

    // Pump past the 1800ms timer
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Verify main navigation loaded with tabs and elevated focus button
    expect(find.text('Hoy'), findsWidgets);
    expect(find.text('Rutinas'), findsWidgets);
    expect(find.text('Diario'), findsWidgets);
    expect(find.text('Progreso'), findsWidgets);
    expect(find.byIcon(Icons.self_improvement_rounded), findsOneWidget);
  });
}
