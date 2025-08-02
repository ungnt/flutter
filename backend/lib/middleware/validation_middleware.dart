import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/security_service.dart';

/// Middleware avançado para validação e sanitização
class ValidationMiddleware {
  static const String _tag = '[ValidationMiddleware]';

  /// Middleware para validar dados de entrada
  static Middleware validator() {
    return (Handler innerHandler) {
      return (Request request) async {
        try {
          // Aplicar rate limiting
          final userId = request.headers['x-user-id'];
          if (userId != null) {
            final isAllowed = SecurityService.checkRateLimit(
              userId, 
              100, // 100 requests
              const Duration(minutes: 1), // por minuto
            );
            
            if (!isAllowed) {
              return Response(429, 
                body: json.encode({'error': 'Rate limit exceeded'}),
                headers: {'Content-Type': 'application/json'},
              );
            }
          }

          // Validar Content-Type para requests POST/PUT
          if (['POST', 'PUT', 'PATCH'].contains(request.method)) {
            final contentType = request.headers['content-type'];
            if (contentType == null || !contentType.contains('application/json')) {
              return Response(400,
                body: json.encode({'error': 'Content-Type deve ser application/json'}),
                headers: {'Content-Type': 'application/json'},
              );
            }
          }

          // Validar tamanho do body
          if (['POST', 'PUT', 'PATCH'].contains(request.method)) {
            final contentLength = request.headers['content-length'];
            if (contentLength != null) {
              final length = int.tryParse(contentLength) ?? 0;
              if (length > 1024 * 1024) { // 1MB limit
                return Response(413,
                  body: json.encode({'error': 'Payload muito grande'}),
                  headers: {'Content-Type': 'application/json'},
                );
              }
            }
          }

          // Continuar com o handler
          return await innerHandler(request);
        } catch (e) {
          print('$_tag Erro no middleware de validação: $e');
          return Response.internalServerError(
            body: json.encode({'error': 'Erro interno do servidor'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      };
    };
  }

  /// Middleware específico para validação de dados de trabalho
  static Middleware trabalhoValidator() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (['POST', 'PUT'].contains(request.method)) {
          try {
            final body = await request.readAsString();
            final data = json.decode(body) as Map<String, dynamic>;
            
            final validation = SecurityService.validateTrabalhoData(data);
            if (!validation.isValid) {
              return Response(400,
                body: json.encode({
                  'error': 'Dados inválidos',
                  'details': validation.errors,
                }),
                headers: {'Content-Type': 'application/json'},
              );
            }

            // Criar nova request com dados sanitizados
            final sanitizedBody = json.encode(validation.sanitizedData);
            final newRequest = Request(
              request.method,
              request.requestedUri,
              headers: request.headers,
              body: sanitizedBody,
            );

            return await innerHandler(newRequest);
          } catch (e) {
            return Response(400,
              body: json.encode({'error': 'JSON inválido'}),
              headers: {'Content-Type': 'application/json'},
            );
          }
        }

        return await innerHandler(request);
      };
    };
  }

  /// Middleware específico para validação de dados de gasto
  static Middleware gastoValidator() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (['POST', 'PUT'].contains(request.method)) {
          try {
            final body = await request.readAsString();
            final data = json.decode(body) as Map<String, dynamic>;
            
            final validation = SecurityService.validateGastoData(data);
            if (!validation.isValid) {
              return Response(400,
                body: json.encode({
                  'error': 'Dados inválidos',
                  'details': validation.errors,
                }),
                headers: {'Content-Type': 'application/json'},
              );
            }

            // Criar nova request com dados sanitizados
            final sanitizedBody = json.encode(validation.sanitizedData);
            final newRequest = Request(
              request.method,
              request.requestedUri,
              headers: request.headers,
              body: sanitizedBody,
            );

            return await innerHandler(newRequest);
          } catch (e) {
            return Response(400,
              body: json.encode({'error': 'JSON inválido'}),
              headers: {'Content-Type': 'application/json'},
            );
          }
        }

        return await innerHandler(request);
      };
    };
  }

  /// Middleware específico para validação de dados de manutenção
  static Middleware manutencaoValidator() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (['POST', 'PUT'].contains(request.method)) {
          try {
            final body = await request.readAsString();
            final data = json.decode(body) as Map<String, dynamic>;
            
            final validation = SecurityService.validateManutencaoData(data);
            if (!validation.isValid) {
              return Response(400,
                body: json.encode({
                  'error': 'Dados inválidos',
                  'details': validation.errors,
                }),
                headers: {'Content-Type': 'application/json'},
              );
            }

            // Criar nova request com dados sanitizados
            final sanitizedBody = json.encode(validation.sanitizedData);
            final newRequest = Request(
              request.method,
              request.requestedUri,
              headers: request.headers,
              body: sanitizedBody,
            );

            return await innerHandler(newRequest);
          } catch (e) {
            return Response(400,
              body: json.encode({'error': 'JSON inválido'}),
              headers: {'Content-Type': 'application/json'},
            );
          }
        }

        return await innerHandler(request);
      };
    };
  }

  /// Middleware para prevenção de SQL Injection (paranoia extra)
  static Middleware sqlInjectionPrevention() {
    return (Handler innerHandler) {
      return (Request request) async {
        // Verificar parâmetros da URL
        final queryParams = request.url.queryParameters;
        for (final value in queryParams.values) {
          if (_containsSqlInjection(value)) {
            return Response(400,
              body: json.encode({'error': 'Conteúdo suspeito detectado'}),
              headers: {'Content-Type': 'application/json'},
            );
          }
        }

        // Verificar body se for POST/PUT
        if (['POST', 'PUT', 'PATCH'].contains(request.method)) {
          try {
            final body = await request.readAsString();
            if (_containsSqlInjection(body)) {
              return Response(400,
                body: json.encode({'error': 'Conteúdo suspeito detectado'}),
                headers: {'Content-Type': 'application/json'},
              );
            }

            // Recriar request com o body lido
            final newRequest = Request(
              request.method,
              request.requestedUri,
              headers: request.headers,
              body: body,
            );

            return await innerHandler(newRequest);
          } catch (e) {
            return Response(400,
              body: json.encode({'error': 'Erro ao processar request'}),
              headers: {'Content-Type': 'application/json'},
            );
          }
        }

        return await innerHandler(request);
      };
    };
  }

  /// Detecta possíveis tentativas de SQL Injection
  static bool _containsSqlInjection(String input) {
    final suspiciousPatterns = [
      RegExp(r'(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION)\b)', caseSensitive: false),
      RegExp(r'(\-\-|\#|\/\*|\*\/)', caseSensitive: false),
      RegExp(r'(\bOR\b.*\b=\b|\bAND\b.*\b=\b)', caseSensitive: false),
      RegExp(r'(\b1\s*=\s*1\b|\b1\s*=\s*0\b)', caseSensitive: false),
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(input)) {
        print('$_tag SQL Injection detectado: $input');
        return true;
      }
    }

    return false;
  }
}