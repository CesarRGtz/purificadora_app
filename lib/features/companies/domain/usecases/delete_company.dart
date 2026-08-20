import '../repositories/company_repository.dart';

class DeleteCompany {
  const DeleteCompany(this._repository);

  final CompanyRepository _repository;

  Future<void> call(String id) => _repository.deleteCompany(id);
}
