import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Estado global de la aplicación con persistencia
class AppState extends ChangeNotifier {
  // === Datos ===
  List<Product> products = [];
  List<TicketItem> currentTicket = [];
  List<Sale> sales = [];
  List<ProductionRecord> production = [];
  List<DeliveryRoute> routes = [];
  InventoryState inventory = InventoryState(full: 0, empty: 0, onRoute: 0, damaged: 0);
  List<InventoryMovement> movements = [];

  // === Nuevos Datos ERP ===
  List<Branch> branches = [];
  List<Supplier> suppliers = [];
  List<Vehicle> vehicles = [];
  List<Client> clients = [];
  List<Asset> assets = [];
  List<RawMaterial> rawMaterials = [];
  List<Purchase> purchases = [];

  // === Caja y Finanzas ===
  CashRegister? activeRegister;
  List<CashRegister> registers = [];
  List<CashMovement> cashMovements = [];
  List<CreditPayment> creditPayments = [];

  SharedPreferences? _prefs;

  AppState() {
    _loadDefaults();
    _initPrefs();
  }

  void _loadDefaults() {
    products = const [
      Product(id: 'p1', name: 'Llenado Garrafón', price: 15.00, icon: '💧'),
      Product(id: 'p2', name: 'Garrafón Nuevo', price: 110.00, icon: '🪣'),
      Product(id: 'p3', name: 'Botella 500ml', price: 8.00, icon: '🥤'),
      Product(id: 'p4', name: 'Sello/Tapa Extra', price: 2.00, icon: '⭕'),
    ];

    production = [
      ProductionRecord(
        id: 'prod1', date: DateTime(2026, 8, 13, 7, 0),
        liters: 5000, chlorine: 0.5, filtersWashed: true, operator: 'Carlos M.',
      ),
      ProductionRecord(
        id: 'prod2', date: DateTime(2026, 8, 12, 7, 15),
        liters: 4500, chlorine: 0.6, filtersWashed: true, operator: 'Carlos M.',
      ),
    ];

    routes = [
      DeliveryRoute(id: 'r1', name: 'Ruta Norte', driver: 'Juan Pérez', status: 'in_progress', completed: 15, total: 25),
      DeliveryRoute(id: 'r2', name: 'Ruta Sur', driver: 'Luis Gómez', status: 'completed', completed: 30, total: 30),
      DeliveryRoute(id: 'r3', name: 'Ruta Centro', driver: '', status: 'pending', completed: 0, total: 42),
    ];

    inventory = InventoryState(full: 125, empty: 48, onRoute: 60, damaged: 3);

    movements = [
      InventoryMovement(
        id: 'm1', type: 'out', description: 'Salida a Ruta Sur (Luis Gómez)',
        date: DateTime(2026, 8, 13, 8, 15), amount: 30, unit: 'Garrafones Llenos',
      ),
      InventoryMovement(
        id: 'm2', type: 'in', description: 'Retorno de Ruta Norte (Juan Pérez)',
        date: DateTime(2026, 8, 12, 18, 30), amount: 25, unit: 'Garrafones Vacíos',
      ),
    ];

    branches = [
      Branch(id: 'b1', name: 'Matriz Centro', address: 'Av. Principal 123', phone: '555-0001'),
      Branch(id: 'b2', name: 'Sucursal Norte', address: 'Plaza Norte L-5', phone: '555-0002'),
    ];

    suppliers = [
      Supplier(id: 's1', name: 'Envases Plásticos S.A.', category: 'Materias Primas', contact: 'ventas@envases.com'),
      Supplier(id: 's2', name: 'Etiquetas Rápidas', category: 'Insumos', contact: '555-1234'),
    ];

    vehicles = [
      Vehicle(id: 'v1', plates: 'XYZ-123', model: 'Nissan NP300', lastMaintenance: DateTime(2026, 7, 10)),
      Vehicle(id: 'v2', plates: 'ABC-987', model: 'Ford Ranger', lastMaintenance: DateTime(2026, 6, 15)),
    ];

    clients = [
      Client(id: 'c1', name: 'Abarrotes Doña Mari', type: 'Punto de Venta', latitude: 19.4326, longitude: -99.1332, priceListId: 'mayoreo'),
      Client(id: 'c2', name: 'Familia Sánchez', type: 'Residencial', latitude: 19.4350, longitude: -99.1400, priceListId: 'menudeo'),
    ];

    assets = [
      Asset(id: 'a1', name: 'Stand de Exhibición 3 Niveles', type: 'Stand', assignedToClientId: 'c1'),
      Asset(id: 'a2', name: 'Garrafón Consigna #105', type: 'Garrafón Consigna', assignedToClientId: 'c2'),
    ];

    rawMaterials = [
      RawMaterial(id: 'rm1', name: 'Tapas de Garrafón', unit: 'Piezas', stock: 5000, cost: 0.50),
      RawMaterial(id: 'rm2', name: 'Sellos Térmicos', unit: 'Piezas', stock: 4500, cost: 0.20),
      RawMaterial(id: 'rm3', name: 'Cloro Líquido', unit: 'Litros', stock: 20, cost: 15.00),
    ];

    purchases = [
      Purchase(id: 'pu1', supplierId: 's1', date: DateTime(2026, 8, 10), rawMaterialId: 'rm1', quantity: 1000, totalCost: 500.0, status: 'received'),
    ];
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
  }

  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
      (DateTime.now().microsecond).toRadixString(36);

