import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class GastosRoutes {
  final DatabaseService _databaseService;
  final AuthService _authService;

  GastosRoutes(this._databaseService, this._authService);

  Router get router {
    final router = Router()
      ..post('/', _createGasto)
      ..get('/', _getGastos)
      ..delete('/<id>', _deleteGasto);
    
    return router;
  }

  Future<Response> _createGasto(Request request) async {
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

      final gastoData = {
        'user_id': userId,
        'data': data['data'],
        'categoria': data['categoria'],
        'valor': data['valor'],
        'descricao': data['descricao'] ?? '',
        'data_registro': data['data_registro'] ?? DateTime.now().toIso8601String(),
      };

      final id = await _databaseService.createGasto(gastoData);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Gasto criado com sucesso',
          'data': {
            'id': id,
            ...gastoData,
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Erro ao criar gasto: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getGastos(Request request) async {
    try {
      final userId = await _getUserFromToken(request);
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({'success': false, 'message': 'Não autorizado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final gastos = _databaseService.getGastosByUser(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': {'gastos': gastos},
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Erro ao buscar gastos: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteGasto(Request request) async {
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

      final affectedRows = _databaseService.deleteGasto(id, userId);

      if (affectedRows == 0) {
        return Response.notFound(
          jsonEncode({'success': false, 'message': 'Gasto não encontrado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Gasto deletado com sucesso',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Erro ao deletar gasto: $e',
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
