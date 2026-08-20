import '../entities/company.dart';
import '../repositories/company_repository.dart';

class UpdateCompany {
  const UpdateCompany(this._repository);

  final CompanyRepository _repository;

  Future<Company> call(Company company) => _repository.updateCompany(company);
}
