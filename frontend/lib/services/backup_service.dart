import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:motouber/services/database_service.dart';
import 'package:motouber/models/trabalho_model.dart';
import 'package:motouber/models/gasto_model.dart';
import 'package:motouber/models/manutencao_model.dart';

class BackupService {
  static Future<Map<String, dynamic>> _exportAllData() async {
    final db = DatabaseService.instance;

    final trabalhos = await db.getAllTrabalhos();
    final gastos = await db.getAllGastos();
    final manutencoes = await db.getAllManutencao();

    return {
      'version': '2.0',
      'export_date': DateTime.now().toIso8601String(),
      'data': {
        'trabalhos': trabalhos.map((t) => t.toMap()).toList(),
        'gastos': gastos.map((g) => g.toMap()).toList(),
        'manutencoes': manutencoes.map((m) => m.toMap()).toList(),
      },
      'stats': {
        'total_trabalhos': trabalhos.length,
        'total_gastos': gastos.length,
        'total_manutencoes': manutencoes.length,
      }
    };
  }

  static Future<String> createBackup() async {
    try {
      final data = await _exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'kmdollar_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Erro ao criar backup: $e');
    }
  }

  static Future<void> shareBackup() async {
    try {
      final filePath = await createBackup();

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Backup KM\$ - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        subject: 'Backup dos dados do KM\$',
      );
    } catch (e) {
      throw Exception('Erro ao compartilhar backup: $e');
    }
  }

  static Future<bool> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        final data = jsonDecode(content) as Map<String, dynamic>;
        
        if (!data.containsKey('data')) {
          throw Exception('Formato de backup inválido');
        }

        await _restoreData(data['data'] as Map<String, dynamic>);
        return true;
      }

      return false;
    } catch (e) {
      throw Exception('Erro ao restaurar backup: $e');
    }
  }

  static Future<void> _restoreData(Map<String, dynamic> data) async {
    final db = DatabaseService.instance;
    
    // Restaurar trabalhos
    if (data.containsKey('trabalhos')) {
      for (var trabalhoData in data['trabalhos']) {
        final trabalho = TrabalhoModel.fromMap(trabalhoData);
        await db.insertTrabalho(trabalho);
      }
    }
    
    // Restaurar gastos
    if (data.containsKey('gastos')) {
      for (var gastoData in data['gastos']) {
        final gasto = GastoModel.fromMap(gastoData);
        await db.insertGasto(gasto);
      }
    }
    
    // Restaurar manutenções
    if (data.containsKey('manutencoes')) {
      for (var manutencaoData in data['manutencoes']) {
        final manutencao = ManutencaoModel.fromMap(manutencaoData);
        await db.insertManutencao(manutencao);
      }
    }
  }

  static Future<Map<String, dynamic>> getBackupInfo() async {
    try {
      final data = await _exportAllData();
      return {
        'can_backup': true,
        'total_records': data['stats']['total_trabalhos'] + 
                        data['stats']['total_gastos'] + 
                        data['stats']['total_manutencoes'],
        'last_work': data['data']['trabalhos'].isNotEmpty 
            ? data['data']['trabalhos'].last['data'] 
            : null,
        'export_date': data['export_date'],
      };
    } catch (e) {
      return {
        'can_backup': false,
        'error': e.toString(),
      };
    }
  }
}