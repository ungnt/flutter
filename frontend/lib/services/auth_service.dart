import 'database_service.dart';
import 'local_session_service.dart';

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

/// Serviço de autenticação que delega gerenciamento de sessão para LocalSessionService
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

  /// Fazer logout (limpar dados locais, tokens e banco de dados)
  static Future<void> logout() async {
    await _sessionService.clearSession();
    await DatabaseService.instance.clearAllData();
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