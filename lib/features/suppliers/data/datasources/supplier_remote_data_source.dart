import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/supplier.dart';
import '../models/supplier_model.dart';

abstract interface class SupplierRemoteDataSource {
  Future<List<SupplierModel>> getSuppliers();
  Future<SupplierModel> createSupplier(Supplier supplier);
  Future<SupplierModel> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
}

class SupabaseSupplierRemoteDataSource implements SupplierRemoteDataSource {
  SupabaseSupplierRemoteDataSource(this._client);

  static const String _table = 'suppliers';
  final SupabaseClient _client;

  @override
  Future<List<SupplierModel>> getSuppliers() async {
    final response = await _client
        .from(_table)
        .select()
        .isFilter('deleted_at', null)
        .order('name');

    return response
        .map((row) => SupplierModel.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<SupplierModel> createSupplier(Supplier supplier) async {
    final response = await _client
        .from(_table)
        .insert(SupplierModel.toInsertJson(supplier))
        .select()
        .single();
    return SupplierModel.fromJson(response);
  }

  @override
  Future<SupplierModel> updateSupplier(Supplier supplier) async {
    final response = await _client
        .from(_table)
        .update(SupplierModel.toUpdateJson(supplier))
        .eq('id', supplier.id)
        .isFilter('deleted_at', null)
        .select()
        .single();
    return SupplierModel.fromJson(response);
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await _client
        .from(_table)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .isFilter('deleted_at', null);
  }
}
