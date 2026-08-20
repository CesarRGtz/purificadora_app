class Supplier {
  const Supplier({
    required this.branchName,
    required this.name,
    required this.address,
    required this.phone,
    this.id = '',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String branchName;
  final String name;
  final String address;
  final String phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}
