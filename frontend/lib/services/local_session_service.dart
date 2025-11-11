import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço centralizado para gerenciar sessão local (token e dados do usuário)
/// Evita duplicação de código entre auth_service e api_service
class LocalSessionService {
  static final LocalSessionService _instance = LocalSessionService._internal();
  static LocalSessionService get instance => _instance;
  LocalSessionService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Obter token de autenticação armazenado
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Armazenar token de autenticação
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Obter dados do usuário armazenados
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return json.decode(userData) as Map<String, dynamic>;
    }
    return null;
  }

  /// Armazenar dados do usuário
  Future<void> setUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(userData));
  }

  /// Verificar se usuário está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Limpar toda a sessão (token e dados do usuário)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Obter email do usuário logado
  Future<String?> getUserEmail() async {
    final userData = await getUserData();
    return userData?['email'];
  }

  /// Obter nome do usuário logado
  Future<String?> getUserName() async {
    final userData = await getUserData();
    return userData?['name'];
  }

  /// Obter ID do usuário logado
  Future<String?> getUserId() async {
    final userData = await getUserData();
    return userData?['id'];
  }
}
