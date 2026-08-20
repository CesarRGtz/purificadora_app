import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../domain/validation/inventory_validators.dart';
import '../inventory_formatters.dart';

class RawMaterialMovementDialog extends StatefulWidget {
  const RawMaterialMovementDialog({
    super.key,
    required this.material,
    required this.products,
  });

  final RawMaterial material;
  final List<InventoryProduct> products;

  static Future<RawMaterialMovement?> show(
    BuildContext context, {
    required RawMaterial material,
    required List<InventoryProduct> products,
  }) {
    return showDialog<RawMaterialMovement>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          RawMaterialMovementDialog(material: material, products: products),
    );
  }

  @override
  State<RawMaterialMovementDialog> createState() =>
      _RawMaterialMovementDialogState();
}

class _RawMaterialMovementDialogState extends State<RawMaterialMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  late final TextEditingController _costController;
  RawMaterialMovementType _type = RawMaterialMovementType.purchase;
  String? _productId;

  bool get _isPurchase => _type == RawMaterialMovementType.purchase;
  bool get _isUse => _type == RawMaterialMovementType.use;

  List<InventoryProduct> get _availableProducts => widget.products
      .where((product) => product.branchIds.contains(widget.material.branchId))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(
      text: formatInventoryUnitCostInput(widget.material.lastUnitCost),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar movimiento'),
      content: SizedBox(
        width: 500,
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
                const SizedBox(height: 4),
                Text(
                  'Existencia actual: ${formatInventoryQuantity(widget.material.stock)} ${widget.material.unit}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<RawMaterialMovementType>(
                  initialValue: _type,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de movimiento *',
                    prefixIcon: Icon(Icons.swap_vert),
                  ),
                  items:
                      const [
                            RawMaterialMovementType.purchase,
                            RawMaterialMovementType.use,
                          ]
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(growable: false),
                  onChanged: (value) {
                    setState(() {
                      _type = value ?? _type;
                      if (!_isUse) _productId = null;
                    });
                  },
                ),
                if (_isUse) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _productId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Producto que utilizó el insumo *',
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
                    onChanged: (value) => setState(() => _productId = value),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad *',
                    suffixText: widget.material.unit,
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) => InventoryValidators.inventoryQuantity(
                    value,
                    label: 'La cantidad',
                  ),
                ),
                if (_isPurchase) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Costo unitario *',
                      prefixText: r'$ ',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        InventoryValidators.unitCost(value, label: 'El costo'),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Las compras aumentan existencias y el uso las reduce. Los traslados entre sucursales se registran desde su acción independiente.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
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
          onPressed: _submit,
          icon: const Icon(Icons.add_task),
          label: const Text('Registrar'),
        ),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      RawMaterialMovement(
        rawMaterialId: widget.material.id,
        type: _type,
        quantity: InventoryValidators.parseDecimal(_quantityController.text),
        unitCost: _isPurchase
            ? InventoryValidators.parseDecimal(_costController.text)
            : null,
        productId: _isUse ? _productId : null,
        createdAt: DateTime.now(),
      ),
    );
  }
}
