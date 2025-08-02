class ManutencaoModel {
  final String? id;  // Corrigido: UUID no Supabase
  final String? userId;  // Adicionado: user_id para sincronização
  final DateTime data;
  final String tipo;
  final double valor;
  final double kmAtual;
  final String? descricao;  // Corrigido: pode ser null
  final DateTime dataRegistro;
  final DateTime? updatedAt;  // Adicionado: updated_at do Supabase

  ManutencaoModel({
    this.id,
    this.userId,
    required this.data,
    required this.tipo,
    required this.valor,
    required this.kmAtual,
    this.descricao,
    required this.dataRegistro,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'data': data.toIso8601String().split('T')[0], // Salvar apenas a data YYYY-MM-DD
      'tipo': tipo,
      'valor': valor,
      'km_atual': kmAtual, // CORRIGIDO: Supabase usa 'km_atual'
      'descricao': descricao,
      'data_registro': dataRegistro.toIso8601String(),
    };
    
    if (id != null) map['id'] = id;
    if (userId != null) map['user_id'] = userId;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  factory ManutencaoModel.fromMap(Map<String, dynamic> map) {
    return ManutencaoModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString(),
      data: DateTime.parse(map['data']),
      tipo: map['tipo'] ?? '',
      valor: map['valor']?.toDouble() ?? 0.0,
      kmAtual: map['km_atual']?.toDouble() ?? 0.0, // CORRIGIDO: Supabase usa 'km_atual'
      descricao: map['descricao']?.toString(),
      dataRegistro: DateTime.parse(map['data_registro']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Método fromJson necessário para sincronização
  factory ManutencaoModel.fromJson(Map<String, dynamic> json) {
    return ManutencaoModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      data: DateTime.parse(json['data']),
      tipo: json['tipo'] ?? '',
      valor: json['valor']?.toDouble() ?? 0.0,
      kmAtual: json['km_atual']?.toDouble() ?? 0.0, // CORRIGIDO: Supabase usa 'km_atual'
      descricao: json['descricao']?.toString(),
      dataRegistro: DateTime.parse(json['data_registro']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  // Método toJson para sincronização
  Map<String, dynamic> toJson() {
    return toMap();
  }

  ManutencaoModel copyWith({
    String? id,
    String? userId,
    DateTime? data,
    String? tipo,
    double? valor,
    double? kmAtual,
    String? descricao,
    DateTime? dataRegistro,
    DateTime? updatedAt,
  }) {
    return ManutencaoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      kmAtual: kmAtual ?? this.kmAtual,
      descricao: descricao ?? this.descricao,
      dataRegistro: dataRegistro ?? this.dataRegistro,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}