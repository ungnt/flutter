class GastoModel {
  final String? id;
  final String userId;
  final DateTime data;
  final String categoria;
  final double valor;
  final String? descricao;
  final DateTime dataRegistro;
  final DateTime? updatedAt;

  GastoModel({
    this.id,
    required this.userId,
    required this.data,
    required this.categoria,
    required this.valor,
    this.descricao,
    required this.dataRegistro,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'user_id': userId,
      'data': data.toIso8601String().split('T')[0], // YYYY-MM-DD
      'categoria': categoria,
      'valor': valor,
      'descricao': descricao,
      'data_registro': dataRegistro.toIso8601String(),
    };
    
    // Só incluir id se não for null (para inserção)
    if (id != null) map['id'] = id;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  factory GastoModel.fromJson(Map<String, dynamic> json) {
    return GastoModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      data: DateTime.parse(json['data']),
      categoria: json['categoria']?.toString() ?? '',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      descricao: json['descricao']?.toString(),
      dataRegistro: DateTime.parse(json['data_registro']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
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

  @override
  String toString() {
    return 'GastoModel(id: $id, userId: $userId, data: $data, categoria: $categoria, valor: $valor)';
  }
}