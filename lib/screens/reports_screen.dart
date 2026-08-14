import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import '../state/app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/toast_helper.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reportes y Exportación de Datos',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 8),
              const Text('Genera reportes en formato Excel (.xlsx) de las diferentes áreas del sistema.',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 32),
              
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _buildExportCard(
                    context: context,
                    title: 'Ventas y Finanzas',
                    icon: Icons.point_of_sale,
                    color: const Color(0xFF10B981),
                    description: 'Exporta el historial de ventas, pagos en efectivo, abonos y créditos.',
                    onExport: () => _exportSales(context, state),
                  ),
                  _buildExportCard(
                    context: context,
                    title: 'Producción',
                    icon: Icons.water_drop,
                    color: const Color(0xFF26C6DA),
                    description: 'Exporta la bitácora de producción, uso de cloro y lavado de filtros.',
                    onExport: () => _exportProduction(context, state),
                  ),
                  _buildExportCard(
                    context: context,
                    title: 'Logística',
                    icon: Icons.local_shipping,
                    color: const Color(0xFF3B82F6),
                    description: 'Exporta el historial de rutas, entregas por chofer y rendimiento.',
                    onExport: () => _exportLogistics(context, state),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onExport,
  }) {
    return SizedBox(
      width: 320,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(color: Colors.black54, height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onExport,
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar Excel'),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveExcel(BuildContext context, Excel excel, String filename) async {
    try {
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final path = '${Directory.current.path}/$filename.xlsx';
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        
        ToastHelper.show(context, 'Reporte guardado en:\n$path', type: ToastType.success);
      }
    } catch (e) {
      ToastHelper.show(context, 'Error al exportar: $e', type: ToastType.error);
    }
  }

  void _exportSales(BuildContext context, AppState state) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Ventas'];
    excel.setDefaultSheet('Ventas');

    // Header
    sheetObject.appendRow([
      TextCellValue('ID Venta'),
      TextCellValue('Fecha'),
      TextCellValue('Cliente ID'),
      TextCellValue('Total (MXN)'),
      TextCellValue('Pagado (MXN)'),
      TextCellValue('Estado'),
      TextCellValue('Artículos'),
    ]);

    for (var sale in state.sales) {
      final dateStr = '${sale.date.day}/${sale.date.month}/${sale.date.year} ${sale.date.hour}:${sale.date.minute}';
      sheetObject.appendRow([
        TextCellValue(sale.id),
        TextCellValue(dateStr),
        TextCellValue(sale.clientId ?? 'Mostrador'),
        DoubleCellValue(sale.total),
        DoubleCellValue(sale.payment),
        TextCellValue(sale.status == 'paid' ? 'Pagado' : 'Crédito'),
        IntCellValue(sale.itemCount),
      ]);
    }
    _saveExcel(context, excel, 'Reporte_Ventas');
  }

  void _exportProduction(BuildContext context, AppState state) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Producción'];
    excel.setDefaultSheet('Producción');

    sheetObject.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Litros Producidos'),
      TextCellValue('Cloro (ppm)'),
      TextCellValue('Filtros Lavados'),
      TextCellValue('Operador'),
    ]);

    for (var p in state.production) {
      final dateStr = '${p.date.day}/${p.date.month}/${p.date.year} ${p.date.hour}:${p.date.minute}';
      sheetObject.appendRow([
        TextCellValue(dateStr),
        DoubleCellValue(p.liters),
        DoubleCellValue(p.chlorine),
        TextCellValue(p.filtersWashed ? 'Sí' : 'No'),
        TextCellValue(p.operator),
      ]);
    }
    _saveExcel(context, excel, 'Reporte_Produccion');
  }

  void _exportLogistics(BuildContext context, AppState state) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Logística'];
    excel.setDefaultSheet('Logística');

    sheetObject.appendRow([
      TextCellValue('Ruta'),
      TextCellValue('Chofer'),
      TextCellValue('Estado'),
      TextCellValue('Entregas Realizadas'),
      TextCellValue('Entregas Totales'),
      TextCellValue('Progreso (%)'),
    ]);

    for (var r in state.routes) {
      sheetObject.appendRow([
        TextCellValue(r.name),
        TextCellValue(r.driver),
        TextCellValue(r.status),
        IntCellValue(r.completed),
        IntCellValue(r.total),
        DoubleCellValue((r.progress * 100).roundToDouble()),
      ]);
    }
    _saveExcel(context, excel, 'Reporte_Logistica');
  }
}
