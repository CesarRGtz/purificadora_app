abstract final class BranchValidators {
  static String? name(String? value) =>
      _requiredText(value, label: 'La sucursal', minLength: 2, maxLength: 150);

  static String? businessName(String? value) =>
      _requiredText(value, label: 'El negocio', minLength: 2, maxLength: 200);

  static String? address(String? value) =>
      _requiredText(value, label: 'La dirección', minLength: 5, maxLength: 500);

  static String? latitude(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || !number.isFinite) return 'Ingresa una latitud válida';
    if (number < -90 || number > 90) {
      return 'La latitud debe estar entre -90 y 90';
    }
    return null;
  }

  static String? longitude(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || !number.isFinite) {
      return 'Ingresa una longitud válida';
    }
    if (number < -180 || number > 180) {
      return 'La longitud debe estar entre -180 y 180';
    }
    return null;
  }

  static String? _requiredText(
    String? value, {
    required String label,
    required int minLength,
    required int maxLength,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return '$label es obligatorio';
    if (normalized.length < minLength) return 'Ingresa un valor válido';
    if (normalized.length > maxLength) return 'Máximo $maxLength caracteres';
    return null;
  }
}
