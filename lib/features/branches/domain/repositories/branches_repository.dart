import '../entities/branch.dart';
import '../entities/product.dart';

abstract interface class BranchesRepository {
  Future<List<Branch>> getBranches();
  Future<Branch> createBranch(Branch branch);
  Future<Branch> updateBranch(Branch branch);
  Future<void> deleteBranch(String id);

  Future<List<Product>> getProducts();
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(String id);

  Future<Set<String>> getBranchProductIds(String branchId);
  Future<void> configureBranchProducts(String branchId, Set<String> productIds);
}
