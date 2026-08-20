class SupplierException implements Exception {
  const SupplierException(this.message);

  final String message;

  @override
  String toString() => message;
}
