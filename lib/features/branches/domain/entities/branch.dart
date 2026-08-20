class Branch {
  const Branch({
    required this.name,
    required this.businessName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.id = '',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String businessName;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}
