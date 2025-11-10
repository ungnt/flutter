import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://zmxigdwkgxirixtmwtwr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpteGlnZHdrZ3hpcml4dG13dHdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxMjE3MzEsImV4cCI6MjA2ODY5NzczMX0.saLVW4cLUc4cr6125un6rryD51y1e65lDbL8L27oorA',
  );

  print('Testando conexão com Supabase...');
  
  try {
    // Tenta listar usuários
    final response = await supabase
        .from('users')
        .select('email, name, is_premium, created_at')
        .limit(10);
    
    print('✅ Conexão OK!');
    print('\nUsuários encontrados:');
    print(response);
  } catch (e) {
    print('❌ Erro: $e');
  }
}
