import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final int ano;
  const DashboardScreen({super.key, required this.ano});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  String _formatBrl(double val) {
    String fixed = val.toStringAsFixed(2);
    List<String> parts = fixed.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];
    final RegExp reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    integerPart = integerPart.replaceAllMapped(reg, (Match match) => '.');
    return 'R\$ $integerPart,$decimalPart';
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ano != widget.ano) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final result = await _apiService.fetchItens(ano: widget.ano);
    setState(() {
      _stats = Map<String, dynamic>.from(result['estatisticas'] ?? {});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }

    final totalItens = _stats['total_itens'] ?? 0;
    final valorTotal = _stats['valor_total'] ?? 0.0;
    final List<dynamic> distPasta = _stats['distribuicao_pasta'] ?? [];
    final List<dynamic> distCategoria = _stats['distribuicao_categoria'] ?? [];
    final List<dynamic> distLaboratorio = _stats['distribuicao_laboratorio'] ?? [];

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Analítico',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Consolidado de custos, quantitativos e planejamento estratégico do PCA 2027',
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF131A2C),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Valor Total Planejado',
                  value: _formatBrl(valorTotal),
                  icon: Icons.analytics_rounded,
                  color: const Color(0xFF3B82F6),
                  description: 'Total consolidado em compras',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildKPICard(
                  title: 'Quantidade de Itens',
                  value: '$totalItens',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF10B981),
                  description: 'Itens mapeados nas tabelas',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildKPICard(
                  title: 'Média por Item',
                  value: totalItens > 0
                      ? _formatBrl(valorTotal / totalItens)
                      : 'R\$ 0,00',
                  icon: Icons.price_check_rounded,
                  color: const Color(0xFF8B5CF6),
                  description: 'Custo médio por recurso',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Charts Section
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dist por Categoria (Barras Horizontais)
                Expanded(
                  flex: 5,
                  child: _buildGlassContainer(
                    title: 'Custo por Categoria de Recurso',
                    child: _buildCategoryBars(distCategoria, valorTotal),
                  ),
                ),
                const SizedBox(width: 24),
                // Dist por Pasta & Distribuição por Setor / Laboratório
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildGlassContainer(
                          title: 'Distribuição por Pasta',
                          child: _buildPastaDistribution(distPasta, valorTotal),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        flex: 6,
                        child: _buildGlassContainer(
                          title: 'Soma por Setor / Laboratório',
                          child: _buildLabDistribution(distLaboratorio, valorTotal),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2C).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildCategoryBars(List<dynamic> dist, double valorTotal) {
    if (dist.isEmpty) {
      return Center(child: Text('Nenhum dado de categoria disponível.', style: GoogleFonts.inter(color: const Color(0xFF64748B))));
    }

    // Ordenar decrescente
    final list = List<dynamic>.from(dist)..sort((a, b) => (b['valor'] ?? 0.0).compareTo(a['valor'] ?? 0.0));

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final item = list[index];
        final String categoria = item['categoria_item'] ?? 'Outros';
        final double valor = item['valor'] ?? 0.0;
        final double pct = valorTotal > 0 ? (valor / valorTotal) : 0.0;

        Color barColor;
        if (categoria == 'Equipamento') {
          barColor = const Color(0xFFEF4444);
        } else if (categoria == 'Serviço') {
          barColor = const Color(0xFFF59E0B);
        } else {
          barColor = const Color(0xFF10B981);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categoria,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${_formatBrl(valor)} (${(pct * 100).toStringAsFixed(1)}%)',
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F19),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [barColor, barColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPastaDistribution(List<dynamic> dist, double valorTotal) {
    if (dist.isEmpty) {
      return Center(child: Text('Nenhum dado de pasta disponível.', style: GoogleFonts.inter(color: const Color(0xFF64748B))));
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: dist.map<Widget>((item) {
          final String pasta = item['origem_pasta'] ?? 'Outros';
          final double valor = item['valor'] ?? 0.0;
          final double pct = valorTotal > 0 ? (valor / valorTotal) : 0.0;

          Color badgeColor;
          if (pasta == 'Laboratórios') {
            badgeColor = const Color(0xFF3B82F6);
          } else if (pasta == 'GEAAD') {
            badgeColor = const Color(0xFF10B981);
          } else {
            badgeColor = const Color(0xFF8B5CF6);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F19).withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pasta,
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatBrl(valor),
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLabDistribution(List<dynamic> dist, double valorTotal) {
    if (dist.isEmpty) {
      return Center(child: Text('Nenhum dado por laboratório disponível.', style: GoogleFonts.inter(color: const Color(0xFF64748B))));
    }

    return ListView.builder(
      itemCount: dist.length,
      itemBuilder: (context, index) {
        final item = dist[index];
        final String lab = item['laboratorio'] ?? 'Outros';
        final double valor = item['valor'] ?? 0.0;
        final int count = item['count'] ?? 0;
        final double pct = valorTotal > 0 ? (valor / valorTotal) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0F19).withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  lab.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lab,
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count itens',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatBrl(valor),
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(pct * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
