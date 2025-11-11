import 'local_session_service.dart';

class AuthService {
  static final _sessionService = LocalSessionService.instance;

  /// Obter token de autenticação armazenado
  static Future<String?> getToken() async {
    return _sessionService.getToken();
  }

  /// Alias para compatibilidade com sync_service
  static Future<String?> getStoredToken() async {
    return _sessionService.getToken();
  }

  /// Armazenar token de autenticação
  static Future<void> setToken(String token) async {
    return _sessionService.setToken(token);
  }

  /// Verificar se usuário está autenticado
  static Future<bool> isAuthenticated() async {
    return _sessionService.isAuthenticated();
  }

  /// Fazer logout (limpar tokens e dados locais da sessão)
  static Future<void> logout() async {
    await _sessionService.clearSession();
  }

  /// Obter email do usuário logado
  static Future<String?> getUserEmail() async {
    return _sessionService.getUserEmail();
  }

  /// Obter nome do usuário logado
  static Future<String?> getUserName() async {
    return _sessionService.getUserName();
  }

  /// Obter ID do usuário logado
  static Future<String?> getUserId() async {
    return _sessionService.getUserId();
  }

  /// Obter dados do usuário armazenados
  static Future<Map<String, dynamic>?> getUserData() async {
    return _sessionService.getUserData();
  }

  /// Armazenar dados do usuário
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    return _sessionService.setUserData(userData);
  }
}