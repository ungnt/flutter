import 'dart:convert';
import 'dart:math';

/// Resultado da validação
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, dynamic>? sanitizedData;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.sanitizedData,
  });
}

/// Serviço avançado de segurança para validação e sanitização
class SecurityService {
  static const String _tag = '[Security]';
  
  // Configurações de segurança
  static const int maxStringLength = 1000;
  static const int maxNumberValue = 999999999;
  static const List<String> allowedCategories = [
    'Combustível',
    'Alimentação', 
    'Manutenção',
    'Seguro',
    'Documentos',
    'Equipamentos',
    'Outros'
  ];
  static const List<String> allowedTiposManutencao = [
    'Troca de óleo',
    'Revisão',
    'Pneus',
    'Freios',
    'Suspensão',
    'Outros'
  ];

  /// Sanitiza e valida entrada de texto
  static String sanitizeText(String? input) {
    if (input == null) return '';
    
    // Remove caracteres potencialmente perigosos
    String sanitized = input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'''[<>"']'''), '') // Remove caracteres especiais
        .trim();
    
    // Limita o tamanho
    if (sanitized.length > maxStringLength) {
      sanitized = sanitized.substring(0, maxStringLength);
    }
    
    return sanitized;
  }

  /// Valida e sanitiza número decimal
  static double sanitizeNumber(dynamic input) {
    if (input == null) return 0.0;
    
    double value = 0.0;
    if (input is num) {
      value = input.toDouble();
    } else if (input is String) {
      value = double.tryParse(input) ?? 0.0;
    }
    
    // Limita valores extremos
    if (value < 0) value = 0.0;
    if (value > maxNumberValue) value = maxNumberValue.toDouble();
    
    // Arredonda para 2 casas decimais
    return double.parse(value.toStringAsFixed(2));
  }

  /// Valida categoria de gasto
  static String sanitizeCategoria(String? categoria) {
    if (categoria == null || categoria.isEmpty) return 'Outros';
    
    final sanitized = sanitizeText(categoria);
    return allowedCategories.contains(sanitized) ? sanitized : 'Outros';
  }

  /// Log de auditoria
  static void auditLog(String userId, String action, Map<String, dynamic>? data) {
    print('[$_tag] AUDIT: $userId - $action - ${data ?? {}}');
  }



  /// Controle de rate limiting
  static bool checkRateLimit(String clientId, int maxRequests, Duration window) {
    // Implementação simples - em produção usar Redis ou similar
    return true; // Por enquanto sempre permite
  }

  /// Valida tipo de manutenção
  static String sanitizeTipoManutencao(String? tipo) {
    if (tipo == null || tipo.isEmpty) return 'Outros';
    
    final sanitized = sanitizeText(tipo);
    return allowedTiposManutencao.contains(sanitized) ? sanitized : 'Outros';
  }

  /// Sanitiza data
  static DateTime? sanitizeDate(dynamic input) {
    if (input == null) return null;
    
    if (input is DateTime) return input;
    
    if (input is String) {
      try {
        return DateTime.parse(input);
      } catch (e) {
        print('$_tag Erro ao parsear data: $input');
        return null;
      }
    }
    
    return null;
  }

  /// Valida email
  static ValidationResult validateEmail(String? email) {
    final errors = <String>[];
    
    if (email == null || email.isEmpty) {
      errors.add('Email é obrigatório');
      return ValidationResult(isValid: false, errors: errors);
    }
    
    final sanitized = sanitizeText(email);
    
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(sanitized)) {
      errors.add('Email deve ter formato válido');
    }
    
    if (sanitized.length > 255) {
      errors.add('Email muito longo');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      sanitizedData: {'email': sanitized},
    );
  }

  /// Valida senha
  static ValidationResult validatePassword(String? password) {
    final errors = <String>[];
    
    if (password == null || password.isEmpty) {
      errors.add('Senha é obrigatória');
      return ValidationResult(isValid: false, errors: errors);
    }
    
    if (password.length < 6) {
      errors.add('Senha deve ter pelo menos 6 caracteres');
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('Senha deve conter pelo menos um número');
    }
    
    if (!password.contains(RegExp(r'[a-zA-Z]'))) {
      errors.add('Senha deve conter pelo menos uma letra');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Valida dados de trabalho
  static ValidationResult validateTrabalhoData(Map<String, dynamic> data) {
    final errors = <String>[];
    final sanitized = <String, dynamic>{};
    
    // Validar data
    final dataTrabalho = sanitizeDate(data['data']);
    if (dataTrabalho == null) {
      errors.add('Data de trabalho inválida');
    } else {
      sanitized['data'] = dataTrabalho.toIso8601String().split('T')[0];
    }
    
    // Validar ganhos
    final ganhos = sanitizeNumber(data['ganhos']);
    if (ganhos <= 0) {
      errors.add('Ganhos devem ser positivos');
    } else {
      sanitized['ganhos'] = ganhos;
    }
    
    // Sanitizar descrição
    sanitized['descricao'] = sanitizeText(data['descricao']);
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      sanitizedData: sanitized,
    );
  }

  /// Valida dados de gasto
  static ValidationResult validateGastoData(Map<String, dynamic> data) {
    final errors = <String>[];
    final sanitized = <String, dynamic>{};
    
    // Validar data
    final dataGasto = sanitizeDate(data['data']);
    if (dataGasto == null) {
      errors.add('Data de gasto inválida');
    } else {
      sanitized['data'] = dataGasto.toIso8601String().split('T')[0];
    }
    
    // Validar valor
    final valor = sanitizeNumber(data['valor']);
    if (valor <= 0) {
      errors.add('Valor deve ser positivo');
    } else {
      sanitized['valor'] = valor;
    }
    
    // Validar categoria
    sanitized['categoria'] = sanitizeCategoria(data['categoria']);
    
    // Sanitizar descrição
    sanitized['descricao'] = sanitizeText(data['descricao']);
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      sanitizedData: sanitized,
    );
  }

  /// Valida dados de manutenção
  static ValidationResult validateManutencaoData(Map<String, dynamic> data) {
    final errors = <String>[];
    final sanitized = <String, dynamic>{};
    
    // Validar data
    final dataManutencao = sanitizeDate(data['data']);
    if (dataManutencao == null) {
      errors.add('Data de manutenção inválida');
    } else {
      sanitized['data'] = dataManutencao.toIso8601String().split('T')[0];
    }
    
    // Validar custo
    final custo = sanitizeNumber(data['custo']);
    if (custo <= 0) {
      errors.add('Custo deve ser positivo');
    } else {
      sanitized['custo'] = custo;
    }
    
    // Validar tipo
    sanitized['tipo'] = sanitizeTipoManutencao(data['tipo']);
    
    // Sanitizar descrição
    sanitized['descricao'] = sanitizeText(data['descricao']);
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      sanitizedData: sanitized,
    );
  }

  /// Detecta tentativas de SQL Injection básicas
  static bool containsSqlInjection(String input) {
    final sqlPatterns = [
      'DROP',
      'DELETE',
      'INSERT',
      'UPDATE',
      'SELECT',
      'UNION',
      '--',
      ';',
      'OR 1=1',
      'AND 1=1',
      'EXEC',
      'SCRIPT',
    ];
    
    final upperInput = input.toUpperCase();
    return sqlPatterns.any((pattern) => upperInput.contains(pattern));
  }

  /// Detecta XSS básico
  static bool containsXss(String input) {
    final xssPatterns = [
      '<script',
      'javascript:',
      'onclick=',
      'onerror=',
      'onload=',
    ];
    
    final lowerInput = input.toLowerCase();
    return xssPatterns.any((pattern) => lowerInput.contains(pattern));
  }

  /// Validação de segurança geral
  static ValidationResult validateSecurity(Map<String, dynamic> data) {
    final errors = <String>[];
    
    for (final entry in data.entries) {
      if (entry.value is String) {
        final value = entry.value as String;
        
        if (containsSqlInjection(value)) {
          errors.add('Tentativa de SQL Injection detectada no campo ${entry.key}');
        }
        
        if (containsXss(value)) {
          errors.add('Tentativa de XSS detectada no campo ${entry.key}');
        }
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}