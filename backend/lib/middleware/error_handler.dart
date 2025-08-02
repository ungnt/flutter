import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ErrorHandler');

/// Middleware para capturar e formatar erros globalmente
Middleware errorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on FormatException catch (e) {
        _logger.warning('Format error: ${e.message}');
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'INVALID_JSON',
            'message': 'Formato de dados inválido'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e, stackTrace) {
        _logger.severe('Unhandled error: $e', e, stackTrace);
        
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'INTERNAL_ERROR',
            'message': 'Erro interno do servidor'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    };
  };
}