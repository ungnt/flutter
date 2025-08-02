import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';

final _logger = Logger('HTTPSEnforcer');

/// Middleware para forçar HTTPS em todas as requisições
Middleware httpsEnforcerMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Verificar se a requisição é HTTPS
      final isHttps = request.headers['x-forwarded-proto'] == 'https' ||
                      request.url.scheme == 'https' ||
                      request.headers['x-forwarded-ssl'] == 'on' ||
                      request.headers['fly-forwarded-proto'] == 'https' ||  // Fly.io specific
                      request.headers['host']?.contains('.fly.dev') == true;  // Fly.io domain
      
      // Em desenvolvimento, permitir HTTP local
      final isDevelopment = 
        request.headers['host']?.contains('localhost') == true ||
        request.headers['host']?.contains('127.0.0.1') == true ||
        request.headers['host']?.contains('replit.') == true ||
        request.headers['host']?.contains('.fly.dev') == true ||  // Fly.io para debug
        request.headers['fly-forwarded-proto'] != null;  // Fly.io internal requests
      
      // Permitir HTTP para health check (usado pelo Fly.io)
      final isHealthCheck = request.url.path == '/health';
      
      // Permitir requisições internas do Fly.io
      final isFlyInternal = request.headers['fly-client-ip'] != null ||
                           request.headers['x-forwarded-for']?.contains('172.') == true;
      
      if (!isHttps && !isDevelopment && !isHealthCheck && !isFlyInternal) {
        _logger.warning('Requisição HTTP rejeitada de ${request.headers['host']}');
        
        return Response.movedPermanently(
          'https://${request.headers['host']}${request.url.path}${request.url.hasQuery ? '?${request.url.query}' : ''}',
          headers: {
            'Content-Type': 'application/json',
            'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
          },
          body: '{"error": "HTTPS_REQUIRED", "message": "Esta API requer HTTPS para máxima segurança"}'
        );
      }
      
      // Prosseguir com a requisição, adicionando headers de segurança
      final response = await innerHandler(request);
      
      // Adicionar headers de segurança em todas as respostas
      final secureHeaders = Map<String, String>.from(response.headers)
        ..addAll({
          'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'DENY',
          'X-XSS-Protection': '1; mode=block',
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          'Content-Security-Policy': "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https:; frame-ancestors 'none';",
        });
      
      return response.change(headers: secureHeaders);
    };
  };
}