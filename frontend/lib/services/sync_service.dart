import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'database_service.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  static SyncService get instance => _instance;
  SyncService._internal();

  final DatabaseService _db = DatabaseService.instance;
  bool _isSyncing = false;

  Future<void> syncTrabalhoToBackend(TrabalhoModel trabalho) async {
    if (_isSyncing) return;
    
    try {
      final isOnline = await ApiService.isOnline();
      if (!isOnline) return;

      final response = await ApiService.uploadTrabalhos([trabalho.toMap()]);
      if (response.success) {
        debugPrint('Trabalho sincronizado: ${trabalho.id}');
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar trabalho: $e');
    }
  }

  Future<void> syncGastoToBackend(GastoModel gasto) async {
    if (_isSyncing) return;
    
    try {
      final isOnline = await ApiService.isOnline();
      if (!isOnline) return;

      final response = await ApiService.uploadGastos([gasto.toMap()]);
      if (response.success) {
        debugPrint('Gasto sincronizado: ${gasto.id}');
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar gasto: $e');
    }
  }

  Future<void> syncManutencaoToBackend(ManutencaoModel manutencao) async {
    if (_isSyncing) return;
    
    try {
      final isOnline = await ApiService.isOnline();
      if (!isOnline) return;

      final response = await ApiService.uploadManutencao([manutencao.toMap()]);
      if (response.success) {
        debugPrint('Manutenção sincronizada: ${manutencao.id}');
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar manutenção: $e');
    }
  }

  Future<void> downloadAllDataFromBackend() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final isOnline = await ApiService.isOnline();
      if (!isOnline) {
        _isSyncing = false;
        return;
      }

      await Future.wait([
        _downloadTrabalhos(),
        _downloadGastos(),
        _downloadManutencoes(),
      ]);

      debugPrint('Dados sincronizados do backend com sucesso');
    } catch (e) {
      debugPrint('Erro ao baixar dados do backend: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _downloadTrabalhos() async {
    try {
      final response = await ApiService.downloadTrabalhos();
      if (response.success && response.data != null) {
        final trabalhos = (response.data!['trabalhos'] as List?)
            ?.map((json) => TrabalhoModel.fromMap(json as Map<String, dynamic>))
            .toList() ?? [];

        for (final trabalho in trabalhos) {
          await _db.insertOrUpdateTrabalho(trabalho);
        }
      }
    } catch (e) {
      debugPrint('Erro ao baixar trabalhos: $e');
    }
  }

  Future<void> _downloadGastos() async {
    try {
      final response = await ApiService.downloadGastos();
      if (response.success && response.data != null) {
        final gastos = (response.data!['gastos'] as List?)
            ?.map((json) => GastoModel.fromMap(json as Map<String, dynamic>))
            .toList() ?? [];

        for (final gasto in gastos) {
          await _db.insertOrUpdateGasto(gasto);
        }
      }
    } catch (e) {
      debugPrint('Erro ao baixar gastos: $e');
    }
  }

  Future<void> _downloadManutencoes() async {
    try {
      final response = await ApiService.downloadManutencoes();
      if (response.success && response.data != null) {
        final manutencoes = (response.data!['manutencao'] as List?)
            ?.map((json) => ManutencaoModel.fromMap(json as Map<String, dynamic>))
            .toList() ?? [];

        for (final manutencao in manutencoes) {
          await _db.insertOrUpdateManutencao(manutencao);
        }
      }
    } catch (e) {
      debugPrint('Erro ao baixar manutenções: $e');
    }
  }

  Future<void> syncAllLocalDataToBackend() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final isOnline = await ApiService.isOnline();
      if (!isOnline) {
        _isSyncing = false;
        return;
      }

      final trabalhos = await _db.getTrabalhos();
      if (trabalhos.isNotEmpty) {
        await ApiService.uploadTrabalhos(trabalhos.map((t) => t.toMap()).toList());
      }

      final gastos = await _db.getGastos();
      if (gastos.isNotEmpty) {
        await ApiService.uploadGastos(gastos.map((g) => g.toMap()).toList());
      }

      final manutencoes = await _db.getManutencoes();
      if (manutencoes.isNotEmpty) {
        await ApiService.uploadManutencao(manutencoes.map((m) => m.toMap()).toList());
      }

      debugPrint('Dados locais sincronizados para o backend com sucesso');
    } catch (e) {
      debugPrint('Erro ao sincronizar dados locais: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
