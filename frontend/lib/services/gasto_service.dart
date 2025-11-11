import '../models/gasto_model.dart';
import '../utils/domain_result.dart';
import 'api_service.dart';

class GastoService {
  static Future<DomainResult<List<GastoModel>>> getAll() async {
    try {
      final response = await ApiService.getGastos();
      
      if (response.success && response.data != null) {
        final gastosList = response.data!['gastos'] as List?;
        if (gastosList != null) {
          final gastos = gastosList
              .map((json) => GastoModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return DomainResult.success(gastos);
        }
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao buscar gastos: $e');
    }
  }

  static Future<DomainResult<GastoModel>> create(GastoModel gasto) async {
    try {
      final response = await ApiService.createGasto(gasto.toJson());
      
      if (response.success && response.data != null) {
        final gastoData = response.data!['gasto'] ?? response.data;
        final createdGasto = GastoModel.fromJson(gastoData as Map<String, dynamic>);
        return DomainResult.success(createdGasto);
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao criar gasto: $e');
    }
  }

  static Future<DomainResult<GastoModel>> update(String id, GastoModel gasto) async {
    try {
      final response = await ApiService.updateGasto(id, gasto.toJson());
      
      if (response.success && response.data != null) {
        final gastoData = response.data!['gasto'] ?? response.data;
        final updatedGasto = GastoModel.fromJson(gastoData as Map<String, dynamic>);
        return DomainResult.success(updatedGasto);
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao atualizar gasto: $e');
    }
  }

  static Future<DomainResult<bool>> delete(String id) async {
    try {
      final response = await ApiService.deleteGasto(id);
      
      if (response.success) {
        return DomainResult.success(true);
      }
      
      return DomainResult.failure(response.message);
    } catch (e) {
      return DomainResult.failure('Erro ao deletar gasto: $e');
    }
  }
}
