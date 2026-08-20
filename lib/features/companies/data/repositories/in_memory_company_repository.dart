import '../../domain/entities/company.dart';
import '../../domain/errors/company_exception.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/validation/company_validators.dart';

/// Repositorio temporal para probar el feature sin una conexión externa.
/// Los datos viven únicamente durante la ejecución actual de la aplicación.
class InMemoryCompanyRepository implements CompanyRepository {
  InMemoryCompanyRepository({List<Company> initialCompanies = const []})
    : _companies = [...initialCompanies];

  final List<Company> _companies;

  @override
  Future<List<Company>> getCompanies() async {
    return _companies.where((company) => company.deletedAt == null).toList()
      ..sort(_sortByBusinessName);
  }

  @override
  Future<Company> createCompany(Company company) async {
    _validate(company);
    _ensureUniqueRfc(company.rfc);

    final now = DateTime.now();
    final created = _normalizedCopy(
      company,
      id: 'local-${now.microsecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );
    _companies.add(created);
    return created;
  }

  @override
  Future<Company> updateCompany(Company company) async {
    final index = _companies.indexWhere(
      (current) => current.id == company.id && current.deletedAt == null,
    );
    if (index == -1) {
      throw const CompanyException('La empresa que intentas editar no existe.');
    }

    _validate(company);
    _ensureUniqueRfc(company.rfc, exceptId: company.id);
    final updated = _normalizedCopy(
      company,
      createdAt: _companies[index].createdAt,
      updatedAt: DateTime.now(),
    );
    _companies[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCompany(String id) async {
    final index = _companies.indexWhere(
      (company) => company.id == id && company.deletedAt == null,
    );
    if (index == -1) {
      throw const CompanyException(
        'La empresa que intentas eliminar no existe.',
      );
    }
    final current = _companies[index];
    _companies[index] = _normalizedCopy(
      current,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: DateTime.now(),
    );
  }

  void _validate(Company company) {
    final error =
        CompanyValidators.businessName(company.businessName) ??
        CompanyValidators.rfc(company.rfc) ??
        CompanyValidators.address(company.address) ??
        CompanyValidators.phone(company.phone);
    if (error != null) throw CompanyException(error);
  }

  void _ensureUniqueRfc(String rfc, {String? exceptId}) {
    final normalizedRfc = CompanyValidators.normalizeRfc(rfc);
    final isDuplicated = _companies.any(
      (company) =>
          company.deletedAt == null &&
          company.id != exceptId &&
          CompanyValidators.normalizeRfc(company.rfc) == normalizedRfc,
    );
    if (isDuplicated) {
      throw const CompanyException('Ya existe una empresa con ese RFC.');
    }
  }

  Company _normalizedCopy(
    Company company, {
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Company(
      id: id ?? company.id,
      businessName: company.businessName.trim(),
      rfc: CompanyValidators.normalizeRfc(company.rfc),
      address: company.address.trim(),
      phone: CompanyValidators.normalizePhone(company.phone),
      createdAt: createdAt ?? company.createdAt,
      updatedAt: updatedAt ?? company.updatedAt,
      deletedAt: deletedAt ?? company.deletedAt,
    );
  }

  static int _sortByBusinessName(Company a, Company b) =>
      a.businessName.toLowerCase().compareTo(b.businessName.toLowerCase());
}
