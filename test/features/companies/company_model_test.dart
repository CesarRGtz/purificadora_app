import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/companies/data/models/company_model.dart';
import 'package:purificadora/features/companies/domain/entities/company.dart';

void main() {
  test('convierte la respuesta de Supabase a una entidad', () {
    final model = CompanyModel.fromJson({
      'id': '9a18ad40-98cb-4529-9638-e94756e48930',
      'business_name': 'Agua Clara, S.A. de C.V.',
      'rfc': 'ACL123456AB1',
      'address': 'Blvd. Principal 100, Hermosillo, Sonora',
      'phone': '6621234567',
      'created_at': '2026-08-20T01:00:00.000Z',
      'updated_at': '2026-08-20T01:00:00.000Z',
    });

    expect(model.businessName, 'Agua Clara, S.A. de C.V.');
    expect(model.rfc, 'ACL123456AB1');
    expect(model.createdAt, DateTime.utc(2026, 8, 20, 1));
    expect(model.deletedAt, isNull);
  });

  test('solo envía campos editables a Supabase', () {
    const company = Company(
      id: 'existing-id',
      businessName: '  Agua Clara  ',
      rfc: ' acl123456ab1 ',
      address: '  Blvd. Principal 100  ',
      phone: '6621234567',
    );

    expect(CompanyModel.toUpdateJson(company), {
      'business_name': 'Agua Clara',
      'rfc': 'ACL123456AB1',
      'address': 'Blvd. Principal 100',
      'phone': '6621234567',
    });
  });
}
