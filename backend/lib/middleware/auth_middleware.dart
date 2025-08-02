import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import '../services/auth_service.dart';

final _logger = Logger('AuthMiddleware');

/// Middleware para validar JWT em rotas protegidas
Middleware authMiddleware(AuthService authService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // Extrair token do header Authorization
      final authHeader = request.headers['authorization'];
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        _logger.warning('Token não fornecido');
        return Response.unauthorized(
          '{"error": "UNAUTHORIZED", "message": "Token de acesso requerido"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final token = authHeader.substring(7); // Remove 'Bearer '
      
      // Validar token
      final payload = authService.validateJWT(token);
      if (payload == null) {
        _logger.warning('Token inválido ou expirado');
        return Response.unauthorized(
          '{"error": "INVALID_TOKEN", "message": "Token inválido ou expirado"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Adicionar dados do usuário ao contexto da requisição
      final updatedRequest = request.change(context: {
        'user_id': payload['user_id'],
        'user_email': payload['email'],
        'is_premium': payload['is_premium'],
        'token_payload': payload,
      });
      
      return await innerHandler(updatedRequest);
    };
  };
}

/// Classe helper para facilitar acesso aos dados do usuário nas rotas
class AuthMiddleware {
  /// Extrai o user_id do contexto da requisição (após middleware de auth)
  static String? getUserId(Request request) {
    return request.context['user_id'] as String?;
  }

  /// Extrai o email do usuário do contexto da requisição
  static String? getUserEmail(Request request) {
    return request.context['user_email'] as String?;
  }

  /// Verifica se o usuário é premium
  static bool isPremium(Request request) {
    return (request.context['is_premium'] as bool?) ?? false;
  }

  /// Aplica middleware de autenticação a um router
  static Handler middleware(Handler handler, {required AuthService authService}) {
    return authMiddleware(authService)(handler);
  }
}

/// Middleware para validar apenas usuários Premium
Middleware premiumMiddleware(AuthService authService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // Primeiro, validar autenticação
      final authResult = await authMiddleware(authService)(innerHandler)(request);
      
      // Se não passou na auth, retornar erro de auth
      if (authResult.statusCode == 401) {
        return authResult;
      }
      
      // Verificar se é Premium
      final isPremium = request.context['is_premium'] as bool? ?? false;
      
      if (!isPremium) {
        _logger.warning('Acesso negado - usuário não Premium: ${request.context['user_email']}');
        return Response.forbidden(
          '{"error": "PREMIUM_REQUIRED", "message": "Esta funcionalidade requer conta Premium"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      return await innerHandler(request);
    };
  };
}