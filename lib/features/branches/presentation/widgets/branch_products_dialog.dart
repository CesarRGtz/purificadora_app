import 'package:flutter/material.dart';

import '../../../../widgets/toast_helper.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/product.dart';
import '../controllers/branches_controller.dart';

class BranchProductsDialog extends StatefulWidget {
  const BranchProductsDialog({
    super.key,
    required this.branch,
    required this.controller,
  });

  final Branch branch;
  final BranchesController controller;

  static Future<void> show(
    BuildContext context, {
    required Branch branch,
    required BranchesController controller,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          BranchProductsDialog(branch: branch, controller: controller),
    );
  }

  @override
  State<BranchProductsDialog> createState() => _BranchProductsDialogState();
}

class _BranchProductsDialogState extends State<BranchProductsDialog> {
  late Set<String> _selectedIds;
  String _query = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.controller.selectedProductIds};
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts(widget.controller.products);
    return AlertDialog(
      title: Text('Productos de ${widget.branch.name}'),
      content: SizedBox(
        width: 680,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona los productos disponibles exclusivamente para esta sucursal.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o SKU',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text('${_selectedIds.length} seleccionados'),
                ),
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(
                          () => _selectedIds = widget.controller.products
                              .map((product) => product.id)
                              .toSet(),
                        ),
                  child: const Text('Seleccionar todos'),
                ),
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(_selectedIds.clear),
                  child: const Text('Limpiar'),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('No hay productos que mostrar.'))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return CheckboxListTile(
                          value: _selectedIds.contains(product.id),
                          onChanged: _isSaving
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected ?? false) {
                                      _selectedIds.add(product.id);
                                    } else {
                                      _selectedIds.remove(product.id);
                                    }
                                  });
                                },
                          title: Text(product.name),
                          subtitle: Text(
                            '${product.sku} · \$${product.basePrice.toStringAsFixed(2)}',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar configuración'),
        ),
      ],
    );
  }

  List<Product> _filteredProducts(List<Product> products) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products
        .where((product) {
          return product.name.toLowerCase().contains(query) ||
              product.sku.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final success = await widget.controller.saveProductConfiguration(
      widget.branch.id,
      _selectedIds,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ToastHelper.show(
        context,
        'Productos de la sucursal actualizados correctamente.',
        type: ToastType.success,
      );
      return;
    }
    setState(() => _isSaving = false);
    ToastHelper.show(
      context,
      widget.controller.operationError ??
          'No fue posible guardar la configuración.',
      type: ToastType.error,
    );
  }
}
