import '../../../branches/domain/entities/product.dart' as branch_catalog;
import '../../../branches/domain/errors/branches_exception.dart';
import '../../../branches/domain/repositories/branches_repository.dart';
import '../../../branches/domain/validation/product_validators.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/errors/inventory_exception.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/validation/inventory_validators.dart';

class InMemoryInventoryRepository implements InventoryRepository {
  InMemoryInventoryRepository({
    required BranchesRepository branchesRepository,
    List<FinishedGood> initialFinishedGoods = const [],
    List<RawMaterial> initialRawMaterials = const [],
    List<RawMaterialMovement> initialRawMaterialMovements = const [],
    List<ProductMaterialRequirement> initialProductMaterialRequirements =
        const [],
  }) : _branchesRepository = branchesRepository,
       _finishedGoods = [...initialFinishedGoods],
       _rawMaterials = [...initialRawMaterials],
       _rawMaterialMovements = [...initialRawMaterialMovements],
       _productMaterialRequirements = [...initialProductMaterialRequirements];

  final BranchesRepository _branchesRepository;
  final List<FinishedGood> _finishedGoods;
  final List<RawMaterial> _rawMaterials;
  final List<RawMaterialMovement> _rawMaterialMovements;
  final List<ProductMaterialRequirement> _productMaterialRequirements;

  int _idSequence = 0;

  @override
  Future<InventorySnapshot> getSnapshot() async {
    final catalog = await _loadCatalog();
    _synchronizeCatalogRelations(catalog);
    final activeBranchIds = catalog.branches.map((branch) => branch.id).toSet();
    final activeProductIds = catalog.products
        .map((product) => product.id)
        .toSet();

    final activeFinishedGoods =
        _finishedGoods
            .where(
              (item) =>
                  item.deletedAt == null &&
                  activeBranchIds.contains(item.branchId),
            )
            .map(_copyFinishedGood)
            .toList()
          ..sort(_sortFinishedGoods);

    final activeRawMaterialRecords = _rawMaterials
        .where(
          (material) =>
              material.deletedAt == null &&
              activeBranchIds.contains(material.branchId),
        )
        .toList();
    final activeRawMaterialIds = activeRawMaterialRecords
        .map((material) => material.id)
        .toSet();

    final activeMovements = _rawMaterialMovements.where(
      (movement) =>
          movement.deletedAt == null &&
          activeRawMaterialIds.contains(movement.rawMaterialId),
    );

    final activeRawMaterials =
        activeRawMaterialRecords
            .map(
              (material) => _withDerivedAggregates(
                material,
                activeMovements.where(
                  (movement) => movement.rawMaterialId == material.id,
                ),
              ),
            )
            .toList()
          ..sort(_sortRawMaterials);

    final activeRequirements =
        _productMaterialRequirements
            .where(
              (requirement) =>
                  requirement.deletedAt == null &&
                  activeProductIds.contains(requirement.productId) &&
                  activeRawMaterialIds.contains(requirement.rawMaterialId),
            )
            .map(_copyRequirement)
            .toList()
          ..sort(_sortRequirements);

    return InventorySnapshot(
      branches: List.unmodifiable(catalog.branches),
      products: List.unmodifiable(catalog.products),
      finishedGoods: List.unmodifiable(activeFinishedGoods),
      rawMaterials: List.unmodifiable(activeRawMaterials),
      productMaterialRequirements: List.unmodifiable(activeRequirements),
    );
  }

  @override
  Future<FinishedGood> createFinishedGood(FinishedGood finishedGood) async {
    final catalog = await _loadCatalog();
    _validateFinishedGood(finishedGood, catalog);
    final now = DateTime.now();
    final created = _copyFinishedGood(
      finishedGood,
      id: _nextId('finished-good'),
      createdAt: now,
      updatedAt: now,
      clearDeletedAt: true,
    );
    _finishedGoods.add(created);
    return _copyFinishedGood(created);
  }

  @override
  Future<FinishedGood> updateFinishedGood(FinishedGood finishedGood) async {
    final index = _activeFinishedGoodIndex(finishedGood.id);
    if (index == -1) {
      throw const InventoryException(
        'El activo que intentas editar no existe.',
      );
    }
    final catalog = await _loadCatalog();
    _validateFinishedGood(finishedGood, catalog);
    final updated = _copyFinishedGood(
      finishedGood,
      createdAt: _finishedGoods[index].createdAt,
      updatedAt: DateTime.now(),
      clearDeletedAt: true,
    );
    _finishedGoods[index] = updated;
    return _copyFinishedGood(updated);
  }

