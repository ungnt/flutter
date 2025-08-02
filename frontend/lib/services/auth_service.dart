import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Estados de sincronização
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Resultado das operações de sincronização
class SyncResult {
  final bool success;
  final String message;
  final int? synced;
  final int? conflicts;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.synced,
    this.conflicts,
    this.errors = const [],
  });
}

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Obter token de autenticação armazenado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Alias para compatibilidade com sync_service
  static Future<String?> getStoredToken() async {
    return getToken();
  }

  /// Armazenar token de autenticação
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Remover token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Verificar se usuário está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Obter dados do usuário armazenados
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return json.decode(userData);
    }
    return null;
  }

  /// Armazenar dados do usuário
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(userData));
  }
}