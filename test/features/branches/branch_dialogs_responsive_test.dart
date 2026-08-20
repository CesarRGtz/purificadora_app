import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/branches/data/repositories/in_memory_branches_repository.dart';
import 'package:purificadora/features/branches/domain/entities/branch.dart';
import 'package:purificadora/features/branches/domain/entities/product.dart';
import 'package:purificadora/features/branches/domain/usecases/branch_use_cases.dart';
import 'package:purificadora/features/branches/domain/usecases/product_use_cases.dart';
import 'package:purificadora/features/branches/presentation/controllers/branches_controller.dart';
import 'package:purificadora/features/branches/presentation/widgets/branch_products_dialog.dart';
import 'package:purificadora/features/branches/presentation/widgets/product_management_dialog.dart';

void main() {
  late InMemoryBranchesRepository repository;
  late BranchesController controller;
  const branch = Branch(
    id: 'b1',
    name: 'Sucursal Centro',
    businessName: 'Negocio Demo',
    address: 'Calle Centro 100',
    latitude: 29.07,
    longitude: -110.95,
  );

  setUp(() {
    repository = InMemoryBranchesRepository(
      initialBranches: const [branch],
      initialProducts: const [
        Product(id: 'p1', name: 'Agua 20 L', sku: 'AGUA-20L', basePrice: 45),
      ],
      initialAssignments: const {
        'b1': {'p1'},
      },
    );
    controller = BranchesController(
      getBranches: GetBranches(repository),
      createBranch: CreateBranch(repository),
      updateBranch: UpdateBranch(repository),
      deleteBranch: DeleteBranch(repository),
      getProducts: GetProducts(repository),
      createProduct: CreateProduct(repository),
      updateProduct: UpdateProduct(repository),
      deleteProduct: DeleteProduct(repository),
      getBranchProductIds: GetBranchProductIds(repository),
      configureBranchProducts: ConfigureBranchProducts(repository),
    );
  });

  tearDown(() => controller.dispose());

  testWidgets('el catálogo de productos cabe en una ventana pequeña', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await controller.loadProducts();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProductManagementDialog(controller: controller)),
      ),
    );

    expect(find.text('Catálogo de productos'), findsOneWidget);
    expect(find.byTooltip('Acciones del producto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la selección por sucursal cabe en una ventana pequeña', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await controller.loadProductConfiguration(branch.id);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BranchProductsDialog(branch: branch, controller: controller),
        ),
      ),
    );

    expect(find.text('Productos de Sucursal Centro'), findsOneWidget);
    expect(find.text('Seleccionar todos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
