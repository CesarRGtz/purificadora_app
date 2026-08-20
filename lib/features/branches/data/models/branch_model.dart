import '../../domain/entities/branch.dart';

class BranchModel extends Branch {
  const BranchModel({
    required super.id,
    required super.name,
    required super.businessName,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as String,
      name: json['name'] as String,
      businessName: json['business_name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(json['deleted_at'] as String? ?? ''),
    );
  }

  static Map<String, dynamic> toInsertJson(Branch branch) =>
      _writableFields(branch);

  static Map<String, dynamic> toUpdateJson(Branch branch) =>
      _writableFields(branch);

  static Map<String, dynamic> _writableFields(Branch branch) {
    return {
      'name': branch.name.trim(),
      'business_name': branch.businessName.trim(),
      'address': branch.address.trim(),
      'latitude': branch.latitude,
      'longitude': branch.longitude,
    };
  }
}
