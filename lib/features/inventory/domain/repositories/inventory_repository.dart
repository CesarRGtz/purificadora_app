import '../entities/inventory_entities.dart';

abstract interface class InventoryRepository {
  Future<InventorySnapshot> getSnapshot();

  Future<FinishedGood> createFinishedGood(FinishedGood finishedGood);
  Future<FinishedGood> updateFinishedGood(FinishedGood finishedGood);
  Future<void> deleteFinishedGood(String id);

  Future<RawMaterial> createRawMaterial(RawMaterial rawMaterial);
  Future<RawMaterial> updateRawMaterial(RawMaterial rawMaterial);
  Future<void> deleteRawMaterial(String id);

  Future<InventoryProduct> createProduct(InventoryProduct product);
  Future<InventoryProduct> updateProduct(InventoryProduct product);
  Future<void> deleteProduct(String id);

  Future<RawMaterialMovement> registerRawMaterialMovement(
    RawMaterialMovement movement,
  );

  Future<void> transferRawMaterial(
    String sourceRawMaterialId,
    String destinationRawMaterialId,
    double quantity,
  );

  Future<void> configureProductBranches(
    String productId,
    Set<String> branchIds,
  );

  Future<void> configureProductMaterials(
    String productId,
    Map<String, double> quantitiesByRawMaterialId,
  );

  Future<void> consumeProduct(String productId, String branchId, int quantity);
}
