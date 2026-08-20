import '../../domain/entities/branch.dart';
import '../../domain/entities/product.dart';
import '../../domain/errors/branches_exception.dart';
import '../../domain/repositories/branches_repository.dart';
import '../../domain/validation/branch_validators.dart';
import '../../domain/validation/product_validators.dart';

class InMemoryBranchesRepository implements BranchesRepository {
  InMemoryBranchesRepository({
    List<Branch> initialBranches = const [],
    List<Product> initialProducts = const [],
    Map<String, Set<String>> initialAssignments = const {},
  }) : _branches = [...initialBranches],
       _products = [...initialProducts],
       _links = [
         for (final entry in initialAssignments.entries)
           for (final productId in entry.value)
             _BranchProductLink(branchId: entry.key, productId: productId),
       ];

  final List<Branch> _branches;
  final List<Product> _products;
  final List<_BranchProductLink> _links;

  @override
  Future<List<Branch>> getBranches() async {
    return _branches.where((branch) => branch.deletedAt == null).toList()
      ..sort(_sortBranches);
  }

  @override
  Future<Branch> createBranch(Branch branch) async {
    _validateBranch(branch);
    final now = DateTime.now();
    final created = _copyBranch(
      branch,
      id: 'local-branch-${now.microsecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );
    _branches.add(created);
    return created;
  }

  @override
  Future<Branch> updateBranch(Branch branch) async {
    final index = _activeBranchIndex(branch.id);
    if (index == -1) {
      throw const BranchesException(
        'La sucursal que intentas editar no existe.',
      );
    }
    _validateBranch(branch);
    final updated = _copyBranch(
      branch,
      createdAt: _branches[index].createdAt,
      updatedAt: DateTime.now(),
    );
    _branches[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteBranch(String id) async {
    final index = _activeBranchIndex(id);
    if (index == -1) {
      throw const BranchesException(
        'La sucursal que intentas eliminar no existe.',
      );
    }
    final now = DateTime.now();
    _branches[index] = _copyBranch(
      _branches[index],
      updatedAt: now,
      deletedAt: now,
    );
    _softDeleteLinks(now, branchId: id);
  }

  @override
  Future<List<Product>> getProducts() async {
    return _products.where((product) => product.deletedAt == null).toList()
      ..sort(_sortProducts);
  }

  @override
  Future<Product> createProduct(Product product) async {
    _validateProduct(product);
    _ensureUniqueSku(product.sku);
    final now = DateTime.now();
    final created = _copyProduct(
      product,
      id: 'local-product-${now.microsecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );
    _products.add(created);
    return created;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final index = _activeProductIndex(product.id);
    if (index == -1) {
      throw const BranchesException(
        'El producto que intentas editar no existe.',
      );
    }
    _validateProduct(product);
    _ensureUniqueSku(product.sku, exceptId: product.id);
    final updated = _copyProduct(
      product,
      createdAt: _products[index].createdAt,
      updatedAt: DateTime.now(),
    );
    _products[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String id) async {
    final index = _activeProductIndex(id);
    if (index == -1) {
      throw const BranchesException(
        'El producto que intentas eliminar no existe.',
      );
    }
    final now = DateTime.now();
    _products[index] = _copyProduct(
      _products[index],
      updatedAt: now,
      deletedAt: now,
    );
    _softDeleteLinks(now, productId: id);
  }

  @override
  Future<Set<String>> getBranchProductIds(String branchId) async {
    if (_activeBranchIndex(branchId) == -1) {
      throw const BranchesException('La sucursal seleccionada no existe.');
    }
    final activeProductIds = _products
        .where((product) => product.deletedAt == null)
        .map((product) => product.id)
        .toSet();
    return _links
        .where(
          (link) =>
              link.branchId == branchId &&
              link.deletedAt == null &&
              activeProductIds.contains(link.productId),
        )
        .map((link) => link.productId)
        .toSet();
  }

  @override
  Future<void> configureBranchProducts(
    String branchId,
    Set<String> productIds,
  ) async {
    if (_activeBranchIndex(branchId) == -1) {
      throw const BranchesException('La sucursal seleccionada no existe.');
    }
    final activeProductIds = _products
        .where((product) => product.deletedAt == null)
        .map((product) => product.id)
        .toSet();
    if (!activeProductIds.containsAll(productIds)) {
      throw const BranchesException(
        'Uno de los productos ya no está disponible.',
      );
    }

    final now = DateTime.now();
    for (var index = 0; index < _links.length; index++) {
      final link = _links[index];
      if (link.branchId == branchId &&
          link.deletedAt == null &&
          !productIds.contains(link.productId)) {
        _links[index] = link.copyWith(deletedAt: now);
      }
    }

    final currentlyActive = _links
        .where((link) => link.branchId == branchId && link.deletedAt == null)
        .map((link) => link.productId)
        .toSet();
    for (final productId in productIds.difference(currentlyActive)) {
      _links.add(_BranchProductLink(branchId: branchId, productId: productId));
    }
  }

  int _activeBranchIndex(String id) => _branches.indexWhere(
    (branch) => branch.id == id && branch.deletedAt == null,
  );

  int _activeProductIndex(String id) => _products.indexWhere(
    (product) => product.id == id && product.deletedAt == null,
  );

  void _validateBranch(Branch branch) {
    final error =
        BranchValidators.name(branch.name) ??
        BranchValidators.businessName(branch.businessName) ??
        BranchValidators.address(branch.address) ??
        BranchValidators.latitude(branch.latitude.toString()) ??
        BranchValidators.longitude(branch.longitude.toString());
    if (error != null) throw BranchesException(error);
  }

  void _validateProduct(Product product) {
    final error =
        ProductValidators.name(product.name) ??
        ProductValidators.sku(product.sku) ??
        ProductValidators.description(product.description) ??
        ProductValidators.basePrice(product.basePrice.toString());
    if (error != null) throw BranchesException(error);
  }

  void _ensureUniqueSku(String sku, {String? exceptId}) {
    final normalized = ProductValidators.normalizeSku(sku);
    final exists = _products.any(
      (product) =>
          product.deletedAt == null &&
          product.id != exceptId &&
          ProductValidators.normalizeSku(product.sku) == normalized,
    );
    if (exists) {
      throw const BranchesException(
        'Ya existe un producto activo con ese SKU.',
      );
    }
  }

  void _softDeleteLinks(
    DateTime deletedAt, {
    String? branchId,
    String? productId,
  }) {
    for (var index = 0; index < _links.length; index++) {
      final link = _links[index];
      final matchesBranch = branchId == null || link.branchId == branchId;
      final matchesProduct = productId == null || link.productId == productId;
      if (link.deletedAt == null && matchesBranch && matchesProduct) {
        _links[index] = link.copyWith(deletedAt: deletedAt);
      }
    }
  }

  Branch _copyBranch(
    Branch branch, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Branch(
      id: id ?? branch.id,
      name: branch.name.trim(),
      businessName: branch.businessName.trim(),
      address: branch.address.trim(),
      latitude: branch.latitude,
      longitude: branch.longitude,
      createdAt: createdAt ?? branch.createdAt,
      updatedAt: updatedAt ?? branch.updatedAt,
      deletedAt: deletedAt ?? branch.deletedAt,
    );
  }

  Product _copyProduct(
    Product product, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Product(
      id: id ?? product.id,
      name: product.name.trim(),
      sku: ProductValidators.normalizeSku(product.sku),
      description: product.description.trim(),
      basePrice: product.basePrice,
      createdAt: createdAt ?? product.createdAt,
      updatedAt: updatedAt ?? product.updatedAt,
      deletedAt: deletedAt ?? product.deletedAt,
    );
  }

  static int _sortBranches(Branch a, Branch b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  static int _sortProducts(Product a, Product b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

class _BranchProductLink {
  const _BranchProductLink({
    required this.branchId,
    required this.productId,
    this.deletedAt,
  });

  final String branchId;
  final String productId;
  final DateTime? deletedAt;

  _BranchProductLink copyWith({DateTime? deletedAt}) {
    return _BranchProductLink(
      branchId: branchId,
      productId: productId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
