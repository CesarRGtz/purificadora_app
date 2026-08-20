import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/suppliers/data/repositories/in_memory_supplier_repository.dart';
import 'package:purificadora/features/suppliers/domain/entities/supplier.dart';
import 'package:purificadora/features/suppliers/domain/errors/supplier_exception.dart';

void main() {
  late InMemorySupplierRepository repository;

  setUp(() => repository = InMemorySupplierRepository());

  test('permite crear y actualizar proveedores sin conexión', () async {
    final created = await repository.createSupplier(_supplier());
    final updated = await repository.updateSupplier(
      Supplier(
        id: created.id,
        branchName: 'Sucursal Norte',
        name: created.name,
        address: created.address,
        phone: created.phone,
      ),
    );

    expect(created.id, startsWith('local-'));
    expect(updated.branchName, 'Sucursal Norte');
    expect(await repository.getSuppliers(), hasLength(1));
  });

  test('la eliminación lógica oculta el proveedor activo', () async {
    final created = await repository.createSupplier(_supplier());
    await repository.deleteSupplier(created.id);

    expect(await repository.getSuppliers(), isEmpty);
    expect(
      () => repository.updateSupplier(created),
      throwsA(isA<SupplierException>()),
    );
  });
}

Supplier _supplier() {
  return const Supplier(
    branchName: 'Sucursal Centro',
    name: 'Envases del Noroeste',
    address: 'Av. Principal 100, Hermosillo, Sonora',
    phone: '6622345678',
  );
}
