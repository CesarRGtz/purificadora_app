abstract final class SupplierValidators {
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{10,15}$');

  static String? branchName(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'La sucursal es obligatoria';
    if (normalized.length < 2) return 'Ingresa una sucursal válida';
    if (normalized.length > 150) return 'Máximo 150 caracteres';
    return null;
  }

  static String? name(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'El nombre es obligatorio';
    if (normalized.length < 2) return 'Ingresa al menos 2 caracteres';
    if (normalized.length > 200) return 'Máximo 200 caracteres';
    return null;
  }

  static String? address(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'La dirección es obligatoria';
    if (normalized.length < 5) return 'Ingresa una dirección válida';
    if (normalized.length > 500) return 'Máximo 500 caracteres';
    return null;
  }

  static String? phone(String? value) {
    final normalized = normalizePhone(value ?? '');
    if (normalized.isEmpty) return 'El teléfono es obligatorio';
    if (!_phonePattern.hasMatch(normalized)) {
      return 'Ingresa entre 10 y 15 dígitos';
    }
    return null;
  }

  static String normalizePhone(String value) {
    final trimmed = value.trim();
    final hasInternationalPrefix = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return hasInternationalPrefix ? '+$digits' : digits;
  }
}
