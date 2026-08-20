import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/branches/data/repositories/in_memory_branches_repository.dart';
import 'package:purificadora/features/branches/domain/entities/branch.dart'
    as catalog;
import 'package:purificadora/features/branches/domain/entities/product.dart'
    as catalog;
import 'package:purificadora/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:purificadora/features/inventory/domain/entities/inventory_entities.dart';
import 'package:purificadora/features/inventory/domain/errors/inventory_exception.dart';
import 'package:purificadora/features/inventory/presentation/controllers/inventory_controller.dart';

void main() {
  test(
    'el controlador libera las acciones después de una operación fallida',
    () async {
      final repository = _inventoryRepository(_branchesRepository());
      final controller = InventoryController(repository);
      await controller.load();

      final failed = await controller.transferRawMaterial(
        'material-inexistente-origen',
        'material-inexistente-destino',
        1,
      );

      expect(failed, isFalse);
      expect(controller.isSubmitting, isFalse);
      expect(controller.operationError, isNotNull);

      final nextMutation = await controller.createFinishedGood(
        const FinishedGood(
          branchId: _branchNorthId,
          name: 'Activo posterior al error',
          type: 'Retornable',
          status: FinishedGoodStatus.purchased,
          quantity: 1,
          isSellable: true,
        ),
      );
      expect(nextMutation, isTrue);
      controller.dispose();
    },
  );

  test('completa CRUD y eliminado lógico de producto terminado', () async {
    final repository = _inventoryRepository(_branchesRepository());

    final created = await repository.createFinishedGood(
      const FinishedGood(
        branchId: _branchNorthId,
        productId: _waterProductId,
        name: 'Garrafón terminado',
        type: 'Retornable',
        status: FinishedGoodStatus.purchased,
        quantity: 20,
        isSellable: true,
      ),
    );
    expect(created.id, isNotEmpty);

    final updated = await repository.updateFinishedGood(
      FinishedGood(
        id: created.id,
        branchId: created.branchId,
        productId: created.productId,
        name: 'Garrafón en préstamo',
        type: created.type,
        status: FinishedGoodStatus.loaned,
        quantity: 4,
        isSellable: false,
      ),
    );
    expect(updated.status, FinishedGoodStatus.loaned);
    expect(updated.isSellable, isFalse);

    await repository.deleteFinishedGood(created.id);
    expect((await repository.getSnapshot()).finishedGoods, isEmpty);
    await expectLater(
      repository.updateFinishedGood(updated),
      throwsA(isA<InventoryException>()),
    );
  });

  test(
    'completa CRUD lógico de materia prima y elimina dependencias',
    () async {
      final repository = _inventoryRepository(_branchesRepository());
      final created = await repository.createRawMaterial(
        const RawMaterial(
          branchId: _branchNorthId,
          category: 'Empaque',
          name: 'Tapas',
          unit: 'pzas',
          lastUnitCost: 0.5,
        ),
      );
      final updated = await repository.updateRawMaterial(
        RawMaterial(
          id: created.id,
          branchId: created.branchId,
          category: 'Consumibles',
          name: 'Tapas reforzadas',
          unit: created.unit,
          lastUnitCost: 0.75,
        ),
      );
      expect(updated.category, 'Consumibles');

      await repository.registerRawMaterialMovement(
        RawMaterialMovement(
          rawMaterialId: created.id,
          type: RawMaterialMovementType.purchase,
          quantity: 100,
          unitCost: 0.75,
          createdAt: DateTime(2026, 8, 20),
        ),
      );
      await repository.configureProductMaterials(_waterProductId, {
        created.id: 1,
      });

      await repository.deleteRawMaterial(created.id);
      final snapshot = await repository.getSnapshot();
      expect(snapshot.rawMaterials, isEmpty);
      expect(snapshot.productMaterialRequirements, isEmpty);
    },
  );

  test('impide duplicar el mismo insumo y unidad por sucursal', () async {
    final repository = _inventoryRepository(_branchesRepository());
    await repository.createRawMaterial(
      const RawMaterial(
        branchId: _branchNorthId,
        category: 'Empaque',
        name: 'Tapas',
        unit: 'pzas',
        lastUnitCost: 0.5,
      ),
    );

    await expectLater(
      repository.createRawMaterial(
        const RawMaterial(
          branchId: _branchNorthId,
          category: 'Consumibles',
          name: ' tapas ',
          unit: 'PZAS',
          lastUnitCost: 0.6,
        ),
      ),
      throwsA(isA<InventoryException>()),
    );
  });

  test('conserva la edición manual del último costo con historial', () async {
    final repository = _inventoryRepository(_branchesRepository());
    final created = await repository.createRawMaterial(
      const RawMaterial(
        branchId: _branchNorthId,
        category: 'Empaque',
        name: 'Tapas',
        unit: 'pzas',
        lastUnitCost: 1,
      ),
    );
    await repository.registerRawMaterialMovement(
      RawMaterialMovement(
        rawMaterialId: created.id,
        type: RawMaterialMovementType.purchase,
        quantity: 10,
        unitCost: 2,
        createdAt: DateTime(2026, 8, 20),
      ),
    );

    await repository.updateRawMaterial(
      RawMaterial(
        id: created.id,
        branchId: created.branchId,
        category: created.category,
        name: created.name,
        unit: created.unit,
        lastUnitCost: 3.125,
      ),
    );

    final material = (await repository.getSnapshot()).rawMaterials.single;
    expect(material.lastUnitCost, 3.125);
    expect(material.totalValue, 31.25);
  });

  test('usa el mismo catálogo y asignaciones que Sucursales', () async {
    final branchesRepository = _branchesRepository(includeProducts: false);
    final repository = _inventoryRepository(branchesRepository);

    final created = await repository.createProduct(
      const InventoryProduct(
        name: 'Botella 1 L',
        sku: 'BOT-1L',
        description: 'Botella individual',
        basePrice: 15,
        branchIds: {_branchNorthId},
      ),
    );

    expect((await branchesRepository.getProducts()).single.id, created.id);
    expect(
      await branchesRepository.getBranchProductIds(_branchNorthId),
      contains(created.id),
    );

    final updated = await repository.updateProduct(
      InventoryProduct(
        id: created.id,
        name: 'Botella 1 litro',
        sku: created.sku,
        description: created.description,
        basePrice: 16,
        branchIds: const {_branchSouthId},
        createdAt: created.createdAt,
      ),
    );
    expect(updated.name, 'Botella 1 litro');
    expect(
      await branchesRepository.getBranchProductIds(_branchNorthId),
      isNot(contains(created.id)),
    );
    expect(
      await branchesRepository.getBranchProductIds(_branchSouthId),
      contains(created.id),
    );

    await repository.deleteProduct(created.id);
    expect(await branchesRepository.getProducts(), isEmpty);
    expect((await repository.getSnapshot()).products, isEmpty);
  });

  test('admite recetas muchos-a-muchos', () async {
    final repository = _inventoryRepository(
      _branchesRepository(includeSecondProduct: true),
      rawMaterials: const [
        RawMaterial(
          id: 'raw-caps',
          branchId: _branchNorthId,
          category: 'Empaque',
          name: 'Tapas',
          unit: 'pzas',
          lastUnitCost: 0.5,
        ),
        RawMaterial(
          id: 'raw-chlorine',
          branchId: _branchNorthId,
          category: 'Tratamiento',
          name: 'Cloro',
          unit: 'L',
          lastUnitCost: 15,
        ),
      ],
    );

    await repository.configureProductMaterials(_waterProductId, const {
      'raw-caps': 2,
      'raw-chlorine': 0.005,
    });
    await repository.configureProductMaterials(_iceProductId, const {
      'raw-caps': 1,
    });

    final requirements =
        (await repository.getSnapshot()).productMaterialRequirements;
    expect(requirements, hasLength(3));
    expect(
      requirements.where((item) => item.rawMaterialId == 'raw-caps'),
      hasLength(2),
    );
    expect(
      requirements.where((item) => item.productId == _waterProductId),
      hasLength(2),
    );
  });

  test(
    'consumir 10 unidades descuenta 20 y 0.05 sólo en la sucursal elegida',
    () async {
      final repository = _consumptionRepository(chlorineNorthStock: 1);

      await repository.consumeProduct(_waterProductId, _branchNorthId, 10);

      final materials = {
        for (final item in (await repository.getSnapshot()).rawMaterials)
          item.id: item,
      };
      expect(materials['caps-north']!.used, 20);
      expect(materials['chlorine-north']!.used, closeTo(0.05, 1e-12));
      expect(materials['caps-south']!.used, 0);
      expect(materials['chlorine-south']!.used, 0);
      expect(materials['caps-north']!.stock, 80);
      expect(materials['chlorine-north']!.stock, closeTo(0.95, 1e-12));
    },
  );

  test('existencia insuficiente revierte el consumo completo', () async {
    final repository = _consumptionRepository(chlorineNorthStock: 0.02);

    await expectLater(
      repository.consumeProduct(_waterProductId, _branchNorthId, 10),
      throwsA(isA<InventoryException>()),
    );

    final after = await repository.getSnapshot();
    expect(after.rawMaterials.singleWhere((m) => m.id == 'caps-north').used, 0);
    expect(
      after.rawMaterials.singleWhere((m) => m.id == 'chlorine-north').used,
      0,
    );
  });

  test('registra compras y usos manuales y recalcula existencias', () async {
    final repository = _inventoryRepository(
      _branchesRepository(),
      rawMaterials: const [
        RawMaterial(
          id: 'raw-caps',
          branchId: _branchNorthId,
          category: 'Empaque',
          name: 'Tapas',
          unit: 'pzas',
          lastUnitCost: 0,
        ),
      ],
      requirements: const [
        ProductMaterialRequirement(
          id: 'requirement-caps',
          productId: _waterProductId,
          rawMaterialId: 'raw-caps',
          quantityPerUnit: 1,
        ),
      ],
    );

    await expectLater(
      repository.registerRawMaterialMovement(
        const RawMaterialMovement(
          rawMaterialId: 'raw-caps',
          type: RawMaterialMovementType.purchase,
          quantity: 1,
        ),
      ),
      throwsA(isA<InventoryException>()),
    );

    final purchase = await repository.registerRawMaterialMovement(
      RawMaterialMovement(
        rawMaterialId: 'raw-caps',
        type: RawMaterialMovementType.purchase,
        quantity: 100,
        unitCost: 2,
        createdAt: DateTime(2026, 8, 20, 8),
      ),
    );
    await repository.registerRawMaterialMovement(
      RawMaterialMovement(
        rawMaterialId: 'raw-caps',
        type: RawMaterialMovementType.use,
        quantity: 5,
        productId: _waterProductId,
        createdAt: DateTime(2026, 8, 20, 9),
      ),
    );
    final snapshot = await repository.getSnapshot();
    final material = snapshot.rawMaterials.single;
    expect(purchase.id, isNotEmpty);
    expect(material.purchased, 100);
    expect(material.used, 5);
    expect(material.transferIn, 0);
    expect(material.transferOut, 0);
    expect(material.stock, 95);
    expect(material.lastUnitCost, 2);

    await repository.deleteRawMaterial('raw-caps');
    final deletedSnapshot = await repository.getSnapshot();
    expect(deletedSnapshot.rawMaterials, isEmpty);
    expect(deletedSnapshot.productMaterialRequirements, isEmpty);
  });

  test('traslada materia prima entre sucursales de forma atómica', () async {
    final repository = _transferRepository(sourceStock: 100);

    await repository.transferRawMaterial(
      'raw-caps-north',
      'raw-caps-south',
      25,
    );

    final snapshot = await repository.getSnapshot();
    final materials = {for (final item in snapshot.rawMaterials) item.id: item};
    final source = materials['raw-caps-north']!;
    final destination = materials['raw-caps-south']!;
    expect(source.purchased, 100);
    expect(source.transferOut, 25);
    expect(source.stock, 75);
    expect(destination.purchased, 0);
    expect(destination.transferIn, 25);
    expect(destination.stock, 25);
    expect(destination.lastUnitCost, 2);
    expect(destination.totalValue, 50);
  });

  test('traslado sin existencia suficiente no modifica ningún saldo', () async {
    final repository = _transferRepository(sourceStock: 5);

    await expectLater(
      repository.transferRawMaterial('raw-caps-north', 'raw-caps-south', 10),
      throwsA(isA<InventoryException>()),
    );

    final after = await repository.getSnapshot();
    final materials = {for (final item in after.rawMaterials) item.id: item};

    expect(materials['raw-caps-north']!.stock, 5);
    expect(materials['raw-caps-north']!.transferOut, 0);
    expect(materials['raw-caps-south']!.stock, 0);
    expect(materials['raw-caps-south']!.transferIn, 0);
  });
}

