import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _apiService.fetchLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Limpar Todos os Logs?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Esta ação é irreversível. Todos os registros de auditoria serão apagados permanentemente.',
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Limpar Tudo', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.clearLogs();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logs limpos com sucesso!', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        _fetchLogs();
      }
    }
  }

  IconData _getActionIcon(String acao) {
    final a = acao.toLowerCase();
    if (a.contains('criou') || a.contains('criar')) return Icons.add_circle_rounded;
    if (a.contains('editou') || a.contains('editar') || a.contains('alterou')) return Icons.edit_rounded;
    if (a.contains('excluiu') || a.contains('deletou') || a.contains('deletar')) return Icons.delete_rounded;
    if (a.contains('login') || a.contains('acesso')) return Icons.login_rounded;
    if (a.contains('configuração') || a.contains('config')) return Icons.settings_rounded;
    if (a.contains('finalizou') || a.contains('bloqueou')) return Icons.lock_rounded;
    if (a.contains('copiou') || a.contains('copiar')) return Icons.content_copy_rounded;
    if (a.contains('limpou') || a.contains('limpar')) return Icons.cleaning_services_rounded;
    return Icons.info_rounded;
  }

  Color _getActionColor(String acao) {
    final a = acao.toLowerCase();
    if (a.contains('criou') || a.contains('criar')) return const Color(0xFF22C55E);
    if (a.contains('editou') || a.contains('editar') || a.contains('alterou')) return const Color(0xFF3B82F6);
    if (a.contains('excluiu') || a.contains('deletou')) return const Color(0xFFEF4444);
    if (a.contains('login')) return const Color(0xFF8B5CF6);
    if (a.contains('configuração') || a.contains('config')) return const Color(0xFFF59E0B);
    if (a.contains('finalizou') || a.contains('bloqueou')) return const Color(0xFFEC4899);
    if (a.contains('copiou')) return const Color(0xFF06B6D4);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logs de Auditoria',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registro de todas as ações realizadas no sistema PCA',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131A2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _isLoading ? null : _fetchLogs,
                      icon: const Icon(Icons.refresh_rounded),
                      color: const Color(0xFF3B82F6),
                      tooltip: 'Atualizar',
                    ),
                    Container(width: 1, height: 24, color: Colors.white.withOpacity(0.06)),
                    IconButton(
                      onPressed: _isLoading || _logs.isEmpty ? null : _clearLogs,
                      icon: const Icon(Icons.delete_sweep_rounded),
                      color: const Color(0xFFEF4444),
                      tooltip: 'Limpar Todos os Logs',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131A2C).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_rounded, color: const Color(0xFF64748B), size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_logs.length} registro${_logs.length != 1 ? "s" : ""} encontrado${_logs.length != 1 ? "s" : ""}',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
              : _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, color: const Color(0xFF1E293B), size: 80),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum log registrado',
                          style: GoogleFonts.outfit(color: const Color(0xFF475569), fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'As ações realizadas no sistema aparecerão aqui',
                          style: GoogleFonts.inter(color: const Color(0xFF334155), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.separated(
                        itemCount: _logs.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.04),
                        ),
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final acao = log['acao'] ?? '';
                          final usuario = log['usuario'] ?? 'Desconhecido';
                          final detalhes = log['detalhes'] ?? '';
                          final dataHora = log['data_hora'] ?? '';
                          final color = _getActionColor(acao);
                          final icon = _getActionIcon(acao);

                          return Container(
                            color: index % 2 == 0
                                ? Colors.transparent
                                : Colors.white.withOpacity(0.01),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: color, size: 18),
                                ),
                                const SizedBox(width: 14),
                                // Action + User
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acao,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.person_rounded, color: const Color(0xFF475569), size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            usuario,
                                            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Details
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    detalhes,
                                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Date/Time
                                SizedBox(
                                  width: 140,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(Icons.schedule_rounded, color: const Color(0xFF475569), size: 13),
                                      const SizedBox(width: 6),
                                      Text(
                                        dataHora.toString().length >= 16
                                            ? dataHora.toString().substring(0, 16).replaceAll('T', ' ')
                                            : dataHora.toString(),
                                        style: GoogleFonts.jetBrainsMono(
                                          color: const Color(0xFF64748B),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
