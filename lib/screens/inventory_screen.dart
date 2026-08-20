import 'package:flutter/material.dart';

import '../features/inventory/inventory_module.dart';

/// Punto de entrada estable del dashboard para el módulo de Inventario.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) => InventoryModule.buildPage();
}
