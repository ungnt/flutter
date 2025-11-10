import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

class OnlineDataService {
  static final OnlineDataService _instance = OnlineDataService._internal();
  static OnlineDataService get instance => _instance;
  OnlineDataService._internal();

  final DatabaseService _db = DatabaseService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;

  Future<OnlineOperationResult> createTrabalho(TrabalhoModel trabalho) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(
        success: false,
        message: 'Sem conexão com a internet. Não é possível adicionar registro.',
      );
    }

    try {
      final response = await ApiService.uploadTrabalhos([trabalho.toJson()]);
      
      if (response.success) {
        await _db.insertOrUpdateTrabalho(trabalho);
        return OnlineOperationResult(
          success: true,
          message: 'Registro salvo com sucesso!',
        );
      } else {
        return OnlineOperationResult(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      return OnlineOperationResult(
        success: false,
        message: 'Erro ao salvar: $e',
      );
    }
  }

  Future<OnlineOperationResult> deleteTrabalho(int id) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(
        success: false,
        message: 'Sem conexão com a internet. Não é possível excluir registro.',
      );
    }

    try {
      await _db.deleteTrabalho(id);
      return OnlineOperationResult(
        success: true,
        message: 'Registro excluído com sucesso!',
      );
    } catch (e) {
      return OnlineOperationResult(
        success: false,
        message: 'Erro ao excluir: $e',
      );
    }
  }

  Future<OnlineOperationResult> createGasto(GastoModel gasto) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(
        success: false,
        message: 'Sem conexão com a internet. Não é possível adicionar gasto.',
      );
    }

    try {
      final response = await ApiService.uploadGastos([gasto.toJson()]);
      
      if (response.success) {
        await _db.insertOrUpdateGasto(gasto);
        return OnlineOperationResult(
          success: true,
          message: 'Gasto salvo com sucesso!',
        );
      } else {
        return OnlineOperationResult(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      return OnlineOperationResult(
        success: false,
        message: 'Erro ao salvar gasto: $e',
      );
    }
  }

  Future<OnlineOperationResult> deleteGasto(int id) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(
        success: false,
        message: 'Sem conexão com a internet. Não é possível excluir gasto.',
      );
    }

    try {
      await _db.deleteGasto(id);
      return OnlineOperationResult(
        success: true,
        message: 'Gasto excluído com sucesso!',
      );
    } catch (e) {
      return OnlineOperationResult(
        success: false,
        message: 'Erro ao excluir gasto: $e',
      );
    }
  }

  Future<OnlineOperationResult> createManutencao(ManutencaoModel manutencao) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(
        success: false,
        message: 'Sem conexão com a internet. Não é possível adicionar manutenção.',
      );
    }

    try {
      final response = await ApiService.uploadManutencao([manutencao.toJson()]);
      
      if (response.success) {
        await _db.insertOrUpdateManutencao(manutencao);
        return OnlineOperationResult(
          success: true,
          message: 'Manutenção salva com sucesso!',
        );
      } else {
        return OnlineOperationResult(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      return OnlineOperationResult(
        success: false,
        message: 'Erro ao salvar manutenção: $e',
      );
    }
  }

  Future<OnlineOperationResult> deleteManutencao(String id) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(
        success: false,
        message: 'Sem conexão com a internet. Não é possível excluir manutenção.',
      );
    }

    try {
      await _db.deleteManutencao(id);
      return OnlineOperationResult(
        success: true,
        message: 'Manutenção excluída com sucesso!',
      );
    } catch (e) {
      return OnlineOperationResult(
        success: false,
        message: 'Erro ao excluir manutenção: $e',
      );
    }
  }

  Future<OnlineOperationResult> loadAllDataFromBackend() async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(
        success: false,
        message: 'Offline - mostrando dados em cache',
      );
    }

    try {
      final trabalhoResponse = await ApiService.downloadTrabalhos();
      final gastosResponse = await ApiService.downloadGastos();
      final manutencoesResponse = await ApiService.downloadManutencoes();

      if (trabalhoResponse.success && trabalhoResponse.data != null) {
        final trabalhos = (trabalhoResponse.data!['trabalhos'] as List?)
            ?.map((json) => TrabalhoModel.fromJson(json))
            .toList() ?? [];
        
        for (var trabalho in trabalhos) {
          await _db.insertOrUpdateTrabalho(trabalho);
        }
      }

      if (gastosResponse.success && gastosResponse.data != null) {
        final gastos = (gastosResponse.data!['gastos'] as List?)
            ?.map((json) => GastoModel.fromJson(json))
            .toList() ?? [];
        
        for (var gasto in gastos) {
          await _db.insertOrUpdateGasto(gasto);
        }
      }

      if (manutencoesResponse.success && manutencoesResponse.data != null) {
        final manutencoes = (manutencoesResponse.data!['manutencao'] as List?)
            ?.map((json) => ManutencaoModel.fromJson(json))
            .toList() ?? [];
        
        for (var manutencao in manutencoes) {
          await _db.insertOrUpdateManutencao(manutencao);
        }
      }

      return OnlineOperationResult(
        success: true,
        message: 'Dados atualizados do servidor',
      );
    } catch (e) {
      return OnlineOperationResult(
        success: false,
        message: 'Erro ao carregar dados: $e',
      );
    }
  }
}

class OnlineOperationResult {
  final bool success;
  final String message;

  OnlineOperationResult({
    required this.success,
    required this.message,
  });
}
