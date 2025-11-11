/// Model para manutenções do veículo
/// Alinhado 100% com backend e Supabase
class ManutencaoModel {
  final int? localId; // ID local SQLite (INTEGER AUTOINCREMENT)
  final String? remoteId; // UUID String para backend/Supabase
  final String? userId; // user_id String para sincronização
  final DateTime data;
  final String tipo;
  final double valor;
  final double kmAtual;
  final String? descricao;  // Corrigido: pode ser null
  final DateTime dataRegistro;
  final DateTime? updatedAt;  // Adicionado: updated_at do Supabase

  ManutencaoModel({
    this.localId,
    this.remoteId,
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
    
    if (localId != null) map['local_id'] = localId!;
    if (remoteId != null) map['remote_id'] = remoteId!;
    if (userId != null) map['user_id'] = userId!;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  factory ManutencaoModel.fromMap(Map<String, dynamic> map) {
    return ManutencaoModel(
      localId: map['local_id'] as int?,
      remoteId: map['remote_id']?.toString(),
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

  // Método fromJson necessário para sincronização (backend retorna 'id' como UUID)
  factory ManutencaoModel.fromJson(Map<String, dynamic> json) {
    return ManutencaoModel(
      localId: null, // Backend não tem localId
      remoteId: json['id']?.toString(),
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

  // Método toJson para sincronização (backend espera 'id' como UUID)
  Map<String, dynamic> toJson() {
    final map = {
      'data': data.toIso8601String().split('T')[0],
      'tipo': tipo,
      'valor': valor,
      'km_atual': kmAtual,
      'descricao': descricao,
      'data_registro': dataRegistro.toIso8601String(),
    };
    
    if (remoteId != null) map['id'] = remoteId!;
    if (userId != null) map['user_id'] = userId!;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  ManutencaoModel copyWith({
    int? localId,
    String? remoteId,
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
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
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