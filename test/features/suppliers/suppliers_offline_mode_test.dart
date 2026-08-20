import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/suppliers/suppliers_module.dart';

void main() {
  testWidgets('permite probar proveedores sin configurar Supabase', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SuppliersModule.buildPage())),
    );

    expect(find.text('Configura la conexión con Supabase'), findsOneWidget);
    final offlineButton = find.text('Probar sin conexión');
    await tester.ensureVisible(offlineButton);
    await tester.pumpAndSettle();
    await tester.tap(offlineButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Modo local de prueba'), findsOneWidget);
    expect(find.text('Envases del Noroeste'), findsOneWidget);
  });
}
