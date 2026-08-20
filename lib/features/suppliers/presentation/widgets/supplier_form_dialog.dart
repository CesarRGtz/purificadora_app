import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/supplier.dart';
import '../../domain/validation/supplier_validators.dart';

class SupplierFormDialog extends StatefulWidget {
  const SupplierFormDialog({super.key, this.supplier});

  final Supplier? supplier;

  static Future<Supplier?> show(BuildContext context, {Supplier? supplier}) {
    return showDialog<Supplier>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SupplierFormDialog(supplier: supplier),
    );
  }

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _branchController;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;

  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    _branchController = TextEditingController(text: supplier?.branchName);
    _nameController = TextEditingController(text: supplier?.name);
    _addressController = TextEditingController(text: supplier?.address);
    _phoneController = TextEditingController(text: supplier?.phone);
  }

  @override
  void dispose() {
    _branchController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar proveedor' : 'Registrar proveedor'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _branchController,
                  decoration: const InputDecoration(
                    labelText: 'Sucursal *',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  validator: SupplierValidators.branchName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.local_shipping_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 200,
                  validator: SupplierValidators.name,
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
                  validator: SupplierValidators.address,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    hintText: '6621234567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  maxLength: 22,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+() -]')),
                  ],
                  validator: SupplierValidators.phone,
                  onFieldSubmitted: (_) => _submit(),
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
    final current = widget.supplier;
    Navigator.of(context).pop(
      Supplier(
        id: current?.id ?? '',
        branchName: _branchController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: SupplierValidators.normalizePhone(_phoneController.text),
        createdAt: current?.createdAt,
        updatedAt: current?.updatedAt,
        deletedAt: current?.deletedAt,
      ),
    );
  }
}
