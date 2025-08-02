import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_config_service.dart';

class ApiService {
  // URL dinâmica baseada na configuração atual
  static String get _baseUrl => BackendConfigService.instance.getBaseUrl();
  static String _getEndpointUrl(String endpoint) => BackendConfigService.instance.getEndpointUrl(endpoint);
  static Duration get _timeout => BackendConfigService.instance.getTimeout();
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Headers padrão
  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers com autorização
  static Future<Map<String, String>> get _authHeaders async {
    final token = await getToken();
    return {
      ..._defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Gerenciamento de token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Gerenciamento de usuário
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Autenticação
  static Future<ApiResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('auth/register')),
        headers: _defaultHeaders,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('auth/login')),
        headers: _defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(_timeout);

      final result = _handleResponse(response);
      
      // Salvar token e dados do usuário se login foi bem-sucedido
      if (result.success && result.data != null) {
        if (result.data!['token'] != null) {
          await saveToken(result.data!['token']);
        }
        if (result.data!['user'] != null) {
          await saveUserData(result.data!['user']);
        }
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

  static Future<ApiResponse> logout() async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('auth/logout')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      // Limpar dados locais
      await removeToken();
      await clearUserData();
      
      return _handleResponse(response);
    } catch (e) {
      // Mesmo que falhe no servidor, remove token localmente
      await removeToken();
      await clearUserData();
      
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

  static Future<ApiResponse> getMe() async {
    try {
      final response = await http.get(
        Uri.parse(_getEndpointUrl('auth/me')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      final result = _handleResponse(response);
      
      // Atualizar dados do usuário se bem-sucedido
      if (result.success && result.data != null) {
        await saveUserData(result.data!);
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

  // Premium
  static Future<ApiResponse> checkPremiumStatus() async {
    try {
      final response = await http.get(
        Uri.parse(_getEndpointUrl('premium/status')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

  static Future<ApiResponse> createPremiumSubscription() async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('premium/subscribe')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

  static Future<ApiResponse> cancelPremiumSubscription() async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('premium/cancel')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

  // CRUD APIs - Trabalho
  static Future<ApiResponse> uploadTrabalhos(List<Map<String, dynamic>> trabalhos) async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('trabalho/sync')),
        headers: await _authHeaders,
        body: jsonEncode({'trabalhos': trabalhos}),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao sincronizar trabalhos: $e',
      );
    }
  }

  static Future<ApiResponse> downloadTrabalhos() async {
    try {
      final response = await http.get(
        Uri.parse(_getEndpointUrl('trabalho/')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao baixar trabalhos: $e',
      );
    }
  }

  // CRUD APIs - Gastos
  static Future<ApiResponse> uploadGastos(List<Map<String, dynamic>> gastos) async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('gastos/sync')),
        headers: await _authHeaders,
        body: jsonEncode({'gastos': gastos}),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao sincronizar gastos: $e',
      );
    }
  }

  static Future<ApiResponse> downloadGastos() async {
    try {
      final response = await http.get(
        Uri.parse(_getEndpointUrl('gastos/')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao baixar gastos: $e',
      );
    }
  }

  // CRUD APIs - Manutenções
  static Future<ApiResponse> uploadManutencao(List<Map<String, dynamic>> manutencoes) async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('manutencao/sync')),
        headers: await _authHeaders,
        body: jsonEncode({'manutencao': manutencoes}),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao sincronizar manutenções: $e',
      );
    }
  }

  static Future<ApiResponse> downloadManutencoes() async {
    try {
      final response = await http.get(
        Uri.parse(_getEndpointUrl('manutencao/')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao baixar manutenções: $e',
      );
    }
  }

  // Backup Completo (todos os dados)
  static Future<ApiResponse> uploadFullBackup(Map<String, dynamic> backupData) async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('backup/upload')),
        headers: await _authHeaders,
        body: jsonEncode(backupData),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro no backup completo: $e',
      );
    }
  }

  static Future<ApiResponse> downloadFullBackup() async {
    try {
      final response = await http.get(
        Uri.parse(_getEndpointUrl('backup/download')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao baixar backup: $e',
      );
    }
  }

  // Helper para processar respostas
  static ApiResponse _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        message: data['message'] as String? ?? 'Operação realizada',
        data: data,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: response.statusCode,
        message: 'Erro ao processar resposta: $e',
      );
    }
  }

  // Verificar conectividade
  static Future<bool> isOnline() async {
    try {
      final healthUrl = '${_baseUrl}/health';
      final response = await http.get(
        Uri.parse(healthUrl),
        headers: _defaultHeaders,
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class ApiResponse {
  final bool success;
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? data;

  ApiResponse({
    required this.success,
    this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() {
    return 'ApiResponse(success: $success, statusCode: $statusCode, message: $message)';
  }
}