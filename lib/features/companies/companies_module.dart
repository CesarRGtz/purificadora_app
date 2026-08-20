import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import 'data/datasources/company_remote_data_source.dart';
import 'data/repositories/company_repository_impl.dart';
import 'data/repositories/in_memory_company_repository.dart';
import 'domain/entities/company.dart';
import 'presentation/pages/companies_page.dart';
import 'presentation/pages/companies_setup_page.dart';

/// Composition root del feature. Mantiene la inyección de dependencias aislada.
abstract final class CompaniesModule {
  static final _offlineRepository = InMemoryCompanyRepository(
    initialCompanies: const [
      Company(
        id: 'local-demo-company',
        businessName: 'Empresa Demo del Desierto, S.A. de C.V.',
        rfc: 'EDD260819AB1',
        address: 'Blvd. Solidaridad 100, Hermosillo, Sonora',
        phone: '6621234567',
      ),
    ],
  );

  static Widget buildPage({Key? key}) {
    return _CompaniesGateway(key: key);
  }
}

class _CompaniesGateway extends StatefulWidget {
  const _CompaniesGateway({super.key});

  @override
  State<_CompaniesGateway> createState() => _CompaniesGatewayState();
}

class _CompaniesGatewayState extends State<_CompaniesGateway> {
  bool _useOfflineMode = false;

  @override
  Widget build(BuildContext context) {
    if (_useOfflineMode) {
      return CompaniesPage(
        key: const ValueKey('companies-offline'),
        repository: CompaniesModule._offlineRepository,
        isOfflineMode: true,
        onExitOfflineMode: () => setState(() => _useOfflineMode = false),
      );
    }

    if (!SupabaseConfig.isReady) {
      return CompaniesSetupPage(
        key: const ValueKey('companies-setup'),
        initializationFailed: SupabaseConfig.initializationError != null,
        onTryOffline: () => setState(() => _useOfflineMode = true),
      );
    }

    final dataSource = SupabaseCompanyRemoteDataSource(
      Supabase.instance.client,
    );
    final repository = CompanyRepositoryImpl(dataSource);
    return CompaniesPage(
      key: const ValueKey('companies-online'),
      repository: repository,
    );
  }
}
