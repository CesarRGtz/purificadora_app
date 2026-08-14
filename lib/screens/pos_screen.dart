import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/toast_helper.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.activeRegister == null) {
          return _buildOpenRegister(context, state);
        }

        final isWide = MediaQuery.of(context).size.width > 900;

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildCatalog(context, state)),
                const SizedBox(width: 24),
                SizedBox(width: 380, child: _buildTicket(context, state)),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCatalog(context, state),
                const SizedBox(height: 16),
                SizedBox(height: 500, child: _buildTicket(context, state)),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildOpenRegister(BuildContext context, AppState state) {
    final controller = TextEditingController(text: '0.00');
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.point_of_sale, size: 64, color: Color(0xFF26C6DA)),
              const SizedBox(height: 24),
              const Text('Caja Cerrada', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              const Text('Abre la caja para comenzar a cobrar', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 32),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fondo Inicial de Caja (MXN)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  final initial = double.tryParse(controller.text) ?? 0;
                  state.openRegister(initial);
                  ToastHelper.show(context, 'Caja abierta con \$${initial.toStringAsFixed(2)}', type: ToastType.success);
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('Abrir Turno'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalog(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats
        Row(
          children: [
            const Text('Catálogo de Productos', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showAccountsReceivableDialog(context, state),
              icon: const Icon(Icons.handshake, size: 16),
              label: const Text('Créditos'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.8)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showCashDialog(context, state),
              icon: const Icon(Icons.account_balance_wallet, size: 16),
              label: const Text('Movimientos'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.withOpacity(0.8)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                state.closeRegister();
                ToastHelper.show(context, 'Corte de caja realizado', type: ToastType.info);
              },
              icon: const Icon(Icons.lock, size: 16),
              label: const Text('Corte Caja'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.8)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Products Grid
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: state.products.map((product) => _ProductCard(product: product)).toList(),
        ),
        // Sales history
        if (state.sales.isNotEmpty) ...[
          const SizedBox(height: 28),
          Row(
            children: [
              const Text('Historial de Ventas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  state.clearSalesHistory();
                  ToastHelper.show(context, 'Historial limpiado', type: ToastType.info);
                },
                icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.black54),
                label: const Text('Limpiar', style: const TextStyle(color: Colors.black54)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
                dataTextStyle: const TextStyle(fontSize: 14, color: Colors.black87),
                columns: const [
                  DataColumn(label: Text('HORA')),
                  DataColumn(label: Text('ARTÍCULOS')),
                  DataColumn(label: Text('TOTAL')),
                  DataColumn(label: Text('PAGO')),
                  DataColumn(label: Text('CAMBIO')),
                ],
                rows: state.sales.take(10).map((sale) {
                  final time = '${sale.date.hour.toString().padLeft(2, '0')}:${sale.date.minute.toString().padLeft(2, '0')}';
                  return DataRow(cells: [
                    DataCell(Text(time)),
                    DataCell(Text('${sale.itemCount} artículo(s)')),
                    DataCell(Text('\$${sale.total.toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700))),
                    DataCell(Text('\$${sale.payment.toStringAsFixed(2)}')),
                    DataCell(Text('\$${sale.change.toStringAsFixed(2)}')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTicket(BuildContext context, AppState state) {
    final hasItems = state.currentTicket.isNotEmpty;

    return GlassCard(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('🧾', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                const Text('Ticket Actual', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                const Spacer(),
                if (hasItems)
                  IconButton(
                    onPressed: () {
                      state.clearTicket();
                      ToastHelper.show(context, 'Ticket vaciado', type: ToastType.info);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.black54, size: 20),
                    tooltip: 'Vaciar ticket',
                  ),
              ],
            ),
          ),
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),

          // Items
          Expanded(
            child: hasItems
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: state.currentTicket.length,
                    itemBuilder: (context, index) {
                      final item = state.currentTicket[index];
                      return _TicketItemRow(item: item);
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🛒', style: TextStyle(fontSize: 48, color: Colors.black12)),
                        const SizedBox(height: 12),
                        const Text('No hay artículos en la venta',
                            style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 4),
                        const Text('Selecciona un producto del catálogo',
                            style: const TextStyle(fontSize: 13, color: Colors.black38)),
                      ],
                    ),
                  ),
          ),

          Divider(color: Colors.grey.withOpacity(0.2), height: 1),

          // Footer
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                    Text(
                      '\$${state.ticketTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: hasItems ? () => _showPaymentDialog(context, state) : null,
                    icon: const Icon(Icons.payments, size: 22),
                    label: const Text('COBRAR', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF10B981),
                      disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, AppState state) {
    final total = state.ticketTotal;
    final controller = TextEditingController(text: total.toStringAsFixed(2));
    double change = 0;
    bool isCredit = false;
    String? selectedClientId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void updateChange() {
            final payment = double.tryParse(controller.text) ?? 0;
            setDialogState(() => change = (payment - total).clamp(0, double.infinity));
          }

          return AlertDialog(
            title: const Row(
              children: [
                Text('💰 ', style: TextStyle(fontSize: 24)),
                Text('Cobrar Venta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Al Contado'),
                        selected: !isCredit,
                        onSelected: (val) => setDialogState(() => isCredit = !val),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('A Crédito'),
                        selected: isCredit,
                        onSelected: (val) => setDialogState(() => isCredit = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Total
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isCredit ? Colors.orange.withOpacity(0.08) : const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('Total de la venta', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text('\$${total.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: isCredit ? Colors.orange : const Color(0xFF10B981))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  if (isCredit) ...[
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Seleccionar Cliente'),
                      items: state.clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) => setDialogState(() => selectedClientId = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Enganche Inicial (Opcional)'),
                    ),
                  ] else ...[
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: 'Monto recibido (MXN)'),
                      onChanged: (_) => updateChange(),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    // Change display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text('Cambio', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          Text('\$${change.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quick pay buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _quickPayButton('Exacto', total, controller, updateChange),
                        _quickPayButton('\$50', 50, controller, updateChange),
                        _quickPayButton('\$100', 100, controller, updateChange),
                        _quickPayButton('\$200', 200, controller, updateChange),
                        _quickPayButton('\$500', 500, controller, updateChange),
                        _quickPayButton('\$1000', 1000, controller, updateChange),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final payment = double.tryParse(controller.text) ?? 0;
                  if (!isCredit && payment < total) {
                    ToastHelper.show(context, 'El monto es menor al total', type: ToastType.error);
                    return;
                  }
                  if (isCredit && selectedClientId == null) {
                    ToastHelper.show(context, 'Selecciona un cliente para el crédito', type: ToastType.error);
                    return;
                  }

                  final sale = state.completeSale(payment, isCredit: isCredit, clientId: selectedClientId);
                  Navigator.pop(ctx);
                  if (sale != null) {
                    if (isCredit) {
                      ToastHelper.show(context, 'Crédito registrado', type: ToastType.success);
                    } else {
                      ToastHelper.show(context, 'Venta completada — Cambio: \$${sale.change.toStringAsFixed(2)}', type: ToastType.success);
                    }
                  }
                },
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Confirmar Venta'),
                style: ElevatedButton.styleFrom(backgroundColor: isCredit ? Colors.orange : const Color(0xFF10B981)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCashDialog(BuildContext context, AppState state) {
    final typeCtrl = TextEditingController(text: 'out');
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('💸 Registrar Movimiento de Caja'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: typeCtrl.text,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'in', child: Text('Ingreso Manual (Fondo)')),
                  DropdownMenuItem(value: 'out', child: Text('Gasto / Retiro')),
                ],
                onChanged: (val) => typeCtrl.text = val!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción / Concepto'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto (MXN)'),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              if (descCtrl.text.isEmpty || amt <= 0) {
                ToastHelper.show(context, 'Campos inválidos', type: ToastType.error);
                return;
              }
              state.addCashMovement(typeCtrl.text, amt, descCtrl.text);
              Navigator.pop(ctx);
              ToastHelper.show(context, 'Movimiento registrado', type: ToastType.success);
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  void _showAccountsReceivableDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('🤝 Cuentas por Cobrar (Créditos Activos)'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: Consumer<AppState>(
              builder: (ctx2, innerState, _) {
                final pendingCredits = innerState.sales.where((s) => s.status == 'credit').toList();

                if (pendingCredits.isEmpty) {
                  return Center(
                    child: const Text('No hay cuentas por cobrar pendientes',
                        style: TextStyle(color: Colors.black54)),
                  );
                }

                return ListView.builder(
                  itemCount: pendingCredits.length,
                  itemBuilder: (ctx3, index) {
                    final sale = pendingCredits[index];
                    final client = innerState.clients.firstWhere((c) => c.id == sale.clientId, orElse: () => Client(id: '', name: 'Desconocido', type: 'Normal', latitude: 0, longitude: 0, priceListId: ''));
                    final totalPaid = sale.payment + innerState.creditPayments.where((cp) => cp.saleId == sale.id).fold(0.0, (s, cp) => s + cp.amount);
                    final debt = sale.total - totalPaid;
                    final dateStr = '${sale.date.day}/${sale.date.month} ${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}';

                    return ListTile(
                      title: Text('Venta #${sale.id.substring(0, 5)} • ${client.name}'),
                      subtitle: Text('Fecha: $dateStr • Artículos: ${sale.itemCount}\nTotal: \$${sale.total.toStringAsFixed(2)} • Abonado: \$${totalPaid.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Resta: \$${debt.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              _showAddPaymentDialog(context, innerState, sale, debt);
                            },
                            child: const Text('Abonar'),
                          )
                        ],
                      ),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          ],
        );
      },
    );
  }

  void _showAddPaymentDialog(BuildContext context, AppState state, Sale sale, double debt) {
    final amountCtrl = TextEditingController(text: debt.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Abonar a Venta #${sale.id.substring(0, 5)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Deuda actual: \$${debt.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto a Abonar (MXN)'),
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              if (amt <= 0 || amt > debt) {
                ToastHelper.show(context, 'Monto inválido. No puede ser 0 ni mayor a la deuda.', type: ToastType.error);
                return;
              }
              state.addCreditPayment(sale.id, amt);
              Navigator.pop(ctx);
              ToastHelper.show(context, 'Abono registrado', type: ToastType.success);
            },
            child: const Text('Registrar Abono'),
          )
        ],
      ),
    );
  }

  Widget _quickPayButton(String label, double amount, TextEditingController controller, VoidCallback onUpdate) {
    return OutlinedButton(
      onPressed: () {
        controller.text = amount.toStringAsFixed(2);
        onUpdate();
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

// === Product Card Widget ===
class _ProductCard extends StatefulWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) {
          _animController.reverse();
          context.read<AppState>().addToTicket(widget.product);
          ToastHelper.show(context, '${widget.product.name} agregado', type: ToastType.success);
        },
        onTapCancel: () => _animController.reverse(),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.product.icon, style: const TextStyle(fontSize: 42)),
              const SizedBox(height: 14),
              Text(
                widget.product.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${widget.product.price.toStringAsFixed(2)} MXN',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === Ticket Item Row ===
class _TicketItemRow extends StatelessWidget {
  final TicketItem item;
  const _TicketItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.product.icon} ${item.product.name}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                Text('\$${item.product.price.toStringAsFixed(2)} c/u',
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          // Qty controls
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _qtyButton(Icons.remove, () => state.updateTicketQty(item.id, -1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                _qtyButton(Icons.add, () => state.updateTicketQty(item.id, 1)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 70,
            child: Text(
              '\$${item.subtotal.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          IconButton(
            onPressed: () => state.removeFromTicket(item.id),
            icon: Icon(Icons.close, size: 18, color: Colors.red.withOpacity(0.6)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
