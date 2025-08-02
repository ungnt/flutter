import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:supabase/supabase.dart';

void main() async {
  // Carregar variáveis de ambiente
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseServiceKey = env['SUPABASE_SERVICE_ROLE_KEY'];
  
  if (supabaseUrl == null) {
    print('❌ SUPABASE_URL não encontrado no .env');
    exit(1);
  }

  // Usar service role key se disponível, senão anon key
  final key = supabaseServiceKey ?? env['SUPABASE_ANON_KEY'];
  if (key == null) {
    print('❌ Nenhuma chave Supabase encontrada no .env');
    exit(1);
  }

  print('🔗 Conectando ao Supabase...');
  final supabase = SupabaseClient(supabaseUrl, key);

  // Criar tabelas uma por uma
  await createTables(supabase);
}

Future<void> createTables(SupabaseClient supabase) async {
  print('📋 Criando tabelas do banco de dados...');

  final sqlCommands = [
    // Tabela trabalho
    '''
    CREATE TABLE IF NOT EXISTS trabalho (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      user_id UUID NOT NULL,
      data DATE NOT NULL,
      ganhos DECIMAL(10,2) NOT NULL,
      quilometragem_inicial INTEGER NOT NULL,
      quilometragem_final INTEGER NOT NULL,
      horas_trabalhadas DECIMAL(4,2) NOT NULL,
      observacoes TEXT,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );
    ''',
    
    // Tabela gastos
    '''
    CREATE TABLE IF NOT EXISTS gastos (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      user_id UUID NOT NULL,
      data DATE NOT NULL,
      categoria VARCHAR(50) NOT NULL,
      valor DECIMAL(10,2) NOT NULL,
      descricao TEXT,
      local VARCHAR(100),
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );
    ''',
    
    // Tabela manutencoes
    '''
    CREATE TABLE IF NOT EXISTS manutencoes (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
      user_id UUID NOT NULL,
      data DATE NOT NULL,
      tipo VARCHAR(50) NOT NULL,
      valor DECIMAL(10,2) NOT NULL,
      quilometragem INTEGER NOT NULL,
      descricao TEXT,
      oficina VARCHAR(100),
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );
    ''',
  ];

  // Tentar executar via RPC se disponível
  for (int i = 0; i < sqlCommands.length; i++) {
    final tableName = ['trabalho', 'gastos', 'manutencoes'][i];
    print('📝 Criando tabela: $tableName');
    
    try {
      // Tentar inserir um registro de teste para verificar se a tabela existe
      await supabase.from(tableName).select('count').limit(1);
      print('✅ Tabela $tableName já existe');
    } catch (e) {
      print('⚠️  Tabela $tableName não existe. Erro: $e');
      print('💡 Execute manualmente no dashboard Supabase:');
      print(sqlCommands[i]);
      print('---');
    }
  }

  // Verificar tabelas existentes
  print('\n🔍 Verificando tabelas criadas...');
  final tables = ['users', 'trabalho', 'gastos', 'manutencoes'];
  
  for (final table in tables) {
    try {
      await supabase.from(table).select('count').limit(1);
      print('✅ $table - OK');
    } catch (e) {
      print('❌ $table - Não existe');
    }
  }
  
  print('\n🎯 Para criar as tabelas faltantes:');
  print('1. Acesse: https://supabase.com/dashboard/project/[seu-project-id]/sql');
  print('2. Execute o SQL acima para cada tabela');
  print('3. Execute novamente este script para verificar');
}