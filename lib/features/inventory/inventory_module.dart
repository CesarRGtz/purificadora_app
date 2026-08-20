import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../branches/branches_module.dart';
import '../branches/data/datasources/branches_remote_data_source.dart';
import '../branches/data/repositories/branches_repository_impl.dart';
import 'data/datasources/inventory_remote_data_source.dart';
import 'data/repositories/in_memory_inventory_repository.dart';
import 'data/repositories/inventory_repository_impl.dart';
import 'domain/entities/inventory_entities.dart';
import 'presentation/pages/inventory_page.dart';
import 'presentation/pages/inventory_setup_page.dart';

abstract final class InventoryModule {
  static bool _offlineModeSelected = false;

  static final _offlineRepository = InMemoryInventoryRepository(
    branchesRepository: BranchesModule.offlineRepository,
    initialFinishedGoods: const [
      FinishedGood(
        id: 'local-finished-water',
        branchId: 'local-demo-branch',
        productId: 'local-product-water-20l',
        name: 'Garrafón de agua 20 L',
        type: 'Garrafón retornable',
        status: FinishedGoodStatus.purchased,
        quantity: 80,
        isSellable: true,
      ),
      FinishedGood(
        id: 'local-finished-loaned',
        branchId: 'local-demo-branch',
        name: 'Garrafón en comodato',
        type: 'Envase retornable',
        status: FinishedGoodStatus.loaned,
        quantity: 12,
        isSellable: false,
      ),
    ],
    initialRawMaterials: const [
      RawMaterial(
        id: 'local-raw-caps',
        branchId: 'local-demo-branch',
        category: 'Empaque',
        name: 'Tapas de garrafón',
        unit: 'pzas',
        lastUnitCost: 0.50,
      ),
      RawMaterial(
        id: 'local-raw-seals',
        branchId: 'local-demo-branch',
        category: 'Empaque',
        name: 'Sellos térmicos',
        unit: 'pzas',
        lastUnitCost: 0.20,
      ),
      RawMaterial(
        id: 'local-raw-chlorine',
        branchId: 'local-demo-branch',
        category: 'Tratamiento',
        name: 'Cloro líquido',
        unit: 'L',
        lastUnitCost: 15,
      ),
    ],
    initialRawMaterialMovements: const [
      RawMaterialMovement(
        id: 'local-move-caps',
        rawMaterialId: 'local-raw-caps',
        type: RawMaterialMovementType.purchase,
        quantity: 5000,
        unitCost: 0.50,
      ),
      RawMaterialMovement(
        id: 'local-move-seals',
        rawMaterialId: 'local-raw-seals',
        type: RawMaterialMovementType.purchase,
        quantity: 4500,
        unitCost: 0.20,
      ),
      RawMaterialMovement(
        id: 'local-move-chlorine',
        rawMaterialId: 'local-raw-chlorine',
        type: RawMaterialMovementType.purchase,
        quantity: 20,
        unitCost: 15,
      ),
    ],
    initialProductMaterialRequirements: const [
      ProductMaterialRequirement(
        id: 'local-recipe-caps',
        productId: 'local-product-water-20l',
        rawMaterialId: 'local-raw-caps',
        quantityPerUnit: 1,
      ),
      ProductMaterialRequirement(
        id: 'local-recipe-seals',
        productId: 'local-product-water-20l',
        rawMaterialId: 'local-raw-seals',
        quantityPerUnit: 1,
      ),
      ProductMaterialRequirement(
        id: 'local-recipe-chlorine',
        productId: 'local-product-water-20l',
        rawMaterialId: 'local-raw-chlorine',
        quantityPerUnit: 0.005,
      ),
    ],
  );

  static Widget buildPage({Key? key}) => _InventoryGateway(key: key);
}

class _InventoryGateway extends StatefulWidget {
  const _InventoryGateway({super.key});

  @override
  State<_InventoryGateway> createState() => _InventoryGatewayState();
}

class _InventoryGatewayState extends State<_InventoryGateway> {
  late bool _useOfflineMode;

  @override
  void initState() {
    super.initState();
    _useOfflineMode = InventoryModule._offlineModeSelected;
  }

  void _setOfflineMode(bool value) {
    InventoryModule._offlineModeSelected = value;
    setState(() => _useOfflineMode = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_useOfflineMode) {
      return InventoryPage(
        key: const ValueKey('inventory-offline'),
        repository: InventoryModule._offlineRepository,
        isOfflineMode: true,
        onExitOfflineMode: () => _setOfflineMode(false),
      );
    }

    if (!SupabaseConfig.isReady) {
      return InventorySetupPage(
        key: const ValueKey('inventory-setup'),
        initializationFailed: SupabaseConfig.initializationError != null,
        onTryOffline: () => _setOfflineMode(true),
      );
    }

    final client = Supabase.instance.client;
    final branchesRepository = BranchesRepositoryImpl(
      SupabaseBranchesRemoteDataSource(client),
    );
    return InventoryPage(
      key: const ValueKey('inventory-online'),
      repository: InventoryRepositoryImpl(
        SupabaseInventoryRemoteDataSource(client),
        branchesRepository,
      ),
      onTryOfflineMode: () => _setOfflineMode(true),
    );
  }
}
