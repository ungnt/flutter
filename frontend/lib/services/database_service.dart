import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Para web, usar sqflite_common_ffi_web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        'km_dollar_web.db',
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
    
    // Para mobile/desktop, usar path normal
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'km_dollar.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de trabalho com dual-ID system
    await db.execute('''
      CREATE TABLE trabalho (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT UNIQUE,
        user_id TEXT,
        data TEXT NOT NULL,
        ganhos REAL NOT NULL,
        km REAL NOT NULL,
        horas REAL NOT NULL,
        observacoes TEXT,
        data_registro TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabela de gastos com dual-ID system
    await db.execute('''
      CREATE TABLE gastos (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT UNIQUE,
        user_id TEXT,
        data TEXT NOT NULL,
        categoria TEXT NOT NULL,
        valor REAL NOT NULL,
        descricao TEXT,
        data_registro TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabela de manutenções com dual-ID system
    await db.execute('''
      CREATE TABLE manutencao (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT UNIQUE,
        user_id TEXT,
        data TEXT NOT NULL,
        tipo TEXT NOT NULL,
        valor REAL NOT NULL,
        km_atual REAL NOT NULL,
        descricao TEXT,
        data_registro TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabela de configurações
    await db.execute('''
      CREATE TABLE config (
        chave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');

    // Tabela de intervalos de manutenção
    await db.execute('''
      CREATE TABLE intervalos_manutencao (
        tipo TEXT PRIMARY KEY,
        intervalo_km INTEGER NOT NULL
      )
    ''');

    // Inserir intervalos padrão
    await _insertDefaultIntervals(db);
    
    // Inserir categorias de gastos padrão
    await _insertDefaultCategories(db);
    
    // Inserir tipos de manutenção padrão
    await _insertDefaultTiposManutencao(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Remover campo combustível da tabela trabalho se existir
      await db.execute('DROP TABLE IF EXISTS trabalho_old');
      await db.execute('ALTER TABLE trabalho RENAME TO trabalho_old');

      await db.execute('''
        CREATE TABLE trabalho (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          data TEXT NOT NULL,
          ganhos REAL NOT NULL,
          km REAL NOT NULL,
          horas REAL NOT NULL,
          observacoes TEXT,
          data_registro TEXT NOT NULL
        )
      ''');

      await db.execute('''
        INSERT INTO trabalho (id, data, ganhos, km, horas, observacoes, data_registro)
        SELECT id, data, ganhos, km, horas, observacoes, data_registro FROM trabalho_old
      ''');

      await db.execute('DROP TABLE trabalho_old');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS intervalos_manutencao (
          tipo TEXT PRIMARY KEY,
          intervalo_km INTEGER NOT NULL
        )
      ''');
      await _insertDefaultIntervals(db);
      await _insertDefaultCategories(db);
      await _insertDefaultTiposManutencao(db);
    }
  }

  Future<void> _insertDefaultIntervals(Database db) async {
    final defaultIntervals = {
      'Troca de óleo': 3000,
      'Revisão geral': 5000,
      'Pneus': 10000,
      'Freios': 8000,
      'Filtros': 6000,
      'Velas': 12000,
      'Correia': 15000,
      'Relação': 5000,
      'Óleo de freio': 5000,
      'Outros': 5000,
    };

    for (var entry in defaultIntervals.entries) {
      await db.insert(
        'intervalos_manutencao',
        {'tipo': entry.key, 'intervalo_km': entry.value},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      'Combustível',
      'Manutenção',
      'Multas/IPVA',
      'Alimentação',
      'Equipamentos',
      'Documentação',
      'Pedágio',
      'Estacionamento',
      'Lavagem',
      'Outros',
    ];

    await db.insert(
      'config',
      {'chave': 'categorias_gastos', 'valor': defaultCategories.join(',')},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _insertDefaultTiposManutencao(Database db) async {
    final defaultTipos = [
      'Troca de óleo',
      'Revisão geral',
      'Pneus',
      'Freios',
      'Filtros',
      'Velas',
      'Correia',
      'Relação',
      'Óleo de freio',
      'Outros',
    ];

    await db.insert(
      'config',
      {'chave': 'tipos_manutencao', 'valor': defaultTipos.join(',')},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Método initDatabase para compatibilidade com main.dart
  Future<void> initDatabase() async {
    await database;
  }

  Future<void> init() async {
    await database;
  }

  // Métodos para trabalho
  Future<int> insertTrabalho(TrabalhoModel trabalho) async {
    final db = await database;
    return await db.insert('trabalho', trabalho.toMap());
  }

  Future<List<TrabalhoModel>> getTrabalhos({DateTime? dataInicio, DateTime? dataFim}) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (dataInicio != null && dataFim != null) {
      where = 'DATE(data) BETWEEN ? AND ?';
      whereArgs = [dataInicio.toIso8601String().split('T')[0], dataFim.toIso8601String().split('T')[0]];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'trabalho',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'data DESC',
    );

    return List.generate(maps.length, (i) => TrabalhoModel.fromMap(maps[i]));
  }

  Future<int> updateTrabalho(TrabalhoModel trabalho) async {
    final db = await database;
    return await db.update(
      'trabalho',
      trabalho.toMap(),
      where: 'id = ?',
      whereArgs: [trabalho.id],
    );
  }

  Future<int> deleteTrabalho(int id) async {
    final db = await database;
    return await db.delete(
      'trabalho',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método específico para buscar trabalhos por período (usado pelo GoalsService)
  Future<List<TrabalhoModel>> getTrabalhosByPeriod(DateTime startDate, DateTime endDate) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'trabalho',
      where: 'DATE(data) BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String().split('T')[0], 
        endDate.toIso8601String().split('T')[0]
      ],
      orderBy: 'data DESC',
    );

    return List.generate(maps.length, (i) => TrabalhoModel.fromMap(maps[i]));
  }

  // Métodos para gastos
  Future<int> insertGasto(GastoModel gasto) async {
    final db = await database;
    return await db.insert('gastos', gasto.toMap());
  }

  Future<List<GastoModel>> getGastos({DateTime? dataInicio, DateTime? dataFim}) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (dataInicio != null && dataFim != null) {
      where = 'DATE(data) BETWEEN ? AND ?';
      whereArgs = [dataInicio.toIso8601String().split('T')[0], dataFim.toIso8601String().split('T')[0]];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'gastos',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'data DESC',
    );

    return List.generate(maps.length, (i) => GastoModel.fromMap(maps[i]));
  }

  Future<int> updateGasto(GastoModel gasto) async {
    final db = await database;
    return await db.update(
      'gastos',
      gasto.toMap(),
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  Future<int> deleteGasto(int id) async {
    final db = await database;
    return await db.delete(
      'gastos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método específico para buscar gastos por período (usado pelo GoalsService)
  Future<List<GastoModel>> getGastosByPeriod(DateTime startDate, DateTime endDate) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'gastos',
      where: 'DATE(data) BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String().split('T')[0], 
        endDate.toIso8601String().split('T')[0]
      ],
      orderBy: 'data DESC',
    );

    return List.generate(maps.length, (i) => GastoModel.fromMap(maps[i]));
  }

  // Métodos para manutenções
  Future<int> insertManutencao(ManutencaoModel manutencao) async {
    final db = await database;
    return await db.insert('manutencao', manutencao.toMap());
  }

  /// Insert ou Update manutenção (para sincronização)
  Future<int> insertOrUpdateManutencao(ManutencaoModel manutencao) async {
    final db = await database;
    return await db.insert(
      'manutencao',
      manutencao.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert ou Update gasto (para sincronização)
  Future<int> insertOrUpdateGasto(GastoModel gasto) async {
    final db = await database;
    return await db.insert(
      'gastos',
      gasto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert ou Update trabalho (para sincronização)
  Future<int> insertOrUpdateTrabalho(TrabalhoModel trabalho) async {
    final db = await database;
    return await db.insert(
      'trabalho',
      trabalho.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ManutencaoModel>> getManutencoes({DateTime? dataInicio, DateTime? dataFim}) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (dataInicio != null && dataFim != null) {
      where = 'DATE(data) BETWEEN ? AND ?';
      whereArgs = [dataInicio.toIso8601String().split('T')[0], dataFim.toIso8601String().split('T')[0]];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'manutencao',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'data DESC',
    );

    return List.generate(maps.length, (i) => ManutencaoModel.fromMap(maps[i]));
  }

  Future<int> updateManutencao(ManutencaoModel manutencao) async {
    final db = await database;
    return await db.update(
      'manutencao',
      manutencao.toMap(),
      where: 'id = ?',
      whereArgs: [manutencao.id],
    );
  }

  Future<int> deleteManutencao(String id) async {
    final db = await database;
    return await db.delete(
      'manutencao',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para configurações
  Future<String?> getConfig(String chave) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'config',
      where: 'chave = ?',
      whereArgs: [chave],
    );

    if (maps.isNotEmpty) {
      return maps.first['valor'];
    }
    return null;
  }

  Future<void> setConfig(String chave, String valor) async {
    final db = await database;
    await db.insert(
      'config',
      {'chave': chave, 'valor': valor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getCategoriasGastos() async {
    final categorias = await getConfig('categorias_gastos');
    return categorias?.split(',') ?? [];
  }

  Future<List<String>> getTiposManutencao() async {
    final tipos = await getConfig('tipos_manutencao');
    return tipos?.split(',') ?? [];
  }

  Future<void> setCategoriasGastos(List<String> categorias) async {
    await setConfig('categorias_gastos', categorias.join(','));
  }

  Future<void> setTiposManutencao(List<String> tipos) async {
    await setConfig('tipos_manutencao', tipos.join(','));
  }

  // Métodos adicionais para suporte completo
  Future<List<TrabalhoModel>> getAllTrabalhos() async {
    final db = await database;
    final maps = await db.query('trabalho', orderBy: 'data DESC');
    return maps.map((map) => TrabalhoModel.fromMap(map)).toList();
  }

  Future<List<GastoModel>> getAllGastos() async {
    final db = await database;
    final maps = await db.query('gastos', orderBy: 'data DESC');
    return maps.map((map) => GastoModel.fromMap(map)).toList();
  }

  Future<List<ManutencaoModel>> getAllManutencao() async {
    final db = await database;
    final maps = await db.query('manutencao', orderBy: 'data DESC');
    return maps.map((map) => ManutencaoModel.fromMap(map)).toList();
  }

  // Métodos getById necessários para sync_service.dart
  Future<GastoModel?> getGastoById(int id) async {
    final db = await database;
    final maps = await db.query('gastos', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return GastoModel.fromMap(maps.first);
    return null;
  }

  Future<ManutencaoModel?> getManutencaoById(int id) async {
    final db = await database;
    final maps = await db.query('manutencao', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return ManutencaoModel.fromMap(maps.first);
    return null;
  }

  Future<TrabalhoModel?> getTrabalhoById(int id) async {
    final db = await database;
    final maps = await db.query('trabalho', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return TrabalhoModel.fromMap(maps.first);
    return null;
  }

  // Métodos para intervalos de manutenção
  Future<int> getIntervaloManutencao(String tipo) async {
    final db = await database;
    final maps = await db.query(
      'intervalos_manutencao',
      where: 'tipo = ?',
      whereArgs: [tipo],
    );

    if (maps.isNotEmpty) {
      return maps.first['intervalo_km'] as int;
    }
    return 5000; // Valor padrão
  }

  // Métodos para gráficos
  Future<double> getGanhosByDate(DateTime date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(ganhos) as total FROM trabalho WHERE DATE(data) = ?',
      [date.toIso8601String().split('T')[0]],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getGastosByDate(DateTime date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(valor) as total FROM gastos WHERE DATE(data) = ?',
      [date.toIso8601String().split('T')[0]],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getGanhosByMonth(int year, int month) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(ganhos) as total FROM trabalho WHERE strftime("%Y", data) = ? AND strftime("%m", data) = ?',
      [year.toString(), month.toString().padLeft(2, '0')],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getGastosByMonth(int year, int month) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(valor) as total FROM gastos WHERE strftime("%Y", data) = ? AND strftime("%m", data) = ?',
      [year.toString(), month.toString().padLeft(2, '0')],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getGanhosByYear(int year) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(ganhos) as total FROM trabalho WHERE strftime("%Y", data) = ?',
      [year.toString()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getGastosByYear(int year) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(valor) as total FROM gastos WHERE strftime("%Y", data) = ?',
      [year.toString()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> setIntervaloManutencao(String tipo, int intervalokm) async {
    final db = await database;
    await db.insert(
      'intervalos_manutencao',
      {'tipo': tipo, 'intervalo_km': intervalokm},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, int>> getAllIntervalosManutencao() async {
    final db = await database;
    final maps = await db.query('intervalos_manutencao');

    Map<String, int> intervalos = {};
    for (var map in maps) {
      intervalos[map['tipo'] as String] = map['intervalo_km'] as int;
    }
    return intervalos;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('trabalho');
      await txn.delete('gastos');
      await txn.delete('manutencao');
    });
  }



  Future<List<ManutencaoModel>> getManutencoesByPeriod(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    final maps = await db.query(
      'manutencao',
      where: 'DATE(data) >= ? AND DATE(data) <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'data DESC',
    );

    return maps.map((map) => ManutencaoModel.fromMap(map)).toList();
  }
}