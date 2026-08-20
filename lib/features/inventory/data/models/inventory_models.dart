import '../../domain/entities/inventory_entities.dart';

class FinishedGoodModel extends FinishedGood {
  const FinishedGoodModel({
    required super.id,
    required super.branchId,
    required super.productId,
    required super.name,
    required super.type,
    required super.status,
    required super.quantity,
    required super.isSellable,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
  });

  factory FinishedGoodModel.fromJson(Map<String, dynamic> json) {
    return FinishedGoodModel(
      id: json['id'] as String,
      branchId: json['branch_id'] as String,
      productId: json['product_id'] as String?,
      name: json['name'] as String,
      type: json['asset_type'] as String,
      status: _finishedGoodStatusFromJson(json['status']),
      quantity: _intFromJson(json['quantity']),
      isSellable: json['is_sellable'] as bool? ?? false,
      createdAt: _dateTimeFromJson(json['created_at']),
      updatedAt: _dateTimeFromJson(json['updated_at']),
      deletedAt: _dateTimeFromJson(json['deleted_at']),
    );
  }

  static Map<String, dynamic> toInsertJson(FinishedGood finishedGood) =>
      _writableFields(finishedGood);

  static Map<String, dynamic> toUpdateJson(FinishedGood finishedGood) =>
      _writableFields(finishedGood);

  static Map<String, dynamic> _writableFields(FinishedGood finishedGood) {
    return {
      'branch_id': finishedGood.branchId,
      'product_id': finishedGood.productId,
      'name': finishedGood.name.trim(),
      'asset_type': finishedGood.type.trim(),
      'status': finishedGood.status.name,
      'quantity': finishedGood.quantity,
      'is_sellable': finishedGood.isSellable,
    };
  }
}

class RawMaterialModel extends RawMaterial {
  const RawMaterialModel({
    required super.id,
    required super.branchId,
    required super.category,
    required super.name,
    required super.unit,
    required super.lastUnitCost,
    required super.purchased,
    required super.used,
    required super.transferIn,
    required super.transferOut,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
  });

  factory RawMaterialModel.fromJson(Map<String, dynamic> json) {
    return RawMaterialModel(
      id: json['id'] as String,
      branchId: json['branch_id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      lastUnitCost: _doubleFromJson(json['last_unit_cost']),
      purchased: _optionalDoubleFromJson(json['purchase_quantity']),
      used: _optionalDoubleFromJson(json['used_quantity']),
      transferIn: _optionalDoubleFromJson(json['transfer_in_quantity']),
      transferOut: _optionalDoubleFromJson(json['transfer_out_quantity']),
      createdAt: _dateTimeFromJson(json['created_at']),
      updatedAt: _dateTimeFromJson(json['updated_at']),
      deletedAt: _dateTimeFromJson(json['deleted_at']),
    );
  }

  RawMaterialModel withInventory({
    required double purchased,
    required double used,
    required double transferIn,
    required double transferOut,
    required double lastUnitCost,
  }) {
    return RawMaterialModel(
      id: id,
      branchId: branchId,
      category: category,
      name: name,
      unit: unit,
      lastUnitCost: lastUnitCost,
      purchased: purchased,
      used: used,
      transferIn: transferIn,
      transferOut: transferOut,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  static Map<String, dynamic> toInsertJson(RawMaterial rawMaterial) =>
      _writableFields(rawMaterial);

  static Map<String, dynamic> toUpdateJson(RawMaterial rawMaterial) =>
      _writableFields(rawMaterial);

  static Map<String, dynamic> _writableFields(RawMaterial rawMaterial) {
    return {
      'branch_id': rawMaterial.branchId,
      'category': rawMaterial.category.trim(),
      'name': rawMaterial.name.trim(),
      'unit': rawMaterial.unit.trim(),
      'last_unit_cost': rawMaterial.lastUnitCost,
    };
  }
}

class RawMaterialMovementModel extends RawMaterialMovement {
  const RawMaterialMovementModel({
    required super.id,
    required super.rawMaterialId,
    required super.type,
    required super.quantity,
    required super.unitCost,
    required super.productId,
    required super.createdAt,
    required super.deletedAt,
  });

  factory RawMaterialMovementModel.fromJson(Map<String, dynamic> json) {
    return RawMaterialMovementModel(
      id: json['id'] as String,
      rawMaterialId: json['raw_material_id'] as String,
      type: _rawMaterialMovementTypeFromJson(json['type']),
      quantity: _doubleFromJson(json['quantity']),
      unitCost: _nullableDoubleFromJson(json['unit_cost']),
      productId: json['product_id'] as String?,
      createdAt: _dateTimeFromJson(json['occurred_at'] ?? json['created_at']),
      deletedAt: _dateTimeFromJson(json['deleted_at']),
    );
  }
}

class ProductMaterialRequirementModel extends ProductMaterialRequirement {
  const ProductMaterialRequirementModel({
    required super.id,
    required super.productId,
    required super.rawMaterialId,
    required super.quantityPerUnit,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
  });

  factory ProductMaterialRequirementModel.fromJson(Map<String, dynamic> json) {
    return ProductMaterialRequirementModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      rawMaterialId: json['raw_material_id'] as String,
      quantityPerUnit: _doubleFromJson(json['quantity_per_unit']),
      createdAt: _dateTimeFromJson(json['created_at']),
      updatedAt: _dateTimeFromJson(json['updated_at']),
      deletedAt: _dateTimeFromJson(json['deleted_at']),
    );
  }
}

class ProductBranchAssignmentModel {
  const ProductBranchAssignmentModel({
    required this.productId,
    required this.branchId,
  });

  final String productId;
  final String branchId;

  factory ProductBranchAssignmentModel.fromJson(Map<String, dynamic> json) {
    return ProductBranchAssignmentModel(
      productId: json['product_id'] as String,
      branchId: json['branch_id'] as String,
    );
  }
}

FinishedGoodStatus _finishedGoodStatusFromJson(Object? value) {
  return switch (value) {
    'purchased' => FinishedGoodStatus.purchased,
    'sold' => FinishedGoodStatus.sold,
    'loaned' => FinishedGoodStatus.loaned,
    'returned' => FinishedGoodStatus.returned,
    _ => throw FormatException('Estado de activo no reconocido: $value'),
  };
}

RawMaterialMovementType _rawMaterialMovementTypeFromJson(Object? value) {
  return switch (value) {
    'purchase' => RawMaterialMovementType.purchase,
    'use' => RawMaterialMovementType.use,
    'transfer_in' => RawMaterialMovementType.transferIn,
    'transfer_out' => RawMaterialMovementType.transferOut,
    _ => throw FormatException(
      'Tipo de movimiento de materia prima no reconocido: $value',
    ),
  };
}

String rawMaterialMovementTypeToJson(RawMaterialMovementType value) {
  return switch (value) {
    RawMaterialMovementType.purchase => 'purchase',
    RawMaterialMovementType.use => 'use',
    RawMaterialMovementType.transferIn => 'transfer_in',
    RawMaterialMovementType.transferOut => 'transfer_out',
  };
}

DateTime? _dateTimeFromJson(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

double _doubleFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Valor numérico no reconocido: $value');
}

double _optionalDoubleFromJson(Object? value) {
  if (value == null) return 0;
  return _doubleFromJson(value);
}

double? _nullableDoubleFromJson(Object? value) {
  if (value == null) return null;
  return _doubleFromJson(value);
}

int _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Valor entero no reconocido: $value');
}
