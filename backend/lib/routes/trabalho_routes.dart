import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';
import '../models/trabalho_model.dart';
import '../services/supabase_service.dart';
import '../services/security_service.dart';

import '../middleware/auth_middleware.dart';

final _logger = Logger('TrabalhoRoutes');

class TrabalhoRoutes {
  static Router get router {
    final router = Router();

    // GET /api/trabalho - Listar trabalho do usuário
    router.get('/', _getTrabalhos);
    
    // POST /api/trabalho - Criar novo trabalho
    router.post('/', _createTrabalho);
    
    // PUT /api/trabalho/<id> - Atualizar trabalho
    router.put('/<id>', _updateTrabalho);
    
    // DELETE /api/trabalho/<id> - Deletar trabalho
    router.delete('/<id>', _deleteTrabalho);
    
    // GET /api/trabalho/periodo - Trabalhos por período
    router.get('/periodo', _getTrabalhosPorPeriodo);
    
    // POST /api/trabalho/sync - Sincronização de trabalhos
    router.post('/sync', _syncTrabalhos);

    return router;
  }

  static Future<Response> _getTrabalhos(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      _logger.info('Listando trabalho para usuário: $userId');

      final response = await SupabaseService.client
          .from('trabalho')
          .select()
          .eq('user_id', userId)
          .order('data', ascending: false);

      final trabalho = (response as List)
          .map((json) => TrabalhoModel.fromJson(json).toJson())
          .toList();

      _logger.info('${trabalho.length} trabalho encontrados');

      return Response.ok(
        json.encode({'trabalho': trabalho}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao listar trabalho: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _createTrabalho(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      // Auditoria de segurança
      SecurityService.auditLog(userId, 'CREATE_TRABALHO', null);

      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      // Validação e sanitização de dados
      final validation = SecurityService.validateTrabalhoData(data);
      if (!validation.isValid) {
        _logger.warning('Dados inválidos: ${validation.errors}');
        return Response(400, body: json.encode({'error': 'Dados inválidos', 'details': validation.errors}));
      }

      final sanitizedData = validation.sanitizedData!;

      // Criar modelo com dados sanitizados
      final agora = DateTime.now();
      final trabalho = TrabalhoModel(
        userId: userId,
        data: DateTime.parse(sanitizedData['data']),
        ganhos: sanitizedData['ganhos'],
        km: sanitizedData['km'],
        horas: sanitizedData['horas'],
        observacoes: sanitizedData['observacoes'],
        dataRegistro: agora,
      );

      _logger.info('Criando trabalho para usuário: $userId');

      final response = await SupabaseService.client
          .from('trabalho')
          .insert(trabalho.toJson())
          .select()
          .single();

      final trabalhoCreated = TrabalhoModel.fromJson(response);

      _logger.info('Trabalho criado com sucesso: ${trabalhoCreated.id}');

      return Response(201,
        body: json.encode({
          'message': 'Trabalho criado com sucesso',
          'trabalho': trabalhoCreated.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao criar trabalho: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _updateTrabalho(Request request) async {
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

      // Verificar se o trabalho pertence ao usuário
      final existing = await SupabaseService.client
          .from('trabalho')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        return Response(404, body: json.encode({'error': 'Trabalho não encontrado'}));
      }

      // Preparar dados para atualização
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (data['data'] != null) updateData['data'] = data['data'];
      if (data['ganhos'] != null) updateData['ganhos'] = (data['ganhos'] as num).toDouble();
      if (data['km'] != null) updateData['km'] = (data['km'] as num).toDouble();
      if (data['horas'] != null) updateData['horas'] = (data['horas'] as num).toDouble();
      if (data['observacoes'] != null) updateData['observacoes'] = data['observacoes'];

      _logger.info('Atualizando trabalho: $id');

      final response = await SupabaseService.client
          .from('trabalho')
          .update(updateData)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      final trabalhoUpdated = TrabalhoModel.fromJson(response);

      _logger.info('Trabalho atualizado com sucesso: $id');

      return Response.ok(
        json.encode({
          'message': 'Trabalho atualizado com sucesso',
          'trabalho': trabalhoUpdated.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao atualizar trabalho: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _deleteTrabalho(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      final id = request.params['id'];
      if (id == null) {
        return Response(400, body: json.encode({'error': 'ID obrigatório'}));
      }

      // Verificar se o trabalho pertence ao usuário
      final existing = await SupabaseService.client
          .from('trabalho')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        return Response(404, body: json.encode({'error': 'Trabalho não encontrado'}));
      }

      _logger.info('Deletando trabalho: $id');

      await SupabaseService.client
          .from('trabalho')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      _logger.info('Trabalho deletado com sucesso: $id');

      return Response.ok(
        json.encode({'message': 'Trabalho deletado com sucesso'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao deletar trabalho: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  static Future<Response> _getTrabalhosPorPeriodo(Request request) async {
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

      _logger.info('Buscando trabalho por período: $dataInicio - $dataFim');

      final response = await SupabaseService.client
          .from('trabalho')
          .select()
          .eq('user_id', userId)
          .gte('data', dataInicio)
          .lte('data', dataFim)
          .order('data', ascending: false);

      final trabalho = (response as List)
          .map((json) => TrabalhoModel.fromJson(json).toJson())
          .toList();

      _logger.info('${trabalho.length} trabalho encontrados no período');

      return Response.ok(
        json.encode({'trabalho': trabalho}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro ao buscar trabalho por período: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }

  /// POST /api/trabalho/sync - Sincronização de trabalhos
  static Future<Response> _syncTrabalhos(Request request) async {
    try {
      final userId = AuthMiddleware.getUserId(request);
      if (userId == null) {
        return Response(401, body: json.encode({'error': 'Token inválido'}));
      }

      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      final trabalhos = data['trabalhos'] as List? ?? [];

      _logger.info('Sincronizando ${trabalhos.length} trabalhos para usuário: $userId');

      List<Map<String, dynamic>> resultados = [];
      int criados = 0;
      int atualizados = 0;
      List<String> erros = [];

      for (final trabalhoData in trabalhos) {
        try {
          final trabalho = TrabalhoModel.fromJson(trabalhoData as Map<String, dynamic>);
          
          // Verificar se já existe
          final existing = await SupabaseService.client
              .from('trabalho')
              .select()
              .eq('user_id', userId)
              .eq('data', trabalho.data.toIso8601String().split('T')[0])
              .eq('ganhos', trabalho.ganhos)
              .eq('km', trabalho.km)
              .eq('horas', trabalho.horas)
              .maybeSingle();

          if (existing == null) {
            // Criar novo
            final trabalhoComUserId = trabalho.copyWith(userId: userId);
            final response = await SupabaseService.client
                .from('trabalho')
                .insert(trabalhoComUserId.toJson())
                .select()
                .single();

            resultados.add(TrabalhoModel.fromJson(response).toJson());
            criados++;
          } else {
            // Atualizar existente
            final updateData = {
              'ganhos': trabalho.ganhos,
              'km': trabalho.km,
              'horas': trabalho.horas,
              'observacoes': trabalho.observacoes,
              'updated_at': DateTime.now().toIso8601String(),
            };

            final response = await SupabaseService.client
                .from('trabalho')
                .update(updateData)
                .eq('id', existing['id'])
                .select()
                .single();

            resultados.add(TrabalhoModel.fromJson(response).toJson());
            atualizados++;
          }
        } catch (e) {
          erros.add('Erro ao processar trabalho: $e');
        }
      }

      _logger.info('Sincronização concluída: $criados criados, $atualizados atualizados, ${erros.length} erros');

      return Response.ok(
        json.encode({
          'success': true,
          'message': 'Sincronização concluída',
          'data': {
            'trabalhos': resultados,
            'statistics': {
              'criados': criados,
              'atualizados': atualizados,
              'erros': erros.length,
              'total': trabalhos.length,
            },
            'erros': erros,
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      _logger.severe('Erro na sincronização de trabalhos: $e', e, stackTrace);
      return Response.internalServerError(
        body: json.encode({'error': 'Erro interno do servidor'}),
      );
    }
  }
}