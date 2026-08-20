import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/branch.dart';
import '../../domain/entities/product.dart';
import '../models/branch_model.dart';
import '../models/product_model.dart';

abstract interface class BranchesRemoteDataSource {
  Future<List<BranchModel>> getBranches();
  Future<BranchModel> createBranch(Branch branch);
  Future<BranchModel> updateBranch(Branch branch);
  Future<void> deleteBranch(String id);

  Future<List<ProductModel>> getProducts();
  Future<ProductModel> createProduct(Product product);
  Future<ProductModel> updateProduct(Product product);
  Future<void> deleteProduct(String id);

  Future<Set<String>> getBranchProductIds(String branchId);
  Future<void> configureBranchProducts(String branchId, Set<String> productIds);
}

class SupabaseBranchesRemoteDataSource implements BranchesRemoteDataSource {
  SupabaseBranchesRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<BranchModel>> getBranches() async {
    final response = await _client
        .from('branches')
        .select()
        .isFilter('deleted_at', null)
        .order('name');
    return response
        .map((row) => BranchModel.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<BranchModel> createBranch(Branch branch) async {
    final response = await _client
        .from('branches')
        .insert(BranchModel.toInsertJson(branch))
        .select()
        .single();
    return BranchModel.fromJson(response);
  }

  @override
  Future<BranchModel> updateBranch(Branch branch) async {
    final response = await _client
        .from('branches')
        .update(BranchModel.toUpdateJson(branch))
        .eq('id', branch.id)
        .isFilter('deleted_at', null)
        .select()
        .single();
    return BranchModel.fromJson(response);
  }

  @override
  Future<void> deleteBranch(String id) async {
    await _client.rpc('soft_delete_branch', params: {'p_id': id});
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await _client
        .from('products')
        .select()
        .isFilter('deleted_at', null)
        .order('name');
    return response
        .map((row) => ProductModel.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<ProductModel> createProduct(Product product) async {
    final response = await _client
        .from('products')
        .insert(ProductModel.toInsertJson(product))
        .select()
        .single();
    return ProductModel.fromJson(response);
  }

  @override
  Future<ProductModel> updateProduct(Product product) async {
    final response = await _client
        .from('products')
        .update(ProductModel.toUpdateJson(product))
        .eq('id', product.id)
        .isFilter('deleted_at', null)
        .select()
        .single();
    return ProductModel.fromJson(response);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client.rpc('soft_delete_product', params: {'p_id': id});
  }

  @override
  Future<Set<String>> getBranchProductIds(String branchId) async {
    final response = await _client
        .from('branch_products')
        .select('product_id')
        .eq('branch_id', branchId)
        .isFilter('deleted_at', null);
    return response.map((row) => row['product_id'] as String).toSet();
  }

  @override
  Future<void> configureBranchProducts(
    String branchId,
    Set<String> productIds,
  ) async {
    await _client.rpc(
      'configure_branch_products',
      params: {
        'p_branch_id': branchId,
        'p_product_ids': productIds.toList(growable: false),
      },
    );
  }
}
