import 'package:flutter/material.dart';

import '../../domain/entities/supplier.dart';

class SuppliersTable extends StatefulWidget {
  const SuppliersTable({
    super.key,
    required this.suppliers,
    required this.onEdit,
    required this.onDelete,
    required this.actionsEnabled,
  });

  final List<Supplier> suppliers;
  final ValueChanged<Supplier> onEdit;
  final ValueChanged<Supplier> onDelete;
  final bool actionsEnabled;

  @override
  State<SuppliersTable> createState() => _SuppliersTableState();
}

class _SuppliersTableState extends State<SuppliersTable> {
  final _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            thickness: 8,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: 28,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Text('Sucursal')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Dirección')),
                    DataColumn(label: Text('Teléfono')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: widget.suppliers
                      .map((supplier) {
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  supplier.branchName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  supplier.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 280,
                                child: Text(
                                  supplier.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(SelectableText(supplier.phone)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Editar proveedor',
                                    onPressed: widget.actionsEnabled
                                        ? () => widget.onEdit(supplier)
                                        : null,
                                    icon: const Icon(Icons.edit_outlined),
                                    color: const Color(0xFF2B528A),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar proveedor',
                                    onPressed: widget.actionsEnabled
                                        ? () => widget.onDelete(supplier)
                                        : null,
                                    icon: const Icon(Icons.delete_outline),
                                    color: const Color(0xFFDC2626),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
