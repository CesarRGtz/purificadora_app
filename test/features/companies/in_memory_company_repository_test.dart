import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/companies/data/repositories/in_memory_company_repository.dart';
import 'package:purificadora/features/companies/domain/entities/company.dart';
import 'package:purificadora/features/companies/domain/errors/company_exception.dart';

void main() {
  late InMemoryCompanyRepository repository;

  setUp(() {
    repository = InMemoryCompanyRepository();
  });

  test('permite probar el CRUD completo sin conexión', () async {
    final created = await repository.createCompany(_company());
    expect(created.id, startsWith('local-'));

    final updated = await repository.updateCompany(
      Company(
        id: created.id,
        businessName: 'Empresa Local Actualizada',
        rfc: created.rfc,
        address: created.address,
        phone: created.phone,
      ),
    );
    expect(updated.businessName, 'Empresa Local Actualizada');

    await repository.deleteCompany(created.id);
    expect(await repository.getCompanies(), isEmpty);
  });

  test('conserva la regla de RFC único en modo local', () async {
    await repository.createCompany(_company());

    expect(
      () => repository.createCompany(_company()),
      throwsA(
        isA<CompanyException>().having(
          (error) => error.message,
          'message',
          'Ya existe una empresa con ese RFC.',
        ),
      ),
    );
  });

  test('oculta empresas eliminadas y permite reutilizar su RFC', () async {
    final created = await repository.createCompany(_company());
    await repository.deleteCompany(created.id);

    expect(await repository.getCompanies(), isEmpty);
    final recreated = await repository.createCompany(_company());
    expect(recreated.rfc, created.rfc);
    expect(await repository.getCompanies(), hasLength(1));
  });
}

Company _company() {
  return const Company(
    businessName: 'Empresa Local',
    rfc: 'ELO260819AB1',
    address: 'Blvd. Principal 100',
    phone: '6621234567',
  );
}
