import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/branches/domain/validation/branch_validators.dart';
import 'package:purificadora/features/branches/domain/validation/product_validators.dart';

void main() {
  group('BranchValidators', () {
    test('acepta coordenadas dentro de sus rangos', () {
      expect(BranchValidators.latitude('29.072967'), isNull);
      expect(BranchValidators.longitude('-110.955919'), isNull);
    });

    test('rechaza coordenadas fuera de rango o no finitas', () {
      expect(BranchValidators.latitude('91'), isNotNull);
      expect(BranchValidators.longitude('-181'), isNotNull);
      expect(BranchValidators.latitude('NaN'), isNotNull);
      expect(BranchValidators.longitude('Infinity'), isNotNull);
    });
  });

  group('ProductValidators', () {
    test('normaliza y valida el SKU', () {
      expect(ProductValidators.normalizeSku(' agua-20l '), 'AGUA-20L');
      expect(ProductValidators.sku('AGUA-20L'), isNull);
      expect(ProductValidators.sku('sku inválido'), isNotNull);
    });

    test('rechaza precios negativos o no finitos', () {
      expect(ProductValidators.basePrice('45.50'), isNull);
      expect(ProductValidators.basePrice('-1'), isNotNull);
      expect(ProductValidators.basePrice('NaN'), isNotNull);
    });
  });
}
