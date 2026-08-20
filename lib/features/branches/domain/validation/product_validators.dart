abstract final class ProductValidators {
  static final RegExp _skuPattern = RegExp(r'^[A-Z0-9][A-Z0-9._-]{1,49}$');

  static String? name(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'El nombre es obligatorio';
    if (normalized.length < 2) return 'Ingresa al menos 2 caracteres';
    if (normalized.length > 200) return 'Máximo 200 caracteres';
    return null;
  }

  static String? sku(String? value) {
    final normalized = normalizeSku(value ?? '');
    if (normalized.isEmpty) return 'El SKU es obligatorio';
    if (!_skuPattern.hasMatch(normalized)) {
      return 'Usa de 2 a 50 letras, números, puntos, guiones o guion bajo';
    }
    return null;
  }

  static String? description(String? value) {
    if ((value ?? '').trim().length > 500) return 'Máximo 500 caracteres';
    return null;
  }

  static String? basePrice(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || !number.isFinite) return 'Ingresa un precio válido';
    if (number < 0) return 'El precio no puede ser negativo';
    if (number > 9999999999.99) return 'El precio excede el máximo permitido';
    return null;
  }

  static String normalizeSku(String value) => value.trim().toUpperCase();
}
