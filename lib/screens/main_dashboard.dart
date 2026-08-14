import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'pos_screen.dart';
import 'production_screen.dart';
import 'logistics_screen.dart';
import 'inventory_screen.dart';
import 'admin_dashboard.dart';
import 'reports_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.admin_panel_settings_outlined, selectedIcon: Icons.admin_panel_settings, label: 'Admin'),
    _NavItem(icon: Icons.point_of_sale_outlined, selectedIcon: Icons.point_of_sale, label: 'POS'),
    _NavItem(icon: Icons.water_drop_outlined, selectedIcon: Icons.water_drop, label: 'Producción'),
    _NavItem(icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping, label: 'Logística'),
    _NavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory, label: 'Inventario'),
    _NavItem(icon: Icons.analytics_outlined, selectedIcon: Icons.analytics, label: 'Reportes'),
  ];

  final List<String> _titles = [
    'Administración Central',
    'Punto de Venta',
    'Bitácora de Producción',
    'Logística y Rutas',
    'Control de Inventario',
    'Reportes y Exportación',
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Scaffold(
        body: Row(
          children: [
            if (isWide) _buildSidebar(),
            if (isWide) VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.02),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            )),
                            child: child,
                          ),
                        );
                      },
                      child: _buildPage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFF2B528A).withOpacity(0.1),
                destinations: _navItems.map((n) => NavigationDestination(
                  icon: Icon(n.icon, color: Colors.black54),
                  selectedIcon: Icon(n.selectedIcon, color: const Color(0xFF2B528A)),
                  label: n.label,
                )).toList(),
              ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B528A), Color(0xFF0277BD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2B528A).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('💧', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Purificadora',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Sistema Admin',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),

          // Nav items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isActive = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _selectedIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: isActive
                                ? LinearGradient(colors: [
                                    const Color(0xFF2B528A).withOpacity(0.1),
                                    const Color(0xFF0277BD).withOpacity(0.05),
                                  ])
                                : null,
                            border: isActive
                                ? Border.all(color: const Color(0xFF2B528A).withOpacity(0.2))
                                : Border.all(color: Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              if (isActive)
                                Container(
                                  width: 3,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2B528A), Color(0xFF0277BD)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              Icon(
                                isActive ? item.selectedIcon : item.icon,
                                color: isActive
                                    ? const Color(0xFF2B528A)
                                    : Colors.black54,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                  color: isActive
                                      ? const Color(0xFF2B528A)
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Footer
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B528A), Color(0xFF0277BD)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('AD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Administrador', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                      Text('admin@purificadora.mx', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2B528A),
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Text(
            _titles[_selectedIndex],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const Spacer(),
          Icon(Icons.calendar_today, size: 16, color: Colors.white.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(
            _formatDate(DateTime.now()),
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return const AdminDashboard(key: ValueKey('admin'));
      case 1:
        return const PosScreen(key: ValueKey('pos'));
      case 2:
        return const ProductionScreen(key: ValueKey('production'));
      case 3:
        return const LogisticsScreen(key: ValueKey('logistics'));
      case 4:
        return const InventoryScreen(key: ValueKey('inventory'));
      case 5:
        return const ReportsScreen(key: ValueKey('reports'));
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatDate(DateTime d) {
    const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    const days = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    return '${days[d.weekday - 1]}, ${d.day} de ${months[d.month - 1]} de ${d.year}';
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}
