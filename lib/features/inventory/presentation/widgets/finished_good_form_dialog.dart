import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../domain/validation/inventory_validators.dart';
import '../inventory_formatters.dart';

class FinishedGoodFormDialog extends StatefulWidget {
  const FinishedGoodFormDialog({
    super.key,
    required this.branches,
    required this.products,
    this.item,
  });

  final List<InventoryBranch> branches;
  final List<InventoryProduct> products;
  final FinishedGood? item;

  static Future<FinishedGood?> show(
    BuildContext context, {
    required List<InventoryBranch> branches,
    required List<InventoryProduct> products,
    FinishedGood? item,
  }) {
    return showDialog<FinishedGood>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FinishedGoodFormDialog(
        branches: branches,
        products: products,
        item: item,
      ),
    );
  }

  @override
  State<FinishedGoodFormDialog> createState() => _FinishedGoodFormDialogState();
}

class _FinishedGoodFormDialogState extends State<FinishedGoodFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _quantityController;
  String? _branchId;
  String? _productId;
  late FinishedGoodStatus _status;
  late bool _isSellable;

  bool get _isEditing => widget.item != null;

  List<InventoryProduct> get _availableProducts => widget.products
      .where(
        (product) => _branchId != null && product.branchIds.contains(_branchId),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _branchId =
        item?.branchId ??
        (widget.branches.length == 1 ? widget.branches.first.id : null);
    final currentProductId = item?.productId;
    _productId =
        currentProductId != null &&
            widget.products.any(
              (product) =>
                  product.id == currentProductId &&
                  product.branchIds.contains(_branchId),
            )
        ? currentProductId
        : null;
    _status = item?.status ?? FinishedGoodStatus.purchased;
    _isSellable = item?.isSellable ?? true;
    _nameController = TextEditingController(text: item?.name);
    _typeController = TextEditingController(text: item?.type);
    _quantityController = TextEditingController(
      text: item?.quantity.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing
            ? 'Editar producto terminado'
            : 'Registrar producto terminado',
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('finished-branch-$_branchId'),
                  initialValue: _branchId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sucursal *',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  items: widget.branches
                      .map(
                        (branch) => DropdownMenuItem(
                          value: branch.id,
                          child: Text(
                            branch.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  validator: InventoryValidators.branchId,
                  onChanged: (value) {
                    setState(() {
                      _branchId = value;
                      if (!_availableProducts.any(
                        (product) => product.id == _productId,
                      )) {
                        _productId = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  key: ValueKey('finished-product-$_branchId-$_productId'),
                  initialValue: _productId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Producto del catálogo (opcional)',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Activo sin producto asociado'),
                    ),
                    ..._availableProducts.map(
                      (product) => DropdownMenuItem<String?>(
                        value: product.id,
                        child: Text(
                          '${product.name} · ${product.sku}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _productId = value);
                    if (value != null && _nameController.text.trim().isEmpty) {
                      final product = _availableProducts.firstWhere(
                        (candidate) => candidate.id == value,
                      );
                      _nameController.text = product.name;
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del activo *',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 200,
                  validator: InventoryValidators.name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo *',
                    hintText: 'Garrafón, botella, exhibidor…',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 100,
                  validator: InventoryValidators.type,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FinishedGoodStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Estado *',
                    prefixIcon: Icon(Icons.fact_check_outlined),
                  ),
                  items: FinishedGoodStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad *',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => InventoryValidators.nonNegativeInteger(
                    value,
                    label: 'La cantidad',
                  ),
                ),
                const SizedBox(height: 4),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Es vendible'),
                  subtitle: const Text(
                    'Indica si este activo puede ofrecerse para venta.',
                  ),
                  value: _isSellable,
                  onChanged: (value) => setState(() => _isSellable = value),
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
          icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
          label: Text(_isEditing ? 'Guardar cambios' : 'Registrar'),
        ),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final current = widget.item;
    Navigator.of(context).pop(
      FinishedGood(
        id: current?.id ?? '',
        branchId: _branchId!,
        productId: _productId,
        name: _nameController.text.trim(),
        type: _typeController.text.trim(),
        status: _status,
        quantity: int.parse(_quantityController.text.trim()),
        isSellable: _isSellable,
        createdAt: current?.createdAt,
        updatedAt: current?.updatedAt,
        deletedAt: current?.deletedAt,
      ),
    );
  }
}
