import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../inventory_formatters.dart';
import 'responsive_inventory_table.dart';

class InventoryProductsTab extends StatelessWidget {
  const InventoryProductsTab({
    super.key,
    required this.snapshot,
    required this.isBusy,
    required this.onCreate,
    required this.onEdit,
    required this.onConfigureBranches,
    required this.onConfigureMaterials,
    required this.onConsume,
    required this.onDelete,
  });

  final InventorySnapshot snapshot;
  final bool isBusy;
  final VoidCallback onCreate;
  final ValueChanged<InventoryProduct> onEdit;
  final ValueChanged<InventoryProduct> onConfigureBranches;
  final ValueChanged<InventoryProduct> onConfigureMaterials;
  final ValueChanged<InventoryProduct> onConsume;
  final ValueChanged<InventoryProduct> onDelete;

  @override
  Widget build(BuildContext context) {
    final branchesById = {
      for (final branch in snapshot.branches) branch.id: branch.name,
    };

    return ListView(
      key: const PageStorageKey('inventory-products-tab'),
      padding: const EdgeInsets.all(24),
      children: [
        _ProductsHeader(onCreate: isBusy ? null : onCreate),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF93C5FD)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sync, color: Color(0xFF1D4ED8), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Este es el mismo catálogo usado en Sucursales. Los cambios y asignaciones se reflejan en ambos apartados.',
                  style: TextStyle(color: Color(0xFF1E40AF), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (snapshot.products.isEmpty)
          const _ProductsEmptyState()
        else
          ResponsiveInventoryTable(
            key: const ValueKey('inventory-products-table'),
            minWidth: 1480,
            columns: const [
              DataColumn(label: Text('Producto')),
              DataColumn(label: Text('SKU')),
              DataColumn(label: Text('Precio base'), numeric: true),
              DataColumn(label: Text('Sucursales')),
              DataColumn(label: Text('Insumos de receta')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: snapshot.products
                .map((product) {
                  final branchNames =
                      product.branchIds
                          .map((id) => branchesById[id])
                          .whereType<String>()
                          .toList(growable: false)
                        ..sort();
                  final requirements = snapshot.productMaterialRequirements
                      .where((item) => item.productId == product.id)
                      .toList(growable: false);
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 230,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (product.description.isNotEmpty)
                                Text(
                                  product.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(SelectableText(product.sku)),
                      DataCell(Text(formatInventoryMoney(product.basePrice))),
                      DataCell(
                        SizedBox(
                          width: 260,
                          child: Text(
                            branchNames.isEmpty
                                ? 'Sin sucursales'
                                : branchNames.join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          requirements.isEmpty
                              ? 'Sin receta'
                              : '${requirements.length} configurados',
                          style: TextStyle(
                            color: requirements.isEmpty
                                ? const Color(0xFFB45309)
                                : const Color(0xFF047857),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Configurar sucursales',
                              onPressed: isBusy
                                  ? null
                                  : () => onConfigureBranches(product),
                              icon: const Icon(Icons.store_outlined),
                              color: const Color(0xFF2563EB),
                            ),
                            IconButton(
                              tooltip: 'Configurar insumos',
                              onPressed: isBusy
                                  ? null
                                  : () => onConfigureMaterials(product),
                              icon: const Icon(Icons.account_tree_outlined),
                              color: const Color(0xFF7C3AED),
                            ),
                            IconButton(
                              tooltip: 'Registrar producción / uso',
                              onPressed: isBusy
                                  ? null
                                  : () => onConsume(product),
                              icon: const Icon(
                                Icons.precision_manufacturing_outlined,
                              ),
                              color: const Color(0xFF059669),
                            ),
                            IconButton(
                              tooltip: 'Editar producto',
                              onPressed: isBusy ? null : () => onEdit(product),
                              icon: const Icon(Icons.edit_outlined),
                              color: const Color(0xFF2B528A),
                            ),
                            IconButton(
                              tooltip: 'Eliminar producto',
                              onPressed: isBusy
                                  ? null
                                  : () => onDelete(product),
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

class _ProductsHeader extends StatelessWidget {
  const _ProductsHeader({required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Productos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'Administra el catálogo, sus sucursales y la receta de materias primas por unidad.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Registrar producto'),
        ),
      ],
    );
  }
}

class _ProductsEmptyState extends StatelessWidget {
  const _ProductsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            Icon(Icons.qr_code_2, size: 48, color: Colors.black38),
            SizedBox(height: 12),
            Text(
              'Aún no hay productos en el catálogo.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
