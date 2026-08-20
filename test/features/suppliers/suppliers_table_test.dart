import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/suppliers/domain/entities/supplier.dart';
import 'package:purificadora/features/suppliers/presentation/widgets/suppliers_table.dart';

void main() {
  testWidgets('la tabla tiene barra horizontal visible en ventanas pequeñas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SuppliersTable(
            suppliers: const [
              Supplier(
                id: '1',
                branchName: 'Sucursal Centro',
                name: 'Envases del Noroeste',
                address: 'Av. Principal 100, Hermosillo, Sonora',
                phone: '6622345678',
              ),
            ],
            onEdit: (_) {},
            onDelete: (_) {},
            actionsEnabled: true,
          ),
        ),
      ),
    );

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, isTrue);
    expect(scrollbar.trackVisibility, isTrue);
    expect(tester.takeException(), isNull);
  });
}
