import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class CreateSupplier {
  const CreateSupplier(this._repository);

  final SupplierRepository _repository;

  Future<Supplier> call(Supplier supplier) =>
      _repository.createSupplier(supplier);
}
