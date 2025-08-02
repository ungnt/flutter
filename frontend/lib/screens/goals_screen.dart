import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:motouber/services/goals_service.dart';
import 'package:motouber/theme/app_theme.dart';
import 'package:motouber/widgets/modern_card.dart';
import 'package:motouber/widgets/animated_counter.dart';
import 'package:motouber/widgets/glowing_card.dart';
import 'package:motouber/widgets/pulsing_icon.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  Map<String, dynamic> _goalsProgress = {};
  Map<String, dynamic> _motivationalStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final progress = await GoalsService.getAllGoalsProgress();
    final stats = await GoalsService.getMotivationalStats();
    
    if (mounted) {
      setState(() {
        _goalsProgress = progress;
        _motivationalStats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('🎯 Metas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('🎯 Metas & Objetivos'),
        actions: [
          IconButton(
            onPressed: _showConfigGoals,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _buildMotivationalHeader(),
                  const SizedBox(height: 24),
                  _buildGoalCard('diaria', 'Meta Diária', Icons.today),
                  const SizedBox(height: 16),
                  _buildGoalCard('mensal', 'Meta Mensal', Icons.calendar_month),
                  const SizedBox(height: 16),
                  _buildFuelEfficiencyCard(),
                  const SizedBox(height: 24),
                  _buildStatsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalHeader() {
    final weekEarnings = _motivationalStats['ganhos_semana'] ?? 0.0;
    final bestDay = _motivationalStats['melhor_dia'] ?? 0.0;
    
    return GlowingCard(
      glowColor: AppTheme.accentColor,
      child: Column(
        children: [
          const Row(
            children: [
              PulsingIcon(
                icon: Icons.emoji_events,
                color: AppTheme.accentColor,
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Conquistando as ruas! 🏍️',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Esta semana',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    AnimatedCounter(
                      value: weekEarnings,
                      prefix: 'R\$ ',
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Melhor dia',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    AnimatedCounter(
                      value: bestDay,
                      prefix: 'R\$ ',
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String key, String title, IconData icon) {
    final goal = _goalsProgress[key] ?? {};
    final progress = goal['progresso']?.toDouble() ?? 0.0;
    final atual = goal['atual']?.toDouble() ?? 0.0;
    final meta = goal['meta']?.toDouble() ?? 0.0;
    final atingida = goal['atingida'] ?? false;

    return ModernCard(
      useGradient: atingida,
      gradient: atingida ? AppTheme.primaryGradient : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: atingida ? Colors.white : AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: atingida ? Colors.white : null,
                  ),
                ),
              ),
              if (atingida)
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: atingida 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (progress / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: atingida 
                      ? Colors.white
                      : (progress >= 100 ? AppTheme.successColor : AppTheme.secondaryColor),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atual',
                    style: TextStyle(
                      fontSize: 12,
                      color: atingida ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  AnimatedCounter(
                    value: atual,
                    prefix: 'R\$ ',
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: atingida ? Colors.white : AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Meta',
                    style: TextStyle(
                      fontSize: 12,
                      color: atingida ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  AnimatedCounter(
                    value: meta,
                    prefix: 'R\$ ',
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: atingida ? Colors.white : AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (progress < 100) ...[
            const SizedBox(height: 8),
            Text(
              '${progress.toStringAsFixed(1)}% concluído',
              style: TextStyle(
                fontSize: 12,
                color: atingida ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFuelEfficiencyCard() {
    final goal = _goalsProgress['eficiencia_combustivel'] ?? {};
    final atual = goal['atual']?.toDouble() ?? 0.0;
    final meta = goal['meta']?.toDouble() ?? 0.0;
    final totalKm = goal['total_km']?.toDouble() ?? 0.0;
    final atingida = goal['atingida'] ?? false;

    return ModernCard(
      useGradient: atingida,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_gas_station,
                color: atingida ? Colors.white : AppTheme.warningColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Eficiência Combustível',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: atingida ? Colors.white : null,
                  ),
                ),
              ),
              if (atingida)
                const Icon(Icons.eco, color: Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atual',
                      style: TextStyle(
                        fontSize: 12,
                        color: atingida ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    Text(
                      '${atual.toStringAsFixed(1)} km/l',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: atingida ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Meta',
                      style: TextStyle(
                        fontSize: 12,
                        color: atingida ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    Text(
                      '${meta.toStringAsFixed(1)} km/l',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: atingida ? Colors.white : AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KM rodados',
                      style: TextStyle(
                        fontSize: 12,
                        color: atingida ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    Text(
                      '${totalKm.toStringAsFixed(0)} km',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: atingida ? Colors.white : AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final diasTrabalhados = _motivationalStats['dias_trabalhados_mes'] ?? 0;
    final mediaDiaria = _motivationalStats['media_diaria_mes'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Estatísticas do Mês',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: ModernCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$diasTrabalhados',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Text(
                      'Dias trabalhados',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModernCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: AppTheme.successColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    AnimatedCounter(
                      value: mediaDiaria,
                      prefix: 'R\$ ',
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const Text(
                      'Média diária',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showConfigGoals() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const GoalsConfigBottomSheet(),
    );
  }
}

class GoalsConfigBottomSheet extends StatefulWidget {
  const GoalsConfigBottomSheet({super.key});

  @override
  State<GoalsConfigBottomSheet> createState() => _GoalsConfigBottomSheetState();
}

class _GoalsConfigBottomSheetState extends State<GoalsConfigBottomSheet> {
  final _dailyController = TextEditingController();
  final _monthlyController = TextEditingController();
  final _fuelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentGoals();
  }

  Future<void> _loadCurrentGoals() async {
    final daily = await GoalsService.getDailyGoal();
    final monthly = await GoalsService.getMonthlyGoal();
    final fuel = await GoalsService.getFuelEfficiencyGoal();

    _dailyController.text = daily.toStringAsFixed(2);
    _monthlyController.text = monthly.toStringAsFixed(2);
    _fuelController.text = fuel.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Configurar Metas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _dailyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Meta diária (R\$)',
              prefixIcon: Icon(Icons.today),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _monthlyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Meta mensal (R\$)',
              prefixIcon: Icon(Icons.calendar_month),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _fuelController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Meta eficiência (km/l)',
              prefixIcon: Icon(Icons.local_gas_station),
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveGoals,
              child: const Text('Salvar Metas'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGoals() async {
    try {
      await GoalsService.setDailyGoal(double.parse(_dailyController.text));
      await GoalsService.setMonthlyGoal(double.parse(_monthlyController.text));
      await GoalsService.setFuelEfficiencyGoal(double.parse(_fuelController.text));
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metas salvas com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar metas: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _monthlyController.dispose();
    _fuelController.dispose();
    super.dispose();
  }
}