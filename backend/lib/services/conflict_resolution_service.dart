import 'dart:convert';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';

/// Estratégias de resolução de conflitos
enum ConflictStrategy {
  serverWins,      // Servidor sempre vence
  clientWins,      // Cliente sempre vence
  lastModifiedWins, // Último modificado vence
  merge,           // Tentar merge inteligente
  userChoice,      // Usuário decide
}

/// Resultado da resolução de conflito
class ConflictResult<T> {
  final T? resolved;
  final bool requiresUserInput;
  final String? conflictDescription;
  final Map<String, dynamic>? metadata;

  ConflictResult({
    this.resolved,
    this.requiresUserInput = false,
    this.conflictDescription,
    this.metadata,
  });
}

/// Serviço avançado para resolução de conflitos em sincronização
class ConflictResolutionService {
  static const String _tag = '[ConflictResolution]';

  /// Detecta e resolve conflitos para TrabalhoModel
  static ConflictResult<TrabalhoModel> resolveTrabalhoConflict(
    TrabalhoModel serverVersion,
    TrabalhoModel clientVersion,
    ConflictStrategy strategy,
  ) {
    try {
      print('$_tag Resolvendo conflito TrabalhoModel com estratégia: $strategy');
      
      // Verificar se realmente há conflito
      if (_isEqual(serverVersion, clientVersion)) {
        return ConflictResult(resolved: serverVersion);
      }

      switch (strategy) {
        case ConflictStrategy.serverWins:
          return ConflictResult(resolved: serverVersion);
          
        case ConflictStrategy.clientWins:
          return ConflictResult(resolved: clientVersion);
          
        case ConflictStrategy.lastModifiedWins:
          final serverTime = serverVersion.updatedAt ?? serverVersion.dataRegistro;
          final clientTime = clientVersion.updatedAt ?? clientVersion.dataRegistro;
          
          if (serverTime.isAfter(clientTime)) {
            return ConflictResult(resolved: serverVersion);
          } else {
            return ConflictResult(resolved: clientVersion);
          }
          
        case ConflictStrategy.merge:
          return _mergeTrabalho(serverVersion, clientVersion);
          
        case ConflictStrategy.userChoice:
          return ConflictResult(
            requiresUserInput: true,
            conflictDescription: 'Conflito detectado entre versão servidor e cliente',
            metadata: {
              'server': serverVersion.toJson(),
              'client': clientVersion.toJson(),
            },
          );
      }
    } catch (e) {
      print('$_tag Erro ao resolver conflito TrabalhoModel: $e');
      return ConflictResult(
        requiresUserInput: true,
        conflictDescription: 'Erro na resolução automática: $e',
      );
    }
  }

  /// Detecta e resolve conflitos para GastoModel
  static ConflictResult<GastoModel> resolveGastoConflict(
    GastoModel serverVersion,
    GastoModel clientVersion,
    ConflictStrategy strategy,
  ) {
    try {
      print('$_tag Resolvendo conflito GastoModel com estratégia: $strategy');
      
      if (_isEqual(serverVersion, clientVersion)) {
        return ConflictResult(resolved: serverVersion);
      }

      switch (strategy) {
        case ConflictStrategy.serverWins:
          return ConflictResult(resolved: serverVersion);
          
        case ConflictStrategy.clientWins:
          return ConflictResult(resolved: clientVersion);
          
        case ConflictStrategy.lastModifiedWins:
          final serverTime = serverVersion.updatedAt ?? serverVersion.dataRegistro;
          final clientTime = clientVersion.updatedAt ?? clientVersion.dataRegistro;
          
          if (serverTime.isAfter(clientTime)) {
            return ConflictResult(resolved: serverVersion);
          } else {
            return ConflictResult(resolved: clientVersion);
          }
          
        case ConflictStrategy.merge:
          return _mergeGasto(serverVersion, clientVersion);
          
        case ConflictStrategy.userChoice:
          return ConflictResult(
            requiresUserInput: true,
            conflictDescription: 'Conflito detectado entre versão servidor e cliente',
            metadata: {
              'server': serverVersion.toJson(),
              'client': clientVersion.toJson(),
            },
          );
      }
    } catch (e) {
      print('$_tag Erro ao resolver conflito GastoModel: $e');
      return ConflictResult(
        requiresUserInput: true,
        conflictDescription: 'Erro na resolução automática: $e',
      );
    }
  }

