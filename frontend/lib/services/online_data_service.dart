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
        message: 'Sem conexão. Não é possível adicionar registro.',
      );
    }

    try {
      final response = await ApiService.post(
        endpoint: 'trabalho/',
        data: trabalho.toJson(),
      );
      
      if (response.success && response.data != null) {
        final serverData = response.data!['data'];
        final updatedTrabalho = trabalho.copyWith(
          id: int.tryParse(serverData['id'].toString()),
        );
        await _db.insertOrUpdateTrabalho(updatedTrabalho);
        return OnlineOperationResult(success: true, message: 'Salvo!');
      } else {
        return OnlineOperationResult(success: false, message: response.message);
      }
    } catch (e) {
      return OnlineOperationResult(success: false, message: 'Erro: $e');
    }
  }

  Future<OnlineOperationResult> deleteTrabalho(int id) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(success: false, message: 'Sem conexão.');
    }

    try {
      final response = await ApiService.delete(endpoint: 'trabalho/$id');
      if (response.success) {
        await _db.deleteTrabalho(id);
        return OnlineOperationResult(success: true, message: 'Excluído!');
      } else {
        return OnlineOperationResult(success: false, message: response.message);
      }
    } catch (e) {
      return OnlineOperationResult(success: false, message: 'Erro: $e');
    }
  }

  Future<OnlineOperationResult> createGasto(GastoModel gasto) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(success: false, message: 'Sem conexão.');
    }

    try {
      final response = await ApiService.post(endpoint: 'gastos/', data: gasto.toJson());
      
      if (response.success && response.data != null) {
        final serverData = response.data!['data'];
        final updatedGasto = gasto.copyWith(
          id: int.tryParse(serverData['id'].toString()),
        );
        await _db.insertOrUpdateGasto(updatedGasto);
        return OnlineOperationResult(success: true, message: 'Salvo!');
      } else {
        return OnlineOperationResult(success: false, message: response.message);
      }
    } catch (e) {
      return OnlineOperationResult(success: false, message: 'Erro: $e');
    }
  }

  Future<OnlineOperationResult> deleteGasto(int id) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(success: false, message: 'Sem conexão.');
    }

    try {
      final response = await ApiService.delete(endpoint: 'gastos/$id');
      if (response.success) {
        await _db.deleteGasto(id);
        return OnlineOperationResult(success: true, message: 'Excluído!');
      } else {
        return OnlineOperationResult(success: false, message: response.message);
      }
    } catch (e) {
      return OnlineOperationResult(success: false, message: 'Erro: $e');
    }
  }

  Future<OnlineOperationResult> createManutencao(ManutencaoModel manutencao) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(success: false, message: 'Sem conexão.');
    }

    try {
      final response = await ApiService.post(endpoint: 'manutencao/', data: manutencao.toJson());
      
      if (response.success && response.data != null) {
        final serverData = response.data!['data'];
        final updatedManutencao = manutencao.copyWith(
          id: int.tryParse(serverData['id'].toString()),
        );
        await _db.insertOrUpdateManutencao(updatedManutencao);
        return OnlineOperationResult(success: true, message: 'Salvo!');
      } else {
        return OnlineOperationResult(success: false, message: response.message);
      }
    } catch (e) {
      return OnlineOperationResult(success: false, message: 'Erro: $e');
    }
  }

  Future<OnlineOperationResult> deleteManutencao(String id) async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(success: false, message: 'Sem conexão.');
    }

    try {
      final response = await ApiService.delete(endpoint: 'manutencao/$id');
      if (response.success) {
        await _db.deleteManutencao(id);
        return OnlineOperationResult(success: true, message: 'Excluído!');
      } else {
        return OnlineOperationResult(success: false, message: response.message);
      }
    } catch (e) {
      return OnlineOperationResult(success: false, message: 'Erro: $e');
    }
  }

  Future<OnlineOperationResult> loadAllDataFromBackend() async {
    if (!_connectivity.isOnline) {
      return OnlineOperationResult(success: false, message: 'Offline - mostrando cache');
    }

    try {
      final trabalhoResp = await ApiService.get(endpoint: 'trabalho/');
      final gastosResp = await ApiService.get(endpoint: 'gastos/');
      final manutencoesResp = await ApiService.get(endpoint: 'manutencao/');

      if (trabalhoResp.success && trabalhoResp.data != null) {
        final trabalhos = (trabalhoResp.data!['data']?['trabalhos'] as List?)
            ?.map((json) => TrabalhoModel.fromJson(json))
            .toList() ?? [];
        
        for (var trabalho in trabalhos) {
          await _db.insertOrUpdateTrabalho(trabalho);
        }
      }

      if (gastosResp.success && gastosResp.data != null) {
        final gastos = (gastosResp.data!['data']?['gastos'] as List?)
            ?.map((json) => GastoModel.fromJson(json))
            .toList() ?? [];
        
        for (var gasto in gastos) {
          await _db.insertOrUpdateGasto(gasto);
        }
      }

      if (manutencoesResp.success && manutencoesResp.data != null) {
        final manutencoes = (manutencoesResp.data!['data']?['manutencao'] as List? ?? manutencoesResp.data!['data']?['manutencoes'] as List?)
            ?.map((json) => ManutencaoModel.fromJson(json))
            .toList() ?? [];
        
        for (var manutencao in manutencoes) {
          await _db.insertOrUpdateManutencao(manutencao);
        }
      }

      return OnlineOperationResult(success: true, message: 'Atualizado!');
    } catch (e) {
      return OnlineOperationResult(success: false, message: 'Erro: $e');
    }
  }
}

class OnlineOperationResult {
  final bool success;
  final String message;

  OnlineOperationResult({required this.success, required this.message});
}
