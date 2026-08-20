import 'package:supabase_flutter/supabase_flutter.dart';

/// Centraliza la configuración de Supabase sin guardar secretos en el código.
abstract final class SupabaseConfig {
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static Object? _initializationError;
  static bool _isReady = false;

  static bool get hasCredentials =>
      _url.isNotEmpty && _publishableKey.isNotEmpty;
  static bool get isReady => _isReady;
  static Object? get initializationError => _initializationError;

  static Future<void> initialize() async {
    if (!hasCredentials) return;

    try {
      await Supabase.initialize(url: _url, publishableKey: _publishableKey);
      _isReady = true;
    } catch (error) {
      _initializationError = error;
    }
  }
}
