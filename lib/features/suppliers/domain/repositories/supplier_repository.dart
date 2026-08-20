import '../entities/supplier.dart';

abstract interface class SupplierRepository {
  Future<List<Supplier>> getSuppliers();
  Future<Supplier> createSupplier(Supplier supplier);
  Future<Supplier> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
}
