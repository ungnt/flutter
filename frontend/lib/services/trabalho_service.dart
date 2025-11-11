import '../models/trabalho_model.dart';
import '../utils/domain_result.dart';
import 'api_service.dart';

class TrabalhoService {
  static Future<DomainResult<List<TrabalhoModel>>> getAll() async {
    try {
      final response = await ApiService.getTrabalhos();
      
      if (response.success && response.data != null) {
        final trabalhosList = response.data!['trabalhos'] as List?;
        if (trabalhosList != null) {
          final trabalhos = trabalhosList
              .map((json) => TrabalhoModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return DomainResult.success(trabalhos);
        }
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao buscar trabalhos: $e');
    }
  }

  static Future<DomainResult<TrabalhoModel>> create(TrabalhoModel trabalho) async {
    try {
      final response = await ApiService.createTrabalho(trabalho.toJson());
      
      if (response.success && response.data != null) {
        final trabalhoData = response.data!['trabalho'] ?? response.data;
        final createdTrabalho = TrabalhoModel.fromJson(trabalhoData as Map<String, dynamic>);
        return DomainResult.success(createdTrabalho);
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao criar trabalho: $e');
    }
  }

  static Future<DomainResult<TrabalhoModel>> update(String id, TrabalhoModel trabalho) async {
    try {
      final response = await ApiService.updateTrabalho(id, trabalho.toJson());
      
      if (response.success && response.data != null) {
        final trabalhoData = response.data!['trabalho'] ?? response.data;
        final updatedTrabalho = TrabalhoModel.fromJson(trabalhoData as Map<String, dynamic>);
        return DomainResult.success(updatedTrabalho);
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao atualizar trabalho: $e');
    }
  }

  static Future<DomainResult<bool>> delete(String id) async {
    try {
      final response = await ApiService.deleteTrabalho(id);
      
      if (response.success) {
        return DomainResult.success(true);
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao deletar trabalho: $e');
    }
  }
}
