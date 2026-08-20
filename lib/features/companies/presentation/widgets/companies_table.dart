import 'package:flutter/material.dart';

import '../../domain/entities/company.dart';

class CompaniesTable extends StatefulWidget {
  const CompaniesTable({
    super.key,
    required this.companies,
    required this.onEdit,
    required this.onDelete,
    required this.actionsEnabled,
  });

  final List<Company> companies;
  final ValueChanged<Company> onEdit;
  final ValueChanged<Company> onDelete;
  final bool actionsEnabled;

  @override
  State<CompaniesTable> createState() => _CompaniesTableState();
}

class _CompaniesTableState extends State<CompaniesTable> {
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
                    DataColumn(label: Text('Razón social')),
                    DataColumn(label: Text('RFC')),
                    DataColumn(label: Text('Dirección fiscal')),
                    DataColumn(label: Text('Teléfono')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: widget.companies
                      .map((company) {
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  company.businessName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(SelectableText(company.rfc)),
                            DataCell(
                              SizedBox(
                                width: 280,
                                child: Text(
                                  company.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(SelectableText(company.phone)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Editar empresa',
                                    onPressed: widget.actionsEnabled
                                        ? () => widget.onEdit(company)
                                        : null,
                                    icon: const Icon(Icons.edit_outlined),
                                    color: const Color(0xFF2B528A),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar empresa',
                                    onPressed: widget.actionsEnabled
                                        ? () => widget.onDelete(company)
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
