import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/backend_config.dart';

class BackendConfigService {
  static const String _configKey = 'backend_config';
  static const String _isConfiguredKey = 'backend_is_configured';
  
  static BackendConfigService? _instance;
  static BackendConfigService get instance {
    _instance ??= BackendConfigService._();
    return _instance!;
  }
  
  BackendConfigService._();

  BackendConfig? _currentConfig;
  
  // Obter configuração atual
  BackendConfig? get currentConfig => _currentConfig;

  // Verificar se já está configurado
  Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isConfiguredKey) ?? false;
  }

  // Carregar configuração salva
  Future<BackendConfig?> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      
      if (configJson != null) {
        final configMap = json.decode(configJson);
        _currentConfig = BackendConfig.fromJson(configMap);
        return _currentConfig;
      }
    } catch (e) {
      print('Erro ao carregar configuração do backend: $e');
    }
    
    // Se não há configuração, usar padrão Replit
    _currentConfig = BackendConfig.replitPublic;
    return _currentConfig;
  }

  // Salvar configuração
  Future<bool> saveConfig(BackendConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = json.encode(config.toJson());
      
      await prefs.setString(_configKey, configJson);
      await prefs.setBool(_isConfiguredKey, true);
      
      _currentConfig = config;
      return true;
    } catch (e) {
      print('Erro ao salvar configuração do backend: $e');
      return false;
    }
  }

  // Limpar configuração
  Future<bool> clearConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_configKey);
      await prefs.setBool(_isConfiguredKey, false);
      _currentConfig = null;
      return true;
    } catch (e) {
      print('Erro ao limpar configuração do backend: $e');
      return false;
    }
  }

  // Obter configurações pré-definidas
  List<BackendConfig> getPresetConfigs() {
    return [
      BackendConfig.replitPublic,
      BackendConfig.localhost,
      BackendConfig.flyio,
    ];
  }

  // Obter URL completa para um endpoint
  String getEndpointUrl(String endpoint) {
    final config = _currentConfig ?? BackendConfig.replitPublic;
    final baseApiUrl = config.fullApiUrl;
    
    // Remover barra inicial do endpoint se existir
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    
    return '$baseApiUrl/$cleanEndpoint';
  }

  // Obter URL base completa
  String getBaseUrl() {
    final config = _currentConfig ?? BackendConfig.replitPublic;
    return config.fullBaseUrl;
  }

  // Obter timeout configurado
  Duration getTimeout() {
    final config = _currentConfig ?? BackendConfig.replitPublic;
    return Duration(seconds: config.timeoutSeconds);
  }

  // Inicializar serviço (chamar no início do app)
  Future<void> initialize() async {
    await loadConfig();
  }

  // Testar conectividade com a configuração
  Future<bool> testConnection(BackendConfig config) async {
    try {
      // Implementar teste de conexão básico
      // Por agora, apenas validar se a URL é válida
      final uri = Uri.tryParse(config.fullBaseUrl);
      return uri != null && (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'));
    } catch (e) {
      print('Erro ao testar conexão: $e');
      return false;
    }
  }

  // Debug: imprimir configuração atual
  void debugPrintConfig() {
    print('=== CONFIGURAÇÃO BACKEND ATUAL ===');
    if (_currentConfig != null) {
      print('Base URL: ${_currentConfig!.fullBaseUrl}');
      print('API URL: ${_currentConfig!.fullApiUrl}');
      print('Timeout: ${_currentConfig!.timeoutSeconds}s');
      print('HTTPS: ${_currentConfig!.useHttps}');
      print('Descrição: ${_currentConfig!.description}');
    } else {
      print('Nenhuma configuração carregada');
    }
    print('===================================');
  }
}