  @override
  Future<void> deleteFinishedGood(String id) async {
    final index = _activeFinishedGoodIndex(id);
    if (index == -1) {
      throw const InventoryException(
        'El activo que intentas eliminar no existe.',
      );
    }
    final now = DateTime.now();
    _finishedGoods[index] = _copyFinishedGood(
      _finishedGoods[index],
      updatedAt: now,
      deletedAt: now,
    );
  }

  @override
  Future<RawMaterial> createRawMaterial(RawMaterial rawMaterial) async {
    final catalog = await _loadCatalog();
    _validateRawMaterial(rawMaterial, catalog);
    _ensureUniqueRawMaterial(rawMaterial);
    final now = DateTime.now();
    final created = _copyRawMaterial(
      rawMaterial,
      id: _nextId('raw-material'),
      purchased: 0,
      used: 0,
      transferIn: 0,
      transferOut: 0,
      createdAt: now,
      updatedAt: now,
      clearDeletedAt: true,
    );
    _rawMaterials.add(created);
    return _copyRawMaterial(created);
  }

  @override
  Future<RawMaterial> updateRawMaterial(RawMaterial rawMaterial) async {
    final index = _activeRawMaterialIndex(rawMaterial.id);
    if (index == -1) {
      throw const InventoryException(
        'La materia prima que intentas editar no existe.',
      );
    }
    final current = _rawMaterials[index];
    if (current.branchId != rawMaterial.branchId &&
        _rawMaterialHasHistoryOrRequirements(current.id)) {
      throw const InventoryException(
        'No puedes cambiar la sucursal de un insumo con movimientos o recetas.',
      );
    }
    final catalog = await _loadCatalog();
    _validateRawMaterial(rawMaterial, catalog);
    _ensureUniqueRawMaterial(rawMaterial, ignoreId: rawMaterial.id);
    final updated = _copyRawMaterial(
      rawMaterial,
      purchased: 0,
      used: 0,
      transferIn: 0,
      transferOut: 0,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      clearDeletedAt: true,
    );
    _rawMaterials[index] = updated;
    return _withDerivedAggregates(updated, _activeMovementsFor(updated.id));
  }

  @override
  Future<void> deleteRawMaterial(String id) async {
    final index = _activeRawMaterialIndex(id);
    if (index == -1) {
      throw const InventoryException(
        'La materia prima que intentas eliminar no existe.',
      );
    }
    final now = DateTime.now();
    _rawMaterials[index] = _copyRawMaterial(
      _rawMaterials[index],
      updatedAt: now,
      deletedAt: now,
    );
    _softDeleteRequirements(now, rawMaterialId: id);
  }

  @override
  Future<InventoryProduct> createProduct(InventoryProduct product) async {
    final catalog = await _loadCatalog();
    _validateProduct(product, catalog, requireExisting: false);

    branch_catalog.Product created;
    try {
      created = await _branchesRepository.createProduct(
        _toBranchProduct(product),
      );
    } on BranchesException catch (error) {
      throw InventoryException(error.message);
    }

    try {
      await configureProductBranches(created.id, product.branchIds);
    } catch (_) {
      try {
        await _branchesRepository.deleteProduct(created.id);
      } catch (_) {
        // Best-effort rollback for repository implementations without transactions.
      }
      rethrow;
    }
    return _inventoryProductFrom(created, product.branchIds);
  }

  @override
  Future<InventoryProduct> updateProduct(InventoryProduct product) async {
    final catalog = await _loadCatalog();
    _validateProduct(product, catalog, requireExisting: true);

    branch_catalog.Product updated;
    try {
      updated = await _branchesRepository.updateProduct(
        _toBranchProduct(product),
      );
      await configureProductBranches(updated.id, product.branchIds);
    } on BranchesException catch (error) {
      throw InventoryException(error.message);
    }
    return _inventoryProductFrom(updated, product.branchIds);
  }

