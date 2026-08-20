import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/company.dart';
import '../../domain/validation/company_validators.dart';

class CompanyFormDialog extends StatefulWidget {
  const CompanyFormDialog({super.key, this.company});

  final Company? company;

  static Future<Company?> show(BuildContext context, {Company? company}) {
    return showDialog<Company>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompanyFormDialog(company: company),
    );
  }

  @override
  State<CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends State<CompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessNameController;
  late final TextEditingController _rfcController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;

  bool get _isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    final company = widget.company;
    _businessNameController = TextEditingController(
      text: company?.businessName,
    );
    _rfcController = TextEditingController(text: company?.rfc);
    _addressController = TextEditingController(text: company?.address);
    _phoneController = TextEditingController(text: company?.phone);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _rfcController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar empresa' : 'Registrar empresa'),
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
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Razón social *',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 200,
                  validator: CompanyValidators.businessName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rfcController,
                  decoration: const InputDecoration(
                    labelText: 'RFC *',
                    hintText: 'ABC123456XYZ',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  maxLength: 13,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9Ññ&]'),
                    ),
                    _UpperCaseTextFormatter(),
                  ],
                  validator: CompanyValidators.rfc,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección fiscal *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 500,
                  validator: CompanyValidators.address,
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
                  validator: CompanyValidators.phone,
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

    final current = widget.company;
    Navigator.of(context).pop(
      Company(
        id: current?.id ?? '',
        businessName: _businessNameController.text.trim(),
        rfc: CompanyValidators.normalizeRfc(_rfcController.text),
        address: _addressController.text.trim(),
        phone: CompanyValidators.normalizePhone(_phoneController.text),
        createdAt: current?.createdAt,
        updatedAt: current?.updatedAt,
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
