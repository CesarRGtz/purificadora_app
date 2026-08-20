import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../domain/validation/inventory_validators.dart';
import '../inventory_formatters.dart';

class ProductConsumptionRequest {
  const ProductConsumptionRequest({
    required this.branchId,
    required this.quantity,
  });

  final String branchId;
  final int quantity;
}

class ConsumeProductDialog extends StatefulWidget {
  const ConsumeProductDialog({
    super.key,
    required this.product,
    required this.branches,
    required this.rawMaterials,
    required this.requirements,
  });

  final InventoryProduct product;
  final List<InventoryBranch> branches;
  final List<RawMaterial> rawMaterials;
  final List<ProductMaterialRequirement> requirements;

  static Future<ProductConsumptionRequest?> show(
    BuildContext context, {
    required InventoryProduct product,
    required List<InventoryBranch> branches,
    required List<RawMaterial> rawMaterials,
    required List<ProductMaterialRequirement> requirements,
  }) {
    return showDialog<ProductConsumptionRequest>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConsumeProductDialog(
        product: product,
        branches: branches,
        rawMaterials: rawMaterials,
        requirements: requirements,
      ),
    );
  }

  @override
  State<ConsumeProductDialog> createState() => _ConsumeProductDialogState();
}

class _ConsumeProductDialogState extends State<ConsumeProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  late final List<InventoryBranch> _availableBranches;
  String? _branchId;

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  List<(RawMaterial, ProductMaterialRequirement)> get _branchRequirements {
    if (_branchId == null) return const [];
    final materialsById = {
      for (final material in widget.rawMaterials)
        if (material.branchId == _branchId) material.id: material,
    };
    return widget.requirements
        .where((item) => item.productId == widget.product.id)
        .map((item) {
          final material = materialsById[item.rawMaterialId];
          return material == null ? null : (material, item);
        })
        .whereType<(RawMaterial, ProductMaterialRequirement)>()
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _availableBranches = widget.branches
        .where((branch) => widget.product.branchIds.contains(branch.id))
        .toList(growable: false);
    _branchId = _availableBranches.length == 1
        ? _availableBranches.first.id
        : null;
    _quantityController.addListener(_refreshSummary);
  }

  @override
  void dispose() {
    _quantityController
      ..removeListener(_refreshSummary)
      ..dispose();
    super.dispose();
  }

  void _refreshSummary() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar producción / uso'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.product.name} · ${widget.product.sku}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Esta acción descuenta los insumos definidos en la receta. Si alguno no alcanza, no se aplicará ningún descuento.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _branchId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sucursal *',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  items: _availableBranches
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
                  onChanged: (value) => setState(() => _branchId = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Unidades producidas / utilizadas *',
                    prefixIcon: Icon(Icons.precision_manufacturing_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => InventoryValidators.positiveInteger(
                    value,
                    label: 'La cantidad',
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Consumo calculado',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (_branchId == null)
                  const Text(
                    'Selecciona una sucursal para revisar la receta.',
                    style: TextStyle(color: Colors.black54),
                  )
                else if (_branchRequirements.isEmpty)
                  const Text(
                    'Este producto todavía no tiene insumos configurados para la sucursal seleccionada.',
                    style: TextStyle(color: Color(0xFFB45309)),
                  )
                else
                  ..._branchRequirements.map((entry) {
                    final material = entry.$1;
                    final requirement = entry.$2;
                    final needed = requirement.quantityPerUnit * _quantity;
                    final enough = material.stock + 1e-9 >= needed;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        enough
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: enough ? Colors.green : Colors.redAccent,
                      ),
                      title: Text(material.name),
                      subtitle: Text(
                        'Disponible: ${formatInventoryQuantity(material.stock)} ${material.unit}',
                      ),
                      trailing: Text(
                        '${formatInventoryQuantity(needed)} ${material.unit}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: enough ? Colors.black87 : Colors.redAccent,
                        ),
                      ),
                    );
                  }),
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
          onPressed: _availableBranches.isEmpty ? null : _submit,
          icon: const Icon(Icons.playlist_add_check),
          label: const Text('Aplicar consumo'),
        ),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_branchRequirements.isEmpty) return;
    Navigator.of(context).pop(
      ProductConsumptionRequest(
        branchId: _branchId!,
        quantity: int.parse(_quantityController.text.trim()),
      ),
    );
  }
}
