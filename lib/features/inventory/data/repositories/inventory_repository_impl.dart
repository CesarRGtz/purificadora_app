import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../branches/domain/entities/branch.dart' as branches_domain;
import '../../../branches/domain/entities/product.dart' as branches_domain;
import '../../../branches/domain/errors/branches_exception.dart';
import '../../../branches/domain/repositories/branches_repository.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/errors/inventory_exception.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_data_source.dart';
import '../models/inventory_models.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(
    this._remoteDataSource,
    this._branchesRepository,
  );

  final InventoryRemoteDataSource _remoteDataSource;
  final BranchesRepository _branchesRepository;

  @override
  Future<InventorySnapshot> getSnapshot() => _guard(() async {
    final loaded = await Future.wait<Object>([
      _branchesRepository.getBranches(),
      _branchesRepository.getProducts(),
      _remoteDataSource.getFinishedGoods(),
      _remoteDataSource.getRawMaterials(),
      _remoteDataSource.getProductMaterialRequirements(),
      _remoteDataSource.getProductBranchAssignments(),
    ]);

    final branches = loaded[0] as List<branches_domain.Branch>;
    final products = loaded[1] as List<branches_domain.Product>;
    final finishedGoods = loaded[2] as List<FinishedGoodModel>;
    final rawMaterials = loaded[3] as List<RawMaterialModel>;
    final requirements = loaded[4] as List<ProductMaterialRequirementModel>;
    final assignments = loaded[5] as List<ProductBranchAssignmentModel>;

    final branchIdsByProduct = <String, Set<String>>{};
    for (final assignment in assignments) {
      branchIdsByProduct
          .putIfAbsent(assignment.productId, () => <String>{})
          .add(assignment.branchId);
    }

    return InventorySnapshot(
      branches: branches
          .map((branch) => InventoryBranch(id: branch.id, name: branch.name))
          .toList(growable: false),
      products: products
          .map(
            (product) => _toInventoryProduct(
              product,
              branchIdsByProduct[product.id] ?? const <String>{},
            ),
          )
          .toList(growable: false),
      finishedGoods: finishedGoods,
      rawMaterials: rawMaterials,
      productMaterialRequirements: requirements,
    );
  }, 'No fue posible cargar el inventario.');

  @override
  Future<FinishedGood> createFinishedGood(FinishedGood finishedGood) => _guard(
    () => _remoteDataSource.createFinishedGood(finishedGood),
    'No fue posible registrar el activo.',
  );

  @override
  Future<FinishedGood> updateFinishedGood(FinishedGood finishedGood) => _guard(
    () => _remoteDataSource.updateFinishedGood(finishedGood),
    'No fue posible actualizar el activo.',
  );

  @override
  Future<void> deleteFinishedGood(String id) => _guard(
    () => _remoteDataSource.deleteFinishedGood(id),
    'No fue posible eliminar el activo.',
  );

  @override
  Future<RawMaterial> createRawMaterial(RawMaterial rawMaterial) => _guard(
    () => _remoteDataSource.createRawMaterial(rawMaterial),
    'No fue posible registrar la materia prima.',
  );

  @override
  Future<RawMaterial> updateRawMaterial(RawMaterial rawMaterial) => _guard(
    () => _remoteDataSource.updateRawMaterial(rawMaterial),
    'No fue posible actualizar la materia prima.',
  );

  @override
  Future<void> deleteRawMaterial(String id) => _guard(
    () => _remoteDataSource.deleteRawMaterial(id),
    'No fue posible eliminar la materia prima.',
  );

  @override
  Future<InventoryProduct> createProduct(InventoryProduct product) =>
      _guard(() async {
        final created = await _branchesRepository.createProduct(
          _toBranchesProduct(product),
        );
        if (product.branchIds.isNotEmpty) {
          try {
            await _remoteDataSource.configureProductBranches(
              created.id,
              product.branchIds,
            );
          } catch (_) {
            try {
              await _branchesRepository.deleteProduct(created.id);
            } catch (_) {
              // Rollback de mejor esfuerzo si la conexión también falla.
            }
            rethrow;
          }
        }
        return _toInventoryProduct(created, product.branchIds);
      }, 'No fue posible registrar el producto.');

  @override
  Future<InventoryProduct> updateProduct(InventoryProduct product) =>
      _guard(() async {
        final updated = await _branchesRepository.updateProduct(
          _toBranchesProduct(product),
        );
        await _remoteDataSource.configureProductBranches(
          updated.id,
          product.branchIds,
        );
        return _toInventoryProduct(updated, product.branchIds);
      }, 'No fue posible actualizar el producto.');

  @override
  Future<void> deleteProduct(String id) => _guard(
    () => _branchesRepository.deleteProduct(id),
    'No fue posible eliminar el producto.',
  );

  @override
  Future<RawMaterialMovement> registerRawMaterialMovement(
    RawMaterialMovement movement,
  ) => _guard(
    () => _remoteDataSource.registerRawMaterialMovement(movement),
    'No fue posible registrar el movimiento.',
  );

  @override
  Future<void> transferRawMaterial(
    String sourceRawMaterialId,
    String destinationRawMaterialId,
    double quantity,
  ) => _guard(
    () => _remoteDataSource.transferRawMaterial(
      sourceRawMaterialId,
      destinationRawMaterialId,
      quantity,
    ),
    'No fue posible completar el traslado.',
  );

  @override
  Future<void> configureProductBranches(
    String productId,
    Set<String> branchIds,
  ) => _guard(
    () => _remoteDataSource.configureProductBranches(productId, branchIds),
    'No fue posible guardar las sucursales del producto.',
  );

  @override
  Future<void> configureProductMaterials(
    String productId,
    Map<String, double> quantitiesByRawMaterialId,
  ) => _guard(
    () => _remoteDataSource.configureProductMaterials(
      productId,
      quantitiesByRawMaterialId,
    ),
    'No fue posible guardar la receta del producto.',
  );

  @override
  Future<void> consumeProduct(
    String productId,
    String branchId,
    int quantity,
  ) => _guard(
    () => _remoteDataSource.consumeProduct(productId, branchId, quantity),
    'No fue posible descontar las materias primas.',
  );

  branches_domain.Product _toBranchesProduct(InventoryProduct product) {
    return branches_domain.Product(
      id: product.id,
      name: product.name,
      sku: product.sku,
      description: product.description,
      basePrice: product.basePrice,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      deletedAt: product.deletedAt,
    );
  }

  InventoryProduct _toInventoryProduct(
    branches_domain.Product product,
    Set<String> branchIds,
  ) {
    return InventoryProduct(
      id: product.id,
      name: product.name,
      sku: product.sku,
      description: product.description,
      basePrice: product.basePrice,
      branchIds: Set<String>.unmodifiable(branchIds),
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      deletedAt: product.deletedAt,
    );
  }

  Future<T> _guard<T>(Future<T> Function() operation, String fallback) async {
    try {
      return await operation();
    } on InventoryException {
      rethrow;
    } on BranchesException catch (error) {
      throw InventoryException(error.message);
    } on PostgrestException catch (error) {
      throw InventoryException(_messageForPostgrest(error, fallback));
    } on FormatException {
      throw const InventoryException(
        'La respuesta de Supabase no coincide con la migración de Inventario.',
      );
    } catch (_) {
      throw InventoryException(fallback);
    }
  }

  String _messageForPostgrest(PostgrestException error, String fallback) {
    if (error.code == '42501') {
      return 'Tu usuario no tiene permisos para realizar esta acción.';
    }
    if (error.code == '42P01' ||
        error.code == 'PGRST202' ||
        error.code == 'PGRST205') {
      return 'La migración de Inventario no está aplicada o está desactualizada.';
    }
    if (error.code == '23503') {
      return 'La sucursal, producto o materia prima relacionada ya no está disponible.';
    }
    if (error.code == '23505') {
      return 'Ya existe un registro activo con los mismos datos.';
    }
    if (error.code == '23514' ||
        error.code == '22P02' ||
        error.code == '22003') {
      return 'Los datos proporcionados no son válidos.';
    }
    if (error.code == 'P0001' || error.code == 'P0002') {
      final message = error.message.trim();
      if (message.isNotEmpty) return message;
    }
    return fallback;
  }
}
