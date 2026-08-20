import 'package:flutter/material.dart';

import '../../../../widgets/toast_helper.dart';
import '../../domain/entities/branch.dart';
import '../../domain/repositories/branches_repository.dart';
import '../../domain/usecases/branch_use_cases.dart';
import '../../domain/usecases/product_use_cases.dart';
import '../controllers/branches_controller.dart';
import '../widgets/branch_form_dialog.dart';
import '../widgets/branch_products_dialog.dart';
import '../widgets/branches_table.dart';
import '../widgets/product_management_dialog.dart';

class BranchesPage extends StatefulWidget {
  const BranchesPage({
    super.key,
    required this.repository,
    this.isOfflineMode = false,
    this.onExitOfflineMode,
  });

  final BranchesRepository repository;
  final bool isOfflineMode;
  final VoidCallback? onExitOfflineMode;

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  late final BranchesController _controller;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final repository = widget.repository;
    _controller = BranchesController(
      getBranches: GetBranches(repository),
      createBranch: CreateBranch(repository),
      updateBranch: UpdateBranch(repository),
      deleteBranch: DeleteBranch(repository),
      getProducts: GetProducts(repository),
      createProduct: CreateProduct(repository),
      updateProduct: UpdateProduct(repository),
      deleteProduct: DeleteProduct(repository),
      getBranchProductIds: GetBranchProductIds(repository),
      configureBranchProducts: ConfigureBranchProducts(repository),
    );
    _controller.loadBranches();
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
        final filteredBranches = _filterBranches(_controller.branches);
        return RefreshIndicator(
          onRefresh: _controller.loadBranches,
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
              _buildSearchAndSummary(filteredBranches.length),
              const SizedBox(height: 16),
              _buildContent(filteredBranches),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sucursales',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2B528A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gestiona ubicaciones y define qué productos ofrece cada una.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed:
                  _controller.isSubmitting || _controller.isProductsLoading
                  ? null
                  : _manageProducts,
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Gestionar productos'),
            ),
            ElevatedButton.icon(
              onPressed: _controller.isSubmitting ? null : _openCreateDialog,
              icon: const Icon(Icons.add_business),
              label: const Text('Registrar sucursal'),
            ),
          ],
        ),
      ],
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
            'Modo local de prueba: sucursales, productos y configuraciones son temporales.',
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

  Widget _buildSearchAndSummary(int visibleCount) {
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: constraints.maxWidth < 410 ? constraints.maxWidth : 410,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por sucursal, negocio o dirección',
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
            avatar: const Icon(Icons.store_outlined, size: 18),
            label: Text(
              _query.trim().isEmpty
                  ? '${_controller.branches.length} sucursales'
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

  Widget _buildContent(List<Branch> branches) {
    switch (_controller.status) {
      case BranchesViewStatus.initial:
      case BranchesViewStatus.loading:
        return const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        );
      case BranchesViewStatus.failure:
        return _ErrorState(
          message:
              _controller.errorMessage ??
              'No fue posible cargar las sucursales.',
          onRetry: _controller.loadBranches,
        );
      case BranchesViewStatus.ready:
        if (branches.isEmpty) {
          return _EmptyState(
            isSearching: _query.trim().isNotEmpty,
            onCreate: _controller.isSubmitting ? null : _openCreateDialog,
          );
        }
        return BranchesTable(
          branches: branches,
          onConfigureProducts: _configureProducts,
          onEdit: _openEditDialog,
          onDelete: _confirmDelete,
          actionsEnabled:
              !_controller.isSubmitting && !_controller.isProductsLoading,
        );
    }
  }

  List<Branch> _filterBranches(List<Branch> branches) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return branches;
    return branches
        .where((branch) {
          return branch.name.toLowerCase().contains(query) ||
              branch.businessName.toLowerCase().contains(query) ||
              branch.address.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _openCreateDialog() async {
    final branch = await BranchFormDialog.show(context);
    if (branch == null || !mounted) return;
    final success = await _controller.createBranch(branch);
    _showResult(
      success,
      success
          ? 'Sucursal registrada correctamente.'
          : _controller.operationError ??
                'No fue posible registrar la sucursal.',
    );
  }

  Future<void> _openEditDialog(Branch current) async {
    final branch = await BranchFormDialog.show(context, branch: current);
    if (branch == null || !mounted) return;
    final success = await _controller.updateBranch(branch);
    _showResult(
      success,
      success
          ? 'Sucursal actualizada correctamente.'
          : _controller.operationError ??
                'No fue posible actualizar la sucursal.',
    );
  }

  Future<void> _manageProducts() async {
    await _controller.loadProducts();
    if (!mounted) return;
    await ProductManagementDialog.show(context, controller: _controller);
  }

  Future<void> _configureProducts(Branch branch) async {
    final loaded = await _controller.loadProductConfiguration(branch.id);
    if (!mounted) return;
    if (!loaded) {
      _showResult(
        false,
        _controller.productsError ??
            'No fue posible cargar los productos de la sucursal.',
      );
      return;
    }
    await BranchProductsDialog.show(
      context,
      branch: branch,
      controller: _controller,
    );
  }

  Future<void> _confirmDelete(Branch branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar sucursal'),
        content: Text(
          '¿Deseas eliminar “${branch.name}”? Se ocultará junto con su configuración de productos, conservando el historial.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await _controller.deleteBranch(branch.id);
    _showResult(
      success,
      success
          ? 'Sucursal eliminada correctamente.'
          : _controller.operationError ??
                'No fue posible eliminar la sucursal.',
    );
  }

  void _showResult(bool success, String message) {
    if (!mounted) return;
    ToastHelper.show(
      context,
      message,
      type: success ? ToastType.success : ToastType.error,
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
              isSearching ? Icons.search_off : Icons.store_outlined,
              size: 48,
              color: Colors.black38,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? 'No encontramos sucursales con ese criterio.'
                  : 'Aún no hay sucursales registradas.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Registrar la primera sucursal'),
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
