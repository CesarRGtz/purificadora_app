import 'package:flutter/material.dart';

import '../../../../widgets/toast_helper.dart';
import '../../domain/entities/product.dart';
import '../controllers/branches_controller.dart';
import 'product_form_dialog.dart';

class ProductManagementDialog extends StatelessWidget {
  const ProductManagementDialog({super.key, required this.controller});

  final BranchesController controller;

  static Future<void> show(
    BuildContext context, {
    required BranchesController controller,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductManagementDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Catálogo de productos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: controller.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Text(
                    'Estos productos pueden habilitarse de forma independiente en cada sucursal.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: controller.isSubmitting
                          ? null
                          : () => _openProductForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo producto'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildContent(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (controller.isProductsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.productsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(controller.productsError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (controller.products.isEmpty) {
      return const Center(child: Text('Aún no hay productos registrados.'));
    }

    return ListView.separated(
      itemCount: controller.products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = controller.products[index];
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.inventory_2_outlined, size: 20),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${product.sku} · Precio base: \$${product.basePrice.toStringAsFixed(2)}'
            '${product.description.isEmpty ? '' : '\n${product.description}'}',
          ),
          isThreeLine: product.description.isNotEmpty,
          trailing: PopupMenuButton<_ProductAction>(
            enabled: !controller.isSubmitting,
            tooltip: 'Acciones del producto',
            onSelected: (action) async {
              switch (action) {
                case _ProductAction.edit:
                  await _openProductForm(context, product: product);
                  break;
                case _ProductAction.delete:
                  await _confirmDelete(context, product);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _ProductAction.edit,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar'),
                ),
              ),
              PopupMenuItem(
                value: _ProductAction.delete,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                  title: Text('Eliminar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openProductForm(
    BuildContext context, {
    Product? product,
  }) async {
    final result = await ProductFormDialog.show(context, product: product);
    if (result == null || !context.mounted) return;
    final success = product == null
        ? await controller.createProduct(result)
        : await controller.updateProduct(result);
    if (!context.mounted) return;
    ToastHelper.show(
      context,
      success
          ? product == null
                ? 'Producto registrado correctamente.'
                : 'Producto actualizado correctamente.'
          : controller.operationError ?? 'No fue posible guardar el producto.',
      type: success ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Deseas eliminar “${product.name}”? Se conservará en el historial y dejará de estar disponible en las sucursales.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await controller.deleteProduct(product.id);
    if (!context.mounted) return;
    ToastHelper.show(
      context,
      success
          ? 'Producto eliminado correctamente.'
          : controller.operationError ?? 'No fue posible eliminar el producto.',
      type: success ? ToastType.success : ToastType.error,
    );
  }
}

enum _ProductAction { edit, delete }
