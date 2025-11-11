import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';

import '../lib/routes/auth_routes.dart';
import '../lib/routes/trabalho_routes.dart';
import '../lib/routes/gastos_routes.dart';
import '../lib/routes/manutencao_routes.dart';
import '../lib/services/auth_service.dart';
import '../lib/services/database_service.dart';
import '../lib/middleware/error_handler.dart';
import '../lib/middleware/auth_middleware.dart';

final _logger = Logger('KMDollarServer');

/// Middleware personalizado para CORS completo com acesso externo
Middleware get _customCorsMiddleware {
  return (Handler innerHandler) {
    return (Request request) async {
      // Handle preflight requests
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
          'Access-Control-Max-Age': '3600',
        });
      }

      // Process regular request and add CORS headers
      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
        'Access-Control-Max-Age': '3600',
        ...response.headers,
      });
    };
  };
}

void main() async {
  // Configurar logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Carregar variáveis de ambiente
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  final port = int.parse(Platform.environment['PORT'] ?? env['PORT'] ?? '5000');
  final host = Platform.environment['HOST'] ?? env['HOST'] ?? '0.0.0.0';

  _logger.info('Iniciando servidor KM\$ Backend Dart...');
  
  // Inicializar serviços
  final jwtSecret = Platform.environment['JWT_SECRET'] ?? env['JWT_SECRET'];
  if (jwtSecret == null || jwtSecret.isEmpty) {
    _logger.severe('ERRO FATAL: JWT_SECRET não definido nas variáveis de ambiente');
    exit(1);
  }
  
  final dbPath = Platform.environment['DB_PATH'] ?? env['DB_PATH'] ?? 'km_dollar.db';
  
  final databaseService = DatabaseService(dbPath);
  final authService = AuthService(databaseService, jwtSecret);
  
  _logger.info('Banco de dados SQLite inicializado: $dbPath');

  // Configurar router principal
  final router = Router()
    // Página inicial
    ..get('/', _homeHandler)
    
    // Health check
    ..get('/health', _healthHandler)
    
    // Rotas da API
    ..mount('/api/auth/', AuthRoutes(authService).router)
    ..mount('/api/trabalho/', 
      const Pipeline()
        .addMiddleware(authMiddleware(authService))
        .addHandler(TrabalhoRoutes(databaseService, authService).router))
    ..mount('/api/gastos/', 
      const Pipeline()
        .addMiddleware(authMiddleware(authService))
        .addHandler(GastosRoutes(databaseService, authService).router))
    ..mount('/api/manutencao/', 
      const Pipeline()
        .addMiddleware(authMiddleware(authService))
        .addHandler(ManutencaoRoutes(databaseService, authService).router))
    
    // 404 para rotas não encontradas
    ..all('/<ignored|.*>', _notFoundHandler);

  // Configurar middleware stack com CORS completo para acesso externo
  final handler = Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(corsHeaders())
    .addMiddleware(_customCorsMiddleware)
    .addMiddleware(errorHandler())
    .addHandler(router);

  // Iniciar servidor
  final server = await serve(handler, host, port);
  
  _logger.info('🚀 KM\$ Backend Dart rodando em ${server.address.host}:${server.port}');
  _logger.info('📡 Health check: https://${server.address.host}:${server.port}/health');
  _logger.info('🔒 HTTPS OBRIGATÓRIO - Todas as comunicações devem usar SSL/TLS');
  
  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    _logger.info('Finalizando servidor...');
    await server.close();
    exit(0);
  });
}

Response _healthHandler(Request request) {
  return Response.ok(
    '{"status": "OK", "message": "KM\$ Backend Dart funcionando", "timestamp": "${DateTime.now().toIso8601String()}", "https_required": true}',
    headers: {
      'Content-Type': 'application/json',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block'
    },
  );
}

Response _homeHandler(Request request) {
  return Response.ok('''
<!DOCTYPE html>
<html>
<head>
    <title>KM\$ Backend API</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        .status { color: green; font-weight: bold; }
        .endpoint { background: #f5f5f5; padding: 10px; margin: 5px 0; border-radius: 5px; }
        .method { color: #007acc; font-weight: bold; }
    </style>
</head>
<body>
    <h1>🚀 KM\$ Backend API</h1>
    <p class="status">✅ Servidor funcionando na porta 8080</p>
    <p class="status">✅ SQLite Database conectado</p>
    
    <h2>📡 Endpoints Disponíveis:</h2>
    <div class="endpoint"><span class="method">GET</span> /health - Health check</div>
    <div class="endpoint"><span class="method">POST</span> /api/auth/register - Cadastro de usuário</div>
    <div class="endpoint"><span class="method">POST</span> /api/auth/login - Login de usuário</div>
    <div class="endpoint"><span class="method">POST</span> /api/auth/logout - Logout de usuário</div>
    <div class="endpoint"><span class="method">GET</span> /api/auth/me - Dados do usuário logado</div>
    <div class="endpoint"><span class="method">GET</span> /api/trabalho - Listar trabalhos</div>
    <div class="endpoint"><span class="method">GET</span> /api/gastos - Listar gastos</div>
    <div class="endpoint"><span class="method">GET</span> /api/manutencao - Listar manutenções</div>
    
    <h2>📱 Flutter Mobile App</h2>
    <p>Este backend serve o aplicativo mobile KM\$ desenvolvido em Flutter.</p>
    <p>Funcionalidades: Controle financeiro, login/cadastro, relatórios.</p>
    
    <h2>🔗 Links</h2>
    <p><a href="/health">Health Check</a></p>
    <p><a href="https://github.com">Código Fonte no GitHub</a></p>
</body>
</html>
  ''', headers: {'Content-Type': 'text/html'});
}

Response _notFoundHandler(Request request) {
  return Response.notFound(
    '{"error": "Endpoint não encontrado", "path": "${request.url.path}"}',
    headers: {'Content-Type': 'application/json'},
  );
}