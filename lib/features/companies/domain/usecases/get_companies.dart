import '../entities/company.dart';
import '../repositories/company_repository.dart';

class GetCompanies {
  const GetCompanies(this._repository);

  final CompanyRepository _repository;

  Future<List<Company>> call() => _repository.getCompanies();
}
