import '../../domain/entities/supplier.dart';
import '../../domain/errors/supplier_exception.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../domain/validation/supplier_validators.dart';

class InMemorySupplierRepository implements SupplierRepository {
  InMemorySupplierRepository({List<Supplier> initialSuppliers = const []})
    : _suppliers = [...initialSuppliers];

  final List<Supplier> _suppliers;

  @override
  Future<List<Supplier>> getSuppliers() async {
    return _suppliers.where((supplier) => supplier.deletedAt == null).toList()
      ..sort(_sortByName);
  }

  @override
  Future<Supplier> createSupplier(Supplier supplier) async {
    _validate(supplier);
    final now = DateTime.now();
    final created = _normalizedCopy(
      supplier,
      id: 'local-${now.microsecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );
    _suppliers.add(created);
    return created;
  }

  @override
  Future<Supplier> updateSupplier(Supplier supplier) async {
    final index = _suppliers.indexWhere(
      (current) => current.id == supplier.id && current.deletedAt == null,
    );
    if (index == -1) {
      throw const SupplierException(
        'El proveedor que intentas editar no existe.',
      );
    }

    _validate(supplier);
    final updated = _normalizedCopy(
      supplier,
      createdAt: _suppliers[index].createdAt,
      updatedAt: DateTime.now(),
    );
    _suppliers[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSupplier(String id) async {
    final index = _suppliers.indexWhere(
      (supplier) => supplier.id == id && supplier.deletedAt == null,
    );
    if (index == -1) {
      throw const SupplierException(
        'El proveedor que intentas eliminar no existe.',
      );
    }

    final current = _suppliers[index];
    _suppliers[index] = _normalizedCopy(
      current,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: DateTime.now(),
    );
  }

  void _validate(Supplier supplier) {
    final error =
        SupplierValidators.branchName(supplier.branchName) ??
        SupplierValidators.name(supplier.name) ??
        SupplierValidators.address(supplier.address) ??
        SupplierValidators.phone(supplier.phone);
    if (error != null) throw SupplierException(error);
  }

  Supplier _normalizedCopy(
    Supplier supplier, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Supplier(
      id: id ?? supplier.id,
      branchName: supplier.branchName.trim(),
      name: supplier.name.trim(),
      address: supplier.address.trim(),
      phone: SupplierValidators.normalizePhone(supplier.phone),
      createdAt: createdAt ?? supplier.createdAt,
      updatedAt: updatedAt ?? supplier.updatedAt,
      deletedAt: deletedAt ?? supplier.deletedAt,
    );
  }

  static int _sortByName(Supplier a, Supplier b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
