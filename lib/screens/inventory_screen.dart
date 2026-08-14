import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/toast_helper.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Producto Terminado'),
              Tab(text: 'Materia Prima y Compras'),
            ],
            indicatorColor: Color(0xFF2B528A),
            labelColor: Color(0xFF2B528A),
            unselectedLabelColor: Colors.black54,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFinishedProductTab(context),
                _buildRawMaterialsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedProductTab(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final inv = state.inventory;
        final movements = state.movements;
        final total = inv.totalUnits;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Control de Inventario (Garrafones)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Total en sistema: $total garrafones',
                          style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showMovementDialog(context, state),
                    icon: const Icon(Icons.swap_vert, size: 18),
                    label: const Text('Registrar Movimiento'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stat Cards
              Row(
                children: [
                  Expanded(child: StatCard(
                    icon: Icons.water_drop, value: '${inv.full}',
                    label: 'Llenos en Planta', color: const Color(0xFF3B82F6),
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: StatCard(
                    icon: Icons.circle_outlined, value: '${inv.empty}',
                    label: 'Vacíos en Planta', color: const Color(0xFF94A3B8),
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: StatCard(
                    icon: Icons.local_shipping, value: '${inv.onRoute}',
                    label: 'En Ruta', color: const Color(0xFFF59E0B),
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: StatCard(
                    icon: Icons.warning_amber, value: '${inv.damaged}',
                    label: 'Dañados / Baja', color: const Color(0xFFEF4444),
                  )),
                ],
              ),
              const SizedBox(height: 24),

              // Distribution Bar
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Distribución de Inventario',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const SizedBox(height: 16),
                      if (total > 0)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 32,
                            child: Row(
                              children: [
                                _barSegment(inv.full, total, const Color(0xFF3B82F6), '${inv.full}'),
                                _barSegment(inv.empty, total, const Color(0xFF94A3B8), '${inv.empty}'),
                                _barSegment(inv.onRoute, total, const Color(0xFFF59E0B), '${inv.onRoute}'),
                                _barSegment(inv.damaged, total, const Color(0xFFEF4444), '${inv.damaged}'),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Text('Sin datos',
                              style: TextStyle(fontSize: 12, color: Colors.black54))),
                        ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          _legend(const Color(0xFF3B82F6), 'Llenos'),
                          _legend(const Color(0xFF94A3B8), 'Vacíos'),
                          _legend(const Color(0xFFF59E0B), 'En Ruta'),
                          _legend(const Color(0xFFEF4444), 'Dañados'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Movements
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Últimos Movimientos',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const SizedBox(height: 12),
                      if (movements.isNotEmpty)
                        ...movements.map((m) => _buildMovementTile(m))
                      else
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: const Center(
                            child: Text('No hay movimientos registrados',
                                style: TextStyle(color: Colors.black54)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRawMaterialsTab(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Existencias de Materia Prima',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 16),
              GlassCard(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.rawMaterials.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.withOpacity(0.2)),
                  itemBuilder: (context, index) {
                    final rm = state.rawMaterials[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF26C6DA).withOpacity(0.2),
                        child: const Icon(Icons.inventory_2, color: Color(0xFF26C6DA), size: 20),
                      ),
                      title: Text(rm.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      subtitle: Text('Costo unitario: \$${rm.cost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54)),
                      trailing: Text('${rm.stock} ${rm.unit}', 
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  const Text('Historial de Compras',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implementar registro de compra
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Registrar Compra'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.purchases.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.withOpacity(0.2)),
                  itemBuilder: (context, index) {
                    final p = state.purchases[index];
                    final isReceived = p.status == 'received';
                    final dateStr = '${p.date.day}/${p.date.month}/${p.date.year}';
                    return ListTile(
                      leading: Icon(
                        isReceived ? Icons.check_circle : Icons.pending_actions,
                        color: isReceived ? Colors.green : Colors.orange,
                      ),
                      title: Text('Compra #${p.id}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      subtitle: Text('Fecha: $dateStr • Total: \$${p.totalCost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54)),
                      trailing: !isReceived 
                        ? ElevatedButton(
                            onPressed: () {
                              state.receivePurchase(p.id);
                              ToastHelper.show(context, 'Compra recibida, inventario actualizado', type: ToastType.success);
                            },
                            child: const Text('Marcar Recibido'),
                          )
                        : const Text('Recibido', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _barSegment(int value, int total, Color color, String label) {
    if (value <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: value,
      child: Container(
        color: color,
        child: Center(
          child: Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(3),
        )),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }

  Widget _buildMovementTile(InventoryMovement m) {
    final isIn = m.type == 'in';
    final color = isIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final dateStr = '${m.date.day}-${_monthName(m.date.month)}-${m.date.year} '
        '${m.date.hour.toString().padLeft(2, '0')}:${m.date.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIn ? Icons.arrow_downward : Icons.arrow_upward,
              color: color, size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          Text(
            '${isIn ? '+' : '-'}${m.amount} ${m.unit}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return names[month - 1];
  }

  void _showMovementDialog(BuildContext context, AppState state) {
    String type = 'in';
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String unit = 'Garrafones Llenos';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('📦 Registrar Movimiento',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipo de Movimiento'),
                  items: const [
                    DropdownMenuItem(value: 'in', child: Text('📥 Entrada')),
                    DropdownMenuItem(value: 'out', child: Text('📤 Salida')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v ?? 'in'),
                  dropdownColor: Colors.white,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción', hintText: 'ej. Retorno de Ruta Norte'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: unit,
                  decoration: const InputDecoration(labelText: 'Tipo de Garrafón'),
                  items: const [
                    DropdownMenuItem(value: 'Garrafones Llenos', child: Text('Garrafones Llenos')),
                    DropdownMenuItem(value: 'Garrafones Vacíos', child: Text('Garrafones Vacíos')),
                    DropdownMenuItem(value: 'Garrafones Nuevos', child: Text('Garrafones Nuevos')),
                    DropdownMenuItem(value: 'Garrafones Dañados', child: Text('Garrafones Dañados')),
                  ],
                  onChanged: (v) => setDialogState(() => unit = v ?? 'Garrafones Llenos'),
                  dropdownColor: Colors.white,
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton.icon(
              onPressed: () {
                if (descCtrl.text.trim().isEmpty || amountCtrl.text.isEmpty) {
                  ToastHelper.show(context, 'Completa todos los campos', type: ToastType.error);
                  return;
                }
                state.addMovement(InventoryMovement(
                  id: DateTime.now().millisecondsSinceEpoch.toRadixString(36),
                  type: type,
                  description: descCtrl.text.trim(),
                  date: DateTime.now(),
                  amount: int.tryParse(amountCtrl.text) ?? 0,
                  unit: unit,
                ));
                Navigator.pop(ctx);
                ToastHelper.show(context,
                    'Movimiento registrado: ${type == 'in' ? 'Entrada' : 'Salida'} de ${amountCtrl.text} $unit',
                    type: ToastType.success);
              },
              icon: const Icon(Icons.add_circle, size: 18),
              label: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
