import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AppSidebar extends StatelessWidget {
  final User user;
  final AuthService authService;
  final int selectedYear;
  final String currentView;
  final String? selectedPasta;
  final ValueChanged<int> onYearChanged;
  final void Function(int, int) onCopyYear;
  final ValueChanged<String> onViewChanged;
  final ValueChanged<String?> onPastaChanged;

  const AppSidebar({
    super.key,
    required this.user,
    required this.authService,
    required this.selectedYear,
    required this.currentView,
    this.selectedPasta,
    required this.onYearChanged,
    required this.onCopyYear,
    required this.onViewChanged,
    required this.onPastaChanged,
  });

  Widget _buildSidebarButton({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B), size: 20),
        label: Text(label, style: GoogleFonts.inter(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          backgroundColor: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
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
                      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
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
                            value: selectedYear,
                            dropdownColor: Colors.white,
                            style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 20),
                            items: [2026, 2027, 2028, 2029, 2030].map((int yr) {
                              return DropdownMenuItem<int>(
                                value: yr,
                                child: Text('PCA $yr'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) onYearChanged(val);
                            },
                          ),
                        ),
                        if (user.isAdmin && selectedYear < 2030) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.content_copy_rounded, color: Color(0xFF2563EB), size: 18),
                            tooltip: 'Copiar dados de $selectedYear para ${selectedYear + 1}',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => onCopyYear(selectedYear, selectedYear + 1),
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
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(color: const Color(0xFF2563EB), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
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
                    onPressed: () => authService.logout(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'MENU PRINCIPAL',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),

            if (user.isAdmin || user.role == UserRole.viewer)
              _buildSidebarButton(
                label: 'Dashboard BI',
                isSelected: currentView == 'dashboard',
                icon: Icons.analytics_rounded,
                onPressed: () => onViewChanged('dashboard'),
              ),
            _buildSidebarButton(
              label: 'Itens do PCA',
              isSelected: currentView == 'list',
              icon: Icons.list_alt_rounded,
              onPressed: () => onViewChanged('list'),
            ),
            if (user.isAdmin)
              _buildSidebarButton(
                label: 'Contas de Acesso',
                isSelected: currentView == 'users',
                icon: Icons.manage_accounts_rounded,
                onPressed: () => onViewChanged('users'),
              ),
            if (user.isAdmin)
              _buildSidebarButton(
                label: 'Parâmetros',
                isSelected: currentView == 'settings',
                icon: Icons.settings_rounded,
                onPressed: () => onViewChanged('settings'),
              ),
            if (user.isAdmin)
              _buildSidebarButton(
                label: 'Logs de Auditoria',
                isSelected: currentView == 'logs',
                icon: Icons.history_rounded,
                onPressed: () => onViewChanged('logs'),
              ),

            if (user.isAdmin && currentView == 'list') ...[
              const SizedBox(height: 24),
              Text(
                'FILTRAR POR PLANILHA',
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),
              _buildSidebarButton(
                label: 'Todos os Itens',
                isSelected: selectedPasta == null,
                icon: Icons.grid_view_rounded,
                onPressed: () => onPastaChanged(null),
              ),
              _buildSidebarButton(
                label: 'Laboratórios',
                isSelected: selectedPasta == 'Laboratórios',
                icon: Icons.biotech_rounded,
                onPressed: () => onPastaChanged('Laboratórios'),
              ),
              _buildSidebarButton(
                label: 'GEAAD',
                isSelected: selectedPasta == 'GEAAD',
                icon: Icons.category_rounded,
                onPressed: () => onPastaChanged('GEAAD'),
              ),
            ],

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Banco Central',
                    style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
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
}
