import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/suppliers/data/models/supplier_model.dart';
import 'package:purificadora/features/suppliers/domain/entities/supplier.dart';

void main() {
  test('convierte la respuesta de Supabase a una entidad', () {
    final model = SupplierModel.fromJson({
      'id': 'f9385340-bcbe-472e-a298-0261239eb157',
      'branch_name': 'Sucursal Centro',
      'name': 'Envases del Noroeste',
      'address': 'Av. Principal 100, Hermosillo, Sonora',
      'phone': '6622345678',
      'created_at': '2026-08-20T10:00:00.000Z',
      'updated_at': '2026-08-20T10:00:00.000Z',
      'deleted_at': null,
    });

    expect(model.branchName, 'Sucursal Centro');
    expect(model.name, 'Envases del Noroeste');
    expect(model.deletedAt, isNull);
  });

  test('solo envía campos editables a Supabase', () {
    const supplier = Supplier(
      id: 'existing-id',
      branchName: '  Sucursal Norte  ',
      name: '  Proveedor Demo  ',
      address: '  Calle Principal 200  ',
      phone: '6623456789',
    );

    expect(SupplierModel.toUpdateJson(supplier), {
      'branch_name': 'Sucursal Norte',
      'name': 'Proveedor Demo',
      'address': 'Calle Principal 200',
      'phone': '6623456789',
    });
  });
}
