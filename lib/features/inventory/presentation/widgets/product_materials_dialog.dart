import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../domain/validation/inventory_validators.dart';
import '../inventory_formatters.dart';

class ProductMaterialsDialog extends StatefulWidget {
  const ProductMaterialsDialog({
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

  static Future<Map<String, double>?> show(
    BuildContext context, {
    required InventoryProduct product,
    required List<InventoryBranch> branches,
    required List<RawMaterial> rawMaterials,
    required List<ProductMaterialRequirement> requirements,
  }) {
    return showDialog<Map<String, double>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductMaterialsDialog(
        product: product,
        branches: branches,
        rawMaterials: rawMaterials,
        requirements: requirements,
      ),
    );
  }

  @override
  State<ProductMaterialsDialog> createState() => _ProductMaterialsDialogState();
}

class _ProductMaterialsDialogState extends State<ProductMaterialsDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _quantityControllers = {};
  late final List<RawMaterial> _availableMaterials;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _availableMaterials =
        widget.rawMaterials
            .where(
              (material) =>
                  widget.product.branchIds.contains(material.branchId),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final branchCompare = a.branchId.compareTo(b.branchId);
            if (branchCompare != 0) return branchCompare;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    final existing = {
      for (final requirement in widget.requirements)
        if (requirement.productId == widget.product.id)
          requirement.rawMaterialId: requirement.quantityPerUnit,
    };
    _selectedIds = existing.keys
        .where((id) => _availableMaterials.any((item) => item.id == id))
        .toSet();
    for (final material in _availableMaterials) {
      _quantityControllers[material.id] = TextEditingController(
        text: existing[material.id] == null
            ? '1'
            : formatInventoryQuantity(existing[material.id]!),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAssignedBranches = widget.product.branchIds.isNotEmpty;
    return AlertDialog(
      title: const Text('Insumos por unidad de producto'),
      content: SizedBox(
        width: 680,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: !hasAssignedBranches
              ? const _RecipeEmptyState(
                  message: 'Primero asigna el producto a una o más sucursales.',
                )
              : _availableMaterials.isEmpty
              ? const _RecipeEmptyState(
                  message:
                      'No hay materias primas registradas en las sucursales de este producto.',
                )
              : Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text(
                        '${widget.product.name} · define cuánto insumo se consume por cada unidad producida.',
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ..._availableMaterials.map(_buildMaterialTile),
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
          onPressed: _availableMaterials.isEmpty ? null : _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar receta'),
        ),
      ],
    );
  }

  Widget _buildMaterialTile(RawMaterial material) {
    final selected = _selectedIds.contains(material.id);
    final branch = widget.branches
        .where((item) => item.id == material.branchId)
        .firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                material.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${branch?.name ?? 'Sucursal no disponible'} · existencia ${formatInventoryQuantity(material.stock)} ${material.unit}',
              ),
              value: selected,
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _selectedIds.add(material.id);
                  } else {
                    _selectedIds.remove(material.id);
                  }
                });
              },
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  key: ValueKey('recipe-quantity-${material.id}'),
                  controller: _quantityControllers[material.id],
                  decoration: InputDecoration(
                    labelText: 'Cantidad por unidad de producto',
                    suffixText: material.unit,
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
              ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop({
      for (final materialId in _selectedIds)
        materialId: InventoryValidators.parseDecimal(
          _quantityControllers[materialId]!.text,
        ),
    });
  }
}

class _RecipeEmptyState extends StatelessWidget {
  const _RecipeEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 44,
            color: Colors.black38,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
