class ItemPCA {
  final int? id;
  final String origemPasta;
  final String origemArquivo;
  final String laboratorio;
  final String setor;
  final String categoriaItem;
  final String tipo;
  final String codigo;
  final String item;
  final String unidade;
  final double quantidade;
  final double valorUnitario;
  final double valorTotal;
  final int? ano;

  ItemPCA({
    this.id,
    required this.origemPasta,
    required this.origemArquivo,
    required this.laboratorio,
    required this.setor,
    required this.categoriaItem,
    required this.tipo,
    required this.codigo,
    required this.item,
    required this.unidade,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
    this.ano = 2027,
  });

  factory ItemPCA.fromJson(Map<String, dynamic> json) {
    return ItemPCA(
      id: json['id'],
      origemPasta: json['origem_pasta'] ?? '',
      origemArquivo: json['origem_arquivo'] ?? '',
      laboratorio: json['laboratorio'] ?? '',
      setor: json['setor'] ?? '',
      categoriaItem: json['categoria_item'] ?? '',
      tipo: json['tipo'] ?? '',
      codigo: json['codigo'] ?? '',
      item: json['item'] ?? '',
      unidade: json['unidade'] ?? '',
      quantidade: (json['quantidade'] as num?)?.toDouble() ?? 0.0,
      valorUnitario: (json['valor_unitario'] as num?)?.toDouble() ?? 0.0,
      valorTotal: (json['valor_total'] as num?)?.toDouble() ?? 0.0,
      ano: json['ano'] != null ? (json['ano'] as num).toInt() : 2027,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origem_pasta': origemPasta,
      'origem_arquivo': origemArquivo,
      'laboratorio': laboratorio,
      'setor': setor,
      'categoria_item': categoriaItem,
      'tipo': tipo,
      'codigo': codigo,
      'item': item,
      'unidade': unidade,
      'quantidade': quantidade,
      'valor_unitario': valorUnitario,
      'ano': ano ?? 2027,
    };
  }
}
