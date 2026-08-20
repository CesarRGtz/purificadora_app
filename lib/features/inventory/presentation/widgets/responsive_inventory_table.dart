import 'package:flutter/material.dart';

class ResponsiveInventoryTable extends StatefulWidget {
  const ResponsiveInventoryTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.minWidth,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;

  @override
  State<ResponsiveInventoryTable> createState() =>
      _ResponsiveInventoryTableState();
}

class _ResponsiveInventoryTableState extends State<ResponsiveInventoryTable> {
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
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : widget.minWidth;
          final tableWidth = availableWidth > widget.minWidth
              ? availableWidth
              : widget.minWidth;

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
                constraints: BoxConstraints(minWidth: tableWidth),
                child: DataTable(
                  columnSpacing: 28,
                  horizontalMargin: 20,
                  columns: widget.columns,
                  rows: widget.rows,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
