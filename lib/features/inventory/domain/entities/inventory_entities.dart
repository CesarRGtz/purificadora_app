enum FinishedGoodStatus { purchased, sold, loaned, returned }

enum RawMaterialMovementType { purchase, use, transferIn, transferOut }

class InventoryBranch {
  const InventoryBranch({required this.id, required this.name});

  final String id;
  final String name;
}

class InventoryProduct {
  const InventoryProduct({
    required this.name,
    required this.sku,
    required this.basePrice,
    this.description = '',
    this.branchIds = const {},
    this.id = '',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String sku;
  final String description;
  final double basePrice;
  final Set<String> branchIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}

class FinishedGood {
  const FinishedGood({
    required this.branchId,
    required this.name,
    required this.type,
    required this.status,
    required this.quantity,
    required this.isSellable,
    this.productId,
    this.id = '',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String branchId;
  final String? productId;
  final String name;
  final String type;
  final FinishedGoodStatus status;
  final int quantity;
  final bool isSellable;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}

class RawMaterial {
  const RawMaterial({
    required this.branchId,
    required this.category,
    required this.name,
    required this.unit,
    required this.lastUnitCost,
    this.purchased = 0,
    this.used = 0,
    this.transferIn = 0,
    this.transferOut = 0,
    this.id = '',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String branchId;
  final String category;
  final String name;
  final String unit;
  final double lastUnitCost;
  final double purchased;
  final double used;
  final double transferIn;
  final double transferOut;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  double get stock => purchased + transferIn - used - transferOut;
  double get totalValue => stock * lastUnitCost;

  double get purchasedQuantity => purchased;
  double get usedQuantity => used;
  double get transferInQuantity => transferIn;
  double get transferOutQuantity => transferOut;
}

class RawMaterialMovement {
  const RawMaterialMovement({
    required this.rawMaterialId,
    required this.type,
    required this.quantity,
    this.unitCost,
    this.productId,
    this.id = '',
    this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String rawMaterialId;
  final RawMaterialMovementType type;
  final double quantity;
  final double? unitCost;
  final String? productId;
  final DateTime? createdAt;
  final DateTime? deletedAt;
}

class ProductMaterialRequirement {
  const ProductMaterialRequirement({
    required this.productId,
    required this.rawMaterialId,
    required this.quantityPerUnit,
    this.id = '',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String productId;
  final String rawMaterialId;
  final double quantityPerUnit;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}

class InventorySnapshot {
  const InventorySnapshot({
    required this.branches,
    required this.products,
    required this.finishedGoods,
    required this.rawMaterials,
    required this.productMaterialRequirements,
  });

  final List<InventoryBranch> branches;
  final List<InventoryProduct> products;
  final List<FinishedGood> finishedGoods;
  final List<RawMaterial> rawMaterials;
  final List<ProductMaterialRequirement> productMaterialRequirements;
}
