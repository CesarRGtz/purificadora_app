import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/inventory/data/models/inventory_models.dart';
import 'package:purificadora/features/inventory/domain/entities/inventory_entities.dart';
import 'package:purificadora/features/inventory/domain/validation/inventory_validators.dart';
import 'package:purificadora/features/inventory/presentation/inventory_formatters.dart';

void main() {
  group('InventoryValidators', () {
    test('valida textos, sucursal y cantidades finitas', () {
      expect(InventoryValidators.name('Activo válido'), isNull);
      expect(InventoryValidators.name(' '), isNotNull);
      expect(InventoryValidators.branchId('branch-1'), isNull);
      expect(InventoryValidators.branchId(''), 'Selecciona una sucursal');

      expect(InventoryValidators.nonNegativeDecimal('0'), isNull);
      expect(InventoryValidators.nonNegativeDecimal('-0.1'), isNotNull);
      expect(InventoryValidators.nonNegativeDecimal('NaN'), isNotNull);
      expect(InventoryValidators.nonNegativeDecimal('Infinity'), isNotNull);
      expect(InventoryValidators.positiveDecimal('0.005'), isNull);
      expect(InventoryValidators.positiveDecimal('0,5'), isNull);
      expect(InventoryValidators.positiveDecimal('0'), isNotNull);
      expect(InventoryValidators.inventoryQuantity('1.125'), isNull);
      expect(InventoryValidators.inventoryQuantity('1.1255'), isNotNull);
      expect(InventoryValidators.unitCost('0.1234'), isNull);
      expect(InventoryValidators.unitCost('0.12345'), isNotNull);
      expect(InventoryValidators.unitCost('9999999999.9999'), isNull);
      expect(InventoryValidators.parseDecimal('0,125'), 0.125);

      expect(InventoryValidators.nonNegativeInteger('10'), isNull);
      expect(InventoryValidators.nonNegativeInteger('1.5'), isNotNull);
      expect(InventoryValidators.positiveInteger('1'), isNull);
      expect(InventoryValidators.positiveInteger('0'), isNotNull);
    });
  });

  test('conserva hasta cuatro decimales en el último costo', () {
    expect(formatInventoryUnitCostInput(0.1234), '0.1234');
    expect(formatInventoryUnitCost(0.1234), r'$0.1234');
    expect(formatInventoryUnitCost(15), r'$15.00');
  });

  test('deriva existencia y total sin almacenarlos', () {
    const material = RawMaterial(
      id: 'raw-1',
      branchId: 'branch-1',
      category: 'Empaque',
      name: 'Tapas',
      unit: 'pzas',
      lastUnitCost: 2,
      purchased: 100,
      used: 20,
      transferIn: 10,
      transferOut: 5,
    );

    expect(material.stock, 85);
    expect(material.totalValue, 170);
  });

  group('modelos de inventario', () {
    test('convierte materia prima y acumulados de Supabase', () {
      final model = RawMaterialModel.fromJson({
        'id': 'raw-1',
        'branch_id': 'branch-1',
        'category': 'Empaque',
        'name': 'Tapas',
        'unit': 'pzas',
        'last_unit_cost': '2.00',
        'purchase_quantity': '100',
        'used_quantity': 20,
        'transfer_in_quantity': 10.0,
        'transfer_out_quantity': '5',
        'created_at': '2026-08-20T10:00:00Z',
        'updated_at': '2026-08-20T11:00:00Z',
        'deleted_at': null,
      });

      expect(model.stock, 85);
      expect(model.totalValue, 170);
      expect(model.createdAt, DateTime.parse('2026-08-20T10:00:00Z'));
      expect(RawMaterialModel.toInsertJson(model), {
        'branch_id': 'branch-1',
        'category': 'Empaque',
        'name': 'Tapas',
        'unit': 'pzas',
        'last_unit_cost': 2.0,
      });
    });

    test('convierte estados, movimientos y únicamente campos editables', () {
      final finishedGood = FinishedGoodModel.fromJson({
        'id': 'finished-1',
        'branch_id': 'branch-1',
        'product_id': 'product-1',
        'name': 'Garrafón',
        'asset_type': 'Retornable',
        'status': 'loaned',
        'quantity': '12',
        'is_sellable': false,
        'created_at': '2026-08-20T10:00:00Z',
        'updated_at': '2026-08-20T10:00:00Z',
        'deleted_at': null,
      });
      final movement = RawMaterialMovementModel.fromJson({
        'id': 'movement-1',
        'raw_material_id': 'raw-1',
        'type': 'transfer_in',
        'quantity': '10.500',
        'unit_cost': null,
        'product_id': null,
        'occurred_at': '2026-08-20T12:00:00Z',
        'deleted_at': null,
      });

      expect(finishedGood.status, FinishedGoodStatus.loaned);
      expect(finishedGood.quantity, 12);
      expect(FinishedGoodModel.toUpdateJson(finishedGood), {
        'branch_id': 'branch-1',
        'product_id': 'product-1',
        'name': 'Garrafón',
        'asset_type': 'Retornable',
        'status': 'loaned',
        'quantity': 12,
        'is_sellable': false,
      });
      expect(movement.type, RawMaterialMovementType.transferIn);
      expect(movement.quantity, 10.5);
      expect(
        rawMaterialMovementTypeToJson(RawMaterialMovementType.transferOut),
        'transfer_out',
      );
    });
  });
}
