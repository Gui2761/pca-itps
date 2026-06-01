import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  final TextEditingController _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _laboratorios = [];
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _tiposRecurso = [];
  
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
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {}); // Força atualização reativa do painel esquerdo dinâmico!
    if (_tabController.indexIsChanging) {
      _inputController.clear();
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final labs = await _apiService.fetchLaboratoriosRaw();
    final cats = await _apiService.fetchCategoriasRaw();
    final recursos = await _apiService.fetchTiposRecursoRaw();
    
    // Buscar configuração global de prazos
    final config = await _apiService.fetchGlobalConfig();
    DateTime? deadline;
    if (config['liberacao_fim'] != null) {
      deadline = DateTime.tryParse(config['liberacao_fim']);
    }

    setState(() {
      _laboratorios = labs;
      _categorias = cats;
      _tiposRecurso = recursos;
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

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final String nome = _inputController.text.trim();
    bool success = false;

    if (_tabController.index == 0) {
      success = await _apiService.createLaboratorio(nome);
    } else if (_tabController.index == 1) {
      success = await _apiService.createCategoria(nome);
    } else if (_tabController.index == 2) {
      success = await _apiService.createTipoRecurso(nome);
    }

    if (success) {
      _inputController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parâmetro inserido com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      _loadAllData();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar parâmetro. Verifique duplicados.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(int id, String nome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A2C),
        title: Text('Confirmar Exclusão', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja excluir "$nome"? Se houver itens associados a este parâmetro, erros de integridade podem ocorrer.', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
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
      bool success = false;

      if (_tabController.index == 0) {
        success = await _apiService.deleteLaboratorio(id);
      } else if (_tabController.index == 1) {
        success = await _apiService.deleteCategoria(id);
      } else if (_tabController.index == 2) {
        success = await _apiService.deleteTipoRecurso(id);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Parâmetro removido com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        _loadAllData();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir o parâmetro.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
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
            'Configurações de Parâmetros',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Cadastre parâmetros dinâmicos ou estabeleça datas limites para as edições centrais do PCA',
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Tab Bar de Configurações
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131A2C).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF3B82F6),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Painel Esquerdo Dinâmico
                Expanded(
                  flex: 2,
                  child: _tabController.index == 3
                      ? _buildDeadlineInstructionsCard()
                      : _buildParameterFormCard(),
                ),
                const SizedBox(width: 32),

                // Lista de Registros Ativos Dinâmicos / Painel de Prazo
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2C).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tabController.index == 3 ? 'Gerenciador de Prazo Global' : 'Registros Mapeados no Banco',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 24),

                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                              : TabBarView(
                                  controller: _tabController,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildParameterList(_laboratorios),
                                    _buildParameterList(_categorias),
                                    _buildParameterList(_tiposRecurso),
                                    _buildDeadlineConfigPanel(),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2C).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inserir Novo Registro',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Digite o nome do parâmetro para cadastrá-lo nas opções de seleção dinâmicas do formulário do PCA.',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _inputController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              validator: (val) => val == null || val.trim().isEmpty ? 'Digite um nome válido' : null,
              decoration: InputDecoration(
                hintText: 'Exemplo: Química de Alimentos, Manutenção...',
                labelText: 'Nome do Parâmetro',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                fillColor: const Color(0xFF0B0F19).withOpacity(0.5),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addItem,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Cadastrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2C).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prazo de Edição do PCA',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 24),
          Text(
            'Como administrador, você pode programar uma data e hora limite para liberar o PCA para todos os setores.',
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13, height: 1.5),
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
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF60A5FA), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selecione uma data e hora no painel à direita e salve para aplicar a liberação temporária.',
                    style: GoogleFonts.inter(color: const Color(0xFF93C5FD), fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(child: Text('Nenhum parâmetro mapeado nesta categoria.', style: GoogleFonts.inter(color: const Color(0xFF64748B))));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05)),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id'] as int;
        final nome = item['nome'] as String;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$id',
              style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          title: Text(
            nome,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
            onPressed: () => _deleteItem(id, nome),
          ),
        );
      },
    );
  }

  Widget _buildDeadlineConfigPanel() {
    String formattedDeadline = "Não configurado (Bloqueado por padrão)";
    if (_globalDeadline != null) {
      formattedDeadline = "${_globalDeadline!.day.toString().padLeft(2, '0')}/${_globalDeadline!.month.toString().padLeft(2, '0')}/${_globalDeadline!.year} às ${_globalDeadline!.hour.toString().padLeft(2, '0')}:${_globalDeadline!.minute.toString().padLeft(2, '0')}";
    }

    final statusColor = _isGloballyReleased ? const Color(0xFF10B981) : const Color(0xFFEF4444);
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
              color: statusColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
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
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prazo Atual: $formattedDeadline',
                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
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
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),

          // Seletor de Data
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF60A5FA), size: 20),
            ),
            title: Text(
              'Data Limite',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              _selectedDate == null ? 'Escolha a data' : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
            ),
            trailing: ElevatedButton(
              onPressed: _pickDate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Selecionar Data'),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 32),

          // Seletor de Hora
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.access_time_rounded, color: Color(0xFF60A5FA), size: 20),
            ),
            title: Text(
              'Hora Limite',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              _selectedTime == null ? 'Escolha a hora' : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
            ),
            trailing: ElevatedButton(
              onPressed: _pickTime,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Selecionar Hora'),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 32),
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
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF131A2C),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0B0F19),
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF131A2C),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0B0F19),
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
          backgroundColor: const Color(0xFFEF4444),
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
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _loadAllData();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar prazo no servidor.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFEF4444),
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
        backgroundColor: const Color(0xFF131A2C),
        title: Text('Bloquear Edição Imediatamente?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Isto irá encerrar imediatamente o período de alterações do PCA para todos os setores comuns. Deseja prosseguir?', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Bloquear Agora', style: GoogleFonts.inter(color: Colors.white)),
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
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadAllData();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao efetuar bloqueio imediato.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
