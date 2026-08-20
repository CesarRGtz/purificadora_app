import 'package:flutter/foundation.dart';

import '../../domain/entities/supplier.dart';
import '../../domain/errors/supplier_exception.dart';
import '../../domain/usecases/create_supplier.dart';
import '../../domain/usecases/delete_supplier.dart';
import '../../domain/usecases/get_suppliers.dart';
import '../../domain/usecases/update_supplier.dart';

enum SuppliersViewStatus { initial, loading, ready, failure }

class SuppliersController extends ChangeNotifier {
  SuppliersController({
    required GetSuppliers getSuppliers,
    required CreateSupplier createSupplier,
    required UpdateSupplier updateSupplier,
    required DeleteSupplier deleteSupplier,
  }) : _getSuppliers = getSuppliers,
       _createSupplier = createSupplier,
       _updateSupplier = updateSupplier,
       _deleteSupplier = deleteSupplier;

  final GetSuppliers _getSuppliers;
  final CreateSupplier _createSupplier;
  final UpdateSupplier _updateSupplier;
  final DeleteSupplier _deleteSupplier;

  SuppliersViewStatus _status = SuppliersViewStatus.initial;
  List<Supplier> _suppliers = const [];
  String? _errorMessage;
  String? _operationError;
  bool _isSubmitting = false;
  bool _isDisposed = false;

  SuppliersViewStatus get status => _status;
  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  String? get errorMessage => _errorMessage;
  String? get operationError => _operationError;
  bool get isSubmitting => _isSubmitting;

  Future<void> loadSuppliers() async {
    _status = SuppliersViewStatus.loading;
    _errorMessage = null;
    _notifySafely();
    try {
      _suppliers = await _getSuppliers();
      _status = SuppliersViewStatus.ready;
    } catch (error) {
      _status = SuppliersViewStatus.failure;
      _errorMessage = _messageFor(error);
    }
    _notifySafely();
  }

  Future<bool> createSupplier(Supplier supplier) async {
    return _runMutation(() async {
      final created = await _createSupplier(supplier);
      _suppliers = [..._suppliers, created]..sort(_sortByName);
    });
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    return _runMutation(() async {
      final updated = await _updateSupplier(supplier);
      _suppliers =
          _suppliers
              .map((current) => current.id == updated.id ? updated : current)
              .toList()
            ..sort(_sortByName);
    });
  }

  Future<bool> deleteSupplier(String id) async {
    return _runMutation(() async {
      await _deleteSupplier(id);
      _suppliers = _suppliers.where((supplier) => supplier.id != id).toList();
    });
  }

  Future<bool> _runMutation(Future<void> Function() operation) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _operationError = null;
    _notifySafely();
    try {
      await operation();
      _status = SuppliersViewStatus.ready;
      return true;
    } catch (error) {
      _operationError = _messageFor(error);
      return false;
    } finally {
      _isSubmitting = false;
      _notifySafely();
    }
  }

  String _messageFor(Object error) {
    if (error is SupplierException) return error.message;
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }

  static int _sortByName(Supplier a, Supplier b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  void _notifySafely() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
