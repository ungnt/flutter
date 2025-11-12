import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/dashboard_cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/animated_counter.dart';
import '../widgets/secret_gesture_detector.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';
import 'registro_integrado_screen.dart';
import 'relatorios_screen.dart';
import 'goals_screen.dart';
import 'configuracoes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, double> dadosHoje = {};
  Map<String, double> dadosMes = {};
  List<Map<String, dynamic>> ultimosRegistros = [];
  bool isLoading = true;
  bool isAuthenticated = false;
  String? userEmail;
  bool isUsingCachedData = false;
  DateTime? lastUpdate;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
    _loadDashboardData();
  }

  Future<void> _checkAuthenticationStatus() async {
    final authenticated = await AuthService.isAuthenticated();
    final email = await AuthService.getUserEmail();
    
    setState(() {
      isAuthenticated = authenticated;
      userEmail = email;
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    
    try {
      final cachedData = await DashboardCacheService.instance.loadDashboardData();
      if (cachedData != null) {
        setState(() {
          dadosHoje = cachedData['dadosHoje'] as Map<String, double>;
          dadosMes = cachedData['dadosMes'] as Map<String, double>;
          ultimosRegistros = cachedData['ultimosRegistros'] as List<Map<String, dynamic>>;
          lastUpdate = cachedData['lastUpdate'] as DateTime?;
          isUsingCachedData = true;
          isLoading = false;
        });
      }
      
      final online = await ApiService.isOnline();
      
      if (!online && mounted) {
        if (cachedData == null) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sem conexão com o servidor e nenhum dado em cache. Verifique sua internet.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Modo offline - mostrando dados salvos'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
        return;
      }
      
      setState(() => isLoading = true);
      
      final hoje = DateTime.now();
      final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
      final fimHoje = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);
      final inicioMes = DateTime(hoje.year, hoje.month, 1);
      final fimMes = DateTime(hoje.year, hoje.month + 1, 0, 23, 59, 59);
      
      final results = await Future.wait([
        ApiService.getTrabalhos(dataInicio: inicioHoje, dataFim: fimHoje),
        ApiService.getGastos(dataInicio: inicioHoje, dataFim: fimHoje),
        ApiService.getManutencoes(dataInicio: inicioHoje, dataFim: fimHoje),
        ApiService.getTrabalhos(dataInicio: inicioMes, dataFim: fimMes),
        ApiService.getGastos(dataInicio: inicioMes, dataFim: fimMes),
        ApiService.getManutencoes(dataInicio: inicioMes, dataFim: fimMes),
      ], eagerError: true);
      
      final responseTrabHoje = results[0];
      final responseGastosHoje = results[1];
      final responseManuHoje = results[2];
      final responseTrabMes = results[3];
      final responseGastosMes = results[4];
      final responseManuMes = results[5];
      
      // Trabalhos de hoje
      List<TrabalhoModel> trabalhosHoje = [];
      if (responseTrabHoje.success && responseTrabHoje.data != null) {
        final list = responseTrabHoje.data!['trabalhos'] as List<dynamic>?;
        if (list != null) {
          trabalhosHoje = list.map((t) => TrabalhoModel.fromMap(t)).toList();
        }
      }
      
      // Gastos de hoje
      List<GastoModel> gastosHoje = [];
      if (responseGastosHoje.success && responseGastosHoje.data != null) {
        final list = responseGastosHoje.data!['gastos'] as List<dynamic>?;
        if (list != null) {
          gastosHoje = list.map((g) => GastoModel.fromMap(g)).toList();
        }
      }
      
      // Manutenções de hoje
      List<ManutencaoModel> manutencoesHoje = [];
      if (responseManuHoje.success && responseManuHoje.data != null) {
        final list = responseManuHoje.data!['manutencoes'] as List<dynamic>?;
        if (list != null) {
          manutencoesHoje = list.map((m) => ManutencaoModel.fromMap(m)).toList();
        }
      }
      
      // Trabalhos do mês
      List<TrabalhoModel> trabalhosMes = [];
      if (responseTrabMes.success && responseTrabMes.data != null) {
        final list = responseTrabMes.data!['trabalhos'] as List<dynamic>?;
        if (list != null) {
          trabalhosMes = list.map((t) => TrabalhoModel.fromMap(t)).toList();
        }
      }
      
      // Gastos do mês
      List<GastoModel> gastosMes = [];
      if (responseGastosMes.success && responseGastosMes.data != null) {
        final list = responseGastosMes.data!['gastos'] as List<dynamic>?;
        if (list != null) {
          gastosMes = list.map((g) => GastoModel.fromMap(g)).toList();
        }
      }
      
      // Manutenções do mês
      List<ManutencaoModel> manutencoesMes = [];
      if (responseManuMes.success && responseManuMes.data != null) {
        final list = responseManuMes.data!['manutencoes'] as List<dynamic>?;
        if (list != null) {
          manutencoesMes = list.map((m) => ManutencaoModel.fromMap(m)).toList();
        }
      }
      
      // Calcular totais
      final ganhosHoje = trabalhosHoje.fold(0.0, (sum, t) => sum + t.ganhos);
      final gastosHojeTotal = gastosHoje.fold(0.0, (sum, g) => sum + g.valor);
      final manutencoesHojeTotal = manutencoesHoje.fold(0.0, (sum, m) => sum + m.valor);
      
      final ganhosMes = trabalhosMes.fold(0.0, (sum, t) => sum + t.ganhos);
      final gastosMesTotal = gastosMes.fold(0.0, (sum, g) => sum + g.valor);
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
    
      // Últimos registros (últimos 10 do mês)
      ultimosRegistros = _getUltimosRegistros(trabalhosMes, gastosMes, manutencoesMes);
      
      await DashboardCacheService.instance.saveDashboardData(
        dadosHoje: dadosHoje,
        dadosMes: dadosMes,
        ultimosRegistros: ultimosRegistros,
      );
      
      setState(() {
        isLoading = false;
        isUsingCachedData = false;
        lastUpdate = DateTime.now();
      });
    } catch (e) {
      print('Erro ao carregar dados do dashboard: $e');
      
      final cachedData = await DashboardCacheService.instance.loadDashboardData();
      if (cachedData != null && mounted) {
        setState(() {
          dadosHoje = cachedData['dadosHoje'] as Map<String, double>;
          dadosMes = cachedData['dadosMes'] as Map<String, double>;
          ultimosRegistros = cachedData['ultimosRegistros'] as List<Map<String, dynamic>>;
          lastUpdate = cachedData['lastUpdate'] as DateTime?;
          isUsingCachedData = true;
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar. Mostrando dados salvos: ${e.toString().split(':').first}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar dados: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<Map<String, dynamic>> _getUltimosRegistros(
    List<TrabalhoModel> trabalhos,
    List<GastoModel> gastos,
    List<ManutencaoModel> manutencoes,
  ) {
    List<Map<String, dynamic>> registros = [];
    
    for (var trabalho in trabalhos) {
      registros.add({
        'tipo': 'trabalho',
        'data': trabalho.data,
        'valor': trabalho.ganhos,
        'descricao': 'Ganhos: R\$ ${trabalho.ganhos.toStringAsFixed(2)}',
        'icon': Icons.work,
        'color': AppTheme.successColor,
      });
    }
    
    for (var gasto in gastos) {
      registros.add({
        'tipo': 'gasto',
        'data': gasto.data,
        'valor': gasto.valor,
        'descricao': '${gasto.categoria}: R\$ ${gasto.valor.toStringAsFixed(2)}',
        'icon': Icons.money_off,
        'color': AppTheme.errorColor,
      });
    }
    
    for (var manutencao in manutencoes) {
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
        title: SecretGestureDetector(
          requiredTaps: 5,
          child: const Text('Motouber - Controle Financeiro'),
        ),
        centerTitle: true,
        actions: [
          if (isAuthenticated) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              onSelected: (value) {
                if (value == 'logout') {
                  _handleLogout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'user',
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Logado como:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(userEmail ?? 'Usuário', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sair', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _navigateToLogin,
              tooltip: 'Fazer Login',
            ),
          ],
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
                    _buildAuthenticationStatus(),
                    const SizedBox(height: 16),
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
    return ModernCard(
      backgroundColor: color.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              AnimatedCounter(
                value: value,
                prefix: 'R\$ ',
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistroIntegradoScreen()));
            }),
            _buildNavButton('Metas', Icons.emoji_events, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen()));
            }, color: AppTheme.accentColor),
            _buildNavButton('Relatórios', Icons.analytics, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RelatoriosScreen()));
            }, color: AppTheme.secondaryColor),
            _buildNavButton('Configurações', Icons.settings, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ConfiguracoesScreen()));
            }, color: AppTheme.chromeColor),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton(String title, IconData icon, VoidCallback onTap, {Color? color}) {
    final buttonColor = color ?? AppTheme.primaryColor;
    
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: buttonColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
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

  Widget _buildAuthenticationStatus() {
    final showOfflineWarning = isUsingCachedData || !isAuthenticated;
    final statusColor = showOfflineWarning ? AppTheme.warningColor : AppTheme.successColor;
    
    return Column(
      children: [
        ModernCard(
          backgroundColor: statusColor.withOpacity(0.05),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  showOfflineWarning ? Icons.cloud_off : Icons.cloud_done,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUsingCachedData ? 'Modo Offline' : (isAuthenticated ? 'Online' : 'Não autenticado'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (isAuthenticated && userEmail != null && !isUsingCachedData) 
                      Text(
                        userEmail!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else if (isUsingCachedData && lastUpdate != null)
                      Text(
                        'Dados de ${DateFormat('dd/MM/yyyy HH:mm').format(lastUpdate!)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else if (!isAuthenticated)
                      const Text(
                        'Dados salvos apenas localmente',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              if (!isAuthenticated)
                TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text('Entrar'),
                ),
            ],
          ),
        ),
        if (isUsingCachedData) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Mostrando dados salvos. Puxe para baixo para tentar atualizar.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Tem certeza que deseja sair?\n\nVocê continuará no modo offline até fazer login novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login').then((_) {
      _checkAuthenticationStatus();
    });
  }
}