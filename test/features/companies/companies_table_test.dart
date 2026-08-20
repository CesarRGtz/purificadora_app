import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/companies/domain/entities/company.dart';
import 'package:purificadora/features/companies/presentation/widgets/companies_table.dart';

void main() {
  testWidgets('la tabla y su encabezado ocupan todo el ancho disponible', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: CompaniesTable(
              companies: const [
                Company(
                  id: '1',
                  businessName: 'Empresa Demo',
                  rfc: 'EDE260819AB1',
                  address: 'Blvd. Principal 100, Hermosillo, Sonora',
                  phone: '6621234567',
                ),
              ],
              onEdit: (_) {},
              onDelete: (_) {},
              actionsEnabled: true,
            ),
          ),
        ),
      ),
    );

    final tableWidth = tester.getSize(find.byType(DataTable)).width;
    expect(tableWidth, greaterThan(1300));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'muestra una barra y permite desplazarse en una ventana pequeña',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompaniesTable(
              companies: const [
                Company(
                  id: '1',
                  businessName: 'Empresa Demo',
                  rfc: 'EDE260819AB1',
                  address: 'Blvd. Principal 100, Hermosillo, Sonora',
                  phone: '6621234567',
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

      final initialActionsX = tester.getTopLeft(find.text('Acciones')).dx;
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-350, 0),
      );
      await tester.pumpAndSettle();
      final scrolledActionsX = tester.getTopLeft(find.text('Acciones')).dx;

      expect(scrolledActionsX, lessThan(initialActionsX));
      expect(tester.takeException(), isNull);
    },
  );
}
