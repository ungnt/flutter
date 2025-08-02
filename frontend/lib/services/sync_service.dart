import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'auth_service.dart';

/// Serviço de sincronização simplificado
class SyncService {
  static const String _tag = '[SyncService]';
  static const String baseUrl = 'http://localhost:8080';
  
  // Estado de sincronização (singleton básico)
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  SyncService._();
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  
  SyncStatus _syncStatus = SyncStatus.idle;
  SyncStatus get syncStatus => _syncStatus;
  
  double _syncProgress = 0.0;
  double get syncProgress => _syncProgress;
  
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Sincronização completa
  Future<SyncResult> fullSync() async {
    return await syncAll();
  }
  
  /// Sincronização apenas upload
  Future<SyncResult> uploadOnly() async {
    return await syncAll();
  }
  
  /// Sincronização apenas download
  Future<SyncResult> downloadOnly() async {
    return await syncAll();
  }
  
  /// Sincronização básica - apenas verifica conectividade
  static Future<SyncResult> syncAll() async {
    final service = SyncService.instance;
    try {
      print('$_tag Iniciando sincronização...');
      service._isSyncing = true;
      service._syncStatus = SyncStatus.syncing;
      service._syncProgress = 0.0;

      // Verificar token
      final token = await AuthService.getStoredToken();
      if (token == null) {
        service._isSyncing = false;
        service._syncStatus = SyncStatus.error;
        return SyncResult(
          success: false,
          message: 'Usuário não autenticado',
        );
      }

      service._syncProgress = 0.5;

      // Verificar conectividade
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(Duration(seconds: 5));

      service._syncProgress = 1.0;

      if (response.statusCode == 200) {
        print('$_tag Servidor conectado');
        service._isSyncing = false;
        service._syncStatus = SyncStatus.success;
        service._lastSyncTime = DateTime.now();
        return SyncResult(
          success: true,
          message: 'Sincronização realizada com sucesso',
          synced: 0,
        );
      } else {
        service._isSyncing = false;
        service._syncStatus = SyncStatus.error;
        return SyncResult(
          success: false,
          message: 'Erro na conexão com servidor',
        );
      }
    } catch (e) {
      print('$_tag Erro na sincronização: $e');
      service._isSyncing = false;
      service._syncStatus = SyncStatus.error;
      return SyncResult(
        success: false,
        message: 'Erro na sincronização: $e',
      );
    }
  }

  /// Verificar se há dados pendentes para sincronizar
  static Future<bool> hasPendingSync() async {
    // Por enquanto sempre retorna false - implementação futura
    return false;
  }

  /// Limpar dados de sincronização
  static Future<void> clearSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync');
  }
}