import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'viewer';

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isGloballyReleased = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final config = await _apiService.fetchGlobalConfig();
    final isGloballyReleased = config['is_globally_released'] ?? false;
    final list = await _apiService.fetchUsers();
    setState(() {
      _users = list;
      _isGloballyReleased = isGloballyReleased;
      _isLoading = false;
    });
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await _apiService.createUser(
      _usernameController.text,
      _passwordController.text,
      _nameController.text,
      _selectedRole,
    );

    if (success) {
      _usernameController.clear();
      _passwordController.clear();
      _nameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuário criado com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      _loadUsers();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao criar usuário. Tente outro username.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A2C),
        title: Text('Confirmar Exclusão', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja excluir o usuário "${user['name']}"?', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
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
      final success = await _apiService.deleteUser(user['id']);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuário excluído com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        _loadUsers();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir usuário.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final editFormKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user['name']);
    final usernameCtrl = TextEditingController(text: user['username']);
    final passwordCtrl = TextEditingController();
    String selectedRole = user['role'] ?? 'viewer';
    bool editLocked = user['edit_locked'] ?? false;
    bool individualRelease = user['individual_release'] ?? false;

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131A2C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Editar Usuário',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              content: Container(
                width: 450,
                child: Form(
                  key: editFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editando credenciais de @${user['username']}',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: nameCtrl,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          validator: (val) => val == null || val.isEmpty ? 'Informe o nome completo' : null,
                          decoration: _buildInputDecoration('Nome Completo', Icons.person_rounded),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: usernameCtrl,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          validator: (val) => val == null || val.isEmpty ? 'Informe o username' : null,
                          decoration: _buildInputDecoration('Usuário (login)', Icons.alternate_email_rounded),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: true,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          decoration: _buildInputDecoration('Nova Senha (deixe vazio para não alterar)', Icons.lock_rounded),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          dropdownColor: const Color(0xFF131A2C),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          decoration: _buildInputDecoration('Perfil / Nível de Acesso', Icons.security_rounded),
                          items: const [
                            DropdownMenuItem(value: 'viewer', child: Text('Visualizador')),
                            DropdownMenuItem(value: 'editor', child: Text('Editor')),
                            DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                          ],
                          onChanged: (val) => setDialogState(() => selectedRole = val!),
                        ),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          title: Text('Bloquear Edição do Planejamento', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                          subtitle: Text('Quando ativado, o usuário não poderá incluir, alterar ou excluir itens.', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11)),
                          value: editLocked,
                          activeColor: const Color(0xFFEF4444),
                          inactiveTrackColor: const Color(0xFF0B0F19),
                          onChanged: (val) {
                            setDialogState(() {
                              editLocked = val;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: Text('Liberação Individual (Pós-Prazo)', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                          subtitle: Text('Permite que o usuário edite mesmo se o prazo geral estiver expirado.', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11)),
                          value: individualRelease,
                          activeColor: const Color(0xFF10B981),
                          inactiveTrackColor: const Color(0xFF0B0F19),
                          onChanged: (val) {
                            setDialogState(() {
                              individualRelease = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!editFormKey.currentState!.validate()) return;
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Salvar Alterações', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true) {
      setState(() => _isLoading = true);
      final success = await _apiService.updateUser(
        user['id'],
        usernameCtrl.text,
        nameCtrl.text,
        selectedRole,
        editLocked: editLocked,
        individualRelease: individualRelease,
        password: passwordCtrl.text.isNotEmpty ? passwordCtrl.text : null,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuário atualizado com sucesso!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        _loadUsers();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar usuário.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleUserAccess(Map<String, dynamic> user) async {
    setState(() => _isLoading = true);
    final currentLocked = user['edit_locked'] == true;
    final success = await _apiService.updateUser(
      user['id'],
      user['username'],
      user['name'],
      user['role'] ?? 'viewer',
      editLocked: !currentLocked,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLocked ? 'Acesso do usuário liberado!' : 'Acesso do usuário bloqueado!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      _loadUsers();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar permissão de acesso.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _toggleUserIndividualRelease(Map<String, dynamic> user) async {
    setState(() => _isLoading = true);
    final currentReleased = user['individual_release'] == true;
    final success = await _apiService.updateUser(
      user['id'],
      user['username'],
      user['name'],
      user['role'] ?? 'viewer',
      editLocked: user['edit_locked'] == true,
      individualRelease: !currentReleased,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentReleased ? 'Liberação Individual concedida!' : 'Liberação Individual revogada!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      _loadUsers();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar liberação individual.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Gerenciamento de Acesso',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Controle de contas, perfis e permissões dos operadores do PCA',
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Formulário e Tabela
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Formulário de Criação (Elegante Glass Container)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2C).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Criar Novo Usuário',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 24),
                            
                            // Campo Nome
                            TextFormField(
                              controller: _nameController,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                              validator: (val) => val == null || val.isEmpty ? 'Informe o nome completo' : null,
                              decoration: _buildInputDecoration('Nome Completo', Icons.person_rounded),
                            ),
                            const SizedBox(height: 20),
                            
                            // Campo Username
                            TextFormField(
                              controller: _usernameController,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                              validator: (val) => val == null || val.isEmpty ? 'Informe o username' : null,
                              decoration: _buildInputDecoration('Usuário (login)', Icons.alternate_email_rounded),
                            ),
                            const SizedBox(height: 20),
                            
                            // Campo Senha
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                              validator: (val) => val == null || val.isEmpty ? 'Informe a senha' : null,
                              decoration: _buildInputDecoration('Senha', Icons.lock_rounded),
                            ),
                            const SizedBox(height: 20),
                            
                            // Seleção Perfil
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              dropdownColor: const Color(0xFF131A2C),
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                              decoration: _buildInputDecoration('Perfil / Nível de Acesso', Icons.security_rounded),
                              items: const [
                                DropdownMenuItem(value: 'viewer', child: Text('Visualizador')),
                                DropdownMenuItem(value: 'editor', child: Text('Editor')),
                                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                              ],
                              onChanged: (val) => setState(() => _selectedRole = val!),
                            ),
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _createUser,
                                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                                label: const Text('Salvar Usuário'),
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
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                
                // Tabela de Usuários Mapeados
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
                          'Contas Ativas',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                              : _users.isEmpty
                                  ? Center(child: Text('Nenhum usuário mapeado.', style: GoogleFonts.inter(color: const Color(0xFF64748B))))
                                  : ListView.separated(
                                      itemCount: _users.length,
                                      separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05)),
                                      itemBuilder: (context, index) {
                                        final user = _users[index];
                                        final isSystemAdmin = user['username'] == 'admin';

                                        return ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.12),
                                            child: Text(
                                              user['name'].substring(0, 1).toUpperCase(),
                                              style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          title: Text(
                                            user['name'],
                                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Text(
                                                '@${user['username']}',
                                                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                                              ),
                                              const SizedBox(width: 12),
                                              _buildRoleBadge(user['role']),
                                              if (user['role'] != 'admin') ...[
                                                const SizedBox(width: 12),
                                                Builder(
                                                  builder: (context) {
                                                    final isLocked = user['edit_locked'] == true;
                                                    final isReleased = user['individual_release'] == true;
                                                    
                                                    String statusText;
                                                    Color badgeColor;
                                                    IconData badgeIcon;

                                                    if (isLocked) {
                                                      statusText = 'Terminou (Bloqueado)';
                                                      badgeColor = const Color(0xFF10B981);
                                                      badgeIcon = Icons.check_circle_rounded;
                                                    } else if (isReleased) {
                                                      statusText = 'Liberado (Individual)';
                                                      badgeColor = const Color(0xFF8B5CF6);
                                                      badgeIcon = Icons.vpn_key_rounded;
                                                    } else if (!_isGloballyReleased) {
                                                      statusText = 'Bloqueado (Prazo Expirado)';
                                                      badgeColor = const Color(0xFFEF4444);
                                                      badgeIcon = Icons.lock_rounded;
                                                    } else {
                                                      statusText = 'Em Aberto (Liberado)';
                                                      badgeColor = const Color(0xFF3B82F6);
                                                      badgeIcon = Icons.lock_open_rounded;
                                                    }

                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: badgeColor.withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(badgeIcon, color: badgeColor.withOpacity(0.8), size: 10),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            statusText,
                                                            style: GoogleFonts.inter(
                                                              color: badgeColor.withOpacity(0.8),
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                          trailing: isSystemAdmin
                                              ? null
                                              : Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (user['role'] != 'admin') ...[
                                                      IconButton(
                                                        icon: Icon(
                                                          user['edit_locked'] == true
                                                              ? Icons.lock_open_rounded
                                                              : Icons.lock_rounded,
                                                          color: user['edit_locked'] == true
                                                              ? const Color(0xFF10B981)
                                                              : const Color(0xFFF59E0B),
                                                          size: 20,
                                                        ),
                                                        tooltip: user['edit_locked'] == true
                                                            ? 'Liberar Acesso'
                                                            : 'Bloquear Acesso',
                                                        onPressed: () => _toggleUserAccess(user),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          user['individual_release'] == true
                                                              ? Icons.key_off_rounded
                                                              : Icons.key_rounded,
                                                          color: user['individual_release'] == true
                                                              ? const Color(0xFF8B5CF6)
                                                              : const Color(0xFF64748B),
                                                          size: 20,
                                                        ),
                                                        tooltip: user['individual_release'] == true
                                                            ? 'Revogar Liberação Individual'
                                                            : 'Conceder Liberação Individual',
                                                        onPressed: () => _toggleUserIndividualRelease(user),
                                                      ),
                                                    ],
                                                    IconButton(
                                                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 20),
                                                      tooltip: 'Editar Conta',
                                                      onPressed: () => _editUser(user),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                                      tooltip: 'Excluir Conta',
                                                      onPressed: () => _deleteUser(user),
                                                    ),
                                                  ],
                                                ),
                                        );
                                      },
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

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      labelText: hint,
      labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
      hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
      fillColor: const Color(0xFF0B0F19).withOpacity(0.5),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    Color textColor;
    String label;
    if (role == 'admin') {
      color = const Color(0xFFEF4444).withOpacity(0.12);
      textColor = const Color(0xFFFCA5A5);
      label = 'Administrador';
    } else if (role == 'editor') {
      color = const Color(0xFFF59E0B).withOpacity(0.12);
      textColor = const Color(0xFFFCD34D);
      label = 'Editor';
    } else {
      color = const Color(0xFF10B981).withOpacity(0.12);
      textColor = const Color(0xFF6EE7B7);
      label = 'Visualizador';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
