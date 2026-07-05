import 'package:flutter/material.dart';
import '../components/app_drawer.dart';

import 'package:fl_chart/fl_chart.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  DashboardStats? _stats;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final stats = await DashboardService.getStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('Error cargando estadísticas:\n$_error', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center))
              : _stats == null
                  ? const Center(child: Text('No hay datos disponibles'))
                  : RefreshIndicator(
                      onRefresh: _loadStats,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Resumen del Inventario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildStatCards(),
                            const SizedBox(height: 32),
                            const Text('Análisis Gráfico', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildCharts(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStatCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 400 ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth > 400 ? 2.0 : 2.5,
          children: [
            _statCard('Total Películas', _stats!.totalFilms.toString(), Icons.movie, Theme.of(context).primaryColor),
            _statCard('Total Copias', _stats!.totalCopies.toString(), Icons.inventory_2, Colors.purple),
            _statCard('Alquileres Activos', _stats!.activeRentals.toString(), Icons.timer, Colors.orange),
            _statCard('Alquileres Devueltos', _stats!.returnedRentals.toString(), Icons.check_circle, Colors.green),
          ],
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 20, child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey))),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    final pieChart = _chartContainer(
      'Estado de Alquileres',
      PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.orange,
              value: _stats!.activeRentals.toDouble(),
              title: '${_stats!.activeRentals}',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              color: Colors.green,
              value: _stats!.returnedRentals.toDouble(),
              title: '${_stats!.returnedRentals}',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
      legend: _buildLegend({'Activos': Colors.orange, 'Devueltos': Colors.green}),
    );

    final barChart = _chartContainer(
      'Películas vs Copias',
      BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (_stats!.totalCopies > _stats!.totalFilms ? _stats!.totalCopies : _stats!.totalFilms).toDouble() * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
                  Widget text;
                  switch (value.toInt()) {
                    case 0:
                      text = const Text('Películas', style: style);
                      break;
                    case 1:
                      text = const Text('Copias', style: style);
                      break;
                    default:
                      text = const Text('');
                      break;
                  }
                  return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: text);
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(toY: _stats!.totalFilms.toDouble(), color: Theme.of(context).primaryColor, width: 22, borderRadius: BorderRadius.circular(4)),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(toY: _stats!.totalCopies.toDouble(), color: Colors.purple, width: 22, borderRadius: BorderRadius.circular(4)),
              ],
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: pieChart),
          const SizedBox(width: 16),
          Expanded(child: barChart),
        ],
      );
    } else {
      return Column(
        children: [
          pieChart,
          const SizedBox(height: 16),
          barChart,
        ],
      );
    }
  }

  Widget _chartContainer(String title, Widget chart, {Widget? legend}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: chart,
            ),
            if (legend != null) ...[
              const SizedBox(height: 16),
              legend,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, Color> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: e.value)),
              const SizedBox(width: 4),
              Text(e.key, style: const TextStyle(fontSize: 14)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

