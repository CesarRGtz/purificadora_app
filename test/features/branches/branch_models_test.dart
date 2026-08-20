import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/branches/data/models/branch_model.dart';
import 'package:purificadora/features/branches/data/models/product_model.dart';

void main() {
  test('convierte una sucursal desde Supabase', () {
    final model = BranchModel.fromJson({
      'id': 'branch-id',
      'name': 'Sucursal Centro',
      'business_name': 'Purificadora Demo',
      'address': 'Blvd. Hidalgo 100, Hermosillo, Sonora',
      'latitude': 29.072967,
      'longitude': -110.955919,
      'created_at': '2026-08-20T12:00:00.000Z',
      'updated_at': '2026-08-20T12:00:00.000Z',
      'deleted_at': null,
    });

    expect(model.name, 'Sucursal Centro');
    expect(model.latitude, closeTo(29.072967, 0.000001));
    expect(model.deletedAt, isNull);
  });

  test('convierte un producto y normaliza su escritura', () {
    final model = ProductModel.fromJson({
      'id': 'product-id',
      'name': 'Garrafón 20 L',
      'sku': 'AGUA-20L',
      'description': 'Agua purificada',
      'base_price': 45.0,
      'created_at': '2026-08-20T12:00:00.000Z',
      'updated_at': '2026-08-20T12:00:00.000Z',
      'deleted_at': null,
    });

    expect(model.basePrice, 45);
    expect(ProductModel.toUpdateJson(model)['sku'], 'AGUA-20L');
  });
}
