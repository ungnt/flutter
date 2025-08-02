import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';
import 'database_service.dart';

/// Estratégias de resolução disponíveis
enum ResolutionStrategy {
  keepLocal,    // Manter versão local
  keepServer,   // Manter versão servidor
  merge,        // Fazer merge inteligente
}

/// Serviço para resolução de conflitos no frontend
class ConflictResolutionService {
  static const String _tag = '[ConflictResolution]';



  /// Resolver conflito de trabalho
  static Future<bool> resolveTrabalhoConflict(
    String id,
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    ResolutionStrategy strategy,
  ) async {
    try {
      print('$_tag Resolvendo conflito de trabalho: $id');

      switch (strategy) {
        case ResolutionStrategy.keepLocal:
          // Manter versão local, não fazer nada
          return true;

        case ResolutionStrategy.keepServer:
          // Atualizar com versão do servidor
          final serverTrabalho = TrabalhoModel.fromJson(serverData);
          await DatabaseService.instance.updateTrabalho(serverTrabalho);
          return true;

        case ResolutionStrategy.merge:
          // Fazer merge inteligente
          final merged = _mergeTrabalho(localData, serverData);
          final mergedTrabalho = TrabalhoModel.fromJson(merged);
          await DatabaseService.instance.updateTrabalho(mergedTrabalho);
          return true;
      }
    } catch (e) {
      print('$_tag Erro ao resolver conflito de trabalho: $e');
      return false;
    }
  }

  /// Resolver conflito de gasto
  static Future<bool> resolveGastoConflict(
    String id,
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    ResolutionStrategy strategy,
  ) async {
    try {
      print('$_tag Resolvendo conflito de gasto: $id');

      switch (strategy) {
        case ResolutionStrategy.keepLocal:
          return true;

        case ResolutionStrategy.keepServer:
          final serverGasto = GastoModel.fromJson(serverData);
          await DatabaseService.instance.updateGasto(serverGasto);
          return true;

        case ResolutionStrategy.merge:
          final merged = _mergeGasto(localData, serverData);
          final mergedGasto = GastoModel.fromJson(merged);
          await DatabaseService.instance.updateGasto(mergedGasto);
          return true;
      }
    } catch (e) {
      print('$_tag Erro ao resolver conflito de gasto: $e');
      return false;
    }
  }

  /// Resolver conflito de manutenção
  static Future<bool> resolveManutencaoConflict(
    String id,
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    ResolutionStrategy strategy,
  ) async {
    try {
      print('$_tag Resolvendo conflito de manutenção: $id');

      switch (strategy) {
        case ResolutionStrategy.keepLocal:
          return true;

        case ResolutionStrategy.keepServer:
          final serverManutencao = ManutencaoModel.fromJson(serverData);
          await DatabaseService.instance.updateManutencao(serverManutencao);
          return true;

        case ResolutionStrategy.merge:
          final merged = _mergeManutencao(localData, serverData);
          final mergedManutencao = ManutencaoModel.fromJson(merged);
          await DatabaseService.instance.updateManutencao(mergedManutencao);
          return true;
      }
    } catch (e) {
      print('$_tag Erro ao resolver conflito de manutenção: $e');
      return false;
    }
  }

  /// Merge inteligente para trabalho
  static Map<String, dynamic> _mergeTrabalho(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final merged = Map<String, dynamic>.from(server);

    // Regras de merge para trabalho:
    // - Ganhos: maior valor (assume correção)
    // - KM: maior valor (assume atualização)
    // - Horas: maior valor (assume correção)
    // - Observações: concatenar se diferentes

    final localGanhos = (local['ganhos'] as num?)?.toDouble() ?? 0.0;
    final serverGanhos = (server['ganhos'] as num?)?.toDouble() ?? 0.0;
    merged['ganhos'] = localGanhos > serverGanhos ? localGanhos : serverGanhos;

    final localKm = (local['km'] as num?)?.toDouble() ?? 0.0;
    final serverKm = (server['km'] as num?)?.toDouble() ?? 0.0;
    merged['km'] = localKm > serverKm ? localKm : serverKm;

    final localHoras = (local['horas'] as num?)?.toDouble() ?? 0.0;
    final serverHoras = (server['horas'] as num?)?.toDouble() ?? 0.0;
    merged['horas'] = localHoras > serverHoras ? localHoras : serverHoras;

    // Merge de observações
    final localObs = local['observacoes']?.toString() ?? '';
    final serverObs = server['observacoes']?.toString() ?? '';
    if (localObs != serverObs && localObs.isNotEmpty && serverObs.isNotEmpty) {
      merged['observacoes'] = '$serverObs | $localObs';
    } else if (localObs.isNotEmpty) {
      merged['observacoes'] = localObs;
    }

    return merged;
  }

