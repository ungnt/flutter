import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class ManutencaoRoutes {
  final DatabaseService _databaseService;
  final AuthService _authService;

  ManutencaoRoutes(this._databaseService, this._authService);

  Router get router {
    final router = Router()
      ..post('/', _createManutencao)
      ..get('/', _getManutencoes)
      ..delete('/<id>', _deleteManutencao);
    
    return router;
  }

  Future<Response> _createManutencao(Request request) async {
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

      final manutencaoData = {
        'user_id': userId,
        'data': data['data'],
        'tipo': data['tipo'],
        'valor': data['valor'],
        'km_atual': data['km_atual'] ?? data['kmAtual'],
        'descricao': data['descricao'] ?? '',
        'data_registro': data['data_registro'] ?? DateTime.now().toIso8601String(),
      };

      final id = await _databaseService.createManutencao(manutencaoData);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Manutenção criada com sucesso',
          'data': {
            'id': id,
            ...manutencaoData,
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Erro ao criar manutenção: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getManutencoes(Request request) async {
    try {
      final userId = await _getUserFromToken(request);
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({'success': false, 'message': 'Não autorizado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final manutencoes = _databaseService.getManutencoesByUser(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': {'manutencao': manutencoes},
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Erro ao buscar manutenções: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteManutencao(Request request) async {
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

      _databaseService.deleteManutencao(id);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Manutenção deletada com sucesso',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Erro ao deletar manutenção: $e',
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
