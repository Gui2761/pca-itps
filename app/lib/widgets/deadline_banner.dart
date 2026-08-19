import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeadlineBanner extends StatelessWidget {
  final bool isGloballyReleased;
  final DateTime? globalDeadline;
  final String countdownText;

  const DeadlineBanner({
    super.key,
    required this.isGloballyReleased,
    this.globalDeadline,
    required this.countdownText,
  });

  String _datetimeToBrl(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (isGloballyReleased) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_outlined, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Período de Edição Liberado Temporariamente',
                    style: GoogleFonts.inter(color: const Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Tempo restante para alterações: ',
                        style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 12),
                      ),
                      Text(
                        countdownText.isNotEmpty ? countdownText : 'Calculando...',
                        style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold),
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
    if (globalDeadline != null) {
      deadlineStr = " em ${_datetimeToBrl(globalDeadline!)}";
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFDC2626), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Período de Edição do PCA Bloqueado',
                  style: GoogleFonts.inter(color: const Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'O prazo limite de alterações estabelecido pela administração expirou$deadlineStr. '
                  'Caso necessite de liberação especial, solicite ao administrador.',
                  style: GoogleFonts.inter(color: const Color(0xFF7F1D1D), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
