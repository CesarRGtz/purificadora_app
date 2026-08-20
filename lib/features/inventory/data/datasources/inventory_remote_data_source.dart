import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/inventory_entities.dart';
import '../models/inventory_models.dart';

abstract interface class InventoryRemoteDataSource {
  Future<List<FinishedGoodModel>> getFinishedGoods();
  Future<FinishedGoodModel> createFinishedGood(FinishedGood finishedGood);
  Future<FinishedGoodModel> updateFinishedGood(FinishedGood finishedGood);
  Future<void> deleteFinishedGood(String id);

  Future<List<RawMaterialModel>> getRawMaterials();
  Future<RawMaterialModel> createRawMaterial(RawMaterial rawMaterial);
  Future<RawMaterialModel> updateRawMaterial(RawMaterial rawMaterial);
  Future<void> deleteRawMaterial(String id);

  Future<RawMaterialMovementModel> registerRawMaterialMovement(
    RawMaterialMovement movement,
  );
  Future<void> transferRawMaterial(
    String sourceRawMaterialId,
    String destinationRawMaterialId,
    double quantity,
  );

  Future<List<ProductMaterialRequirementModel>>
  getProductMaterialRequirements();

  Future<List<ProductBranchAssignmentModel>> getProductBranchAssignments();
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

class SupabaseInventoryRemoteDataSource implements InventoryRemoteDataSource {
  SupabaseInventoryRemoteDataSource(this._client);

  static const _pageSize = 500;
  final SupabaseClient _client;
  static final Random _secureRandom = Random.secure();
  static final Map<String, String> _pendingOperationIds = {};

