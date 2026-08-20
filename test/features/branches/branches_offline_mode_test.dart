import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/branches/branches_module.dart';

void main() {
  testWidgets('permite probar sucursales y productos sin Supabase', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: BranchesModule.buildPage())),
    );

    final offlineButton = find.text('Probar sin conexión');
    await tester.ensureVisible(offlineButton);
    await tester.pumpAndSettle();
    await tester.tap(offlineButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Modo local de prueba'), findsOneWidget);
    expect(find.text('Sucursal Centro'), findsOneWidget);
    expect(find.text('Gestionar productos'), findsOneWidget);
    expect(find.text('Configurar'), findsOneWidget);
  });
}
