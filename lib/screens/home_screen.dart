import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';
import '../theme/app_theme.dart';
import 'trabalho_screen.dart';
import 'gastos_screen.dart';
import 'manutencoes_screen.dart';
import 'relatorios_screen.dart';
import 'configuracoes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService.instance;
  Map<String, double> dadosHoje = {};
  Map<String, double> dadosMes = {};
  List<Map<String, dynamic>> ultimosRegistros = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    
    final hoje = DateTime.now();
    final inicioMes = DateTime(hoje.year, hoje.month, 1);
    final fimMes = DateTime(hoje.year, hoje.month + 1, 0);
    
    // Dados de hoje
    final trabalhosHoje = await _db.getTrabalhos(dataInicio: hoje, dataFim: hoje);
    final gastosHoje = await _db.getGastos(dataInicio: hoje, dataFim: hoje);
    final manutencoesHoje = await _db.getManutencoes(dataInicio: hoje, dataFim: hoje);
    
    // Dados do mês
    final trabalhosMes = await _db.getTrabalhos(dataInicio: inicioMes, dataFim: fimMes);
    final gastosMes = await _db.getGastos(dataInicio: inicioMes, dataFim: fimMes);
    final manutencoesMes = await _db.getManutencoes(dataInicio: inicioMes, dataFim: fimMes);
    
    // Calcular totais
    final ganhosHoje = trabalhosHoje.fold(0.0, (sum, t) => sum + t.ganhos);
    final gastosHojeTotal = gastosHoje.fold(0.0, (sum, g) => sum + g.valor) +
                           trabalhosHoje.fold(0.0, (sum, t) => sum + t.combustivel);
    final manutencoesHojeTotal = manutencoesHoje.fold(0.0, (sum, m) => sum + m.valor);
    
    final ganhosMes = trabalhosMes.fold(0.0, (sum, t) => sum + t.ganhos);
    final gastosMesTotal = gastosMes.fold(0.0, (sum, g) => sum + g.valor) +
                          trabalhosMes.fold(0.0, (sum, t) => sum + t.combustivel);
    final manutencoesMesTotal = manutencoesMes.fold(0.0, (sum, m) => sum + m.valor);
    
    dadosHoje = {
      'ganhos': ganhosHoje,
      'gastos': gastosHojeTotal,
      'manutencoes': manutencoesHojeTotal,
      'liquido': ganhosHoje - gastosHojeTotal - manutencoesHojeTotal,
    };
    
    dadosMes = {
      'ganhos': ganhosMes,
      'gastos': gastosMesTotal,
      'manutencoes': manutencoesMesTotal,
      'liquido': ganhosMes - gastosMesTotal - manutencoesMesTotal,
    };
    
    // Últimos registros
    ultimosRegistros = await _getUltimosRegistros();
    
    setState(() => isLoading = false);
  }

  Future<List<Map<String, dynamic>>> _getUltimosRegistros() async {
    final trabalhos = await _db.getTrabalhos();
    final gastos = await _db.getGastos();
    final manutencoes = await _db.getManutencoes();
    
    List<Map<String, dynamic>> registros = [];
    
    for (var trabalho in trabalhos.take(5)) {
      registros.add({
        'tipo': 'trabalho',
        'data': trabalho.data,
        'valor': trabalho.ganhos,
        'descricao': 'Ganhos: R\$ ${trabalho.ganhos.toStringAsFixed(2)}',
        'icon': Icons.work,
        'color': AppTheme.successColor,
      });
    }
    
    for (var gasto in gastos.take(5)) {
      registros.add({
        'tipo': 'gasto',
        'data': gasto.data,
        'valor': gasto.valor,
        'descricao': '${gasto.categoria}: R\$ ${gasto.valor.toStringAsFixed(2)}',
        'icon': Icons.money_off,
        'color': AppTheme.errorColor,
      });
    }
    
    for (var manutencao in manutencoes.take(5)) {
      registros.add({
        'tipo': 'manutencao',
        'data': manutencao.data,
        'valor': manutencao.valor,
        'descricao': '${manutencao.tipo}: R\$ ${manutencao.valor.toStringAsFixed(2)}',
        'icon': Icons.build,
        'color': AppTheme.warningColor,
      });
    }
    
    registros.sort((a, b) => b['data'].compareTo(a['data']));
    return registros.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motouber - Controle Financeiro'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashboardCards(),
                    const SizedBox(height: 24),
                    _buildNavigationButtons(),
                    const SizedBox(height: 24),
                    _buildUltimosRegistros(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDashboardCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Ganhos Hoje',
                dadosHoje['ganhos'] ?? 0.0,
                AppTheme.successColor,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Gastos Hoje',
                dadosHoje['gastos'] ?? 0.0,
                AppTheme.errorColor,
                Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Líquido Hoje',
                dadosHoje['liquido'] ?? 0.0,
                AppTheme.primaryColor,
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Líquido Mês',
                dadosMes['liquido'] ?? 0.0,
                AppTheme.secondaryColor,
                Icons.calendar_month,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                'R\$ ${value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  Widget _buildNavigationButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Navegação',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildNavButton('Registro Diário', Icons.work, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TrabalhoScreen()));
            }),
            _buildNavButton('Gastos', Icons.money_off, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GastosScreen()));
            }),
            _buildNavButton('Manutenções', Icons.build, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManutencoesScreen()));
            }),
            _buildNavButton('Relatórios', Icons.analytics, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RelatoriosScreen()));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUltimosRegistros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimos Registros',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (ultimosRegistros.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum registro encontrado'),
            ),
          )
        else
          ...ultimosRegistros.map((registro) => Card(
            child: ListTile(
              leading: Icon(registro['icon'], color: registro['color']),
              title: Text(registro['descricao']),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(registro['data'])),
              trailing: Text(
                'R\$ ${registro['valor'].toStringAsFixed(2)}',
                style: TextStyle(
                  color: registro['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )),
      ],
    );
  }
}