import '../models/manutencao_model.dart';
import '../utils/domain_result.dart';
import 'api_service.dart';

class ManutencaoService {
  static Future<DomainResult<List<ManutencaoModel>>> getAll() async {
    try {
      final response = await ApiService.getManutencoes();
      
      if (response.success && response.data != null) {
        final manutencoesList = response.data!['manutencao'] as List?;
        if (manutencoesList != null) {
          final manutencoes = manutencoesList
              .map((json) => ManutencaoModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return DomainResult.success(manutencoes);
        }
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao buscar manutenções: $e');
    }
  }

  static Future<DomainResult<ManutencaoModel>> create(ManutencaoModel manutencao) async {
    try {
      final response = await ApiService.createManutencao(manutencao.toJson());
      
      if (response.success && response.data != null) {
        final manutencaoData = response.data!['manutencao'] ?? response.data;
        final createdManutencao = ManutencaoModel.fromJson(manutencaoData as Map<String, dynamic>);
        return DomainResult.success(createdManutencao);
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao criar manutenção: $e');
    }
  }

  static Future<DomainResult<ManutencaoModel>> update(String id, ManutencaoModel manutencao) async {
    try {
      final response = await ApiService.updateManutencao(id, manutencao.toJson());
      
      if (response.success && response.data != null) {
        final manutencaoData = response.data!['manutencao'] ?? response.data;
        final updatedManutencao = ManutencaoModel.fromJson(manutencaoData as Map<String, dynamic>);
        return DomainResult.success(updatedManutencao);
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao atualizar manutenção: $e');
    }
  }

  static Future<DomainResult<bool>> delete(String id) async {
    try {
      final response = await ApiService.deleteManutencao(id);
      
      if (response.success) {
        return DomainResult.success(true);
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao deletar manutenção: $e');
    }
  }
}