  // === Persistencia ===
  Future<void> _save() async {
    if (_prefs == null) return;
    await _prefs!.setString('sales', jsonEncode(sales.map((s) => s.toJson()).toList()));
    await _prefs!.setString('production', jsonEncode(production.map((p) => p.toJson()).toList()));
    await _prefs!.setString('routes', jsonEncode(routes.map((r) => r.toJson()).toList()));
    await _prefs!.setString('inventory', jsonEncode(inventory.toJson()));
    await _prefs!.setString('movements', jsonEncode(movements.map((m) => m.toJson()).toList()));
    await _prefs!.setString('ticket', jsonEncode(currentTicket.map((t) => t.toJson()).toList()));
  }

  void _loadFromPrefs() {
    if (_prefs == null) return;
    try {
      final salesStr = _prefs!.getString('sales');
      if (salesStr != null) {
        sales = (jsonDecode(salesStr) as List).map((s) => Sale.fromJson(s)).toList();
      }
      final prodStr = _prefs!.getString('production');
      if (prodStr != null) {
        production = (jsonDecode(prodStr) as List).map((p) => ProductionRecord.fromJson(p)).toList();
      }
      final routesStr = _prefs!.getString('routes');
      if (routesStr != null) {
        routes = (jsonDecode(routesStr) as List).map((r) => DeliveryRoute.fromJson(r)).toList();
      }
      final invStr = _prefs!.getString('inventory');
      if (invStr != null) {
        inventory = InventoryState.fromJson(jsonDecode(invStr));
      }
      final movStr = _prefs!.getString('movements');
      if (movStr != null) {
        movements = (jsonDecode(movStr) as List).map((m) => InventoryMovement.fromJson(m)).toList();
      }
      final ticketStr = _prefs!.getString('ticket');
      if (ticketStr != null) {
        currentTicket = (jsonDecode(ticketStr) as List).map((t) => TicketItem.fromJson(t)).toList();
      }
    } catch (e) {
      debugPrint('Error loading prefs: $e');
    }
    notifyListeners();
  }

  // === POS ===
  double get ticketTotal => currentTicket.fold(0, (sum, item) => sum + item.subtotal);

  void addToTicket(Product product) {
    final existing = currentTicket.where((i) => i.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      existing.first.qty++;
    } else {
      currentTicket.add(TicketItem(id: _generateId(), product: product));
    }
    _save();
    notifyListeners();
  }

  void updateTicketQty(String itemId, int delta) {
    final item = currentTicket.firstWhere((i) => i.id == itemId, orElse: () => currentTicket.first);
    item.qty += delta;
    if (item.qty <= 0) {
      currentTicket.removeWhere((i) => i.id == itemId);
    }
    _save();
    notifyListeners();
  }

  void removeFromTicket(String itemId) {
    currentTicket.removeWhere((i) => i.id == itemId);
    _save();
    notifyListeners();
  }

  void clearTicket() {
    currentTicket.clear();
    _save();
    notifyListeners();
  }

