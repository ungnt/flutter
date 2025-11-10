import 'package:sqlite3/sqlite3.dart';
import 'package:logging/logging.dart';
import '../models/user_model.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';
import 'dart:convert';

class DatabaseService {
  static final _logger = Logger('DatabaseService');
  late Database _db;
  static DatabaseService? _instance;

  DatabaseService(String dbPath) {
    _db = sqlite3.open(dbPath);
    _instance = this;
    _initializeTables();
  }

  static Database get db {
    if (_instance == null) {
      throw StateError('DatabaseService não foi inicializado');
    }
    return _instance!._db;
  }

  void _initializeTables() {
    try {
      _logger.info('Criando tabelas...');
      
      _db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          email TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          password_hash TEXT NOT NULL,
          is_premium INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          premium_until TEXT,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      _db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)');
      _db.execute('CREATE INDEX IF NOT EXISTS idx_users_premium ON users(is_premium)');

      _db.execute('''
        CREATE TABLE IF NOT EXISTS sync_data (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          table_name TEXT NOT NULL,
          data TEXT NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      _db.execute('CREATE INDEX IF NOT EXISTS idx_sync_user_table ON sync_data(user_id, table_name)');

      _db.execute('''
        CREATE TABLE IF NOT EXISTS trabalho (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          data TEXT NOT NULL,
          ganhos REAL NOT NULL,
          km REAL NOT NULL,
          horas REAL NOT NULL,
          observacoes TEXT,
          data_registro TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      _db.execute('CREATE INDEX IF NOT EXISTS idx_trabalho_user ON trabalho(user_id)');
      _db.execute('CREATE INDEX IF NOT EXISTS idx_trabalho_data ON trabalho(data)');

      _db.execute('''
        CREATE TABLE IF NOT EXISTS gastos (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          data TEXT NOT NULL,
          categoria TEXT NOT NULL,
          valor REAL NOT NULL,
          descricao TEXT,
          data_registro TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      _db.execute('CREATE INDEX IF NOT EXISTS idx_gastos_user ON gastos(user_id)');
      _db.execute('CREATE INDEX IF NOT EXISTS idx_gastos_data ON gastos(data)');

      _db.execute('''
        CREATE TABLE IF NOT EXISTS manutencao (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          data TEXT NOT NULL,
          tipo TEXT NOT NULL,
          valor REAL NOT NULL,
          km_atual REAL NOT NULL,
          descricao TEXT,
          data_registro TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      _db.execute('CREATE INDEX IF NOT EXISTS idx_manutencao_user ON manutencao(user_id)');
      _db.execute('CREATE INDEX IF NOT EXISTS idx_manutencao_data ON manutencao(data)');

      _logger.info('Tabelas criadas com sucesso');
    } catch (e) {
      _logger.severe('Erro ao criar tabelas: $e');
      rethrow;
    }
  }

  Future<UserModel?> createUser({
    required String email,
    required String name,
    required String hashedPassword,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      _db.execute(
        'INSERT INTO users (id, email, name, password_hash) VALUES (?, ?, ?, ?)',
        [id, email, name, hashedPassword]
      );

      return getUserById(id);
    } catch (e) {
      _logger.severe('Erro ao criar usuário: $e');
      return null;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final result = _db.select(
        'SELECT id, email, name, is_premium, created_at FROM users WHERE email = ?',
        [email],
      );

      if (result.isEmpty) return null;
      
      final row = result.first;
      return UserModel.fromJson({
        'id': row['id'],
        'email': row['email'],
        'name': row['name'],
        'is_premium': row['is_premium'] == 1,
        'created_at': row['created_at'],
      });
    } catch (e) {
      _logger.warning('Erro ao buscar usuário por email: $e');
      return null;
    }
  }

  Future<UserModel?> getUserById(String id) async {
    try {
      final result = _db.select(
        'SELECT id, email, name, is_premium, created_at FROM users WHERE id = ?',
        [id],
      );

      if (result.isEmpty) return null;
      
      final row = result.first;
      return UserModel.fromJson({
        'id': row['id'],
        'email': row['email'],
        'name': row['name'],
        'is_premium': row['is_premium'] == 1,
        'created_at': row['created_at'],
      });
    } catch (e) {
      _logger.warning('Erro ao buscar usuário por ID: $e');
      return null;
    }
  }

  Future<String?> getUserPassword(String userId) async {
    try {
      final result = _db.select(
        'SELECT password_hash FROM users WHERE id = ?',
        [userId],
      );

      if (result.isEmpty) return null;
      return result.first['password_hash'] as String;
    } catch (e) {
      _logger.warning('Erro ao buscar senha: $e');
      return null;
    }
  }

  Future<bool> updatePremiumStatus(String userId, {
    required bool isPremium,
    DateTime? premiumUntil,
  }) async {
    try {
      _db.execute(
        'UPDATE users SET is_premium = ?, premium_until = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
        [isPremium ? 1 : 0, premiumUntil?.toIso8601String(), userId]
      );
      return true;
    } catch (e) {
      _logger.severe('Erro ao atualizar status premium: $e');
      return false;
    }
  }

  Future<bool> saveSyncData(String userId, String tableName, Map<String, dynamic> data) async {
    try {
      _db.execute(
        'DELETE FROM sync_data WHERE user_id = ? AND table_name = ?',
        [userId, tableName],
      );

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      _db.execute(
        'INSERT INTO sync_data (id, user_id, table_name, data) VALUES (?, ?, ?, ?)',
        [id, userId, tableName, jsonEncode(data)]
      );

      return true;
    } catch (e) {
      _logger.severe('Erro ao salvar dados de sync: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSyncData(String userId, String tableName) async {
    try {
      final result = _db.select(
        'SELECT data FROM sync_data WHERE user_id = ? AND table_name = ?',
        [userId, tableName],
      );

      if (result.isEmpty) return null;
      return jsonDecode(result.first['data'] as String);
    } catch (e) {
      _logger.warning('Erro ao buscar dados de sync: $e');
      return null;
    }
  }

  Future<List<String>> getUserSyncTables(String userId) async {
    try {
      final result = _db.select(
        'SELECT DISTINCT table_name FROM sync_data WHERE user_id = ?',
        [userId],
      );

      return result.map((row) => row['table_name'] as String).toList();
    } catch (e) {
      _logger.warning('Erro ao listar tabelas de sync: $e');
      return [];
    }
  }

  Future<String> createTrabalho(Map<String, dynamic> data) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _db.execute(
      'INSERT INTO trabalho (id, user_id, data, ganhos, km, horas, observacoes, data_registro) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [id, data['user_id'], data['data'], data['ganhos'], data['km'], data['horas'], data['observacoes'], data['data_registro']]
    );
    return id;
  }

  List<Map<String, dynamic>> getTrabalhosByUser(String userId) {
    final result = _db.select('SELECT * FROM trabalho WHERE user_id = ? ORDER BY data DESC', [userId]);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  void updateTrabalho(String id, Map<String, dynamic> data) {
    _db.execute(
      'UPDATE trabalho SET ganhos = ?, km = ?, horas = ?, observacoes = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [data['ganhos'], data['km'], data['horas'], data['observacoes'], id]
    );
  }

  void deleteTrabalho(String id) {
    _db.execute('DELETE FROM trabalho WHERE id = ?', [id]);
  }

  Future<String> createGasto(Map<String, dynamic> data) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _db.execute(
      'INSERT INTO gastos (id, user_id, data, categoria, valor, descricao, data_registro) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, data['user_id'], data['data'], data['categoria'], data['valor'], data['descricao'], data['data_registro']]
    );
    return id;
  }

  List<Map<String, dynamic>> getGastosByUser(String userId) {
    final result = _db.select('SELECT * FROM gastos WHERE user_id = ? ORDER BY data DESC', [userId]);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  void updateGasto(String id, Map<String, dynamic> data) {
    _db.execute(
      'UPDATE gastos SET categoria = ?, valor = ?, descricao = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [data['categoria'], data['valor'], data['descricao'], id]
    );
  }

  void deleteGasto(String id) {
    _db.execute('DELETE FROM gastos WHERE id = ?', [id]);
  }

  Future<String> createManutencao(Map<String, dynamic> data) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _db.execute(
      'INSERT INTO manutencao (id, user_id, data, tipo, valor, km_atual, descricao, data_registro) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [id, data['user_id'], data['data'], data['tipo'], data['valor'], data['km_atual'], data['descricao'], data['data_registro']]
    );
    return id;
  }

  List<Map<String, dynamic>> getManutencoesByUser(String userId) {
    final result = _db.select('SELECT * FROM manutencao WHERE user_id = ? ORDER BY data DESC', [userId]);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  void updateManutencao(String id, Map<String, dynamic> data) {
    _db.execute(
      'UPDATE manutencao SET tipo = ?, valor = ?, km_atual = ?, descricao = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [data['tipo'], data['valor'], data['km_atual'], data['descricao'], id]
    );
  }

  void deleteManutencao(String id) {
    _db.execute('DELETE FROM manutencao WHERE id = ?', [id]);
  }

  void close() {
    _db.dispose();
  }
}