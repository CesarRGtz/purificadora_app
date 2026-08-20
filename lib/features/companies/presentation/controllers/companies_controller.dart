import 'package:flutter/foundation.dart';

import '../../domain/entities/company.dart';
import '../../domain/errors/company_exception.dart';
import '../../domain/usecases/create_company.dart';
import '../../domain/usecases/delete_company.dart';
import '../../domain/usecases/get_companies.dart';
import '../../domain/usecases/update_company.dart';

enum CompaniesViewStatus { initial, loading, ready, failure }

class CompaniesController extends ChangeNotifier {
  CompaniesController({
    required GetCompanies getCompanies,
    required CreateCompany createCompany,
    required UpdateCompany updateCompany,
    required DeleteCompany deleteCompany,
  }) : _getCompanies = getCompanies,
       _createCompany = createCompany,
       _updateCompany = updateCompany,
       _deleteCompany = deleteCompany;

  final GetCompanies _getCompanies;
  final CreateCompany _createCompany;
  final UpdateCompany _updateCompany;
  final DeleteCompany _deleteCompany;

  CompaniesViewStatus _status = CompaniesViewStatus.initial;
  List<Company> _companies = const [];
  String? _errorMessage;
  String? _operationError;
  bool _isSubmitting = false;
  bool _isDisposed = false;

  CompaniesViewStatus get status => _status;
  List<Company> get companies => List.unmodifiable(_companies);
  String? get errorMessage => _errorMessage;
  String? get operationError => _operationError;
  bool get isSubmitting => _isSubmitting;

  Future<void> loadCompanies() async {
    _status = CompaniesViewStatus.loading;
    _errorMessage = null;
    _notifySafely();

    try {
      _companies = await _getCompanies();
      _status = CompaniesViewStatus.ready;
    } catch (error) {
      _status = CompaniesViewStatus.failure;
      _errorMessage = _messageFor(error);
    }
    _notifySafely();
  }

  Future<bool> createCompany(Company company) async {
    return _runMutation(() async {
      final created = await _createCompany(company);
      _companies = [..._companies, created]..sort(_sortByBusinessName);
    });
  }

  Future<bool> updateCompany(Company company) async {
    return _runMutation(() async {
      final updated = await _updateCompany(company);
      _companies =
          _companies
              .map((current) => current.id == updated.id ? updated : current)
              .toList()
            ..sort(_sortByBusinessName);
    });
  }

  Future<bool> deleteCompany(String id) async {
    return _runMutation(() async {
      await _deleteCompany(id);
      _companies = _companies.where((company) => company.id != id).toList();
    });
  }

  Future<bool> _runMutation(Future<void> Function() operation) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _operationError = null;
    _notifySafely();

    try {
      await operation();
      _status = CompaniesViewStatus.ready;
      return true;
    } catch (error) {
      _operationError = _messageFor(error);
      return false;
    } finally {
      _isSubmitting = false;
      _notifySafely();
    }
  }

  String _messageFor(Object error) {
    if (error is CompanyException) return error.message;
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }

  static int _sortByBusinessName(Company a, Company b) =>
      a.businessName.toLowerCase().compareTo(b.businessName.toLowerCase());

  void _notifySafely() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
