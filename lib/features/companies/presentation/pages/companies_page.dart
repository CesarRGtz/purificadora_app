import 'package:flutter/material.dart';

import '../../../../widgets/toast_helper.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/usecases/create_company.dart';
import '../../domain/usecases/delete_company.dart';
import '../../domain/usecases/get_companies.dart';
import '../../domain/usecases/update_company.dart';
import '../controllers/companies_controller.dart';
import '../widgets/companies_table.dart';
import '../widgets/company_form_dialog.dart';

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({
    super.key,
    required this.repository,
    this.isOfflineMode = false,
    this.onExitOfflineMode,
  });

  final CompanyRepository repository;
  final bool isOfflineMode;
  final VoidCallback? onExitOfflineMode;

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  late final CompaniesController _controller;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = CompaniesController(
      getCompanies: GetCompanies(widget.repository),
      createCompany: CreateCompany(widget.repository),
      updateCompany: UpdateCompany(widget.repository),
      deleteCompany: DeleteCompany(widget.repository),
    );
    _controller.loadCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final filteredCompanies = _filterCompanies(_controller.companies);
        return RefreshIndicator(
          onRefresh: _controller.loadCompanies,
          child: ListView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildHeader(context),
              if (widget.isOfflineMode) ...[
                const SizedBox(height: 16),
                _buildOfflineBanner(),
              ],
              const SizedBox(height: 24),
              _buildSearchAndSummary(context, filteredCompanies.length),
              const SizedBox(height: 16),
              _buildContent(filteredCompanies),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, color: Color(0xFFB45309)),
          const Text(
            'Modo local de prueba: los cambios son temporales y se perderán al cerrar la aplicación.',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.onExitOfflineMode != null)
            TextButton(
              onPressed: widget.onExitOfflineMode,
              child: const Text('Ver configuración de Supabase'),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Empresas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2B528A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Administra los datos fiscales que se utilizarán en facturación.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _controller.isSubmitting ? null : _openCreateDialog,
          icon: const Icon(Icons.add_business),
          label: const Text('Registrar empresa'),
        ),
      ],
    );
  }

  Widget _buildSearchAndSummary(BuildContext context, int visibleCount) {
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: constraints.maxWidth < 380 ? constraints.maxWidth : 380,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por razón social, RFC, dirección o teléfono',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Chip(
            avatar: const Icon(Icons.business_outlined, size: 18),
            label: Text(
              _query.trim().isEmpty
                  ? '${_controller.companies.length} empresas'
                  : '$visibleCount resultados',
            ),
          ),
          if (_controller.isSubmitting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Company> companies) {
    switch (_controller.status) {
      case CompaniesViewStatus.initial:
      case CompaniesViewStatus.loading:
        return const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        );
      case CompaniesViewStatus.failure:
        return _ErrorState(
          message:
              _controller.errorMessage ?? 'No fue posible cargar los datos.',
          onRetry: _controller.loadCompanies,
        );
      case CompaniesViewStatus.ready:
        if (companies.isEmpty) {
          return _EmptyState(
            isSearching: _query.trim().isNotEmpty,
            onCreate: _controller.isSubmitting ? null : _openCreateDialog,
          );
        }
        return CompaniesTable(
          companies: companies,
          onEdit: _openEditDialog,
          onDelete: _confirmDelete,
          actionsEnabled: !_controller.isSubmitting,
        );
    }
  }

  List<Company> _filterCompanies(List<Company> companies) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return companies;

    return companies
        .where((company) {
          return company.businessName.toLowerCase().contains(query) ||
              company.rfc.toLowerCase().contains(query) ||
              company.address.toLowerCase().contains(query) ||
              company.phone.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _openCreateDialog() async {
    final company = await CompanyFormDialog.show(context);
    if (company == null || !mounted) return;

    final wasCreated = await _controller.createCompany(company);
    if (!mounted) return;
    ToastHelper.show(
      context,
      wasCreated
          ? 'Empresa registrada correctamente.'
          : _controller.operationError ??
                'No fue posible registrar la empresa.',
      type: wasCreated ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _openEditDialog(Company current) async {
    final company = await CompanyFormDialog.show(context, company: current);
    if (company == null || !mounted) return;

    final wasUpdated = await _controller.updateCompany(company);
    if (!mounted) return;
    ToastHelper.show(
      context,
      wasUpdated
          ? 'Empresa actualizada correctamente.'
          : _controller.operationError ??
                'No fue posible actualizar la empresa.',
      type: wasUpdated ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _confirmDelete(Company company) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar empresa'),
        content: Text(
          '¿Deseas eliminar “${company.businessName}”? Se ocultará del catálogo, pero se conservará en el historial.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final wasDeleted = await _controller.deleteCompany(company.id);
    if (!mounted) return;
    ToastHelper.show(
      context,
      wasDeleted
          ? 'Empresa eliminada correctamente.'
          : _controller.operationError ?? 'No fue posible eliminar la empresa.',
      type: wasDeleted ? ToastType.success : ToastType.error,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearching, required this.onCreate});

  final bool isSearching;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
        child: Column(
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.business_outlined,
              size: 48,
              color: Colors.black38,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? 'No encontramos empresas con ese criterio.'
                  : 'Aún no hay empresas registradas.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Registrar la primera empresa'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
