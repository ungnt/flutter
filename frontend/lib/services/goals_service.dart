import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';

class GoalsService {
  static const String _dailyGoalKey = 'daily_goal';
  static const String _monthlyGoalKey = 'monthly_goal';
  static const String _fuelEfficiencyGoalKey = 'fuel_efficiency_goal';

  // Salvar metas
  static Future<void> setDailyGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dailyGoalKey, goal);
  }

  static Future<void> setMonthlyGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_monthlyGoalKey, goal);
  }

  static Future<void> setFuelEfficiencyGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fuelEfficiencyGoalKey, goal);
  }

  // Obter metas
  static Future<double> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_dailyGoalKey) ?? 200.0;
  }

  static Future<double> getMonthlyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_monthlyGoalKey) ?? 5000.0;
  }

  static Future<double> getFuelEfficiencyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fuelEfficiencyGoalKey) ?? 15.0; // km/l
  }

  // Calcular progresso das metas
  static Future<Map<String, dynamic>> getDailyProgress() async {
    final goal = await getDailyGoal();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await ApiService.getTrabalhos(dataInicio: startOfDay, dataFim: endOfDay);
    final trabalhos = response.success && response.data?['trabalhos'] != null
        ? (response.data!['trabalhos'] as List).map((t) => TrabalhoModel.fromJson(t)).toList()
        : <TrabalhoModel>[];
    
    final atual = trabalhos.fold<double>(0, (sum, t) => sum + t.ganhos);
    final progresso = goal > 0 ? (atual / goal) * 100 : 0.0;

    return {
      'meta': goal,
      'atual': atual,
      'progresso': progresso.clamp(0, 100),
      'faltam': (goal - atual).clamp(0, double.infinity),
      'atingida': atual >= goal,
    };
  }

  static Future<Map<String, dynamic>> getMonthlyProgress() async {
    final goal = await getMonthlyGoal();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final response = await ApiService.getTrabalhos(dataInicio: startOfMonth, dataFim: endOfMonth);
    final trabalhos = response.success && response.data?['trabalhos'] != null
        ? (response.data!['trabalhos'] as List).map((t) => TrabalhoModel.fromJson(t)).toList()
        : <TrabalhoModel>[];
    
    final atual = trabalhos.fold<double>(0, (sum, t) => sum + t.ganhos);
    final progresso = goal > 0 ? (atual / goal) * 100 : 0.0;

    return {
      'meta': goal,
      'atual': atual,
      'progresso': progresso.clamp(0, 100),
      'faltam': (goal - atual).clamp(0, double.infinity),
      'atingida': atual >= goal,
    };
  }

  static Future<Map<String, dynamic>> getFuelEfficiencyProgress() async {
    final goal = await getFuelEfficiencyGoal();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final trabalhosResponse = await ApiService.getTrabalhos(dataInicio: startOfMonth, dataFim: endOfMonth);
    final trabalhos = trabalhosResponse.success && trabalhosResponse.data?['trabalhos'] != null
        ? (trabalhosResponse.data!['trabalhos'] as List).map((t) => TrabalhoModel.fromJson(t)).toList()
        : <TrabalhoModel>[];
    
    final gastosResponse = await ApiService.getGastos(dataInicio: startOfMonth, dataFim: endOfMonth);
    final gastos = gastosResponse.success && gastosResponse.data?['gastos'] != null
        ? (gastosResponse.data!['gastos'] as List).map((g) => GastoModel.fromJson(g)).toList()
        : <GastoModel>[];

    final totalKm = trabalhos.fold<double>(0, (sum, t) => sum + t.km);
    final gastoCombustivel = gastos
        .where((g) => g.categoria.toLowerCase().contains('combustível') || 
                      g.categoria.toLowerCase().contains('gasolina') ||
                      g.categoria.toLowerCase().contains('álcool') ||
                      g.categoria.toLowerCase().contains('etanol'))
        .fold<double>(0, (sum, g) => sum + g.valor);

    double eficienciaAtual = 0;
    if (gastoCombustivel > 0) {
      // Estimativa aproximada: 1 litro ≈ R$ 5,50 (média)
      final litrosConsumidos = gastoCombustivel / 5.5;
      if (litrosConsumidos > 0) {
        eficienciaAtual = totalKm / litrosConsumidos;
      }
    }

    final progresso = goal > 0 ? (eficienciaAtual / goal) * 100 : 0.0;

    return {
      'meta': goal,
      'atual': eficienciaAtual,
      'progresso': progresso.clamp(0, 100),
      'total_km': totalKm,
      'gasto_combustivel': gastoCombustivel,
      'atingida': eficienciaAtual >= goal,
    };
  }

  // Obter todas as metas e progressos
  static Future<Map<String, dynamic>> getAllGoalsProgress() async {
    final daily = await getDailyProgress();
    final monthly = await getMonthlyProgress();
    final fuelEfficiency = await getFuelEfficiencyProgress();

    return {
      'diaria': daily,
      'mensal': monthly,
      'eficiencia_combustivel': fuelEfficiency,
    };
  }

  // Estatísticas motivacionais
  static Future<Map<String, dynamic>> getMotivationalStats() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    // Trabalhos da semana
    final weekResponse = await ApiService.getTrabalhos(dataInicio: startOfWeek, dataFim: now.add(const Duration(days: 1)));
    final weekWork = weekResponse.success && weekResponse.data?['trabalhos'] != null
        ? (weekResponse.data!['trabalhos'] as List).map((t) => TrabalhoModel.fromJson(t)).toList()
        : <TrabalhoModel>[];
    final weekEarnings = weekWork.fold<double>(0, (sum, t) => sum + t.ganhos);

    // Trabalhos do mês
    final monthResponse = await ApiService.getTrabalhos(dataInicio: startOfMonth, dataFim: DateTime(now.year, now.month + 1, 1));
    final monthWork = monthResponse.success && monthResponse.data?['trabalhos'] != null
        ? (monthResponse.data!['trabalhos'] as List).map((t) => TrabalhoModel.fromJson(t)).toList()
        : <TrabalhoModel>[];
    final monthEarnings = monthWork.fold<double>(0, (sum, t) => sum + t.ganhos);

    // Melhor dia do mês
    final bestDay = monthWork.isNotEmpty 
        ? monthWork.reduce((a, b) => a.ganhos > b.ganhos ? a : b) 
        : null;

    // Dias trabalhados no mês
    final diasTrabalhados = monthWork.map((t) => 
        DateTime(t.data.year, t.data.month, t.data.day)).toSet().length;

    return {
      'ganhos_semana': weekEarnings,
      'ganhos_mes': monthEarnings,
      'melhor_dia': bestDay?.ganhos ?? 0,
      'melhor_dia_data': bestDay?.data,
      'dias_trabalhados_mes': diasTrabalhados,
      'media_diaria_mes': diasTrabalhados > 0 ? monthEarnings / diasTrabalhados : 0,
    };
  }
}