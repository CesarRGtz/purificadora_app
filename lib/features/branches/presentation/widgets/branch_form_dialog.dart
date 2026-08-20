import 'package:flutter/material.dart';

import '../../domain/entities/branch.dart';
import '../../domain/validation/branch_validators.dart';

class BranchFormDialog extends StatefulWidget {
  const BranchFormDialog({super.key, this.branch});

  final Branch? branch;

  static Future<Branch?> show(BuildContext context, {Branch? branch}) {
    return showDialog<Branch>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BranchFormDialog(branch: branch),
    );
  }

  @override
  State<BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _businessController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  bool get _isEditing => widget.branch != null;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _nameController = TextEditingController(text: branch?.name);
    _businessController = TextEditingController(text: branch?.businessName);
    _addressController = TextEditingController(text: branch?.address);
    _latitudeController = TextEditingController(
      text: branch?.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: branch?.longitude.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar sucursal' : 'Registrar sucursal'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Sucursal *',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  validator: BranchValidators.name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _businessController,
                  decoration: const InputDecoration(
                    labelText: 'Negocio *',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 200,
                  validator: BranchValidators.businessName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 500,
                  validator: BranchValidators.address,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitud *',
                          hintText: '29.0729',
                          prefixIcon: Icon(Icons.my_location),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: BranchValidators.latitude,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitud *',
                          hintText: '-110.9559',
                          prefixIcon: Icon(Icons.explore_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        textInputAction: TextInputAction.done,
                        validator: BranchValidators.longitude,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ),
                  ],
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
          icon: Icon(_isEditing ? Icons.save_outlined : Icons.add_business),
          label: Text(_isEditing ? 'Guardar cambios' : 'Registrar'),
        ),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final current = widget.branch;
    Navigator.of(context).pop(
      Branch(
        id: current?.id ?? '',
        name: _nameController.text.trim(),
        businessName: _businessController.text.trim(),
        address: _addressController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        createdAt: current?.createdAt,
        updatedAt: current?.updatedAt,
        deletedAt: current?.deletedAt,
      ),
    );
  }
}
