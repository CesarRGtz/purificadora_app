
/// Modelo para un producto del catálogo POS
class Product {
  final String id;
  final String name;
  final double price;
  final String icon;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price, 'icon': icon};
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'], name: json['name'], price: (json['price'] as num).toDouble(), icon: json['icon'],
  );
}

/// Artículo dentro del ticket de venta
class TicketItem {
  final String id;
  final Product product;
  int qty;

  TicketItem({required this.id, required this.product, this.qty = 1});

  double get subtotal => product.price * qty;

  Map<String, dynamic> toJson() => {'id': id, 'product': product.toJson(), 'qty': qty};
  factory TicketItem.fromJson(Map<String, dynamic> json) => TicketItem(
    id: json['id'], product: Product.fromJson(json['product']), qty: json['qty'],
  );
}

/// Venta completada
class Sale {
  final String id;
  final List<TicketItem> items;
  final double total;
  final double payment;
  final double change;
  final DateTime date;
  final String status; // 'paid', 'credit'
  final String? clientId;

  Sale({
    required this.id,
    required this.items,
    required this.total,
    required this.payment,
    required this.change,
    required this.date,
    this.status = 'paid',
    this.clientId,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.qty);

  Map<String, dynamic> toJson() => {
    'id': id, 'items': items.map((i) => i.toJson()).toList(),
    'total': total, 'payment': payment, 'change': change,
    'date': date.toIso8601String(),
    'status': status,
    'clientId': clientId,
  };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'],
    items: (json['items'] as List).map((i) => TicketItem.fromJson(i)).toList(),
    total: (json['total'] as num).toDouble(),
    payment: (json['payment'] as num).toDouble(),
    change: (json['change'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    status: json['status'] ?? 'paid',
    clientId: json['clientId'],
  );
}

/// Registro de producción
class ProductionRecord {
  final String id;
  DateTime date;
  double liters;
  double chlorine;
  bool filtersWashed;
  String operator;

  ProductionRecord({
    required this.id,
    required this.date,
    required this.liters,
    required this.chlorine,
    required this.filtersWashed,
    required this.operator,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'liters': liters,
    'chlorine': chlorine, 'filtersWashed': filtersWashed, 'operator': operator,
  };

  factory ProductionRecord.fromJson(Map<String, dynamic> json) => ProductionRecord(
    id: json['id'], date: DateTime.parse(json['date']),
    liters: (json['liters'] as num).toDouble(),
    chlorine: (json['chlorine'] as num).toDouble(),
    filtersWashed: json['filtersWashed'], operator: json['operator'],
  );
}

/// Ruta de reparto
class DeliveryRoute {
  final String id;
  String name;
  String driver;
  String status; // 'pending', 'in_progress', 'completed'
  int completed;
  int total;
  List<String> clientIds;

  DeliveryRoute({
    required this.id,
    required this.name,
    required this.driver,
    required this.status,
    required this.completed,
    required this.total,
    this.clientIds = const [],
  });

  double get progress => total > 0 ? completed / total : 0;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'driver': driver,
    'status': status, 'completed': completed, 'total': total,
    'clientIds': clientIds,
  };

  factory DeliveryRoute.fromJson(Map<String, dynamic> json) => DeliveryRoute(
    id: json['id'], name: json['name'], driver: json['driver'],
    status: json['status'], completed: json['completed'], total: json['total'],
    clientIds: List<String>.from(json['clientIds'] ?? []),
  );
}

/// Estado del inventario
class InventoryState {
  int full;
  int empty;
  int onRoute;
  int damaged;

  InventoryState({
    required this.full,
    required this.empty,
    required this.onRoute,
    required this.damaged,
  });

  int get totalUnits => full + empty + onRoute + damaged;

  Map<String, dynamic> toJson() => {
    'full': full, 'empty': empty, 'onRoute': onRoute, 'damaged': damaged,
  };

  factory InventoryState.fromJson(Map<String, dynamic> json) => InventoryState(
    full: json['full'], empty: json['empty'],
    onRoute: json['onRoute'], damaged: json['damaged'],
  );
}

/// Movimiento de inventario
class InventoryMovement {
  final String id;
  final String type; // 'in' o 'out'
  final String description;
  final DateTime date;
  final int amount;
  final String unit;

  InventoryMovement({
    required this.id,
    required this.type,
    required this.description,
    required this.date,
    required this.amount,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'description': description,
    'date': date.toIso8601String(), 'amount': amount, 'unit': unit,
  };

  factory InventoryMovement.fromJson(Map<String, dynamic> json) => InventoryMovement(
    id: json['id'], type: json['type'], description: json['description'],
    date: DateTime.parse(json['date']), amount: json['amount'], unit: json['unit'],
  );
}

// --- NUEVOS MODELOS ERP ---

class Branch {
  final String id;
  final String name;
  final String address;
  final String phone;

  Branch({required this.id, required this.name, required this.address, required this.phone});
}

class Supplier {
  final String id;
  final String name;
  final String category; // 'Materias Primas', 'Mantenimiento', etc.
  final String contact;

  Supplier({required this.id, required this.name, required this.category, required this.contact});
}

class Vehicle {
  final String id;
  final String plates;
  final String model;
  final DateTime lastMaintenance;

  Vehicle({required this.id, required this.plates, required this.model, required this.lastMaintenance});
}

class Client {
  final String id;
  final String name;
  final String type; // 'Residencial', 'Empresarial', 'Punto de Venta'
  final double latitude;
  final double longitude;
  final String priceListId;

  Client({
    required this.id, required this.name, required this.type,
    required this.latitude, required this.longitude, required this.priceListId,
  });
}

class Asset {
  final String id;
  final String name;
  final String type; // 'Stand', 'Garrafón Consigna'
  final String assignedToClientId;

  Asset({required this.id, required this.name, required this.type, required this.assignedToClientId});
}

class RawMaterial {
  final String id;
  final String name;
  final String unit; // 'Piezas', 'Litros', 'Kilos'
  int stock;
  final double cost;

  RawMaterial({required this.id, required this.name, required this.unit, required this.stock, required this.cost});
}

class Purchase {
  final String id;
  final String supplierId;
  final DateTime date;
  final String rawMaterialId;
  final int quantity;
  final double totalCost;
  String status; // 'pending', 'received'

  Purchase({
    required this.id, required this.supplierId, required this.date,
    required this.rawMaterialId, required this.quantity, required this.totalCost, required this.status,
  });
}

class CashRegister {
  final String id;
  final DateTime openedAt;
  DateTime? closedAt;
  final double openingBalance;
  double? closingBalance;
  String status; // 'open', 'closed'

  CashRegister({
    required this.id, required this.openedAt, this.closedAt,
    required this.openingBalance, this.closingBalance, required this.status,
  });
}

class CashMovement {
  final String id;
  final String registerId;
  final String type; // 'in' (ingreso), 'out' (gasto)
  final double amount;
  final String description;
  final DateTime date;

  CashMovement({
    required this.id, required this.registerId, required this.type,
    required this.amount, required this.description, required this.date,
  });
}

class CreditPayment {
  final String id;
  final String saleId;
  final double amount;
  final DateTime date;

  CreditPayment({required this.id, required this.saleId, required this.amount, required this.date});
}

