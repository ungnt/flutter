import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../middleware/auth_middleware.dart';

final _logger = Logger('AuthRoutes');

class AuthRoutes {
  final AuthService _authService;
  
  AuthRoutes(this._authService);

  Router get router {
    final router = Router()
      ..post('/register', _registerHandler)
      ..post('/login', _loginHandler) 
      ..get('/me', Pipeline()
          .addMiddleware(authMiddleware(_authService))
          .addHandler(_meHandler));

    return router;
  }

  /// POST /api/auth/register
  /// Cadastrar novo usuário
  Future<Response> _registerHandler(Request request) async {
    try {
      _logger.info('Tentativa de registro');
      
      final body = await request.readAsString();
      if (body.isEmpty) {
        return Response.badRequest(
          body: '{"error": "BAD_REQUEST", "message": "Dados não fornecidos"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final json = jsonDecode(body);
      final registerRequest = RegisterRequest.fromJson(json);
      
      // Validações básicas
      if (registerRequest.email.isEmpty || !_isValidEmail(registerRequest.email)) {
        return Response.badRequest(
          body: '{"error": "INVALID_EMAIL", "message": "Email inválido"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      if (registerRequest.password.length < 6) {
        return Response.badRequest(
          body: '{"error": "WEAK_PASSWORD", "message": "Senha deve ter pelo menos 6 caracteres"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      if (registerRequest.name.trim().isEmpty) {
        return Response.badRequest(
          body: '{"error": "INVALID_NAME", "message": "Nome é obrigatório"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Tentar registrar
      final authResponse = await _authService.register(registerRequest);
      
      if (authResponse == null) {
        return Response(409, // Conflict
          body: '{"error": "EMAIL_EXISTS", "message": "Este email já está cadastrado"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      _logger.info('Usuário registrado com sucesso: ${authResponse.user.email}');
      
      return Response.ok(
        jsonEncode(authResponse.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e, stack) {
      _logger.severe('Erro no registro: $e', e, stack);
      return Response.internalServerError(
        body: '{"error": "INTERNAL_ERROR", "message": "Erro interno do servidor"}',
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/auth/login
  /// Login do usuário
  Future<Response> _loginHandler(Request request) async {
    try {
      _logger.info('Tentativa de login');
      
      final body = await request.readAsString();
      if (body.isEmpty) {
        return Response.badRequest(
          body: '{"error": "BAD_REQUEST", "message": "Dados não fornecidos"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final json = jsonDecode(body);
      final loginRequest = LoginRequest.fromJson(json);
      
      // Tentar fazer login
      final authResponse = await _authService.login(loginRequest);
      
      if (authResponse == null) {
        return Response.unauthorized(
          '{"error": "INVALID_CREDENTIALS", "message": "Email ou senha incorretos"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      _logger.info('Login bem-sucedido: ${authResponse.user.email}');
      
      return Response.ok(
        jsonEncode(authResponse.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e, stack) {
      _logger.severe('Erro no login: $e', e, stack);
      return Response.internalServerError(
        body: '{"error": "INTERNAL_ERROR", "message": "Erro interno do servidor"}',
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/auth/me
  /// Obter perfil do usuário autenticado
  Future<Response> _meHandler(Request request) async {
    try {
      final userId = request.context['user_id'] as String;
      final user = await _authService.getUserFromToken(
        request.headers['authorization']!.substring(7)
      );
      
      if (user == null) {
        return Response.unauthorized(
          '{"error": "USER_NOT_FOUND", "message": "Usuário não encontrado"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      return Response.ok(
        jsonEncode(user.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e, stack) {
      _logger.severe('Erro ao buscar dados do usuário: $e', e, stack);
      return Response.internalServerError(
        body: '{"error": "INTERNAL_ERROR", "message": "Erro interno do servidor"}',
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }
}