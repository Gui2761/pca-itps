import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class ImportPlanilhaDialog extends StatefulWidget {
  final User user;
  final int currentYear;
  final String userLaboratorio;

  const ImportPlanilhaDialog({
    super.key,
    required this.user,
    required this.currentYear,
    required this.userLaboratorio,
  });

  @override
  State<ImportPlanilhaDialog> createState() => _ImportPlanilhaDialogState();
}

class _ImportPlanilhaDialogState extends State<ImportPlanilhaDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _fileName;
  List<int>? _fileBytes;
  late String _selectedLab;
  late int _selectedYear;

  final List<String> _laboratorios = [
    'Química de Águas',
    'Inorgânica',
    'Microbiologia',
    'Solos',
    'Bromatologia',
    'Orgânica',
    'Qualidade',
    'Geconf',
    'GEAAD / Insumos Gerais',
    'Diretoria',
    'Geral'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.currentYear;
    _selectedLab = widget.user.isAdmin ? 'Geral' : widget.userLaboratorio;
    if (!widget.user.isAdmin && !_laboratorios.contains(_selectedLab)) {
      _laboratorios.add(_selectedLab);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _importar() async {
    if (_fileBytes == null || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione um arquivo Excel primeiro.', style: GoogleFonts.inter())),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await _apiService.importItems(
      _selectedYear,
      _selectedLab,
      _fileBytes!,
      _fileName!,
    );

    setState(() => _isLoading = false);

    if (response != null) {
      if (response['success'] == true) {
        Navigator.pop(context, true); // true = recarregar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'], style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erro desconhecido', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão com o servidor.', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF131A2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.upload_file_rounded, color: Color(0xFF3B82F6), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importar Planilha',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  'O Agente Antiduplicidade protegerá contra itens repetidos.',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Setor de Destino', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F19),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLab,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  style: GoogleFonts.inter(color: Colors.white),
                  items: _laboratorios.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: widget.user.isAdmin
                      ? (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedLab = newValue);
                          }
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Arquivo (.xlsx)', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isLoading ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _fileBytes == null ? const Color(0xFF0B0F19) : const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _fileBytes == null ? Colors.white.withOpacity(0.06) : const Color(0xFF22C55E).withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _fileBytes == null ? Icons.folder_open_rounded : Icons.check_circle_rounded,
                      color: _fileBytes == null ? const Color(0xFF64748B) : const Color(0xFF22C55E),
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fileBytes == null ? 'Clique para selecionar a planilha' : _fileName!,
                      style: GoogleFonts.inter(
                        color: _fileBytes == null ? const Color(0xFF94A3B8) : const Color(0xFF22C55E),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A primeira linha deve conter os nomes das colunas: Categoria, Tipo, Código, Item, Unidade, Quantidade, Valor Unitário.',
                      style: GoogleFonts.inter(color: const Color(0xFFFCD34D), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _importar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Importar Dados', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
