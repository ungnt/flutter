import 'package:supabase/supabase.dart';
import 'package:logging/logging.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final _logger = Logger('SupabaseService');
  final SupabaseClient _client;
  static SupabaseService? _instance;

  SupabaseService(String url, String anonKey)
      : _client = SupabaseClient(url, anonKey) {
    _instance = this;
  }

  static SupabaseClient get client {
    if (_instance == null) {
      throw StateError('SupabaseService não foi inicializado');
    }
    return _instance!._client;
  }

  /// Inicializar tabelas (executar uma vez)
  Future<void> initializeTables() async {
    try {
      _logger.info('Inicializando tabelas do banco...');
      
      // Supabase não suporta RPC exec_sql diretamente
      // Vamos criar as tabelas via SQL Editor ou usar SQL direto
      
      // Tentar criar tabela users primeiro
      try {
        await _client
            .from('users')
            .select('count')
            .limit(1);
        _logger.info('Tabela users já existe');
      } catch (e) {
        _logger.info('Tabelas devem ser criadas via SQL Editor do Supabase');
        _logger.info('Execute este SQL no dashboard Supabase:');
        _logger.info('''
        -- Criar tabela users
        CREATE TABLE IF NOT EXISTS users (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          email TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          password_hash TEXT NOT NULL,
          is_premium BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP DEFAULT NOW(),
          premium_until TIMESTAMP,
          updated_at TIMESTAMP DEFAULT NOW()
        );
        
        -- Índices para performance
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        CREATE INDEX IF NOT EXISTS idx_users_premium ON users(is_premium);
        
        -- Tabela para dados de sincronização  
        CREATE TABLE IF NOT EXISTS sync_data (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id UUID REFERENCES users(id) ON DELETE CASCADE,
          table_name TEXT NOT NULL,
          data JSONB NOT NULL,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        );
        
        CREATE INDEX IF NOT EXISTS idx_sync_user_table ON sync_data(user_id, table_name);
        
        -- Habilitar Row Level Security
        ALTER TABLE users ENABLE ROW LEVEL SECURITY;
        ALTER TABLE sync_data ENABLE ROW LEVEL SECURITY;
        
        -- Políticas básicas (opcional - para maior segurança)
        CREATE POLICY "Users can view own data" ON users FOR SELECT USING (true);
        CREATE POLICY "Users can insert own data" ON users FOR INSERT WITH CHECK (true);
        CREATE POLICY "Sync data policy" ON sync_data FOR ALL USING (true);
        ''');
      }
      
      _logger.info('Verificação de tabelas concluída');
      
    } catch (e) {
      _logger.severe('Erro ao verificar tabelas: $e');
      rethrow;
    }
  }

  /// Criar novo usuário
  Future<UserModel?> createUser({
    required String email,
    required String name,
    required String hashedPassword,
  }) async {
    try {
      final response = await _client
          .from('users')
          .insert({
            'email': email,
            'name': name,
            'password_hash': hashedPassword,
          })
          .select()
          .single();

      return UserModel.fromJson(response);
      
    } catch (e) {
      _logger.severe('Erro ao criar usuário: $e');
      return null;
    }
  }

  /// Buscar usuário por email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _client
          .from('users')
          .select('id, email, name, is_premium, created_at')
          .eq('email', email)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
      
    } catch (e) {
      _logger.warning('Erro ao buscar usuário por email: $e');
      return null;
    }
  }

  /// Buscar usuário por ID
  Future<UserModel?> getUserById(String id) async {
    try {
      final response = await _client
          .from('users')
          .select('id, email, name, is_premium, created_at')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
      
    } catch (e) {
      _logger.warning('Erro ao buscar usuário por ID: $e');
      return null;
    }
  }

  /// Buscar senha hasheada do usuário
  Future<String?> getUserPassword(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('password_hash')
          .eq('id', userId)
          .maybeSingle();

      return response?['password_hash'] as String?;
      
    } catch (e) {
      _logger.warning('Erro ao buscar senha: $e');
      return null;
    }
  }

  /// Atualizar status Premium do usuário
  Future<bool> updatePremiumStatus(String userId, {
    required bool isPremium,
    DateTime? premiumUntil,
  }) async {
    try {
      await _client
          .from('users')
          .update({
            'is_premium': isPremium,
            'premium_until': premiumUntil?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return true;
      
    } catch (e) {
      _logger.severe('Erro ao atualizar status premium: $e');
      return false;
    }
  }

  /// Salvar dados de sincronização
  Future<bool> saveSyncData(String userId, String tableName, Map<String, dynamic> data) async {
    try {
      // Primeiro, deletar dados antigos desta tabela
      await _client
          .from('sync_data')
          .delete()
          .eq('user_id', userId)
          .eq('table_name', tableName);

      // Inserir novos dados
      await _client
          .from('sync_data')
          .insert({
            'user_id': userId,
            'table_name': tableName,
            'data': data,
          });

      return true;
      
    } catch (e) {
      _logger.severe('Erro ao salvar dados de sync: $e');
      return false;
    }
  }

  /// Buscar dados de sincronização
  Future<Map<String, dynamic>?> getSyncData(String userId, String tableName) async {
    try {
      final response = await _client
          .from('sync_data')
          .select('data')
          .eq('user_id', userId)
          .eq('table_name', tableName)
          .maybeSingle();

      return response?['data'] as Map<String, dynamic>?;
      
    } catch (e) {
      _logger.warning('Erro ao buscar dados de sync: $e');
      return null;
    }
  }

  /// Listar todas as tabelas sincronizadas de um usuário
  Future<List<String>> getUserSyncTables(String userId) async {
    try {
      final response = await _client
          .from('sync_data')
          .select('table_name')
          .eq('user_id', userId);

      return (response as List)
          .map((row) => row['table_name'] as String)
          .toList();
          
    } catch (e) {
      _logger.warning('Erro ao listar tabelas de sync: $e');
      return [];
    }
  }
}