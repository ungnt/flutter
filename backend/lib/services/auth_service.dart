import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:logging/logging.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  static final _logger = Logger('AuthService');
  final DatabaseService _database;
  final String _jwtSecret;
  
  AuthService(this._database, this._jwtSecret);

  /// Hash da senha com bcrypt (salt único automático)
  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// Verificar senha (suporta bcrypt novo e SHA-256 legado)
  bool _verifyPassword(String password, String hashedPassword) {
    // Tentar bcrypt primeiro (hash começa com $2)
    if (hashedPassword.startsWith('\$2')) {
      return BCrypt.checkpw(password, hashedPassword);
    }
    
    // Fallback para SHA-256 legado (para senhas antigas)
    final salt = 'km_dollar_salt_2025';
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString() == hashedPassword;
  }

  /// Gerar JWT token
  String _generateJWT(UserModel user) {
    final jwt = JWT({
      'user_id': user.id,
      'email': user.email,
      'is_premium': user.isPremium,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000, // 1 hora
    });

    return jwt.sign(SecretKey(_jwtSecret));
  }

  /// Validar JWT token
  Map<String, dynamic>? validateJWT(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;
      
      // Verificar expiração
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (now >= exp) {
        _logger.warning('Token expirado');
        return null;
      }
      
      return payload;
    } catch (e) {
      _logger.warning('Token inválido: $e');
      return null;
    }
  }

  /// Registrar novo usuário
  Future<AuthResponse?> register(RegisterRequest request) async {
    try {
      _logger.info('Registrando usuário: ${request.email}');
      
      // Verificar se email já existe
      final existingUser = await _database.getUserByEmail(request.email);
      if (existingUser != null) {
        _logger.warning('Email já cadastrado: ${request.email}');
        return null;
      }
      
      // Hash da senha
      final hashedPassword = _hashPassword(request.password);
      
      // Criar usuário no banco
      final user = await _database.createUser(
        email: request.email,
        name: request.name,
        hashedPassword: hashedPassword,
      );
      
      if (user == null) {
        _logger.severe('Erro ao criar usuário no banco');
        return null;
      }
      
      // Gerar token
      final token = _generateJWT(user);
      final expiresAt = DateTime.now().add(Duration(hours: 1));
      
      _logger.info('Usuário registrado com sucesso: ${user.id}');
      
      return AuthResponse(
        user: user,
        token: token,
        expiresAt: expiresAt,
      );
      
    } catch (e, stack) {
      _logger.severe('Erro no registro: $e', e, stack);
      return null;
    }
  }

  /// Fazer login
  Future<AuthResponse?> login(LoginRequest request) async {
    try {
      _logger.info('Login attempt: ${request.email}');
      
      // Buscar usuário por email
      final user = await _database.getUserByEmail(request.email);
      if (user == null) {
        _logger.warning('Usuário não encontrado: ${request.email}');
        return null;
      }
      
      // Buscar senha hasheada
      final storedPassword = await _database.getUserPassword(user.id);
      if (storedPassword == null) {
        _logger.severe('Senha não encontrada para usuário: ${user.id}');
        return null;
      }
      
      // Verificar senha
      if (!_verifyPassword(request.password, storedPassword)) {
        _logger.warning('Senha incorreta para: ${request.email}');
        return null;
      }
      
      // Gerar token
      final token = _generateJWT(user);
      final expiresAt = DateTime.now().add(Duration(hours: 1));
      
      _logger.info('Login bem-sucedido: ${user.id}');
      
      return AuthResponse(
        user: user,
        token: token,
        expiresAt: expiresAt,
      );
      
    } catch (e, stack) {
      _logger.severe('Erro no login: $e', e, stack);
      return null;
    }
  }

  /// Buscar usuário por ID do token
  Future<UserModel?> getUserFromToken(String token) async {
    try {
      final payload = validateJWT(token);
      if (payload == null) return null;
      
      final userId = payload['user_id'] as String;
      return await _database.getUserById(userId);
      
    } catch (e) {
      _logger.warning('Erro ao buscar usuário do token: $e');
      return null;
    }
  }
}