import 'package:shelf/shelf.dart';

/// Middleware de rate limiting para proteger APIs
Middleware rateLimiterMiddleware() {
  // TODO: Implementar rate limiting real com cache (Redis ou em memória)
  // Por agora, middleware passthrough
  
  final Map<String, List<DateTime>> _requestHistory = {};
  const int maxRequests = 100; // máximo de requests
  const Duration windowDuration = Duration(minutes: 15); // janela de tempo
  
  return (Handler innerHandler) {
    return (Request request) async {
      final clientIp = request.headers['x-forwarded-for'] ?? 
                      request.headers['x-real-ip'] ?? 
                      'unknown';
      
      // Limpar requests antigos
      final now = DateTime.now();
      _requestHistory[clientIp]?.removeWhere(
        (time) => now.difference(time) > windowDuration
      );
      
      // Verificar limite
      final currentRequests = _requestHistory[clientIp]?.length ?? 0;
      if (currentRequests >= maxRequests) {
        return Response(429, 
          body: '{"error": "Rate limit exceeded", "message": "Muitas requisições. Tente novamente em 15 minutos."}',
          headers: {'Content-Type': 'application/json'}
        );
      }
      
      // Registrar request atual
      _requestHistory[clientIp] = (_requestHistory[clientIp] ?? [])..add(now);
      
      return await innerHandler(request);
    };
  };
}