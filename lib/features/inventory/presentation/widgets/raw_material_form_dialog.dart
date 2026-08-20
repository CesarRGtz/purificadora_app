import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../domain/validation/inventory_validators.dart';
import '../inventory_formatters.dart';

class RawMaterialFormDialog extends StatefulWidget {
  const RawMaterialFormDialog({
    super.key,
    required this.branches,
    this.material,
  });

  final List<InventoryBranch> branches;
  final RawMaterial? material;

  static Future<RawMaterial?> show(
    BuildContext context, {
    required List<InventoryBranch> branches,
    RawMaterial? material,
  }) {
    return showDialog<RawMaterial>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          RawMaterialFormDialog(branches: branches, material: material),
    );
  }

  @override
  State<RawMaterialFormDialog> createState() => _RawMaterialFormDialogState();
}

class _RawMaterialFormDialogState extends State<RawMaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _categoryController;
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _costController;
  String? _branchId;

  bool get _isEditing => widget.material != null;

  @override
  void initState() {
    super.initState();
    final material = widget.material;
    _branchId =
        material?.branchId ??
        (widget.branches.length == 1 ? widget.branches.first.id : null);
    _categoryController = TextEditingController(text: material?.category);
    _nameController = TextEditingController(text: material?.name);
    _unitController = TextEditingController(text: material?.unit);
    _costController = TextEditingController(
      text: material == null
          ? '0.00'
          : formatInventoryUnitCostInput(material.lastUnitCost),
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Editar materia prima' : 'Registrar materia prima',
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
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
                  onChanged: (value) => setState(() => _branchId = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Categoría *',
                    hintText: 'Empaque, químico, envase…',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 100,
                  validator: InventoryValidators.category,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 200,
                  validator: InventoryValidators.name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unidad *',
                    hintText: 'Piezas, litros, kg…',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 50,
                  validator: InventoryValidators.unit,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(
                    labelText: 'Último costo unitario *',
                    prefixText: r'$ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                    helperText:
                        'Se actualizará automáticamente con cada compra.',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      InventoryValidators.unitCost(value, label: 'El costo'),
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
    final current = widget.material;
    Navigator.of(context).pop(
      RawMaterial(
        id: current?.id ?? '',
        branchId: _branchId!,
        category: _categoryController.text.trim(),
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
        lastUnitCost: InventoryValidators.parseDecimal(_costController.text),
        purchased: current?.purchased ?? 0,
        used: current?.used ?? 0,
        transferIn: current?.transferIn ?? 0,
        transferOut: current?.transferOut ?? 0,
        createdAt: current?.createdAt,
        updatedAt: current?.updatedAt,
        deletedAt: current?.deletedAt,
      ),
    );
  }
}
