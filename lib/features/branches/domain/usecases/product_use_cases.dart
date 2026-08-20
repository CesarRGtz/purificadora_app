import '../entities/product.dart';
import '../repositories/branches_repository.dart';

class GetProducts {
  const GetProducts(this._repository);
  final BranchesRepository _repository;
  Future<List<Product>> call() => _repository.getProducts();
}

class CreateProduct {
  const CreateProduct(this._repository);
  final BranchesRepository _repository;
  Future<Product> call(Product product) => _repository.createProduct(product);
}

class UpdateProduct {
  const UpdateProduct(this._repository);
  final BranchesRepository _repository;
  Future<Product> call(Product product) => _repository.updateProduct(product);
}

class DeleteProduct {
  const DeleteProduct(this._repository);
  final BranchesRepository _repository;
  Future<void> call(String id) => _repository.deleteProduct(id);
}

class GetBranchProductIds {
  const GetBranchProductIds(this._repository);
  final BranchesRepository _repository;
  Future<Set<String>> call(String branchId) =>
      _repository.getBranchProductIds(branchId);
}

class ConfigureBranchProducts {
  const ConfigureBranchProducts(this._repository);
  final BranchesRepository _repository;
  Future<void> call(String branchId, Set<String> productIds) =>
      _repository.configureBranchProducts(branchId, productIds);
}
