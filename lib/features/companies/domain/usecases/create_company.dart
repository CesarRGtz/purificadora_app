import '../entities/company.dart';
import '../repositories/company_repository.dart';

class CreateCompany {
  const CreateCompany(this._repository);

  final CompanyRepository _repository;

  Future<Company> call(Company company) => _repository.createCompany(company);
}
