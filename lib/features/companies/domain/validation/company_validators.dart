abstract final class CompanyValidators {
  static final RegExp _rfcPattern = RegExp(
    r'^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$',
  );
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{10,15}$');

  static String? businessName(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'La razón social es obligatoria';
    if (normalized.length < 3) return 'Ingresa al menos 3 caracteres';
    if (normalized.length > 200) return 'Máximo 200 caracteres';
    return null;
  }

  static String? rfc(String? value) {
    final normalized = normalizeRfc(value ?? '');
    if (normalized.isEmpty) return 'El RFC es obligatorio';
    if (!_rfcPattern.hasMatch(normalized)) {
      return 'Ingresa un RFC válido de 12 o 13 caracteres';
    }
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

  static String normalizeRfc(String value) => value.trim().toUpperCase();

  static String normalizePhone(String value) {
    final trimmed = value.trim();
    final hasInternationalPrefix = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return hasInternationalPrefix ? '+$digits' : digits;
  }
}
