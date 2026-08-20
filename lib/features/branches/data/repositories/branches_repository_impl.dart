import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/branch.dart';
import '../../domain/entities/product.dart';
import '../../domain/errors/branches_exception.dart';
import '../../domain/repositories/branches_repository.dart';
import '../datasources/branches_remote_data_source.dart';

class BranchesRepositoryImpl implements BranchesRepository {
  const BranchesRepositoryImpl(this._remoteDataSource);

  final BranchesRemoteDataSource _remoteDataSource;

  @override
  Future<List<Branch>> getBranches() => _guard(
    _remoteDataSource.getBranches,
    'No fue posible cargar las sucursales.',
  );

  @override
  Future<Branch> createBranch(Branch branch) => _guard(
    () => _remoteDataSource.createBranch(branch),
    'No fue posible registrar la sucursal.',
  );

  @override
  Future<Branch> updateBranch(Branch branch) => _guard(
    () => _remoteDataSource.updateBranch(branch),
    'No fue posible actualizar la sucursal.',
  );

  @override
  Future<void> deleteBranch(String id) => _guard(
    () => _remoteDataSource.deleteBranch(id),
    'No fue posible eliminar la sucursal.',
  );

  @override
  Future<List<Product>> getProducts() => _guard(
    _remoteDataSource.getProducts,
    'No fue posible cargar los productos.',
  );

  @override
  Future<Product> createProduct(Product product) => _guard(
    () => _remoteDataSource.createProduct(product),
    'No fue posible registrar el producto.',
  );

  @override
  Future<Product> updateProduct(Product product) => _guard(
    () => _remoteDataSource.updateProduct(product),
    'No fue posible actualizar el producto.',
  );

  @override
  Future<void> deleteProduct(String id) => _guard(
    () => _remoteDataSource.deleteProduct(id),
    'No fue posible eliminar el producto.',
  );

  @override
  Future<Set<String>> getBranchProductIds(String branchId) => _guard(
    () => _remoteDataSource.getBranchProductIds(branchId),
    'No fue posible cargar los productos de la sucursal.',
  );

  @override
  Future<void> configureBranchProducts(
    String branchId,
    Set<String> productIds,
  ) => _guard(
    () => _remoteDataSource.configureBranchProducts(branchId, productIds),
    'No fue posible guardar los productos de la sucursal.',
  );

  Future<T> _guard<T>(Future<T> Function() operation, String fallback) async {
    try {
      return await operation();
    } on PostgrestException catch (error) {
      final errorDetails = '${error.message} ${error.details}';
      if (error.code == '23505' &&
          errorDetails.contains('products_active_sku_unique_idx')) {
        throw const BranchesException(
          'Ya existe un producto activo con ese SKU.',
        );
      }
      if (error.code == '42501') {
        throw const BranchesException(
          'Tu usuario no tiene permisos para realizar esta acción.',
        );
      }
      throw BranchesException(fallback);
    } catch (_) {
      throw BranchesException(fallback);
    }
  }
}
