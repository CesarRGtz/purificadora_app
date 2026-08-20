import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/companies/domain/entities/company.dart';
import 'package:purificadora/features/companies/domain/errors/company_exception.dart';
import 'package:purificadora/features/companies/domain/repositories/company_repository.dart';
import 'package:purificadora/features/companies/domain/usecases/create_company.dart';
import 'package:purificadora/features/companies/domain/usecases/delete_company.dart';
import 'package:purificadora/features/companies/domain/usecases/get_companies.dart';
import 'package:purificadora/features/companies/domain/usecases/update_company.dart';
import 'package:purificadora/features/companies/presentation/controllers/companies_controller.dart';

void main() {
  late _FakeCompanyRepository repository;
  late CompaniesController controller;

  setUp(() {
    repository = _FakeCompanyRepository();
    controller = CompaniesController(
      getCompanies: GetCompanies(repository),
      createCompany: CreateCompany(repository),
      updateCompany: UpdateCompany(repository),
      deleteCompany: DeleteCompany(repository),
    );
  });

  tearDown(() => controller.dispose());

  test('carga las empresas desde el repositorio', () async {
    repository.storedCompanies.add(_company(id: '1'));

    await controller.loadCompanies();

    expect(controller.status, CompaniesViewStatus.ready);
    expect(controller.companies, hasLength(1));
    expect(controller.companies.single.businessName, 'Agua Clara');
  });

  test(
    'agrega y elimina una empresa manteniendo el estado sincronizado',
    () async {
      await controller.loadCompanies();
      final created = await controller.createCompany(_company());

      expect(created, isTrue);
      expect(controller.companies.single.id, 'generated-id');

      final deleted = await controller.deleteCompany('generated-id');
      expect(deleted, isTrue);
      expect(controller.companies, isEmpty);
    },
  );

  test('expone un error de dominio entendible para la interfaz', () async {
    repository.createError = const CompanyException(
      'Ya existe una empresa con ese RFC.',
    );
    await controller.loadCompanies();

    final created = await controller.createCompany(_company());

    expect(created, isFalse);
    expect(controller.operationError, 'Ya existe una empresa con ese RFC.');
  });
}

Company _company({String id = ''}) {
  return Company(
    id: id,
    businessName: 'Agua Clara',
    rfc: 'ACL123456AB1',
    address: 'Blvd. Principal 100',
    phone: '6621234567',
  );
}

class _FakeCompanyRepository implements CompanyRepository {
  final List<Company> storedCompanies = [];
  CompanyException? createError;

  @override
  Future<List<Company>> getCompanies() async => [...storedCompanies];

  @override
  Future<Company> createCompany(Company company) async {
    if (createError case final error?) throw error;
    final created = Company(
      id: 'generated-id',
      businessName: company.businessName,
      rfc: company.rfc,
      address: company.address,
      phone: company.phone,
    );
    storedCompanies.add(created);
    return created;
  }

  @override
  Future<Company> updateCompany(Company company) async {
    final index = storedCompanies.indexWhere((item) => item.id == company.id);
    storedCompanies[index] = company;
    return company;
  }

  @override
  Future<void> deleteCompany(String id) async {
    storedCompanies.removeWhere((company) => company.id == id);
  }
}
