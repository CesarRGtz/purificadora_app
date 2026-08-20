class Company {
  const Company({
    required this.businessName,
    required this.rfc,
    required this.address,
    required this.phone,
    this.id = '',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String businessName;
  final String rfc;
  final String address;
  final String phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}
