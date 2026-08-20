import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../inventory_formatters.dart';
import 'responsive_inventory_table.dart';

class FinishedGoodsTab extends StatelessWidget {
  const FinishedGoodsTab({
    super.key,
    required this.snapshot,
    required this.isBusy,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final InventorySnapshot snapshot;
  final bool isBusy;
  final VoidCallback onCreate;
  final ValueChanged<FinishedGood> onEdit;
  final ValueChanged<FinishedGood> onDelete;

  @override
  Widget build(BuildContext context) {
    final branchNames = {
      for (final branch in snapshot.branches) branch.id: branch.name,
    };
    final productNames = {
      for (final product in snapshot.products) product.id: product.name,
    };

    return RefreshIndicator(
      onRefresh: () async {},
      notificationPredicate: (_) => false,
      child: ListView(
        key: const PageStorageKey('finished-goods-tab'),
        padding: const EdgeInsets.all(24),
        children: [
          _TabHeader(
            title: 'Producto Terminado',
            description:
                'Controla activos y existencias terminadas por sucursal, estado y disponibilidad de venta.',
            buttonLabel: 'Registrar activo',
            buttonIcon: Icons.add_box_outlined,
            onPressed: isBusy || snapshot.branches.isEmpty ? null : onCreate,
          ),
          if (snapshot.branches.isEmpty) ...[
            const SizedBox(height: 16),
            const _Notice(
              message:
                  'Registra al menos una sucursal antes de agregar producto terminado.',
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: FinishedGoodStatus.values
                .map((status) {
                  final quantity = snapshot.finishedGoods
                      .where((item) => item.status == status)
                      .fold<int>(0, (sum, item) => sum + item.quantity);
                  return _StatusSummary(
                    label: status.label,
                    value: quantity,
                    color: status.color,
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          if (snapshot.finishedGoods.isEmpty)
            const _EmptyInventoryState(
              icon: Icons.inventory_2_outlined,
              message: 'Aún no hay productos terminados registrados.',
            )
          else
            ResponsiveInventoryTable(
              key: const ValueKey('finished-goods-table'),
              minWidth: 1250,
              columns: const [
                DataColumn(label: Text('Sucursal')),
                DataColumn(label: Text('Activo / producto')),
                DataColumn(label: Text('Tipo')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Cantidad'), numeric: true),
                DataColumn(label: Text('Vendible')),
                DataColumn(label: Text('Producto asociado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: snapshot.finishedGoods
                  .map((item) {
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 170,
                            child: Text(
                              branchNames[item.branchId] ??
                                  'Sucursal eliminada',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 190,
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(item.type)),
                        DataCell(_StatusChip(status: item.status)),
                        DataCell(Text('${item.quantity}')),
                        DataCell(
                          Icon(
                            item.isSellable
                                ? Icons.check_circle
                                : Icons.block_outlined,
                            color: item.isSellable
                                ? const Color(0xFF059669)
                                : Colors.black38,
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Text(
                              item.productId == null
                                  ? 'Sin asociación'
                                  : productNames[item.productId] ??
                                        'Producto no disponible',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: isBusy ? null : () => onEdit(item),
                                icon: const Icon(Icons.edit_outlined),
                                color: const Color(0xFF2B528A),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                onPressed: isBusy ? null : () => onDelete(item),
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
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final FinishedGoodStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: status.color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.inventory_outlined, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
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

class _TabHeader extends StatelessWidget {
  const _TabHeader({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final IconData buttonIcon;
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
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(buttonIcon),
          label: Text(buttonLabel),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

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

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
