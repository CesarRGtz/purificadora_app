import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/company.dart';
import '../../domain/errors/company_exception.dart';
import '../../domain/repositories/company_repository.dart';
import '../datasources/company_remote_data_source.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  const CompanyRepositoryImpl(this._remoteDataSource);

  final CompanyRemoteDataSource _remoteDataSource;

  @override
  Future<List<Company>> getCompanies() => _guard(
    _remoteDataSource.getCompanies,
    fallbackMessage: 'No fue posible cargar las empresas.',
  );

  @override
  Future<Company> createCompany(Company company) => _guard(
    () => _remoteDataSource.createCompany(company),
    fallbackMessage: 'No fue posible registrar la empresa.',
  );

  @override
  Future<Company> updateCompany(Company company) => _guard(
    () => _remoteDataSource.updateCompany(company),
    fallbackMessage: 'No fue posible actualizar la empresa.',
  );

  @override
  Future<void> deleteCompany(String id) => _guard(
    () => _remoteDataSource.deleteCompany(id),
    fallbackMessage: 'No fue posible eliminar la empresa.',
  );

  Future<T> _guard<T>(
    Future<T> Function() operation, {
    required String fallbackMessage,
  }) async {
    try {
      return await operation();
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const CompanyException('Ya existe una empresa con ese RFC.');
      }
      if (error.code == '42501') {
        throw const CompanyException(
          'Tu usuario no tiene permisos para realizar esta acción.',
        );
      }
      throw CompanyException(fallbackMessage);
    } catch (_) {
      throw CompanyException(fallbackMessage);
    }
  }
}
