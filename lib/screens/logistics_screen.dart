import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/toast_helper.dart';

class LogisticsScreen extends StatelessWidget {
  const LogisticsScreen({super.key});

  static const _statusConfig = {
    'pending': ('Pendiente', Color(0xFFF59E0B)),
    'in_progress': ('En progreso', Color(0xFF3B82F6)),
    'completed': ('Completada', Color(0xFF10B981)),
  };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Consumer<AppState>(
      builder: (context, state, _) {
        final routes = state.routes;

        Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Logística y Rutas de Reparto',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('${routes.length} rutas registradas',
                        style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showRouteDialog(context, state),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Ruta'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats
            Row(
              children: [
                Expanded(child: StatCard(
                  icon: Icons.route,
                  value: '${routes.length}',
                  label: 'Rutas totales',
                  color: const Color(0xFF3B82F6),
                )),
                const SizedBox(width: 14),
                Expanded(child: StatCard(
                  icon: Icons.pending_actions,
                  value: '${routes.where((r) => r.status == 'in_progress').length}',
                  label: 'En progreso',
                  color: const Color(0xFFF59E0B),
                )),
                const SizedBox(width: 14),
                Expanded(child: StatCard(
                  icon: Icons.check_circle,
                  value: '${state.completedDeliveries}/${state.totalDeliveries}',
                  label: 'Entregas completadas',
                  color: const Color(0xFF10B981),
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Route Cards
            if (routes.isNotEmpty)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: routes.map((route) => _buildRouteCard(context, state, route)).toList(),
              )
            else
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('🚚', style: TextStyle(fontSize: 56, color: Colors.black12)),
                        const SizedBox(height: 12),
                        const Text('No hay rutas registradas',
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: SingleChildScrollView(child: content)),
                const SizedBox(width: 24),
                // Vista Móvil del Repartidor
                Expanded(flex: 2, child: _buildMobileDriverView(context, state)),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                content,
                const SizedBox(height: 32),
                const Text('App del Repartidor', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildMobileDriverView(context, state),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildMobileDriverView(BuildContext context, AppState state) {
    final activeRoute = state.routes.where((r) => r.status == 'in_progress').firstOrNull;
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      height: 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Status bar mock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: Colors.black,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('12:00', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_4_bar, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Icon(Icons.wifi, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Icon(Icons.battery_full, size: 14, color: Colors.white),
                    ],
                  )
                ],
              ),
            ),
            // App Content
            Expanded(
              child: activeRoute == null
                ? const Center(child: Text('No tienes rutas activas.\nEspera asignación.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)))
                : Column(
                    children: [
                      // Header Driver App
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: const Color(0xFF1E293B),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundColor: Color(0xFF3B82F6), child: Icon(Icons.person, color: Colors.white)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(activeRoute.driver, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                  Text('Ruta: ${activeRoute.name}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Map View (Real)
                      Expanded(
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(19.432608, -99.133209),
                                zoom: 13,
                              ),
                              markers: {
                                const Marker(
                                  markerId: MarkerId('driver'),
                                  position: LatLng(19.432608, -99.133209),
                                  infoWindow: InfoWindow(title: 'Repartidor'),
                                ),
                                const Marker(
                                  markerId: MarkerId('next_stop'),
                                  position: LatLng(19.442608, -99.143209),
                                  infoWindow: InfoWindow(title: 'Siguiente Parada'),
                                ),
                              },
                              zoomControlsEnabled: false,
                            ),
                            // Navigation overlay
                            Positioned(
                              bottom: 16, left: 16, right: 16,
                              child: GlassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Siguiente Parada', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      const Text('Cliente: Abarrotes Doña Mari', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                      const Text('Dirección: Av. Principal 123', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            if (activeRoute.completed < activeRoute.total) {
                                              state.advanceRoute(activeRoute.id);
                                              ToastHelper.show(context, 'Entrega registrada desde App Móvil', type: ToastType.success);
                                            } else {
                                              state.updateRouteStatus(activeRoute.id, 'completed');
                                              ToastHelper.show(context, 'Ruta finalizada', type: ToastType.success);
                                            }
                                          },
                                          icon: const Icon(Icons.check_circle),
                                          label: Text(activeRoute.completed < activeRoute.total ? 'Confirmar Entrega' : 'Finalizar Ruta'),
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
            // Bottom Nav mock
            Container(
              height: 60,
              color: const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.map, color: const Color(0xFF3B82F6).withOpacity(0.8)),
                  Icon(Icons.list, color: Colors.white.withOpacity(0.3)),
                  Icon(Icons.settings, color: Colors.white.withOpacity(0.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapPin(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildRouteCard(BuildContext context, AppState state, DeliveryRoute route) {
    final config = _statusConfig[route.status] ?? _statusConfig['pending']!;
    final statusLabel = config.$1;
    final statusColor = config.$2;
    final progress = route.progress;

    return SizedBox(
      width: 340,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(route.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Info
              _infoRow(Icons.person, 'Chofer: ${route.driver.isEmpty ? 'Sin asignar' : route.driver}',
                  route.driver.isEmpty ? const Color(0xFFF59E0B) : null),
              const SizedBox(height: 8),
              _infoRow(Icons.inventory_2, 'Entregas: ${route.completed} / ${route.total}', null),
              const SizedBox(height: 18),

              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progreso', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  Text('${(progress * 100).round()}%',
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  if (route.status == 'pending')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          state.updateRouteStatus(route.id, 'in_progress');
                          ToastHelper.show(context, 'Ruta iniciada', type: ToastType.success);
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Iniciar'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    )
                  else if (route.status == 'in_progress') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          state.updateRouteStatus(route.id, 'completed');
                          ToastHelper.show(context, 'Ruta completada ✅', type: ToastType.success);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Completar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (route.completed < route.total) {
                          state.advanceRoute(route.id);
                          ToastHelper.show(context, 'Entrega ${route.completed + 1}/${route.total}', type: ToastType.success);
                        } else {
                          ToastHelper.show(context, 'Todas las entregas completadas', type: ToastType.warning);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('+1'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12)),
                    ),
                  ] else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Finalizada'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _showRouteDialog(context, state, existing: route),
                    icon: Icon(Icons.edit, size: 18, color: Colors.white.withOpacity(0.4)),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    onPressed: () {
                      state.deleteRoute(route.id);
                      ToastHelper.show(context, 'Ruta eliminada', type: ToastType.info);
                    },
                    icon: Icon(Icons.delete, size: 18, color: const Color(0xFFEF4444).withOpacity(0.7)),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color? highlightColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 14, color: highlightColor ?? Colors.black54)),
        ),
      ],
    );
  }

  void _showRouteDialog(BuildContext context, AppState state, {DeliveryRoute? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final driverCtrl = TextEditingController(text: existing?.driver ?? '');
    final totalCtrl = TextEditingController(text: existing?.total.toString() ?? '');
    final completedCtrl = TextEditingController(text: existing?.completed.toString() ?? '0');
    String status = existing?.status ?? 'pending';
    List<String> assignedClients = List.from(existing?.clientIds ?? []);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? '✏️ Editar Ruta' : '➕ Nueva Ruta',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre de la Ruta'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: driverCtrl,
                  decoration: const InputDecoration(labelText: 'Chofer Asignado'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalCtrl,
                  decoration: const InputDecoration(labelText: 'Total de Entregas'),
                  keyboardType: TextInputType.number,
                ),
                if (isEdit) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: completedCtrl,
                    decoration: const InputDecoration(labelText: 'Entregas Completadas'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'in_progress', child: Text('En progreso')),
                      DropdownMenuItem(value: 'completed', child: Text('Completada')),
                    ],
                    onChanged: (v) => setDialogState(() => status = v ?? 'pending'),
                    dropdownColor: Colors.white,
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Clientes Asignados (Geolocalizados)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: state.clients.length,
                    itemBuilder: (c, i) {
                      final client = state.clients[i];
                      final isAssigned = assignedClients.contains(client.id);
                      return CheckboxListTile(
                        title: Text(client.name, style: const TextStyle(fontSize: 13)),
                        subtitle: Text('Lat: ${client.latitude}, Lng: ${client.longitude}', style: const TextStyle(fontSize: 10)),
                        value: isAssigned,
                        dense: true,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              assignedClients.add(client.id);
                            } else {
                              assignedClients.remove(client.id);
                            }
                            totalCtrl.text = assignedClients.length.toString();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton.icon(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || totalCtrl.text.isEmpty) {
                  ToastHelper.show(context, 'Completa nombre y total', type: ToastType.error);
                  return;
                }
                if (isEdit) {
                  state.updateRoute(existing.id, DeliveryRoute(
                    id: existing.id,
                    name: nameCtrl.text.trim(),
                    driver: driverCtrl.text.trim(),
                    status: status,
                    completed: int.tryParse(completedCtrl.text) ?? 0,
                    total: int.tryParse(totalCtrl.text) ?? 0,
                    clientIds: assignedClients,
                  ));
                  ToastHelper.show(context, 'Ruta actualizada', type: ToastType.success);
                } else {
                  state.addRoute(DeliveryRoute(
                    id: DateTime.now().millisecondsSinceEpoch.toRadixString(36),
                    name: nameCtrl.text.trim(),
                    driver: driverCtrl.text.trim(),
                    status: 'pending',
                    completed: 0,
                    total: int.tryParse(totalCtrl.text) ?? 0,
                    clientIds: assignedClients,
                  ));
                  ToastHelper.show(context, 'Ruta creada', type: ToastType.success);
                }
                Navigator.pop(ctx);
              },
              icon: Icon(isEdit ? Icons.save : Icons.add_circle, size: 18),
              label: Text(isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
