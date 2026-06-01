// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item_pca.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'item_form_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'user_management_screen.dart';
import 'settings_screen.dart';

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
  String _currentView = 'list'; // 'dashboard', 'list', 'users', 'settings'
  int _selectedYear = 2026;
  DateTime? _globalDeadline;
  bool _isGloballyReleased = false;
  Timer? _countdownTimer;
  String _countdownText = '';

  List<String> _laboratorios = [
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

  List<String> _categorias = [
    'Material de Consumo',
    'Equipamento',
    'Serviço'
  ];

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
      'quimica_aguas': 'Química de Águas',
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

    // Buscar configuração global de prazo
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
    setState(() {
      _globalDeadline = deadline;
      _isGloballyReleased = isGloballyReleased;
      _itens = List<ItemPCA>.from(result['itens'] ?? []);
      _estatisticas = Map<String, dynamic>.from(result['estatisticas'] ?? {});
      _isLoading = false;
    });
    _startCountdownTimer();
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
    if (days > 0) {
      parts.add('$days ${days == 1 ? "dia" : "dias"}');
    }
    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? "hora" : "horas"}');
    }
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? "minuto" : "minutos"}');
    }
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
            backgroundColor: const Color(0xFF131A2C),
            title: Text('Segurança: Confirmar Importação', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deseja copiar todos os itens cadastrados no ano de $deAno para o ano de $paraAno?\n\n'
                  'ATENÇÃO: Se já existirem itens cadastrados em $paraAno, eles serão excluídos e substituídos por esta nova cópia.',
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Para autorizar a ação, digite a palavra COPIAR no campo abaixo:',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  style: GoogleFonts.inter(color: Colors.white),
                  onChanged: (val) {
                    setDialogState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'COPIAR',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    fillColor: const Color(0xFF0B0F19),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: isMatch ? () => Navigator.pop(context, true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  disabledBackgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white24,
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
      try {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/api/pca/copiar-ano'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'de_ano': deAno, 'para_ano': paraAno}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Dados copiados com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          setState(() {
            _selectedYear = paraAno;
          });
          _loadData();
        } else {
          final err = jsonDecode(response.body);
          throw Exception(err['detail'] ?? 'Erro desconhecido');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha ao copiar dados: $e', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
        backgroundColor: const Color(0xFF131A2C),
        title: Text('Confirmar Exclusão', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja excluir o item "${item.item}"?', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Excluir', style: GoogleFonts.inter(color: Colors.white)),
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

  // EXPORTAR PARA EXCEL (CSV) — versão Web (download via navegador)
  Future<void> _exportToExcel() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('ID;Categoria;Planilha;Laboratório;Setor;Recurso;Código;Descrição;Unidade;Quantidade;Valor Unitário;Valor Total');
      
      for (var item in _itens) {
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

      final fileName = 'pca_export_$_selectedYear.csv';
      final blob = html.Blob([buffer.toString()], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Planilha $fileName baixada com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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

  // EXPORTAR RELATÓRIO PDF (TXT/Formatado) — versão Web
  Future<void> _exportToPDF() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('========================================================================');
      buffer.writeln('                   ITPS - PLANO DE CONTRATAÇÕES ANUAL (PCA) $_selectedYear        ');
      buffer.writeln('                           RELATÓRIO CONSOLIDADO                        ');
      buffer.writeln('========================================================================\n');
      buffer.writeln('Gerado em: ${datetimeToBrl(datetimeNow())}\n');
      
      final valorTotal = _estatisticas['valor_total'] ?? 0.0;
      final totalItens = _estatisticas['total_itens'] ?? 0;
      buffer.writeln('Métricas Consolidadas:');
      buffer.writeln('  - Quantidade de Itens: $totalItens');
      buffer.writeln('  - Valor Total Planejado: R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}\n');
      buffer.writeln('------------------------------------------------------------------------');
      buffer.writeln('ID | Laboratório | Setor | Recurso | Descrição | Qtd. | Val. Unit. | Total');
      buffer.writeln('------------------------------------------------------------------------');
      
      for (var item in _itens) {
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

      final fileName = 'relatorio_pca_$_selectedYear.txt';
      final blob = html.Blob([buffer.toString()], 'text/plain;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Relatório $fileName baixado com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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

  String datetimeToBrl(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  DateTime datetimeNow() => DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Tela de carregamento enquanto SharedPreferences é inicializado
    if (!_authService.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F19),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    // Tela de login se não estiver autenticado
    if (!_authService.isAuthenticated) {
      return LoginScreen(
        authService: _authService,
        onLoginSuccess: () {
          _loadData();
        },
      );
    }

    final user = _authService.currentUser!;
    if (!user.isAdmin && _currentView == 'dashboard') {
      _currentView = 'list';
    }
    final isGuest = user.isViewer || (!user.isAdmin && !_isGloballyReleased);

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
      case 'list':
      default:
        mainContent = Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(user),
              if (!user.isAdmin) ...[
                const SizedBox(height: 24),
                _buildLockBanner(),
              ],
              const SizedBox(height: 32),
              
              // Dashboard Stats Cards
              _buildStatsSection(valorTotal, totalItens),
              const SizedBox(height: 32),
              
              // Filtros & Tabela
              Expanded(
                child: _buildTableSection(isGuest),
              ),
            ],
          ),
        );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(user),
          
          // Área de Conteúdo Principal
          Expanded(
            child: mainContent,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(User user) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF131A2C),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Brand Logo
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'P',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          dropdownColor: const Color(0xFF131A2C),
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                          items: [2026, 2027, 2028, 2029, 2030].map((int yr) {
                            return DropdownMenuItem<int>(
                              value: yr,
                              child: Text('PCA $yr'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedYear = val;
                              });
                              _loadData();
                            }
                          },
                        ),
                      ),
                      if (user.isAdmin && _selectedYear < 2030) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.content_copy_rounded, color: Color(0xFF3B82F6), size: 18),
                          tooltip: 'Copiar dados de $_selectedYear para ${_selectedYear + 1}',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _copyYearData(_selectedYear, _selectedYear + 1),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Planejamento ITPS',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // User Profile Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F19).withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3B82F6).withOpacity(0.15),
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.roleName,
                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                  onPressed: () => _authService.logout(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'MENU PRINCIPAL',
            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          
          if (user.isAdmin)
            _buildSidebarButton(
              label: 'Dashboard BI',
              isSelected: _currentView == 'dashboard',
              icon: Icons.analytics_rounded,
              onPressed: () {
                setState(() => _currentView = 'dashboard');
              },
            ),
          _buildSidebarButton(
            label: 'Itens do PCA',
            isSelected: _currentView == 'list',
            icon: Icons.list_alt_rounded,
            onPressed: () {
              setState(() => _currentView = 'list');
              _loadData();
              _loadFilterOptions();
            },
          ),
          if (user.isAdmin)
            _buildSidebarButton(
              label: 'Contas de Acesso',
              isSelected: _currentView == 'users',
              icon: Icons.manage_accounts_rounded,
              onPressed: () {
                setState(() => _currentView = 'users');
              },
            ),
          if (user.isAdmin)
            _buildSidebarButton(
              label: 'Parâmetros',
              isSelected: _currentView == 'settings',
              icon: Icons.settings_rounded,
              onPressed: () {
                setState(() => _currentView = 'settings');
              },
            ),
          
          if (user.isAdmin && _currentView == 'list') ...[
            const SizedBox(height: 24),
            Text(
              'FILTRAR POR PLANILHA',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            _buildSidebarButton(
              label: 'Todos os Itens',
              isSelected: _selectedPasta == null,
              icon: Icons.grid_view_rounded,
              onPressed: () {
                setState(() => _selectedPasta = null);
                _loadData();
              },
            ),
            _buildSidebarButton(
              label: 'Laboratórios',
              isSelected: _selectedPasta == 'Laboratórios',
              icon: Icons.biotech_rounded,
              onPressed: () {
                setState(() => _selectedPasta = 'Laboratórios');
                _loadData();
              },
            ),
            _buildSidebarButton(
              label: 'GEAAD',
              isSelected: _selectedPasta == 'GEAAD',
              icon: Icons.category_rounded,
              onPressed: () {
                setState(() => _selectedPasta = 'GEAAD');
                _loadData();
              },
            ),
          ],
          
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F19).withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Banco Central',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'Conectado ao PostgreSQL do ITPS no IP 172.23.6.109',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSidebarButton({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8), size: 20),
        label: Text(label, style: GoogleFonts.inter(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          backgroundColor: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _confirmFinalizePlanning(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 24),
            const SizedBox(width: 12),
            Text(
              'Finalizar Planejamento?',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Text(
          'Atenção: Ao finalizar, todas as suas alterações do PCA serão salvas e o seu acesso de edição será bloqueado. '
          'Você não poderá criar, alterar ou excluir mais nenhum item, a menos que solicite a reabertura do acesso ao Administrador.\n\n'
          'Deseja concluir o seu planejamento agora?',
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Voltar', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
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
            Text(
              'Gerenciamento do PCA',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Controle completo de compras, insumos e planejamentos para o ano de 2027',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            if (!user.isAdmin && !user.editLocked) ...[
              ElevatedButton.icon(
                onPressed: () => _confirmFinalizePlanning(user),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF10B981)),
                label: const Text('Finalizar Planejamento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.12),
                  foregroundColor: const Color(0xFF6EE7B7),
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
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFFFCD34D), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Planejamento Concluído (Edição Bloqueada)',
                      style: GoogleFonts.inter(color: const Color(0xFFFCD34D), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (!isGuest)
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
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLockBanner() {
    if (_isGloballyReleased) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_outlined, color: Color(0xFF60A5FA), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Período de Edição Liberado Temporariamente',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Tempo restante para alterações: ',
                        style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 12),
                      ),
                      Text(
                        _countdownText.isNotEmpty ? _countdownText : 'Calculando...',
                        style: GoogleFonts.inter(color: const Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    String deadlineStr = "";
    if (_globalDeadline != null) {
      deadlineStr = " em ${datetimeToBrl(_globalDeadline!)}";
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFF87171), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Período de Edição do PCA Bloqueado',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'O prazo limite de alterações estabelecido pela administração expirou$deadlineStr. '
                  'Caso necessite de liberação especial, solicite ao administrador.',
                  style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
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
            accentColor: const Color(0xFF3B82F6),
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
        color: const Color(0xFF131A2C).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
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
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28),
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
        color: const Color(0xFF131A2C).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Barra de Filtro de Busca & Exports
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => _loadData(),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Buscar itens por descrição, código ou grupo...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    fillColor: const Color(0xFF0B0F19).withOpacity(0.5),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    ),
                  ),
                ),
              ),
               if (user.isAdmin) ...[
                _buildDropdownFilter(
                  hint: 'Laboratório',
                  value: _selectedLaboratorio,
                  items: _laboratorios,
                  onChanged: (val) {
                    setState(() => _selectedLaboratorio = val);
                    _loadData();
                  },
                ),
                const SizedBox(width: 16),
              ],
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
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0B0F19),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 16),
              // Botão Exportar Excel
              IconButton(
                tooltip: 'Exportar Excel (CSV)',
                onPressed: _exportToExcel,
                icon: const Icon(Icons.table_view_rounded, color: Color(0xFF10B981)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0B0F19),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 16),
              // Botão Exportar Relatório
              IconButton(
                tooltip: 'Exportar Relatório Texto',
                onPressed: _exportToPDF,
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0B0F19),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Tabela
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                : _itens.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum item cadastrado.',
                          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 16),
                        ),
                      )
                    : LayoutBuilder(
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
                              controller: _verticalScrollController,
                              thumbVisibility: true,
                              child: Scrollbar(
                                controller: _horizontalScrollController,
                                thumbVisibility: true,
                                notificationPredicate: (notif) => notif.depth == 1,
                                child: SingleChildScrollView(
                                  controller: _verticalScrollController,
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    controller: _horizontalScrollController,
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      horizontalMargin: 8,
                                      columnSpacing: 10,
                                      dataRowMinHeight: 44,
                                      dataRowMaxHeight: 64,
                                      headingRowColor: WidgetStateProperty.all(const Color(0xFF0B0F19).withOpacity(0.5)),
                                      columns: [
                                        DataColumn(label: Container(width: col1Width, child: Text('Origem / Recurso', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)))),
                                        DataColumn(label: Container(width: col2Width, child: Text('Área / Subgrupo', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)))),
                                        DataColumn(label: Container(width: col3Width, child: Text('Item / Código', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)))),
                                        DataColumn(label: Container(width: col4Width, child: Text('Qtd / Unid', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)))),
                                        DataColumn(numeric: true, label: Container(width: col5Width, alignment: Alignment.centerRight, child: Text('Valor Estimado', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)))),
                                        if (!isGuest)
                                          DataColumn(label: Container(width: col6Width, child: Text('Ações', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)))),
                                      ],
                                      rows: _itens.map((item) {
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
                                                    Text(item.laboratorio, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
                                                    const SizedBox(height: 3),
                                                    Text(item.setor, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
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
                                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
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
                                                    Text(item.quantidade.toString(), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                                    const SizedBox(height: 1),
                                                    Text(item.unidade, style: GoogleFonts.inter(color: Colors.white60, fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 1),
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
                                                    Text(_formatBrl(item.valorTotal), style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
                                                    const SizedBox(height: 1),
                                                    Text('Unit: ${_formatBrl(item.valorUnitario)}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 10)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Ações
                                            if (!isGuest)
                                              DataCell(
                                                Container(
                                                  width: col6Width,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 16),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () async {
                                                          final reload = await Navigator.push<bool>(
                                                            context,
                                                            MaterialPageRoute(builder: (context) => ItemFormScreen(item: item, forcedLaboratorio: _getUserLaboratorio(user))),
                                                          );
                                                          if (reload == true) _loadData();
                                                        },
                                                      ),
                                                      const SizedBox(width: 8),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 16),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () => _deleteItem(item),
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
        color: const Color(0xFF0B0F19).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13)),
          onChanged: onChanged,
          dropdownColor: const Color(0xFF131A2C),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Todos: $hint'),
            ),
            ...items.map<DropdownMenuItem<String>>((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String pasta) {
    Color color;
    Color textColor;
    if (pasta == 'Laboratórios') {
      color = const Color(0xFF3B82F6).withOpacity(0.12);
      textColor = const Color(0xFF93C5FD);
    } else if (pasta == 'GEAAD') {
      color = const Color(0xFF10B981).withOpacity(0.12);
      textColor = const Color(0xFF6EE7B7);
    } else {
      color = const Color(0xFF8B5CF6).withOpacity(0.12);
      textColor = const Color(0xFFC084FC);
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
      color = const Color(0xFFEF4444).withOpacity(0.12);
      textColor = const Color(0xFFFCA5A5);
    } else if (cat == 'Serviço') {
      color = const Color(0xFFF59E0B).withOpacity(0.12);
      textColor = const Color(0xFFFCD34D);
    } else {
      color = const Color(0xFF10B981).withOpacity(0.12);
      textColor = const Color(0xFF6EE7B7);
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
}