InMemoryBranchesRepository _branchesRepository({
  bool includeProducts = true,
  bool includeSecondProduct = false,
}) {
  final products = <catalog.Product>[
    if (includeProducts)
      const catalog.Product(
        id: _waterProductId,
        name: 'Garrafón de agua 20 L',
        sku: 'AGUA-20L',
        basePrice: 45,
      ),
    if (includeSecondProduct)
      const catalog.Product(
        id: _iceProductId,
        name: 'Bolsa de hielo',
        sku: 'HIELO-5KG',
        basePrice: 38,
      ),
  ];
  final assignedIds = {
    if (includeProducts) _waterProductId,
    if (includeSecondProduct) _iceProductId,
  };
  return InMemoryBranchesRepository(
    initialBranches: const [
      catalog.Branch(
        id: _branchNorthId,
        name: 'Sucursal Norte',
        businessName: 'Purificadora Demo',
        address: 'Blvd. Norte 100',
        latitude: 29.1,
        longitude: -110.9,
      ),
      catalog.Branch(
        id: _branchSouthId,
        name: 'Sucursal Sur',
        businessName: 'Purificadora Demo',
        address: 'Blvd. Sur 200',
        latitude: 29.0,
        longitude: -110.8,
      ),
    ],
    initialProducts: products,
    initialAssignments: {
      _branchNorthId: {...assignedIds},
      _branchSouthId: {if (includeProducts) _waterProductId},
    },
  );
}

