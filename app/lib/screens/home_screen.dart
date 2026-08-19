import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/item_pca.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../services/export_service.dart';

import 'item_form_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'user_management_screen.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';
import 'import_dialog.dart';

import '../widgets/app_sidebar.dart';
import '../widgets/deadline_banner.dart';
import '../widgets/items_data_table.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  List<ItemPCA> _itens = [];
  Map<String, dynamic> _estatisticas = {};
  String? _selectedPasta;
  String? _selectedLaboratorio;
  String? _selectedCategoria;
  bool _isLoading = false;
  String _currentView = 'list';
  int _selectedYear = 2027;
  DateTime? _globalDeadline;
  bool _isGloballyReleased = false;
  Timer? _countdownTimer;
  String _countdownText = '';

  List<String> _laboratorios = ['Química de Água', 'Inorgânica', 'Microbiologia', 'Solos', 'Bromatologia', 'Orgânica', 'Qualidade', 'Geconf', 'GEAAD / Insumos Gerais'];
  List<String> _categorias = ['Material de Consumo', 'Equipamento', 'Serviço'];

  String _formatBrl(double val) {
    String fixed = val.toStringAsFixed(2);
    List<String> parts = fixed.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];
    final RegExp reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    integerPart = integerPart.replaceAllMapped(reg, (Match match) => '.');
    return 'R\$ $integerPart,$decimalPart';
  }

  Future<void> _loadFilterOptions() async {
    try {
      final labs = await _apiService.fetchLaboratorios();
      final cats = await _apiService.fetchTiposRecurso();
      if (mounted) {
        setState(() {
          if (labs.isNotEmpty) _laboratorios = labs;
          if (cats.isNotEmpty) _categorias = cats;
        });
      }
    } catch (e) {
      print('Erro ao carregar opções dinâmicas dos filtros: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _authService.init();
    _authService.addListener(_onAuthChanged);
    _loadFilterOptions();
    _loadData();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final updateData = await UpdateService.checkForUpdate();
    if (updateData != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
          title: Text('Atualização Disponível', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          content: Text('Uma nova versão do PCA está disponível (${updateData['tag_name']}). Deseja atualizar agora?', style: GoogleFonts.inter(color: const Color(0xFF475569))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Mais Tarde', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (updateData['assets'] != null && updateData['assets'].isNotEmpty) {
                  _downloadUpdate(updateData['assets'][0]['browser_download_url']);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Atualizar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _downloadUpdate(String url) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            Text('Baixando e instalando atualização...\nO aplicativo será reiniciado em instantes.', 
              style: GoogleFonts.inter(color: const Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    await UpdateService.downloadAndInstallUpdate(url);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _authService.removeListener(_onAuthChanged);
    _searchController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
      _loadData();
    }
  }

  String? _getUserLaboratorio(User? user) {
    if (user == null || user.isAdmin) return null;
    final mapping = {
      'agua': 'Química de Água',
      'quimica_aguas': 'Química de Água',
      'inorganica': 'Inorgânica',
      'microbiologia': 'Microbiologia',
      'solos': 'Solos',
      'bromatologia': 'Bromatologia',
      'organica': 'Orgânica',
      'qualidade': 'Qualidade',
      'geconf': 'Geconf',
      'geaad': 'GEAAD / Insumos Gerais',
    };
    if (mapping.containsKey(user.username)) {
      return mapping[user.username];
    }
    for (var lab in _laboratorios) {
      if (lab.toLowerCase() == user.name.toLowerCase() || lab.toLowerCase() == user.username.toLowerCase()) {
        return lab;
      }
    }
    return null;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final currentUser = _authService.currentUser;
    final userLab = _getUserLaboratorio(currentUser);

    final config = await _apiService.fetchGlobalConfig();
    DateTime? deadline;
    if (config['liberacao_fim'] != null) {
      deadline = DateTime.tryParse(config['liberacao_fim']);
    }
    final isGloballyReleased = config['is_globally_released'] ?? false;

    final result = await _apiService.fetchItens(
      busca: _searchController.text,
      pasta: _selectedPasta,
      laboratorio: userLab ?? _selectedLaboratorio,
      categoriaItem: _selectedCategoria,
      ano: _selectedYear,
    );
    if (mounted) {
      setState(() {
        _globalDeadline = deadline;
        _isGloballyReleased = isGloballyReleased;
        _itens = List<ItemPCA>.from(result['itens'] ?? []);
        _estatisticas = Map<String, dynamic>.from(result['estatisticas'] ?? {});
        _isLoading = false;
      });
      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (_globalDeadline == null) {
      setState(() {
        _countdownText = '';
      });
      return;
    }
    final now = DateTime.now();
    final difference = _globalDeadline!.difference(now);
    if (difference.isNegative) {
      setState(() {
        _countdownText = 'Prazo encerrado!';
        _isGloballyReleased = false;
      });
      _countdownTimer?.cancel();
      return;
    }
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days ${days == 1 ? "dia" : "dias"}');
    if (hours > 0) parts.add('$hours ${hours == 1 ? "hora" : "horas"}');
    if (minutes > 0) parts.add('$minutes ${minutes == 1 ? "minuto" : "minutos"}');
    parts.add('$seconds ${seconds == 1 ? "segundo" : "segundos"}');
    setState(() {
      _countdownText = 'falta ${parts.join(" e ")}';
    });
  }

  Future<void> _copyYearData(int deAno, int paraAno) async {
    final TextEditingController confirmController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isMatch = confirmController.text.trim().toUpperCase() == 'COPIAR';
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
            title: Text('Segurança: Confirmar Importação', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deseja copiar todos os itens cadastrados no ano de $deAno para o ano de $paraAno?\n\n'
                  'ATENÇÃO: Se já existirem itens cadastrados em $paraAno, eles serão excluídos e substituídos por esta nova cópia.',
                  style: GoogleFonts.inter(color: const Color(0xFF475569)),
                ),
                const SizedBox(height: 20),
                Text('Para autorizar a ação, digite a palavra COPIAR no campo abaixo:', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  style: GoogleFonts.inter(color: const Color(0xFF0F172A)),
                  onChanged: (val) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: 'COPIAR',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF64748B)))),
              ElevatedButton(
                onPressed: isMatch ? () => Navigator.pop(context, true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirmar Cópia'),
              ),
            ],
          );
        }
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _apiService.copiarAno(deAno, paraAno);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'], style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          setState(() => _selectedYear = paraAno);
          _loadData();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha ao copiar dados: ${result['message']}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteItem(ItemPCA item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
        title: Text('Confirmar Exclusão', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja excluir o item "${item.item}"?', style: GoogleFonts.inter(color: const Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Excluir', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _apiService.deleteItem(item.id!);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item excluído com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        _loadData();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir o item do banco de dados.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final path = await ExportService.exportCSV(_itens, _selectedYear);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Planilha exportada com sucesso em: $path', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar planilha: $e', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final path = await ExportService.exportTXT(_itens, _estatisticas, _selectedYear);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Relatório exportado com sucesso em: $path', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar relatório: $e', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _confirmFinalizePlanning(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 24),
            const SizedBox(width: 12),
            Text('Finalizar Planejamento?', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Text(
          'Atenção: Ao finalizar, todas as suas alterações do PCA serão salvas e o seu acesso de edição será bloqueado. '
          'Você não poderá criar, alterar ou excluir mais nenhum item, a menos que solicite a reabertura do acesso ao Administrador.\n\n'
          'Deseja concluir o seu planejamento agora?',
          style: GoogleFonts.inter(color: const Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Voltar', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Sim, Finalizar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && user.id != null) {
      setState(() => _isLoading = true);
      final success = await _apiService.lockUserPlanning(user.id!);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Planejamento finalizado e bloqueado com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        _authService.logout();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao finalizar planejamento.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Widget _buildHeader(User user) {
    final isGuest = user.isViewer;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gerenciamento do PCA', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Controle completo de compras, insumos e planejamentos para o ano de 2027', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14)),
          ],
        ),
        Row(
          children: [
            if (!user.isAdmin && !user.editLocked && user.role != UserRole.viewer && (_isGloballyReleased || user.individualRelease)) ...[
              ElevatedButton.icon(
                onPressed: () => _confirmFinalizePlanning(user),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF059669)),
                label: const Text('Finalizar Planejamento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFECFDF5),
                  foregroundColor: const Color(0xFF065F46),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 16),
            ] else if (!user.isAdmin && user.editLocked) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFFB45309), size: 18),
                    const SizedBox(width: 8),
                    Text('Planejamento Concluído (Edição Bloqueada)', style: GoogleFonts.inter(color: const Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (!isGuest)
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final reload = await showDialog<bool>(
                        context: context,
                        builder: (context) => ImportPlanilhaDialog(user: user, currentYear: _selectedYear, userLaboratorio: _getUserLaboratorio(user) ?? 'Geral'),
                      );
                      if (reload == true) _loadData();
                    },
                    icon: const Icon(Icons.upload_file_rounded, size: 20),
                    label: const Text('Importar Planilha'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final reload = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (context) => ItemFormScreen(forcedLaboratorio: _getUserLaboratorio(user))),
                      );
                      if (reload == true) _loadData();
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Novo Item PCA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(double valorTotal, int totalItens) {
    final valorBrl = _formatBrl(valorTotal);
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Valor Total Planejado',
            value: valorBrl,
            icon: Icons.monetization_on_rounded,
            accentColor: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatCard(
            label: 'Quantidade de Itens',
            value: totalItens.toString(),
            icon: Icons.shopping_bag_rounded,
            accentColor: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection(bool isGuest) {
    final user = _authService.currentUser;
    if (user == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => _loadData(),
                  style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Buscar itens por descrição, código ou grupo...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                  ),
                ),
              ),
              if (user.isAdmin) ...[
                const SizedBox(width: 16),
                _buildDropdownFilter(
                  hint: 'Laboratório',
                  value: _selectedLaboratorio,
                  items: _laboratorios,
                  onChanged: (val) {
                    setState(() => _selectedLaboratorio = val);
                    _loadData();
                  },
                ),
              ],
              const SizedBox(width: 16),
              _buildDropdownFilter(
                hint: 'Categoria',
                value: _selectedCategoria,
                items: _categorias,
                onChanged: (val) {
                  setState(() => _selectedCategoria = val);
                  _loadData();
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Exportar Excel (CSV)',
                onPressed: _exportToExcel,
                icon: const Icon(Icons.table_view_rounded, color: Color(0xFF059669)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFECFDF5),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Exportar Relatório Texto',
                onPressed: _exportToPDF,
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ItemsDataTable(
              itens: _itens,
              isGuest: isGuest,
              isLoading: _isLoading,
              verticalScrollController: _verticalScrollController,
              horizontalScrollController: _horizontalScrollController,
              onEdit: (item) async {
                final reload = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => ItemFormScreen(item: item, forcedLaboratorio: _getUserLaboratorio(user))),
                );
                if (reload == true) _loadData();
              },
              onDelete: _deleteItem,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      width: 225,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13)),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 13),
          items: [
            DropdownMenuItem<String>(value: null, child: Text('Todos: $hint')),
            ...items.map<DropdownMenuItem<String>>((String val) {
              return DropdownMenuItem<String>(value: val, child: Text(val));
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authService.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    if (!_authService.isAuthenticated) {
      return LoginScreen(
        authService: _authService,
        onLoginSuccess: () => _loadData(),
      );
    }

    final user = _authService.currentUser!;
    if (!user.isAdmin && user.role != UserRole.viewer && _currentView == 'dashboard') {
      _currentView = 'list';
    }
    final isGuest = user.isViewer || (!user.isAdmin && !_isGloballyReleased && !user.individualRelease);

    final valorTotal = _estatisticas['valor_total'] ?? 0.0;
    final totalItens = _estatisticas['total_itens'] ?? 0;

    Widget mainContent;
    switch (_currentView) {
      case 'dashboard':
        mainContent = DashboardScreen(ano: _selectedYear);
        break;
      case 'users':
        mainContent = const UserManagementScreen();
        break;
      case 'settings':
        mainContent = const SettingsScreen();
        break;
      case 'logs':
        mainContent = const LogsScreen();
        break;
      case 'list':
      default:
        mainContent = Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user),
              if (!user.isAdmin) ...[
                const SizedBox(height: 24),
                DeadlineBanner(
                  isGloballyReleased: _isGloballyReleased,
                  globalDeadline: _globalDeadline,
                  countdownText: _countdownText,
                ),
              ],
              const SizedBox(height: 32),
              _buildStatsSection(valorTotal, totalItens),
              const SizedBox(height: 32),
              Expanded(
                child: _buildTableSection(isGuest),
              ),
            ],
          ),
        );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          AppSidebar(
            user: user,
            authService: _authService,
            selectedYear: _selectedYear,
            currentView: _currentView,
            selectedPasta: _selectedPasta,
            onYearChanged: (val) {
              setState(() => _selectedYear = val);
              _loadData();
            },
            onCopyYear: _copyYearData,
            onViewChanged: (view) {
              setState(() => _currentView = view);
              if (view == 'list') {
                _loadData();
                _loadFilterOptions();
              }
            },
            onPastaChanged: (pasta) {
              setState(() => _selectedPasta = pasta);
              _loadData();
            },
          ),
          Expanded(
            child: mainContent,
          ),
        ],
      ),
    );
  }
}
