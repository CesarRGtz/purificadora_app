abstract final class InventoryValidators {
  static String? name(String? value) =>
      requiredText(value, label: 'El nombre', minLength: 2, maxLength: 200);

  static String? type(String? value) =>
      requiredText(value, label: 'El tipo', minLength: 2, maxLength: 100);

  static String? category(String? value) =>
      requiredText(value, label: 'La categoría', minLength: 2, maxLength: 100);

  static String? unit(String? value) =>
      requiredText(value, label: 'La unidad', minLength: 1, maxLength: 50);

  static String? branchId(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Selecciona una sucursal';
    }
    return null;
  }

  static String? nonNegativeDecimal(
    String? value, {
    String label = 'El valor',
  }) {
    final number = tryParseDecimal(value);
    if (number == null || !number.isFinite) {
      return '$label debe ser válido';
    }
    if (number < 0) {
      return '$label no puede ser negativo';
    }
    return null;
  }

  static String? positiveDecimal(
    String? value, {
    String label = 'La cantidad',
  }) {
    final error = nonNegativeDecimal(value, label: label);
    if (error != null) {
      return error;
    }
    if (parseDecimal(value!) <= 0) {
      return '$label debe ser mayor que cero';
    }
    return null;
  }

  static String? inventoryQuantity(
    String? value, {
    String label = 'La cantidad',
  }) {
    final error = positiveDecimal(value, label: label);
    if (error != null) return error;
    final number = parseDecimal(value!);
    if (!_hasAllowedScale(value, 3) || !fitsInventoryQuantity(number)) {
      return '$label admite hasta 3 decimales y un máximo de 99,999,999,999.999';
    }
    return null;
  }

  static String? unitCost(String? value, {String label = 'El costo'}) {
    final error = nonNegativeDecimal(value, label: label);
    if (error != null) return error;
    final number = parseDecimal(value!);
    if (!_hasAllowedScale(value, 4) || !fitsUnitCost(number)) {
      return '$label admite hasta 4 decimales y un máximo de 9,999,999,999.9999';
    }
    return null;
  }

  static String? nonNegativeInteger(
    String? value, {
    String label = 'La cantidad',
  }) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null) {
      return '$label debe ser un número entero válido';
    }
    if (number < 0) {
      return '$label no puede ser negativa';
    }
    return null;
  }

  static String? positiveInteger(
    String? value, {
    String label = 'La cantidad',
  }) {
    final error = nonNegativeInteger(value, label: label);
    if (error != null) {
      return error;
    }
    if (int.parse(value!.trim()) == 0) {
      return '$label debe ser mayor que cero';
    }
    return null;
  }

  static String? requiredText(
    String? value, {
    required String label,
    required int minLength,
    required int maxLength,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '$label es obligatorio';
    }
    if (normalized.length < minLength) {
      return 'Ingresa un valor válido';
    }
    if (normalized.length > maxLength) {
      return 'Máximo $maxLength caracteres';
    }
    return null;
  }

  static bool isNonNegativeFinite(num value) => value.isFinite && value >= 0;
  static bool isPositiveFinite(num value) => value.isFinite && value > 0;

  static double? tryParseDecimal(String? value) {
    final normalized = _normalizeDecimal(value ?? '');
    return double.tryParse(normalized);
  }

  static double parseDecimal(String value) =>
      double.parse(_normalizeDecimal(value));

  static bool fitsInventoryQuantity(num value) =>
      isPositiveFinite(value) &&
      value <= 99999999999.999 &&
      _fitsScale(value.toDouble(), 3);

  static bool fitsUnitCost(num value) =>
      isNonNegativeFinite(value) &&
      value <= 9999999999.9999 &&
      _fitsScale(value.toDouble(), 4);

  static bool _fitsScale(double value, int scale) {
    final rounded = double.parse(value.toStringAsFixed(scale));
    return rounded == value;
  }

  static bool _hasAllowedScale(String value, int scale) {
    final normalized = _normalizeDecimal(
      value,
    ).replaceFirst(RegExp(r'^\+'), '');
    final decimalIndex = normalized.indexOf('.');
    if (decimalIndex == -1) return true;
    final decimals = normalized
        .substring(decimalIndex + 1)
        .replaceFirst(RegExp(r'0+$'), '');
    return decimals.length <= scale;
  }

  static String _normalizeDecimal(String value) {
    final normalized = value.trim();
    if (normalized.contains('.') && normalized.contains(',')) {
      return normalized;
    }
    return normalized.replaceAll(',', '.');
  }
}
