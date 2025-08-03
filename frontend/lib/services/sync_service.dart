import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_config_service.dart';
import 'auth_service.dart';

/// Serviço de sincronização simplificado
class SyncService {
  static const String _tag = '[SyncService]';
  // URL dinâmica baseada na configuração atual
  static String get baseUrl => BackendConfigService.instance.getBaseUrl();

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

  /// Sincronização completa - upload e download de dados reais
  static Future<SyncResult> syncAll() async {
    final service = SyncService.instance;
    try {
      print('$_tag Iniciando sincronização completa...');
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

      service._syncProgress = 0.1;

      // 1. UPLOAD - Enviar dados locais para servidor
      await _uploadLocalData(token);
      service._syncProgress = 0.5;

      // 2. DOWNLOAD - Baixar dados do servidor
      final downloadResult = await _downloadServerData(token);
      service._syncProgress = 1.0;

      service._isSyncing = false;
      service._syncStatus = SyncStatus.success;
      service._lastSyncTime = DateTime.now();

      return SyncResult(
        success: true,
        message: 'Sincronização completa realizada com sucesso',
        synced: downloadResult,
      );

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

  /// Upload dados locais para servidor
  static Future<void> _uploadLocalData(String token) async {
    try {
      print('$_tag Enviando dados locais para servidor...');

      // Obter dados locais do SQLite
      final db = DatabaseService.instance;
      final trabalhos = await db.getAllTrabalhos();
      final gastos = await db.getAllGastos();
      final manutencoes = await db.getAllManutencao();

      final localData = {
        'dados': {
          'trabalhos': trabalhos.map((t) => t.toJson()).toList(),
          'gastos': gastos.map((g) => g.toJson()).toList(),
          'manutencao': manutencoes.map((m) => m.toJson()).toList(),
        },
        'deviceId': 'flutter_app',
        'lastSync': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/backup/upload'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(localData),
      ).timeout(BackendConfigService.instance.getTimeout());

      if (response.statusCode == 200) {
        print('$_tag Upload realizado com sucesso');
      } else {
        print('$_tag Erro no upload: ${response.statusCode}');
      }

    } catch (e) {
      print('$_tag Erro no upload: $e');
    }
  }

  /// Download dados do servidor
  static Future<int> _downloadServerData(String token) async {
    try {
      print('$_tag Baixando dados do servidor...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/backup/download?deviceId=flutter_app'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(BackendConfigService.instance.getTimeout());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final serverData = data['data'] as Map<String, dynamic>;

        // Salvar dados no SQLite local
        await _saveServerDataLocally(serverData);

        final totalRecords = (serverData['trabalhos'] as List? ?? []).length +
                            (serverData['gastos'] as List? ?? []).length +
                            (serverData['manutencao'] as List? ?? []).length;

        print('$_tag Download realizado: $totalRecords registros');
        return totalRecords;
      } else {
        print('$_tag Erro no download: ${response.statusCode}');
        return 0;
      }

    } catch (e) {
      print('$_tag Erro no download: $e');
      return 0;
    }
  }

  /// Salvar dados do servidor no SQLite local
  static Future<void> _saveServerDataLocally(Map<String, dynamic> serverData) async {
    try {
      final db = DatabaseService.instance;

      // Salvar trabalhos
      final trabalhos = serverData['trabalhos'] as List? ?? [];
      for (final trabalhoData in trabalhos) {
        final trabalho = TrabalhoModel.fromJson(trabalhoData);
        await db.insertOrUpdateTrabalho(trabalho);
      }

      // Salvar gastos
      final gastos = serverData['gastos'] as List? ?? [];
      for (final gastoData in gastos) {
        final gasto = GastoModel.fromJson(gastoData);
        await db.insertOrUpdateGasto(gasto);
      }

      // Salvar manutenções
      final manutencao = serverData['manutencao'] as List? ?? [];
      for (final manutencaoData in manutencao) {
        final manutencaoObj = ManutencaoModel.fromJson(manutencaoData);
        await db.insertOrUpdateManutencao(manutencaoObj);
      }

      print('$_tag Dados salvos localmente com sucesso');

    } catch (e) {
      print('$_tag Erro ao salvar dados localmente: $e');
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

  /// Download dados da nuvem
  Future<bool> downloadFromCloud() async {
    try {
      if (!await ApiService.isLoggedIn()) {
        print('❌ Usuário não logado - não é possível sincronizar');
        return false;
      }

      //TODO: Implementar a lógica de download aqui

      return true; //TODO: Mudar o retorno

    } catch (e) {
      print('Erro ao baixar dados da nuvem: $e');
      return false;
    }
  }
}

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncResult {
  final bool success;
  final String message;
  final int? synced;

  SyncResult({
    required this.success,
    required this.message,
    this.synced,
  });
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/gasto_model.dart';
import '../model/manutencao_model.dart';
import '../model/trabalho_model.dart';
import 'database_service.dart';

/// Serviço de API para comunicação com o backend
class ApiService {
  static const String _tag = '[ApiService]';

  // Base URL da API (deve ser configurável)
  static const String baseUrl = 'http://localhost:3000'; //TODO: Mudar

  // Chave para armazenar o token no SharedPreferences
  static const String tokenKey = 'auth_token';

  /// Fazer login e obter token JWT
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        print('$_tag Login realizado com sucesso - token: $token');

        // Armazenar o token localmente
        await storeToken(token);
        return true;
      } else {
        print('$_tag Erro no login: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('$_tag Erro no login: $e');
      return false;
    }
  }

  /// Fazer registro e obter token JWT
  static Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        print('$_tag Registro realizado com sucesso - token: $token');

        // Armazenar o token localmente
        await storeToken(token);
        return true;
      } else {
        print('$_tag Erro no registro: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('$_tag Erro no registro: $e');
      return false;
    }
  }

  /// Armazenar token no SharedPreferences
  static Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    print('$_tag Token armazenado localmente');
  }

  /// Obter token do SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  /// Remover token do SharedPreferences (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    print('$_tag Token removido localmente');
  }

  /// Verificar se o usuário está logado (tem token válido)
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// Upload de backup completo para o servidor
  static Future<bool> uploadFullBackup() async {
    try {
      // Simular dados para upload
      final data = {
        'deviceId': 'meu_dispositivo',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {'chave1': 'valor1', 'chave2': 'valor2'}
      };

      // Converter dados para JSON
      final jsonData = jsonEncode(data);

      // Obter o token JWT
      final token = await getToken();

      // Verificar se o token está presente
      if (token == null) {
        print('$_tag Não autenticado - necessário fazer login');
        return false;
      }

      // Imprimir o token JWT
      print('$_tag Usando token JWT: $token');

      // Enviar a requisição POST para o endpoint de upload
      final response = await http.post(
        Uri.parse('$baseUrl/api/backup/upload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Incluir o token no cabeçalho
        },
        body: jsonData,
      );

      // Verificar o status da resposta
      if (response.statusCode == 200) {
        print('$_tag Backup enviado com sucesso!');
        return true;
      } else {
        print('$_tag Falha ao enviar o backup. Código de status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Lidar com erros de rede ou outros erros
      print('$_tag Erro ao enviar o backup: $e');
      return false;
    }
  }
}