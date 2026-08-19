import 'dart:io';
import '../models/item_pca.dart';

class ExportService {
  static String datetimeToBrl(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static Future<String> exportCSV(List<ItemPCA> itens, int selectedYear) async {
    final buffer = StringBuffer();
    buffer.writeln('ID;Categoria;Planilha;Laboratório;Setor;Recurso;Código;Descrição;Unidade;Quantidade;Valor Unitário;Valor Total');
    
    for (var item in itens) {
      buffer.writeln(
        '${item.id};'
        '${item.origemPasta};'
        '${item.origemArquivo};'
        '${item.laboratorio};'
        '${item.setor};'
        '${item.categoriaItem};'
        '${item.codigo};'
        '"${item.item.replaceAll('"', '""')}";'
        '${item.unidade};'
        '${item.quantidade.toString().replaceAll('.', ',')};'
        '${item.valorUnitario.toString().replaceAll('.', ',')};'
        '${item.valorTotal.toString().replaceAll('.', ',')}'
      );
    }

    final dir = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}\\pca_export_$selectedYear.csv');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  static Future<String> exportTXT(List<ItemPCA> itens, Map<String, dynamic> estatisticas, int selectedYear) async {
    final buffer = StringBuffer();
    buffer.writeln('========================================================================');
    buffer.writeln('                   ITPS - PLANO DE CONTRATAÇÕES ANUAL (PCA) $selectedYear        ');
    buffer.writeln('                           RELATÓRIO CONSOLIDADO                        ');
    buffer.writeln('========================================================================\n');
    buffer.writeln('Gerado em: ${datetimeToBrl(DateTime.now())}\n');
    
    final valorTotal = estatisticas['valor_total'] ?? 0.0;
    final totalItens = estatisticas['total_itens'] ?? 0;
    buffer.writeln('Métricas Consolidadas:');
    buffer.writeln('  - Quantidade de Itens: $totalItens');
    buffer.writeln('  - Valor Total Planejado: R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}\n');
    buffer.writeln('------------------------------------------------------------------------');
    buffer.writeln('ID | Laboratório | Setor | Recurso | Descrição | Qtd. | Val. Unit. | Total');
    buffer.writeln('------------------------------------------------------------------------');
    
    for (var item in itens) {
      buffer.writeln(
        '${item.id} | '
        '${item.laboratorio} | '
        '${item.setor} | '
        '${item.categoriaItem} | '
        '${item.item.length > 30 ? '${item.item.substring(0, 27)}...' : item.item} | '
        '${item.quantidade} | '
        'R\$ ${item.valorUnitario.toStringAsFixed(2)} | '
        'R\$ ${item.valorTotal.toStringAsFixed(2)}'
      );
    }
    buffer.writeln('\n========================================================================');

    final dir = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}\\relatorio_pca_$selectedYear.txt');
    await file.writeAsString(buffer.toString());
    return file.path;
  }
}
