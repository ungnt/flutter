import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';
import '../theme/app_theme.dart';


class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  final DatabaseService _db = DatabaseService.instance;
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now();
  
  List<TrabalhoModel> _trabalhos = [];
  List<GastoModel> _gastos = [];
  List<ManutencaoModel> _manutencoes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _trabalhos = await _db.getTrabalhos(dataInicio: _dataInicio, dataFim: _dataFim);
    _gastos = await _db.getGastos(dataInicio: _dataInicio, dataFim: _dataFim);
    _manutencoes = await _db.getManutencoes(dataInicio: _dataInicio, dataFim: _dataFim);
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios e Análises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),
                  _buildResumoFinanceiro(),
                  const SizedBox(height: 16),
                  _buildGraficoGanhos(),
                  const SizedBox(height: 16),
                  _buildAnaliseRentabilidade(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Período de Análise',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dataInicio,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dataInicio = date);
                        _loadData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Data Início', style: TextStyle(fontSize: 12)),
                          Text(DateFormat('dd/MM/yyyy').format(_dataInicio)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dataFim,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _dataFim = date);
                        _loadData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Data Fim', style: TextStyle(fontSize: 12)),
                          Text(DateFormat('dd/MM/yyyy').format(_dataFim)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoFinanceiro() {
    final totalGanhos = _trabalhos.fold(0.0, (sum, t) => sum + t.ganhos);
    final totalGastos = _gastos.fold(0.0, (sum, g) => sum + g.valor);
    final totalManutencoes = _manutencoes.fold(0.0, (sum, m) => sum + m.valor);
    final totalLiquido = totalGanhos - totalGastos - totalManutencoes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo Financeiro',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Ganhos',
                    'R\$ ${totalGanhos.toStringAsFixed(2)}',
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Total Gastos',
                    'R\$ ${(totalGastos + totalManutencoes).toStringAsFixed(2)}',
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMetricCard(
              'Lucro Líquido',
              'R\$ ${totalLiquido.toStringAsFixed(2)}',
              totalLiquido >= 0 ? Colors.green : Colors.red,
              totalLiquido >= 0 ? Icons.thumb_up : Icons.thumb_down,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((255 * 0.3).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoGanhos() {
    if (_trabalhos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhum dado de ganhos para exibir'),
        ),
      );
    }

    // Agrupar ganhos por dia
    final ganhosPorDia = <DateTime, double>{};
    for (final trabalho in _trabalhos) {
      final dia = DateTime(trabalho.data.year, trabalho.data.month, trabalho.data.day);
      ganhosPorDia[dia] = (ganhosPorDia[dia] ?? 0) + trabalho.ganhos;
    }

    final spots = ganhosPorDia.entries
        .map((entry) => FlSpot(
              entry.key.millisecondsSinceEpoch.toDouble(),
              entry.value,
            ))
        .toList();

    spots.sort((a, b) => a.x.compareTo(b.x));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolução dos Ganhos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text(
                            DateFormat('dd/MM').format(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'R\$ ${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.successColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoGastos() {
    if (_gastos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhum dado de gastos para exibir'),
        ),
      );
    }

    // Agrupar gastos por categoria
    final gastosPorCategoria = <String, double>{};
    for (final gasto in _gastos) {
      gastosPorCategoria[gasto.categoria] = 
          (gastosPorCategoria[gasto.categoria] ?? 0) + gasto.valor;
    }

    final sections = gastosPorCategoria.entries
        .map((entry) => PieChartSectionData(
              color: _getCategoryColor(entry.key),
              value: entry.value,
              title: '${entry.key}\nR\$ ${entry.value.toStringAsFixed(2)}',
              titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
            ))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gastos por Categoria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnaliseRentabilidade() {
    final totalGanhos = _trabalhos.fold(0.0, (sum, t) => sum + t.ganhos);
    final totalKm = _trabalhos.fold(0.0, (sum, t) => sum + t.km);
    final totalHoras = _trabalhos.fold(0.0, (sum, t) => sum + t.horas);
    final totalCombustivel = _gastos.where((g) => g.categoria == 'Combustível').fold(0.0, (sum, g) => sum + g.valor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análise de Rentabilidade',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildAnaliseItem(
              'Ganhos por KM',
              totalKm > 0 ? totalGanhos / totalKm : 0,
              'R\$/km',
              AppTheme.primaryColor,
            ),
            
            _buildAnaliseItem(
              'Ganhos por Hora',
              totalHoras > 0 ? totalGanhos / totalHoras : 0,
              'R\$/h',
              AppTheme.successColor,
            ),
            
            _buildAnaliseItem(
              'Gasto com Combustível',
              totalKm > 0 ? totalCombustivel / totalKm : 0,
              'R\$/km',
              AppTheme.errorColor,
            ),
            
            _buildAnaliseItem(
              'Eficiência Energética',
              totalCombustivel > 0 ? totalKm / (totalCombustivel / 5.5) : 0,
              'km/l',
              AppTheme.warningColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnaliseItem(String titulo, double valor, String unidade, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${valor.toStringAsFixed(2)} $unidade',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria) {
      case 'Combustível':
        return Colors.orange;
      case 'Alimentação':
        return Colors.green;
      case 'Pedágio':
        return Colors.blue;
      case 'Estacionamento':
        return Colors.purple;
      case 'Limpeza':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}