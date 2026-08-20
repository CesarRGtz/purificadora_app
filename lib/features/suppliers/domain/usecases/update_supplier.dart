import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class UpdateSupplier {
  const UpdateSupplier(this._repository);

  final SupplierRepository _repository;

  Future<Supplier> call(Supplier supplier) =>
      _repository.updateSupplier(supplier);
}
