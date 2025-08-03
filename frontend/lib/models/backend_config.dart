class BackendConfig {
  final String baseUrl;
  final String protocol;
  final String host;
  final int port;
  final String apiPath;
  final int timeoutSeconds;
  final bool useHttps;
  final String description;

  BackendConfig({
    required this.baseUrl,
    this.protocol = 'https',
    this.host = 'localhost',
    this.port = 5000,
    this.apiPath = '/api',
    this.timeoutSeconds = 30,
    this.useHttps = true,
    this.description = '',
  });

  // Construir URL completa
  String get fullBaseUrl {
    if (baseUrl.isNotEmpty) {
      return baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    }
    return '$protocol://$host:$port';
  }

  String get fullApiUrl => '$fullBaseUrl$apiPath';

  // Configurações pré-definidas
  static BackendConfig get replitPublic => BackendConfig(
    baseUrl: 'https://6d6e54df-ff6d-4db5-89c0-f44cf71804ff-00-udgvjocecjan.janeway.replit.dev',
    protocol: 'https',
    host: '6d6e54df-ff6d-4db5-89c0-f44cf71804ff-00-udgvjocecjan.janeway.replit.dev',
    port: 443,
    apiPath: '/api',
    timeoutSeconds: 30,
    useHttps: true,
    description: 'Replit Backend Público',
  );

  static BackendConfig get localhost => BackendConfig(
    baseUrl: 'http://localhost:5000',
    protocol: 'http',
    host: 'localhost',
    port: 5000,
    apiPath: '/api',
    timeoutSeconds: 10,
    useHttps: false,
    description: 'Backend Local (desenvolvimento)',
  );

  static BackendConfig get flyio => BackendConfig(
    baseUrl: 'https://moto.fly.dev',
    protocol: 'https',
    host: 'moto.fly.dev',
    port: 5000,
    apiPath: '/api',
    timeoutSeconds: 30,
    useHttps: true,
    description: 'Fly.io Production',
  );

  // Conversão para JSON
  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'protocol': protocol,
      'host': host,
      'port': port,
      'apiPath': apiPath,
      'timeoutSeconds': timeoutSeconds,
      'useHttps': useHttps,
      'description': description,
    };
  }

  // Conversão do JSON
  static BackendConfig fromJson(Map<String, dynamic> json) {
    return BackendConfig(
      baseUrl: json['baseUrl'] ?? '',
      protocol: json['protocol'] ?? 'https',
      host: json['host'] ?? 'localhost',
      port: json['port'] ?? 5000,
      apiPath: json['apiPath'] ?? '/api',
      timeoutSeconds: json['timeoutSeconds'] ?? 30,
      useHttps: json['useHttps'] ?? true,
      description: json['description'] ?? '',
    );
  }

  // Copiar com mudanças
  BackendConfig copyWith({
    String? baseUrl,
    String? protocol,
    String? host,
    int? port,
    String? apiPath,
    int? timeoutSeconds,
    bool? useHttps,
    String? description,
  }) {
    return BackendConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      protocol: protocol ?? this.protocol,
      host: host ?? this.host,
      port: port ?? this.port,
      apiPath: apiPath ?? this.apiPath,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      useHttps: useHttps ?? this.useHttps,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'BackendConfig(fullBaseUrl: $fullBaseUrl, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackendConfig &&
        other.baseUrl == baseUrl &&
        other.protocol == protocol &&
        other.host == host &&
        other.port == port &&
        other.apiPath == apiPath &&
        other.timeoutSeconds == timeoutSeconds &&
        other.useHttps == useHttps &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      baseUrl,
      protocol,
      host,
      port,
      apiPath,
      timeoutSeconds,
      useHttps,
      description,
    );
  }
}