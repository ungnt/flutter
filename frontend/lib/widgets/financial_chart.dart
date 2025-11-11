import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';

class FinancialChart extends StatelessWidget {
  final String period; // 'dias', 'meses', 'anos'
  final Color barColor;

  const FinancialChart({
    super.key,
    required this.period,
    this.barColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BarChartGroupData>>(
      future: _getChartData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Sem dados para exibir'));
        }

        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY(snapshot.data!),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      'R\$ ${rod.toY.toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _getBottomTitle(value.toInt()),
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        'R\$ ${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: snapshot.data!,
            ),
          ),
        );
      },
    );
  }

  Future<List<BarChartGroupData>> _getChartData() async {
    final now = DateTime.now();
    List<BarChartGroupData> chartData = [];

    switch (period) {
      case 'dias':
        // Últimos 7 dias
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final startOfDay = DateTime(date.year, date.month, date.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));
          
          final trabalhosResp = await ApiService.getTrabalhos(dataInicio: startOfDay, dataFim: endOfDay);
          final trabalhos = trabalhosResp.success && trabalhosResp.data?['trabalhos'] != null
              ? (trabalhosResp.data!['trabalhos'] as List).map((t) => TrabalhoModel.fromJson(t)).toList()
              : <TrabalhoModel>[];
          
          final gastosResp = await ApiService.getGastos(dataInicio: startOfDay, dataFim: endOfDay);
          final gastos = gastosResp.success && gastosResp.data?['gastos'] != null
              ? (gastosResp.data!['gastos'] as List).map((g) => GastoModel.fromJson(g)).toList()
              : <GastoModel>[];
          
          final ganhos = trabalhos.fold<double>(0, (sum, t) => sum + t.ganhos);
          final gastoTotal = gastos.fold<double>(0, (sum, g) => sum + g.valor);
          final liquido = ganhos - gastoTotal;
          
          chartData.add(BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: liquido.abs(),
                color: liquido >= 0 ? Colors.green : Colors.red,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ));
        }
        break;

      case 'meses':
        // Últimos 6 meses
        for (int i = 5; i >= 0; i--) {
          final date = DateTime(now.year, now.month - i, 1);
          final endOfMonth = DateTime(date.year, date.month + 1, 1);
          
          final trabalhosResp = await ApiService.getTrabalhos(dataInicio: date, dataFim: endOfMonth);
          final trabalhos = trabalhosResp.success && trabalhosResp.data?['trabalhos'] != null
              ? (trabalhosResp.data!['trabalhos'] as List).map((t) => TrabalhoModel.fromJson(t)).toList()
              : <TrabalhoModel>[];
          
          final gastosResp = await ApiService.getGastos(dataInicio: date, dataFim: endOfMonth);
          final gastos = gastosResp.success && gastosResp.data?['gastos'] != null
              ? (gastosResp.data!['gastos'] as List).map((g) => GastoModel.fromJson(g)).toList()
              : <GastoModel>[];
          
          final ganhos = trabalhos.fold<double>(0, (sum, t) => sum + t.ganhos);
          final gastoTotal = gastos.fold<double>(0, (sum, g) => sum + g.valor);
          final liquido = ganhos - gastoTotal;
          
          chartData.add(BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: liquido.abs(),
                color: liquido >= 0 ? Colors.green : Colors.red,
                width: 30,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ));
        }
        break;

      case 'anos':
        // Últimos 3 anos
        for (int i = 2; i >= 0; i--) {
          final year = now.year - i;
          final startOfYear = DateTime(year, 1, 1);
          final endOfYear = DateTime(year + 1, 1, 1);
          
          final trabalhosResp = await ApiService.getTrabalhos(dataInicio: startOfYear, dataFim: endOfYear);
          final trabalhos = trabalhosResp.success && trabalhosResp.data?['trabalhos'] != null
              ? (trabalhosResp.data!['trabalhos'] as List).map((t) => TrabalhoModel.fromJson(t)).toList()
              : <TrabalhoModel>[];
          
          final gastosResp = await ApiService.getGastos(dataInicio: startOfYear, dataFim: endOfYear);
          final gastos = gastosResp.success && gastosResp.data?['gastos'] != null
              ? (gastosResp.data!['gastos'] as List).map((g) => GastoModel.fromJson(g)).toList()
              : <GastoModel>[];
          
          final ganhos = trabalhos.fold<double>(0, (sum, t) => sum + t.ganhos);
          final gastoTotal = gastos.fold<double>(0, (sum, g) => sum + g.valor);
          final liquido = ganhos - gastoTotal;
          
          chartData.add(BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: liquido.abs(),
                color: liquido >= 0 ? Colors.green : Colors.red,
                width: 40,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ));
        }
        break;
    }

    return chartData;
  }

  double _getMaxY(List<BarChartGroupData> data) {
    double max = 0;
    for (final group in data) {
      for (final rod in group.barRods) {
        if (rod.toY > max) max = rod.toY;
      }
    }
    return max * 1.2; // 20% a mais para espaçamento
  }

  String _getBottomTitle(int value) {
    final now = DateTime.now();
    
    switch (period) {
      case 'dias':
        final date = now.subtract(Duration(days: 6 - value));
        return DateFormat('dd/MM').format(date);
      case 'meses':
        final date = DateTime(now.year, now.month - (5 - value), 1);
        return DateFormat('MMM').format(date);
      case 'anos':
        return (now.year - (2 - value)).toString();
      default:
        return '';
    }
  }
}