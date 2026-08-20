import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../domain/validation/inventory_validators.dart';
import '../inventory_formatters.dart';

class RawMaterialProductLink {
  const RawMaterialProductLink({
    required this.productId,
    required this.quantityPerUnit,
  });

  final String productId;
  final double quantityPerUnit;
}

class RawMaterialProductDialog extends StatefulWidget {
  const RawMaterialProductDialog({
    super.key,
    required this.material,
    required this.products,
    required this.requirements,
  });

  final RawMaterial material;
  final List<InventoryProduct> products;
  final List<ProductMaterialRequirement> requirements;

  static Future<RawMaterialProductLink?> show(
    BuildContext context, {
    required RawMaterial material,
    required List<InventoryProduct> products,
    required List<ProductMaterialRequirement> requirements,
  }) {
    return showDialog<RawMaterialProductLink>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RawMaterialProductDialog(
        material: material,
        products: products,
        requirements: requirements,
      ),
    );
  }

  @override
  State<RawMaterialProductDialog> createState() =>
      _RawMaterialProductDialogState();
}

class _RawMaterialProductDialogState extends State<RawMaterialProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  late final List<InventoryProduct> _availableProducts;
  String? _productId;

  @override
  void initState() {
    super.initState();
    _availableProducts = widget.products
        .where(
          (product) => product.branchIds.contains(widget.material.branchId),
        )
        .toList(growable: false);
    final linkedProductIds = widget.requirements
        .where((item) => item.rawMaterialId == widget.material.id)
        .map((item) => item.productId)
        .toSet();
    for (final product in _availableProducts) {
      if (linkedProductIds.contains(product.id)) {
        _selectProduct(product.id);
        break;
      }
    }
    if (_productId == null && _availableProducts.length == 1) {
      _selectProduct(_availableProducts.first.id);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vincular materia prima a producto'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.material.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Existencia: ${formatInventoryQuantity(widget.material.stock)} ${widget.material.unit}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                if (_availableProducts.isEmpty)
                  const Text(
                    'No hay productos asignados a la sucursal de este insumo. Configura primero las sucursales desde la categoría Productos.',
                    style: TextStyle(color: Color(0xFFB45309), height: 1.4),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _productId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Producto *',
                      prefixIcon: Icon(Icons.qr_code_2),
                    ),
                    items: _availableProducts
                        .map(
                          (product) => DropdownMenuItem(
                            value: product.id,
                            child: Text(
                              '${product.name} · ${product.sku}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Selecciona un producto'
                        : null,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectProduct(value));
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Cantidad utilizada por unidad *',
                      suffixText: widget.material.unit,
                      prefixIcon: const Icon(Icons.science_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => InventoryValidators.inventoryQuantity(
                      value,
                      label: 'La cantidad requerida',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _availableProducts.isEmpty ? null : _submit,
          icon: const Icon(Icons.link),
          label: const Text('Guardar vínculo'),
        ),
      ],
    );
  }

  void _selectProduct(String productId) {
    _productId = productId;
    ProductMaterialRequirement? existing;
    for (final requirement in widget.requirements) {
      if (requirement.productId == productId &&
          requirement.rawMaterialId == widget.material.id) {
        existing = requirement;
        break;
      }
    }
    _quantityController.text = existing == null
        ? '1'
        : formatInventoryQuantity(existing.quantityPerUnit);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      RawMaterialProductLink(
        productId: _productId!,
        quantityPerUnit: InventoryValidators.parseDecimal(
          _quantityController.text,
        ),
      ),
    );
  }
}
