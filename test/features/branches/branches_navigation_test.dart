import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/screens/main_dashboard.dart';

void main() {
  testWidgets('la navegación móvil permite abrir Sucursales sin desbordarse', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MainDashboard()));
    expect(find.byType(NavigationBar), findsOneWidget);

    final branchDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Sucursales'),
    );
    await tester.ensureVisible(branchDestination);
    await tester.pumpAndSettle();
    await tester.tap(branchDestination);
    await tester.pumpAndSettle();

    expect(find.text('Gestión de Sucursales'), findsOneWidget);
    expect(find.text('Configura la conexión con Supabase'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la navegación lateral es desplazable en poca altura', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MainDashboard()));

    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