  /// Detecta e resolve conflitos para ManutencaoModel
  static ConflictResult<ManutencaoModel> resolveManutencaoConflict(
    ManutencaoModel serverVersion,
    ManutencaoModel clientVersion,
    ConflictStrategy strategy,
  ) {
    try {
      print('$_tag Resolvendo conflito ManutencaoModel com estratégia: $strategy');
      
      if (_isEqual(serverVersion, clientVersion)) {
        return ConflictResult(resolved: serverVersion);
      }

      switch (strategy) {
        case ConflictStrategy.serverWins:
          return ConflictResult(resolved: serverVersion);
          
        case ConflictStrategy.clientWins:
          return ConflictResult(resolved: clientVersion);
          
        case ConflictStrategy.lastModifiedWins:
          final serverTime = serverVersion.updatedAt ?? serverVersion.dataRegistro;
          final clientTime = clientVersion.updatedAt ?? clientVersion.dataRegistro;
          
          if (serverTime.isAfter(clientTime)) {
            return ConflictResult(resolved: serverVersion);
          } else {
            return ConflictResult(resolved: clientVersion);
          }
          
        case ConflictStrategy.merge:
          return _mergeManutencao(serverVersion, clientVersion);
          
        case ConflictStrategy.userChoice:
          return ConflictResult(
            requiresUserInput: true,
            conflictDescription: 'Conflito detectado entre versão servidor e cliente',
            metadata: {
              'server': serverVersion.toJson(),
              'client': clientVersion.toJson(),
            },
          );
      }
    } catch (e) {
      print('$_tag Erro ao resolver conflito ManutencaoModel: $e');
      return ConflictResult(
        requiresUserInput: true,
        conflictDescription: 'Erro na resolução automática: $e',
      );
    }
  }

  /// Merge inteligente para TrabalhoModel
  static ConflictResult<TrabalhoModel> _mergeTrabalho(
    TrabalhoModel server,
    TrabalhoModel client,
  ) {
    try {
      // Prioridades de merge para trabalho:
      // 1. Ganhos: valor maior (assume correção)
      // 2. KM: valor maior (assume atualização)
      // 3. Horas: valor maior (assume correção)
      // 4. Observações: merge de texto
      
      final merged = TrabalhoModel(
        id: server.id,
        userId: server.userId,
        data: server.data,
        ganhos: server.ganhos > client.ganhos ? server.ganhos : client.ganhos,
        km: server.km > client.km ? server.km : client.km,
        horas: server.horas > client.horas ? server.horas : client.horas,
        observacoes: _mergeText(server.observacoes, client.observacoes),
        dataRegistro: server.dataRegistro,
        updatedAt: DateTime.now(),
      );

      return ConflictResult(resolved: merged);
    } catch (e) {
      return ConflictResult(
        requiresUserInput: true,
        conflictDescription: 'Falha no merge automático: $e',
      );
    }
  }

  /// Merge inteligente para GastoModel
  static ConflictResult<GastoModel> _mergeGasto(
    GastoModel server,
    GastoModel client,
  ) {
    try {
      // Para gastos, preferir sempre a versão mais recente
      final serverTime = server.updatedAt ?? server.dataRegistro;
      final clientTime = client.updatedAt ?? client.dataRegistro;
      
      if (serverTime.isAfter(clientTime)) {
        return ConflictResult(resolved: server);
      } else {
        return ConflictResult(resolved: client.copyWith(
          id: server.id,
          updatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      return ConflictResult(
        requiresUserInput: true,
        conflictDescription: 'Falha no merge automático: $e',
      );
    }
  }

  /// Merge inteligente para ManutencaoModel
  static ConflictResult<ManutencaoModel> _mergeManutencao(
    ManutencaoModel server,
    ManutencaoModel client,
  ) {
    try {
      // Para manutenções, merge baseado em prioridade de campos
      final merged = ManutencaoModel(
        id: server.id,
        userId: server.userId,
        data: server.data,
        tipo: server.tipo,
        valor: server.valor > client.valor ? server.valor : client.valor, // Valor maior assume correção
        kmAtual: server.kmAtual > client.kmAtual ? server.kmAtual : client.kmAtual, // KM maior assume atualização
        descricao: _mergeText(server.descricao, client.descricao),
        dataRegistro: server.dataRegistro,
        updatedAt: DateTime.now(),
      );

      return ConflictResult(resolved: merged);
    } catch (e) {
      return ConflictResult(
        requiresUserInput: true,
        conflictDescription: 'Falha no merge automático: $e',
      );
    }
  }

  /// Merge inteligente de texto
  static String? _mergeText(String? server, String? client) {
    if (server == null || server.isEmpty) return client;
    if (client == null || client.isEmpty) return server;
    if (server == client) return server;
    
    // Se diferentes, combinar
    return '$server | $client';
  }

  /// Verifica se dois objetos são iguais (comparação profunda)
  static bool _isEqual(dynamic obj1, dynamic obj2) {
    try {
      final json1 = jsonEncode(obj1.toJson());
      final json2 = jsonEncode(obj2.toJson());
      return json1 == json2;
    } catch (e) {
      return false;
    }
  }

  /// Gera hash para versionamento
  static String generateHash(dynamic object) {
    try {
      final json = jsonEncode(object.toJson());
      return json.hashCode.toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
}