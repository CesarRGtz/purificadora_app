import '../entities/company.dart';

abstract interface class CompanyRepository {
  Future<List<Company>> getCompanies();

  Future<Company> createCompany(Company company);

  Future<Company> updateCompany(Company company);

  Future<void> deleteCompany(String id);
}
