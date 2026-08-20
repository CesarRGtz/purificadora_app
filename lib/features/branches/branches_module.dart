import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import 'data/datasources/branches_remote_data_source.dart';
import 'data/repositories/branches_repository_impl.dart';
import 'data/repositories/in_memory_branches_repository.dart';
import 'domain/entities/branch.dart';
import 'domain/entities/product.dart';
import 'presentation/pages/branches_page.dart';
import 'presentation/pages/branches_setup_page.dart';

abstract final class BranchesModule {
  static final _offlineRepository = InMemoryBranchesRepository(
    initialBranches: const [
      Branch(
        id: 'local-demo-branch',
        name: 'Sucursal Centro',
        businessName: 'Purificadora Demo',
        address: 'Blvd. Hidalgo 100, Hermosillo, Sonora',
        latitude: 29.072967,
        longitude: -110.955919,
      ),
    ],
    initialProducts: const [
      Product(
        id: 'local-product-water-20l',
        name: 'Garrafón de agua 20 L',
        sku: 'AGUA-20L',
        description: 'Garrafón retornable de agua purificada.',
        basePrice: 45,
      ),
      Product(
        id: 'local-product-ice-5kg',
        name: 'Bolsa de hielo 5 kg',
        sku: 'HIELO-5KG',
        description: 'Bolsa de hielo purificado.',
        basePrice: 38,
      ),
    ],
    initialAssignments: const {
      'local-demo-branch': {'local-product-water-20l'},
    },
  );

  /// Catálogo local compartido por Sucursales e Inventario.
  ///
  /// Mantener una sola instancia permite que las altas de sucursales y
  /// productos hechas sin Supabase también se reflejen en Inventario.
  static InMemoryBranchesRepository get offlineRepository => _offlineRepository;

  static Widget buildPage({Key? key}) => _BranchesGateway(key: key);
}

class _BranchesGateway extends StatefulWidget {
  const _BranchesGateway({super.key});

  @override
  State<_BranchesGateway> createState() => _BranchesGatewayState();
}

class _BranchesGatewayState extends State<_BranchesGateway> {
  bool _useOfflineMode = false;

  @override
  Widget build(BuildContext context) {
    if (_useOfflineMode) {
      return BranchesPage(
        key: const ValueKey('branches-offline'),
        repository: BranchesModule._offlineRepository,
        isOfflineMode: true,
        onExitOfflineMode: () => setState(() => _useOfflineMode = false),
      );
    }

    if (!SupabaseConfig.isReady) {
      return BranchesSetupPage(
        key: const ValueKey('branches-setup'),
        initializationFailed: SupabaseConfig.initializationError != null,
        onTryOffline: () => setState(() => _useOfflineMode = true),
      );
    }

    final dataSource = SupabaseBranchesRemoteDataSource(
      Supabase.instance.client,
    );
    return BranchesPage(
      key: const ValueKey('branches-online'),
      repository: BranchesRepositoryImpl(dataSource),
    );
  }
}
