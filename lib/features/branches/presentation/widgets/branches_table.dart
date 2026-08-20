import 'package:flutter/material.dart';

import '../../domain/entities/branch.dart';

class BranchesTable extends StatefulWidget {
  const BranchesTable({
    super.key,
    required this.branches,
    required this.onConfigureProducts,
    required this.onEdit,
    required this.onDelete,
    required this.actionsEnabled,
  });

  final List<Branch> branches;
  final ValueChanged<Branch> onConfigureProducts;
  final ValueChanged<Branch> onEdit;
  final ValueChanged<Branch> onDelete;
  final bool actionsEnabled;

  @override
  State<BranchesTable> createState() => _BranchesTableState();
}

class _BranchesTableState extends State<BranchesTable> {
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
                    DataColumn(label: Text('Negocio')),
                    DataColumn(label: Text('Dirección')),
                    DataColumn(label: Text('Coordenadas')),
                    DataColumn(label: Text('Productos')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: widget.branches
                      .map((branch) {
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 190,
                                child: Text(
                                  branch.name,
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
                                width: 210,
                                child: Text(
                                  branch.businessName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 270,
                                child: Text(
                                  branch.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              SelectableText(
                                '${branch.latitude.toStringAsFixed(6)}, '
                                '${branch.longitude.toStringAsFixed(6)}',
                              ),
                            ),
                            DataCell(
                              OutlinedButton.icon(
                                onPressed: widget.actionsEnabled
                                    ? () => widget.onConfigureProducts(branch)
                                    : null,
                                icon: const Icon(Icons.tune, size: 18),
                                label: const Text('Configurar'),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Editar sucursal',
                                    onPressed: widget.actionsEnabled
                                        ? () => widget.onEdit(branch)
                                        : null,
                                    icon: const Icon(Icons.edit_outlined),
                                    color: const Color(0xFF2B528A),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar sucursal',
                                    onPressed: widget.actionsEnabled
                                        ? () => widget.onDelete(branch)
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
