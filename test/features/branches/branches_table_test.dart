import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/branches/domain/entities/branch.dart';
import 'package:purificadora/features/branches/presentation/widgets/branches_table.dart';

void main() {
  testWidgets('la tabla mantiene una barra horizontal visible', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BranchesTable(
            branches: const [
              Branch(
                id: '1',
                name: 'Sucursal Centro',
                businessName: 'Purificadora Demo',
                address: 'Blvd. Hidalgo 100, Hermosillo, Sonora',
                latitude: 29.072967,
                longitude: -110.955919,
              ),
            ],
            onConfigureProducts: (_) {},
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
