import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class TrabalhoRoutes {
  final DatabaseService _databaseService;
  final AuthService _authService;

  TrabalhoRoutes(this._databaseService, this._authService);

  Router get router {
    final router = Router()
      ..post('/', _createTrabalho)
      ..get('/', _getTrabalhos)
      ..delete('/<id>', _deleteTrabalho);
    
    return router;
  }

  Future<Response> _createTrabalho(Request request) async {
    try {
      final userId = await _getUserFromToken(request);
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({'success': false, 'message': 'Não autorizado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final trabalhoData = {
        'user_id': userId,
        'data': data['data'],
        'ganhos': data['ganhos'],
        'km': data['km'],
        'horas': data['horas'],
        'observacoes': data['observacoes'] ?? '',
        'data_registro': data['data_registro'] ?? DateTime.now().toIso8601String(),
      };

      final id = await _databaseService.createTrabalho(trabalhoData);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Trabalho criado com sucesso',
          'data': {
            'id': id,
            ...trabalhoData,
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Erro ao criar trabalho: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getTrabalhos(Request request) async {
    try {
      final userId = await _getUserFromToken(request);
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({'success': false, 'message': 'Não autorizado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final trabalhos = _databaseService.getTrabalhosByUser(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': {'trabalhos': trabalhos},
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Erro ao buscar trabalhos: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteTrabalho(Request request) async {
    try {
      final userId = await _getUserFromToken(request);
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({'success': false, 'message': 'Não autorizado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final id = request.params['id'];
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'ID não fornecido'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final affectedRows = _databaseService.deleteTrabalho(id, userId);

      if (affectedRows == 0) {
        return Response.notFound(
          jsonEncode({'success': false, 'message': 'Trabalho não encontrado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Trabalho deletado com sucesso',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Erro ao deletar trabalho: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<String?> _getUserFromToken(Request request) async {
    final token = request.headers['authorization']?.replaceFirst('Bearer ', '');
    if (token == null) return null;

    try {
      final payload = _authService.validateJWT(token);
      return payload?['user_id'];
    } catch (e) {
      return null;
    }
  }
}
