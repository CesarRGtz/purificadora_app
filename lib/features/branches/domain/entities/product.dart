class Product {
  const Product({
    required this.name,
    required this.sku,
    required this.basePrice,
    this.description = '',
    this.id = '',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String sku;
  final String description;
  final double basePrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}