InMemoryInventoryRepository _inventoryRepository(
  InMemoryBranchesRepository branchesRepository, {
  List<RawMaterial> rawMaterials = const [],
  List<RawMaterialMovement> movements = const [],
  List<ProductMaterialRequirement> requirements = const [],
}) {
  return InMemoryInventoryRepository(
    branchesRepository: branchesRepository,
    initialRawMaterials: rawMaterials,
    initialRawMaterialMovements: movements,
    initialProductMaterialRequirements: requirements,
  );
}

InMemoryInventoryRepository _consumptionRepository({
  required double chlorineNorthStock,
}) {
  return _inventoryRepository(
    _branchesRepository(),
    rawMaterials: const [
      RawMaterial(
        id: 'caps-north',
        branchId: _branchNorthId,
        category: 'Empaque',
        name: 'Tapas Norte',
        unit: 'pzas',
        lastUnitCost: 0.5,
      ),
      RawMaterial(
        id: 'chlorine-north',
        branchId: _branchNorthId,
        category: 'Tratamiento',
        name: 'Cloro Norte',
        unit: 'L',
        lastUnitCost: 15,
      ),
      RawMaterial(
        id: 'caps-south',
        branchId: _branchSouthId,
        category: 'Empaque',
        name: 'Tapas Sur',
        unit: 'pzas',
        lastUnitCost: 0.5,
      ),
      RawMaterial(
        id: 'chlorine-south',
        branchId: _branchSouthId,
        category: 'Tratamiento',
        name: 'Cloro Sur',
        unit: 'L',
        lastUnitCost: 15,
      ),
    ],
    movements: [
      const RawMaterialMovement(
        id: 'purchase-caps-north',
        rawMaterialId: 'caps-north',
        type: RawMaterialMovementType.purchase,
        quantity: 100,
      ),
      RawMaterialMovement(
        id: 'purchase-chlorine-north',
        rawMaterialId: 'chlorine-north',
        type: RawMaterialMovementType.purchase,
        quantity: chlorineNorthStock,
      ),
      const RawMaterialMovement(
        id: 'purchase-caps-south',
        rawMaterialId: 'caps-south',
        type: RawMaterialMovementType.purchase,
        quantity: 100,
      ),
      const RawMaterialMovement(
        id: 'purchase-chlorine-south',
        rawMaterialId: 'chlorine-south',
        type: RawMaterialMovementType.purchase,
        quantity: 1,
      ),
    ],
    requirements: const [
      ProductMaterialRequirement(
        id: 'recipe-caps-north',
        productId: _waterProductId,
        rawMaterialId: 'caps-north',
        quantityPerUnit: 2,
      ),
      ProductMaterialRequirement(
        id: 'recipe-chlorine-north',
        productId: _waterProductId,
        rawMaterialId: 'chlorine-north',
        quantityPerUnit: 0.005,
      ),
      ProductMaterialRequirement(
        id: 'recipe-caps-south',
        productId: _waterProductId,
        rawMaterialId: 'caps-south',
        quantityPerUnit: 2,
      ),
      ProductMaterialRequirement(
        id: 'recipe-chlorine-south',
        productId: _waterProductId,
        rawMaterialId: 'chlorine-south',
        quantityPerUnit: 0.005,
      ),
    ],
  );
}

InMemoryInventoryRepository _transferRepository({required double sourceStock}) {
  return _inventoryRepository(
    _branchesRepository(),
    rawMaterials: const [
      RawMaterial(
        id: 'raw-caps-north',
        branchId: _branchNorthId,
        category: 'Empaque',
        name: 'Tapas',
        unit: 'pzas',
        lastUnitCost: 2,
      ),
      RawMaterial(
        id: 'raw-caps-south',
        branchId: _branchSouthId,
        category: 'Empaque',
        name: 'Tapas',
        unit: 'pzas',
        lastUnitCost: 0,
      ),
    ],
    movements: [
      RawMaterialMovement(
        id: 'purchase-caps-north',
        rawMaterialId: 'raw-caps-north',
        type: RawMaterialMovementType.purchase,
        quantity: sourceStock,
        unitCost: 2,
      ),
    ],
  );
}

const _branchNorthId = 'branch-north';
const _branchSouthId = 'branch-south';
const _waterProductId = 'product-water';
const _iceProductId = 'product-ice';