  /// Merge inteligente para gasto
  static Map<String, dynamic> _mergeGasto(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final merged = Map<String, dynamic>.from(server);

    // Para gastos, preferir sempre o valor mais atualizado (server)
    // Mas fazer merge da descrição se diferente

    final localDesc = local['descricao']?.toString() ?? '';
    final serverDesc = server['descricao']?.toString() ?? '';
    if (localDesc != serverDesc && localDesc.isNotEmpty && serverDesc.isNotEmpty) {
      merged['descricao'] = '$serverDesc | $localDesc';
    } else if (localDesc.isNotEmpty) {
      merged['descricao'] = localDesc;
    }

    return merged;
  }

  /// Merge inteligente para manutenção
  static Map<String, dynamic> _mergeManutencao(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final merged = Map<String, dynamic>.from(server);

    // Regras de merge para manutenção:
    // - Valor: maior valor (assume correção)
    // - KM atual: maior valor (assume atualização)
    // - Descrição: concatenar se diferentes

    final localValor = (local['valor'] as num?)?.toDouble() ?? 0.0;
    final serverValor = (server['valor'] as num?)?.toDouble() ?? 0.0;
    merged['valor'] = localValor > serverValor ? localValor : serverValor;

    final localKm = (local['km_atual'] as num?)?.toDouble() ?? 0.0;
    final serverKm = (server['km_atual'] as num?)?.toDouble() ?? 0.0;
    merged['km_atual'] = localKm > serverKm ? localKm : serverKm;

    // Merge de descrição
    final localDesc = local['descricao']?.toString() ?? '';
    final serverDesc = server['descricao']?.toString() ?? '';
    if (localDesc != serverDesc && localDesc.isNotEmpty && serverDesc.isNotEmpty) {
      merged['descricao'] = '$serverDesc | $localDesc';
    } else if (localDesc.isNotEmpty) {
      merged['descricao'] = localDesc;
    }

    return merged;
  }

  /// Resolver todos os conflitos automaticamente
  static Future<Map<String, int>> resolveAllConflicts(
    List<Map<String, dynamic>> conflicts,
    ResolutionStrategy strategy,
  ) async {
    final results = {
      'resolved': 0,
      'failed': 0,
    };

    for (final conflict in conflicts) {
      final type = conflict['type'] as String;
      final id = conflict['id'] as String;
      final localData = conflict['local'] as Map<String, dynamic>;
      final serverData = conflict['server'] as Map<String, dynamic>;

      bool success = false;

      switch (type) {
        case 'trabalho':
          success = await resolveTrabalhoConflict(id, localData, serverData, strategy);
          break;
        case 'gasto':
          success = await resolveGastoConflict(id, localData, serverData, strategy);
          break;
        case 'manutencao':
          success = await resolveManutencaoConflict(id, localData, serverData, strategy);
          break;
      }

      if (success) {
        results['resolved'] = results['resolved']! + 1;
      } else {
        results['failed'] = results['failed']! + 1;
      }
    }

    return results;
  }

  /// Obter recomendação automática de estratégia
  static ResolutionStrategy getRecommendedStrategy(Map<String, dynamic> conflict) {
    final conflictFields = conflict['conflictFields'] as List<String>? ?? [];
    
    // Se há muitos campos em conflito, preferir merge
    if (conflictFields.length > 2) {
      return ResolutionStrategy.merge;
    }
    
    // Se apenas observações/descrição, fazer merge
    if (conflictFields.length == 1 && 
        (conflictFields.contains('observacoes') || 
         conflictFields.contains('descricao'))) {
      return ResolutionStrategy.merge;
    }
    
    // Para valores numéricos, preferir server (mais recente)
    if (conflictFields.any((field) => ['ganhos', 'valor', 'km', 'km_atual', 'horas'].contains(field))) {
      return ResolutionStrategy.keepServer;
    }
    
    // Default: manter servidor
    return ResolutionStrategy.keepServer;
  }
}