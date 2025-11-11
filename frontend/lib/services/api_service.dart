import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_config_service.dart';
import 'local_session_service.dart';

class ApiService {
  static String get _baseUrl => BackendConfigService.instance.getBaseUrl();
  static String _getEndpointUrl(String endpoint) {
    final base = BackendConfigService.instance.getBaseUrl();
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$base/api/$cleanEndpoint';
  }
  static Duration get _timeout => BackendConfigService.instance.getTimeout();
  
  static final _sessionService = LocalSessionService.instance;

  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> get _authHeaders async {
    final token = await _sessionService.getToken();
    return {
      ..._defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> getToken() async {
    return _sessionService.getToken();
  }

  static Future<void> saveToken(String token) async {
    return _sessionService.setToken(token);
  }

  static Future<void> removeToken() async {
    return _sessionService.clearSession();
  }

  static Future<bool> isLoggedIn() async {
    return _sessionService.isAuthenticated();
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    return _sessionService.getUserData();
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    return _sessionService.setUserData(userData);
  }

  static Future<void> clearUserData() async {
    return _sessionService.clearSession();
  }

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
      await removeToken();
      await clearUserData();
      
      return ApiResponse(
        success: true,
        message: 'Logout realizado com sucesso',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao fazer logout: $e',
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

  static Future<ApiResponse> getTrabalhos() async {
    try {
      final response = await http.get(
        Uri.parse(_getEndpointUrl('trabalho/')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao buscar trabalhos: $e',
      );
    }
  }

  static Future<ApiResponse> createTrabalho(Map<String, dynamic> trabalho) async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('trabalho/')),
        headers: await _authHeaders,
        body: jsonEncode(trabalho),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao criar trabalho: $e',
      );
    }
  }

  static Future<ApiResponse> updateTrabalho(String id, Map<String, dynamic> trabalho) async {
    try {
      final response = await http.put(
        Uri.parse(_getEndpointUrl('trabalho/$id')),
        headers: await _authHeaders,
        body: jsonEncode(trabalho),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao atualizar trabalho: $e',
      );
    }
  }

  static Future<ApiResponse> deleteTrabalho(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(_getEndpointUrl('trabalho/$id')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao deletar trabalho: $e',
      );
    }
  }

  static Future<ApiResponse> getGastos() async {
    try {
      final response = await http.get(
        Uri.parse(_getEndpointUrl('gastos/')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao buscar gastos: $e',
      );
    }
  }

  static Future<ApiResponse> createGasto(Map<String, dynamic> gasto) async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('gastos/')),
        headers: await _authHeaders,
        body: jsonEncode(gasto),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao criar gasto: $e',
      );
    }
  }

  static Future<ApiResponse> updateGasto(String id, Map<String, dynamic> gasto) async {
    try {
      final response = await http.put(
        Uri.parse(_getEndpointUrl('gastos/$id')),
        headers: await _authHeaders,
        body: jsonEncode(gasto),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao atualizar gasto: $e',
      );
    }
  }

  static Future<ApiResponse> deleteGasto(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(_getEndpointUrl('gastos/$id')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao deletar gasto: $e',
      );
    }
  }

  static Future<ApiResponse> getManutencoes() async {
    try {
      final response = await http.get(
        Uri.parse(_getEndpointUrl('manutencao/')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao buscar manutenções: $e',
      );
    }
  }

  static Future<ApiResponse> createManutencao(Map<String, dynamic> manutencao) async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl('manutencao/')),
        headers: await _authHeaders,
        body: jsonEncode(manutencao),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao criar manutenção: $e',
      );
    }
  }

  static Future<ApiResponse> updateManutencao(String id, Map<String, dynamic> manutencao) async {
    try {
      final response = await http.put(
        Uri.parse(_getEndpointUrl('manutencao/$id')),
        headers: await _authHeaders,
        body: jsonEncode(manutencao),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao atualizar manutenção: $e',
      );
    }
  }

  static Future<ApiResponse> deleteManutencao(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(_getEndpointUrl('manutencao/$id')),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro ao deletar manutenção: $e',
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

  // Helpers genéricos para CRUD
  static Future<ApiResponse> post({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_getEndpointUrl(endpoint)),
        headers: await _authHeaders,
        body: jsonEncode(data),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro na requisição: $e',
      );
    }
  }

  static Future<ApiResponse> get({required String endpoint}) async {
    try {
      final response = await http.get(
        Uri.parse(_getEndpointUrl(endpoint)),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro na requisição: $e',
      );
    }
  }

  static Future<ApiResponse> delete({required String endpoint}) async {
    try {
      final response = await http.delete(
        Uri.parse(_getEndpointUrl(endpoint)),
        headers: await _authHeaders,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro na requisição: $e',
      );
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