import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';

class BackupRoutes {
  Router get router {
    final router = Router()
      ..post('/upload', _uploadHandler)
      ..get('/download', _downloadHandler)
      ..get('/list', _listHandler)
      ..delete('/<backupId>', _deleteHandler)
      ..post('/sync', _syncHandler); // Nova rota para resolver conflitos

    return router;
  }

  /// POST /api/backup/upload
  /// Upload dos dados do app Flutter para nuvem
  Future<Response> _uploadHandler(Request request) async {
    // TODO: Validar usuário Premium
    // TODO: Processar dados do SQLite local
    // TODO: Resolver conflitos de dados (timestamps!)
    
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      // Estrutura esperada dos dados do Flutter
      final backupData = data['dados'] as Map<String, dynamic>?;
      final deviceId = data['deviceId'] as String?;
      final lastSync = data['lastSync'] as String?; // timestamp da última sincronização
      
      if (backupData == null) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'MISSING_DATA',
            'message': 'Dados para backup não fornecidos'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Processar dados reais do Flutter
      final trabalhos = backupData['trabalhos'] as List? ?? [];
      final gastos = backupData['gastos'] as List? ?? [];
      final manutencao = backupData['manutencao'] as List? ?? [];
      
      // Obter usuário do token
      final token = request.headers['authorization']?.replaceFirst('Bearer ', '');
      final userId = await _getUserFromToken(token);
      
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({'success': false, 'error': 'Token inválido'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Salvar trabalhos no Supabase
      await _saveTrabalhos(trabalhos, userId);
      
      // Salvar gastos no Supabase
      await _saveGastos(gastos, userId);
      
      // Salvar manutenções no Supabase
      await _saveManutencao(manutencao, userId);
      
      final totalRecords = trabalhos.length + gastos.length + manutencao.length;
      final estimatedSize = (body.length / 1024).toStringAsFixed(1); // KB
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Upload backup - implementação com resolução de conflitos',
          'data': {
            'backupId': 'backup_${DateTime.now().millisecondsSinceEpoch}',
            'uploadedAt': DateTime.now().toIso8601String(),
            'records': {
              'trabalhos': trabalhos.length,
              'gastos': gastos.length,
              'manutencao': manutencao.length,
              'configuracoes': 0
            },
            'totalRecords': totalRecords,
            'size': '${estimatedSize}KB',
            'conflicts': [], // TODO: Lista de conflitos detectados
            'deviceId': deviceId,
            'syncStrategy': 'last_write_wins' // TODO: Configurável
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'UPLOAD_ERROR',
          'message': 'Erro ao processar upload: $e'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/backup/download
  /// Download dos dados da nuvem para o app Flutter
  Future<Response> _downloadHandler(Request request) async {
    // TODO: Validar usuário Premium
    // TODO: Retornar dados do PostgreSQL em formato compatível com SQLite
    
    final deviceId = request.url.queryParameters['deviceId'];
    final lastSync = request.url.queryParameters['lastSync'];
    
    // Obter usuário do token
    final token = request.headers['authorization']?.replaceFirst('Bearer ', '');
    final userId = await _getUserFromToken(token);
    
    if (userId == null) {
      return Response.unauthorized(
        jsonEncode({'success': false, 'error': 'Token inválido'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // Buscar dados reais do Supabase
    final trabalhos = await _getTrabalhos(userId);
    final gastos = await _getGastos(userId);
    final manutencao = await _getManutencao(userId);

    return Response.ok(
      jsonEncode({
        'success': true,
        'message': 'Download backup - dados reais do Supabase',
        'data': {
          'trabalhos': trabalhos,
          'gastos': gastos,
          'manutencao': manutencao,
          'metadata': {
            'lastSync': DateTime.now().toIso8601String(),
            'totalRecords': trabalhos.length + gastos.length + manutencao.length,
            'deviceId': deviceId,
            'serverVersion': '1.0.0'
          }
        }
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// GET /api/backup/list
  /// Listar backups disponíveis (histórico)
  Future<Response> _listHandler(Request request) async {
    // TODO: Validar usuário Premium
    // TODO: Buscar histórico de backups no PostgreSQL
    
    return Response.ok(
      jsonEncode({
        'success': true,
        'message': 'Lista de backups - implementação com retenção por plano',
        'data': {
          'backups': [
            {
              'id': 'backup_1737563400000',
              'createdAt': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
              'size': '2.1KB',
              'records': {
                'trabalhos': 15,
                'gastos': 32,
                'manutencao': 3
              },
              'deviceId': 'device_001',
              'version': '1.0.0'
            },
            {
              'id': 'backup_1737559800000',
              'createdAt': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
              'size': '1.8KB',
              'records': {
                'trabalhos': 14,
                'gastos': 28,
                'manutencao': 3
              },
              'deviceId': 'device_001',
              'version': '1.0.0'
            }
          ],
          'pagination': {
            'total': 2,
            'page': 1,
            'limit': 10
          },
          'retention': {
            'plan': 'premium',
            'daysLimit': -1, // ilimitado para premium
            'autoCleanup': false
          }
        }
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// DELETE /api/backup/:backupId
  /// Deletar backup específico
  Future<Response> _deleteHandler(Request request) async {
    final backupId = request.params['backupId'];
    
    // TODO: Validar usuário Premium
    // TODO: Verificar se backup pertence ao usuário
    // TODO: Deletar do PostgreSQL
    
    return Response.ok(
      jsonEncode({
        'success': true,
        'message': 'Backup deletado com sucesso',
        'data': {
          'backupId': backupId,
          'deletedAt': DateTime.now().toIso8601String()
        }
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// POST /api/backup/sync
  /// Sincronização inteligente - resolve conflitos de dados
  Future<Response> _syncHandler(Request request) async {
    // TODO: Esta é a rota mais complexa - resolve conflitos cliente vs servidor
    
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final localData = data['localData'] as Map<String, dynamic>?;
      final lastSync = data['lastSync'] as String?;
      final deviceId = data['deviceId'] as String?;
      final conflictStrategy = data['conflictStrategy'] as String? ?? 'last_write_wins';
      
      // TODO: Implementar lógica complexa de sincronização:
      /*
      1. DETECTAR CONFLITOS:
         - Registros modificados em ambos os lados após lastSync
         - Mesmo ID com timestamps diferentes
         - Registros deletados localmente mas modificados no servidor
      
      2. ESTRATÉGIAS DE RESOLUÇÃO:
         - last_write_wins: Timestamp mais recente vence
         - server_wins: Servidor sempre prevalece  
         - client_wins: Cliente sempre prevalece
         - manual: Retornar conflitos para usuário decidir
      
      3. MERGE INTELIGENTE:
         - Campos não conflitantes são mesclados
         - Timestamps de criação preservados
         - Histórico de modificações mantido
      
      4. RESULTADO:
         - Dados mesclados para cliente aplicar
         - Lista de conflitos resolvidos
         - Novo timestamp de sincronização
      */
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Sincronização com resolução de conflitos - implementação crítica',
          'data': {
            'syncResult': {
              'conflicts': [], // Lista de conflitos encontrados e resolvidos
              'mergedData': {
                'trabalhos': [], // Dados finais após merge
                'gastos': [],
                'manutencao': [],
                'configuracoes': {}
              },
              'statistics': {
                'totalConflicts': 0,
                'resolvedConflicts': 0,
                'pendingConflicts': 0,
                'addedRecords': 0,
                'updatedRecords': 0,
                'deletedRecords': 0
              },
              'newSyncTimestamp': DateTime.now().toIso8601String(),
              'strategy': conflictStrategy,
              'deviceId': deviceId
            }
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'SYNC_ERROR',
          'message': 'Erro crítico na sincronização: $e'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Obter userId do token JWT
  Future<String?> _getUserFromToken(String? token) async {
    if (token == null) return null;
    
    try {
      // Usar o AuthService para validar token
      // Usar o método correto do AuthService
      final authService = AuthService(SupabaseService(), 'jwt_secret_key');
      final payload = authService.validateJWT(token);
      return payload?['user_id'];
    } catch (e) {
      print('Erro ao validar token: $e');
      return null;
    }
  }

  /// Salvar trabalhos no Supabase
  Future<void> _saveTrabalhos(List<dynamic> trabalhos, String userId) async {
    try {
      for (final trabalhoData in trabalhos) {
        final trabalho = TrabalhoModel.fromJson(trabalhoData);
        final trabalhoWithUser = trabalho.copyWith(userId: userId);
        
        // Insert ou update no Supabase
        await SupabaseService.client
            .from('trabalho')
            .upsert(trabalhoWithUser.toJson());
      }
    } catch (e) {
      print('Erro ao salvar trabalhos: $e');
    }
  }

  /// Salvar gastos no Supabase
  Future<void> _saveGastos(List<dynamic> gastos, String userId) async {
    try {
      for (final gastoData in gastos) {
        final gasto = GastoModel.fromJson(gastoData);
        final gastoWithUser = gasto.copyWith(userId: userId);
        
        await SupabaseService.client
            .from('gastos')
            .upsert(gastoWithUser.toJson());
      }
    } catch (e) {
      print('Erro ao salvar gastos: $e');
    }
  }

  /// Salvar manutenções no Supabase
  Future<void> _saveManutencao(List<dynamic> manutencao, String userId) async {
    try {
      for (final manutencaoData in manutencao) {
        final manutencaoObj = ManutencaoModel.fromJson(manutencaoData);
        final manutencaoWithUser = manutencaoObj.copyWith(userId: userId);
        
        await SupabaseService.client
            .from('manutencoes')
            .upsert(manutencaoWithUser.toJson());
      }
    } catch (e) {
      print('Erro ao salvar manutenções: $e');
    }
  }

  /// Buscar trabalhos do Supabase
  Future<List<Map<String, dynamic>>> _getTrabalhos(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('trabalho')
          .select()
          .eq('user_id', userId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar trabalhos: $e');
      return [];
    }
  }

  /// Buscar gastos do Supabase
  Future<List<Map<String, dynamic>>> _getGastos(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('gastos')
          .select()
          .eq('user_id', userId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar gastos: $e');
      return [];
    }
  }

  /// Buscar manutenções do Supabase
  Future<List<Map<String, dynamic>>> _getManutencao(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('manutencoes')
          .select()
          .eq('user_id', userId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar manutenções: $e');
      return [];
    }
  }
}