  @override
  Future<List<FinishedGoodModel>> getFinishedGoods() async {
    final response = await _loadAllPages(
      (from, to) => _client
          .from('finished_goods')
          .select()
          .isFilter('deleted_at', null)
          .order('name')
          .order('id')
          .range(from, to),
    );
    return response
        .map((row) => FinishedGoodModel.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<FinishedGoodModel> createFinishedGood(
    FinishedGood finishedGood,
  ) async {
    final response = await _client
        .from('finished_goods')
        .insert(FinishedGoodModel.toInsertJson(finishedGood))
        .select()
        .single();
    return FinishedGoodModel.fromJson(response);
  }

  @override
  Future<FinishedGoodModel> updateFinishedGood(
    FinishedGood finishedGood,
  ) async {
    final response = await _client
        .from('finished_goods')
        .update(FinishedGoodModel.toUpdateJson(finishedGood))
        .eq('id', finishedGood.id)
        .isFilter('deleted_at', null)
        .select()
        .single();
    return FinishedGoodModel.fromJson(response);
  }

  @override
  Future<void> deleteFinishedGood(String id) async {
    await _client.rpc('soft_delete_finished_good', params: {'p_id': id});
  }

  @override
  Future<List<RawMaterialModel>> getRawMaterials() async {
    final response = await _loadAllPages(
      (from, to) => _client
          .from('raw_material_inventory')
          .select()
          .order('name')
          .order('id')
          .range(from, to),
    );
    return response
        .map((row) => RawMaterialModel.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<RawMaterialModel> createRawMaterial(RawMaterial rawMaterial) async {
    final response = await _client
        .from('raw_materials')
        .insert(RawMaterialModel.toInsertJson(rawMaterial))
        .select()
        .single();
    return RawMaterialModel.fromJson(response);
  }

  @override
  Future<RawMaterialModel> updateRawMaterial(RawMaterial rawMaterial) async {
    final response = await _client
        .from('raw_materials')
        .update(RawMaterialModel.toUpdateJson(rawMaterial))
        .eq('id', rawMaterial.id)
        .isFilter('deleted_at', null)
        .select()
        .single();
    return RawMaterialModel.fromJson(response);
  }

  @override
  Future<void> deleteRawMaterial(String id) async {
    await _client.rpc('soft_delete_raw_material', params: {'p_id': id});
  }

  @override
  Future<RawMaterialMovementModel> registerRawMaterialMovement(
    RawMaterialMovement movement,
  ) async {
    final rawMaterial = await _client
        .from('raw_materials')
        .select('branch_id')
        .eq('id', movement.rawMaterialId)
        .isFilter('deleted_at', null)
        .single();
    final operationKey = [
      'movement',
      movement.rawMaterialId,
      movement.type.name,
      movement.quantity,
      movement.unitCost,
      movement.productId,
    ].join(':');
    final operationId = _operationIdFor(operationKey);

    final response = await _client.rpc(
      'register_raw_material_movement',
      params: {
        'p_raw_material_id': movement.rawMaterialId,
        'p_branch_id': rawMaterial['branch_id'] as String,
        'p_type': rawMaterialMovementTypeToJson(movement.type),
        'p_quantity': movement.quantity,
        'p_operation_id': operationId,
        'p_unit_cost': movement.unitCost,
        'p_product_id': movement.productId,
        'p_note': '',
        'p_occurred_at': movement.createdAt?.toUtc().toIso8601String(),
      },
    );

    final movementId = _rpcUuid(response, 'movimiento de materia prima');
    final created = await _client
        .from('raw_material_movements')
        .select()
        .eq('id', movementId)
        .isFilter('deleted_at', null)
        .single();
    _pendingOperationIds.remove(operationKey);
    return RawMaterialMovementModel.fromJson(created);
  }

  @override
  Future<void> transferRawMaterial(
    String sourceRawMaterialId,
    String destinationRawMaterialId,
    double quantity,
  ) async {
    final operationKey = [
      'transfer',
      sourceRawMaterialId,
      destinationRawMaterialId,
      quantity,
    ].join(':');
    final operationId = _operationIdFor(operationKey);
    await _client.rpc(
      'transfer_raw_material',
      params: {
        'p_source_raw_material_id': sourceRawMaterialId,
        'p_destination_raw_material_id': destinationRawMaterialId,
        'p_quantity': quantity,
        'p_operation_id': operationId,
      },
    );
    _pendingOperationIds.remove(operationKey);
  }

  @override
  Future<List<ProductMaterialRequirementModel>>
  getProductMaterialRequirements() async {
    final response = await _loadAllPages(
      (from, to) => _client
          .from('product_material_requirements')
          .select()
          .isFilter('deleted_at', null)
          .order('product_id')
          .order('id')
          .range(from, to),
    );
    return response
        .map((row) => ProductMaterialRequirementModel.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<List<ProductBranchAssignmentModel>>
  getProductBranchAssignments() async {
    final response = await _loadAllPages(
      (from, to) => _client
          .from('branch_products')
          .select('product_id, branch_id')
          .isFilter('deleted_at', null)
          .order('product_id')
          .order('branch_id')
          .range(from, to),
    );
    return response
        .map((row) => ProductBranchAssignmentModel.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<void> configureProductBranches(
    String productId,
    Set<String> branchIds,
  ) async {
    final sortedBranchIds = branchIds.toList(growable: false)..sort();
    await _client.rpc(
      'configure_product_branches',
      params: {'p_product_id': productId, 'p_branch_ids': sortedBranchIds},
    );
  }

  @override
  Future<void> configureProductMaterials(
    String productId,
    Map<String, double> quantitiesByRawMaterialId,
  ) async {
    final sortedEntries = quantitiesByRawMaterialId.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    await _client.rpc(
      'configure_product_materials',
      params: {
        'p_product_id': productId,
        'p_materials': {
          for (final entry in sortedEntries) entry.key: entry.value,
        },
      },
    );
  }

  @override
  Future<void> consumeProduct(
    String productId,
    String branchId,
    int quantity,
  ) async {
    final operationKey = 'consume:$productId:$branchId:$quantity';
    final operationId = _operationIdFor(operationKey);
    await _client.rpc(
      'consume_product_materials',
      params: {
        'p_product_id': productId,
        'p_branch_id': branchId,
        'p_quantity': quantity,
        'p_operation_id': operationId,
      },
    );
    _pendingOperationIds.remove(operationKey);
  }

  String _rpcUuid(Object? response, String operation) {
    if (response is String && response.isNotEmpty) return response;
    throw FormatException(
      'Supabase no devolvió el identificador del $operation.',
    );
  }

  Future<List<Map<String, dynamic>>> _loadAllPages(
    Future<List<Map<String, dynamic>>> Function(int from, int to) loadPage,
  ) async {
    final rows = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final page = await loadPage(from, from + _pageSize - 1);
      if (page.isEmpty) return rows;
      rows.addAll(page);
      from += page.length;
    }
  }

  String _operationIdFor(String key) =>
      _pendingOperationIds.putIfAbsent(key, _newUuidV4);

  String _newUuidV4() {
    final bytes = List<int>.generate(
      16,
      (_) => _secureRandom.nextInt(256),
      growable: false,
    );
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