  @override
  Future<void> deleteProduct(String id) async {
    final catalog = await _loadCatalog();
    _requireProduct(catalog, id);
    try {
      await _branchesRepository.deleteProduct(id);
    } on BranchesException catch (error) {
      throw InventoryException(error.message);
    }
    final now = DateTime.now();
    _softDeleteRequirements(now, productId: id);
    for (var index = 0; index < _finishedGoods.length; index++) {
      final item = _finishedGoods[index];
      if (item.deletedAt == null && item.productId == id) {
        _finishedGoods[index] = _copyFinishedGood(
          item,
          updatedAt: now,
          clearProductId: true,
        );
      }
    }
  }

  @override
  Future<RawMaterialMovement> registerRawMaterialMovement(
    RawMaterialMovement movement,
  ) async {
    if (movement.type == RawMaterialMovementType.transferIn ||
        movement.type == RawMaterialMovementType.transferOut) {
      throw const InventoryException(
        'Usa el traslado entre sucursales para registrar ambas partes.',
      );
    }
    final rawIndex = _activeRawMaterialIndex(movement.rawMaterialId);
    if (rawIndex == -1) {
      throw const InventoryException(
        'La materia prima seleccionada no existe.',
      );
    }
    _validateInventoryQuantity(movement.quantity, 'La cantidad');
    if (movement.type == RawMaterialMovementType.purchase) {
      if (movement.unitCost == null) {
        throw const InventoryException(
          'Las compras deben indicar el costo unitario.',
        );
      }
      _validateUnitCost(movement.unitCost!, 'El costo unitario');
    } else if (movement.unitCost != null) {
      throw const InventoryException(
        'El costo unitario sólo se captura en las compras.',
      );
    }
    if (movement.type != RawMaterialMovementType.use &&
        (movement.productId?.trim().isNotEmpty ?? false)) {
      throw const InventoryException(
        'Sólo los movimientos de uso pueden asociarse a un producto.',
      );
    }

    final catalog = await _loadCatalog();
    final rawMaterial = _rawMaterials[rawIndex];
    _requireBranch(catalog, rawMaterial.branchId);

    if (movement.type == RawMaterialMovementType.use) {
      final productId = movement.productId?.trim() ?? '';
      if (productId.isEmpty) {
        throw const InventoryException(
          'Selecciona el producto que utilizó la materia prima.',
        );
      }
      final product = _requireProduct(catalog, productId);
      if (!product.branchIds.contains(rawMaterial.branchId)) {
        throw const InventoryException(
          'El producto no está disponible en la sucursal del insumo.',
        );
      }
      final hasRequirement = _productMaterialRequirements.any(
        (requirement) =>
            requirement.deletedAt == null &&
            requirement.productId == productId &&
            requirement.rawMaterialId == rawMaterial.id,
      );
      if (!hasRequirement) {
        throw const InventoryException(
          'El insumo no forma parte de la receta del producto.',
        );
      }
    }

    if (movement.type == RawMaterialMovementType.use) {
      final current = _withDerivedAggregates(
        rawMaterial,
        _activeMovementsFor(rawMaterial.id),
      );
      if (current.stock + _quantityTolerance < movement.quantity) {
        throw InventoryException(
          'Existencia insuficiente de ${rawMaterial.name}.',
        );
      }
    }

    final created = _copyMovement(
      movement,
      id: _nextId('raw-movement'),
      createdAt: movement.createdAt ?? DateTime.now(),
      clearDeletedAt: true,
    );
    _rawMaterialMovements.add(created);
    if (created.type == RawMaterialMovementType.purchase &&
        created.unitCost != null &&
        !_hasLaterInboundCost(created)) {
      _rawMaterials[rawIndex] = _copyRawMaterial(
        rawMaterial,
        lastUnitCost: created.unitCost,
        updatedAt: DateTime.now(),
      );
    }
    return _copyMovement(created);
  }

