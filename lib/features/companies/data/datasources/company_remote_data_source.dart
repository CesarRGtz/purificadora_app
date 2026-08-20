import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/company.dart';
import '../models/company_model.dart';

abstract interface class CompanyRemoteDataSource {
  Future<List<CompanyModel>> getCompanies();
  Future<CompanyModel> createCompany(Company company);
  Future<CompanyModel> updateCompany(Company company);
  Future<void> deleteCompany(String id);
}

class SupabaseCompanyRemoteDataSource implements CompanyRemoteDataSource {
  SupabaseCompanyRemoteDataSource(this._client);

  static const String _table = 'companies';
  final SupabaseClient _client;

  @override
  Future<List<CompanyModel>> getCompanies() async {
    final response = await _client
        .from(_table)
        .select()
        .isFilter('deleted_at', null)
        .order('business_name');

    return response
        .map((row) => CompanyModel.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<CompanyModel> createCompany(Company company) async {
    final response = await _client
        .from(_table)
        .insert(CompanyModel.toInsertJson(company))
        .select()
        .single();
    return CompanyModel.fromJson(response);
  }

  @override
  Future<CompanyModel> updateCompany(Company company) async {
    final response = await _client
        .from(_table)
        .update(CompanyModel.toUpdateJson(company))
        .eq('id', company.id)
        .select()
        .single();
    return CompanyModel.fromJson(response);
  }

  @override
  Future<void> deleteCompany(String id) async {
    await _client
        .from(_table)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .isFilter('deleted_at', null);
  }
}
