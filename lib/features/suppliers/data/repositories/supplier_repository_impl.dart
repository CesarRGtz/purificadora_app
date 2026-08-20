import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/supplier.dart';
import '../../domain/errors/supplier_exception.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/supplier_remote_data_source.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  const SupplierRepositoryImpl(this._remoteDataSource);

  final SupplierRemoteDataSource _remoteDataSource;

  @override
  Future<List<Supplier>> getSuppliers() => _guard(
    _remoteDataSource.getSuppliers,
    fallbackMessage: 'No fue posible cargar los proveedores.',
  );

  @override
  Future<Supplier> createSupplier(Supplier supplier) => _guard(
    () => _remoteDataSource.createSupplier(supplier),
    fallbackMessage: 'No fue posible registrar el proveedor.',
  );

  @override
  Future<Supplier> updateSupplier(Supplier supplier) => _guard(
    () => _remoteDataSource.updateSupplier(supplier),
    fallbackMessage: 'No fue posible actualizar el proveedor.',
  );

  @override
  Future<void> deleteSupplier(String id) => _guard(
    () => _remoteDataSource.deleteSupplier(id),
    fallbackMessage: 'No fue posible eliminar el proveedor.',
  );

  Future<T> _guard<T>(
    Future<T> Function() operation, {
    required String fallbackMessage,
  }) async {
    try {
      return await operation();
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        throw const SupplierException(
          'Tu usuario no tiene permisos para realizar esta acción.',
        );
      }
      throw SupplierException(fallbackMessage);
    } catch (_) {
      throw SupplierException(fallbackMessage);
    }
  }
}