  @override
  Future<void> transferRawMaterial(
    String sourceRawMaterialId,
    String destinationRawMaterialId,
    double quantity,
  ) async {
    _validateInventoryQuantity(quantity, 'La cantidad del traslado');
    if (sourceRawMaterialId == destinationRawMaterialId) {
      throw const InventoryException(
        'Selecciona una materia prima de otra sucursal como destino.',
      );
    }
    final sourceIndex = _activeRawMaterialIndex(sourceRawMaterialId);
    final destinationIndex = _activeRawMaterialIndex(destinationRawMaterialId);
    if (sourceIndex == -1 || destinationIndex == -1) {
      throw const InventoryException(
        'La materia prima de origen o destino ya no está disponible.',
      );
    }

    final source = _rawMaterials[sourceIndex];
    final destination = _rawMaterials[destinationIndex];
    if (source.branchId == destination.branchId) {
      throw const InventoryException(
        'El traslado debe realizarse entre sucursales diferentes.',
      );
    }
    if (source.name.trim().toLowerCase() !=
            destination.name.trim().toLowerCase() ||
        source.unit.trim().toLowerCase() !=
            destination.unit.trim().toLowerCase()) {
      throw const InventoryException(
        'El insumo de destino debe tener el mismo nombre y unidad.',
      );
    }

    final catalog = await _loadCatalog();
    _requireBranch(catalog, source.branchId);
    _requireBranch(catalog, destination.branchId);
    final sourceWithStock = _withDerivedAggregates(
      source,
      _activeMovementsFor(source.id),
    );
    if (sourceWithStock.stock + _quantityTolerance < quantity) {
      throw InventoryException('Existencia insuficiente de ${source.name}.');
    }

    final now = DateTime.now();
    _rawMaterialMovements.addAll([
      RawMaterialMovement(
        id: _nextId('raw-transfer-out'),
        rawMaterialId: source.id,
        type: RawMaterialMovementType.transferOut,
        quantity: quantity,
        unitCost: sourceWithStock.lastUnitCost,
        createdAt: now,
      ),
      RawMaterialMovement(
        id: _nextId('raw-transfer-in'),
        rawMaterialId: destination.id,
        type: RawMaterialMovementType.transferIn,
        quantity: quantity,
        unitCost: sourceWithStock.lastUnitCost,
        createdAt: now,
      ),
    ]);
    _rawMaterials[destinationIndex] = _copyRawMaterial(
      destination,
      lastUnitCost: sourceWithStock.lastUnitCost,
      updatedAt: now,
    );
  }

  @override
  Future<void> configureProductBranches(
    String productId,
    Set<String> branchIds,
  ) async {
    final catalog = await _loadCatalog();
    _requireProduct(catalog, productId);
    final activeBranchIds = catalog.branches.map((branch) => branch.id).toSet();
    if (!activeBranchIds.containsAll(branchIds)) {
      throw const InventoryException(
        'Una de las sucursales seleccionadas ya no está disponible.',
      );
    }

    for (final branch in catalog.branches) {
      final currentIds = {...catalog.productIdsByBranch[branch.id] ?? const {}};
      if (branchIds.contains(branch.id)) {
        currentIds.add(productId);
      } else {
        currentIds.remove(productId);
      }
      try {
        await _branchesRepository.configureBranchProducts(
          branch.id,
          currentIds,
        );
      } on BranchesException catch (error) {
        throw InventoryException(error.message);
      }
    }

    final now = DateTime.now();
    for (var index = 0; index < _productMaterialRequirements.length; index++) {
      final requirement = _productMaterialRequirements[index];
      if (requirement.deletedAt != null || requirement.productId != productId) {
        continue;
      }
      final rawIndex = _activeRawMaterialIndex(requirement.rawMaterialId);
      if (rawIndex == -1 ||
          !branchIds.contains(_rawMaterials[rawIndex].branchId)) {
        _productMaterialRequirements[index] = _copyRequirement(
          requirement,
          updatedAt: now,
          deletedAt: now,
        );
      }
    }
    for (var index = 0; index < _finishedGoods.length; index++) {
      final item = _finishedGoods[index];
      if (item.deletedAt == null &&
          item.productId == productId &&
          !branchIds.contains(item.branchId)) {
        _finishedGoods[index] = _copyFinishedGood(
          item,
          updatedAt: now,
          clearProductId: true,
        );
      }
    }
  }

