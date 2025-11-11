import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardCacheService {
  static final DashboardCacheService _instance = DashboardCacheService._internal();
  static DashboardCacheService get instance => _instance;
  DashboardCacheService._internal();

  static const String _dadosHojeKey = 'dashboard_dados_hoje';
  static const String _dadosMesKey = 'dashboard_dados_mes';
  static const String _ultimosRegistrosKey = 'dashboard_ultimos_registros';
  static const String _lastUpdateKey = 'dashboard_last_update';

  Future<void> saveDashboardData({
    required Map<String, double> dadosHoje,
    required Map<String, double> dadosMes,
    required List<Map<String, dynamic>> ultimosRegistros,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_dadosHojeKey, json.encode(dadosHoje));
      await prefs.setString(_dadosMesKey, json.encode(dadosMes));
      
      final registrosSanitized = ultimosRegistros.map((r) {
        final copy = Map<String, dynamic>.from(r);
        if (copy['data'] is DateTime) {
          copy['data'] = (copy['data'] as DateTime).toIso8601String();
        }
        return copy;
      }).toList();
      
      await prefs.setString(_ultimosRegistrosKey, json.encode(registrosSanitized));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Erro ao salvar cache do dashboard: $e');
    }
  }

  Future<Map<String, dynamic>?> loadDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final dadosHojeJson = prefs.getString(_dadosHojeKey);
      final dadosMesJson = prefs.getString(_dadosMesKey);
      final ultimosRegistrosJson = prefs.getString(_ultimosRegistrosKey);
      final lastUpdateJson = prefs.getString(_lastUpdateKey);
      
      if (dadosHojeJson == null || dadosMesJson == null) {
        return null;
      }
      
      final dadosHoje = Map<String, double>.from(json.decode(dadosHojeJson));
      final dadosMes = Map<String, double>.from(json.decode(dadosMesJson));
      
      List<Map<String, dynamic>> ultimosRegistros = [];
      if (ultimosRegistrosJson != null) {
        final registrosList = json.decode(ultimosRegistrosJson) as List<dynamic>;
        ultimosRegistros = registrosList.map((r) {
          final registro = Map<String, dynamic>.from(r);
          if (registro['data'] is String) {
            registro['data'] = DateTime.parse(registro['data'] as String);
          }
          return registro;
        }).toList();
      }
      
      DateTime? lastUpdate;
      if (lastUpdateJson != null) {
        lastUpdate = DateTime.parse(lastUpdateJson);
      }
      
      return {
        'dadosHoje': dadosHoje,
        'dadosMes': dadosMes,
        'ultimosRegistros': ultimosRegistros,
        'lastUpdate': lastUpdate,
      };
    } catch (e) {
      print('Erro ao carregar cache do dashboard: $e');
      return null;
    }
  }

  Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateJson = prefs.getString(_lastUpdateKey);
      if (lastUpdateJson != null) {
        return DateTime.parse(lastUpdateJson);
      }
    } catch (e) {
      print('Erro ao obter data da última atualização: $e');
    }
    return null;
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dadosHojeKey);
      await prefs.remove(_dadosMesKey);
      await prefs.remove(_ultimosRegistrosKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      print('Erro ao limpar cache do dashboard: $e');
    }
  }
}
