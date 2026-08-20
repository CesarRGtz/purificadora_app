import '../../domain/entities/product.dart';
import '../../domain/validation/product_validators.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.sku,
    required super.description,
    required super.basePrice,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      description: json['description'] as String? ?? '',
      basePrice: (json['base_price'] as num).toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(json['deleted_at'] as String? ?? ''),
    );
  }

  static Map<String, dynamic> toInsertJson(Product product) =>
      _writableFields(product);

  static Map<String, dynamic> toUpdateJson(Product product) =>
      _writableFields(product);

  static Map<String, dynamic> _writableFields(Product product) {
    return {
      'name': product.name.trim(),
      'sku': ProductValidators.normalizeSku(product.sku),
      'description': product.description.trim(),
      'base_price': product.basePrice,
    };
  }
}