  @override
  Future<void> configureProductMaterials(
    String productId,
    Map<String, double> quantitiesByRawMaterialId,
  ) async {
    final catalog = await _loadCatalog();
    final product = _requireProduct(catalog, productId);

    for (final entry in quantitiesByRawMaterialId.entries) {
      final index = _activeRawMaterialIndex(entry.key);
      if (index == -1) {
        throw const InventoryException(
          'Una de las materias primas seleccionadas ya no está disponible.',
        );
      }
      _validateInventoryQuantity(entry.value, 'La cantidad por producto');
      if (!product.branchIds.contains(_rawMaterials[index].branchId)) {
        throw const InventoryException(
          'Cada insumo debe pertenecer a una sucursal asignada al producto.',
        );
      }
    }

    final now = DateTime.now();
    _softDeleteRequirements(now, productId: productId);
    for (final entry in quantitiesByRawMaterialId.entries) {
      _productMaterialRequirements.add(
        ProductMaterialRequirement(
          id: _nextId('product-material'),
          productId: productId,
          rawMaterialId: entry.key,
          quantityPerUnit: entry.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  @override
  Future<void> consumeProduct(
    String productId,
    String branchId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      throw const InventoryException(
        'La cantidad de productos debe ser mayor que cero.',
      );
    }

    final snapshot = await getSnapshot();
    final branchExists = snapshot.branches.any(
      (branch) => branch.id == branchId,
    );
    if (!branchExists) {
      throw const InventoryException('La sucursal seleccionada no existe.');
    }
    final product = snapshot.products
        .where((candidate) => candidate.id == productId)
        .firstOrNull;
    if (product == null) {
      throw const InventoryException('El producto seleccionado no existe.');
    }
    if (!product.branchIds.contains(branchId)) {
      throw const InventoryException(
        'El producto no está configurado para esta sucursal.',
      );
    }

    final rawById = {
      for (final material in snapshot.rawMaterials)
        if (material.branchId == branchId) material.id: material,
    };
    final requirements = snapshot.productMaterialRequirements
        .where(
          (requirement) =>
              requirement.productId == productId &&
              rawById.containsKey(requirement.rawMaterialId),
        )
        .toList();
    if (requirements.isEmpty) {
      throw const InventoryException(
        'El producto no tiene una receta configurada para esta sucursal.',
      );
    }

    final requiredQuantities = <String, double>{};
    for (final requirement in requirements) {
      final required = requirement.quantityPerUnit * quantity;
      _validateInventoryQuantity(required, 'La cantidad requerida');
      requiredQuantities.update(
        requirement.rawMaterialId,
        (current) => current + required,
        ifAbsent: () => required,
      );
    }

    for (final entry in requiredQuantities.entries) {
      final material = rawById[entry.key]!;
      if (material.stock + _quantityTolerance < entry.value) {
        throw InventoryException(
          'Existencia insuficiente de ${material.name}.',
        );
      }
    }

    final now = DateTime.now();
    final movements = requiredQuantities.entries.map(
      (entry) => RawMaterialMovement(
        id: _nextId('raw-movement'),
        rawMaterialId: entry.key,
        type: RawMaterialMovementType.use,
        quantity: entry.value,
        productId: productId,
        createdAt: now,
      ),
    );
    _rawMaterialMovements.addAll(movements);
  }

  Future<_InventoryCatalog> _loadCatalog() async {
    try {
      final branches = await _branchesRepository.getBranches();
      final products = await _branchesRepository.getProducts();
      final assignmentEntries = await Future.wait(
        branches.map((branch) async {
          final productIds = await _branchesRepository.getBranchProductIds(
            branch.id,
          );
          return MapEntry(branch.id, productIds);
        }),
      );
      final productIdsByBranch = Map<String, Set<String>>.fromEntries(
        assignmentEntries,
      );
      final branchIdsByProduct = <String, Set<String>>{};
      for (final entry in productIdsByBranch.entries) {
        for (final productId in entry.value) {
          branchIdsByProduct
              .putIfAbsent(productId, () => <String>{})
              .add(entry.key);
        }
      }

      final inventoryBranches =
          branches
              .where((branch) => branch.deletedAt == null)
              .map(
                (branch) => InventoryBranch(id: branch.id, name: branch.name),
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      final inventoryProducts =
          products
              .where((product) => product.deletedAt == null)
              .map(
                (product) => _inventoryProductFrom(
                  product,
                  branchIdsByProduct[product.id] ?? const {},
                ),
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      return _InventoryCatalog(
        branches: inventoryBranches,
        products: inventoryProducts,
        productIdsByBranch: productIdsByBranch,
      );
    } on BranchesException catch (error) {
      throw InventoryException(error.message);
    }
  }

  void _synchronizeCatalogRelations(_InventoryCatalog catalog) {
    final productsById = {
      for (final product in catalog.products) product.id: product,
    };
    final now = DateTime.now();

    for (var index = 0; index < _finishedGoods.length; index++) {
      final item = _finishedGoods[index];
      final productId = item.productId;
      if (item.deletedAt != null || productId == null) continue;
      final product = productsById[productId];
      if (product == null || !product.branchIds.contains(item.branchId)) {
        _finishedGoods[index] = _copyFinishedGood(
          item,
          updatedAt: now,
          clearProductId: true,
        );
      }
    }

    for (var index = 0; index < _productMaterialRequirements.length; index++) {
      final requirement = _productMaterialRequirements[index];
      if (requirement.deletedAt != null) continue;
      final rawIndex = _activeRawMaterialIndex(requirement.rawMaterialId);
      final product = productsById[requirement.productId];
      if (rawIndex == -1 ||
          product == null ||
          !product.branchIds.contains(_rawMaterials[rawIndex].branchId)) {
        _productMaterialRequirements[index] = _copyRequirement(
          requirement,
          updatedAt: now,
          deletedAt: now,
        );
      }
    }
  }

  void _validateFinishedGood(
    FinishedGood finishedGood,
    _InventoryCatalog catalog,
  ) {
    final error =
        InventoryValidators.branchId(finishedGood.branchId) ??
        InventoryValidators.name(finishedGood.name) ??
        InventoryValidators.type(finishedGood.type) ??
        InventoryValidators.nonNegativeInteger(
          finishedGood.quantity.toString(),
        );
    if (error != null) throw InventoryException(error);
    _requireBranch(catalog, finishedGood.branchId);

    final productId = finishedGood.productId?.trim();
    if (productId != null && productId.isNotEmpty) {
      final product = _requireProduct(catalog, productId);
      if (!product.branchIds.contains(finishedGood.branchId)) {
        throw const InventoryException(
          'El producto no está disponible en la sucursal seleccionada.',
        );
      }
    }
  }

  void _validateRawMaterial(
    RawMaterial rawMaterial,
    _InventoryCatalog catalog,
  ) {
    final error =
        InventoryValidators.branchId(rawMaterial.branchId) ??
        InventoryValidators.category(rawMaterial.category) ??
        InventoryValidators.name(rawMaterial.name) ??
        InventoryValidators.unit(rawMaterial.unit);
    if (error != null) throw InventoryException(error);
    _validateUnitCost(rawMaterial.lastUnitCost, 'El último costo');
    _validateNonNegativeNumber(rawMaterial.purchased, 'La cantidad comprada');
    _validateNonNegativeNumber(rawMaterial.used, 'La cantidad usada');
    _validateNonNegativeNumber(
      rawMaterial.transferIn,
      'La transferencia de entrada',
    );
    _validateNonNegativeNumber(
      rawMaterial.transferOut,
      'La transferencia de salida',
    );
    _requireBranch(catalog, rawMaterial.branchId);
  }

  void _ensureUniqueRawMaterial(RawMaterial rawMaterial, {String? ignoreId}) {
    final normalizedName = rawMaterial.name.trim().toLowerCase();
    final normalizedUnit = rawMaterial.unit.trim().toLowerCase();
    final duplicated = _rawMaterials.any(
      (current) =>
          current.deletedAt == null &&
          current.id != ignoreId &&
          current.branchId == rawMaterial.branchId &&
          current.name.trim().toLowerCase() == normalizedName &&
          current.unit.trim().toLowerCase() == normalizedUnit,
    );
    if (duplicated) {
      throw const InventoryException(
        'Ya existe esa materia prima con la misma unidad en la sucursal.',
      );
    }
  }

  void _validateProduct(
    InventoryProduct product,
    _InventoryCatalog catalog, {
    required bool requireExisting,
  }) {
    final error =
        ProductValidators.name(product.name) ??
        ProductValidators.sku(product.sku) ??
        ProductValidators.description(product.description) ??
        ProductValidators.basePrice(product.basePrice.toString());
    if (error != null) throw InventoryException(error);
    final activeBranchIds = catalog.branches.map((branch) => branch.id).toSet();
    if (!activeBranchIds.containsAll(product.branchIds)) {
      throw const InventoryException(
        'Una de las sucursales seleccionadas ya no está disponible.',
      );
    }
    if (requireExisting) _requireProduct(catalog, product.id);
  }

  InventoryBranch _requireBranch(_InventoryCatalog catalog, String id) {
    for (final branch in catalog.branches) {
      if (branch.id == id) return branch;
    }
    throw const InventoryException('La sucursal seleccionada no existe.');
  }

  InventoryProduct _requireProduct(_InventoryCatalog catalog, String id) {
    for (final product in catalog.products) {
      if (product.id == id) return product;
    }
    throw const InventoryException('El producto seleccionado no existe.');
  }

  void _validateNonNegativeNumber(double value, String label) {
    if (!InventoryValidators.isNonNegativeFinite(value)) {
      throw InventoryException('$label debe ser válido y no negativo.');
    }
  }

  void _validateInventoryQuantity(double value, String label) {
    if (!InventoryValidators.fitsInventoryQuantity(value)) {
      throw InventoryException(
        '$label admite hasta 3 decimales y debe estar dentro del rango permitido.',
      );
    }
  }

  void _validateUnitCost(double value, String label) {
    if (!InventoryValidators.fitsUnitCost(value)) {
      throw InventoryException(
        '$label admite hasta 4 decimales y debe estar dentro del rango permitido.',
      );
    }
  }

  RawMaterial _withDerivedAggregates(
    RawMaterial material,
    Iterable<RawMaterialMovement> movements,
  ) {
    var purchased = 0.0;
    var used = 0.0;
    var transferIn = 0.0;
    var transferOut = 0.0;
    for (final movement in movements) {
      switch (movement.type) {
        case RawMaterialMovementType.purchase:
          purchased += movement.quantity;
        case RawMaterialMovementType.use:
          used += movement.quantity;
        case RawMaterialMovementType.transferIn:
          transferIn += movement.quantity;
        case RawMaterialMovementType.transferOut:
          transferOut += movement.quantity;
      }
    }
    return _copyRawMaterial(
      material,
      purchased: purchased,
      used: used,
      transferIn: transferIn,
      transferOut: transferOut,
    );
  }

  bool _hasLaterInboundCost(RawMaterialMovement movement) {
    final occurredAt = movement.createdAt ?? _epoch;
    return _activeMovementsFor(movement.rawMaterialId).any(
      (other) =>
          other.id != movement.id &&
          other.unitCost != null &&
          (other.type == RawMaterialMovementType.purchase ||
              other.type == RawMaterialMovementType.transferIn) &&
          (other.createdAt ?? _epoch).isAfter(occurredAt),
    );
  }

  Iterable<RawMaterialMovement> _activeMovementsFor(String rawMaterialId) =>
      _rawMaterialMovements.where(
        (movement) =>
            movement.rawMaterialId == rawMaterialId &&
            movement.deletedAt == null,
      );

  bool _rawMaterialHasHistoryOrRequirements(String id) {
    return _activeMovementsFor(id).isNotEmpty ||
        _productMaterialRequirements.any(
          (requirement) =>
              requirement.rawMaterialId == id && requirement.deletedAt == null,
        );
  }

  void _softDeleteRequirements(
    DateTime deletedAt, {
    String? productId,
    String? rawMaterialId,
  }) {
    for (var index = 0; index < _productMaterialRequirements.length; index++) {
      final requirement = _productMaterialRequirements[index];
      final matchesProduct =
          productId == null || requirement.productId == productId;
      final matchesRawMaterial =
          rawMaterialId == null || requirement.rawMaterialId == rawMaterialId;
      if (requirement.deletedAt == null &&
          matchesProduct &&
          matchesRawMaterial) {
        _productMaterialRequirements[index] = _copyRequirement(
          requirement,
          updatedAt: deletedAt,
          deletedAt: deletedAt,
        );
      }
    }
  }

  int _activeFinishedGoodIndex(String id) => _finishedGoods.indexWhere(
    (item) => item.id == id && item.deletedAt == null,
  );

  int _activeRawMaterialIndex(String id) => _rawMaterials.indexWhere(
    (material) => material.id == id && material.deletedAt == null,
  );

  String _nextId(String prefix) {
    _idSequence++;
    return 'local-$prefix-${DateTime.now().microsecondsSinceEpoch}-$_idSequence';
  }

  FinishedGood _copyFinishedGood(
    FinishedGood item, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool clearProductId = false,
  }) {
    final normalizedProductId = clearProductId ? null : item.productId?.trim();
    return FinishedGood(
      id: id ?? item.id,
      branchId: item.branchId.trim(),
      productId: normalizedProductId == null || normalizedProductId.isEmpty
          ? null
          : normalizedProductId,
      name: item.name.trim(),
      type: item.type.trim(),
      status: item.status,
      quantity: item.quantity,
      isSellable: item.isSellable,
      createdAt: createdAt ?? item.createdAt,
      updatedAt: updatedAt ?? item.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? item.deletedAt),
    );
  }

  RawMaterial _copyRawMaterial(
    RawMaterial material, {
    String? id,
    double? lastUnitCost,
    double? purchased,
    double? used,
    double? transferIn,
    double? transferOut,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return RawMaterial(
      id: id ?? material.id,
      branchId: material.branchId.trim(),
      category: material.category.trim(),
      name: material.name.trim(),
      unit: material.unit.trim(),
      lastUnitCost: lastUnitCost ?? material.lastUnitCost,
      purchased: purchased ?? material.purchased,
      used: used ?? material.used,
      transferIn: transferIn ?? material.transferIn,
      transferOut: transferOut ?? material.transferOut,
      createdAt: createdAt ?? material.createdAt,
      updatedAt: updatedAt ?? material.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? material.deletedAt),
    );
  }

  RawMaterialMovement _copyMovement(
    RawMaterialMovement movement, {
    String? id,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    final normalizedProductId = movement.productId?.trim();
    return RawMaterialMovement(
      id: id ?? movement.id,
      rawMaterialId: movement.rawMaterialId.trim(),
      type: movement.type,
      quantity: movement.quantity,
      unitCost: movement.unitCost,
      productId: normalizedProductId == null || normalizedProductId.isEmpty
          ? null
          : normalizedProductId,
      createdAt: createdAt ?? movement.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? movement.deletedAt),
    );
  }

  ProductMaterialRequirement _copyRequirement(
    ProductMaterialRequirement requirement, {
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ProductMaterialRequirement(
      id: requirement.id,
      productId: requirement.productId,
      rawMaterialId: requirement.rawMaterialId,
      quantityPerUnit: requirement.quantityPerUnit,
      createdAt: requirement.createdAt,
      updatedAt: updatedAt ?? requirement.updatedAt,
      deletedAt: deletedAt ?? requirement.deletedAt,
    );
  }

  branch_catalog.Product _toBranchProduct(InventoryProduct product) {
    return branch_catalog.Product(
      id: product.id,
      name: product.name.trim(),
      sku: ProductValidators.normalizeSku(product.sku),
      description: product.description.trim(),
      basePrice: product.basePrice,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      deletedAt: product.deletedAt,
    );
  }

  InventoryProduct _inventoryProductFrom(
    branch_catalog.Product product,
    Set<String> branchIds,
  ) {
    return InventoryProduct(
      id: product.id,
      name: product.name,
      sku: product.sku,
      description: product.description,
      basePrice: product.basePrice,
      branchIds: Set.unmodifiable(branchIds),
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      deletedAt: product.deletedAt,
    );
  }

  static int _sortFinishedGoods(FinishedGood a, FinishedGood b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  static int _sortRawMaterials(RawMaterial a, RawMaterial b) {
    final branchComparison = a.branchId.compareTo(b.branchId);
    if (branchComparison != 0) return branchComparison;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  static int _sortRequirements(
    ProductMaterialRequirement a,
    ProductMaterialRequirement b,
  ) {
    final productComparison = a.productId.compareTo(b.productId);
    if (productComparison != 0) return productComparison;
    return a.rawMaterialId.compareTo(b.rawMaterialId);
  }

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);
  static const double _quantityTolerance = 0.000000001;
}

class _InventoryCatalog {
  const _InventoryCatalog({
    required this.branches,
    required this.products,
    required this.productIdsByBranch,
  });

  final List<InventoryBranch> branches;
  final List<InventoryProduct> products;
  final Map<String, Set<String>> productIdsByBranch;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
