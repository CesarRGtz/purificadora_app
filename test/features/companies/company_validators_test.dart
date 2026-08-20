import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/companies/domain/validation/company_validators.dart';

void main() {
  group('CompanyValidators', () {
    test('acepta RFC de persona moral y física', () {
      expect(CompanyValidators.rfc('ABC123456XYZ'), isNull);
      expect(CompanyValidators.rfc('GODE561231GR8'), isNull);
    });

    test('rechaza un RFC con formato inválido', () {
      expect(CompanyValidators.rfc('RFC-INVALIDO'), isNotNull);
    });

    test('normaliza RFC y teléfono antes de persistir', () {
      expect(CompanyValidators.normalizeRfc(' abc123456xyz '), 'ABC123456XYZ');
      expect(
        CompanyValidators.normalizePhone('+52 (662) 123-4567'),
        '+526621234567',
      );
    });
  });
}
