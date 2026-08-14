import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/glass_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catálogos y Administración Central',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2B528A),
            ),
          ),
          const SizedBox(height: 24),
          
          // Grid para mostrar los diferentes catálogos
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildCatalogCard(
                    context,
                    title: 'Sucursales',
                    count: state.branches.length,
                    icon: Icons.store_outlined,
                    color: Colors.blue,
                  ),
                  _buildCatalogCard(
                    context,
                    title: 'Proveedores',
                    count: state.suppliers.length,
                    icon: Icons.local_shipping_outlined,
                    color: Colors.orange,
                  ),
                  _buildCatalogCard(
                    context,
                    title: 'Vehículos',
                    count: state.vehicles.length,
                    icon: Icons.directions_car_outlined,
                    color: Colors.purple,
                  ),
                  _buildCatalogCard(
                    context,
                    title: 'Clientes',
                    count: state.clients.length,
                    icon: Icons.people_outline,
                    color: Colors.green,
                  ),
                  _buildCatalogCard(
                    context,
                    title: 'Activos (Consignas)',
                    count: state.assets.length,
                    icon: Icons.category_outlined,
                    color: Colors.redAccent,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          Text(
            'Vista Previa: Sucursales',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2B528A),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.branches.length,
              separatorBuilder: (_, __) => Divider(color: Colors.grey.withOpacity(0.2)),
              itemBuilder: (context, index) {
                final branch = state.branches[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0277BD),
                    child: Icon(Icons.store, color: Colors.white, size: 20),
                  ),
                  title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  subtitle: Text('${branch.address} • ${branch.phone}', style: const TextStyle(color: Colors.black54)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF0277BD)),
                    onPressed: () {
                      // TODO: Implementar edición
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCatalogCard(BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      child: InkWell(
        onTap: () {
          // TODO: Navegar al detalle del catálogo
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey.withOpacity(0.5), size: 16),
                ],
              ),
              const Spacer(),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
