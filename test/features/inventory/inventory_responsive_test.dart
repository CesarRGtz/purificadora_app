import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/inventory/domain/entities/inventory_entities.dart';
import 'package:purificadora/features/inventory/inventory_module.dart';
import 'package:purificadora/features/inventory/presentation/widgets/consume_product_dialog.dart';
import 'package:purificadora/features/inventory/presentation/widgets/finished_good_form_dialog.dart';
import 'package:purificadora/features/inventory/presentation/widgets/product_branches_dialog.dart';
import 'package:purificadora/features/inventory/presentation/widgets/product_materials_dialog.dart';
import 'package:purificadora/features/inventory/presentation/widgets/raw_material_form_dialog.dart';
import 'package:purificadora/features/inventory/presentation/widgets/raw_material_movement_dialog.dart';
import 'package:purificadora/features/inventory/presentation/widgets/raw_material_transfer_dialog.dart';
import 'package:purificadora/features/inventory/presentation/widgets/responsive_inventory_table.dart';

void main() {
  testWidgets('el modo local muestra las tres categorías de inventario', (
    tester,
  ) async {
    _setSmallSurface(tester);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: InventoryModule.buildPage())),
    );

    expect(find.text('Configura la conexión con Supabase'), findsOneWidget);
    await tester.tap(find.text('Probar sin conexión'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Modo local:'), findsOneWidget);
    expect(find.byKey(const ValueKey('inventory-tabs')), findsOneWidget);
    expect(_tabWithText('Producto Terminado'), findsOneWidget);
    expect(_tabWithText('Materia Prima'), findsOneWidget);
    expect(_tabWithText('Productos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la tabla conserva scroll horizontal visible en móvil', (
    tester,
  ) async {
    _setSmallSurface(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveInventoryTable(
            minWidth: 1250,
            columns: const [
              DataColumn(label: Text('Sucursal')),
              DataColumn(label: Text('Producto')),
              DataColumn(label: Text('Tipo')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Cantidad')),
              DataColumn(label: Text('Vendible')),
              DataColumn(label: Text('Asociado')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: const [
              DataRow(
                cells: [
                  DataCell(Text('Sucursal Norte')),
                  DataCell(Text('Garrafón 20 L')),
                  DataCell(Text('Retornable')),
                  DataCell(Text('Comprado')),
                  DataCell(Text('20')),
                  DataCell(Text('Sí')),
                  DataCell(Text('AGUA-20L')),
                  DataCell(Text('Editar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, isTrue);
    expect(scrollbar.trackVisibility, isTrue);
    expect(scrollbar.interactive, isTrue);

    final initialActionsX = tester.getTopLeft(find.text('Acciones')).dx;
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    final scrolledActionsX = tester.getTopLeft(find.text('Acciones')).dx;

    expect(scrolledActionsX, lessThan(initialActionsX));
    expect(tester.takeException(), isNull);
  });

  testWidgets('formularios de activos, insumos y movimientos no desbordan', (
    tester,
  ) async {
    _setSmallSurface(tester);

    await _pumpDialog(
      tester,
      const FinishedGoodFormDialog(branches: _branches, products: _products),
    );
    await _pumpDialog(tester, const RawMaterialFormDialog(branches: _branches));
    await _pumpDialog(
      tester,
      const RawMaterialMovementDialog(
        material: _rawMaterial,
        products: _products,
      ),
    );
  });

  testWidgets('diálogos de sucursales, receta y consumo no desbordan', (
    tester,
  ) async {
    _setSmallSurface(tester);

    await _pumpDialog(
      tester,
      const ProductBranchesDialog(product: _product, branches: _branches),
    );
    await _pumpDialog(
      tester,
      const ProductMaterialsDialog(
        product: _product,
        branches: _branches,
        rawMaterials: [_rawMaterial],
        requirements: [_requirement],
      ),
    );
    await _pumpDialog(
      tester,
      const ConsumeProductDialog(
        product: _product,
        branches: _branches,
        rawMaterials: [_rawMaterial],
        requirements: [_requirement],
      ),
    );
  });

  testWidgets('el traslado válido funciona sin desbordar en móvil', (
    tester,
  ) async {
    _setSmallSurface(tester);
    RawMaterialTransferRequest? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await RawMaterialTransferDialog.show(
                    context,
                    source: _rawMaterial,
                    rawMaterials: const [_rawMaterial, _destinationRawMaterial],
                    branches: _transferBranches,
                  );
                },
                child: const Text('Abrir traslado'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir traslado'));
    await tester.pumpAndSettle();

    expect(find.text('Trasladar materia prima'), findsOneWidget);
    expect(find.text('Sucursal Sur'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextFormField), '25');
    await tester.tap(find.text('Trasladar'));
    await tester.pumpAndSettle();

    expect(result?.destinationRawMaterialId, 'raw-caps-south');
    expect(result?.quantity, 25);
    expect(find.text('Trasladar materia prima'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Finder _tabWithText(String text) {
  return find.byWidgetPredicate(
    (widget) => widget is Tab && widget.text == text,
  );
}

void _setSmallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(420, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpDialog(WidgetTester tester, Widget dialog) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: dialog)),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

const _branches = [InventoryBranch(id: 'branch-north', name: 'Sucursal Norte')];

const _transferBranches = [
  InventoryBranch(id: 'branch-north', name: 'Sucursal Norte'),
  InventoryBranch(id: 'branch-south', name: 'Sucursal Sur'),
];

const _product = InventoryProduct(
  id: 'product-water',
  name: 'Garrafón de agua 20 L',
  sku: 'AGUA-20L',
  basePrice: 45,
  branchIds: {'branch-north'},
);

const _products = [_product];

const _rawMaterial = RawMaterial(
  id: 'raw-caps',
  branchId: 'branch-north',
  category: 'Empaque',
  name: 'Tapas de garrafón',
  unit: 'pzas',
  lastUnitCost: 0.5,
  purchased: 100,
);

const _destinationRawMaterial = RawMaterial(
  id: 'raw-caps-south',
  branchId: 'branch-south',
  category: 'Empaque',
  name: 'Tapas de garrafón',
  unit: 'pzas',
  lastUnitCost: 0.5,
);

const _requirement = ProductMaterialRequirement(
  id: 'recipe-caps',
  productId: 'product-water',
  rawMaterialId: 'raw-caps',
  quantityPerUnit: 2,
);
