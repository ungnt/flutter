import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';
import '../models/manutencao_model.dart';
import '../services/supabase_service.dart';
import '../services/security_service.dart';
import '../services/conflict_resolution_service.dart';
import '../middleware/auth_middleware.dart';

final _logger = Logger('ManutencaoRoutes');

class ManutencaoRoutes {
  static Router get router {
    final router = Router();

    // GET /api/manutencao - Listar manutenções do usuário
    router.get('/', _getManutencoes);
    
    // POST /api/manutencao - Criar nova manutenção
    router.post('/', _createManutencao);
    
    // PUT /api/manutencao/<id> - Atualizar manutenção
    router.put('/<id>', _updateManutencao);
    
    // DELETE /api/manutencao/<id> - Deletar manutenção
    router.delete('/<id>', _deleteManutencao);
    
    // GET /api/manutencao/periodo - Manutenções por período
    router.get('/periodo', _getManutencoesPorPeriodo);
    
    // GET /api/manutencao/tipos - Manutenções agrupadas por tipo
    router.get('/tipos', _getManutencoesPorTipo);

    return router;
  }

  static Future<Response> _getManutencoes(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      _logger.info('Listando manutenções para usuário: $userId');

      final response = await SupabaseService.client
          .from('manutencoes')
          .select()
          .eq('user_id', userId)
          .order('data', ascending: false);

      final manutencoes = (response as List)
          .map((json) => ManutencaoModel.fromJson(json).toJson())
          .toList();

      _logger.info('${manutencoes.length} manutenções encontradas');

      return Response.ok(
        json.encode({'manutencoes': manutencoes}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao listar manutenções: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _createManutencao(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      // Validações
      if (data['data'] == null || data['tipo'] == null || 
          data['valor'] == null || data['quilometragem'] == null) {
        return Response(400, body: json.encode({
          'error': 'Campos obrigatórios: data, tipo, valor, quilometragem'
        }));
      }

      final agora = DateTime.now();
      final manutencao = ManutencaoModel(
        userId: userId,
        data: DateTime.parse(data['data']),
        tipo: data['tipo'].toString(),
        valor: (data['valor'] as num).toDouble(),
        kmAtual: (data['quilometragem'] as num).toDouble(),
        descricao: data['descricao']?.toString(),
        dataRegistro: agora,
      );

      _logger.info('Criando manutenção para usuário: $userId');

      final response = await SupabaseService.client
          .from('manutencoes')
          .insert(manutencao.toJson())
          .select()
          .single();

      final manutencaoCreated = ManutencaoModel.fromJson(response);

      _logger.info('Manutenção criada com sucesso: ${manutencaoCreated.id}');

      return Response(201,
        body: json.encode({
          'message': 'Manutenção criada com sucesso',
          'manutencao': manutencaoCreated.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao criar manutenção: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _updateManutencao(Request request) async {
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

      // Verificar se a manutenção pertence ao usuário
      final existing = await SupabaseService.client
          .from('manutencoes')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        return Response(404, body: json.encode({'error': 'Manutenção não encontrada'}));
      }

      // Preparar dados para atualização
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (data['data'] != null) updateData['data'] = data['data'];
      if (data['tipo'] != null) updateData['tipo'] = data['tipo'];
      if (data['valor'] != null) updateData['valor'] = (data['valor'] as num).toDouble();
      if (data['quilometragem'] != null) updateData['quilometragem'] = (data['quilometragem'] as num).toInt();
      if (data['descricao'] != null) updateData['descricao'] = data['descricao'];
      if (data['oficina'] != null) updateData['oficina'] = data['oficina'];

      _logger.info('Atualizando manutenção: $id');

      final response = await SupabaseService.client
          .from('manutencoes')
          .update(updateData)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      final manutencaoUpdated = ManutencaoModel.fromJson(response);

      _logger.info('Manutenção atualizada com sucesso: $id');

      return Response.ok(
        json.encode({
          'message': 'Manutenção atualizada com sucesso',
          'manutencao': manutencaoUpdated.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao atualizar manutenção: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _deleteManutencao(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      final id = request.params['id'];
      if (id == null) {
        return Response(400, body: json.encode({'error': 'ID obrigatório'}));
      }

      // Verificar se a manutenção pertence ao usuário
      final existing = await SupabaseService.client
          .from('manutencoes')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        return Response(404, body: json.encode({'error': 'Manutenção não encontrada'}));
      }

      _logger.info('Deletando manutenção: $id');

      await SupabaseService.client
          .from('manutencoes')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      _logger.info('Manutenção deletada com sucesso: $id');

      return Response.ok(
        json.encode({'message': 'Manutenção deletada com sucesso'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao deletar manutenção: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _getManutencoesPorPeriodo(Request request) async {
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

      _logger.info('Buscando manutenções por período: $dataInicio - $dataFim');

      final response = await SupabaseService.client
          .from('manutencoes')
          .select()
          .eq('user_id', userId)
          .gte('data', dataInicio)
          .lte('data', dataFim)
          .order('data', ascending: false);

      final manutencoes = (response as List)
          .map((json) => ManutencaoModel.fromJson(json).toJson())
          .toList();

      _logger.info('${manutencoes.length} manutenções encontradas no período');

      return Response.ok(
        json.encode({'manutencoes': manutencoes}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao buscar manutenções por período: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _getManutencoesPorTipo(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      final params = request.url.queryParameters;
      final dataInicio = params['data_inicio'];
      final dataFim = params['data_fim'];

      _logger.info('Buscando manutenções por tipo');

      // Query com filtro de período opcional
      var query = SupabaseService.client
          .from('manutencoes')
          .select('tipo, valor')
          .eq('user_id', userId);

      if (dataInicio != null && dataFim != null) {
        query = query.gte('data', dataInicio).lte('data', dataFim);
      }

      final response = await query;

      // Agrupar por tipo
      final Map<String, double> tipos = {};
      for (final manutencao in response) {
        final tipo = manutencao['tipo'] as String;
        final valor = (manutencao['valor'] as num).toDouble();
        tipos[tipo] = (tipos[tipo] ?? 0) + valor;
      }

      final resultado = tipos.entries
          .map((entry) => {
                'tipo': entry.key,
                'total': entry.value,
              })
          .toList();

      _logger.info('${resultado.length} tipos encontrados');

      return Response.ok(
        json.encode({'tipos': resultado}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao buscar manutenções por tipo: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }
}