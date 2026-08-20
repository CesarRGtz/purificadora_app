import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../inventory_formatters.dart';
import 'responsive_inventory_table.dart';

class RawMaterialsTab extends StatelessWidget {
  const RawMaterialsTab({
    super.key,
    required this.snapshot,
    required this.isBusy,
    required this.onCreate,
    required this.onLinkProduct,
    required this.onMovement,
    required this.onTransfer,
    required this.onEdit,
    required this.onDelete,
  });

  final InventorySnapshot snapshot;
  final bool isBusy;
  final VoidCallback onCreate;
  final ValueChanged<RawMaterial> onLinkProduct;
  final ValueChanged<RawMaterial> onMovement;
  final ValueChanged<RawMaterial> onTransfer;
  final ValueChanged<RawMaterial> onEdit;
  final ValueChanged<RawMaterial> onDelete;

  @override
  Widget build(BuildContext context) {
    final branchNames = {
      for (final branch in snapshot.branches) branch.id: branch.name,
    };
    final productsById = {
      for (final product in snapshot.products) product.id: product.name,
    };
    final stockValue = snapshot.rawMaterials.fold<double>(
      0,
      (sum, material) => sum + material.totalValue,
    );

    return ListView(
      key: const PageStorageKey('raw-materials-tab'),
      padding: const EdgeInsets.all(24),
      children: [
        _RawMaterialsHeader(
          onPressed: isBusy || snapshot.branches.isEmpty ? null : onCreate,
        ),
        if (snapshot.branches.isEmpty) ...[
          const SizedBox(height: 16),
          const _RawNotice(
            message:
                'Registra al menos una sucursal antes de agregar materias primas.',
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _RawSummaryCard(
              icon: Icons.inventory_2_outlined,
              label: 'Insumos activos',
              value: '${snapshot.rawMaterials.length}',
              color: const Color(0xFF2563EB),
            ),
            _RawSummaryCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Valor de existencia',
              value: formatInventoryMoney(stockValue),
              color: const Color(0xFF059669),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Existencia = compras + traslados de entrada − usados − traslados de salida. Total = existencia × último costo.',
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 14),
        if (snapshot.rawMaterials.isEmpty)
          const _RawEmptyState()
        else
          ResponsiveInventoryTable(
            key: const ValueKey('raw-materials-table'),
            minWidth: 2050,
            columns: const [
              DataColumn(label: Text('Sucursal')),
              DataColumn(label: Text('Categoría')),
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Unidad')),
              DataColumn(
                label: Tooltip(
                  message: 'Cantidad acumulada recibida mediante compras',
                  child: Text('Ctd. compra'),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Tooltip(
                  message: 'Cantidad consumida manualmente o por productos',
                  child: Text('Ctd. usados'),
                ),
                numeric: true,
              ),
              DataColumn(label: Text('Tras. entrada'), numeric: true),
              DataColumn(label: Text('Tras. salida'), numeric: true),
              DataColumn(
                label: Tooltip(
                  message: 'Costo unitario de la compra o entrada más reciente',
                  child: Text('Últ. costo'),
                ),
                numeric: true,
              ),
              DataColumn(label: Text('Existencia'), numeric: true),
              DataColumn(
                label: Tooltip(
                  message: 'Valor monetario de la existencia actual',
                  child: Text('Total'),
                ),
                numeric: true,
              ),
              DataColumn(label: Text('Productos vinculados')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: snapshot.rawMaterials
                .map((material) {
                  final lowStock = material.stock <= 0;
                  final linkedProductNames =
                      snapshot.productMaterialRequirements
                          .where((item) => item.rawMaterialId == material.id)
                          .map((item) => productsById[item.productId])
                          .whereType<String>()
                          .toSet()
                          .toList(growable: false)
                        ..sort();
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 170,
                          child: Text(
                            branchNames[material.branchId] ??
                                'Sucursal eliminada',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(material.category)),
                      DataCell(
                        SizedBox(
                          width: 190,
                          child: Text(
                            material.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      DataCell(Text(material.unit)),
                      DataCell(
                        Text(formatInventoryQuantity(material.purchased)),
                      ),
                      DataCell(Text(formatInventoryQuantity(material.used))),
                      DataCell(
                        Text(formatInventoryQuantity(material.transferIn)),
                      ),
                      DataCell(
                        Text(formatInventoryQuantity(material.transferOut)),
                      ),
                      DataCell(
                        Text(formatInventoryUnitCost(material.lastUnitCost)),
                      ),
                      DataCell(
                        Text(
                          formatInventoryQuantity(material.stock),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: lowStock ? Colors.redAccent : Colors.black87,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          formatInventoryMoney(material.totalValue),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 210,
                          child: Text(
                            linkedProductNames.isEmpty
                                ? 'Sin vincular'
                                : linkedProductNames.join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: linkedProductNames.isEmpty
                                  ? const Color(0xFFB45309)
                                  : Colors.black87,
                              fontWeight: linkedProductNames.isEmpty
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Vincular a producto',
                              onPressed: isBusy
                                  ? null
                                  : () => onLinkProduct(material),
                              icon: const Icon(Icons.link),
                              color: const Color(0xFF7C3AED),
                            ),
                            IconButton(
                              tooltip: 'Registrar movimiento',
                              onPressed: isBusy
                                  ? null
                                  : () => onMovement(material),
                              icon: const Icon(Icons.swap_vert),
                              color: const Color(0xFF059669),
                            ),
                            IconButton(
                              tooltip: 'Trasladar a otra sucursal',
                              onPressed: isBusy || material.stock <= 0
                                  ? null
                                  : () => onTransfer(material),
                              icon: const Icon(Icons.compare_arrows),
                              color: const Color(0xFF2563EB),
                            ),
                            IconButton(
                              tooltip: 'Editar',
                              onPressed: isBusy ? null : () => onEdit(material),
                              icon: const Icon(Icons.edit_outlined),
                              color: const Color(0xFF2B528A),
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              onPressed: isBusy
                                  ? null
                                  : () => onDelete(material),
                              icon: const Icon(Icons.delete_outline),
                              color: const Color(0xFFDC2626),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                })
                .toList(growable: false),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _RawMaterialsHeader extends StatelessWidget {
  const _RawMaterialsHeader({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Materia Prima',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'Gestiona insumos por sucursal y registra compras, usos y traslados sin perder el historial.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Registrar materia prima'),
        ),
      ],
    );
  }
}

class _RawSummaryCard extends StatelessWidget {
  const _RawSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(label, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RawNotice extends StatelessWidget {
  const _RawNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF92400E))),
    );
  }
}

class _RawEmptyState extends StatelessWidget {
  const _RawEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            Icon(Icons.science_outlined, size: 48, color: Colors.black38),
            SizedBox(height: 12),
            Text(
              'Aún no hay materias primas registradas.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
