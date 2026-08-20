import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import 'data/datasources/supplier_remote_data_source.dart';
import 'data/repositories/in_memory_supplier_repository.dart';
import 'data/repositories/supplier_repository_impl.dart';
import 'domain/entities/supplier.dart';
import 'presentation/pages/suppliers_page.dart';
import 'presentation/pages/suppliers_setup_page.dart';

abstract final class SuppliersModule {
  static final _offlineRepository = InMemorySupplierRepository(
    initialSuppliers: const [
      Supplier(
        id: 'local-demo-supplier',
        branchName: 'Sucursal Centro',
        name: 'Envases del Noroeste',
        address: 'Av. de los Insumos 250, Hermosillo, Sonora',
        phone: '6622345678',
      ),
    ],
  );

  static Widget buildPage({Key? key}) => _SuppliersGateway(key: key);
}

class _SuppliersGateway extends StatefulWidget {
  const _SuppliersGateway({super.key});

  @override
  State<_SuppliersGateway> createState() => _SuppliersGatewayState();
}

class _SuppliersGatewayState extends State<_SuppliersGateway> {
  bool _useOfflineMode = false;

  @override
  Widget build(BuildContext context) {
    if (_useOfflineMode) {
      return SuppliersPage(
        key: const ValueKey('suppliers-offline'),
        repository: SuppliersModule._offlineRepository,
        isOfflineMode: true,
        onExitOfflineMode: () => setState(() => _useOfflineMode = false),
      );
    }

    if (!SupabaseConfig.isReady) {
      return SuppliersSetupPage(
        key: const ValueKey('suppliers-setup'),
        initializationFailed: SupabaseConfig.initializationError != null,
        onTryOffline: () => setState(() => _useOfflineMode = true),
      );
    }

    final dataSource = SupabaseSupplierRemoteDataSource(
      Supabase.instance.client,
    );
    return SuppliersPage(
      key: const ValueKey('suppliers-online'),
      repository: SupplierRepositoryImpl(dataSource),
    );
  }
}