  Sale? completeSale(double paymentAmount, {bool isCredit = false, String? clientId}) {
    if (currentTicket.isEmpty) return null;
    final total = ticketTotal;
    
    // Si es crédito, el paymentAmount es 0 o el enganche.
    final actualPayment = isCredit ? paymentAmount : paymentAmount;
    final change = isCredit ? 0.0 : paymentAmount - total;

    final sale = Sale(
      id: _generateId(),
      items: currentTicket.map((i) => TicketItem(id: i.id, product: i.product, qty: i.qty)).toList(),
      total: total,
      payment: actualPayment,
      change: change,
      date: DateTime.now(),
      status: isCredit ? 'credit' : 'paid',
      clientId: clientId,
    );
    sales.insert(0, sale);

    // Si la venta es de contado, ingresa el dinero a la caja
    if (!isCredit && activeRegister != null) {
      addCashMovement('in', total, 'Venta en mostrador Ticket #${sale.id.substring(0, 5)}');
    }

    // Impactar inventario
    final garrafones = currentTicket
        .where((i) => i.product.id == 'p1' || i.product.id == 'p2')
        .fold(0, (sum, i) => sum + i.qty);
    if (garrafones > 0) {
      inventory.full = (inventory.full - garrafones).clamp(0, 99999);
      movements.insert(0, InventoryMovement(
        id: _generateId(), type: 'out',
        description: 'Venta en mostrador ($garrafones garrafones)',
        date: DateTime.now(), amount: garrafones, unit: 'Garrafones Llenos',
      ));
    }

    currentTicket.clear();
    _save();
    notifyListeners();
    return sale;
  }

  int get todaySalesCount {
    final today = DateTime.now();
    return sales.where((s) =>
        s.date.year == today.year && s.date.month == today.month && s.date.day == today.day
    ).length;
  }

  double get todaySalesTotal {
    final today = DateTime.now();
    return sales
        .where((s) => s.date.year == today.year && s.date.month == today.month && s.date.day == today.day)
        .fold(0, (sum, s) => sum + s.total);
  }

  void clearSalesHistory() {
    sales.clear();
    _save();
    notifyListeners();
  }

  // === Producción y Materia Prima ===
  void addProduction(ProductionRecord record, int garrafonesProduced) {
    production.insert(0, record);
    // Descuento automático de insumos
    if (garrafonesProduced > 0) {
      inventory.full += garrafonesProduced;
      inventory.empty = (inventory.empty - garrafonesProduced).clamp(0, 99999);
      
      final tapasIdx = rawMaterials.indexWhere((rm) => rm.name.contains('Tapas'));
      if (tapasIdx != -1) rawMaterials[tapasIdx].stock = (rawMaterials[tapasIdx].stock - garrafonesProduced).clamp(0, 999999);
      
      final sellosIdx = rawMaterials.indexWhere((rm) => rm.name.contains('Sellos'));
      if (sellosIdx != -1) rawMaterials[sellosIdx].stock = (rawMaterials[sellosIdx].stock - garrafonesProduced).clamp(0, 999999);
    }
    _save();
    notifyListeners();
  }

  void updateProduction(String id, ProductionRecord updated) {
    final idx = production.indexWhere((p) => p.id == id);
    if (idx != -1) {
      production[idx] = updated;
      _save();
      notifyListeners();
    }
  }

  void deleteProduction(String id) {
    production.removeWhere((p) => p.id == id);
    _save();
    notifyListeners();
  }

  double get totalLitersProduced => production.fold(0, (sum, r) => sum + r.liters);

  // === Logística ===
  void addRoute(DeliveryRoute route) {
    routes.add(route);
    _save();
    notifyListeners();
  }

  void updateRoute(String id, DeliveryRoute updated) {
    final idx = routes.indexWhere((r) => r.id == id);
    if (idx != -1) {
      routes[idx] = updated;
      _save();
      notifyListeners();
    }
  }

  void updateRouteStatus(String id, String status) {
    final route = routes.firstWhere((r) => r.id == id);
    route.status = status;
    if (status == 'completed') route.completed = route.total;
    _save();
    notifyListeners();
  }

  void advanceRoute(String id) {
    final route = routes.firstWhere((r) => r.id == id);
    if (route.completed < route.total) {
      route.completed++;
      _save();
      notifyListeners();
    }
  }

  void deleteRoute(String id) {
    routes.removeWhere((r) => r.id == id);
    _save();
    notifyListeners();
  }

