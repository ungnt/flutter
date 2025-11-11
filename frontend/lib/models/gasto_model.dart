/// Model para gastos/despesas do usuário
/// Alinhado 100% com backend e Supabase
class GastoModel {
  final int? localId; // ID local SQLite (INTEGER AUTOINCREMENT)
  final String? remoteId; // UUID String para backend/Supabase
  final String? userId; // user_id String para sincronização
  final DateTime data;
  final String categoria;
  final double valor;
  final String descricao;
  final DateTime dataRegistro;
  final DateTime? updatedAt; // updated_at do Supabase

  GastoModel({
    this.localId,
    this.remoteId,
    this.userId,
    required this.data,
    required this.categoria,
    required this.valor,
    this.descricao = '',
    required this.dataRegistro,
    this.updatedAt,
  });

  // Getter para compatibilidade com código legado
  int? get id => localId;

  Map<String, dynamic> toMap() {
    final map = {
      'data': data.toIso8601String().split('T')[0], // Salvar apenas a data YYYY-MM-DD
      'categoria': categoria,
      'valor': valor,
      'descricao': descricao,
      'data_registro': dataRegistro.toIso8601String(),
    };
    
    if (localId != null) map['local_id'] = localId!;
    if (remoteId != null) map['remote_id'] = remoteId!;
    if (userId != null) map['user_id'] = userId!;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  factory GastoModel.fromMap(Map<String, dynamic> map) {
    return GastoModel(
      localId: map['local_id'] as int?,
      remoteId: map['remote_id']?.toString(),
      userId: map['user_id']?.toString(),
      data: DateTime.parse(map['data']),
      categoria: map['categoria'] ?? '',
      valor: map['valor']?.toDouble() ?? 0.0,
      descricao: map['descricao'] ?? '',
      dataRegistro: DateTime.parse(map['data_registro']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Método fromJson necessário para sincronização (backend retorna 'id' como UUID)
  factory GastoModel.fromJson(Map<String, dynamic> json) {
    return GastoModel(
      localId: null, // Backend não tem localId
      remoteId: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      data: DateTime.parse(json['data']),
      categoria: json['categoria'] ?? '',
      valor: json['valor']?.toDouble() ?? 0.0,
      descricao: json['descricao'] ?? '',
      dataRegistro: DateTime.parse(json['data_registro']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  // Método toJson para sincronização (backend espera 'id' como UUID)
  Map<String, dynamic> toJson() {
    final map = {
      'data': data.toIso8601String().split('T')[0],
      'categoria': categoria,
      'valor': valor,
      'descricao': descricao,
      'data_registro': dataRegistro.toIso8601String(),
    };
    
    if (remoteId != null) map['id'] = remoteId!;
    if (userId != null) map['user_id'] = userId!;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  GastoModel copyWith({
    int? localId,
    String? remoteId,
    String? userId,
    DateTime? data,
    String? categoria,
    double? valor,
    String? descricao,
    DateTime? dataRegistro,
    DateTime? updatedAt,
  }) {
    return GastoModel(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
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