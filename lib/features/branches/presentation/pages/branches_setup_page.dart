import 'package:flutter/material.dart';

class BranchesSetupPage extends StatelessWidget {
  const BranchesSetupPage({
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
          'Sucursales',
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
                  'Aplica las migraciones de supabase/migrations para habilitar sucursales, productos y su configuración independiente.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 18),
                const Text(
                  'Puedes probar el CRUD completo y la asignación de productos con datos temporales.',
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
