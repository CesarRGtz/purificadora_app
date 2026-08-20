import 'package:flutter/material.dart';

import '../../../../widgets/toast_helper.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../domain/usecases/create_supplier.dart';
import '../../domain/usecases/delete_supplier.dart';
import '../../domain/usecases/get_suppliers.dart';
import '../../domain/usecases/update_supplier.dart';
import '../controllers/suppliers_controller.dart';
import '../widgets/supplier_form_dialog.dart';
import '../widgets/suppliers_table.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({
    super.key,
    required this.repository,
    this.isOfflineMode = false,
    this.onExitOfflineMode,
  });

  final SupplierRepository repository;
  final bool isOfflineMode;
  final VoidCallback? onExitOfflineMode;

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  late final SuppliersController _controller;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = SuppliersController(
      getSuppliers: GetSuppliers(widget.repository),
      createSupplier: CreateSupplier(widget.repository),
      updateSupplier: UpdateSupplier(widget.repository),
      deleteSupplier: DeleteSupplier(widget.repository),
    );
    _controller.loadSuppliers();
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
        final filteredSuppliers = _filterSuppliers(_controller.suppliers);
        return RefreshIndicator(
          onRefresh: _controller.loadSuppliers,
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
              _buildSearchAndSummary(filteredSuppliers.length),
              const SizedBox(height: 16),
              _buildContent(filteredSuppliers),
            ],
          ),
        );
      },
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
                'Proveedores',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2B528A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Administra los proveedores asociados a cada sucursal.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _controller.isSubmitting ? null : _openCreateDialog,
          icon: const Icon(Icons.add_business),
          label: const Text('Registrar proveedor'),
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
            'Modo local de prueba: los cambios se perderán al cerrar la aplicación.',
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
            width: constraints.maxWidth < 400 ? constraints.maxWidth : 400,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por sucursal, nombre, dirección o teléfono',
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
            avatar: const Icon(Icons.local_shipping_outlined, size: 18),
            label: Text(
              _query.trim().isEmpty
                  ? '${_controller.suppliers.length} proveedores'
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

  Widget _buildContent(List<Supplier> suppliers) {
    switch (_controller.status) {
      case SuppliersViewStatus.initial:
      case SuppliersViewStatus.loading:
        return const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        );
      case SuppliersViewStatus.failure:
        return _ErrorState(
          message:
              _controller.errorMessage ??
              'No fue posible cargar los proveedores.',
          onRetry: _controller.loadSuppliers,
        );
      case SuppliersViewStatus.ready:
        if (suppliers.isEmpty) {
          return _EmptyState(
            isSearching: _query.trim().isNotEmpty,
            onCreate: _controller.isSubmitting ? null : _openCreateDialog,
          );
        }
        return SuppliersTable(
          suppliers: suppliers,
          onEdit: _openEditDialog,
          onDelete: _confirmDelete,
          actionsEnabled: !_controller.isSubmitting,
        );
    }
  }

  List<Supplier> _filterSuppliers(List<Supplier> suppliers) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return suppliers;
    return suppliers
        .where((supplier) {
          return supplier.branchName.toLowerCase().contains(query) ||
              supplier.name.toLowerCase().contains(query) ||
              supplier.address.toLowerCase().contains(query) ||
              supplier.phone.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _openCreateDialog() async {
    final supplier = await SupplierFormDialog.show(context);
    if (supplier == null || !mounted) return;
    final wasCreated = await _controller.createSupplier(supplier);
    if (!mounted) return;
    ToastHelper.show(
      context,
      wasCreated
          ? 'Proveedor registrado correctamente.'
          : _controller.operationError ??
                'No fue posible registrar el proveedor.',
      type: wasCreated ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _openEditDialog(Supplier current) async {
    final supplier = await SupplierFormDialog.show(context, supplier: current);
    if (supplier == null || !mounted) return;
    final wasUpdated = await _controller.updateSupplier(supplier);
    if (!mounted) return;
    ToastHelper.show(
      context,
      wasUpdated
          ? 'Proveedor actualizado correctamente.'
          : _controller.operationError ??
                'No fue posible actualizar el proveedor.',
      type: wasUpdated ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _confirmDelete(Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text(
          '¿Deseas eliminar “${supplier.name}”? Se ocultará del catálogo, pero se conservará en el historial.',
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
    final wasDeleted = await _controller.deleteSupplier(supplier.id);
    if (!mounted) return;
    ToastHelper.show(
      context,
      wasDeleted
          ? 'Proveedor eliminado correctamente.'
          : _controller.operationError ??
                'No fue posible eliminar el proveedor.',
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
              isSearching ? Icons.search_off : Icons.local_shipping_outlined,
              size: 48,
              color: Colors.black38,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? 'No encontramos proveedores con ese criterio.'
                  : 'Aún no hay proveedores registrados.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Registrar el primer proveedor'),
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
