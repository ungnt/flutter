/// Model para manutenções do veículo
/// Alinhado 100% com frontend e Supabase
class ManutencaoModel {
  final String? id; // UUID String para compatibilidade total com Supabase
  final String userId;
  final DateTime data;
  final String tipo;
  final double valor;
  final double kmAtual;  // Corrigido: km_atual como numeric no Supabase
  final String? descricao;
  final DateTime dataRegistro;  // Corrigido: data_registro como no Supabase
  final DateTime? updatedAt;

  ManutencaoModel({
    this.id,
    required this.userId,
    required this.data,
    required this.tipo,
    required this.valor,
    required this.kmAtual,
    this.descricao,
    required this.dataRegistro,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'user_id': userId,
      'data': data.toIso8601String().split('T')[0], // YYYY-MM-DD
      'tipo': tipo,
      'valor': valor,
      'km_atual': kmAtual,  // Corrigido: nome do campo no Supabase
      'descricao': descricao,
      'data_registro': dataRegistro.toIso8601String(),  // Corrigido
    };
    
    // Só incluir id se não for null (para inserção)
    if (id != null) map['id'] = id;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  factory ManutencaoModel.fromJson(Map<String, dynamic> json) {
    return ManutencaoModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      data: DateTime.parse(json['data']),
      tipo: json['tipo']?.toString() ?? '',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      kmAtual: (json['km_atual'] as num?)?.toDouble() ?? 0.0,  // Corrigido
      descricao: json['descricao']?.toString(),
      dataRegistro: DateTime.parse(json['data_registro']),  // Corrigido
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
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

  @override
  String toString() {
    return 'ManutencaoModel(id: $id, userId: $userId, data: $data, tipo: $tipo, valor: $valor, kmAtual: $kmAtual)';
  }
}