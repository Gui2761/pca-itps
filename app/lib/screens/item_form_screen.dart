import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item_pca.dart';
import '../services/api_service.dart';

class ItemFormScreen extends StatefulWidget {
  final ItemPCA? item;
  final String? forcedLaboratorio;

  const ItemFormScreen({super.key, this.item, this.forcedLaboratorio});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late String _origemPasta;
  late TextEditingController _origemArquivoController;
  late String _laboratorio;
  late TextEditingController _setorController;
  late String _categoriaItem;
  late TextEditingController _tipoController;
  late TextEditingController _codigoController;
  late int _ano;
  late TextEditingController _itemController;
  late TextEditingController _unidadeController;
  late TextEditingController _quantidadeController;
  late TextEditingController _valorUnitarioController;

  double _valorTotal = 0.0;
  bool _isLoading = false;

  List<String> _laboratoriosList = [
    'Química de Águas',
    'Inorgânica',
    'Microbiologia',
    'Solos',
    'Bromatologia',
    'Orgânica',
    'Qualidade',
    'Geconf',
    'GEAAD / Insumos Gerais'
  ];

  List<String> _categoriasList = [
    'Material de Consumo',
    'Equipamento',
    'Serviço'
  ];

  Future<void> _loadDynamicOptions() async {
    try {
      final labs = await _apiService.fetchLaboratorios();
      final cats = await _apiService.fetchTiposRecurso();
      if (mounted) {
        setState(() {
          if (labs.isNotEmpty) {
            _laboratoriosList = labs;
            if (!_laboratoriosList.contains(_laboratorio)) {
              _laboratoriosList.add(_laboratorio);
            }
          }
          if (cats.isNotEmpty) {
            _categoriasList = cats;
            if (!_categoriasList.contains(_categoriaItem)) {
              _categoriasList.add(_categoriaItem);
            }
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar opções dinâmicas nos formulários: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _origemPasta = item?.origemPasta ?? 'Laboratórios';
    if (_origemPasta == 'PCA') _origemPasta = 'Laboratórios';
    _origemArquivoController = TextEditingController(text: item?.origemArquivo ?? 'Inserção Direta');
    _ano = item?.ano ?? 2026;
    
    _laboratorio = widget.forcedLaboratorio ?? item?.laboratorio ?? 'GEAAD / Insumos Gerais';
    if (!_laboratoriosList.contains(_laboratorio)) {
      _laboratoriosList.add(_laboratorio);
    }
    
    _setorController = TextEditingController(text: item?.setor ?? 'Geral');
    
    _categoriaItem = item?.categoriaItem ?? 'Material de Consumo';
    if (!_categoriasList.contains(_categoriaItem)) {
      _categoriasList.add(_categoriaItem);
    }

    _tipoController = TextEditingController(text: item?.tipo ?? '');
    _codigoController = TextEditingController(text: item?.codigo ?? '');
    _itemController = TextEditingController(text: item?.item ?? '');
    _unidadeController = TextEditingController(text: item?.unidade ?? 'Unidade');
    _quantidadeController = TextEditingController(text: item?.quantidade == null ? '1' : item!.quantidade.toString());
    _valorUnitarioController = TextEditingController(text: item?.valorUnitario == null ? '0.0' : item!.valorUnitario.toString());

    _quantidadeController.addListener(_recalculateTotal);
    _valorUnitarioController.addListener(_recalculateTotal);
    _recalculateTotal();
    _loadDynamicOptions();
  }

  void _recalculateTotal() {
    final qty = double.tryParse(_quantidadeController.text) ?? 0.0;
    final unitVal = double.tryParse(_valorUnitarioController.text) ?? 0.0;
    setState(() {
      _valorTotal = qty * unitVal;
    });
  }

  @override
  void dispose() {
    _origemArquivoController.dispose();
    _setorController.dispose();
    _tipoController.dispose();
    _codigoController.dispose();
    _itemController.dispose();
    _unidadeController.dispose();
    _quantidadeController.dispose();
    _valorUnitarioController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final itemInput = ItemPCA(
      id: widget.item?.id,
      origemPasta: _origemPasta,
      origemArquivo: _origemArquivoController.text,
      laboratorio: _laboratorio,
      setor: _setorController.text,
      categoriaItem: _categoriaItem,
      tipo: _tipoController.text,
      codigo: _codigoController.text,
      item: _itemController.text,
      unidade: _unidadeController.text,
      quantidade: double.tryParse(_quantidadeController.text) ?? 0.0,
      valorUnitario: double.tryParse(_valorUnitarioController.text) ?? 0.0,
      valorTotal: _valorTotal,
      ano: _ano,
    );

    bool success;
    if (widget.item == null) {
      success = await _apiService.createItem(itemInput);
    } else {
      success = await _apiService.updateItem(widget.item!.id!, itemInput);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null ? 'Item cadastrado com sucesso!' : 'Item atualizado com sucesso!',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao salvar o item no banco de dados central.',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Editar Item do PCA' : 'Novo Item do PCA',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF131A2C),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A2C).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Atualize as informações do item' : 'Preencha os campos abaixo',
                          style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildDropdown(
                                label: 'Categoria / Pasta',
                                value: _origemPasta,
                                items: ['Laboratórios', 'GEAAD'],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _origemPasta = val;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ano do PCA',
                                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: _ano,
                                    dropdownColor: const Color(0xFF131A2C),
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                                    items: [2026, 2027, 2028, 2029, 2030].map<DropdownMenuItem<int>>((int yr) {
                                      return DropdownMenuItem<int>(
                                        value: yr,
                                        child: Text(yr.toString()),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _ano = val;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      fillColor: const Color(0xFF0B0F19).withOpacity(0.4),
                                      filled: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                label: 'Planilha de Referência',
                                controller: _origemArquivoController,
                                placeholder: 'Ex: Lab. Aguas.xlsx',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                label: 'Laboratório / Área *',
                                value: _laboratorio,
                                items: _laboratoriosList,
                                onChanged: widget.forcedLaboratorio != null ? null : (val) {
                                  if (val != null) {
                                    setState(() {
                                      _laboratorio = val;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: 'Subgrupo / Finalidade *',
                                controller: _setorController,
                                placeholder: 'Ex: Cromatografia, Manutenção, ICP, AA',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                label: 'Tipo de Recurso *',
                                value: _categoriaItem,
                                items: _categoriasList,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _categoriaItem = val;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: 'Código i-Gesp',
                                controller: _codigoController,
                                placeholder: 'Ex: 391257-4',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Descrição do Item *',
                          controller: _itemController,
                          placeholder: 'Digite a especificação completa do item...',
                          maxLines: 3,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'A descrição do item é obrigatória.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Unidade de Medida',
                                controller: _unidadeController,
                                placeholder: 'Ex: Unidade, Frasco, Pacote',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: 'Quantidade *',
                                controller: _quantidadeController,
                                placeholder: '0',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (val == null || double.tryParse(val) == null) {
                                    return 'Digite um número válido.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: 'Valor Unitário (R\$) *',
                                controller: _valorUnitarioController,
                                placeholder: '0.00',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (val == null || double.tryParse(val) == null) {
                                    return 'Digite um valor válido.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0F19).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'VALOR ESTIMADO TOTAL:',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                'R\$ ${_valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: const Color(0xFF94A3B8),
                                side: BorderSide(color: Colors.white.withOpacity(0.08)),
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _saveForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ).copyWith(
                                overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.save_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(isEdit ? 'Salvar Alterações' : 'Cadastrar Item'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
            fillColor: const Color(0xFF0B0F19).withOpacity(0.4),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            ),
            errorStyle: GoogleFonts.inter(color: const Color(0xFFEF4444)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF131A2C),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          items: items.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          decoration: InputDecoration(
            fillColor: const Color(0xFF0B0F19).withOpacity(0.4),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
