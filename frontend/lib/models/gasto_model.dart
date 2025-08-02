class GastoModel {
  final String? id; // UUID para compatibilidade Supabase
  final String? userId; // user_id para sincronização
  final DateTime data;
  final String categoria;
  final double valor;
  final String descricao;
  final DateTime dataRegistro;
  final DateTime? updatedAt; // updated_at do Supabase

  GastoModel({
    this.id,
    this.userId,
    required this.data,
    required this.categoria,
    required this.valor,
    this.descricao = '',
    required this.dataRegistro,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'data': data.toIso8601String().split('T')[0], // Salvar apenas a data YYYY-MM-DD
      'categoria': categoria,
      'valor': valor,
      'descricao': descricao,
      'data_registro': dataRegistro.toIso8601String(),
    };
    
    if (id != null) map['id'] = id!;
    if (userId != null) map['user_id'] = userId!;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  factory GastoModel.fromMap(Map<String, dynamic> map) {
    return GastoModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString(),
      data: DateTime.parse(map['data']),
      categoria: map['categoria'] ?? '',
      valor: map['valor']?.toDouble() ?? 0.0,
      descricao: map['descricao'] ?? '',
      dataRegistro: DateTime.parse(map['data_registro']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Método fromJson necessário para sincronização
  factory GastoModel.fromJson(Map<String, dynamic> json) {
    return GastoModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      data: DateTime.parse(json['data']),
      categoria: json['categoria'] ?? '',
      valor: json['valor']?.toDouble() ?? 0.0,
      descricao: json['descricao'] ?? '',
      dataRegistro: DateTime.parse(json['data_registro']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  // Método toJson para sincronização
  Map<String, dynamic> toJson() {
    return toMap();
  }

  GastoModel copyWith({
    String? id,
    String? userId,
    DateTime? data,
    String? categoria,
    double? valor,
    String? descricao,
    DateTime? dataRegistro,
    DateTime? updatedAt,
  }) {
    return GastoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      categoria: categoria ?? this.categoria,
      valor: valor ?? this.valor,
      descricao: descricao ?? this.descricao,
      dataRegistro: dataRegistro ?? this.dataRegistro,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}