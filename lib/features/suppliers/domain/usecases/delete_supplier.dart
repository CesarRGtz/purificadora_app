import '../repositories/supplier_repository.dart';

class DeleteSupplier {
  const DeleteSupplier(this._repository);

  final SupplierRepository _repository;

  Future<void> call(String id) => _repository.deleteSupplier(id);
}
