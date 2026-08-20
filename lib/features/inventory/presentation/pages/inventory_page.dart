import 'package:flutter/material.dart';

import '../../../../widgets/toast_helper.dart';
import '../../../branches/domain/entities/product.dart' as branches;
import '../../../branches/presentation/widgets/product_form_dialog.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../controllers/inventory_controller.dart';
import '../widgets/consume_product_dialog.dart';
import '../widgets/finished_good_form_dialog.dart';
import '../widgets/finished_goods_tab.dart';
import '../widgets/inventory_products_tab.dart';
import '../widgets/product_branches_dialog.dart';
import '../widgets/product_materials_dialog.dart';
import '../widgets/raw_material_form_dialog.dart';
import '../widgets/raw_material_movement_dialog.dart';
import '../widgets/raw_material_product_dialog.dart';
import '../widgets/raw_material_transfer_dialog.dart';
import '../widgets/raw_materials_tab.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.repository,
    this.isOfflineMode = false,
    this.onExitOfflineMode,
    this.onTryOfflineMode,
  });

  final InventoryRepository repository;
  final bool isOfflineMode;
  final VoidCallback? onExitOfflineMode;
  final VoidCallback? onTryOfflineMode;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late final InventoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InventoryController(widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              _buildTopSection(context),
              const TabBar(
                key: ValueKey('inventory-tabs'),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Color(0xFF2B528A),
                labelColor: Color(0xFF2B528A),
                unselectedLabelColor: Colors.black54,
                tabs: [
                  Tab(
                    icon: Icon(Icons.inventory_2_outlined, size: 19),
                    text: 'Producto Terminado',
                  ),
                  Tab(
                    icon: Icon(Icons.science_outlined, size: 19),
                    text: 'Materia Prima',
                  ),
                  Tab(icon: Icon(Icons.qr_code_2, size: 19), text: 'Productos'),
                ],
              ),
              if (_controller.isSubmitting)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(child: _buildContent()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
      child: Column(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventario por sucursal',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2B528A),
                          ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Productos terminados, materias primas y recetas en un mismo control auditable.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _controller.isSubmitting ? null : _controller.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          if (widget.isOfflineMode) ...[
            const SizedBox(height: 14),
            _OfflineInventoryBanner(
              onExitOfflineMode: widget.onExitOfflineMode,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_controller.status) {
      case InventoryViewStatus.initial:
      case InventoryViewStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case InventoryViewStatus.failure:
        return _InventoryErrorState(
          message:
              _controller.errorMessage ??
              'No fue posible cargar el inventario.',
          onRetry: _controller.load,
          onTryOffline: widget.onTryOfflineMode,
        );
      case InventoryViewStatus.ready:
        final snapshot = _controller.snapshot;
        return TabBarView(
          children: [
            FinishedGoodsTab(
              snapshot: snapshot,
              isBusy: _controller.isSubmitting,
              onCreate: _createFinishedGood,
              onEdit: _editFinishedGood,
              onDelete: _deleteFinishedGood,
            ),
            RawMaterialsTab(
              snapshot: snapshot,
              isBusy: _controller.isSubmitting,
              onCreate: _createRawMaterial,
              onLinkProduct: _linkRawMaterialToProduct,
              onMovement: _registerRawMaterialMovement,
              onTransfer: _transferRawMaterial,
              onEdit: _editRawMaterial,
              onDelete: _deleteRawMaterial,
            ),
            InventoryProductsTab(
              snapshot: snapshot,
              isBusy: _controller.isSubmitting,
              onCreate: _createProduct,
              onEdit: _editProduct,
              onConfigureBranches: _configureProductBranches,
              onConfigureMaterials: _configureProductMaterials,
              onConsume: _consumeProduct,
              onDelete: _deleteProduct,
            ),
          ],
        );
    }
  }

  Future<void> _createFinishedGood() async {
    final item = await FinishedGoodFormDialog.show(
      context,
      branches: _controller.snapshot.branches,
      products: _controller.snapshot.products,
    );
    if (item == null || !mounted) return;
    final success = await _controller.createFinishedGood(item);
    _showResult(
      success,
      success
          ? 'Producto terminado registrado.'
          : _controller.operationError ?? 'No fue posible registrarlo.',
    );
  }

  Future<void> _editFinishedGood(FinishedGood current) async {
    final item = await FinishedGoodFormDialog.show(
      context,
      branches: _controller.snapshot.branches,
      products: _controller.snapshot.products,
      item: current,
    );
    if (item == null || !mounted) return;
    final success = await _controller.updateFinishedGood(item);
    _showResult(
      success,
      success
          ? 'Producto terminado actualizado.'
          : _controller.operationError ?? 'No fue posible actualizarlo.',
    );
  }

  Future<void> _deleteFinishedGood(FinishedGood item) async {
    final confirmed = await _confirmDelete(
      title: 'Eliminar producto terminado',
      message:
          '¿Deseas eliminar “${item.name}”? Se ocultará conservando su historial.',
    );
    if (!confirmed || !mounted) return;
    final success = await _controller.deleteFinishedGood(item.id);
    _showResult(
      success,
      success
          ? 'Producto terminado eliminado.'
          : _controller.operationError ?? 'No fue posible eliminarlo.',
    );
  }

  Future<void> _createRawMaterial() async {
    final material = await RawMaterialFormDialog.show(
      context,
      branches: _controller.snapshot.branches,
    );
    if (material == null || !mounted) return;
    final success = await _controller.createRawMaterial(material);
    _showResult(
      success,
      success
          ? 'Materia prima registrada.'
          : _controller.operationError ?? 'No fue posible registrarla.',
    );
  }

  Future<void> _editRawMaterial(RawMaterial current) async {
    final material = await RawMaterialFormDialog.show(
      context,
      branches: _controller.snapshot.branches,
      material: current,
    );
    if (material == null || !mounted) return;
    final success = await _controller.updateRawMaterial(material);
    _showResult(
      success,
      success
          ? 'Materia prima actualizada.'
          : _controller.operationError ?? 'No fue posible actualizarla.',
    );
  }

  Future<void> _deleteRawMaterial(RawMaterial material) async {
    final confirmed = await _confirmDelete(
      title: 'Eliminar materia prima',
      message:
          '¿Deseas eliminar “${material.name}”? Sus recetas se desactivarán y el historial permanecerá guardado.',
    );
    if (!confirmed || !mounted) return;
    final success = await _controller.deleteRawMaterial(material.id);
    _showResult(
      success,
      success
          ? 'Materia prima eliminada.'
          : _controller.operationError ?? 'No fue posible eliminarla.',
    );
  }

  Future<void> _registerRawMaterialMovement(RawMaterial material) async {
    final movement = await RawMaterialMovementDialog.show(
      context,
      material: material,
      products: _controller.snapshot.products
          .where(
            (product) => _controller.snapshot.productMaterialRequirements.any(
              (requirement) =>
                  requirement.productId == product.id &&
                  requirement.rawMaterialId == material.id,
            ),
          )
          .toList(growable: false),
    );
    if (movement == null || !mounted) return;
    final success = await _controller.registerRawMaterialMovement(movement);
    _showResult(
      success,
      success
          ? 'Movimiento registrado; existencias actualizadas.'
          : _controller.operationError ??
                'No fue posible registrar el movimiento.',
    );
  }

  Future<void> _transferRawMaterial(RawMaterial source) async {
    final request = await RawMaterialTransferDialog.show(
      context,
      source: source,
      rawMaterials: _controller.snapshot.rawMaterials,
      branches: _controller.snapshot.branches,
    );
    if (request == null || !mounted) return;
    final success = await _controller.transferRawMaterial(
      source.id,
      request.destinationRawMaterialId,
      request.quantity,
    );
    _showResult(
      success,
      success
          ? 'Traslado registrado en ambas sucursales.'
          : _controller.operationError ??
                'No fue posible realizar el traslado.',
    );
  }

  Future<void> _linkRawMaterialToProduct(RawMaterial material) async {
    final link = await RawMaterialProductDialog.show(
      context,
      material: material,
      products: _controller.snapshot.products,
      requirements: _controller.snapshot.productMaterialRequirements,
    );
    if (link == null || !mounted) return;
    final quantities = {
      for (final requirement
          in _controller.snapshot.productMaterialRequirements)
        if (requirement.productId == link.productId)
          requirement.rawMaterialId: requirement.quantityPerUnit,
      material.id: link.quantityPerUnit,
    };
    final success = await _controller.configureProductMaterials(
      link.productId,
      quantities,
    );
    _showResult(
      success,
      success
          ? 'Materia prima vinculada al producto.'
          : _controller.operationError ?? 'No fue posible guardar el vínculo.',
    );
  }

  Future<void> _createProduct() async {
    final product = await ProductFormDialog.show(context);
    if (product == null || !mounted) return;
    final success = await _controller.createProduct(
      _toInventoryProduct(product),
    );
    _showResult(
      success,
      success
          ? 'Producto registrado en el catálogo compartido.'
          : _controller.operationError ??
                'No fue posible registrar el producto.',
    );
  }

  Future<void> _editProduct(InventoryProduct current) async {
    final product = await ProductFormDialog.show(
      context,
      product: _toBranchesProduct(current),
    );
    if (product == null || !mounted) return;
    final success = await _controller.updateProduct(
      _toInventoryProduct(product, branchIds: current.branchIds),
    );
    _showResult(
      success,
      success
          ? 'Producto actualizado.'
          : _controller.operationError ??
                'No fue posible actualizar el producto.',
    );
  }

  Future<void> _deleteProduct(InventoryProduct product) async {
    final confirmed = await _confirmDelete(
      title: 'Eliminar producto',
      message:
          '¿Deseas eliminar “${product.name}”? Se quitará de las sucursales, sus recetas quedarán desactivadas y los activos conservarán su nombre histórico sin asociación.',
    );
    if (!confirmed || !mounted) return;
    final success = await _controller.deleteProduct(product.id);
    _showResult(
      success,
      success
          ? 'Producto eliminado.'
          : _controller.operationError ??
                'No fue posible eliminar el producto.',
    );
  }

  Future<void> _configureProductBranches(InventoryProduct product) async {
    final branchIds = await ProductBranchesDialog.show(
      context,
      product: product,
      branches: _controller.snapshot.branches,
    );
    if (branchIds == null || !mounted) return;
    final success = await _controller.configureProductBranches(
      product.id,
      branchIds,
    );
    _showResult(
      success,
      success
          ? 'Sucursales del producto actualizadas.'
          : _controller.operationError ??
                'No fue posible guardar las sucursales.',
    );
  }

  Future<void> _configureProductMaterials(InventoryProduct product) async {
    final quantities = await ProductMaterialsDialog.show(
      context,
      product: product,
      branches: _controller.snapshot.branches,
      rawMaterials: _controller.snapshot.rawMaterials,
      requirements: _controller.snapshot.productMaterialRequirements,
    );
    if (quantities == null || !mounted) return;
    final success = await _controller.configureProductMaterials(
      product.id,
      quantities,
    );
    _showResult(
      success,
      success
          ? 'Receta de insumos actualizada.'
          : _controller.operationError ?? 'No fue posible guardar la receta.',
    );
  }

  Future<void> _consumeProduct(InventoryProduct product) async {
    final request = await ConsumeProductDialog.show(
      context,
      product: product,
      branches: _controller.snapshot.branches,
      rawMaterials: _controller.snapshot.rawMaterials,
      requirements: _controller.snapshot.productMaterialRequirements,
    );
    if (request == null || !mounted) return;
    final success = await _controller.consumeProduct(
      product.id,
      request.branchId,
      request.quantity,
    );
    _showResult(
      success,
      success
          ? 'Consumo aplicado a todas las materias primas de la receta.'
          : _controller.operationError ?? 'No fue posible aplicar el consumo.',
    );
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
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
        ) ??
        false;
  }

  InventoryProduct _toInventoryProduct(
    branches.Product product, {
    Set<String> branchIds = const {},
  }) {
    return InventoryProduct(
      id: product.id,
      name: product.name,
      sku: product.sku,
      description: product.description,
      basePrice: product.basePrice,
      branchIds: {...branchIds},
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      deletedAt: product.deletedAt,
    );
  }

  branches.Product _toBranchesProduct(InventoryProduct product) {
    return branches.Product(
      id: product.id,
      name: product.name,
      sku: product.sku,
      description: product.description,
      basePrice: product.basePrice,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      deletedAt: product.deletedAt,
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

class _OfflineInventoryBanner extends StatelessWidget {
  const _OfflineInventoryBanner({this.onExitOfflineMode});

  final VoidCallback? onExitOfflineMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, color: Color(0xFFB45309)),
          const Text(
            'Modo local: comparte sucursales y productos temporales con el apartado Sucursales.',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onExitOfflineMode != null)
            TextButton(
              onPressed: onExitOfflineMode,
              child: const Text('Ver configuración de Supabase'),
            ),
        ],
      ),
    );
  }
}

class _InventoryErrorState extends StatelessWidget {
  const _InventoryErrorState({
    required this.message,
    required this.onRetry,
    this.onTryOffline,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback? onTryOffline;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                  if (onTryOffline != null)
                    ElevatedButton.icon(
                      onPressed: onTryOffline,
                      icon: const Icon(Icons.wifi_off_outlined),
                      label: const Text('Probar sin conexión'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
