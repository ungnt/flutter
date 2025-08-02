import 'package:logging/logging.dart';

final _logger = Logger('DatabaseService');

// Classe simplificada - Supabase já gerencia a conexão PostgreSQL
class DatabaseService {
  static bool _initialized = false;
  
  /// Inicializar serviços de banco (Supabase já gerencia conexão)
  static Future<void> initialize() async {
    try {
      _logger.info('Usando Supabase - conexão PostgreSQL gerenciada automaticamente');
      _initialized = true;
    } catch (e) {
      _logger.severe('Erro ao inicializar Database Service: $e');
      rethrow;
    }
  }
  
  /// Verificar se está inicializado
  static bool get isInitialized => _initialized;
  
  /// Fechar não é necessário com Supabase
  static Future<void> close() async {
    _initialized = false;
    _logger.info('Database service desativado');
  }
  
  /// Status do banco (para health checks)
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'provider': 'Supabase PostgreSQL',
      'connection': 'Managed by Supabase SDK'
    };
  }
}