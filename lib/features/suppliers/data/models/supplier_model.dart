import '../../domain/entities/supplier.dart';

class SupplierModel extends Supplier {
  const SupplierModel({
    required super.id,
    required super.branchName,
    required super.name,
    required super.address,
    required super.phone,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      branchName: json['branch_name'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(json['deleted_at'] as String? ?? ''),
    );
  }

  static Map<String, dynamic> toInsertJson(Supplier supplier) =>
      _writableFields(supplier);

  static Map<String, dynamic> toUpdateJson(Supplier supplier) =>
      _writableFields(supplier);

  static Map<String, dynamic> _writableFields(Supplier supplier) {
    return {
      'branch_name': supplier.branchName.trim(),
      'name': supplier.name.trim(),
      'address': supplier.address.trim(),
      'phone': supplier.phone.trim(),
    };
  }
}
