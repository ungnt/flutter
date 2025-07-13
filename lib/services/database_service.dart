import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('motouber.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabela de trabalho
    await db.execute('''
      CREATE TABLE trabalho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        ganhos REAL NOT NULL,
        km REAL NOT NULL,
        combustivel REAL NOT NULL,
        horas REAL NOT NULL,
        observacoes TEXT,
        data_registro TEXT NOT NULL
      )
    ''');

    // Tabela de gastos
    await db.execute('''
      CREATE TABLE gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        categoria TEXT NOT NULL,
        valor REAL NOT NULL,
        descricao TEXT,
        data_registro TEXT NOT NULL
      )
    ''');

    // Tabela de manutenções
    await db.execute('''
      CREATE TABLE manutencoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        tipo TEXT NOT NULL,
        valor REAL NOT NULL,
        km_atual REAL NOT NULL,
        descricao TEXT,
        data_registro TEXT NOT NULL
      )
    ''');

    // Tabela de configurações
    await db.execute('''
      CREATE TABLE config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chave TEXT UNIQUE NOT NULL,
        valor TEXT NOT NULL
      )
    ''');

    // Inserir configurações padrão
    await _insertDefaultConfig(db);
  }

  Future<void> _insertDefaultConfig(Database db) async {
    final defaultCategories = [
      'Combustível',
      'Alimentação',
      'Pedágio',
      'Estacionamento',
      'Limpeza',
      'Outros'
    ];

    final defaultMaintenanceTypes = [
      'Troca de óleo',
      'Revisão geral',
      'Pneus',
      'Freios',
      'Filtros',
      'Velas',
      'Correia',
      'Outros'
    ];

    await db.insert('config', {
      'chave': 'categorias_gastos',
      'valor': defaultCategories.join(','),
    });

    await db.insert('config', {
      'chave': 'tipos_manutencao',
      'valor': defaultMaintenanceTypes.join(','),
    });
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
      where = 'data BETWEEN ? AND ?';
      whereArgs = [dataInicio.toIso8601String(), dataFim.toIso8601String()];
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
      where = 'data BETWEEN ? AND ?';
      whereArgs = [dataInicio.toIso8601String(), dataFim.toIso8601String()];
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

  // Métodos para manutenções
  Future<int> insertManutencao(ManutencaoModel manutencao) async {
    final db = await database;
    return await db.insert('manutencoes', manutencao.toMap());
  }

  Future<List<ManutencaoModel>> getManutencoes({DateTime? dataInicio, DateTime? dataFim}) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (dataInicio != null && dataFim != null) {
      where = 'data BETWEEN ? AND ?';
      whereArgs = [dataInicio.toIso8601String(), dataFim.toIso8601String()];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'manutencoes',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'data DESC',
    );

    return List.generate(maps.length, (i) => ManutencaoModel.fromMap(maps[i]));
  }

  Future<int> updateManutencao(ManutencaoModel manutencao) async {
    final db = await database;
    return await db.update(
      'manutencoes',
      manutencao.toMap(),
      where: 'id = ?',
      whereArgs: [manutencao.id],
    );
  }

  Future<int> deleteManutencao(int id) async {
    final db = await database;
    return await db.delete(
      'manutencoes',
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
}