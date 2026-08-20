import 'package:flutter/material.dart';

class CompaniesSetupPage extends StatelessWidget {
  const CompaniesSetupPage({
    super.key,
    required this.initializationFailed,
    required this.onTryOffline,
  });

  final bool initializationFailed;
  final VoidCallback onTryOffline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Empresas',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B528A),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  initializationFailed
                      ? Icons.error_outline
                      : Icons.settings_ethernet,
                  size: 42,
                  color: initializationFailed
                      ? Colors.redAccent
                      : const Color(0xFF2B528A),
                ),
                const SizedBox(height: 16),
                Text(
                  initializationFailed
                      ? 'No se pudo iniciar la conexión con Supabase'
                      : 'Configura la conexión con Supabase',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Aplica la migración incluida en supabase/migrations y ejecuta la app con SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY mediante --dart-define.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SelectableText(
                    'flutter run --dart-define=SUPABASE_URL=https://<proyecto>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 18),
                Text(
                  '¿Solo quieres revisar y probar el apartado?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Puedes usar datos temporales sin conectarte. Nada de lo que registres en este modo se enviará a Supabase.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onTryOffline,
                  icon: const Icon(Icons.wifi_off_outlined),
                  label: const Text('Probar sin conexión'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
