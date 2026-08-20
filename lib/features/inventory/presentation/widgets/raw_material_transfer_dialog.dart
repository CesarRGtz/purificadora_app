import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../domain/validation/inventory_validators.dart';
import '../inventory_formatters.dart';

class RawMaterialTransferRequest {
  const RawMaterialTransferRequest({
    required this.destinationRawMaterialId,
    required this.quantity,
  });

  final String destinationRawMaterialId;
  final double quantity;
}

class RawMaterialTransferDialog extends StatefulWidget {
  const RawMaterialTransferDialog({
    super.key,
    required this.source,
    required this.rawMaterials,
    required this.branches,
  });

  final RawMaterial source;
  final List<RawMaterial> rawMaterials;
  final List<InventoryBranch> branches;

  static Future<RawMaterialTransferRequest?> show(
    BuildContext context, {
    required RawMaterial source,
    required List<RawMaterial> rawMaterials,
    required List<InventoryBranch> branches,
  }) {
    return showDialog<RawMaterialTransferRequest>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RawMaterialTransferDialog(
        source: source,
        rawMaterials: rawMaterials,
        branches: branches,
      ),
    );
  }

  @override
  State<RawMaterialTransferDialog> createState() =>
      _RawMaterialTransferDialogState();
}

class _RawMaterialTransferDialogState extends State<RawMaterialTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  late final Map<String, String> _branchNames;
  late final List<RawMaterial> _destinations;
  String? _destinationRawMaterialId;

  @override
  void initState() {
    super.initState();
    _branchNames = {
      for (final branch in widget.branches) branch.id: branch.name,
    };
    final normalizedName = _normalize(widget.source.name);
    final normalizedUnit = _normalize(widget.source.unit);
    _destinations =
        widget.rawMaterials
            .where(
              (material) =>
                  material.id != widget.source.id &&
                  material.branchId != widget.source.branchId &&
                  _normalize(material.name) == normalizedName &&
                  _normalize(material.unit) == normalizedUnit,
            )
            .toList(growable: false)
          ..sort(
            (left, right) => (_branchNames[left.branchId] ?? '').compareTo(
              _branchNames[right.branchId] ?? '',
            ),
          );
    if (_destinations.length == 1) {
      _destinationRawMaterialId = _destinations.first.id;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceBranch =
        _branchNames[widget.source.branchId] ?? 'Sucursal no disponible';
    return AlertDialog(
      title: const Text('Trasladar materia prima'),
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
                  widget.source.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Origen: $sourceBranch · Disponible: '
                  '${formatInventoryQuantity(widget.source.stock)} '
                  '${widget.source.unit}',
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 18),
                if (_destinations.isEmpty)
                  const Text(
                    'No existe el mismo insumo y unidad en otra sucursal. Regístralo primero en la sucursal de destino.',
                    style: TextStyle(color: Color(0xFFB45309), height: 1.4),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _destinationRawMaterialId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sucursal de destino *',
                      prefixIcon: Icon(Icons.store_mall_directory_outlined),
                    ),
                    items: _destinations
                        .map(
                          (material) => DropdownMenuItem(
                            value: material.id,
                            child: Text(
                              _branchNames[material.branchId] ??
                                  'Sucursal no disponible',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Selecciona la sucursal de destino'
                        : null,
                    onChanged: (value) =>
                        setState(() => _destinationRawMaterialId = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Cantidad a trasladar *',
                      suffixText: widget.source.unit,
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateQuantity,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'La salida y la entrada se guardarán juntas. Si alguna validación falla, no se modificará ninguna sucursal.',
                    style: TextStyle(color: Colors.black54, height: 1.4),
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
          onPressed: _destinations.isEmpty ? null : _submit,
          icon: const Icon(Icons.compare_arrows),
          label: const Text('Trasladar'),
        ),
      ],
    );
  }

  String? _validateQuantity(String? value) {
    final validation = InventoryValidators.inventoryQuantity(
      value,
      label: 'La cantidad',
    );
    if (validation != null) return validation;
    final quantity = InventoryValidators.parseDecimal(value!);
    if (quantity > widget.source.stock + 0.0000001) {
      return 'La cantidad supera la existencia disponible';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      RawMaterialTransferRequest(
        destinationRawMaterialId: _destinationRawMaterialId!,
        quantity: InventoryValidators.parseDecimal(_quantityController.text),
      ),
    );
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
