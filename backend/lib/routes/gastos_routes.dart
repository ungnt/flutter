import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';
import '../models/gasto_model.dart';
import '../services/supabase_service.dart';
import '../services/security_service.dart';
import '../services/conflict_resolution_service.dart';
import '../middleware/auth_middleware.dart';

final _logger = Logger('GastosRoutes');

class GastosRoutes {
  static Router get router {
    final router = Router();

    // GET /api/gastos - Listar gastos do usuário
    router.get('/', _getGastos);
    
    // POST /api/gastos - Criar novo gasto
    router.post('/', _createGasto);
    
    // PUT /api/gastos/<id> - Atualizar gasto
    router.put('/<id>', _updateGasto);
    
    // DELETE /api/gastos/<id> - Deletar gasto
    router.delete('/<id>', _deleteGasto);
    
    // GET /api/gastos/periodo - Gastos por período
    router.get('/periodo', _getGastosPorPeriodo);
    
    // GET /api/gastos/categorias - Gastos agrupados por categoria
    router.get('/categorias', _getGastosPorCategoria);

    return router;
  }

  static Future<Response> _getGastos(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      _logger.info('Listando gastos para usuário: $userId');

      final response = await SupabaseService.client
          .from('gastos')
          .select()
          .eq('user_id', userId)
          .order('data', ascending: false);

      final gastos = (response as List)
          .map((json) => GastoModel.fromJson(json).toJson())
          .toList();

      _logger.info('${gastos.length} gastos encontrados');

      return Response.ok(
        json.encode({'gastos': gastos}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao listar gastos: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _createGasto(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      // Validações
      if (data['data'] == null || data['categoria'] == null || data['valor'] == null) {
        return Response(400, body: json.encode({
          'error': 'Campos obrigatórios: data, categoria, valor'
        }));
      }

      final agora = DateTime.now();
      final gasto = GastoModel(
        userId: userId,
        data: DateTime.parse(data['data']),
        categoria: data['categoria'].toString(),
        valor: (data['valor'] as num).toDouble(),
        descricao: data['descricao']?.toString(),
        dataRegistro: agora,
      );

      _logger.info('Criando gasto para usuário: $userId');

      final response = await SupabaseService.client
          .from('gastos')
          .insert(gasto.toJson())
          .select()
          .single();

      final gastoCreated = GastoModel.fromJson(response);

      _logger.info('Gasto criado com sucesso: ${gastoCreated.id}');

      return Response(201,
        body: json.encode({
          'message': 'Gasto criado com sucesso',
          'gasto': gastoCreated.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao criar gasto: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _updateGasto(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      final id = request.params['id'];
      if (id == null) {
        return Response(400, body: json.encode({'error': 'ID obrigatório'}));
      }

      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      // Verificar se o gasto pertence ao usuário
      final existing = await SupabaseService.client
          .from('gastos')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        return Response(404, body: json.encode({'error': 'Gasto não encontrado'}));
      }

      // Preparar dados para atualização
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (data['data'] != null) updateData['data'] = data['data'];
      if (data['categoria'] != null) updateData['categoria'] = data['categoria'];
      if (data['valor'] != null) updateData['valor'] = (data['valor'] as num).toDouble();
      if (data['descricao'] != null) updateData['descricao'] = data['descricao'];

      _logger.info('Atualizando gasto: $id');

      final response = await SupabaseService.client
          .from('gastos')
          .update(updateData)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      final gastoUpdated = GastoModel.fromJson(response);

      _logger.info('Gasto atualizado com sucesso: $id');

      return Response.ok(
        json.encode({
          'message': 'Gasto atualizado com sucesso',
          'gasto': gastoUpdated.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao atualizar gasto: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _deleteGasto(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      final id = request.params['id'];
      if (id == null) {
        return Response(400, body: json.encode({'error': 'ID obrigatório'}));
      }

      // Verificar se o gasto pertence ao usuário
      final existing = await SupabaseService.client
          .from('gastos')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        return Response(404, body: json.encode({'error': 'Gasto não encontrado'}));
      }

      _logger.info('Deletando gasto: $id');

      await SupabaseService.client
          .from('gastos')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      _logger.info('Gasto deletado com sucesso: $id');

      return Response.ok(
        json.encode({'message': 'Gasto deletado com sucesso'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao deletar gasto: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _getGastosPorPeriodo(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      final params = request.url.queryParameters;
      final dataInicio = params['data_inicio'];
      final dataFim = params['data_fim'];

      if (dataInicio == null || dataFim == null) {
        return Response(400, body: json.encode({
          'error': 'Parâmetros obrigatórios: data_inicio, data_fim'
        }));
      }

      _logger.info('Buscando gastos por período: $dataInicio - $dataFim');

      final response = await SupabaseService.client
          .from('gastos')
          .select()
          .eq('user_id', userId)
          .gte('data', dataInicio)
          .lte('data', dataFim)
          .order('data', ascending: false);

      final gastos = (response as List)
          .map((json) => GastoModel.fromJson(json).toJson())
          .toList();

      _logger.info('${gastos.length} gastos encontrados no período');

      return Response.ok(
        json.encode({'gastos': gastos}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao buscar gastos por período: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _getGastosPorCategoria(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      final params = request.url.queryParameters;
      final dataInicio = params['data_inicio'];
      final dataFim = params['data_fim'];

      _logger.info('Buscando gastos por categoria');

      // Query com filtro de período opcional
      var query = SupabaseService.client
          .from('gastos')
          .select('categoria, valor')
          .eq('user_id', userId);

      if (dataInicio != null && dataFim != null) {
        query = query.gte('data', dataInicio).lte('data', dataFim);
      }

      final response = await query;

      // Agrupar por categoria
      final Map<String, double> categorias = {};
      for (final gasto in response) {
        final categoria = gasto['categoria'] as String;
        final valor = (gasto['valor'] as num).toDouble();
        categorias[categoria] = (categorias[categoria] ?? 0) + valor;
      }

      final resultado = categorias.entries
          .map((entry) => {
                'categoria': entry.key,
                'total': entry.value,
              })
          .toList();

      _logger.info('${resultado.length} categorias encontradas');

      return Response.ok(
        json.encode({'categorias': resultado}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao buscar gastos por categoria: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }
}