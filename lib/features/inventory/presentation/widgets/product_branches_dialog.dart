import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';

class ProductBranchesDialog extends StatefulWidget {
  const ProductBranchesDialog({
    super.key,
    required this.product,
    required this.branches,
  });

  final InventoryProduct product;
  final List<InventoryBranch> branches;

  static Future<Set<String>?> show(
    BuildContext context, {
    required InventoryProduct product,
    required List<InventoryBranch> branches,
  }) {
    return showDialog<Set<String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ProductBranchesDialog(product: product, branches: branches),
    );
  }

  @override
  State<ProductBranchesDialog> createState() => _ProductBranchesDialogState();
}

class _ProductBranchesDialogState extends State<ProductBranchesDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.product.branchIds};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sucursales del producto'),
      content: SizedBox(
        width: 540,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: widget.branches.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Primero registra una sucursal para configurar el producto.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      '${widget.product.name} · ${widget.product.sku}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.branches.map(
                      (branch) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(branch.name),
                        value: _selectedIds.contains(branch.id),
                        onChanged: (selected) {
                          setState(() {
                            if (selected ?? false) {
                              _selectedIds.add(branch.id);
                            } else {
                              _selectedIds.remove(branch.id);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: widget.branches.isEmpty
              ? null
              : () => Navigator.of(context).pop({..._selectedIds}),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