  int get totalDeliveries => routes.fold(0, (sum, r) => sum + r.total);
  int get completedDeliveries => routes.fold(0, (sum, r) => sum + r.completed);

  // === Inventario ===
  void addMovement(InventoryMovement movement) {
    final amount = movement.amount;
    if (movement.type == 'in') {
      if (movement.unit.toLowerCase().contains('lleno')) {
        inventory.full += amount;
      } else if (movement.unit.toLowerCase().contains('vacío') || movement.unit.toLowerCase().contains('vacio')) {
        inventory.empty += amount;
      }
    } else {
      if (movement.unit.toLowerCase().contains('lleno')) {
        inventory.full = (inventory.full - amount).clamp(0, 99999);
      } else if (movement.unit.toLowerCase().contains('vacío') || movement.unit.toLowerCase().contains('vacio')) {
        inventory.empty = (inventory.empty - amount).clamp(0, 99999);
      }
    }
    movements.insert(0, movement);
    _save();
    notifyListeners();
  }

  // === Compras ===
  void receivePurchase(String purchaseId) {
    final idx = purchases.indexWhere((p) => p.id == purchaseId);
    if (idx != -1 && purchases[idx].status == 'pending') {
      purchases[idx].status = 'received';
      final rmIdx = rawMaterials.indexWhere((rm) => rm.id == purchases[idx].rawMaterialId);
      if (rmIdx != -1) {
        rawMaterials[rmIdx].stock += purchases[idx].quantity;
      }
      _save();
      notifyListeners();
    }
  }

  void addPurchase(Purchase purchase) {
    purchases.insert(0, purchase);
    _save();
    notifyListeners();
  }

  // === Caja y Finanzas ===
  void openRegister(double initialBalance) {
    activeRegister = CashRegister(
      id: _generateId(),
      openedAt: DateTime.now(),
      openingBalance: initialBalance,
      status: 'open',
    );
    registers.add(activeRegister!);
    _save();
    notifyListeners();
  }

  void closeRegister() {
    if (activeRegister != null) {
      activeRegister!.closedAt = DateTime.now();
      activeRegister!.closingBalance = activeRegister!.openingBalance + currentCashInRegister();
      activeRegister!.status = 'closed';
      activeRegister = null;
      _save();
      notifyListeners();
    }
  }

  void addCashMovement(String type, double amount, String description) {
    if (activeRegister == null) return;
    cashMovements.add(CashMovement(
      id: _generateId(),
      registerId: activeRegister!.id,
      type: type,
      amount: amount,
      description: description,
      date: DateTime.now(),
    ));
    _save();
    notifyListeners();
  }

  double currentCashInRegister() {
    if (activeRegister == null) return 0;
    final moves = cashMovements.where((m) => m.registerId == activeRegister!.id);
    double inCash = moves.where((m) => m.type == 'in').fold(0, (sum, m) => sum + m.amount);
    double outCash = moves.where((m) => m.type == 'out').fold(0, (sum, m) => sum + m.amount);
    return inCash - outCash;
  }

  // === Créditos ===
  void addCreditPayment(String saleId, double amount) {
    creditPayments.add(CreditPayment(
      id: _generateId(),
      saleId: saleId,
      amount: amount,
      date: DateTime.now(),
    ));

    if (activeRegister != null) {
      addCashMovement('in', amount, 'Abono a cuenta Sale #${saleId.substring(0, 5)}');
    }

    // Check if fully paid
    final saleIdx = sales.indexWhere((s) => s.id == saleId);
    if (saleIdx != -1) {
      final sale = sales[saleIdx];
      final totalPaid = sale.payment + creditPayments.where((cp) => cp.saleId == saleId).fold(0.0, (s, cp) => s + cp.amount);
      if (totalPaid >= sale.total) {
        // En Dart los objetos son mutables pero `Sale` tiene campos final. No podemos cambiar el status directamente.
        // Reemplazamos la venta
        sales[saleIdx] = Sale(
          id: sale.id, items: sale.items, total: sale.total, payment: sale.payment, change: sale.change,
          date: sale.date, status: 'paid', clientId: sale.clientId,
        );
      }
    }
    _save();
    notifyListeners();
  }

  // === Reset ===
  void resetAll() {
    currentTicket.clear();
    sales.clear();
    _loadDefaults();
    _save();
    notifyListeners();
  }
}
