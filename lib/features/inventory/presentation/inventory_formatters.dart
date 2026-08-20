import 'package:flutter/material.dart';

import '../domain/entities/inventory_entities.dart';

extension FinishedGoodStatusPresentation on FinishedGoodStatus {
  String get label => switch (this) {
    FinishedGoodStatus.purchased => 'Comprado',
    FinishedGoodStatus.sold => 'Vendido',
    FinishedGoodStatus.loaned => 'Prestado',
    FinishedGoodStatus.returned => 'Devuelto',
  };

  Color get color => switch (this) {
    FinishedGoodStatus.purchased => const Color(0xFF2563EB),
    FinishedGoodStatus.sold => const Color(0xFF059669),
    FinishedGoodStatus.loaned => const Color(0xFFD97706),
    FinishedGoodStatus.returned => const Color(0xFF7C3AED),
  };
}

extension RawMaterialMovementPresentation on RawMaterialMovementType {
  String get label => switch (this) {
    RawMaterialMovementType.purchase => 'Compra',
    RawMaterialMovementType.use => 'Uso',
    RawMaterialMovementType.transferIn => 'Traslado de entrada',
    RawMaterialMovementType.transferOut => 'Traslado de salida',
  };
}

String formatInventoryQuantity(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String formatInventoryMoney(double value) => '\$${value.toStringAsFixed(2)}';

String formatInventoryUnitCost(double value) {
  final input = formatInventoryUnitCostInput(value);
  final decimalIndex = input.indexOf('.');
  final normalized = decimalIndex == -1
      ? '$input.00'
      : input.length - decimalIndex - 1 == 1
      ? '${input}0'
      : input;
  return '\$$normalized';
}

String formatInventoryUnitCostInput(double value) => value
    .toStringAsFixed(4)
    .replaceFirst(RegExp(r'0+$'), '')
    .replaceFirst(RegExp(r'\.$'), '');
