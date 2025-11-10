import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('km_dollar.db');
  
  print('=== USUÁRIOS ===');
  final users = db.select('SELECT id, email, name, is_premium FROM users');
  for (final user in users) {
    print('ID: ${user['id']}, Email: ${user['email']}, Nome: ${user['name']}, Premium: ${user['is_premium']}');
  }
  
  print('\n=== TRABALHOS (GANHOS) ===');
  final trabalhos = db.select('SELECT * FROM trabalho');
  print('Total: ${trabalhos.length}');
  for (final t in trabalhos) {
    print('ID: ${t['id']}, User: ${t['user_id']}, Data: ${t['data']}, Ganhos: ${t['ganhos']}, KM: ${t['km']}');
  }
  
  print('\n=== GASTOS ===');
  final gastos = db.select('SELECT * FROM gastos');
  print('Total: ${gastos.length}');
  for (final g in gastos) {
    print('ID: ${g['id']}, User: ${g['user_id']}, Data: ${g['data']}, Valor: ${g['valor']}, Categoria: ${g['categoria']}');
  }
  
  print('\n=== MANUTENÇÃO ===');
  final manutencoes = db.select('SELECT * FROM manutencao');
  print('Total: ${manutencoes.length}');
  for (final m in manutencoes) {
    print('ID: ${m['id']}, User: ${m['user_id']}, Data: ${m['data']}, Tipo: ${m['tipo']}, Valor: ${m['valor']}');
  }
  
  db.dispose();
}
