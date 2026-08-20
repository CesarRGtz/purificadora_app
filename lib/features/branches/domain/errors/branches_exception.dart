class BranchesException implements Exception {
  const BranchesException(this.message);

  final String message;

  @override
  String toString() => message;
}
