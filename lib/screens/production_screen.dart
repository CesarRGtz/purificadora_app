import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/toast_helper.dart';

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final records = state.production;

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
                      const Text('Bitácora de Producción',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('${records.length} registros en la bitácora',
                          style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showFormDialog(context, state),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo Registro'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.water_drop,
                      value: records.isNotEmpty ? records.first.liters.toStringAsFixed(0) : '0',
                      label: 'Última producción (litros)',
                      color: const Color(0xFF26C6DA),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatCard(
                      icon: Icons.science,
                      value: records.isNotEmpty ? '${records.first.chlorine}' : '—',
                      label: 'Último cloro residual (ppm)',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatCard(
                      icon: Icons.analytics,
                      value: state.totalLitersProduced.toStringAsFixed(0),
                      label: 'Total litros producidos',
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Table
              GlassCard(
                child: records.isNotEmpty
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingTextStyle: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: Colors.black54,
                            letterSpacing: 0.5,
                          ),
                          dataTextStyle: const TextStyle(fontSize: 14, color: Colors.black87),
                          columns: const [
                            DataColumn(label: Text('FECHA Y HORA')),
                            DataColumn(label: Text('LITROS PRODUCIDOS')),
                            DataColumn(label: Text('CLORO RESIDUAL')),
                            DataColumn(label: Text('FILTROS')),
                            DataColumn(label: Text('ENCARGADO')),
                            DataColumn(label: Text('ACCIONES')),
                          ],
                          rows: records.map((r) {
                            final dateStr = '${r.date.day}-${_monthName(r.date.month)}-${r.date.year} '
                                '${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}';
                            return DataRow(cells: [
                              DataCell(Text(dateStr)),
                              DataCell(Text('${r.liters.toStringAsFixed(0)} L',
                                  style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(_chlorineBadge(r.chlorine)),
                              DataCell(Icon(
                                r.filtersWashed ? Icons.check_circle : Icons.cancel,
                                color: r.filtersWashed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                size: 20,
                              )),
                              DataCell(Text(r.operator)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    color: Colors.black54,
                                    onPressed: () => _showFormDialog(context, state, existing: r),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    color: const Color(0xFFEF4444).withOpacity(0.7),
                                    onPressed: () {
                                      state.deleteProduction(r.id);
                                      ToastHelper.show(context, 'Registro eliminado', type: ToastType.info);
                                    },
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                          child: Column(
                            children: [
                              const Text('📋', style: TextStyle(fontSize: 56, color: Colors.black12)),
                              const SizedBox(height: 12),
                              const Text('No hay registros de producción',
                                  style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chlorineBadge(double value) {
    Color color;
    if (value <= 0.5) {
      color = const Color(0xFF10B981);
    } else if (value <= 1.0) {
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFFEF4444);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$value ppm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _monthName(int month) {
    const names = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return names[month - 1];
  }

  void _showFormDialog(BuildContext context, AppState state, {ProductionRecord? existing}) {
    final isEdit = existing != null;
    final litersCtrl = TextEditingController(text: existing?.liters.toStringAsFixed(0) ?? '');
    final chlorineCtrl = TextEditingController(text: existing?.chlorine.toString() ?? '');
    final operatorCtrl = TextEditingController(text: existing?.operator ?? '');
    final garrafonesCtrl = TextEditingController(text: '0'); // Nuevo campo
    bool filtersWashed = existing?.filtersWashed ?? false;
    DateTime selectedDate = existing?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? '✏️ Editar Registro' : '➕ Nuevo Registro',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, size: 20),
                    title: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} '
                      '${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          setDialogState(() {
                            selectedDate = DateTime(
                              date.year, date.month, date.day,
                              time?.hour ?? selectedDate.hour,
                              time?.minute ?? selectedDate.minute,
                            );
                          });
                        }
                      },
                      child: const Text('Cambiar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: litersCtrl,
                          decoration: const InputDecoration(labelText: 'Litros Producidos'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: garrafonesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Garrafones (Descuenta Insumos)',
                            labelStyle: TextStyle(fontSize: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: chlorineCtrl,
                    decoration: const InputDecoration(labelText: 'Cloro Residual (ppm)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Filtros lavados', style: const TextStyle(fontSize: 14)),
                    value: filtersWashed,
                    onChanged: (v) => setDialogState(() => filtersWashed = v ?? false),
                    activeColor: const Color(0xFF2B528A),
                  ),
                  TextField(
                    controller: operatorCtrl,
                    decoration: const InputDecoration(labelText: 'Encargado'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (litersCtrl.text.isEmpty || chlorineCtrl.text.isEmpty || operatorCtrl.text.trim().isEmpty) {
                  ToastHelper.show(context, 'Completa todos los campos', type: ToastType.error);
                  return;
                }
                final record = ProductionRecord(
                  id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toRadixString(36),
                  date: selectedDate,
                  liters: double.tryParse(litersCtrl.text) ?? 0,
                  chlorine: double.tryParse(chlorineCtrl.text) ?? 0,
                  filtersWashed: filtersWashed,
                  operator: operatorCtrl.text.trim(),
                );
                if (isEdit) {
                  state.updateProduction(existing.id, record);
                  ToastHelper.show(context, 'Registro actualizado', type: ToastType.success);
                } else {
                  int garrafones = int.tryParse(garrafonesCtrl.text) ?? 0;
                  state.addProduction(record, garrafones);
                  ToastHelper.show(context, 'Registro agregado. Insumos descontados: $garrafones', type: ToastType.success);
                }
                Navigator.pop(ctx);
              },
              icon: Icon(isEdit ? Icons.save : Icons.add_circle, size: 18),
              label: Text(isEdit ? 'Guardar' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}
