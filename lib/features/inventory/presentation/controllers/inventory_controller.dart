import 'package:flutter/foundation.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../domain/errors/inventory_exception.dart';
import '../../domain/repositories/inventory_repository.dart';

enum InventoryViewStatus { initial, loading, ready, failure }

class InventoryController extends ChangeNotifier {
  InventoryController(this._repository);

  final InventoryRepository _repository;

  InventoryViewStatus _status = InventoryViewStatus.initial;
  InventorySnapshot _snapshot = const InventorySnapshot(
    branches: [],
    products: [],
    finishedGoods: [],
    rawMaterials: [],
    productMaterialRequirements: [],
  );
  String? _errorMessage;
  String? _operationError;
  bool _isSubmitting = false;
  bool _isDisposed = false;

  InventoryViewStatus get status => _status;
  InventorySnapshot get snapshot => _snapshot;
  String? get errorMessage => _errorMessage;
  String? get operationError => _operationError;
  bool get isSubmitting => _isSubmitting;

  Future<void> load() async {
    _status = InventoryViewStatus.loading;
    _errorMessage = null;
    _notifySafely();
    try {
      _snapshot = await _repository.getSnapshot();
      _status = InventoryViewStatus.ready;
    } catch (error) {
      _status = InventoryViewStatus.failure;
      _errorMessage = _messageFor(error);
    }
    _notifySafely();
  }

  Future<bool> createFinishedGood(FinishedGood item) =>
      _runMutation(() => _repository.createFinishedGood(item));

  Future<bool> updateFinishedGood(FinishedGood item) =>
      _runMutation(() => _repository.updateFinishedGood(item));

  Future<bool> deleteFinishedGood(String id) =>
      _runMutation(() => _repository.deleteFinishedGood(id));

  Future<bool> createRawMaterial(RawMaterial material) =>
      _runMutation(() => _repository.createRawMaterial(material));

  Future<bool> updateRawMaterial(RawMaterial material) =>
      _runMutation(() => _repository.updateRawMaterial(material));

  Future<bool> deleteRawMaterial(String id) =>
      _runMutation(() => _repository.deleteRawMaterial(id));

  Future<bool> registerRawMaterialMovement(RawMaterialMovement movement) =>
      _runMutation(() => _repository.registerRawMaterialMovement(movement));

  Future<bool> transferRawMaterial(
    String sourceRawMaterialId,
    String destinationRawMaterialId,
    double quantity,
  ) => _runMutation(
    () => _repository.transferRawMaterial(
      sourceRawMaterialId,
      destinationRawMaterialId,
      quantity,
    ),
  );

  Future<bool> createProduct(InventoryProduct product) =>
      _runMutation(() => _repository.createProduct(product));

  Future<bool> updateProduct(InventoryProduct product) =>
      _runMutation(() => _repository.updateProduct(product));

  Future<bool> deleteProduct(String id) =>
      _runMutation(() => _repository.deleteProduct(id));

  Future<bool> configureProductBranches(
    String productId,
    Set<String> branchIds,
  ) => _runMutation(
    () => _repository.configureProductBranches(productId, branchIds),
  );

  Future<bool> configureProductMaterials(
    String productId,
    Map<String, double> quantities,
  ) => _runMutation(
    () => _repository.configureProductMaterials(productId, quantities),
  );

  Future<bool> consumeProduct(
    String productId,
    String branchId,
    int quantity,
  ) => _runMutation(
    () => _repository.consumeProduct(productId, branchId, quantity),
  );

  Future<bool> _runMutation(Future<Object?> Function() operation) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _operationError = null;
    _notifySafely();
    try {
      try {
        await operation();
      } catch (error) {
        _operationError = _messageFor(error);
        return false;
      }

      try {
        _snapshot = await _repository.getSnapshot();
        _status = InventoryViewStatus.ready;
        return true;
      } catch (_) {
        // La escritura ya fue confirmada. No se reporta como fallida para
        // evitar que el usuario la repita y duplique compras o consumos.
        _status = InventoryViewStatus.failure;
        _errorMessage =
            'El cambio se guardó, pero no fue posible actualizar la vista. Vuelve a cargar el inventario.';
        return true;
      }
    } finally {
      _isSubmitting = false;
      _notifySafely();
    }
  }

  String _messageFor(Object error) {
    if (error is InventoryException) return error.message;
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }

  void _notifySafely() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
