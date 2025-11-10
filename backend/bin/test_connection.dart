import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://zmxigdwkgxirixtmwtwr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpteGlnZHdrZ3hpcml4dG13dHdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxMjE3MzEsImV4cCI6MjA2ODY5NzczMX0.saLVW4cLUc4cr6125un6rryD51y1e65lDbL8L27oorA',
  );

  print('🔌 Testando conexão com Supabase...\n');
  
  try {
    final response = await supabase
        .from('users')
        .select('email, name, is_premium, created_at')
        .limit(10);
    
    print('✅ Conexão OK!');
    print('📊 Total de usuários: ${response.length}\n');
    
    if (response.isEmpty) {
      print('Nenhum usuário cadastrado ainda.');
    } else {
      print('Usuários cadastrados:');
      for (var user in response) {
        print('  - ${user['email']} | ${user['name']} | Premium: ${user['is_premium']}');
      }
    }
  } catch (e) {
    print('❌ Erro: $e');
  }
}
