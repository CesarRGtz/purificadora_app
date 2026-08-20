class CompanyException implements Exception {
  const CompanyException(this.message);

  final String message;

  @override
  String toString() => message;
}
