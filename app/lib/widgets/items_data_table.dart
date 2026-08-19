import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item_pca.dart';

class ItemsDataTable extends StatelessWidget {
  final List<ItemPCA> itens;
  final bool isGuest;
  final bool isLoading;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final void Function(ItemPCA) onEdit;
  final void Function(ItemPCA) onDelete;

  const ItemsDataTable({
    super.key,
    required this.itens,
    required this.isGuest,
    required this.isLoading,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatBrl(double val) {
    String fixed = val.toStringAsFixed(2);
    List<String> parts = fixed.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];
    final RegExp reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    integerPart = integerPart.replaceAllMapped(reg, (Match match) => '.');
    return 'R\$ $integerPart,$decimalPart';
  }

  Widget _buildCategoryBadge(String pasta) {
    Color color;
    Color textColor;
    if (pasta == 'Laboratórios') {
      color = const Color(0xFFEFF6FF);
      textColor = const Color(0xFF1E40AF);
    } else if (pasta == 'GEAAD') {
      color = const Color(0xFFECFDF5);
      textColor = const Color(0xFF065F46);
    } else {
      color = const Color(0xFFF5F3FF);
      textColor = const Color(0xFF6D28D9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        pasta,
        style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold, fontSize: 8),
      ),
    );
  }

  Widget _buildResourceBadge(String cat) {
    Color color;
    Color textColor;
    if (cat == 'Equipamento') {
      color = const Color(0xFFFEF2F2);
      textColor = const Color(0xFF991B1B);
    } else if (cat == 'Serviço') {
      color = const Color(0xFFFEF3C7);
      textColor = const Color(0xFF92400E);
    } else {
      color = const Color(0xFFECFDF5);
      textColor = const Color(0xFF065F46);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        cat,
        style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold, fontSize: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }
    if (itens.isEmpty) {
      return Center(
        child: Text(
          'Nenhum item cadastrado.',
          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 16),
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double tableWidth = availableWidth > 900 ? availableWidth : 900;
        
        final col1Width = tableWidth * 0.13;
        final col2Width = tableWidth * 0.18;
        final col3Width = tableWidth * 0.36;
        final col4Width = tableWidth * 0.11;
        final col5Width = tableWidth * 0.12;
        final col6Width = isGuest ? 0.0 : tableWidth * 0.07;

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Scrollbar(
            controller: verticalScrollController,
            thumbVisibility: true,
            child: Scrollbar(
              controller: horizontalScrollController,
              thumbVisibility: true,
              notificationPredicate: (notif) => notif.depth == 1,
              child: SingleChildScrollView(
                controller: verticalScrollController,
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  controller: horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    horizontalMargin: 8,
                    columnSpacing: 10,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 64,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: [
                      DataColumn(label: SizedBox(width: col1Width, child: Text('Origem / Recurso', style: GoogleFonts.inter(color: const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12)))),
                      DataColumn(label: SizedBox(width: col2Width, child: Text('Área / Subgrupo', style: GoogleFonts.inter(color: const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12)))),
                      DataColumn(label: SizedBox(width: col3Width, child: Text('Item / Código', style: GoogleFonts.inter(color: const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12)))),
                      DataColumn(label: SizedBox(width: col4Width, child: Text('Qtd / Unid', style: GoogleFonts.inter(color: const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12)))),
                      DataColumn(numeric: true, label: SizedBox(width: col5Width, child: Align(alignment: Alignment.centerRight, child: Text('Valor Estimado', style: GoogleFonts.inter(color: const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12))))),
                      if (!isGuest)
                        DataColumn(label: SizedBox(width: col6Width, child: Text('Ações', style: GoogleFonts.inter(color: const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12)))),
                    ],
                    rows: itens.map((item) {
                      return DataRow(
                        cells: [
                          // Origem / Recurso
                          DataCell(
                            Container(
                              width: col1Width,
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildCategoryBadge(item.origemPasta),
                                  const SizedBox(height: 3),
                                  _buildResourceBadge(item.categoriaItem),
                                ],
                              ),
                            ),
                          ),
                          // Área / Subgrupo
                          DataCell(
                            Container(
                              width: col2Width,
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(item.laboratorio, style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
                                  const SizedBox(height: 3),
                                  Text(item.setor, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
                                ],
                              ),
                            ),
                          ),
                          // Item / Código
                          DataCell(
                            Container(
                              width: col3Width,
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (item.codigo.isNotEmpty) ...[
                                    Text(item.codigo, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 1),
                                  ],
                                  Text(
                                    item.item,
                                    style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.w500, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Qtd / Unid
                          DataCell(
                            Container(
                              width: col4Width,
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(item.quantidade.toString(), style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 1),
                                  Text(item.unidade, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 1),
                                ],
                              ),
                            ),
                          ),
                          // Valor Estimado
                          DataCell(
                            Container(
                              width: col5Width,
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_formatBrl(item.valorTotal), style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 1),
                                  Text('Unit: ${_formatBrl(item.valorUnitario)}', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                          // Ações
                          if (!isGuest)
                            DataCell(
                              SizedBox(
                                width: col6Width,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => onEdit(item),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, color: Color(0xFFDC2626), size: 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => onDelete(item),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
