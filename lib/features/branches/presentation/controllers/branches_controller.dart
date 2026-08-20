import 'package:flutter/foundation.dart';

import '../../domain/entities/branch.dart';
import '../../domain/entities/product.dart';
import '../../domain/errors/branches_exception.dart';
import '../../domain/usecases/branch_use_cases.dart';
import '../../domain/usecases/product_use_cases.dart';

enum BranchesViewStatus { initial, loading, ready, failure }

class BranchesController extends ChangeNotifier {
  BranchesController({
    required GetBranches getBranches,
    required CreateBranch createBranch,
    required UpdateBranch updateBranch,
    required DeleteBranch deleteBranch,
    required GetProducts getProducts,
    required CreateProduct createProduct,
    required UpdateProduct updateProduct,
    required DeleteProduct deleteProduct,
    required GetBranchProductIds getBranchProductIds,
    required ConfigureBranchProducts configureBranchProducts,
  }) : _getBranches = getBranches,
       _createBranch = createBranch,
       _updateBranch = updateBranch,
       _deleteBranch = deleteBranch,
       _getProducts = getProducts,
       _createProduct = createProduct,
       _updateProduct = updateProduct,
       _deleteProduct = deleteProduct,
       _getBranchProductIds = getBranchProductIds,
       _configureBranchProducts = configureBranchProducts;

  final GetBranches _getBranches;
  final CreateBranch _createBranch;
  final UpdateBranch _updateBranch;
  final DeleteBranch _deleteBranch;
  final GetProducts _getProducts;
  final CreateProduct _createProduct;
  final UpdateProduct _updateProduct;
  final DeleteProduct _deleteProduct;
  final GetBranchProductIds _getBranchProductIds;
  final ConfigureBranchProducts _configureBranchProducts;

  BranchesViewStatus _status = BranchesViewStatus.initial;
  List<Branch> _branches = const [];
  List<Product> _products = const [];
  Set<String> _selectedProductIds = const {};
  String? _errorMessage;
  String? _productsError;
  String? _operationError;
  bool _isProductsLoading = false;
  bool _isSubmitting = false;
  bool _isDisposed = false;

  BranchesViewStatus get status => _status;
  List<Branch> get branches => List.unmodifiable(_branches);
  List<Product> get products => List.unmodifiable(_products);
  Set<String> get selectedProductIds => Set.unmodifiable(_selectedProductIds);
  String? get errorMessage => _errorMessage;
  String? get productsError => _productsError;
  String? get operationError => _operationError;
  bool get isProductsLoading => _isProductsLoading;
  bool get isSubmitting => _isSubmitting;

  Future<void> loadBranches() async {
    _status = BranchesViewStatus.loading;
    _errorMessage = null;
    _notifySafely();
    try {
      _branches = await _getBranches();
      _status = BranchesViewStatus.ready;
    } catch (error) {
      _status = BranchesViewStatus.failure;
      _errorMessage = _messageFor(error);
    }
    _notifySafely();
  }

  Future<bool> createBranch(Branch branch) async {
    return _runMutation(() async {
      final created = await _createBranch(branch);
      _branches = [..._branches, created]..sort(_sortBranches);
    });
  }

  Future<bool> updateBranch(Branch branch) async {
    return _runMutation(() async {
      final updated = await _updateBranch(branch);
      _branches =
          _branches
              .map((current) => current.id == updated.id ? updated : current)
              .toList()
            ..sort(_sortBranches);
    });
  }

  Future<bool> deleteBranch(String id) async {
    return _runMutation(() async {
      await _deleteBranch(id);
      _branches = _branches.where((branch) => branch.id != id).toList();
    });
  }

  Future<bool> loadProducts() async {
    if (_isProductsLoading) return false;
    _isProductsLoading = true;
    _productsError = null;
    _notifySafely();
    try {
      _products = await _getProducts();
      return true;
    } catch (error) {
      _productsError = _messageFor(error);
      return false;
    } finally {
      _isProductsLoading = false;
      _notifySafely();
    }
  }

  Future<bool> loadProductConfiguration(String branchId) async {
    if (_isProductsLoading) return false;
    _isProductsLoading = true;
    _productsError = null;
    _selectedProductIds = const {};
    _notifySafely();
    try {
      _products = await _getProducts();
      _selectedProductIds = await _getBranchProductIds(branchId);
      return true;
    } catch (error) {
      _productsError = _messageFor(error);
      return false;
    } finally {
      _isProductsLoading = false;
      _notifySafely();
    }
  }

  Future<bool> createProduct(Product product) async {
    return _runMutation(() async {
      final created = await _createProduct(product);
      _products = [..._products, created]..sort(_sortProducts);
    });
  }

  Future<bool> updateProduct(Product product) async {
    return _runMutation(() async {
      final updated = await _updateProduct(product);
      _products =
          _products
              .map((current) => current.id == updated.id ? updated : current)
              .toList()
            ..sort(_sortProducts);
    });
  }

  Future<bool> deleteProduct(String id) async {
    return _runMutation(() async {
      await _deleteProduct(id);
      _products = _products.where((product) => product.id != id).toList();
      _selectedProductIds = {..._selectedProductIds}..remove(id);
    });
  }

  Future<bool> saveProductConfiguration(
    String branchId,
    Set<String> productIds,
  ) async {
    return _runMutation(() async {
      await _configureBranchProducts(branchId, productIds);
      _selectedProductIds = {...productIds};
    });
  }

  Future<bool> _runMutation(Future<void> Function() operation) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _operationError = null;
    _notifySafely();
    try {
      await operation();
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
    if (error is BranchesException) return error.message;
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }

  static int _sortBranches(Branch a, Branch b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  static int _sortProducts(Product a, Product b) =>
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
