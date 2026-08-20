import '../../domain/entities/company.dart';

class CompanyModel extends Company {
  const CompanyModel({
    required super.id,
    required super.businessName,
    required super.rfc,
    required super.address,
    required super.phone,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      rfc: json['rfc'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(json['deleted_at'] as String? ?? ''),
    );
  }

  static Map<String, dynamic> toInsertJson(Company company) =>
      _writableFields(company);

  static Map<String, dynamic> toUpdateJson(Company company) =>
      _writableFields(company);

  static Map<String, dynamic> _writableFields(Company company) {
    return {
      'business_name': company.businessName.trim(),
      'rfc': company.rfc.trim().toUpperCase(),
      'address': company.address.trim(),
      'phone': company.phone.trim(),
    };
  }
}
