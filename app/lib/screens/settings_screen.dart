import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/lab_management_tab.dart';
import '../widgets/category_management_tab.dart';
import '../widgets/resource_type_tab.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  // Variáveis para prazo de edição global
  DateTime? _globalDeadline;
  bool _isGloballyReleased = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadDeadlineData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {}); // Força atualização reativa
  }

  Future<void> _loadDeadlineData() async {
    setState(() => _isLoading = true);
    
    // Buscar configuração global de prazos
    final config = await _apiService.fetchGlobalConfig();
    DateTime? deadline;
    if (config['liberacao_fim'] != null) {
      deadline = DateTime.tryParse(config['liberacao_fim']);
    }

    if (mounted) {
      setState(() {
        _globalDeadline = deadline;
        _isGloballyReleased = config['is_globally_released'] ?? false;
        if (deadline != null) {
          _selectedDate = deadline;
          _selectedTime = TimeOfDay.fromDateTime(deadline);
        } else {
          _selectedDate = null;
          _selectedTime = null;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Parâmetros e Prazos do Sistema',
            style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Cadastre parâmetros dinâmicos ou estabeleça datas limites para as edições centrais do PCA',
            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Tab Bar de Configurações
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2563EB),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
              tabs: const [
                Tab(text: 'Laboratórios / Setores', icon: Icon(Icons.biotech_rounded, size: 20)),
                Tab(text: 'Categorias (Origem)', icon: Icon(Icons.folder_shared_rounded, size: 20)),
                Tab(text: 'Tipos de Recurso (Categoria)', icon: Icon(Icons.category_rounded, size: 20)),
                Tab(text: 'Prazo Limite PCA', icon: Icon(Icons.lock_clock_rounded, size: 20)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Área de Exibição / Formulário e Listagem
          Expanded(
            child: _tabController.index == 3
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Painel Esquerdo Dinâmico
                      Expanded(
                        flex: 2,
                        child: _buildDeadlineInstructionsCard(),
                      ),
                      const SizedBox(width: 32),

                      // Lista de Registros Ativos Dinâmicos / Painel de Prazo
                      Expanded(
                        flex: 3,
                        child: Container(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gerenciador de Prazo Global',
                                style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 24),
                              Expanded(
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                                    : _buildDeadlineConfigPanel(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      LabManagementTab(),
                      CategoryManagementTab(),
                      ResourceTypeTab(),
                      SizedBox.shrink(), // Renderizado pelo row acima
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineInstructionsCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prazo de Edição do PCA',
            style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 24),
          Text(
            'Como administrador, você pode programar uma data e hora limite para liberar o PCA para todos os setores.',
            style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Text(
            '• Durante o período: Todos os usuários podem adicionar, editar e excluir seus respectivos itens (exceto se finalizarem individualmente).\n\n'
            '• Após o prazo: O sistema bloqueia automaticamente novas edições globalmente, mudando todas as contas para modo apenas visualização.',
            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selecione uma data e hora no painel à direita e salve para aplicar a liberação temporária.',
                    style: GoogleFonts.inter(color: const Color(0xFF1E40AF), fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineConfigPanel() {
    String formattedDeadline = "Não configurado (Bloqueado por padrão)";
    if (_globalDeadline != null) {
      formattedDeadline = "${_globalDeadline!.day.toString().padLeft(2, '0')}/${_globalDeadline!.month.toString().padLeft(2, '0')}/${_globalDeadline!.year} às ${_globalDeadline!.hour.toString().padLeft(2, '0')}:${_globalDeadline!.minute.toString().padLeft(2, '0')}";
    }

    final statusColor = _isGloballyReleased ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final statusBg = _isGloballyReleased ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final statusBorder = _isGloballyReleased ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);
    final statusText = _isGloballyReleased ? "Edição Liberada Globalmente" : "Edição Bloqueada Globalmente";
    final statusIcon = _isGloballyReleased ? Icons.lock_open_rounded : Icons.lock_rounded;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de Status Atual
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prazo Atual: $formattedDeadline',
                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Configurar Prazo de Expiração',
            style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),

          // Seletor de Data
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            title: Text(
              'Data Limite',
              style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              _selectedDate == null ? 'Escolha a data' : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
            ),
            trailing: ElevatedButton(
              onPressed: _pickDate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Selecionar Data'),
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 32),

          // Seletor de Hora
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.access_time_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            title: Text(
              'Hora Limite',
              style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              _selectedTime == null ? 'Escolha a hora' : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
            ),
            trailing: ElevatedButton(
              onPressed: _pickTime,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Selecionar Hora'),
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 32),
          const SizedBox(height: 16),

          // Ações do Formulário
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveDeadline,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Salvar Prazo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearDeadline,
                  icon: const Icon(Icons.lock_rounded, size: 18),
                  label: const Text('Bloquear Já'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveDeadline() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, selecione a data e a hora limite.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final finalDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final success = await _apiService.updateGlobalConfig(finalDateTime.toIso8601String());

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prazo de liberação global salvo com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _loadDeadlineData();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar prazo no servidor.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _clearDeadline() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: Text('Bloquear Edição Imediatamente?', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        content: Text('Isto irá encerrar imediatamente o período de alterações do PCA para todos os setores comuns. Deseja prosseguir?', style: GoogleFonts.inter(color: const Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Bloquear Agora', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final pastDateTime = DateTime.now().subtract(const Duration(hours: 1));
      final success = await _apiService.updateGlobalConfig(pastDateTime.toIso8601String());

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Edição do PCA bloqueada imediatamente!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadDeadlineData();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao efetuar bloqueio imediato.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
